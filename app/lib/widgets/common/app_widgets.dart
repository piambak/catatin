// lib/widgets/common/app_widgets.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_theme.dart';

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
          color: borderColor ?? AppColors.stone200,
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
      style: AppTextStyles.label(color: color),
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
      BadgeVariant.green: (AppColors.incomeLight,  AppColors.income),
      BadgeVariant.red:   (AppColors.expenseLight, AppColors.expense),
      BadgeVariant.amber: (AppColors.warningLight, AppColors.warning),
      BadgeVariant.blue:  (AppColors.navyLight,    AppColors.navy),
      BadgeVariant.gray:  (AppColors.stone100,     AppColors.stone500),
    };
    final (bg, fg) = colors[variant]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: AppTextStyles.body(10, color: fg, weight: FontWeight.w600)),
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
      baseColor: AppColors.stone200,
      highlightColor: AppColors.stone100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.stone200,
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
            Icon(icon, size: 48, color: AppColors.stone300),
            const SizedBox(height: 12),
            Text(title,
              style: AppTextStyles.body(15, color: AppColors.stone500, weight: FontWeight.w500),
              textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                style: AppTextStyles.body(13, color: AppColors.stone400),
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
            Icon(Icons.error_outline, size: 40, color: AppColors.stone300),
            const SizedBox(height: 12),
            Text(message,
              style: AppTextStyles.body(14, color: AppColors.stone500),
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
        child: Text(label, style: AppTextStyles.body(11, color: AppColors.stone400)),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}