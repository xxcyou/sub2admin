import 'package:flutter_test/flutter_test.dart';
import 'package:sub2admin/models/models.dart';

void main() {
  group('DashboardSnapshot - real API shape', () {
    test('parses stats map', () {
      final s = DashboardSnapshot.fromJson({
        'total_users': 72,
        'today_new_users': 0,
        'active_users': 1,
        'hourly_active_users': 1,
        'total_api_keys': 77,
        'active_api_keys': 76,
        'total_accounts': 19,
        'normal_accounts': 18,
        'error_accounts': 0,
        'ratelimit_accounts': 0,
        'overload_accounts': 0,
        'total_requests': 55107,
        'today_requests': 199,
        'total_tokens': 5785352473,
        'total_cost': 4007.5759,
        'total_actual_cost': 6367.32,
        'today_cost': 0.1113,
        'today_input_tokens': 209869,
        'today_output_tokens': 77561,
        'average_duration_ms': 12266.6,
      });
      expect(s.totalUsers, 72);
      expect(s.activeApiKeys, 76);
      expect(s.totalRequests, 55107);
      expect(s.todayCost, closeTo(0.1113, 0.0001));
    });
  });

  group('RankItem - model & group leaderboard', () {
    test('parses model ranking', () {
      final m = RankItem.fromJson({
        'model': 'deepseek-v4-flash',
        'requests': 2413,
        'total_tokens': 327350226,
        'cost': 2.281,
        'actual_cost': 2.281,
      }, nameKey: 'model');
      expect(m.name, 'deepseek-v4-flash');
      expect(m.requests, 2413);
    });

    test('parses group ranking', () {
      final g = RankItem.fromJson({
        'group_id': 26,
        'group_name': 'demo-group',
        'requests': 2454,
        'total_tokens': 330190811,
        'cost': 2.459,
        'actual_cost': 2.459,
      }, nameKey: 'group_name');
      expect(g.name, 'demo-group');
      expect(g.requests, 2454);
    });
  });

  group('UserItem - real API shape', () {
    test('parses user', () {
      final u = UserItem.fromJson({
        'id': 72,
        'email': '1319966793@qq.com',
        'username': '',
        'role': 'user',
        'balance': 0.1,
        'frozen_balance': 0,
        'concurrency': 1,
        'status': 'active',
        'created_at': '2026-06-11T13:19:54.322912+08:00',
        'last_active_at': '2026-06-11T13:30:28.403685+08:00',
        'notes': '',
      });
      expect(u.id, 72);
      expect(u.email, '1319966793@qq.com');
      expect(u.balance, 0.1);
      expect(u.status, 'active');
      expect(u.role, 'user');
    });
  });

  group('ChannelItem - real API shape', () {
    test('parses channel', () {
      final c = ChannelItem.fromJson({
        'id': 5,
        'name': 'hwy',
        'description': '华为云',
        'status': 'active',
        'group_ids': [14],
        'created_at': '2026-06-14T19:51:52Z',
      });
      expect(c.id, 5);
      expect(c.name, 'hwy');
      expect(c.description, '华为云');
      expect(c.status, 'active');
      expect(c.groupNames, ['14']);
    });
  });

  group('RequestLog - real API shape', () {
    test('parses request log entry', () {
      final l = RequestLog.fromJson({
        'kind': 'success',
        'created_at': '2026-08-20T15:37:46.168681+08:00',
        'platform': 'openai',
        'model': 'deepseek-v4-flash',
        'duration_ms': 3883,
        'user_id': 1,
        'api_key_id': 84,
        'account_id': 129,
        'group_id': 26,
        'stream': true,
      });
      expect(l.kind, 'success');
      expect(l.model, 'deepseek-v4-flash');
      expect(l.durationMs, 3883);
      expect(l.userId, 1);
    });
  });

  profTests();
}

void profTests() {
  group('RealtimeTraffic - real API shape', () {
    test('parses qps/tps', () {
      final rt = RealtimeTraffic.fromJson({
        'enabled': true,
        'summary': {
          'window': '1min',
          'qps': {'current': 0.1, 'peak': 0.1, 'avg': 0.1},
          'tps': {'current': 14510, 'peak': 8966.1, 'avg': 14510},
        },
      });
      expect(rt.window, '1min');
      expect(rt.qpsCurrent, closeTo(0.1, 0.001));
      expect(rt.tpsCurrent, closeTo(14510, 0.1));
      expect(rt.tpsPeak, closeTo(8966.1, 0.1));
    });
  });

  group('ThroughputPoint', () {
    test('parses per-minute bucket', () {
      final p = ThroughputPoint.fromJson({
        'bucket_start': '2026-08-20T07:36:00Z',
        'request_count': 6,
        'token_consumed': 52786,
        'switch_count': 0,
        'qps': 0.1,
        'tps': 879.8,
      });
      expect(p.requestCount, 6);
      expect(p.tokenConsumed, closeTo(52786, 1));
      expect(p.tps, closeTo(879.8, 0.1));
    });
  });

  group('UsageRecord - full detail', () {
    test('parses full record', () {
      final u = UsageRecord.fromJson({
        'id': 55307,
        'user_id': 1,
        'api_key_id': 84,
        'account_id': 129,
        'request_id': 'client:b8efce3a',
        'model': 'deepseek-v4-flash',
        'upstream_model': 'deepseek-v4-flash',
        'group_id': 26,
        'inbound_endpoint': '/v1/chat/completions',
        'input_tokens': 1685,
        'output_tokens': 1171,
        'cache_creation_tokens': 0,
        'cache_read_tokens': 186112,
        'input_cost': 0.0002359,
        'output_cost': 0.00032788,
        'cache_creation_cost': 0,
        'cache_read_cost': 0.0005211136,
        'total_cost': 0.0010848936,
        'actual_cost': 0.0010848936,
        'rate_multiplier': 1,
        'billing_mode': 'token',
        'duration_ms': 19081,
        'first_token_ms': 1886,
        'request_type': 'stream',
        'stream': true,
        'created_at': '2026-08-20T16:35:07Z',
        'user': {'email': 'user@example.com', 'id': 1},
        'api_key': {'id': 84, 'key': 'sk-xxx', 'name': 'demo-key', 'status': 'active', 'quota': 0, 'quota_used': 0, 'current_concurrency': 0},
        'account': {'name': 'demo-group'},
        'group': {'name': 'demo-group'},
      });
      expect(u.inputTokens, 1685);
      expect(u.outputTokens, 1171);
      expect(u.cacheReadTokens, 186112);
      expect(u.totalTokens, 1685 + 1171 + 186112);
      expect(u.totalCost, closeTo(0.0010848936, 1e-9));
      expect(u.firstTokenMs, 1886);
      expect(u.userEmail, 'user@example.com');
      expect(u.apiKey!.name, 'demo-key');
      expect(u.accountName, 'demo-group');
    });
  });
}
