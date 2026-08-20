import '../models/models.dart';
import 'api_client.dart';

/// High-level data access for the dashboard screens.
class DashboardData {
  final DashboardSnapshot stats;
  final List<RankItem> models;
  final List<RankItem> groups;
  final List<TrendPoint> trend;
  final List<UserRankItem> userRanking;

  DashboardData(this.stats, this.models, this.groups, this.trend, this.userRanking);
}

class TrendPoint {
  final DateTime date;
  final int requests;
  final double tokens;
  final double cost;

  TrendPoint(this.date, this.requests, this.tokens, this.cost);

  factory TrendPoint.fromJson(Map<String, dynamic> j) {
    return TrendPoint(
      DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      (j['requests'] as num?)?.toInt() ?? 0,
      (j['total_tokens'] as num?)?.toDouble() ?? 0,
      (j['cost'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Repository {
  final ApiClient api;
  Repository(this.api);

  /// ---- Dashboard ----
  Future<DashboardData> dashboard() async {
    final results = await Future.wait([
      api.get('dashboard/snapshot-v2'),
      api.get('dashboard/models'),
      api.get('dashboard/groups'),
      api.get('dashboard/trend'),
      api.get('dashboard/users-ranking'),
    ]);
    final statsJson = (results[0] as Map<String, dynamic>)['stats'] as Map<String, dynamic>;
    final stats = DashboardSnapshot.fromJson(statsJson);

    final modelRanks = _rankList((results[1] as Map)['models'], 'model');
    final groupRanks = _rankList((results[2] as Map)['groups'], 'group_name');

    final trend = ((results[3] as Map<String, dynamic>)['trend'] as List? ?? const [])
        .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    final userRanking = ((results[4] as Map<String, dynamic>)['ranking'] as List? ?? const [])
        .map((e) => UserRankItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardData(stats, modelRanks, groupRanks, trend, userRanking);
  }

  static List<RankItem> _rankList(dynamic data, String nameKey) {
    final items = (data as List?) ?? const [];
    return items
        .map((e) => RankItem.fromJson(e as Map<String, dynamic>, nameKey: nameKey))
        .toList();
  }

  /// ---- Users ----
  Future<PageData<UserItem>> users({int page = 1, int pageSize = 25}) async {
    final data = await api.get('users', query: {'page': page, 'page_size': pageSize});
    final items = ((data as Map<String, dynamic>)['items'] as List? ?? [])
        .map((e) => UserItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] as num?)?.toInt();
    return PageData(items, page, pageSize, total);
  }

  Future<UserItem> userDetail(int id) async {
    final data = await api.get('users/$id');
    return UserItem.fromJson(data as Map<String, dynamic>);
  }

  /// Update a user (partial: status / concurrency / notes / username).
  Future<UserItem> updateUser(int id, Map<String, dynamic> fields) async {
    final data = await api.put('users/$id', body: fields);
    return UserItem.fromJson(data as Map<String, dynamic>);
  }

  /// Create a new user.
  Future<UserItem> createUser({
    required String email,
    required String password,
    String username = '',
    double balance = 0,
    int concurrency = 1,
    String status = 'active',
  }) async {
    final data = await api.post('users', body: {
      'email': email,
      'password': password,
      'username': username,
      'balance': balance,
      'concurrency': concurrency,
      'status': status,
    });
    return UserItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteUser(int id) async {
    await api.delete('users/$id');
  }

  /// ---- Channels ----
  Future<PageData<ChannelItem>> channels({int page = 1, int pageSize = 25}) async {
    final data = await api.get('channels', query: {'page': page, 'page_size': pageSize});
    final items = ((data as Map<String, dynamic>)['items'] as List? ?? [])
        .map((e) => ChannelItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return PageData(items, page, pageSize, null);
  }

  Future<ChannelItem> channelDetail(int id) async {
    final data = await api.get('channels/$id');
    return ChannelItem.fromJson(data as Map<String, dynamic>);
  }

  /// Toggle a channel enabled/disabled.
  Future<ChannelItem> channelToggle(int id, String status) async {
    final data = await api.put('channels/$id', body: {'status': status});
    return ChannelItem.fromJson(data as Map<String, dynamic>);
  }

  Future<ChannelItem> createChannel({required String name, String description = ''}) async {
    final data = await api.post('channels', body: {
      'name': name,
      'description': description,
      'status': 'active',
    });
    return ChannelItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteChannel(int id) async {
    await api.delete('channels/$id');
  }

  /// ---- Request logs ----
  Future<PageData<RequestLog>> logs({
    int page = 1,
    int pageSize = 30,
    String? model,
    int? apiKeyId,
    int? userId,
  }) async {
    final q = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (model != null && model.isNotEmpty) q['model'] = model;
    if (apiKeyId != null) q['api_key_id'] = apiKeyId;
    if (userId != null) q['user_id'] = userId;
    final data = await api.get('ops/requests', query: q);
    final items = ((data as Map<String, dynamic>)['items'] as List? ?? [])
        .map((e) => RequestLog.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] as num?)?.toInt();
    return PageData(items, page, pageSize, total);
  }

  Future<List<RankItem>> models() async {
    final data = await api.get('dashboard/models');
    return _rankList((data as Map<String, dynamic>)['models'], 'model');
  }

  /// ---- System health ----
  Future<SystemHealth> systemHealth() async {
    final data = await api.get('ops/dashboard/overview');
    return SystemHealth.fromJson(data as Map<String, dynamic>);
  }

  /// ---- Version / update check ----
  Future<VersionInfo> version() async {
    final data = await api.get('system/version');
    if (data is Map && data['version'] != null) {
      return VersionInfo.fromJson(data as Map<String, dynamic>);
    }
    return VersionInfo(current: data.toString(), hasUpdate: false);
  }

  Future<VersionInfo> checkUpdates() async {
    final data = await api.get('system/check-updates');
    return VersionInfo.fromJson({
      'current_version': (data as Map<String, dynamic>)['current_version'],
      'latest_version': data['latest_version'],
      'has_update': data['has_update'],
    });
  }

  /// ---- API key search ----
  Future<List<ApiKeyInfo>> searchApiKeys(String keyword) async {
    final data = await api.get('usage/search-api-keys', query: {'keyword': keyword});
    if (data is List) {
      return data.map((e) => ApiKeyInfo.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }

  /// ---- Real-time traffic (QPS / TPS) ----
  Future<RealtimeTraffic> realtime({String window = '1m'}) async {
    final data = await api.get('ops/realtime-traffic', query: {'window': window});
    return RealtimeTraffic.fromJson(data as Map<String, dynamic>);
  }

  /// ---- Throughput trend (per-minute qps/tps/tokens) ----
  Future<List<ThroughputPoint>> throughput({String bucket = '1m'}) async {
    final data = await api.get('ops/dashboard/throughput-trend', query: {'bucket': bucket});
    final points = (data as Map<String, dynamic>)['points'] as List? ?? const [];
    return points.map((e) => ThroughputPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// ---- Latency histogram ----
  Future<LatencyHistogram> latency({String bucket = '1m'}) async {
    final data = await api.get('ops/dashboard/latency-histogram', query: {'bucket': bucket});
    return LatencyHistogram.fromJson(data as Map<String, dynamic>);
  }

  /// ---- Full detailed usage records ----
  Future<PageData<UsageRecord>> usage({
    int page = 1,
    int pageSize = 25,
    int? userId,
    String? model,
    String? startTime,
    String? endTime,
  }) async {
    final q = <String, dynamic>{'page': page, 'page_size': pageSize};
    if (userId != null) q['user_id'] = userId;
    if (model != null && model.isNotEmpty) q['model'] = model;
    if (startTime != null) q['start_time'] = startTime;
    if (endTime != null) q['end_time'] = endTime;
    final data = await api.get('usage', query: q);
    final items = ((data as Map<String, dynamic>)['items'] as List? ?? [])
        .map((e) => UsageRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] as num?)?.toInt();
    return PageData(items, page, pageSize, total);
  }

  /// ---- API key management ----
  Future<List<ManagedApiKey>> listUserApiKeys(int userId) async {
    final data = await api.get('users/$userId/api-keys');
    final items = (data is Map<String, dynamic> ? data['items'] : null) as List? ?? const [];
    return items.map((e) => ManagedApiKey.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PageData<ManagedApiKey>> listGroupApiKeys(int groupId, {int page = 1, int pageSize = 20}) async {
    final data = await api.get('groups/$groupId/api-keys', query: {'page': page, 'page_size': pageSize});
    final m = (data as Map<String, dynamic>?) ?? const {};
    final items = (m['items'] as List?)?.map((e) => ManagedApiKey.fromJson(e as Map<String, dynamic>)).toList() ?? <ManagedApiKey>[];
    final total = (m['total'] as num?)?.toInt();
    return PageData(items, page, pageSize, total);
  }

  Future<Map<int, KeyUsageStats>> keyUsage(List<int> ids) async {
    final data = await api.post('dashboard/api-keys-usage', body: {'api_key_ids': ids});
    final stats = (data is Map<String, dynamic> ? data['stats'] : null) as Map<String, dynamic>? ?? const {};
    final out = <int, KeyUsageStats>{};
    stats.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        final s = KeyUsageStats.fromJson(v);
        out[s.apiKeyId] = s;
      }
    });
    return out;
  }

  Future<List<KeyTrendPoint>> keyTrend() async {
    final data = await api.get('dashboard/api-keys-trend');
    final trend = (data is Map<String, dynamic> ? data['trend'] : null) as List? ?? const [];
    return trend.map((e) => KeyTrendPoint.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateApiKey(int id, Map<String, dynamic> body) async {
    await api.put('api-keys/$id', body: body);
  }

  Future<void> toggleApiKeyStatus(int id, String status) async {
    await api.put('api-keys/$id', body: {'status': status});
  }

  Future<void> deleteApiKey(int id) async {
    await api.delete('api-keys/$id');
  }
}
