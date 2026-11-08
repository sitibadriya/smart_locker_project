import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../widgets/mobile/mobile_stat_card.dart';
import '../../../widgets/mobile/mobile_sub_header.dart';

/// Notifikasi di dalam aplikasi (UI saja). [events] = catatan `locker-activity`
/// berhasil akses DITOLAK, disaring oleh layout dari stream yang sudah ada.
class MobileNotifikasiScreen extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final VoidCallback onBack;

  const MobileNotifikasiScreen({
    super.key,
    required this.events,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          MobileSubHeader(
            title: 'Notifikasi',
            subtitle: 'Peringatan keamanan locker',
            onBack: onBack,
          ),
          const SizedBox(height: 18),
          if (events.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: MobileColors.card.withAlpha(170),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 46, color: MobileColors.textDim),
                  SizedBox(height: 12),
                  Text('Belum ada peringatan', style: MobileText.body),
                  SizedBox(height: 6),
                  Text('Akses yang ditolak akan muncul di sini.',
                      textAlign: TextAlign.center, style: MobileText.caption),
                ],
              ),
            )
          else
            ...events.map((e) {
              final nama = (e['namaSantri'] ?? 'Tidak diketahui').toString();
              final locker = (e['idLocker'] ?? '-').toString();
              final ket = (e['keterangan'] ?? '').toString().trim();
              final waktu = e['waktu'];
              final waktuTeks =
                  waktu is Timestamp ? mobileDateTime(waktu.toDate()) : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MobileColors.card,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: MobileColors.denied.withAlpha(36),
                      ),
                      child: const Icon(Icons.block_rounded,
                          color: MobileColors.denied, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Akses ditolak',
                              style: MobileText.title.copyWith(fontSize: 17)),
                          const SizedBox(height: 3),
                          Text('$nama · Locker $locker',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MobileText.body.copyWith(fontSize: 14)),
                          if (ket.isNotEmpty && ket != '-') ...[
                            const SizedBox(height: 3),
                            Text(ket, style: MobileText.caption),
                          ],
                          if (waktuTeks.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(waktuTeks, style: MobileText.caption),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
