// lib/widgets/dashboard/tax_calendar_card.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── Calendar event model ─────────────────────────────────────────────────────

enum CalEventType { payPph, reportSpt, pph21, info }

class CalEvent {
  final int day;
  final CalEventType type;
  final String title;
  final String description;

  const CalEvent({
    required this.day,
    required this.type,
    required this.title,
    required this.description,
  });
}

// ─── Tax Calendar Card ────────────────────────────────────────────────────────

class TaxCalendarCard extends StatefulWidget {
  final bool isPkp;
  final bool hasEmployees;

  const TaxCalendarCard({
    super.key,
    this.isPkp = false,
    this.hasEmployees = true,
  });

  @override
  State<TaxCalendarCard> createState() => _TaxCalendarCardState();
}

class _TaxCalendarCardState extends State<TaxCalendarCard> {
  late DateTime _month;
  int? _hoveredDay;

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prev() => setState(() =>
      _month = DateTime(_month.year, _month.month - 1));

  void _next() => setState(() =>
      _month = DateTime(_month.year, _month.month + 1));

  // Build events for the current month
  List<CalEvent> get _events {
    final events = <CalEvent>[];

    // PPh Final — setor tanggal 15
    events.add(CalEvent(
      day: 15, type: CalEventType.payPph,
      title: 'Bayar PPh Final',
      description:
          'Setor PPh Final 0,5% masa ${_monthName(_month.month - 1)} '
          '${_month.year} paling lambat hari ini.',
    ));

    // PPh 21 — setor tanggal 10, lapor tanggal 20
    if (widget.hasEmployees) {
      events.add(CalEvent(
        day: 10, type: CalEventType.pph21,
        title: 'Setor PPh 21 Karyawan',
        description:
            'Batas setor PPh 21 karyawan masa '
            '${_monthName(_month.month - 1)} ${_month.year}.',
      ));
      events.add(CalEvent(
        day: 20, type: CalEventType.reportSpt,
        title: 'Lapor SPT Masa PPh 21',
        description:
            'Deadline laporan SPT Masa PPh 21 '
            '${_monthName(_month.month)} ${_month.year} ke KPP.',
      ));
    }

    // PPN — kalau PKP
    if (widget.isPkp) {
      events.add(CalEvent(
        day: 25, type: CalEventType.payPph,
        title: 'Bayar & Lapor PPN',
        description:
            'Setoran dan laporan SPT Masa PPN masa '
            '${_monthName(_month.month)} ${_month.year}.',
      ));
    }

    // SPT Tahunan — April
    if (_month.month == 4) {
      events.add(CalEvent(
        day: 30, type: CalEventType.reportSpt,
        title: 'Deadline SPT Tahunan',
        description:
            'Batas lapor SPT Tahunan PPh Orang Pribadi '
            'tahun ${_month.year - 1}. Lapor via DJP Online.',
      ));
    }

    return events;
  }

  Map<int, CalEvent> get _eventMap =>
      {for (final e in _events) e.day: e};

  int get _daysInMonth =>
      DateTime(_month.year, _month.month + 1, 0).day;

  // 0 = Sunday
  int get _startWeekday {
    final d = DateTime(_month.year, _month.month, 1).weekday;
    return d == 7 ? 0 : d;
  }

  @override
  Widget build(BuildContext context) {
    final events = _eventMap;
    final today  = DateTime.now();
    final isThisMonth =
        _month.year == today.year && _month.month == today.month;

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kalender Pajak',
                  style: AppTextStyles.display(13)),
                Text('Sentuh tanggal berwarna untuk detail',
                  style: AppTextStyles.body(10, color: AppColors.stone400)),
              ]),
              Row(children: [
                _MonthBtn(
                  icon: Icons.chevron_left_rounded,
                  onTap: _prev),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${_monthName(_month.month)} ${_month.year}',
                    style: AppTextStyles.body(
                      12, weight: FontWeight.w500),
                  ),
                ),
                _MonthBtn(
                  icon: Icons.chevron_right_rounded,
                  onTap: _next),
              ]),
            ],
          ),
          const SizedBox(height: 12),

          // Day labels
          Row(
            children: ['Min','Sen','Sel','Rab','Kam','Jum','Sab']
                .map((d) => Expanded(
                  child: Text(d,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(
                      9, color: AppColors.stone400,
                      weight: FontWeight.w500)),
                ))
                .toList(),
          ),
          const SizedBox(height: 4),

          // Calendar grid
          LayoutBuilder(builder: (ctx, box) {
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                      mainAxisExtent: 36,
                    ),
                itemCount: 42,
                itemBuilder: (_, i) {
                  final day = i - _startWeekday + 1;
                  final valid = day >= 1 && day <= _daysInMonth;
                  final event = valid ? events[day] : null;
                  final isToday = valid && isThisMonth
                      && day == today.day;

                  return _CalCell(
                    day:        day,
                    valid:      valid,
                    isToday:    isToday,
                    event:      event,
                    isHovered:  _hoveredDay == day && valid,
                    onHover:    (h) => setState(() =>
                        _hoveredDay = h ? day : null),
                    onTap: event != null
                        ? () => _showEventSheet(context, event)
                        : null,
                  );
                },
              );
            }),

          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 10, runSpacing: 6,
            children: [
              _LegendItem(label: 'Bayar PPh',   color: AppColors.expense),
              _LegendItem(label: 'Lapor SPT',   color: AppColors.warning),
              _LegendItem(label: 'PPh 21',      color: AppColors.income),
              _LegendItem(label: 'Info lainnya',color: AppColors.navy),
            ],
          ),
        ],
      ),
    );
  }

  void _showEventSheet(BuildContext context, CalEvent event) {
    final (bg, color, _) = _colorsFor(event.type);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone200,
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(9)),
                child: Icon(
                  _iconFor(event.type), size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                    style: AppTextStyles.display(15)),
                  Text(
                    '${event.day} ${_monthName(_month.month)} '
                    '${_month.year}',
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
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(event.description,
                style: AppTextStyles.body(13, color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Calendar cell ────────────────────────────────────────────────────────────

class _CalCell extends StatelessWidget {
  final int day;
  final bool valid;
  final bool isToday;
  final CalEvent? event;
  final bool isHovered;
  final ValueChanged<bool> onHover;
  final VoidCallback? onTap;

  const _CalCell({
    required this.day,
    required this.valid,
    required this.isToday,
    required this.event,
    required this.isHovered,
    required this.onHover,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!valid) {
      return const SizedBox.shrink();
    }

    final (bg, fg, dot) = event != null
        ? _colorsFor(event!.type)
        : (Colors.transparent, AppColors.stone500, Colors.transparent);

    final Color cellBg = isToday && event == null
        ? AppColors.stone100
        : (event != null ? bg : Colors.transparent);

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit:  (_) => onHover(false),
      cursor: event != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: isHovered && event != null
                ? bg.withOpacity(0.7)
                : cellBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: AppTextStyles.body(
                  11,
                  color: event != null ? fg
                      : isToday ? AppColors.stone800
                      : AppColors.stone500,
                  weight: event != null || isToday
                      ? FontWeight.w500
                      : FontWeight.w400,
                ),
              ),
              if (event != null)
                Positioned(
                  bottom: 3,
                  child: Container(
                    width: 4, height: 4,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Legend item ──────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(label,
        style: AppTextStyles.body(10, color: AppColors.stone500)),
    ]);
  }
}

// ─── Month nav button ─────────────────────────────────────────────────────────

class _MonthBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MonthBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: AppColors.stone100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.stone200, width: 0.5),
        ),
        child: Icon(icon, size: 16, color: AppColors.stone500),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

(Color bg, Color fg, Color dot) _colorsFor(CalEventType t) {
  switch (t) {
    case CalEventType.payPph:
      return (AppColors.expenseLight, AppColors.expense,
          AppColors.expense);
    case CalEventType.reportSpt:
      return (AppColors.warningLight, AppColors.warning,
          AppColors.warning);
    case CalEventType.pph21:
      return (AppColors.incomeLight, AppColors.income,
          AppColors.income);
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
