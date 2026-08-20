import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/liquid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Sub2AdminApp());
}

class Sub2AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ov = state.seedOverride;
    final palette = (ov != null && ov != state.theme.lightSeed)
        ? buildPaletteFromSeed(ov)
        : buildPalette(state.theme);

    return MaterialApp(
      title: 'Sub2API Admin',
      debugShowCheckedModeBanner: false,
      theme: palette.light,
      darkTheme: palette.dark,
      themeMode: state.themeMode,
      builder: (context, child) => LiquidBackdrop(
        base: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF080B16)
            : const Color(0xFFF4F6FF),
        glowA: state.glowA,
        glowB: state.glowB,
        child: child,
      ),
      home: state.hasSession ? const HomeShell() : const LoginScreen(),
    );
  }
}
