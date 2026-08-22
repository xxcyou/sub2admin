import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sub2admin/screens/home_shell.dart';
import 'package:sub2admin/services/api_client.dart';
import 'package:sub2admin/services/app_state.dart';
import 'package:sub2admin/theme/app_theme.dart';
import 'package:sub2admin/theme/liquid.dart';

/// Fake API client that returns deterministic demo data for every screen.
class FakeApiClient extends ApiClient {
  FakeApiClient()
      : super(AdminConfig(baseUrl: 'https://demo.example.com', apiKey: 'demo-admin-key'));

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == 'dashboard/snapshot-v2') return _snapshot;
    if (path == 'dashboard/models') return _models;
    if (path == 'dashboard/groups') return _groups;
    if (path == 'dashboard/trend') return _trend;
    if (path == 'dashboard/users-ranking') return _ranking;
    if (path == 'ops/realtime-traffic') return _realtime;
    if (path == 'ops/dashboard/throughput-trend') return _throughput;
    if (path == 'ops/dashboard/latency-histogram') return _latency;
    if (path == 'users') return _users;
    if (path.startsWith('users/') && path.endsWith('/api-keys')) return _apiKeys;
    if (path == 'channels') return _channels;
    if (path == 'ops/requests') return _requests;
    if (path == 'usage') return _usage;
    if (path == 'usage/search-api-keys') return _searchKeys;
    if (path == 'dashboard/api-keys-trend') return _keyTrend;
    if (path.startsWith('ops/dashboard/overview')) return _overview;
    if (path == 'channels/1') return _channels['items'][0];
    return <String, dynamic>{'items': <dynamic>[], 'total': 0};
  }

  @override
  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query}) async {
    if (path == 'dashboard/api-keys-usage') return _keyUsage;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query}) async {
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) async {
    return <String, dynamic>{};
  }

  static const _snapshot = <String, dynamic>{
    'stats': <String, dynamic>{
      'total_users': 128,
      'today_new_users': 12,
      'active_users': 86,
      'hourly_active_users': 34,
      'total_api_keys': 256,
      'active_api_keys': 210,
      'total_accounts': 7,
      'normal_accounts': 6,
      'error_accounts': 0,
      'ratelimit_accounts': 1,
      'overload_accounts': 0,
      'total_requests': 1250000,
      'today_requests': 15420,
      'total_tokens': 5800000000,
      'total_cost': 5600,
      'total_actual_cost': 4008.90,
      'today_cost': 34.50,
      'today_input_tokens': 8100000,
      'today_output_tokens': 5900000,
      'average_duration_ms': 620,
    },
  };

  static const _models = <String, dynamic>{
    'models': <dynamic>[
      <String, dynamic>{'model': 'GPT-4o', 'requests': 38500, 'total_tokens': 120000000, 'cost': 180.0, 'actual_cost': 145.2},
      <String, dynamic>{'model': 'DeepSeek-V3', 'requests': 41200, 'total_tokens': 256000000, 'cost': 220.0, 'actual_cost': 198.5},
      <String, dynamic>{'model': 'Claude-3.5', 'requests': 9800, 'total_tokens': 36000000, 'cost': 96.0, 'actual_cost': 88.0},
    ],
  };

  static const _groups = <String, dynamic>{
    'groups': <dynamic>[
      <String, dynamic>{'group_name': '默认分组', 'requests': 500000, 'total_tokens': 2000000000, 'cost': 1000.0, 'actual_cost': 800.0},
      <String, dynamic>{'group_name': 'VIP', 'requests': 300000, 'total_tokens': 1200000000, 'cost': 800.0, 'actual_cost': 640.0},
    ],
  };

  static const _trend = <String, dynamic>{
    'trend': <dynamic>[
      <String, dynamic>{'date': '2025-08-10', 'requests': 11000, 'total_tokens': 160000000, 'cost': 38.0},
      <String, dynamic>{'date': '2025-08-11', 'requests': 13200, 'total_tokens': 185000000, 'cost': 44.0},
      <String, dynamic>{'date': '2025-08-12', 'requests': 12800, 'total_tokens': 178000000, 'cost': 42.5},
      <String, dynamic>{'date': '2025-08-13', 'requests': 14600, 'total_tokens': 220000000, 'cost': 51.0},
      <String, dynamic>{'date': '2025-08-14', 'requests': 15100, 'total_tokens': 235000000, 'cost': 55.0},
      <String, dynamic>{'date': '2025-08-15', 'requests': 14900, 'total_tokens': 228000000, 'cost': 53.0},
      <String, dynamic>{'date': '2025-08-16', 'requests': 15420, 'total_tokens': 240000000, 'cost': 56.0},
    ],
  };

  static const _ranking = <String, dynamic>{
    'ranking': <dynamic>[
      <String, dynamic>{'user_id': 1, 'email': 'alpha@example.com', 'username': 'alpha', 'actual_cost': 500.0, 'requests': 100000, 'tokens': 100000000},
      <String, dynamic>{'user_id': 2, 'email': 'beta@example.com', 'username': 'beta', 'actual_cost': 320.0, 'requests': 68000, 'tokens': 65000000},
      <String, dynamic>{'user_id': 3, 'email': 'gamma@example.com', 'username': 'gamma', 'actual_cost': 180.0, 'requests': 42000, 'tokens': 45000000},
    ],
  };

  static const _realtime = <String, dynamic>{
    'summary': <String, dynamic>{
      'enabled': true,
      'window': '1m',
      'qps': <String, dynamic>{'current': 3.2, 'peak': 6.8, 'avg': 2.4},
      'tps': <String, dynamic>{'current': 15320, 'peak': 32000, 'avg': 18000},
    },
    'timestamp': '2025-08-16T12:00:00Z',
  };

  static Map<String, dynamic> get _throughput {
    final points = <dynamic>[];
    final now = DateTime.utc(2025, 8, 16, 12);
    for (var i = 0; i < 30; i++) {
      final tps = 8000 + ((i * 137) % 9000);
      final qps = (i * 13) % 40;
      points.add(<String, dynamic>{
        'bucket_start': now.add(Duration(minutes: i)).toIso8601String(),
        'request_count': 200 + i * 11,
        'token_consumed': tps * 1200,
        'switch_count': 0,
        'qps': qps.toDouble(),
        'tps': tps.toDouble(),
      });
    }
    return <String, dynamic>{'points': points};
  }

  static const _latency = <String, dynamic>{
    'total_requests': 15420,
    'buckets': <dynamic>[
      <String, dynamic>{'range': '<500ms', 'count': 12000},
      <String, dynamic>{'range': '500-1s', 'count': 3000},
      <String, dynamic>{'range': '1-2s', 'count': 300},
      <String, dynamic>{'range': '>2s', 'count': 120},
    ],
  };

  static const _users = <String, dynamic>{
    'items': <dynamic>[
      <String, dynamic>{'id': 1, 'email': 'alpha@example.com', 'username': 'alpha', 'role': 'user', 'balance': 12.34, 'frozen_balance': 0, 'concurrency': 1, 'status': 'active', 'created_at': '2025-01-01T00:00:00Z', 'last_active_at': '2025-08-16T12:00:00Z', 'notes': ''},
      <String, dynamic>{'id': 2, 'email': 'beta@example.com', 'username': 'beta', 'role': 'user', 'balance': 5.20, 'frozen_balance': 0.5, 'concurrency': 2, 'status': 'active', 'created_at': '2025-01-05T00:00:00Z', 'last_active_at': '2025-08-16T10:30:00Z', 'notes': ''},
      <String, dynamic>{'id': 3, 'email': 'gamma@example.com', 'username': 'gamma', 'role': 'user', 'balance': 1.80, 'frozen_balance': 0, 'concurrency': 1, 'status': 'disabled', 'created_at': '2025-02-01T00:00:00Z', 'last_active_at': '2025-08-10T08:00:00Z', 'notes': ''},
    ],
    'total': 3,
  };

  static const _channels = <String, dynamic>{
    'items': <dynamic>[
      <String, dynamic>{'id': 1, 'name': 'OpenAI 官方', 'description': 'GPT-4o / GPT-4.1 主通道', 'status': 'active', 'group_ids': <dynamic>['默认', 'VIP'], 'created_at': '2025-01-01T00:00:00Z'},
      <String, dynamic>{'id': 2, 'name': 'DeepSeek 直连', 'description': 'V3 / R1 高速通道', 'status': 'active', 'group_ids': <dynamic>['默认'], 'created_at': '2025-02-01T00:00:00Z'},
      <String, dynamic>{'id': 3, 'name': 'Claude 中转', 'description': '备用通道', 'status': 'disabled', 'group_ids': <dynamic>['VIP'], 'created_at': '2025-03-01T00:00:00Z'},
    ],
    'total': 3,
  };

  static const _requests = <String, dynamic>{
    'items': <dynamic>[
      <String, dynamic>{'kind': 'chat', 'created_at': '2025-08-16T11:59:58Z', 'platform': 'api', 'model': 'gpt-4o', 'duration_ms': 512, 'user_id': 1, 'api_key_id': 101, 'stream': true},
      <String, dynamic>{'kind': 'chat', 'created_at': '2025-08-16T11:58:40Z', 'platform': 'web', 'model': 'deepseek-v3', 'duration_ms': 820, 'user_id': 2, 'api_key_id': 102, 'stream': true},
      <String, dynamic>{'kind': 'chat', 'created_at': '2025-08-16T11:57:21Z', 'platform': 'api', 'model': 'claude-3-5-sonnet', 'duration_ms': 360, 'user_id': 3, 'api_key_id': 103, 'stream': false},
    ],
    'total': 120,
  };

  static const _usage = <String, dynamic>{
    'items': <dynamic>[
      <String, dynamic>{'id': 9001, 'user_id': 1, 'api_key_id': 101, 'account_id': 7, 'request_id': 'req_demo_0001', 'model': 'gpt-4o', 'upstream_model': 'gpt-4o', 'group_id': 1, 'inbound_endpoint': '/v1/chat/completions', 'upstream_endpoint': '/v1/chat/completions', 'input_tokens': 1200, 'output_tokens': 800, 'cache_creation_tokens': 0, 'cache_read_tokens': 200, 'input_cost': 0.006, 'output_cost': 0.012, 'cache_creation_cost': 0, 'cache_read_cost': 0.0002, 'total_cost': 0.0182, 'actual_cost': 0.0182, 'rate_multiplier': 1, 'billing_mode': 'per-token', 'billing_type': 1, 'duration_ms': 512, 'first_token_ms': 80, 'request_type': 'chat.completion', 'stream': true, 'image_count': 0, 'image_input_tokens': 0, 'image_output_tokens': 0, 'ip_address': '203.0.113.10', 'user_agent': 'OpenAI/Node 1.0', 'created_at': '2025-08-16T11:59:58Z', 'user': <String, dynamic>{'email': 'alpha@example.com'}, 'api_key': <String, dynamic>{'id': 101, 'key': 'sk-demo-****', 'name': '生产环境', 'status': 'active', 'group_id': 1, 'quota': 1000000, 'quota_used': 345000, 'expires_at': '2026-01-01T00:00:00Z', 'last_used_at': '2025-08-16T11:59:58Z', 'current_concurrency': 1}},
    ],
    'total': 1,
  };

  static const _searchKeys = <dynamic>[
    <String, dynamic>{'id': 101, 'name': '生产环境', 'user_id': 1},
    <String, dynamic>{'id': 102, 'name': '测试环境', 'user_id': 2},
    <String, dynamic>{'id': 103, 'name': 'Demo Key', 'user_id': 3},
  ];

  static const _keyUsage = <String, dynamic>{
    'stats': <String, dynamic>{
      '101': <String, dynamic>{'api_key_id': 101, 'today_actual_cost': 12.34, 'total_actual_cost': 567.80},
      '102': <String, dynamic>{'api_key_id': 102, 'today_actual_cost': 3.56, 'total_actual_cost': 120.40},
      '103': <String, dynamic>{'api_key_id': 103, 'today_actual_cost': 0.21, 'total_actual_cost': 45.60},
    },
  };

  static const _keyTrend = <String, dynamic>{
    'trend': <dynamic>[
      <String, dynamic>{'date': '2025-08-10', 'api_key_id': 101, 'key_name': '生产环境', 'requests': 1200, 'tokens': 4500000},
      <String, dynamic>{'date': '2025-08-11', 'api_key_id': 101, 'key_name': '生产环境', 'requests': 1400, 'tokens': 5200000},
      <String, dynamic>{'date': '2025-08-12', 'api_key_id': 101, 'key_name': '生产环境', 'requests': 1350, 'tokens': 4900000},
      <String, dynamic>{'date': '2025-08-13', 'api_key_id': 101, 'key_name': '生产环境', 'requests': 1580, 'tokens': 6100000},
      <String, dynamic>{'date': '2025-08-14', 'api_key_id': 101, 'key_name': '生产环境', 'requests': 1500, 'tokens': 5800000},
      <String, dynamic>{'date': '2025-08-15', 'api_key_id': 101, 'key_name': '生产环境', 'requests': 1620, 'tokens': 6300000},
      <String, dynamic>{'date': '2025-08-16', 'api_key_id': 101, 'key_name': '生产环境', 'requests': 1700, 'tokens': 6800000},
    ],
  };

  static const _apiKeys = <String, dynamic>{
    'items': <dynamic>[
      <String, dynamic>{'id': 101, 'user_id': 1, 'key': 'sk-demo-****EXAMPLEDEMO****', 'name': '生产环境', 'group_id': 1, 'status': 'active', 'quota': 1000000, 'quota_used': 345000, 'expires_at': '2026-01-01T00:00:00Z', 'created_at': '2025-01-01T00:00:00Z', 'last_used_at': '2025-08-16T12:00:00Z', 'last_used_ip': '203.0.113.10', 'rate_limit_5h': 10000, 'rate_limit_1d': 50000, 'rate_limit_7d': 300000, 'usage_5h': 1234, 'usage_1d': 5678, 'usage_7d': 34567, 'current_concurrency': 3, 'ip_whitelist': '', 'ip_blacklist': '', 'user': <String, dynamic>{'id': 1, 'email': 'alpha@example.com', 'username': 'alpha', 'role': 'user', 'status': 'active'}, 'group': <String, dynamic>{'id': 1, 'name': '默认', 'description': '', 'platform': 'openai', 'status': 'active'}},
      <String, dynamic>{'id': 102, 'user_id': 2, 'key': 'sk-demo-****SECONDKEY****', 'name': '测试环境', 'group_id': 1, 'status': 'active', 'quota': 100000, 'quota_used': 20000, 'expires_at': '2026-01-01T00:00:00Z', 'created_at': '2025-02-01T00:00:00Z', 'last_used_at': '2025-08-16T09:00:00Z', 'last_used_ip': '203.0.113.20', 'rate_limit_5h': 1000, 'rate_limit_1d': 5000, 'rate_limit_7d': 30000, 'usage_5h': 100, 'usage_1d': 400, 'usage_7d': 2500, 'current_concurrency': 1, 'ip_whitelist': '', 'ip_blacklist': '', 'user': <String, dynamic>{'id': 2, 'email': 'beta@example.com', 'username': 'beta', 'role': 'user', 'status': 'active'}, 'group': <String, dynamic>{'id': 1, 'name': '默认', 'description': '', 'platform': 'openai', 'status': 'active'}},
    ],
    'total': 2,
  };

  static const _overview = <String, dynamic>{
    'cpu': '12%',
    'memory': '45%',
    'disk': '33%',
  };
}

Future<void> pumpShell(WidgetTester tester, AppState state) async {
  final palette = buildPaletteFromSeed(const Color(0xFF14B8A6));
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: palette.light,
        darkTheme: palette.dark,
        themeMode: ThemeMode.light,
        builder: (context, child) => LiquidBackdrop(
          base: const Color(0xFFF4F6FF),
          glowA: const Color(0xFF14B8A6),
          glowB: const Color(0xFF6C4DF6),
          child: child,
        ),
        home: const HomeShell(),
      ),
    ),
  );
}

Future<void> settleShell(WidgetTester tester) async {
  // LiquidBackdrop runs a continuous fluid animation, so pumpAndSettle would
  // time out. Pump fixed-duration frames instead and let async loads finish.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

AppState buildState() {
  final cfg = AdminConfig(baseUrl: 'https://demo.example.com', apiKey: 'demo-admin-key');
  final state = AppState();
  state.config = cfg;
  state.client = FakeApiClient();
  state.hasSession = true;
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('generate clean full-screen UI screenshots', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    tester.view.physicalSize = const Size(1200, 2608);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final state = buildState();
    await pumpShell(tester, state);
    await settleShell(tester);

    await expectLater(find.byType(HomeShell), matchesGoldenFile('../test/goldens/01_dashboard.png'));

    await tester.tap(find.text('密钥'));
    await settleShell(tester);
    await expectLater(find.byType(HomeShell), matchesGoldenFile('../test/goldens/02_keys.png'));

    await tester.tap(find.text('用户'));
    await settleShell(tester);
    await expectLater(find.byType(HomeShell), matchesGoldenFile('../test/goldens/03_users.png'));

    await tester.tap(find.text('渠道'));
    await settleShell(tester);
    await expectLater(find.byType(HomeShell), matchesGoldenFile('../test/goldens/04_channels.png'));

    await tester.tap(find.text('日志'));
    await settleShell(tester);
    await expectLater(find.byType(HomeShell), matchesGoldenFile('../test/goldens/05_logs.png'));

    await tester.tap(find.text('设置'));
    await settleShell(tester);
    await expectLater(find.byType(HomeShell), matchesGoldenFile('../test/goldens/06_settings.png'));

    // Scroll settings to the theme section and capture the dynamic theme block.
    await tester.drag(find.byType(HomeShell), const Offset(0, -900));
    await settleShell(tester);
    await expectLater(find.byType(HomeShell), matchesGoldenFile('../test/goldens/07_settings_theme.png'));

    // Dispose the shell so periodic timers do not leak.
    await tester.pumpWidget(const SizedBox());
  });
}
