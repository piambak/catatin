// lib/widgets/common/ds_widgets.dart
//
// Komponen bersama yang diturunkan dari mockup Claude Design.
//
// Catatan soal bayangan: PRD awal (R-2) menargetkan nol bayangan. Mockup yang
// akhirnya dibuat memakai bayangan sangat halus di dua tempat — kartu langkah
// simulator dan pil navigasi mengambang. Desain menang atas PRD di sini;
// R-2 perlu diperbarui. Di luar dua tempat itu, tidak ada bayangan.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/theme_notifier.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/formatters.dart';

/// Label huruf besar berjarak lebar — penanda bagian paling khas di mockup.
class DsLabel extends StatelessWidget {
  const DsLabel(this.text, {super.key, this.size = 11, this.color});

  final String text;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: Typo.label(size: size, color: color));
}

/// Pil status dengan titik di kiri — dipakai untuk "8 hari lagi".
class DsStatusPill extends StatelessWidget {
  const DsStatusPill({
    super.key,
    required this.text,
    this.dotColor,
    this.background,
    this.foreground,
  });

  final String text;
  final Color? dotColor;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? DS.brandMuted,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor ?? DS.brandDeep,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: Typo.sans(12.5,
                weight: FontWeight.w600, color: foreground ?? DS.brandInk),
          ),
        ],
      ),
    );
  }
}

enum DsButtonKind { filled, outlined, ghost }

/// Tombol pil. Tinggi minimum 46–52 menjaga target sentuh ≥44 (R-9).
class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = DsButtonKind.filled,
    this.expand = false,
    this.minHeight = 46,
    this.background,
    this.foreground,
  });

  final String label;
  final VoidCallback? onPressed;
  final DsButtonKind kind;
  final bool expand;
  final double minHeight;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    final Color bg;
    final Color fg;
    switch (kind) {
      case DsButtonKind.filled:
        bg = disabled ? DS.hairline : (background ?? DS.brand);
        fg = disabled ? DS.faint : (foreground ?? DS.onBrand);
      case DsButtonKind.outlined:
        bg = background ?? DS.surface;
        fg = foreground ?? DS.body;
      case DsButtonKind.ghost:
        bg = Colors.transparent;
        fg = foreground ?? DS.body;
    }

    final button = Material(
      color: bg,
      borderRadius: BorderRadius.circular(Radii.pill),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.pill),
            border: kind == DsButtonKind.outlined
                ? Border.all(color: DS.border)
                : null,
          ),
          // Alignment HANYA saat expand. Container yang diberi alignment
          // melebar sampai batas maksimum constraint-nya; di dalam Wrap —
          // yang memberi lebar baris penuh sebagai maksimum — itu membuat
          // tiap tombol memakan satu baris sendiri alih-alih berdampingan.
          alignment: expand ? Alignment.center : null,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Typo.sans(15,
                weight: kind == DsButtonKind.filled
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: fg),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Pil pilihan — daftar profesi dan status keluarga di simulator.
class DsChoiceChip extends StatelessWidget {
  const DsChoiceChip({
    super.key,
    required this.label,
    required this.onTap,
    this.trailing,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Kode pendek di kanan (mis. `K/1`).
  final String? trailing;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.symmetric(horizontal: expand ? 16 : 16, vertical: 10),
      decoration: BoxDecoration(
        color: DS.surface,
        border: Border.all(color: DS.border),
        borderRadius:
            BorderRadius.circular(expand ? Radii.md : Radii.pill),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, style: Typo.sans(14.5, color: DS.body)),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Text(trailing!, style: Typo.mono(12.5, color: DS.faint)),
          ],
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(expand ? Radii.md : Radii.pill),
        child: content,
      ),
    );
  }
}

/// Baris jawaban yang sudah mengendap, dengan tautan "Ubah". Pola inti 1c.
class DsAnsweredRow extends StatelessWidget {
  const DsAnsweredRow({
    super.key,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DS.sunken,
      borderRadius: BorderRadius.circular(Radii.md),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: DS.hairline),
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: Typo.sans(12, color: DS.faint, height: 1.3)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: Typo.sans(15,
                            weight: FontWeight.w500,
                            color: DS.ink,
                            height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text('Ubah',
                  style: Typo.sans(13, weight: FontWeight.w500, color: DS.link)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu langkah simulator — satu-satunya tempat bayangan dipakai di konten.
class DsStepCard extends StatelessWidget {
  const DsStepCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: DS.surface,
        border: Border.all(color: DS.border),
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: themeNotifier.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0D0D1B2A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// Baris daftar dengan garis pemisah tipis — dipakai di "SETELAH ITU",
/// "TERAKHIR DICATAT", dan daftar transaksi.
class DsListRow extends StatelessWidget {
  const DsListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingStyle,
    this.onTap,
    this.showDivider = true,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final TextStyle? trailingStyle;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: DS.hairline))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: Typo.sans(15, color: DS.body, height: 1.3)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: Typo.sans(12.5, color: DS.faint, height: 1.3)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            Text(trailing!, style: trailingStyle ?? Typo.mono(14, color: DS.muted)),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Judul bagian dengan garis atas — pemisah utama di dashboard.
class DsSection extends StatelessWidget {
  const DsSection({
    super.key,
    required this.label,
    required this.child,
    this.action,
    this.topBorder = true,
    this.spacing = 18,
  });

  final String label;
  final Widget child;
  final Widget? action;
  final bool topBorder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topBorder ? 22 : 0),
      decoration: BoxDecoration(
        border: topBorder
            ? Border(top: BorderSide(color: DS.hairline))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: DsLabel(label)),
              ?action,
            ],
          ),
          SizedBox(height: spacing),
          child,
        ],
      ),
    );
  }
}

/// Satu titik pada garis waktu kewajiban.
class DsTimelineNode extends StatelessWidget {
  const DsTimelineNode({
    super.key,
    required this.date,
    required this.title,
    required this.amount,
    this.active = false,
  });

  final String date;
  final String title;
  final String amount;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: active ? DS.brand : DS.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? DS.brand : DS.border,
              width: active ? 3 : 1,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(date, style: Typo.sans(12.5, color: DS.muted, height: 1.3)),
        const SizedBox(height: 3),
        Text(
          title,
          style: Typo.sans(15,
              weight: active ? FontWeight.w600 : FontWeight.w500,
              color: active ? DS.ink : DS.body,
              height: 1.3),
        ),
        const SizedBox(height: 4),
        Text(amount,
            style: Typo.mono(14, color: active ? DS.body : DS.muted)),
      ],
    );
  }
}

/// Wordmark "Catatin" — "Catat" dalam warna teks, "in" dalam warna merek.
class DsWordmark extends StatelessWidget {
  const DsWordmark({super.key, this.size = 26, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Catatin',
      child: ExcludeSemantics(
        child: RichText(
          text: TextSpan(
            style: Typo.serif(size, color: color ?? DS.wordmark),
            children: [
              const TextSpan(text: 'Catat'),
              TextSpan(text: 'in', style: Typo.serif(size, color: DS.brand)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kolom isian dengan label di atas — bukan label mengambang.
///
/// Label yang selalu terlihat lebih mudah dipindai daripada label yang naik
/// saat difokus, terutama di form panjang seperti Profil usaha.
class DsField extends StatelessWidget {
  const DsField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.onSubmitted,
    this.textInputAction,
    this.inputFormatters,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Typo.sans(13, weight: FontWeight.w500, color: DS.body)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          enabled: enabled,
          style: Typo.sans(15, color: DS.ink),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: Typo.sans(15, color: DS.faint),
            suffixIcon: suffix,
            filled: true,
            fillColor: enabled ? DS.surface : DS.sunken,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            border: _border(DS.border),
            enabledBorder: _border(DS.border),
            focusedBorder: _border(DS.brand, width: 1.5),
            errorBorder: _border(DS.expense),
            focusedErrorBorder: _border(DS.expense, width: 1.5),
            errorStyle: Typo.sans(11.5, color: DS.expense),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 5),
          Text(helper!, style: Typo.sans(12, color: DS.faint, height: 1.4)),
        ],
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Banner galat inline — dipakai di form auth.
class DsErrorBanner extends StatelessWidget {
  const DsErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DS.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Radii.sm),
        border: Border.all(color: DS.expense.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: DS.expense, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: Typo.sans(13, color: DS.expense, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Bar progres tipis — ambang PKP.
class DsProgressBar extends StatelessWidget {
  const DsProgressBar({
    super.key,
    required this.value,
    this.semanticLabel,
  });

  /// 0..1
  final double value;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      value: Pct.formatValue(value * 100),
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: DS.tint,
          borderRadius: BorderRadius.circular(Radii.pill),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: DS.brand,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
          ),
        ),
      ),
    );
  }
}
