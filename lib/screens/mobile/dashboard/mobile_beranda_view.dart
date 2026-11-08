import 'package:flutter/material.dart';
import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../widgets/mobile/door_illustration.dart';
import '../../../widgets/mobile/mobile_lock_state.dart';
import '../../../widgets/mobile/slide_to_unlock.dart';

/// Tampilan Beranda (murni UI, tanpa akses Firebase).
/// Layar lama (mobile_dashboard / mobile_home) membungkus widget ini dan
/// mengisi parameter dari stream/provider yang SUDAH ada.
class MobileBerandaView extends StatelessWidget {
  final String title;
  final List<String> lockerLabels; // mis. ['L01', 'L02']
  final int selectedIndex;
  final ValueChanged<int> onSelectLocker;

  final MobileLockState state;
  final bool? online; // null = status online tidak diketahui
  final String deviceName; // mis. 'ESP32'
  final String? ownerName; // null = locker kosong

  final Future<void> Function() onUnlock;
  final VoidCallback? onRelock;
  final bool canUnlock; // false untuk Sarpras (mode pantau)

  final VoidCallback? onFingerprint; // null = tile disembunyikan (Sarpras)
  final VoidCallback onHistory;

  final int unreadCount;
  final VoidCallback? onBell; // null = lonceng disembunyikan
  final VoidCallback? onCardTap;

  const MobileBerandaView({
    super.key,
    this.title = 'Locker',
    required this.lockerLabels,
    required this.selectedIndex,
    required this.onSelectLocker,
    required this.state,
    this.online,
    this.deviceName = 'ESP32',
    this.ownerName,
    required this.onUnlock,
    this.onRelock,
    this.canUnlock = true,
    this.onFingerprint,
    required this.onHistory,
    this.unreadCount = 0,
    this.onBell,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Header(title: title, unread: unreadCount, onBell: onBell),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lockerLabels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _LockerChip(
                label: lockerLabels[i],
                selected: i == selectedIndex,
                onTap: () => onSelectLocker(i),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onCardTap,
            child: _MainCard(
              state: state,
              online: online,
              deviceName: deviceName,
              ownerName: ownerName,
            ),
          ),
          const SizedBox(height: 16),
          SlideToUnlock(
            key: ValueKey(lockerLabels[selectedIndex]),
            enabled: canUnlock,
            onUnlock: onUnlock,
            onRelock: onRelock,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onFingerprint != null) ...[
                Expanded(
                  child: _ActionTile(
                    icon: Icons.fingerprint_rounded,
                    label: 'Fingerprint',
                    onTap: onFingerprint!,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _ActionTile(
                  icon: Icons.history_rounded,
                  label: 'Riwayat',
                  onTap: onHistory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final int unread;
  final VoidCallback? onBell;
  const _Header({required this.title, required this.unread, required this.onBell});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: MobileText.display),
        const Spacer(),
        if (onBell != null)
        Semantics(
          button: true,
          label: unread > 0 ? 'Notifikasi, $unread belum dibaca' : 'Notifikasi',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBell,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MobileColors.card.withAlpha(170),
                    ),
                    child: const Icon(Icons.notifications_rounded, size: 22),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 6,
                      right: 8,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: MobileColors.denied,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: MobileColors.bgTop, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LockerChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _LockerChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? MobileColors.softBlue
              : MobileColors.card.withAlpha(150),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: MobileText.body.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? MobileColors.bgTop : MobileColors.textDim,
          ),
        ),
      ),
    );
  }
}

class _MainCard extends StatelessWidget {
  final MobileLockState state;
  final bool? online;
  final String deviceName;
  final String? ownerName;
  const _MainCard({
    required this.state,
    required this.online,
    required this.deviceName,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    final dot = online == null
        ? MobileColors.textDim
        : (online! ? MobileColors.open : MobileColors.denied);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: MobileColors.card,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(90),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    state.label,
                    key: ValueKey(state),
                    style: MobileText.status.copyWith(color: state.color),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    online == null
                        ? deviceName
                        : (online! ? 'Online · $deviceName' : 'Offline · $deviceName'),
                    style: MobileText.caption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          DoorIllustration(state: state),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_rounded,
                    size: 16, color: MobileColors.softBlue),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    ownerName ?? 'Kosong',
                    overflow: TextOverflow.ellipsis,
                    style: MobileText.body.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            color: MobileColors.card.withAlpha(170),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withAlpha(16)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: MobileColors.softBlue),
              const SizedBox(height: 8),
              Text(label, style: MobileText.label),
            ],
          ),
        ),
      ),
    );
  }
}
