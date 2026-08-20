import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// ============================================================
///  Liquid Glass (流动玻璃) design system
///  Frosted-glass cards, an animated flowing gradient backdrop,
///  and a floating glass bottom navigation — the current trend.
/// ============================================================

/// Animated flowing gradient background. Slow, smooth drift.
class LiquidBackdrop extends StatefulWidget {
  final Widget? child;
  final Color base;
  final Color glowA;
  final Color glowB;
  final bool animated;
  const LiquidBackdrop({
    super.key,
    this.child,
    this.base = const Color(0xFF0B1020),
    this.glowA = const Color(0xFF4F46E5),
    this.glowB = const Color(0xFF06B6D4),
    this.animated = true,
  });

  @override
  State<LiquidBackdrop> createState() => _LiquidBackdropState();
}

class _LiquidBackdropState extends State<LiquidBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = widget.animated ? _c.value : 0.0;
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.4,
                  colors: [
                    widget.base,
                    widget.base,
                    _shift(widget.glowA, t),
                    _shift(widget.glowB, t + 0.5),
                  ],
                  stops: const [0.0, 0.5, 0.75, 1.0],
                  center: Alignment(
                    math.cos(t * 2 * math.pi) * 0.6,
                    math.sin(t * 2 * math.pi) * 0.6,
                  ),
                ),
              ),
            );
          },
        ),
        // soft large blur blobs for a "liquid" feel
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = widget.animated ? _c.value : 0.0;
            return Stack(
              children: [
                _blob(widget.glowA, .5 + .25 * math.sin(t * 2 * math.pi),
                    Alignment(-1.1, -1.1), 0.9),
                _blob(widget.glowB, .5 + .25 * math.cos(t * 2 * math.pi),
                    Alignment(1.2, 1.0), 1.0),
              ],
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }

  Widget _blob(Color c, double alpha, Alignment align, double scale) {
    return Align(
      alignment: align,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 380,
          height: 380,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [c.withValues(alpha: alpha), c.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }

  static Color _shift(Color c, double t) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withHue((hsl.hue + t * 28) % 360).toColor();
  }
}

/// Frosted-glass container: blurs whatever is behind it and tints it.
class GlassCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final Color tint;
  final double blur;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final Color? borderColor;
  const GlassCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.tint = const Color(0x14FFFFFF),
    this.blur = 18,
    this.border,
    this.boxShadow,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTint = tint == const Color(0x14FFFFFF)
        ? (isDark ? const Color(0x1AFFFFFF) : const Color(0x9EFFFFFF))
        : tint;
    final effBorder = border ??
        Border.all(
          color: borderColor ??
              (isDark ? const Color(0x28FFFFFF) : const Color(0x2EFFFFFF)),
          width: 1,
        );
    final content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: effectiveTint,
            borderRadius: borderRadius,
            border: effBorder,
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

/// Floating glass bottom navigation "dock".
class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;
  final double margin;
  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.margin = 16,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(margin, 0, margin, 10),
        child: GlassCard(
          borderRadius: BorderRadius.circular(28),
          blur: 26,
          tint: isDark ? const Color(0x33272739) : const Color(0xE6FFFFFF),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: isDark ? 0.35 : 0.18),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final it = items[i];
              final sel = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: sel
                          ? LinearGradient(colors: [
                              scheme.primary.withValues(alpha: 0.28),
                              scheme.primary.withValues(alpha: 0.08),
                            ])
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutBack,
                          padding: EdgeInsets.all(sel ? 7 : 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? scheme.primary : Colors.transparent,
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: scheme.primary.withValues(alpha: 0.5),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            it.icon,
                            size: sel ? 21 : 20,
                            color: sel ? scheme.onPrimary : scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          it.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                            color: sel ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class GlassNavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  const GlassNavItem(this.label, this.icon, {this.activeIcon});
}

/// Small frosted info tile (used inside cards / dashboards).
class GlassTile extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  const GlassTile({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tile = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: isDark ? const Color(0x1FFFF0FE) : const Color(0xB8FFFFFF),
            borderRadius: borderRadius,
            border: Border.all(
              color: isDark ? const Color(0x26FFFFFF) : const Color(0x2EFFFFFF),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return tile;
    return GestureDetector(onTap: onTap, child: tile);
  }
}

/// A glowing circular gradient button for primary actions.
class GlowFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  const GlowFAB({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c, c.withValues(alpha: 0.6)],
              ),
              boxShadow: [
                BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
