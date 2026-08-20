import 'package:flutter/material.dart';

/// Shared dialog / bottom-sheet helpers for admin management actions.

/// Confirm dialog returning true/false.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = '确认',
  Color? confirmColor,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: confirmColor != null
              ? FilledButton.styleFrom(backgroundColor: confirmColor)
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return r == true;
}

/// Render a labeled value row inside detail pages.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  const InfoRow({super.key, required this.label, required this.value, this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon!, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 92,
            child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? scheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card wrapper used across detail pages.
class DetailCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const DetailCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

/// Section title inside detail pages.
class DetailSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const DetailSection({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(title,
            style: TextStyle(color: scheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
        const Spacer(),
        trailing ?? const SizedBox(),
      ],
    );
  }
}

/// Async action button that shows a spinner while running.
class ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Future<void> Function() onPressed;
  final bool loading;
  final bool destructive;
  final Color? color;
  final double height;

  const ActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.destructive = false,
    this.color,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? (destructive ? const Color(0xFFE74C3C) : null);
    final Widget child = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
              Text(label),
            ],
          );
    return SizedBox(
      height: height,
      child: destructive
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: base,
                side: BorderSide(color: base!, width: 1.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: loading ? null : onPressed,
              child: child,
            )
          : ElevatedButton(
              style: color != null
                  ? ElevatedButton.styleFrom(backgroundColor: base, foregroundColor: Colors.white)
                  : null,
              onPressed: loading ? null : onPressed,
              child: child,
            ),
    );
  }
}
