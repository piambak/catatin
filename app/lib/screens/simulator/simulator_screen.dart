// lib/screens/simulator/simulator_screen.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'pph_final_tab.dart';
import 'pph21_tab.dart';
import 'scenario_tab.dart';
import 'calendar_tab.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _tabs = [
    _TabItem(label: 'PPh Final',  icon: Icons.bolt_rounded),
    _TabItem(label: 'PPh 21',     icon: Icons.people_outline_rounded),
    _TabItem(label: 'Skenario',   icon: Icons.tune_rounded),
    _TabItem(label: 'Deadline',   icon: Icons.calendar_month_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ── App bar + tab bar ────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Simulator Pajak',
              style: AppTextStyles.display(17, weight: FontWeight.w600, color: Theme.of(context).appBarTheme.foregroundColor)),
            Text('Hitung dan rencanakan kewajiban pajak',
              style: AppTextStyles.body(11, color: AppColors.stone500)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: TabBar(
              controller: _tabCtrl,
              isScrollable: false,
              labelColor: Theme.of(context).appBarTheme.foregroundColor,
              unselectedLabelColor: AppColors.stone400,
              labelStyle: AppTextStyles.body(12, weight: FontWeight.w600),
              unselectedLabelStyle: AppTextStyles.body(12),
              indicatorColor: AppColors.brand,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: AppColors.stone200,
              tabs: _tabs.map((t) => Tab(
                height: 40,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 14),
                    const SizedBox(width: 5),
                    Text(t.label),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),

      // ── Tab views ────────────────────────────────────────────
      body: TabBarView(
        controller: _tabCtrl,
        physics: const NeverScrollableScrollPhysics(),
        // NeverScrollable so Rupiah inputs don't conflict with swipe
        children: const [
          PphFinalTab(),
          Pph21Tab(),
          ScenarioTab(),
          CalendarTab(),
        ],
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}