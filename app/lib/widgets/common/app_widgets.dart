// lib/widgets/common/app_widgets.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/design_tokens.dart';

// ─── App Card ─────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor ?? DS.hairline,
          width: 0.5,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const SectionLabel(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Typo.label(color: color),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

enum BadgeVariant { green, red, amber, blue, gray }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;

  const StatusBadge(this.text, {super.key, this.variant = BadgeVariant.gray});

  @override
  Widget build(BuildContext context) {
    final colors = {
      BadgeVariant.green: (DS.income.withValues(alpha: 0.12),  DS.income),
      BadgeVariant.red:   (DS.expense.withValues(alpha: 0.12), DS.expense),
      BadgeVariant.amber: (DS.brandMuted, DS.brandDeep),
      BadgeVariant.blue:  (DS.accent.withValues(alpha: 0.12),    DS.accent),
      BadgeVariant.gray:  (DS.hairline,     DS.muted),
    };
    final (bg, fg) = colors[variant]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: Typo.sans(10, color: fg, weight: FontWeight.w600)),
    );
  }
}

// ─── Shimmer Loading Box ───────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: DS.hairline,
      highlightColor: DS.hairline,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: DS.hairline,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: DS.border),
            const SizedBox(height: 12),
            Text(title,
              style: Typo.sans(15, color: DS.muted, weight: FontWeight.w500),
              textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                style: Typo.sans(13, color: DS.faint),
                textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: DS.border),
            const SizedBox(height: 12),
            Text(message,
              style: Typo.sans(14, color: DS.muted),
              textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh, size: 16),
                label: const Text('Coba Lagi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Divider with label ────────────────────────────────────────────────────────

class LabelDivider extends StatelessWidget {
  final String label;
  const LabelDivider(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: Typo.sans(11, color: DS.faint)),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}