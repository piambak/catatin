// lib/widgets/dashboard/cal_deadline_card.dart
// Calendar + Deadline combined into one card

import 'package:flutter/material.dart';
import '../../core/services/dashboard_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../common/app_widgets.dart';
// CalEvent, CalEventType defined below (copied from tax_calendar_card)


// ─── Calendar models & helpers (self-contained) ──────────────────────────────

enum CalEventType { payPph, reportSpt, pph21, info }

class CalEvent {
  final int day;
  final CalEventType type;
  final String title;
  final String description;
  const CalEvent({
    required this.day, required this.type,
    required this.title, required this.description,
  });
}

(Color bg, Color fg, Color dot) _colorsFor(CalEventType t) {
  switch (t) {
    case CalEventType.payPph:
      return (AppColors.expenseLight, AppColors.expense, AppColors.expense);
    case CalEventType.reportSpt:
      return (AppColors.warningLight, AppColors.warning, AppColors.warning);
    case CalEventType.pph21:
      return (AppColors.incomeLight, AppColors.income, AppColors.income);
    case CalEventType.info:
      return (AppColors.navyLight, AppColors.navy, AppColors.navy);
  }
}

IconData _iconFor(CalEventType t) {
  switch (t) {
    case CalEventType.payPph:    return Icons.payments_outlined;
    case CalEventType.reportSpt: return Icons.send_outlined;
    case CalEventType.pph21:     return Icons.people_outline_rounded;
    case CalEventType.info:      return Icons.info_outline_rounded;
  }
}

String _monthName(int month) {
  final m = ((month - 1) % 12) + 1;
  return const [
    'Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember',
  ][m - 1];
}

class CalDeadlineCard extends StatefulWidget {
  final List<TaxDeadline> deadlines;
  final bool isLoading;
  final bool isPkp;
  final bool hasEmployees;
  final VoidCallback? onViewAll;

  const CalDeadlineCard({
    super.key,
    this.deadlines   = const [],
    this.isLoading   = false,
    this.isPkp       = false,
    this.hasEmployees = true,
    this.onViewAll,
  });

  @override
  State<CalDeadlineCard> createState() => _CalDeadlineCardState();
}

class _CalDeadlineCardState extends State<CalDeadlineCard> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prev() => setState(() =>
      _month = DateTime(_month.year, _month.month - 1));
  void _next() => setState(() =>
      _month = DateTime(_month.year, _month.month + 1));

  List<CalEvent> get _events {
    final ev = <CalEvent>[];
    ev.add(CalEvent(day: 15, type: CalEventType.payPph,
      title: 'Bayar PPh Final',
      description: 'Setor PPh Final 0,5% masa '
          '${_monthName(_month.month - 1)} ${_month.year}.'));
    if (widget.hasEmployees) {
      ev.add(CalEvent(day: 10, type: CalEventType.pph21,
        title: 'Setor PPh 21 Karyawan',
        description: 'Batas setor PPh 21 masa '
            '${_monthName(_month.month - 1)} ${_month.year}.'));
      ev.add(CalEvent(day: 20, type: CalEventType.reportSpt,
        title: 'Lapor SPT Masa PPh 21',
        description: 'Deadline laporan SPT Masa PPh 21 '
            '${_monthName(_month.month)} ${_month.year}.'));
    }
    if (widget.isPkp) {
      ev.add(CalEvent(day: 25, type: CalEventType.payPph,
        title: 'Bayar & Lapor PPN',
        description: 'Setoran dan laporan SPT Masa PPN '
            '${_monthName(_month.month)} ${_month.year}.'));
    }
    if (_month.month == 4) {
      ev.add(CalEvent(day: 30, type: CalEventType.reportSpt,
        title: 'Deadline SPT Tahunan',
        description: 'Batas lapor SPT Tahunan PPh OP '
            'tahun ${_month.year - 1}.'));
    }
    return ev;
  }

  Map<int, CalEvent> get _eventMap =>
      {for (final e in _events) e.day: e};

  int get _daysInMonth =>
      DateTime(_month.year, _month.month + 1, 0).day;

  int get _startWeekday {
    final d = DateTime(_month.year, _month.month, 1).weekday;
    return d == 7 ? 0 : d;
  }

  @override
  Widget build(BuildContext context) {
    final events   = _eventMap;
    final today    = DateTime.now();
    final isThisMo = _month.year == today.year &&
        _month.month == today.month;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Calendar header ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kalender Pajak',
                      style: AppTextStyles.display(13)),
                    Text('Sentuh tanggal berwarna untuk detail',
                      style: AppTextStyles.body(10, color: AppColors.stone400),
                      overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _MonthBtn(icon: Icons.chevron_left_rounded,  onTap: _prev),
                SizedBox(
                  width: 90,
                  child: Text(
                    '${_monthName(_month.month)} ${_month.year}',
                    style: AppTextStyles.body(11, weight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis),
                ),
                _MonthBtn(icon: Icons.chevron_right_rounded, onTap: _next),
              ]),
            ],
          ),
          const SizedBox(height: 10),

          // ── Day labels ─────────────────────────────────────
          Row(
            children: ['Min','Sen','Sel','Rab','Kam','Jum','Sab']
                .map((d) => Expanded(
                  child: Text(d,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      9, color: AppColors.stone400,
                      weight: FontWeight.w500))))
                .toList(),
          ),
          const SizedBox(height: 3),

          // ── Calendar grid ──────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  mainAxisExtent: 32,
                ),
            itemCount: 42,
            itemBuilder: (_, i) {
              final day = i - _startWeekday + 1;
              final valid = day >= 1 && day <= _daysInMonth;
              final event = valid ? events[day] : null;
              final isToday = valid && isThisMo && day == today.day;
              return _CalCell(
                day:     day,
                valid:   valid,
                isToday: isToday,
                event:   event,
                onTap:   event != null
                    ? () => _showDetail(context, event)
                    : null,
              );
            },
          ),
          const SizedBox(height: 8),

          // ── Legend ─────────────────────────────────────────
          Wrap(spacing: 8, runSpacing: 4, children: [
            _LegItem(label: 'Bayar PPh', color: AppColors.expense),
            _LegItem(label: 'Lapor SPT', color: AppColors.warning),
            _LegItem(label: 'PPh 21',    color: AppColors.income),
          ]),

          // ── Divider ────────────────────────────────────────
          Container(
            height: 0.5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.stone200,
          ),

          // ── Deadline section ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Deadline Pajak',
                style: AppTextStyles.display(13)),
              if (widget.onViewAll != null)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                  onTap: widget.onViewAll,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 100),
                    style: AppTextStyles.body(10,
                      color: AppColors.navy,
                      weight: FontWeight.w500),
                    child: const Text('Selengkapnya')),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (widget.isLoading)
            Column(children: List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: const [
                ShimmerBox(width: 8, height: 8, radius: 4),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(
                  width: double.infinity, height: 12)),
              ]),
            )))
          else
            ...widget.deadlines.take(3).map((d) =>
              _DeadlineRow(deadline: d)),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, CalEvent event) {
    final (bg, color, _) = _colorsFor(event.type);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.stone200,
                borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(9)),
                child: Icon(_iconFor(event.type),
                  size: 18, color: color)),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                    style: AppTextStyles.display(15)),
                  Text('${event.day} ${_monthName(_month.month)} ${_month.year}',
                    style: AppTextStyles.body(
                      11, color: AppColors.stone400)),
                ],
              )),
            ]),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(8)),
              child: Text(event.description,
                style: AppTextStyles.body(13, color: color)),
            ),
          ],
        )),
      )),
    ));
  }
}

// ── Calendar cell ─────────────────────────────────────────────────────────────

class _CalCell extends StatefulWidget {
  final int day;
  final bool valid, isToday;
  final CalEvent? event;
  final VoidCallback? onTap;
  const _CalCell({
    required this.day, required this.valid,
    required this.isToday, required this.event,
    required this.onTap,
  });

  @override
  State<_CalCell> createState() => _CalCellState();
}

class _CalCellState extends State<_CalCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.valid) return const SizedBox.shrink();
    final (bg, fg, dot) = widget.event != null
        ? _colorsFor(widget.event!.type)
        : (Colors.transparent, AppColors.stone500, Colors.transparent);
    final cellBg = _hovered && widget.event != null
        ? bg.withOpacity(0.7)
        : widget.isToday && widget.event == null
            ? AppColors.stone100
            : (widget.event != null ? bg : Colors.transparent);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: cellBg,
          borderRadius: BorderRadius.circular(5),
          border: _hovered && widget.event != null
              ? Border.all(color: AppColors.brand, width: 1)
              : null),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(alignment: Alignment.center, children: [
            Text('${widget.day}', style: AppTextStyles.body(10,
              color: widget.event != null ? fg
                  : widget.isToday ? AppColors.stone800 : AppColors.stone500,
              weight: widget.event != null || widget.isToday
                  ? FontWeight.w500 : FontWeight.w400)),
            if (widget.event != null)
              Positioned(bottom: 2, child: Container(
                width: 3, height: 3,
                decoration: BoxDecoration(
                  color: dot, shape: BoxShape.circle))),
          ]),
        ),
      ),
    );
  }
}

// ── Deadline row ──────────────────────────────────────────────────────────────

class _DeadlineRow extends StatelessWidget {
  final TaxDeadline deadline;
  const _DeadlineRow({required this.deadline});

  Color get _dotColor {
    if (deadline.isOverdue || deadline.isUrgent) return AppColors.expense;
    if (deadline.isWarning) return AppColors.warning;
    return AppColors.income;
  }

  Color get _badgeBg {
    if (deadline.isOverdue || deadline.isUrgent) return AppColors.expenseLight;
    if (deadline.isWarning) return AppColors.warningLight;
    return AppColors.incomeLight;
  }

  Color get _badgeFg {
    if (deadline.isOverdue || deadline.isUrgent) return const Color(0xFF791F1F);
    if (deadline.isWarning) return const Color(0xFF633806);
    return const Color(0xFF27500A);
  }

  String get _daysLabel {
    final d = deadline.daysRemaining;
    if (d < 0)  return 'Terlambat!';
    if (d == 0) return 'Hari ini!';
    return '$d hari';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: _dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(deadline.label,
              style: AppTextStyles.body(11, weight: FontWeight.w500),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(Tanggal.short(deadline.deadline),
              style: AppTextStyles.body(10, color: AppColors.stone400)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: _badgeBg,
            borderRadius: BorderRadius.circular(20)),
          child: Text(_daysLabel,
            style: AppTextStyles.body(9,
              color: _badgeFg, weight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ── Legend item ───────────────────────────────────────────────────────────────

class _LegItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.body(
        10, color: AppColors.stone500)),
    ]);
  }
}

// ── Month button ──────────────────────────────────────────────────────────────

class _MonthBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MonthBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: AppColors.stone100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.stone200, width: 0.5)),
        child: Icon(icon, size: 15, color: AppColors.stone500)),
    );
  }
}
