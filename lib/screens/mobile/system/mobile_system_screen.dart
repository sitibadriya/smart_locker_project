import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../repositories/fingerprint_repository.dart';
import '../../../widgets/mobile/mobile_stat_card.dart';
import '../../../widgets/mobile/mobile_sub_header.dart';

/// Status sistem (tampilan navy, nilai NYATA dari Firestore; tidak ada teks
/// tetap "Terhubung/Aktif"). Hanya MEMBACA `locker-config` dan
/// FingerprintRepository.watchAllFingerprintMapping().
class MobileSystemScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MobileSystemScreen({super.key, required this.onBack});

  @override
  State<MobileSystemScreen> createState() => _MobileSystemScreenState();
}

class _MobileSystemScreenState extends State<MobileSystemScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _lockers =
      FirebaseFirestore.instance.collection('locker-config').snapshots();
  late final Stream<List<Map<String, dynamic>>> _fingerprints =
      FingerprintRepository().watchAllFingerprintMapping();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _lockers,
        builder: (context, snap) {
          final error = snap.hasError;
          final loading = !snap.hasData && !error;
          final docs = snap.data?.docs ?? const [];
          final syncing = snap.data?.metadata.isFromCache ?? false;

          final Color color;
          final IconData icon;
          final String title;
          final String desc;
          if (error) {
            color = MobileColors.denied;
            icon = Icons.cloud_off_rounded;
            title = 'Tidak terhubung';
            desc = 'Data locker tidak dapat dimuat. Periksa koneksi internet.';
          } else if (loading) {
            color = MobileColors.textDim;
            icon = Icons.sync_rounded;
            title = 'Memeriksa…';
            desc = 'Menghubungkan ke server.';
          } else if (syncing) {
            color = MobileColors.locked;
            icon = Icons.sync_rounded;
            title = 'Menyinkronkan';
            desc = 'Menampilkan data tersimpan sampai koneksi pulih.';
          } else {
            color = MobileColors.open;
            icon = Icons.cloud_done_rounded;
            title = 'Terhubung';
            desc = 'Data locker diterima langsung dari server.';
          }

          final terbuka = docs
              .where((d) => (d.data()['statusPintu'] ?? '') == 'TERBUKA')
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              MobileSubHeader(
                title: 'Status sistem',
                subtitle: 'Kondisi koneksi dan perangkat',
                onBack: widget.onBack,
              ),
              const SizedBox(height: 18),
              Container(
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
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withAlpha(36),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: MobileText.status
                                  .copyWith(fontSize: 26, color: color)),
                          const SizedBox(height: 6),
                          Text(desc, style: MobileText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MobileStatCard(
                      icon: Icons.inventory_2_rounded,
                      value: '${docs.length}',
                      title: 'Locker terdaftar',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MobileStatCard(
                      icon: Icons.lock_open_rounded,
                      value: '$terbuka',
                      title: 'Sedang terbuka',
                      color: terbuka > 0
                          ? MobileColors.open
                          : MobileColors.textDim,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _fingerprints,
                builder: (context, fp) {
                  final aktif = (fp.data ?? const [])
                      .where((e) => e['statusAktif'] == true)
                      .length;
                  return Row(
                    children: [
                      Expanded(
                        child: MobileStatCard(
                          icon: Icons.fingerprint_rounded,
                          value: fp.hasData ? '$aktif' : '–',
                          title: 'Fingerprint aktif',
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox.shrink()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 22),
              const Text('Perangkat', style: MobileText.title),
              const SizedBox(height: 12),
              if (docs.isEmpty && !loading)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: MobileColors.card.withAlpha(170),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Text('Belum ada locker terdaftar',
                        style: MobileText.body),
                  ),
                )
              else
                ...docs.map((d) {
                  final data = d.data();
                  var device = (data['idPerangkat'] ??
                          data['deviceId'] ??
                          data['device_id'] ??
                          '')
                      .toString()
                      .trim();
                  if (device.isEmpty) device = 'Perangkat belum terhubung';
                  final open = (data['statusPintu'] ?? '') == 'TERBUKA';
                  final c = open ? MobileColors.open : MobileColors.locked;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MobileColors.card,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: MobileColors.softBlue.withAlpha(36),
                          ),
                          child: const Icon(Icons.developer_board_rounded,
                              color: MobileColors.softBlue, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.id,
                                  style:
                                      MobileText.title.copyWith(fontSize: 17)),
                              const SizedBox(height: 3),
                              Text(device,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: MobileText.caption),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.withAlpha(34),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(open ? 'Terbuka' : 'Terkunci',
                              style: MobileText.caption.copyWith(
                                  color: c, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
