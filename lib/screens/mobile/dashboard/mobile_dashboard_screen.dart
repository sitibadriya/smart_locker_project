import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../models/santri.dart';
import '../../../widgets/mobile/mobile_lock_state.dart';
import 'mobile_beranda_view.dart';

/// Beranda mobile. Sumber data TIDAK berubah:
/// FirebaseFirestore.instance.collection('locker-config').snapshots()
/// dengan field `idLocker` dan `statusPintu` ('TERBUKA' / 'TERTUTUP').
/// `onLockerTap` tetap ada dan tetap dipanggil saat kartu locker diketuk.
///
/// Hal yang belum diketahui polanya di data lama dibuat sebagai pengait opsional,
/// supaya tidak ada nama field yang ditebak:
///  - [onUnlock]  : fungsi remote-unlock lama (null = slider terkunci / mode pantau)
///  - [isOnline]  : baca status online ESP32 dari dokumen locker-config
///  - [ownerOf]   : opsional; jika kosong, pemilik = santri dengan idSantri sama
///                  dengan activeSantriId locker (cadangan: santri.lockerId)
class MobileDashboardScreen extends StatefulWidget {
  final VoidCallback? onLockerTap;
  final VoidCallback? onFingerprint; // null = tile Fingerprint disembunyikan
  final VoidCallback? onHistory;
  final VoidCallback? onBell; // null = lonceng disembunyikan
  final int unreadCount;
  final Future<void> Function(String idLocker)? onUnlock;
  final bool? Function(Map<String, dynamic> data)? isOnline;
  final String? Function(Map<String, dynamic> data)? ownerOf;

  const MobileDashboardScreen({
    super.key,
    this.onLockerTap,
    this.onFingerprint,
    this.onHistory,
    this.onBell,
    this.unreadCount = 0,
    this.onUnlock,
    this.isOnline,
    this.ownerOf,
  });

  @override
  State<MobileDashboardScreen> createState() => _MobileDashboardScreenState();
}

class _MobileDashboardScreenState extends State<MobileDashboardScreen> {
  // Stream yang sama seperti sebelumnya, dibuat sekali agar tidak
  // berlangganan ulang saat pindah chip L01/L02.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      FirebaseFirestore.instance.collection('locker-config').snapshots();

  // Koleksi santri hanya DIBACA (model Santri.fromFirestore tidak diubah).
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _santriStream =
      FirebaseFirestore.instance.collection('santri').snapshots();

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Gagal memuat status locker', style: MobileText.body),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: MobileColors.softBlue),
          );
        }

        final lockers = snapshot.data?.docs ?? [];

        if (lockers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 46, color: MobileColors.textDim),
                SizedBox(height: 12),
                Text('Belum ada locker terdaftar', style: MobileText.body),
              ],
            ),
          );
        }

        String idOf(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
            (d.data()['idLocker'] ?? d.id).toString();

        final index = _selected.clamp(0, lockers.length - 1);
        final doc = lockers[index];
        final data = doc.data();
        final id = idOf(doc);
        final status = (data['statusPintu'] ?? '').toString();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _santriStream,
          builder: (context, santriSnap) {
            String? owner;
            if (widget.ownerOf != null) {
              owner = widget.ownerOf!(data);
            } else {
              // Pemilik = santri pada sesi aktif locker (activeSantriId, sama dengan
              // definisi "Terpakai" di halaman Locker); cadangan: santri.lockerId.
              final activeId = (data['activeSantriId'] ?? '').toString();
              Santri? match;
              Santri? byLocker;
              for (final d in santriSnap.data?.docs ?? const []) {
                final sn = Santri.fromFirestore(d.data());
                if (activeId.isNotEmpty && sn.idSantri == activeId) {
                  match = sn;
                  break;
                }
                if (sn.lockerId == id &&
                    (byLocker == null ||
                        (sn.statusAktif && !byLocker.statusAktif))) {
                  byLocker = sn;
                }
              }
              match ??= byLocker;
              owner = (match == null || match.nama.isEmpty) ? null : match.nama;
            }

            return MobileBerandaView(
              lockerLabels: lockers.map(idOf).toList(),
              selectedIndex: index,
              onSelectLocker: (i) => setState(() => _selected = i),
              state: status == 'TERBUKA'
                  ? MobileLockState.open
                  : MobileLockState.locked,
              online: widget.isOnline?.call(data),
              ownerName: owner,
              canUnlock: widget.onUnlock != null,
              onUnlock: () async {
                try {
                  await widget.onUnlock!(id);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Gagal mengirim perintah buka')),
                    );
                  }
                  rethrow; // slider kembali ke posisi awal
                }
              },
              onFingerprint: widget.onFingerprint,
              onHistory: widget.onHistory ?? () {},
              unreadCount: widget.unreadCount,
              onBell: widget.onBell,
              onCardTap: widget.onLockerTap,
            );
          },
        );
      },
    );
  }
}
