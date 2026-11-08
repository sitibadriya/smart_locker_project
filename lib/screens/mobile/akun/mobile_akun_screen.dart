import 'package:flutter/material.dart';
import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../services/notification_service.dart';

/// Halaman Akun (UI saja). Data pengguna dan fungsi keluar dikirim dari luar,
/// jadi tidak ada koneksi Firebase baru di sini.
class MobileAkunScreen extends StatelessWidget {
  final String userName;
  final String? userEmail;
  final String roleLabel; // mis. 'Admin / Pembina' atau 'Sarpras'
  final VoidCallback? onFingerprint; // null = disembunyikan (Sarpras)
  final VoidCallback onSistem;
  final Future<void> Function()? onLogout; // null = tombol Keluar disembunyikan

  const MobileAkunScreen({
    super.key,
    required this.userName,
    this.userEmail,
    required this.roleLabel,
    this.onFingerprint,
    required this.onSistem,
    this.onLogout,
  });

  Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MobileColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Keluar dari akun?', style: MobileText.title),
        content: const Text('Kamu perlu masuk lagi untuk memakai aplikasi.',
            style: MobileText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal',
                style: TextStyle(color: MobileColors.softBlue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar',
                style: TextStyle(
                    color: MobileColors.denied, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (yes == true) await onLogout!();
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        userName.trim().isEmpty ? '?' : userName.trim()[0].toUpperCase();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text('Akun', style: MobileText.display),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: MobileColors.card,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: MobileColors.softBlue,
                  ),
                  child: Text(initial,
                      style: MobileText.title
                          .copyWith(color: MobileColors.bgTop, fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MobileText.title),
                      if (userEmail != null) ...[
                        const SizedBox(height: 2),
                        Text(userEmail!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MobileText.caption),
                      ],
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: MobileColors.locked.withAlpha(36),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(roleLabel,
                            style: MobileText.label
                                .copyWith(color: MobileColors.locked)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Row(
            icon: Icons.notifications_active_rounded,
            label: 'Notifikasi',
            onTap: () async {
              try {
                final token =
                    await NotificationService.enableAndRegisterDevice();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(token != null
                            ? 'Notifikasi aktif di perangkat ini'
                            : 'Izin notifikasi belum diberikan')),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Notifikasi belum dapat diaktifkan')),
                  );
                }
              }
            },
          ),
          _Row(
            icon: Icons.settings_rounded,
            label: 'Pengaturan',
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: MobileColors.card,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: const Text('Pengaturan', style: MobileText.title),
                content: const Text(
                  'Aplikasi Smart Locker menggunakan tema navy. '
                  'Pengaturan akun dan perangkat mengikuti konfigurasi sistem.',
                  style: MobileText.body,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
          ),
          if (onFingerprint != null)
            _Row(
                icon: Icons.fingerprint_rounded,
                label: 'Fingerprint',
                onTap: onFingerprint!),
          _Row(
              icon: Icons.monitor_heart_rounded,
              label: 'Status sistem',
              onTap: onSistem),
          if (onLogout != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: MobileColors.denied,
                  side: BorderSide(color: MobileColors.denied.withAlpha(140)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Row({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: MobileColors.card.withAlpha(170),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Icon(icon, color: MobileColors.softBlue),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: MobileText.body)),
                const Icon(Icons.chevron_right_rounded,
                    color: MobileColors.textDim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
