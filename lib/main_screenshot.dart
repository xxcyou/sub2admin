import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'screenshot/fake_api_client.dart';
import 'screens/home_shell.dart';
import 'services/api_client.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/liquid.dart';

/// Screenshot-only entrypoint.
///
/// Build with:
///   flutter build apk --release -t lib/main_screenshot.dart --target-platform android-arm64
///
/// It starts HomeShell with deterministic demo data and hides system UI. It
/// automatically visits every tab and saves a 1200x2608 PNG under the app cache
/// directory (`cache/shots/`), so screenshots never depend on adb taps and are
/// clean full-screen captures with real Chinese fonts and no real data.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const Sub2AdminScreenshotApp());
}

class Sub2AdminScreenshotApp extends StatelessWidget {
  const Sub2AdminScreenshotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final state = AppState(restorePrefs: false);
        state.config = AdminConfig(baseUrl: 'https://demo.example.com', apiKey: 'demo-admin-key');
        state.client = FakeApiClient();
        state.hasSession = true;
        state.setDynamicSeed(const Color(0xFF14B8A6));
        return state;
      },
      child: const _ScreenshotRoot(),
    );
  }
}

class _ScreenshotRoot extends StatelessWidget {
  const _ScreenshotRoot();

  @override
  Widget build(BuildContext context) {
    final palette = buildPaletteFromSeed(const Color(0xFF14B8A6));

    return MaterialApp(
      title: 'Sub2API Admin Screenshot',
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
      home: const _ShotRunner(),
    );
  }
}

class _ShotRunner extends StatefulWidget {
  const _ShotRunner();

  @override
  State<_ShotRunner> createState() => _ShotRunnerState();
}

class _ShotRunnerState extends State<_ShotRunner> {
  static const _names = [
    '01_dashboard',
    '02_keys',
    '03_users',
    '04_channels',
    '05_logs',
    '06_settings',
  ];

  final GlobalKey _boundaryKey = GlobalKey();
  int _tab = 0;
  String _status = '准备截图…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final dirs = <String>[];
    try {
      final cache = await getApplicationCacheDirectory();
      dirs.add('${cache.path}/shots');
      dirs.firstWhere((d) => true);
      Directory(dirs.last).createSync(recursive: true);
    } catch (_) {}

    // External app dir is normally writable and may be pulled via adb/MCP.
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) dirs.add('${ext.path}/shots');
    } catch (_) {}

    // Public Download folder is easiest to pull via adb shell when permitted.
    try {
      final public = Directory('/sdcard/Download/sub2admin_shots')..createSync(recursive: true);
      dirs.add(public.path);
    } catch (_) {}

    final uniqueDirs = <String>{...dirs}.toList();
    for (var i = 0; i < _names.length; i++) {
      setState(() {
        _tab = i;
        _status = '正在截取 ${_names[i]}';
      });
      await Future<void>.delayed(const Duration(seconds: 4));
      for (final d in uniqueDirs) {
        await _capture('$d/${_names[i]}.png');
      }
    }
    if (mounted) {
      setState(() => _status = '完成：${uniqueDirs.join(', ')}');
    }
  }

  Future<void> _capture(String path) async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      await File(path).writeAsBytes(data.buffer.asUint8List());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RepaintBoundary(
          key: _boundaryKey,
          child: HomeShell(key: ValueKey<int>(_tab), initialIndex: _tab),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_status, style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ),
      ],
    );
  }
}
