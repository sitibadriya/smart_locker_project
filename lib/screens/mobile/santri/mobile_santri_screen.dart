import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../models/santri.dart';
import '../../../repositories/fingerprint_repository.dart';
import '../../../widgets/mobile/mobile_form_sheet.dart';
import '../../fingerprint_enrollment_screen.dart';

/// Halaman Santri (tampilan baru). Logika Firestore dan navigasi lama dipertahankan:
/// daftar dari FingerprintRepository.watchSantriAktif(), tambah/edit langsung ke
/// koleksi `santri`, pendaftaran fingerprint lewat FingerprintEnrollmentScreen.
class MobileSantriScreen extends StatefulWidget {
  const MobileSantriScreen({super.key});

  @override
  State<MobileSantriScreen> createState() => _MobileSantriScreenState();
}

class _MobileSantriScreenState extends State<MobileSantriScreen> {
  final FingerprintRepository _repository = FingerprintRepository();

  // Dibuat sekali agar mengetik di kolom pencarian tidak berlangganan ulang.
  late final Stream<List<Santri>> _santriStream =
      _repository.watchSantriAktif();

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // TAMBAH / EDIT SANTRI (isi dokumen sama seperti sebelumnya)
  // ============================================================

  Future<void> _showSantriForm({Santri? santri}) async {
    final isEdit = santri != null;

    final saved = await showMobileFormSheet(
      context: context,
      title: isEdit ? 'Edit santri' : 'Tambah santri',
      subtitle: isEdit
          ? 'Ubah nama untuk ${santri.idSantri}'
          : 'Daftarkan santri baru',
      icon: Icons.person_outline_rounded,
      submitLabel: isEdit ? 'Simpan' : 'Tambah',
      requiredMessage: 'ID dan nama santri wajib diisi.',
      fields: [
        MobileFieldSpec(
          key: 'id',
          label: 'ID / NIS santri',
          hint: 'Contoh: ST-2026-003',
          icon: Icons.badge_outlined,
          initial: santri?.idSantri ?? '',
          enabled: !isEdit,
        ),
        MobileFieldSpec(
          key: 'nama',
          label: 'Nama lengkap',
          hint: 'Masukkan nama santri',
          icon: Icons.person_outline_rounded,
          initial: santri?.nama ?? '',
          capitalization: TextCapitalization.words,
        ),
      ],
      onSubmit: (values) async {
        final id = values['id']!;
        final nama = values['nama']!;
        final docRef = FirebaseFirestore.instance.collection('santri').doc(id);

        if (!isEdit) {
          await docRef.set({
            'idSantri': id,
            'nama': nama,
            'lockerId': '',
            'statusAktif': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await docRef.update({
            'nama': nama,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      },
    );

    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Data santri berhasil diperbarui.'
                : 'Santri berhasil ditambahkan.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: MobileAddFab(
        label: 'Tambah santri',
        onPressed: () => _showSantriForm(),
      ),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Santri>>(
          stream: _santriStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: MobileColors.softBlue),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat data santri:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: MobileText.body,
                  ),
                ),
              );
            }

            final allSantri = snapshot.data ?? [];
            final query = _searchQuery.toLowerCase();

            final santriList = allSantri.where((santri) {
              return santri.nama.toLowerCase().contains(query) ||
                  santri.idSantri.toLowerCase().contains(query);
            }).toList();

            return ListView(
              // Padding bawah besar agar tombol + tidak menutupi kartu terakhir.
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                // HEADER (sama dengan halaman Locker)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Santri', style: MobileText.display),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text('${allSantri.length} aktif',
                          style: MobileText.caption),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // PENCARIAN
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _searchQuery = value.trim());
                  },
                  style: MobileText.body,
                  cursorColor: MobileColors.softBlue,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau ID santri',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            icon: const Icon(Icons.close_rounded,
                                color: MobileColors.textDim),
                          )
                        : null,
                    fillColor: MobileColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // KOSONG
                if (santriList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: MobileColors.card.withAlpha(170),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.groups_outlined,
                          size: 46,
                          color: MobileColors.textDim,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Santri tidak ditemukan'
                              : 'Belum ada santri aktif',
                          style: MobileText.body,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Coba gunakan nama atau ID lain.'
                              : 'Tekan + untuk menambahkan santri.',
                          textAlign: TextAlign.center,
                          style: MobileText.caption,
                        ),
                      ],
                    ),
                  ),

                // KARTU SANTRI
                ...santriList.map(
                  (santri) => _MobileSantriCard(
                    santri: santri,
                    onEdit: () => _showSantriForm(santri: santri),
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

// ============================================================
// KARTU SANTRI
// ============================================================

class _MobileSantriCard extends StatelessWidget {
  final Santri santri;
  final VoidCallback onEdit;

  const _MobileSantriCard({
    required this.santri,
    required this.onEdit,
  });

  /// Panel dalam kartu: lebih gelap dari kartu agar teks terang tetap terbaca.
  static final BoxDecoration _panel = BoxDecoration(
    color: MobileColors.bgTop.withAlpha(130),
    borderRadius: BorderRadius.circular(18),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
      decoration: BoxDecoration(
        color: MobileColors.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // INFO SANTRI (pola sama dengan kartu locker)
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MobileColors.softBlue.withAlpha(36),
                ),
                child: const Icon(Icons.person_rounded,
                    color: MobileColors.softBlue, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      santri.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MobileText.title.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 3),
                    Text(santri.idSantri, style: MobileText.caption),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit santri',
                icon: const Icon(Icons.edit_outlined,
                    color: MobileColors.textDim),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),

                // LOCKER
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('locker-config')
                      .where('activeSantriId', isEqualTo: santri.idSantri)
                      .snapshots(),
                  builder: (context, snapshot) {
                    var lockerName = '-';

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      lockerName = snapshot.data!.docs.first.id;
                    }

                    final hasLocker = lockerName != '-';

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: _panel,
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              color: MobileColors.softBlue, size: 20),
                          const SizedBox(width: 10),
                          const Text('Locker', style: MobileText.label),
                          const Spacer(),
                          Text(
                            hasLocker ? lockerName : 'Belum ada',
                            style: MobileText.body.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: hasLocker
                                  ? MobileColors.text
                                  : MobileColors.locked,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // FINGERPRINT
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('fingerprint-mapping')
                      .where('idSantri', isEqualTo: santri.idSantri)
                      .where('statusAktif', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final jumlah =
                        snapshot.hasData ? snapshot.data!.docs.length : 0;

                    final maksimal = jumlah >= 5;
                    final progress = (jumlah / 5).clamp(0.0, 1.0);
                    final accent =
                        maksimal ? MobileColors.open : MobileColors.softBlue;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: _panel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fingerprint_rounded,
                                  color: accent, size: 22),
                              const SizedBox(width: 10),
                              const Text('Fingerprint',
                                  style: MobileText.label),
                              const Spacer(),
                              Text(
                                '$jumlah / 5',
                                style: MobileText.body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor:
                                  MobileColors.textDim.withAlpha(60),
                              valueColor: AlwaysStoppedAnimation(accent),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: maksimal
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FingerprintEnrollmentScreen(
                                            santri: santri,
                                          ),
                                        ),
                                      );
                                    },
                              icon: Icon(
                                maksimal
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.fingerprint_rounded,
                                size: 20,
                              ),
                              label: Text(
                                maksimal
                                    ? 'Fingerprint lengkap'
                                    : 'Daftarkan fingerprint',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MobileColors.softBlue,
                                disabledForegroundColor: MobileColors.open,
                                side: BorderSide(
                                  color: maksimal
                                      ? MobileColors.open.withAlpha(110)
                                      : MobileColors.softBlue.withAlpha(110),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
