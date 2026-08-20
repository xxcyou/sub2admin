import 'package:flutter/material.dart';

/// Modern multi-theme system for the Sub2API Admin panel.
///
/// Provides a set of curated color schemes (themes) that can be switched
/// at runtime, each with its own light & dark variants plus an accent color.
class AppTheme {
  final String id;
  final String name;
  final Color lightSeed;
  final Color darkSeed;
  final Color accent;

  const AppTheme({
    required this.id,
    required this.name,
    required this.lightSeed,
    required this.darkSeed,
    required this.accent,
  });
}

/// All available themes (curated, modern & beautiful).
const List<AppTheme> kThemes = [
  AppTheme(
    id: 'aurora',
    name: '极光紫',
    lightSeed: Color(0xFF6C4DF6),
    darkSeed: Color(0xFF8B7BFF),
    accent: Color(0xFF00E5FF),
  ),
  AppTheme(
    id: 'ocean',
    name: '深海蓝',
    lightSeed: Color(0xFF1565C0),
    darkSeed: Color(0xFF4FC3F7),
    accent: Color(0xFF00B0FF),
  ),
  AppTheme(
    id: 'emerald',
    name: '翡翠绿',
    lightSeed: Color(0xFF00897B),
    darkSeed: Color(0xFF26E0C7),
    accent: Color(0xFF69F0AE),
  ),
  AppTheme(
    id: 'sunset',
    name: '日落橙',
    lightSeed: Color(0xFFFF7043),
    darkSeed: Color(0xFFFFAB91),
    accent: Color(0xFFFFD740),
  ),
  AppTheme(
    id: 'rose',
    name: '胭脂粉',
    lightSeed: Color(0xFFE91E63),
    darkSeed: Color(0xFFF48FB1),
    accent: Color(0xFFFF80AB),
  ),
  AppTheme(
    id: 'graphite',
    name: '石墨灰',
    lightSeed: Color(0xFF455A64),
    darkSeed: Color(0xFFB0BEC5),
    accent: Color(0xFF80CBC4),
  ),
];

class AppThemePalette {
  final ThemeData light;
  final ThemeData dark;
  final Color accent;

  const AppThemePalette({required this.light, required this.dark, required this.accent});

  ThemeData of({required Brightness brightness}) =>
      brightness == Brightness.dark ? dark : light;
}

/// Build a full Material 3 theme palette from an AppTheme.
AppThemePalette buildPalette(AppTheme theme) {
  final lightScheme = ColorScheme.fromSeed(
    seedColor: theme.lightSeed,
    brightness: Brightness.light,
    surface: Colors.white,
  );
  final darkScheme = ColorScheme.fromSeed(
    seedColor: theme.darkSeed,
    brightness: Brightness.dark,
  );

  const radius = 20.0;

  ThemeData build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 15),
        subtitleTextStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.3), thickness: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 19, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? scheme.inverseSurface : scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest),
      ),
    );
  }

  return AppThemePalette(light: build(lightScheme), dark: build(darkScheme), accent: theme.accent);
}

/// Build a full Material 3 palette from an arbitrary seed color (light variant)
/// plus a dark seed. Used for the **dynamic theme**: capturing the site's brand
/// color or letting the user pick a color at runtime.
AppThemePalette buildPaletteFromSeed(Color seed, {Color? darkSeed, Color? accent}) {
  final lightSeed = HSLColor.fromColor(seed).withLightness(0.5).toColor();
  final useDark = darkSeed ?? HSLColor.fromColor(seed).withLightness(0.7).withSaturation(0.72).toColor();
  final acc = accent ?? HSLColor.fromColor(seed).withHue((HSLColor.fromColor(seed).hue + 24) % 360).toColor();

  final lightScheme = ColorScheme.fromSeed(
    seedColor: lightSeed,
    brightness: Brightness.light,
    surface: Colors.white,
  );
  final darkScheme = ColorScheme.fromSeed(
    seedColor: useDark,
    brightness: Brightness.dark,
  );

  // reuse the same component styling as buildPalette
  final radius = 20.0;

  ThemeData build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.35 : 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600, fontSize: 15),
        subtitleTextStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.3), thickness: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 19, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest),
      ),
    );
  }

  return AppThemePalette(light: build(lightScheme), dark: build(darkScheme), accent: acc);
}

/// A fixed set of premium "liquid" gradient presets for the dynamic theme
/// picker (each maps to a base seed color).
class LiquidPalette {
  final String id;
  final String name;
  final Color seed;
  final Color glowA;
  final Color glowB;
  const LiquidPalette({
    required this.id,
    required this.name,
    required this.seed,
    required this.glowA,
    required this.glowB,
  });
}

const List<LiquidPalette> kLiquidPalettes = [
  LiquidPalette(id: 'aurora', name: '极光紫', seed: Color(0xFF6C4DF6), glowA: Color(0xFF8B5CF6), glowB: Color(0xFF06B6D4)),
  LiquidPalette(id: 'ocean', name: '深海蓝', seed: Color(0xFF1565C0), glowA: Color(0xFF3B82F6), glowB: Color(0xFF06B6D4)),
  LiquidPalette(id: 'teal', name: '青碧 (站点)', seed: Color(0xFF0D9488), glowA: Color(0xFF14B8A6), glowB: Color(0xFF2DD4BF)),
  LiquidPalette(id: 'sunset', name: '日落橙', seed: Color(0xFFEA580C), glowA: Color(0xFFF97316), glowB: Color(0xFFFBBF24)),
  LiquidPalette(id: 'rose', name: '胭脂粉', seed: Color(0xFFE11D48), glowA: Color(0xFFEC4899), glowB: Color(0xFFF472B6)),
  LiquidPalette(id: 'graphite', name: '石墨青', seed: Color(0xFF334155), glowA: Color(0xFF64748B), glowB: Color(0xFF14B8A6)),
];
