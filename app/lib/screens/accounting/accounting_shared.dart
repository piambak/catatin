// lib/screens/accounting/accounting_shared.dart
//
// Widget kecil yang dipakai lebih dari satu tab Pencatatan.
//
// Dipecah dari accounting_screen.dart (2.451 baris) untuk PRD R-7 / issue #52.
// Pemindahan murni: tidak ada perilaku yang diubah. Hanya delapan kelas yang
// naik jadi publik, yaitu yang dipakai lintas berkas.

import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

class MonthNav extends StatelessWidget {
  final DateTime cursor;
  final ValueChanged<DateTime> onShift;

  const MonthNav({required this.cursor, required this.onShift});

  static const _months = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(
      children: [
        NavBtn(
          icon: Icons.chevron_left_rounded,
          onTap: () => onShift(DateTime(cursor.year, cursor.month - 1)),
        ),
        const SizedBox(width: 10),
        Text(
          '${_months[cursor.month]} ${cursor.year}',
          style: Typo.sans(13, weight: FontWeight.w500),
        ),
        const SizedBox(width: 10),
        NavBtn(
          icon: Icons.chevron_right_rounded,
          onTap: () => onShift(DateTime(cursor.year, cursor.month + 1)),
        ),
      ],
    ),
  );
}

class YearNav extends StatelessWidget {
  final int year;
  final ValueChanged<int> onShift;

  const YearNav({required this.year, required this.onShift});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(
      children: [
        NavBtn(
          icon: Icons.chevron_left_rounded,
          onTap: () => onShift(year - 1),
        ),
        const SizedBox(width: 10),
        Text('$year', style: Typo.sans(13, weight: FontWeight.w500)),
        const SizedBox(width: 10),
        NavBtn(
          icon: Icons.chevron_right_rounded,
          onTap: () => onShift(year + 1),
        ),
      ],
    ),
  );
}

class NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: DS.hairline,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: DS.hairline, width: 0.5),
        ),
        child: Icon(icon, size: 17, color: DS.muted),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DAILY TAB
// ─────────────────────────────────────────────────────────────────────────────

class LegDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .3),
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(label, style: Typo.sans(10, color: DS.muted)),
    ],
  );
}
