// lib/widgets/dashboard/deadline_card.dart

import 'package:flutter/material.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../common/app_widgets.dart';

// ─── Single Deadline Item ─────────────────────────────────────────────────────

class DeadlineCard extends StatelessWidget {
  final List<TaxDeadline> deadlines;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const DeadlineCard({
    super.key,
    required this.deadlines,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deadline Pajak', style: AppTextStyles.display(15)),
              if (onViewAll != null)
                GestureDetector(
                  onTap: onViewAll,
                  child: Text('Selengkapnya',
                    style: AppTextStyles.body(12,
                      color: AppColors.brand, weight: FontWeight.w500)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (isLoading)
            Column(children: List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: const [
                ShimmerBox(width: 8, height: 8, radius: 4),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: double.infinity, height: 12)),
              ]),
            )))
          else if (deadlines.isEmpty)
            Text('Tidak ada deadline mendatang',
              style: AppTextStyles.body(12, color: AppColors.stone400))
          else
            Column(
              children: deadlines.map((d) => _DeadlineRow(deadline: d)).toList(),
            ),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  final TaxDeadline deadline;
  const _DeadlineRow({required this.deadline});

  Color get _dotColor {
    if (deadline.isOverdue) return AppColors.expense;
    if (deadline.isUrgent)  return AppColors.expense;
    if (deadline.isWarning) return AppColors.warning;
    return AppColors.income;
  }

  String get _daysLabel {
    final d = deadline.daysRemaining;
    if (d < 0)  return 'Terlambat!';
    if (d == 0) return 'Hari ini!';
    return '$d hari lagi';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deadline.label,
                  style: AppTextStyles.body(12, weight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                Text('Jatuh tempo: ${Tanggal.long(deadline.deadline)}',
                  style: AppTextStyles.body(10, color: AppColors.stone400)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(
            _daysLabel,
            variant: deadline.isUrgent || deadline.isOverdue
              ? BadgeVariant.red
              : deadline.isWarning
                ? BadgeVariant.amber
                : BadgeVariant.green,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class QuickActions extends StatelessWidget {
  final VoidCallback onNewTx;
  final VoidCallback onSimulator;
  final VoidCallback onLibrary;

  const QuickActions({
    super.key,
    required this.onNewTx,
    required this.onSimulator,
    required this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(
        label: 'Catat Transaksi',
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.income,
        bg: AppColors.incomeLight,
        onTap: onNewTx,
      ),
      _Action(
        label: 'Hitung Pajak',
        icon: Icons.calculate_outlined,
        color: AppColors.navy,
        bg: AppColors.navyLight,
        onTap: onSimulator,
      ),
      _Action(
        label: 'Cari Regulasi',
        icon: Icons.menu_book_outlined,
        color: AppColors.warning,
        bg: AppColors.warningLight,
        onTap: onLibrary,
      ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // spaceBetween spreads buttons when card is taller than content
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text('Aksi Cepat', style: AppTextStyles.display(15)),
          const SizedBox(height: 10),
          ...actions.map((a) => _ActionRow(action: a)),
        ],
      ),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _Action({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });
}

class _ActionRow extends StatefulWidget {
  final _Action action;
  const _ActionRow({required this.action});

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hovered ? action.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(8)),
        child: GestureDetector(
          onTap: action.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: action.bg,
                  borderRadius: BorderRadius.circular(7)),
                child: Icon(action.icon, size: 16, color: action.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(action.label,
                  style: AppTextStyles.body(13,
                    weight: FontWeight.w500))),
              Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.stone300),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Setup Prompt (shown when no business profile) ───────────────────────────

class SetupPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const SetupPrompt({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.brandSurface,
      borderColor: AppColors.brand.withOpacity(0.3),
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.business_outlined,
            color: AppColors.brand, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lengkapi profil usaha',
              style: AppTextStyles.body(13,
                weight: FontWeight.w600, color: AppColors.stone800)),
            Text('Tambahkan nama usaha dan status PKP untuk mulai.',
              style: AppTextStyles.body(11, color: AppColors.stone500)),
          ],
        )),
        Icon(Icons.chevron_right_rounded,
          color: AppColors.stone400, size: 20),
      ]),
    );
  }
}