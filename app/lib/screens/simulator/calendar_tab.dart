// lib/screens/simulator/calendar_tab.dart

import 'package:flutter/material.dart';
import '../../core/services/simulator_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/simulator/sim_widgets.dart';
import '../../widgets/common/app_widgets.dart';

class CalendarTab extends StatefulWidget {
  const CalendarTab({super.key});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab>
    with AutomaticKeepAliveClientMixin {
  final int _year        = DateTime.now().year;
  bool      _isPkp       = false;
  bool      _hasEmployees= true;
  String?   _filterType; // null = all

  late List<TaxDeadlineItem> _allItems;
  List<TaxDeadlineItem> get _filtered => _filterType == null
      ? _allItems
      : _allItems.where((d) => d.taxType == _filterType).toList();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  void _rebuild() {
    _allItems = generateCalendar(
      year:         _year,
      isPkp:        _isPkp,
      hasEmployees: _hasEmployees,
    );
  }

  (Color, Color, Color) _colors(DeadlineStatus s) => switch (s) {
    DeadlineStatus.overdue  => (AppColors.expense,
        AppColors.expenseLight, AppColors.expense),
    DeadlineStatus.urgent   => (AppColors.expense,
        AppColors.expenseLight, AppColors.expense),
    DeadlineStatus.warning  => (AppColors.warning,
        AppColors.warningLight, AppColors.warning),
    DeadlineStatus.upcoming => (AppColors.income,
        AppColors.incomeLight,  AppColors.income),
  };

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Urgent banner items
    final urgent = _allItems
        .where((d) => d.status == DeadlineStatus.urgent ||
                      d.status == DeadlineStatus.overdue)
        .take(2)
        .toList();

    // Summary counts
    final overdueCount  = _allItems.where((d) => d.status == DeadlineStatus.overdue).length;
    final urgentCount   = _allItems.where((d) => d.status == DeadlineStatus.urgent).length;
    final warningCount  = _allItems.where((d) => d.status == DeadlineStatus.warning).length;
    final upcomingCount = _allItems.where((d) => d.status == DeadlineStatus.upcoming).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Config ────────────────────────────────────────
          SimCard(
            title: 'Pengaturan Kalender $_year',
            subtitle: 'Sesuaikan dengan kondisi usaha Anda',
            icon: Icons.settings_outlined,
            iconColor: AppColors.stone500,
            children: [
              Row(children: [
                Expanded(child: _ConfigTile(
                  label: 'Ada Karyawan',
                  value: _hasEmployees,
                  onChanged: (v) => setState(() {
                    _hasEmployees = v; _rebuild(); }),
                )),
                const SizedBox(width: 10),
                Expanded(child: _ConfigTile(
                  label: 'Status PKP',
                  value: _isPkp,
                  onChanged: (v) => setState(() {
                    _isPkp = v; _rebuild(); }),
                )),
              ]),
            ],
          ),
          const SizedBox(height: 14),

          // ── Urgent banner ─────────────────────────────────
          if (urgent.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.expenseLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.expense.withOpacity(0.3), width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.notifications_active_rounded,
                      color: AppColors.expense, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${urgent.length} deadline dalam 7 hari ke depan!',
                      style: AppTextStyles.body(13,
                        color: AppColors.expense, weight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 8),
                  ...urgent.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.expense, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(d.label,
                        style: AppTextStyles.body(
                          12, color: AppColors.expense))),
                      Text(d.daysLabel,
                        style: AppTextStyles.mono(11,
                          color: AppColors.expense,
                          weight: FontWeight.w600)),
                    ]),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Summary cards ─────────────────────────────────
          Row(children: [
            _SummaryChip(count: overdueCount + urgentCount,
              label: '< 7 hari', color: AppColors.expense),
            const SizedBox(width: 8),
            _SummaryChip(count: warningCount,
              label: '7–30 hari', color: AppColors.warning),
            const SizedBox(width: 8),
            _SummaryChip(count: upcomingCount,
              label: '> 30 hari', color: AppColors.income),
            const SizedBox(width: 8),
            _SummaryChip(count: _allItems.length,
              label: 'Total', color: AppColors.stone500),
          ]),
          const SizedBox(height: 14),

          // ── Filter tabs ───────────────────────────────────
          _FilterRow(
            selected: _filterType,
            types: ['PPh Final', 'PPh 21', 'PPN', 'SPT Tahunan'],
            onChanged: (t) => setState(() => _filterType = t),
          ),
          const SizedBox(height: 10),

          // ── Deadline list ─────────────────────────────────
          AppCard(
            padding: EdgeInsets.zero,
            child: _filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: EmptyState(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tidak ada deadline',
                      subtitle: 'Sesuaikan filter atau pengaturan di atas',
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = _filtered[i];
                      final (dot, bg, fg) = _colors(d.status);
                      return DeadlineRow(
                        taxType:    d.taxType,
                        label:      d.label,
                        period:     d.period,
                        deadline:   d.deadline,
                        daysLabel:  d.daysLabel,
                        dotColor:   dot,
                        badgeColor: bg,
                        badgeText:  fg,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 14),
          const SimDisclaimer(),
        ],
      ),
    );
  }
}

// ─── Config Tile ──────────────────────────────────────────────────────────────

class _ConfigTile extends StatelessWidget {
  final String label;
  final bool   value;
  final ValueChanged<bool> onChanged;

  const _ConfigTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: value ? AppColors.dark : AppColors.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppColors.dark : AppColors.stone300,
            width: 0.5),
        ),
        child: Row(children: [
          Icon(
            value ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
            color: value ? AppColors.brand : AppColors.stone400,
            size: 20),
          const SizedBox(width: 6),
          Expanded(child: Text(label,
            style: AppTextStyles.body(12,
              color: value ? Colors.white : AppColors.stone700,
              weight: FontWeight.w500))),
        ]),
      ),
    );
  }
}

// ─── Summary Chip ────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final int    count;
  final String label;
  final Color  color;

  const _SummaryChip({
    required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25), width: 0.5),
        ),
        child: Column(children: [
          Text('$count',
            style: AppTextStyles.mono(
              16, color: color, weight: FontWeight.w700)),
          Text(label,
            style: AppTextStyles.body(
              9, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ─── Filter Row ──────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final String?       selected;
  final List<String>  types;
  final ValueChanged<String?> onChanged;

  const _FilterRow({
    required this.selected,
    required this.types,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _FilterChip(label: 'Semua',
          isSelected: selected == null,
          onTap: () => onChanged(null)),
        ...types.map((t) => _FilterChip(
          label: t,
          isSelected: selected == t,
          onTap: () => onChanged(selected == t ? null : t),
        )),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String   label;
  final bool     isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.dark : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.dark : AppColors.stone200,
            width: 0.5),
        ),
        child: Text(label,
          style: AppTextStyles.body(11,
            color: isSelected ? Colors.white : AppColors.stone600,
            weight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }
}
