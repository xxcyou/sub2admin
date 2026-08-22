import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'api_client.dart';

/// Global app state: auth config, selected theme, brightness and API client.
class AppState extends ChangeNotifier {
  AdminConfig? config;
  ApiClient? client;
  bool hasSession = false;

  AppTheme _theme = kThemes.first;
  ThemeMode _themeMode = ThemeMode.system;
  bool _cacheTheme = false;
  String _themeId = kThemes.first.id;
  Brightness? _forcedBrightness;
  Color? _seedOverride; // dynamic theme: captured site brand / user picker
  Color _glowA = const Color(0xFF6C4DF6);
  Color _glowB = const Color(0xFF06B6D4);
  Color _accent = const Color(0xFF00E5FF);

  AppState({bool restorePrefs = true}) {
    if (restorePrefs) {
      _restorePrefs();
    }
  }

  AppTheme get theme => _theme;
  ThemeMode get themeMode => _themeMode;
  bool get cacheTheme => _cacheTheme;
  Color? get seedOverride => _seedOverride;
  Color get glowA => _glowA;
  Color get glowB => _glowB;
  Color get accentColor => _accent;

  /// Primary seed used to build the active palette:
  /// a dynamic override (captured/picked) wins, else the theme's built-in seed.
  Color get activeSeed {
    if (_seedOverride != null) return _seedOverride!;
    return _theme.lightSeed;
  }

  /// Apply a dynamic theme from an arbitrary seed color (site brand or picked).
  Future<void> setDynamicSeed(Color seed, {Color? glowA, Color? glowB, Color? accent}) async {
    _seedOverride = seed;
    if (glowA != null) _glowA = glowA;
    if (glowB != null) _glowB = glowB;
    if (accent != null) _accent = accent;
    notifyListeners();
  }

  /// Reset back to the built-in preset theme.
  Future<void> clearDynamicSeed() async {
    _seedOverride = null;
    notifyListeners();
  }
  Brightness get effectiveBrightness =>
      _forcedBrightness ?? (_themeMode == ThemeMode.dark
          ? Brightness.dark
          : _themeMode == ThemeMode.light
              ? Brightness.light
              : Brightness.light);

  Future<void> _restorePrefs() async {
    config = await AdminConfig.load();
    hasSession = config != null;
    if (config != null) {
      client = ApiClient(config!);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeId = prefs.getString('theme_id') ?? kThemes.first.id;
      _theme = kThemes.firstWhere((t) => t.id == _themeId, orElse: () => kThemes.first);
      final mode = prefs.getString('theme_mode') ?? 'system';
      _themeMode = mode == 'light'
          ? ThemeMode.light
          : mode == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setTheme(AppTheme t) async {
    _theme = t;
    _themeId = t.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_id', t.id);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', m == ThemeMode.light
        ? 'light'
        : m == ThemeMode.dark
            ? 'dark'
            : 'system');
    notifyListeners();
  }

  Future<void> setBrightnessOverride(Brightness? b) async {
    _forcedBrightness = b;
    notifyListeners();
  }

  /// Save a new session (base URL + admin key) and instantiate the client.
  Future<void> login(String base, String key) async {
    final cfg = AdminConfig(baseUrl: base, apiKey: key);
    await cfg.save();
    config = cfg;
    client = ApiClient(cfg);
    hasSession = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await config?.clear();
    client?.close();
    config = null;
    client = null;
    hasSession = false;
    notifyListeners();
  }

  /// Fetch the admin site's frontend CSS and heuristically extract its brand
  /// color, then apply it as the dynamic theme seed.
  Future<Color?> captureSiteBrandColor() async {
    try {
      final base = config?.baseUrl ?? '';
      if (base.isEmpty) return null;
      final root = await http.get(Uri.parse(base)).timeout(const Duration(seconds: 10));
      final html = root.body;
      final cssMatch = RegExp(r'assets/[A-Za-z0-9_.-]+\.css').firstMatch(html);
      if (cssMatch == null) return null;
      final cssUrl = '$base/${cssMatch.group(0)}';
      final css = await http.get(Uri.parse(cssUrl)).timeout(const Duration(seconds: 10));
      final colors = RegExp(r'#([0-9a-fA-F]{6})').allMatches(css.body).map((m) => m.group(1)!.toUpperCase()).toList();
      if (colors.isEmpty) return null;

      // Score each color: saturated/medium-bright colors are likely brand accents.
      String? best;
      double bestScore = -1;
      for (final c in colors) {
        final rgb = Color(int.parse('FF$c', radix: 16));
        final hsl = HSLColor.fromColor(rgb);
        // avoid pure gray/black/white, prefer mid-brightness saturated hues
        if (hsl.saturation < 0.25) continue;
        if (hsl.lightness < 0.12 || hsl.lightness > 0.9) continue;
        final score = hsl.saturation * 0.6 + (0.5 - (hsl.lightness - 0.5).abs()) * 0.4 + colors.where((x) => x == c).length * 0.01;
        if (score > bestScore) {
          bestScore = score;
          best = c;
        }
      }
      if (best == null) return null;
      await setDynamicSeed(Color(int.parse('FF$best', radix: 16)));
      return _seedOverride;
    } catch (_) {
      return null;
    }
  }

  /// Apply one of the curated liquid palettes (reset dynamic seed or set it).
  Future<void> applyLiquidPalette(LiquidPalette p) async {
    await setDynamicSeed(p.seed, glowA: p.glowA, glowB: p.glowB);
  }

  ApiClient get api {
    final c = client;
    if (c == null) {
      throw ApiException('尚未登录');
    }
    return c;
  }
}
