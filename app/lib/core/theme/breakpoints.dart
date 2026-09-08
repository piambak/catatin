// lib/core/theme/breakpoints.dart
//
// Satu-satunya tempat angka breakpoint boleh ditulis.
//
// Menggantikan lima ambang literal yang sebelumnya tersebar inline:
// 480 (dashboard), 500 (accounting), 600 (kpi_card), 680 (accounting),
// 700 (dashboard). Lihat docs/PRD-REDESAIN-UI.md R-4.

import 'package:flutter/widgets.dart';

enum Breakpoint {
  /// Ponsel. Navigasi bawah, satu kolom.
  compact,

  /// Tablet / jendela sempit. Navigasi bawah, dua kolom.
  medium,

  /// Web lebar. Navigation rail, tiga kolom, lebar konten dibatasi.
  expanded;

  bool get isCompact => this == Breakpoint.compact;
  bool get isExpanded => this == Breakpoint.expanded;

  /// Rail dipakai hanya di [expanded]; sisanya memakai navigasi bawah.
  bool get usesRail => this == Breakpoint.expanded;
}

class Bp {
  Bp._();

  static const double mediumMin = 600;
  static const double expandedMin = 1024;

  /// Lebar maksimum kolom konten di layar sangat lebar, supaya baris teks
  /// tidak membentang penuh.
  static const double contentMax = 1200;

  /// Ruang yang harus disisakan di bawah konten saat pil navigasi mengambang
  /// menutupi layar (hanya di [Breakpoint.compact] dan [Breakpoint.medium]).
  ///
  /// Terdiri dari: margin atas 10 + padding pil 8 + tinggi item 52 +
  /// padding bawah 8 + margin bawah 20.
  static const double floatingNavInset = 98;

  /// Sisa ruang bawah untuk sebuah rentang — nol saat rail dipakai.
  static double bottomInset(Breakpoint bp) =>
      bp.usesRail ? 0 : floatingNavInset;

  static Breakpoint of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  static Breakpoint fromWidth(double width) {
    if (width >= expandedMin) return Breakpoint.expanded;
    if (width >= mediumMin) return Breakpoint.medium;
    return Breakpoint.compact;
  }

  /// Margin tepi halaman per rentang.
  static double pagePadding(Breakpoint bp) => switch (bp) {
        Breakpoint.compact => 22,
        Breakpoint.medium => 32,
        Breakpoint.expanded => 44,
      };
}

/// Membangun ulang subtree saat rentang breakpoint berubah.
///
/// Memakai [LayoutBuilder] alih-alih [MediaQuery] supaya ikut benar saat
/// widget dipakai di dalam panel yang lebih sempit dari layar.
class BreakpointBuilder extends StatelessWidget {
  const BreakpointBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, Breakpoint bp) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) =>
            builder(context, Bp.fromWidth(constraints.maxWidth)),
      );
}
