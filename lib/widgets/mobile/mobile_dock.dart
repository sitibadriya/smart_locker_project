import 'package:flutter/material.dart';
import '../../core/theme/mobile_colors.dart';

class MobileDockItem {
  final IconData icon;
  final String semanticLabel; // dibaca screen reader; tidak ditampilkan
  const MobileDockItem(this.icon, this.semanticLabel);
}

/// Dock bulat tanpa tulisan. Daftar item disusun oleh layout sesuai peran:
/// Admin/Pembina: 5 item; Sarpras: tanpa item Santri.
class MobileDock extends StatelessWidget {
  final List<MobileDockItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MobileDock({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  /// Item standar sesuai desain: Beranda, Locker, Santri, Riwayat, Akun.
  static List<MobileDockItem> defaultItems({bool withSantri = true}) => [
        const MobileDockItem(Icons.home_rounded, 'Beranda'),
        const MobileDockItem(Icons.lock_rounded, 'Locker'),
        if (withSantri) const MobileDockItem(Icons.groups_rounded, 'Santri'),
        const MobileDockItem(Icons.history_rounded, 'Riwayat'),
        const MobileDockItem(Icons.person_rounded, 'Akun'),
      ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: MobileColors.dock,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withAlpha(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(110),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                _DockButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  final MobileDockItem item;
  final bool selected;
  final VoidCallback onTap;
  const _DockButton(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? MobileColors.softBlue : Colors.transparent,
          ),
          child: Icon(
            item.icon,
            size: 24,
            color: selected ? MobileColors.bgTop : MobileColors.textDim,
          ),
        ),
      ),
    );
  }
}
