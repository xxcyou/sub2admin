import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A typed exception thrown when the API returns an error.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic code;

  ApiException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}

/// Auth / configuration holder, persisted to SharedPreferences.
class AdminConfig {
  static const _kBase = 'cfg_base_url';
  static const _kKey = 'cfg_api_key';

  String baseUrl;
  String apiKey;

  AdminConfig({required this.baseUrl, required this.apiKey});

  String get trimmedBase => baseUrl.replaceAll(RegExp(r'/+$'), '');

  static Future<AdminConfig?> load() async {
    final sp = await SharedPreferences.getInstance();
    final base = sp.getString(_kBase);
    final key = sp.getString(_kKey);
    if (base == null || key == null || base.trim().isEmpty || key.trim().isEmpty) {
      return null;
    }
    return AdminConfig(baseUrl: base, apiKey: key);
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kBase, baseUrl.trim());
    await sp.setString(_kKey, apiKey.trim());
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kBase);
    await sp.remove(_kKey);
  }
}

/// REST client for the Sub2API / new-api style admin backend.
///
/// All requests carry `x-api-key: <admin-key>` and hit `<base>/api/v1/admin/*`.
class ApiClient {
  AdminConfig config;
  final http.Client _client = http.Client();
  final int timeoutSeconds;

  ApiClient(this.config, {this.timeoutSeconds = 25});

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query == null
        ? null
        : query.map((k, v) => MapEntry(k, v.toString()));
    return Uri.parse('${config.trimmedBase}/api/v1/admin/$path').replace(queryParameters: q);
  }

  Map<String, String> get _headers => {
        'x-api-key': config.apiKey,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  /// Perform a GET and decode the standard `{ code, message, data }` envelope.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _send('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) async {
    return _send('POST', path, body: body, query: query);
  }

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query}) async {
    return _send('PUT', path, body: body, query: query);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async {
    return _send('DELETE', path, query: query);
  }

  Future<dynamic> _send(String method, String path,
      {Object? body, Map<String, dynamic>? query}) async {
    final uri = _uri(path, query);
    if (kDebugMode) {
      debugPrint('[Api] $method $uri');
    }
    http.Response resp;
    try {
      final req = http.Request(method, uri)..headers.addAll(_headers);
      if (body != null) {
        req.body = jsonEncode(body);
      }
      final streamed = await _client.send(req).timeout(Duration(seconds: timeoutSeconds));
      resp = await http.Response.fromStream(streamed).timeout(Duration(seconds: timeoutSeconds));
    } on TimeoutException {
      throw ApiException('请求超时，请检查网络或服务器状态', statusCode: 0);
    } on SocketException catch (e) {
      throw ApiException('无法连接服务器：${e.message}', statusCode: 0);
    } on http.ClientException catch (e) {
      throw ApiException('网络错误：${e.message}', statusCode: 0);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(resp.bodyBytes));
    } catch (_) {
      throw ApiException('服务器返回了无法解析的数据 (HTTP ${resp.statusCode})',
          statusCode: resp.statusCode);
    }

    if (resp.statusCode == 401 || (decoded is Map && decoded['code'] == 'INVALID_TOKEN')) {
      throw ApiException('管理员密钥无效或已过期，请检查 x-api-key', statusCode: 401);
    }
    if (resp.statusCode == 403) {
      throw ApiException('没有权限执行此操作', statusCode: 403);
    }

    if (decoded is Map && decoded.containsKey('code')) {
      final code = decoded['code'];
      // new-api style: numeric 0 == success; string codes are errors.
      if (code is num && code == 0) {
        return decoded['data'];
      }
      final msg = decoded['message']?.toString() ?? '请求失败';
      throw ApiException(msg, statusCode: resp.statusCode, code: code);
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return decoded;
    }
    throw ApiException('请求失败 (HTTP ${resp.statusCode})', statusCode: resp.statusCode);
  }

  void close() => _client.close();
}
