/// Data models for the Sub2API admin panel.

import 'package:intl/intl.dart';

String fmtNum(num? v) {
  if (v == null) return '0';
  if (v is int) return NumberFormat('#,##0').format(v);
  return NumberFormat('#,##0.##').format(v);
}

String fmtCompact(num? v) {
  if (v == null) return '0';
  final d = v.toDouble();
  if (d >= 1e9) return '${(d / 1e9).toStringAsFixed(2)}B';
  if (d >= 1e6) return '${(d / 1e6).toStringAsFixed(2)}M';
  if (d >= 1e3) return '${(d / 1e3).toStringAsFixed(1)}K';
  return d.toStringAsFixed(0);
}

/// ---- Dashboard snapshot ----
class DashboardSnapshot {
  final int totalUsers;
  final int todayNewUsers;
  final int activeUsers;
  final int hourlyActiveUsers;
  final int totalApiKeys;
  final int activeApiKeys;
  final int totalAccounts;
  final int normalAccounts;
  final int errorAccounts;
  final int ratelimitAccounts;
  final int overloadAccounts;
  final int totalRequests;
  final int todayRequests;
  final double totalTokens;
  final double totalCost;
  final double totalActualCost;
  final double todayCost;
  final int todayInputTokens;
  final int todayOutputTokens;
  final num averageDurationMs;

  DashboardSnapshot._(this.totalUsers, this.todayNewUsers, this.activeUsers,
      this.hourlyActiveUsers, this.totalApiKeys, this.activeApiKeys,
      this.totalAccounts, this.normalAccounts, this.errorAccounts,
      this.ratelimitAccounts, this.overloadAccounts, this.totalRequests,
      this.todayRequests, this.totalTokens, this.totalCost, this.totalActualCost,
      this.todayCost, this.todayInputTokens, this.todayOutputTokens,
      this.averageDurationMs);

  factory DashboardSnapshot.fromJson(Map<String, dynamic> s) {
    return DashboardSnapshot._(
      (s['total_users'] as num?)?.toInt() ?? 0,
      (s['today_new_users'] as num?)?.toInt() ?? 0,
      (s['active_users'] as num?)?.toInt() ?? 0,
      (s['hourly_active_users'] as num?)?.toInt() ?? 0,
      (s['total_api_keys'] as num?)?.toInt() ?? 0,
      (s['active_api_keys'] as num?)?.toInt() ?? 0,
      (s['total_accounts'] as num?)?.toInt() ?? 0,
      (s['normal_accounts'] as num?)?.toInt() ?? 0,
      (s['error_accounts'] as num?)?.toInt() ?? 0,
      (s['ratelimit_accounts'] as num?)?.toInt() ?? 0,
      (s['overload_accounts'] as num?)?.toInt() ?? 0,
      (s['total_requests'] as num?)?.toInt() ?? 0,
      (s['today_requests'] as num?)?.toInt() ?? 0,
      (s['total_tokens'] as num?)?.toDouble() ?? 0,
      (s['total_cost'] as num?)?.toDouble() ?? 0,
      (s['total_actual_cost'] as num?)?.toDouble() ?? 0,
      (s['today_cost'] as num?)?.toDouble() ?? 0,
      (s['today_input_tokens'] as num?)?.toInt() ?? 0,
      (s['today_output_tokens'] as num?)?.toInt() ?? 0,
      (s['average_duration_ms'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// ---- Leaderboard / stat categories (users, models, groups) ----
class RankItem {
  final String name;
  final int requests;
  final double tokens;
  final double cost;
  final double actualCost;

  RankItem(this.name, this.requests, this.tokens, this.cost, this.actualCost);

  factory RankItem.fromJson(Map<String, dynamic> j,
      {String nameKey = 'name'}) {
    return RankItem(
      (j[nameKey] ?? '').toString(),
      (j['requests'] as num?)?.toInt() ?? 0,
      (j['total_tokens'] as num?)?.toDouble() ?? 0,
      (j['cost'] as num?)?.toDouble() ?? 0,
      (j['actual_cost'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// ---- Users page ----
class UserItem {
  final int id;
  final String email;
  final String username;
  final String role;
  final double balance;
  final double frozenBalance;
  final int concurrency;
  final String status;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final String notes;

  UserItem({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.balance,
    required this.frozenBalance,
    required this.concurrency,
    required this.status,
    this.createdAt,
    this.lastActive,
    this.notes = '',
  });

  factory UserItem.fromJson(Map<String, dynamic> j) {
    DateTime? parse(String? s) {
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s)?.toLocal();
    }

    return UserItem(
      id: (j['id'] as num).toInt(),
      email: j['email']?.toString() ?? '',
      username: j['username']?.toString() ?? '',
      role: j['role']?.toString() ?? 'user',
      balance: (j['balance'] as num?)?.toDouble() ?? 0,
      frozenBalance: (j['frozen_balance'] as num?)?.toDouble() ?? 0,
      concurrency: (j['concurrency'] as num?)?.toInt() ?? 1,
      status: j['status']?.toString() ?? 'active',
      createdAt: parse(j['created_at']?.toString()),
      lastActive: parse(j['last_active_at']?.toString()),
      notes: j['notes']?.toString() ?? '',
    );
  }
}

class PageData<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final int? total;

  PageData(this.items, this.page, this.pageSize, this.total);
}

/// ---- Channels ----
class ChannelItem {
  final int id;
  final String name;
  final String description;
  final String status;
  final List<String> groupNames;
  final DateTime? createdAt;

  ChannelItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.groupNames,
    this.createdAt,
  });

  factory ChannelItem.fromJson(Map<String, dynamic> j) {
    final groups = (j['group_ids'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    DateTime? parse(String? s) =>
        (s == null || s.isEmpty) ? null : DateTime.tryParse(s)?.toLocal();
    return ChannelItem(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: j['name']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      status: j['status']?.toString() ?? 'active',
      groupNames: groups,
      createdAt: parse(j['created_at']?.toString()),
    );
  }
}

/// ---- Request log ----
class RequestLog {
  final String kind;
  final DateTime createdAt;
  final String platform;
  final String model;
  final int durationMs;
  final int userId;
  final int apiKeyId;
  final bool stream;

  RequestLog({
    required this.kind,
    required this.createdAt,
    required this.platform,
    required this.model,
    required this.durationMs,
    required this.userId,
    required this.apiKeyId,
    required this.stream,
  });

  factory RequestLog.fromJson(Map<String, dynamic> j) {
    return RequestLog(
      kind: j['kind']?.toString() ?? 'unknown',
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      platform: j['platform']?.toString() ?? '',
      model: j['model']?.toString() ?? '',
      durationMs: (j['duration_ms'] as num?)?.toInt() ?? 0,
      userId: (j['user_id'] as num?)?.toInt() ?? 0,
      apiKeyId: (j['api_key_id'] as num?)?.toInt() ?? 0,
      stream: j['stream'] == true,
    );
  }
}

/// ---- System health (from /ops/dashboard/overview) ----
class SystemHealth {
  final int healthScore;
  final double cpuUsagePercent;
  final int memoryUsedMb;
  final int memoryTotalMb;
  final bool dbOk;
  final bool redisOk;
  final int goroutineCount;
  final int concurrencyQueueDepth;
  final int accountSwitchCount;
  final DateTime? startTime;
  final DateTime? endTime;

  SystemHealth({
    required this.healthScore,
    required this.cpuUsagePercent,
    required this.memoryUsedMb,
    required this.memoryTotalMb,
    required this.dbOk,
    required this.redisOk,
    required this.goroutineCount,
    required this.concurrencyQueueDepth,
    required this.accountSwitchCount,
    this.startTime,
    this.endTime,
  });

  factory SystemHealth.fromJson(Map<String, dynamic> j) {
    final metrics = (j['system_metrics'] as Map<String, dynamic>?) ?? {};
    final sm = metrics['system_metrics'] as Map<String, dynamic>? ?? {};
    // metrics may be nested at j['system_metrics'] directly
    return SystemHealth(
      healthScore: (j['health_score'] as num?)?.toInt() ?? 0,
      cpuUsagePercent:
          ((metrics['cpu_usage_percent'] ?? sm['cpu_usage_percent']) as num?)?.toDouble() ?? 0,
      memoryUsedMb:
          ((metrics['memory_used_mb'] ?? sm['memory_used_mb']) as num?)?.toInt() ?? 0,
      memoryTotalMb:
          ((metrics['memory_total_mb'] ?? sm['memory_total_mb']) as num?)?.toInt() ?? 0,
      dbOk: (metrics['db_ok'] ?? sm['db_ok']) == true,
      redisOk: (metrics['redis_ok'] ?? sm['redis_ok']) == true,
      goroutineCount:
          ((metrics['goroutine_count'] ?? sm['goroutine_count']) as num?)?.toInt() ?? 0,
      concurrencyQueueDepth:
          ((metrics['concurrency_queue_depth'] ?? sm['concurrency_queue_depth']) as num?)?.toInt() ?? 0,
      accountSwitchCount:
          ((metrics['account_switch_count'] ?? sm['account_switch_count']) as num?)?.toInt() ?? 0,
      startTime: DateTime.tryParse(j['start_time']?.toString() ?? '')?.toLocal(),
      endTime: DateTime.tryParse(j['end_time']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// ---- API key info (from /usage/search-api-keys) ----
class ApiKeyInfo {
  final int id;
  final String name;
  final int userId;

  ApiKeyInfo({required this.id, required this.name, required this.userId});

  factory ApiKeyInfo.fromJson(Map<String, dynamic> j) => ApiKeyInfo(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        userId: (j['user_id'] as num?)?.toInt() ?? 0,
      );
}

/// ---- Version / update info ----
class VersionInfo {
  final String current;
  final String? latest;
  final bool hasUpdate;

  VersionInfo({required this.current, this.latest, required this.hasUpdate});

  factory VersionInfo.fromJson(Map<String, dynamic> j) {
    final d = j['data'] as Map<String, dynamic>?;
    final ver = (j['version'] ?? d?['version'])?.toString() ?? '';
    final latest = (j['latest_version'] ?? d?['latest_version'])?.toString();
    final has = (j['has_update'] ?? d?['has_update']) == true;
    return VersionInfo(current: ver, latest: latest, hasUpdate: has);
  }
}

/// ---- User ranking item ----
class UserRankItem {
  final int userId;
  final String email;
  final String username;
  final double actualCost;
  final int requests;
  final double tokens;

  UserRankItem({
    required this.userId,
    required this.email,
    required this.username,
    required this.actualCost,
    required this.requests,
    required this.tokens,
  });

  factory UserRankItem.fromJson(Map<String, dynamic> j) => UserRankItem(
        userId: (j['user_id'] as num?)?.toInt() ?? 0,
        email: j['email']?.toString() ?? '',
        username: j['username']?.toString() ?? '',
        actualCost: (j['actual_cost'] as num?)?.toDouble() ?? 0,
        requests: (j['requests'] as num?)?.toInt() ?? 0,
        tokens: (j['tokens'] as num?)?.toDouble() ?? 0,
      );
}

/// ---- Real-time traffic (from /ops/realtime-traffic) ----
class RealtimeTraffic {
  final bool enabled;
  final String window;
  final double qpsCurrent;
  final double qpsPeak;
  final double qpsAvg;
  final double tpsCurrent;
  final double tpsPeak;
  final double tpsAvg;
  final DateTime? timestamp;

  RealtimeTraffic({
    required this.enabled,
    required this.window,
    required this.qpsCurrent,
    required this.qpsPeak,
    required this.qpsAvg,
    required this.tpsCurrent,
    required this.tpsPeak,
    required this.tpsAvg,
    this.timestamp,
  });

  factory RealtimeTraffic.fromJson(Map<String, dynamic> j) {
    final summary = (j['summary'] as Map<String, dynamic>?) ?? {};
    final qps = (summary['qps'] as Map<String, dynamic>?) ?? {};
    final tps = (summary['tps'] as Map<String, dynamic>?) ?? {};
    return RealtimeTraffic(
      enabled: j['enabled'] == true || summary['enabled'] == true,
      window: summary['window']?.toString() ?? j['window']?.toString() ?? '',
      qpsCurrent: (qps['current'] as num?)?.toDouble() ?? 0,
      qpsPeak: (qps['peak'] as num?)?.toDouble() ?? 0,
      qpsAvg: (qps['avg'] as num?)?.toDouble() ?? 0,
      tpsCurrent: (tps['current'] as num?)?.toDouble() ?? 0,
      tpsPeak: (tps['peak'] as num?)?.toDouble() ?? 0,
      tpsAvg: (tps['avg'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.tryParse(j['timestamp']?.toString() ?? summary['end_time']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// ---- Throughput trend point (from /ops/dashboard/throughput-trend) ----
class ThroughputPoint {
  final DateTime bucketStart;
  final int requestCount;
  final double tokenConsumed;
  final int switchCount;
  final double qps;
  final double tps;

  ThroughputPoint({
    required this.bucketStart,
    required this.requestCount,
    required this.tokenConsumed,
    required this.switchCount,
    required this.qps,
    required this.tps,
  });

  factory ThroughputPoint.fromJson(Map<String, dynamic> j) => ThroughputPoint(
        bucketStart: DateTime.tryParse(j['bucket_start']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        requestCount: (j['request_count'] as num?)?.toInt() ?? 0,
        tokenConsumed: (j['token_consumed'] as num?)?.toDouble() ?? 0,
        switchCount: (j['switch_count'] as num?)?.toInt() ?? 0,
        qps: (j['qps'] as num?)?.toDouble() ?? 0,
        tps: (j['tps'] as num?)?.toDouble() ?? 0,
      );
}

/// ---- Latency distribution (from /ops/dashboard/latency-histogram) ----
class LatencyBucket {
  final String range;
  final int count;
  LatencyBucket(this.range, this.count);

  factory LatencyBucket.fromJson(Map<String, dynamic> j) =>
      LatencyBucket(j['range']?.toString() ?? '', (j['count'] as num?)?.toInt() ?? 0);
}

class LatencyHistogram {
  final int totalRequests;
  final List<LatencyBucket> buckets;
  LatencyHistogram({required this.totalRequests, required this.buckets});

  factory LatencyHistogram.fromJson(Map<String, dynamic> j) {
    final buckets = (j['buckets'] as List? ?? const [])
        .map((e) => LatencyBucket.fromJson(e as Map<String, dynamic>))
        .toList();
    return LatencyHistogram(
      totalRequests: (j['total_requests'] as num?)?.toInt() ?? 0,
      buckets: buckets,
    );
  }
}

/// ---- API key embedded in usage record ----
class KeyInfo {
  final int id;
  final String key;
  final String name;
  final String status;
  final int? groupId;
  final int quota;
  final int quotaUsed;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;
  final int currentConcurrency;

  KeyInfo({
    required this.id,
    required this.key,
    required this.name,
    required this.status,
    this.groupId,
    required this.quota,
    required this.quotaUsed,
    this.expiresAt,
    this.lastUsedAt,
    required this.currentConcurrency,
  });

  factory KeyInfo.fromJson(Map<String, dynamic> j) => KeyInfo(
        id: (j['id'] as num?)?.toInt() ?? 0,
        key: j['key']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        status: j['status']?.toString() ?? '',
        groupId: (j['group_id'] as num?)?.toInt(),
        quota: (j['quota'] as num?)?.toInt() ?? 0,
        quotaUsed: (j['quota_used'] as num?)?.toInt() ?? 0,
        expiresAt: DateTime.tryParse(j['expires_at']?.toString() ?? '')?.toLocal(),
        lastUsedAt: DateTime.tryParse(j['last_used_at']?.toString() ?? '')?.toLocal(),
        currentConcurrency: (j['current_concurrency'] as num?)?.toInt() ?? 0,
      );
}

/// ---- Full usage record (from /usage) ----
class UsageRecord {
  final int id;
  final int userId;
  final int apiKeyId;
  final int accountId;
  final String requestId;
  final String model;
  final String upstreamModel;
  final int groupId;
  final String inboundEndpoint;
  final String upstreamEndpoint;

  // tokens
  final int inputTokens;
  final int outputTokens;
  final int cacheCreationTokens;
  final int cacheReadTokens;
  final int totalTokens;

  // costs
  final double inputCost;
  final double outputCost;
  final double cacheCreationCost;
  final double cacheReadCost;
  final double totalCost;
  final double actualCost;
  final double rateMultiplier;
  final String billingMode;
  final int billingType;

  // performance
  final int durationMs;
  final int firstTokenMs;

  // metadata
  final String requestType;
  final bool isStream;
  final int imageCount;
  final int imageInputTokens;
  final int imageOutputTokens;
  final String? ipAddress;
  final String? userAgent;
  final DateTime? createdAt;

  // enriched
  final String? userEmail;
  final KeyInfo? apiKey;
  final String? accountName;
  final String? groupName;
  final String? subscriptionStatus;

  UsageRecord._({
    required this.id,
    required this.userId,
    required this.apiKeyId,
    required this.accountId,
    required this.requestId,
    required this.model,
    required this.upstreamModel,
    required this.groupId,
    required this.inboundEndpoint,
    required this.upstreamEndpoint,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheCreationTokens,
    required this.cacheReadTokens,
    required this.totalTokens,
    required this.inputCost,
    required this.outputCost,
    required this.cacheCreationCost,
    required this.cacheReadCost,
    required this.totalCost,
    required this.actualCost,
    required this.rateMultiplier,
    required this.billingMode,
    required this.billingType,
    required this.durationMs,
    required this.firstTokenMs,
    required this.requestType,
    required this.isStream,
    required this.imageCount,
    required this.imageInputTokens,
    required this.imageOutputTokens,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
    required this.userEmail,
    required this.apiKey,
    required this.accountName,
    required this.groupName,
    required this.subscriptionStatus,
  });

  factory UsageRecord.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    final account = j['account'] as Map<String, dynamic>?;
    final group = j['group'] as Map<String, dynamic>?;
    final sub = j['subscription'] as Map<String, dynamic>?;
    final input = (j['input_tokens'] as num?)?.toInt() ?? 0;
    final output = (j['output_tokens'] as num?)?.toInt() ?? 0;
    final cc = (j['cache_creation_tokens'] as num?)?.toInt() ?? 0;
    final cr = (j['cache_read_tokens'] as num?)?.toInt() ?? 0;

    return UsageRecord._(
      id: (j['id'] as num?)?.toInt() ?? 0,
      userId: (j['user_id'] as num?)?.toInt() ?? 0,
      apiKeyId: (j['api_key_id'] as num?)?.toInt() ?? 0,
      accountId: (j['account_id'] as num?)?.toInt() ?? 0,
      requestId: j['request_id']?.toString() ?? '',
      model: j['model']?.toString() ?? '',
      upstreamModel: (j['upstream_model'] ?? j['upstream_response_model'])?.toString() ?? '',
      groupId: (j['group_id'] as num?)?.toInt() ?? 0,
      inboundEndpoint: j['inbound_endpoint']?.toString() ?? '',
      upstreamEndpoint: j['upstream_endpoint']?.toString() ?? '',
      inputTokens: input,
      outputTokens: output,
      cacheCreationTokens: cc,
      cacheReadTokens: cr,
      totalTokens: input + output + cc + cr,
      inputCost: (j['input_cost'] as num?)?.toDouble() ?? 0,
      outputCost: (j['output_cost'] as num?)?.toDouble() ?? 0,
      cacheCreationCost: (j['cache_creation_cost'] as num?)?.toDouble() ?? 0,
      cacheReadCost: (j['cache_read_cost'] as num?)?.toDouble() ?? 0,
      totalCost: (j['total_cost'] as num?)?.toDouble() ?? 0,
      actualCost: (j['actual_cost'] as num?)?.toDouble() ?? 0,
      rateMultiplier: (j['rate_multiplier'] as num?)?.toDouble() ?? 1,
      billingMode: j['billing_mode']?.toString() ?? '',
      billingType: (j['billing_type'] as num?)?.toInt() ?? 0,
      durationMs: (j['duration_ms'] as num?)?.toInt() ?? 0,
      firstTokenMs: (j['first_token_ms'] as num?)?.toInt() ?? 0,
      requestType: j['request_type']?.toString() ?? '',
      isStream: j['stream'] == true,
      imageCount: (j['image_count'] as num?)?.toInt() ?? 0,
      imageInputTokens: (j['image_input_tokens'] as num?)?.toInt() ?? 0,
      imageOutputTokens: (j['image_output_tokens'] as num?)?.toInt() ?? 0,
      ipAddress: j['ip_address']?.toString(),
      userAgent: j['user_agent']?.toString(),
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '')?.toLocal(),
      userEmail: user?['email']?.toString(),
      apiKey: j['api_key'] != null ? KeyInfo.fromJson(j['api_key'] as Map<String, dynamic>) : null,
      accountName: account?['name']?.toString(),
      groupName: group?['name']?.toString(),
      subscriptionStatus: sub?['status']?.toString(),
    );
  }
}

/// ---- Full API key (managed) ----
class ManagedApiKey {
  final int id;
  final int userId;
  final String key;
  final String name;
  final int groupId;
  final String status;
  final int quota;
  final int quotaUsed;
  final String? expiresAt;
  final String? createdAt;
  final String? lastUsedAt;
  final String? lastUsedIp;
  final num rateLimit5h;
  final num rateLimit1d;
  final num rateLimit7d;
  final num usage5h;
  final num usage1d;
  final num usage7d;
  final int currentConcurrency;
  final String? ipWhitelist;
  final String? ipBlacklist;
  final KeyUserMini? user;
  final KeyGroupMini? group;

  ManagedApiKey({
    required this.id,
    required this.userId,
    required this.key,
    required this.name,
    required this.groupId,
    required this.status,
    required this.quota,
    required this.quotaUsed,
    this.expiresAt,
    this.createdAt,
    this.lastUsedAt,
    this.lastUsedIp,
    this.rateLimit5h = 0,
    this.rateLimit1d = 0,
    this.rateLimit7d = 0,
    this.usage5h = 0,
    this.usage1d = 0,
    this.usage7d = 0,
    this.currentConcurrency = 0,
    this.ipWhitelist,
    this.ipBlacklist,
    this.user,
    this.group,
  });

  bool get isActive => status == 'active';

  factory ManagedApiKey.fromJson(Map<String, dynamic> j) => ManagedApiKey(
        id: (j['id'] as num?)?.toInt() ?? 0,
        userId: (j['user_id'] as num?)?.toInt() ?? 0,
        key: j['key']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        groupId: (j['group_id'] as num?)?.toInt() ?? 0,
        status: j['status']?.toString() ?? '',
        quota: (j['quota'] as num?)?.toInt() ?? 0,
        quotaUsed: (j['quota_used'] as num?)?.toInt() ?? 0,
        expiresAt: j['expires_at']?.toString(),
        createdAt: j['created_at']?.toString(),
        lastUsedAt: j['last_used_at']?.toString(),
        lastUsedIp: j['last_used_ip']?.toString(),
        rateLimit5h: (j['rate_limit_5h'] as num?) ?? 0,
        rateLimit1d: (j['rate_limit_1d'] as num?) ?? 0,
        rateLimit7d: (j['rate_limit_7d'] as num?) ?? 0,
        usage5h: (j['usage_5h'] as num?) ?? 0,
        usage1d: (j['usage_1d'] as num?) ?? 0,
        usage7d: (j['usage_7d'] as num?) ?? 0,
        currentConcurrency: (j['current_concurrency'] as num?)?.toInt() ?? 0,
        ipWhitelist: j['ip_whitelist']?.toString(),
        ipBlacklist: j['ip_blacklist']?.toString(),
        user: j['user'] is Map<String, dynamic> ? KeyUserMini.fromJson(j['user'] as Map<String, dynamic>) : null,
        group: j['group'] is Map<String, dynamic> ? KeyGroupMini.fromJson(j['group'] as Map<String, dynamic>) : null,
      );
}

class KeyUserMini {
  final int id;
  final String? email;
  final String? username;
  final String? role;
  final String? status;
  KeyUserMini({required this.id, this.email, this.username, this.role, this.status});
  factory KeyUserMini.fromJson(Map<String, dynamic> j) => KeyUserMini(
        id: (j['id'] as num?)?.toInt() ?? 0,
        email: j['email']?.toString(),
        username: j['username']?.toString(),
        role: j['role']?.toString(),
        status: j['status']?.toString(),
      );
}

class KeyGroupMini {
  final int id;
  final String name;
  final String? description;
  final String? platform;
  final String? status;
  KeyGroupMini({required this.id, required this.name, this.description, this.platform, this.status});
  factory KeyGroupMini.fromJson(Map<String, dynamic> j) => KeyGroupMini(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString(),
        platform: j['platform']?.toString(),
        status: j['status']?.toString(),
      );
}

/// Per-key cost stats from dashboard/api-keys-usage
class KeyUsageStats {
  final int apiKeyId;
  final double todayActualCost;
  final double totalActualCost;
  KeyUsageStats({required this.apiKeyId, required this.todayActualCost, required this.totalActualCost});
  factory KeyUsageStats.fromJson(Map<String, dynamic> j) => KeyUsageStats(
        apiKeyId: (j['api_key_id'] as num?)?.toInt() ?? 0,
        todayActualCost: (j['today_actual_cost'] as num?)?.toDouble() ?? 0,
        totalActualCost: (j['total_actual_cost'] as num?)?.toDouble() ?? 0,
      );
}

/// Daily trend point for a key from dashboard/api-keys-trend
class KeyTrendPoint {
  final String date;
  final int apiKeyId;
  final String? keyName;
  final int requests;
  final int tokens;
  KeyTrendPoint({required this.date, required this.apiKeyId, this.keyName, required this.requests, required this.tokens});
  factory KeyTrendPoint.fromJson(Map<String, dynamic> j) => KeyTrendPoint(
        date: j['date']?.toString() ?? '',
        apiKeyId: (j['api_key_id'] as num?)?.toInt() ?? 0,
        keyName: j['key_name']?.toString(),
        requests: (j['requests'] as num?)?.toInt() ?? 0,
        tokens: (j['tokens'] as num?)?.toInt() ?? 0,
      );
}
