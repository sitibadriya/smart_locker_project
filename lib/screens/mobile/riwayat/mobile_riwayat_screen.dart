import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../widgets/mobile/mobile_stat_card.dart';

enum _Filter { semua, diizinkan, ditolak }

/// Riwayat akses (tampilan baru). Sumber data sama: koleksi `locker-activity`
/// diurutkan `waktu` terbaru; kini dibatasi per halaman (50) + "Muat lebih banyak".
class MobileRiwayatScreen extends StatefulWidget {
  const MobileRiwayatScreen({super.key});

  @override
  State<MobileRiwayatScreen> createState() => _MobileRiwayatScreenState();
}

class _MobileRiwayatScreenState extends State<MobileRiwayatScreen> {
  static const int _step = 100;

  int _limit = _step;
  _Filter _filter = _Filter.semua;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream = _open();

  // Total sebenarnya dihitung di server (tanpa memuat semua dokumen),
  // supaya angka tidak ikut mengecil saat daftar dibatasi per halaman.
  int? _totalAllowed;
  int? _totalDenied;
  String? _lastFirstId;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  Future<void> _loadTotals() async {
    try {
      final col = FirebaseFirestore.instance.collection('locker-activity');
      final a =
          await col.where('hasilAkses', isEqualTo: 'DIIZINKAN').count().get();
      final d =
          await col.where('hasilAkses', isEqualTo: 'DITOLAK').count().get();
      if (!mounted) return;
      setState(() {
        _totalAllowed = a.count ?? 0;
        _totalDenied = d.count ?? 0;
      });
    } catch (_) {
      // Gagal menghitung: pakai hitungan dari catatan yang termuat.
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _open() {
    return FirebaseFirestore.instance
        .collection('locker-activity')
        .orderBy('waktu', descending: true)
        .limit(_limit)
        .snapshots();
  }

  void _loadMore() {
    setState(() {
      _limit += _step;
      _stream = _open();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 46, color: MobileColors.denied),
                    SizedBox(height: 12),
                    Text('Gagal memuat riwayat', style: MobileText.body),
                    SizedBox(height: 6),
                    Text('Periksa koneksi atau konfigurasi Firestore.',
                        textAlign: TextAlign.center,
                        style: MobileText.caption),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: MobileColors.softBlue),
            );
          }

          final docs = snapshot.data!.docs;
          final all = docs.map((d) => d.data()).toList();
          final diizinkan = _totalAllowed ??
              all.where((d) => d['hasilAkses'] == 'DIIZINKAN').length;
          final ditolak = _totalDenied ??
              all.where((d) => d['hasilAkses'] == 'DITOLAK').length;

          // Ada catatan baru -> segarkan total.
          if (docs.isNotEmpty && docs.first.id != _lastFirstId) {
            _lastFirstId = docs.first.id;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _loadTotals());
          }

          final shown = all.where((d) {
            if (_filter == _Filter.diizinkan) {
              return d['hasilAkses'] == 'DIIZINKAN';
            }
            if (_filter == _Filter.ditolak) {
              return d['hasilAkses'] == 'DITOLAK';
            }
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Riwayat', style: MobileText.display),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text('Menampilkan ${all.length} terbaru',
                        style: MobileText.caption),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: MobileStatCard(
                      icon: Icons.check_circle_outline_rounded,
                      value: '$diizinkan',
                      title: 'Diizinkan',
                      color: MobileColors.open,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MobileStatCard(
                      icon: Icons.cancel_outlined,
                      value: '$ditolak',
                      title: 'Ditolak',
                      color: MobileColors.denied,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    MobileFilterChip(
                      label: 'Semua',
                      selected: _filter == _Filter.semua,
                      onTap: () => setState(() => _filter = _Filter.semua),
                    ),
                    const SizedBox(width: 10),
                    MobileFilterChip(
                      label: 'Diizinkan',
                      selected: _filter == _Filter.diizinkan,
                      onTap: () => setState(() => _filter = _Filter.diizinkan),
                    ),
                    const SizedBox(width: 10),
                    MobileFilterChip(
                      label: 'Ditolak',
                      selected: _filter == _Filter.ditolak,
                      onTap: () => setState(() => _filter = _Filter.ditolak),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (shown.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: MobileColors.card.withAlpha(170),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 46, color: MobileColors.textDim),
                      SizedBox(height: 12),
                      Text('Belum ada catatan', style: MobileText.body),
                      SizedBox(height: 6),
                      Text('Aktivitas akses locker akan tampil di sini.',
                          textAlign: TextAlign.center,
                          style: MobileText.caption),
                    ],
                  ),
                )
              else
                ...shown.map((d) => _HistoryCard(data: d)),
              if (docs.length >= _limit) ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _loadMore,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MobileColors.softBlue,
                      side: BorderSide(
                          color: MobileColors.softBlue.withAlpha(90)),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Muat lebih banyak'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HistoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasil = (data['hasilAkses'] ?? '').toString();
    final allowed = hasil == 'DIIZINKAN';
    final denied = hasil == 'DITOLAK';

    final color = allowed
        ? MobileColors.open
        : denied
            ? MobileColors.denied
            : MobileColors.textDim;
    final label = allowed
        ? 'Diizinkan'
        : denied
            ? 'Ditolak'
            : 'Tidak diketahui';

    final nama = (data['namaSantri'] ?? 'Tidak diketahui').toString();
    final locker = (data['idLocker'] ?? '-').toString();
    final fingerprint = (data['idFingerprint'] ?? '-').toString();
    final idSantri = (data['idSantri'] ?? '-').toString();
    final keterangan = (data['keterangan'] ?? '').toString().trim();

    final waktu = data['waktu'];
    final waktuTeks = waktu is Timestamp
        ? mobileDateTime(waktu.toDate())
        : 'Waktu tidak tersedia';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MobileColors.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withAlpha(36),
                ),
                child: Icon(
                  allowed
                      ? Icons.lock_open_rounded
                      : denied
                          ? Icons.block_rounded
                          : Icons.help_outline_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MobileText.title.copyWith(fontSize: 17)),
                    const SizedBox(height: 3),
                    Text(waktuTeks, style: MobileText.caption),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withAlpha(34),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: MobileText.caption
                        .copyWith(color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _Row(Icons.inventory_2_outlined, 'Locker', locker),
                const SizedBox(height: 10),
                _Row(Icons.fingerprint_rounded, 'Fingerprint', fingerprint),
                const SizedBox(height: 10),
                _Row(Icons.badge_outlined, 'ID Santri', idSantri),
              ],
            ),
          ),
          if (keterangan.isNotEmpty && keterangan != '-') ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: MobileColors.softBlue),
                const SizedBox(width: 8),
                Expanded(child: Text(keterangan, style: MobileText.caption)),
              ],
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
  final String value;
  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MobileColors.textDim),
        const SizedBox(width: 10),
        Text(label, style: MobileText.caption),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: MobileText.body
                .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
