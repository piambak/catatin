// lib/widgets/common/app_nav.dart
//
// Navigasi adaptif — mengikuti Catatin.dc.html.
//
// Di ponsel: pil mengambang di atas konten (artboard 1b/1c).
// Di web lebar: rail kiri yang bisa diperkecil (artboard 1b versi web).
//
// Urutan tab mengikuti mockup: Dashboard · Simulator · Pencatatan · Pengaturan.
// Urutan lama menaruh Pencatatan di posisi kedua. Rute tidak berubah, hanya
// urutan tampilannya.

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

/// Pil navigasi mengambang untuk layar sempit.
///
/// Ini satu dari dua tempat yang masih memakai bayangan — pil harus terbaca
/// terangkat di atas konten yang lewat di bawahnya.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: DS.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 0,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < destinations.length; i++)
              Expanded(
                child: _NavPill(
                  destination: destinations[i],
                  selected: i == currentIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? DS.brandMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.pill),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    destination.icon,
                    size: 22,
                    color: selected ? DS.brandDeep : DS.faint,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Typo.sans(10.5,
                        weight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected ? DS.brandInk : DS.muted,
                        height: 1.2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rail kiri untuk layar lebar. Bisa diperkecil jadi ikon saja.
class AppNavRail extends StatelessWidget {
  const AppNavRail({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelect,
    required this.expanded,
    required this.onToggle,
    this.userName,
    this.userRole,
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool expanded;
  final VoidCallback onToggle;
  final String? userName;
  final String? userRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expanded ? 248 : 92,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: BoxDecoration(
        color: DS.surface,
        border: Border(right: BorderSide(color: DS.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _railHeader(),
          const SizedBox(height: 24),
          for (var i = 0; i < destinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _RailItem(
                destination: destinations[i],
                selected: i == currentIndex,
                expanded: expanded,
                onTap: () => onSelect(i),
              ),
            ),
          const Spacer(),
          _railFooter(),
        ],
      ),
    );
  }

  Widget _railHeader() {
    final toggle = Semantics(
      button: true,
      label: expanded ? 'Perkecil menu' : 'Perbesar menu',
      child: Tooltip(
        message: expanded ? 'Perkecil menu' : 'Perbesar menu',
        child: InkWell(
          onTap: onToggle,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: expanded ? DS.sunken : DS.invSurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: expanded
                ? Icon(Icons.chevron_left_rounded, size: 20, color: DS.body)
                : Text('C',
                    style: Typo.serif(19, color: DS.invInk, height: 1)),
          ),
        ),
      ),
    );

    if (!expanded) return Center(child: toggle);

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: Typo.serif(24, color: DS.wordmark),
                children: [
                  const TextSpan(text: 'Catat'),
                  TextSpan(text: 'in', style: Typo.serif(24, color: DS.brand)),
                ],
              ),
            ),
          ),
        ),
        toggle,
      ],
    );
  }

  Widget _railFooter() {
    final initials = _initials(userName);
    final avatar = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: DS.wordmark, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials,
          style: Typo.sans(13.5, weight: FontWeight.w600, color: Colors.white)),
    );

    if (!expanded) return Center(child: avatar);

    return Padding(
      padding: const EdgeInsets.only(top: 14, left: 6),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName?.isNotEmpty == true ? userName! : 'Pengguna',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Typo.sans(13.5, weight: FontWeight.w500, color: DS.ink),
                ),
                if (userRole?.isNotEmpty == true)
                  Text(
                    userRole!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Typo.sans(11.5, color: DS.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String? name) {
    final parts =
        (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: EdgeInsets.symmetric(
          horizontal: expanded ? 14 : 0, vertical: 12),
      child: Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Icon(destination.icon,
              size: 20, color: selected ? DS.brand : DS.muted),
          if (expanded) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Typo.sans(14.5,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? DS.ink : DS.body),
              ),
            ),
          ],
        ],
      ),
    );

    return Semantics(
      selected: selected,
      button: true,
      child: Tooltip(
        message: expanded ? '' : destination.label,
        child: Material(
          color: selected ? DS.sunken : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.pill),
            child: content,
          ),
        ),
      ),
    );
  }
}
