// lib/screens/dashboard/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';

// ─── Notification Model ───────────────────────────────────────────────────────

enum NotifType { setup, deadline, payment, regulation, info }

class AppNotification {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id, type: type, title: title, body: body,
    time: time, isRead: isRead ?? this.isRead,
  );
}

// ─── Notification Screen ──────────────────────────────────────────────────────

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late List<AppNotification> _notifs;
  bool _profileComplete = true;

  @override
  void initState() {
    super.initState();
    _notifs = _dummyNotifications();
    _checkProfile();
  }

  Future<void> _checkProfile() async {
    // Profile is complete only when businessId is set (user filled in business details)
    final bizId = await StorageService.getBusinessId();
    if (mounted) {
      setState(() => _profileComplete = bizId != null && bizId.isNotEmpty);
    }
  }

  int get _unreadCount {
    final base = _notifs.where((n) => !n.isRead).length;
    return _profileComplete ? base : base + 1;
  }

  void _markAllRead() {
    setState(() {
      _notifs = _notifs.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  void _markRead(String id) {
    setState(() {
      _notifs = _notifs.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifikasi',
              style: AppTextStyles.display(17, weight: FontWeight.w600, color: Theme.of(context).appBarTheme.foregroundColor)),
            if (_unreadCount > 0)
              Text('$_unreadCount belum dibaca',
                style: AppTextStyles.body(11, color: AppColors.stone400)),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Tandai semua dibaca',
                style: AppTextStyles.body(12,
                  color: AppColors.brand, weight: FontWeight.w500)),
            ),
        ],
      ),
      body: Builder(builder: (context) {
        // Setup notif pinned at top when profile not complete
        final setupNotif = _profileComplete ? null : AppNotification(
          id: '__setup__',
          type: NotifType.setup,
          title: 'Lengkapi profil usaha Anda',
          body: 'Tambahkan nama usaha, NPWP, dan status PKP agar '
                'semua fitur NamaAppmu berjalan optimal. Ketuk untuk melengkapi.',
          time: DateTime.now(),
          isRead: false,
        );
        final all = [
          if (setupNotif != null) setupNotif,
          ..._notifs,
        ];
        if (all.isEmpty) return _buildEmpty();
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: all.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 64),
          itemBuilder: (_, i) {
            final n = all[i];
            return _NotifTile(
              notif: n,
              isPinned: n.id == '__setup__',
              onTap: n.id == '__setup__'
                  ? () => context.push(AppRoutes.bizSetup)
                  : () => _markRead(n.id),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
            size: 52, color: AppColors.stone300),
          const SizedBox(height: 12),
          Text('Tidak ada notifikasi',
            style: AppTextStyles.body(15,
              color: AppColors.stone400, weight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Kami akan memberitahu Anda\ntentang deadline dan info pajak terbaru',
            style: AppTextStyles.body(13, color: AppColors.stone400),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Notification Tile ────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final VoidCallback onTap;
  final bool isPinned;

  const _NotifTile({
    required this.notif,
    required this.onTap,
    this.isPinned = false,
  });

  (Color bg, Color icon, IconData iconData) get _style {
    switch (notif.type) {
      case NotifType.setup:
        return (AppColors.brandLight, AppColors.brand,
          Icons.business_outlined);
      case NotifType.deadline:
        return (AppColors.expenseLight, AppColors.expense,
          Icons.calendar_today_rounded);
      case NotifType.payment:
        return (AppColors.warningLight, AppColors.warning,
          Icons.payments_outlined);
      case NotifType.regulation:
        return (AppColors.navyLight, AppColors.navy,
          Icons.menu_book_outlined);
      case NotifType.info:
        return (AppColors.incomeLight, AppColors.income,
          Icons.info_outline_rounded);
    }
  }

  String get _timeLabel {
    final diff = DateTime.now().difference(notif.time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24)   return '${diff.inHours} jam lalu';
    if (diff.inDays < 7)     return '${diff.inDays} hari lalu';
    return Tanggal.short(notif.time);
  }

  @override
  Widget build(BuildContext context) {
    final (bg, iconColor, iconData) = _style;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isPinned
          ? AppColors.brand.withOpacity(0.06)
          : notif.isRead
            ? Colors.transparent
            : AppColors.brand.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(notif.title,
                        style: AppTextStyles.body(13,
                          weight: notif.isRead
                            ? FontWeight.w400
                            : FontWeight.w600)),
                    ),
                    if (isPinned) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Perlu aksi',
                          style: AppTextStyles.body(9,
                            color: AppColors.brand,
                            weight: FontWeight.w600)),
                      ),
                    ] else if (!notif.isRead) ...[
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(left: 6, top: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(notif.body,
                    style: AppTextStyles.body(12, color: AppColors.stone500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Text(_timeLabel,
                    style: AppTextStyles.body(11, color: AppColors.stone400)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dummy Data ───────────────────────────────────────────────────────────────

List<AppNotification> _dummyNotifications() {
  final now = DateTime.now();
  return [
    AppNotification(
      id: '1',
      type: NotifType.deadline,
      title: 'Deadline PPh Final Masa Oktober',
      body: 'Batas setor PPh Final 0,5% masa Oktober 2025 adalah 15 November 2025. Sisa 3 hari lagi.',
      time: now.subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    AppNotification(
      id: '2',
      type: NotifType.payment,
      title: 'PPh 21 Karyawan Belum Disetor',
      body: 'PPh 21 masa Oktober 2025 sebesar Rp 402.500 jatuh tempo 10 November 2025.',
      time: now.subtract(const Duration(hours: 5)),
      isRead: false,
    ),
    AppNotification(
      id: '3',
      type: NotifType.regulation,
      title: 'Peraturan Baru: PMK 81/2024',
      body: 'Pemerintah menerbitkan PMK 81/2024 tentang penyesuaian tarif PTKP. Berlaku mulai Januari 2025.',
      time: now.subtract(const Duration(days: 1)),
      isRead: false,
    ),
    AppNotification(
      id: '4',
      type: NotifType.deadline,
      title: 'SPT Tahunan 2025',
      body: 'Jangan lupa! SPT Tahunan PPh Orang Pribadi tahun 2025 harus dilaporkan paling lambat 30 April 2026.',
      time: now.subtract(const Duration(days: 2)),
      isRead: true,
    ),
    AppNotification(
      id: '5',
      type: NotifType.info,
      title: 'Omzet Mendekati Batas PKP',
      body: 'Omzet YTD Anda sudah mencapai 85% dari batas PKP Rp 4,8 Miliar. Pertimbangkan konsultasi dengan konsultan pajak.',
      time: now.subtract(const Duration(days: 3)),
      isRead: true,
    ),
    AppNotification(
      id: '6',
      type: NotifType.regulation,
      title: 'Update: PP 23/2018 — Batas Waktu',
      body: 'Pengingat: PP 23/2018 berlaku maksimal 7 tahun untuk WP Orang Pribadi. Periksa status usaha Anda.',
      time: now.subtract(const Duration(days: 5)),
      isRead: true,
    ),
    AppNotification(
      id: '7',
      type: NotifType.payment,
      title: 'Konfirmasi Pembayaran PPh Final',
      body: 'Pembayaran PPh Final masa September 2025 sebesar Rp 142.500 telah tercatat.',
      time: now.subtract(const Duration(days: 6)),
      isRead: true,
    ),
    AppNotification(
      id: '8',
      type: NotifType.info,
      title: 'Fitur Baru: Export Laporan Excel',
      body: 'Kini Anda dapat mengekspor laporan laba rugi ke format Excel langsung dari menu Pembukuan.',
      time: now.subtract(const Duration(days: 7)),
      isRead: true,
    ),
  ];
}