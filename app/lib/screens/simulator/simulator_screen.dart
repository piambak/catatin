// lib/screens/simulator/simulator_screen.dart
//
// Simulator hasil redesain — mengikuti artboard 1c di Catatin.dc.html.
//
// Perubahan struktur: tab "PPh Final" dan "PPh 21" digabung jadi satu alur
// percakapan (`TaxConversationTab`) yang menghitung keduanya sekaligus dan
// membandingkannya di penjelasan. Tab "Skenario" dan "Deadline" tetap terpisah
// karena tugasnya memang lain.
//
// Berkas lama `pph_final_tab.dart` dan `pph21_tab.dart` sengaja TIDAK dihapus.
// Keduanya masih jadi rujukan saat T-1 (kategori TER B & C) dikerjakan, dan
// menghapusnya di PR yang sama akan mencampur dua topik.

import 'package:flutter/material.dart';

import '../../core/theme/breakpoints.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/common/ds_widgets.dart';
import 'calendar_tab.dart';
import 'scenario_tab.dart';
import 'tax_conversation_tab.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _tabs = ['Hitung pajak', 'Skenario', 'Deadline'];

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
      backgroundColor: DS.surface,
      body: SafeArea(
        child: BreakpointBuilder(
          builder: (context, bp) {
            final pad = Bp.pagePadding(bp);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: Bp.contentMax),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (bp.isExpanded) ...[
                            const DsLabel('Simulator'),
                            const SizedBox(height: 8),
                          ],
                          Text('Hitung pajak Anda',
                              style: T.serif(bp.isExpanded ? 29 : 23)),
                          const SizedBox(height: 4),
                          Text(
                            bp.isExpanded
                                ? 'Versi web memakai alur yang sama — hanya lebih lapang.'
                                : 'Tiga pertanyaan, tanpa istilah rumit.',
                            style: T.sans(bp.isExpanded ? 15 : 13.5,
                                color: DS.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _SimulatorTabs(controller: _tabCtrl, labels: _tabs, pad: pad),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    // NeverScrollable supaya input rupiah tidak bentrok
                    // dengan gestur geser antar-tab.
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      TaxConversationTab(),
                      ScenarioTab(),
                      CalendarTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Tab bergaya pil, menggantikan TabBar bergaris bawah.
class _SimulatorTabs extends StatelessWidget {
  const _SimulatorTabs({
    required this.controller,
    required this.labels,
    required this.pad,
  });

  final TabController controller;
  final List<String> labels;
  final double pad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: DS.hairline)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Bp.contentMax),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _TabPill(
                      label: labels[i],
                      selected: controller.index == i,
                      onTap: () => controller.animateTo(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? DS.brandMuted : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              label,
              style: T.sans(13.5,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? DS.brandInk : DS.muted),
            ),
          ),
        ),
      ),
    );
  }
}
