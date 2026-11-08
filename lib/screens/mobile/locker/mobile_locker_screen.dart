import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../repositories/locker_repository.dart';
import '../../../widgets/mobile/mobile_form_sheet.dart';
import '../../locker_detail_screen.dart';

/// Halaman Locker (tampilan baru). Logika Firestore dan navigasi lama dipertahankan:
/// tambah/edit/hapus langsung ke koleksi `locker-config`, detail ke LockerDetailScreen,
/// izin notifikasi kini diminta sekali oleh layout setelah masuk.
class MobileLockerScreen extends StatefulWidget {
  /// false untuk Sarpras: menyembunyikan Ganti pemilik dan Kosongkan.
  final bool canManageOwner;

  /// false untuk Sarpras (mode pantau): menyembunyikan tombol + Tambah locker,
  /// Edit perangkat, dan Hapus.
  final bool canEdit;

  /// Opsional: aksi "Ganti pemilik". Jika null, menu itu tidak ditampilkan.
  final void Function(String idLocker)? onGantiPemilik;

  /// false = mode pantau (Sarpras): halaman detail tanpa tombol Buka Loker dan
  /// Reset / Ganti Pemilik. Jika null, mengikuti [canManageOwner].
  final bool? canControl;

  /// Opsional: fungsi remote unlock yang dipakai halaman detail (mis. yang
  /// sekaligus mencatat ke remote-unlock-log). Jika null, detail memakai
  /// perintah lama (remoteCommand = UNLOCK).
  final Future<void> Function(String idLocker)? onRemoteUnlock;

  const MobileLockerScreen({
    super.key,
    this.canManageOwner = true,
    this.canEdit = true,
    this.onGantiPemilik,
    this.canControl,
    this.onRemoteUnlock,
  });

  @override
  State<MobileLockerScreen> createState() => _MobileLockerScreenState();
}

class _MobileLockerScreenState extends State<MobileLockerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LockerRepository _lockerRepository = LockerRepository();

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      _firestore.collection('locker-config').snapshots();

  // ============================================================
  // TAMBAH / EDIT LOCKER (isi dokumen sama seperti sebelumnya)
  // ============================================================

  Future<void> _showLockerForm(
      {String? lockerId, String? currentDeviceId}) async {
    final isEdit = lockerId != null;

    final initialDevice = currentDeviceId == null ||
            currentDeviceId.trim().isEmpty ||
            currentDeviceId == '-'
        ? 'esp32-locker-01'
        : currentDeviceId;

    var savedId = lockerId ?? '';

    final saved = await showMobileFormSheet(
      context: context,
      title: isEdit ? 'Edit locker' : 'Tambah locker',
      subtitle: isEdit
          ? 'Ubah perangkat ESP32 untuk $lockerId'
          : 'Daftarkan unit locker baru',
      icon: Icons.inventory_2_outlined,
      submitLabel: isEdit ? 'Simpan' : 'Tambah',
      requiredMessage: 'ID locker dan perangkat wajib diisi.',
      fields: [
        MobileFieldSpec(
          key: 'id',
          label: 'ID locker',
          hint: 'Contoh: L01',
          icon: Icons.inventory_2_outlined,
          initial: lockerId ?? '',
          enabled: !isEdit,
        ),
        MobileFieldSpec(
          key: 'device',
          label: 'ID perangkat ESP32',
          hint: 'Contoh: esp32-locker-01',
          icon: Icons.developer_board_outlined,
          initial: initialDevice,
        ),
      ],
      // Isi dokumen sama seperti sebelumnya.
      onSubmit: (values) async {
        final id = values['id']!;
        final deviceId = values['device']!;
        savedId = id;
        final docRef = _firestore.collection('locker-config').doc(id);

        if (!isEdit) {
          await docRef.set({
            'activeBatchId': '',
            'activeSantriId': '',
            'enrollCommand': 'IDLE',
            'idPerangkat': deviceId,
            'lastCommandTime': FieldValue.serverTimestamp(),
            'lastEnrollStatus': 'IDLE',
            'resetCommand': 'IDLE',
            'targetSlot': 0,
          });
        } else {
          await docRef.set({
            'idPerangkat': deviceId,
            'lastCommandTime': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      },
    );

    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? 'Locker $savedId berhasil diperbarui.'
                : 'Locker $savedId berhasil ditambahkan.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // HAPUS LOCKER
  // ============================================================

  void _confirmDeleteLocker(String lockerId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MobileColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Hapus locker $lockerId?', style: MobileText.title),
        content: const Text(
          'Dokumen konfigurasi locker ini akan dihapus permanen.',
          style: MobileText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal',
                style: TextStyle(color: MobileColors.softBlue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MobileColors.denied,
              foregroundColor: MobileColors.bgTop,
            ),
            onPressed: () async {
              try {
                await _firestore
                    .collection('locker-config')
                    .doc(lockerId)
                    .delete();

                if (dialogContext.mounted) Navigator.pop(dialogContext);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Locker $lockerId berhasil dihapus.'),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Gagal menghapus locker: $e')),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KOSONGKAN (memakai LockerRepository.sendResetLockerCommand yang lama)
  // ============================================================

  void _confirmKosongkan(String lockerId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MobileColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Kosongkan locker $lockerId?', style: MobileText.title),
        content: const Text(
          'Perintah reset pemilik akan dikirim ke perangkat.',
          style: MobileText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal',
                style: TextStyle(color: MobileColors.softBlue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MobileColors.locked,
              foregroundColor: MobileColors.bgTop,
            ),
            onPressed: () async {
              try {
                await _lockerRepository.sendResetLockerCommand(lockerId);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Perintah kosongkan $lockerId terkirim.'),
                    ),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Gagal mengosongkan locker: $e')),
                  );
                }
              }
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL LOCKER
  // ============================================================

  void _openLockerDetail(String lockerId, String deviceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LockerDetailScreen(
          idLocker: lockerId,
          idPerangkat: deviceId == '-' ? 'esp32-locker-01' : deviceId,
          dark: true,
          canControl: widget.canControl ?? widget.canManageOwner,
          onRemoteUnlock: widget.onRemoteUnlock,
        ),
      ),
    );
  }

  void _onMenu(String value, String lockerId, String deviceId) {
    switch (value) {
      case 'detail':
        _openLockerDetail(lockerId, deviceId);
        break;
      case 'edit':
        _showLockerForm(lockerId: lockerId, currentDeviceId: deviceId);
        break;
      case 'ganti':
        widget.onGantiPemilik?.call(lockerId);
        break;
      case 'kosongkan':
        _confirmKosongkan(lockerId);
        break;
      case 'hapus':
        _confirmDeleteLocker(lockerId);
        break;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.canEdit
          ? MobileAddFab(
              label: 'Tambah locker',
              onPressed: () => _showLockerForm(),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stream,
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
                    'Gagal memuat locker:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: MobileText.body,
                  ),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Locker', style: MobileText.display),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text('${docs.length} unit',
                          style: MobileText.caption),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (docs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: MobileColors.card.withAlpha(170),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 46, color: MobileColors.textDim),
                        SizedBox(height: 12),
                        Text('Belum ada unit locker', style: MobileText.body),
                        SizedBox(height: 6),
                        Text('Tekan + untuk menambahkan locker.',
                            textAlign: TextAlign.center,
                            style: MobileText.caption),
                      ],
                    ),
                  ),
                ...docs.map((doc) {
                  final data = doc.data();
                  final lockerId = doc.id;

                  String deviceId = (data['idPerangkat'] ??
                          data['deviceId'] ??
                          data['device_id'] ??
                          '')
                      .toString()
                      .trim();
                  if (deviceId.isEmpty) deviceId = '-';

                  final activeSantriId =
                      (data['activeSantriId'] ?? '').toString();

                  return _LockerCard(
                    lockerId: lockerId,
                    deviceId: deviceId,
                    activeSantriId: activeSantriId,
                    canEdit: widget.canEdit,
                    canKosongkan: widget.canManageOwner,
                    canGanti:
                        widget.canManageOwner && widget.onGantiPemilik != null,
                    onTap: () => _openLockerDetail(lockerId, deviceId),
                    onMenu: (v) => _onMenu(v, lockerId, deviceId),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// KARTU LOCKER
// ============================================================

class _LockerCard extends StatelessWidget {
  final String lockerId;
  final String deviceId;
  final String activeSantriId;
  final bool canEdit;
  final bool canKosongkan;
  final bool canGanti;
  final VoidCallback onTap;
  final ValueChanged<String> onMenu;

  const _LockerCard({
    required this.lockerId,
    required this.deviceId,
    required this.activeSantriId,
    required this.canEdit,
    required this.canKosongkan,
    required this.canGanti,
    required this.onTap,
    required this.onMenu,
  });

  PopupMenuItem<String> _item(String value, IconData icon, String label,
      {Color color = MobileColors.text}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(label, style: MobileText.body.copyWith(color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final terpakai = activeSantriId.isNotEmpty;
    final chipColor = terpakai ? MobileColors.softBlue : MobileColors.textDim;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: MobileColors.card,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: MobileColors.softBlue.withAlpha(36),
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: MobileColors.softBlue, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lockerId,
                          style: MobileText.title.copyWith(fontSize: 18)),
                      const SizedBox(height: 3),
                      Text(
                        deviceId == '-'
                            ? 'Perangkat belum terhubung'
                            : deviceId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MobileText.caption,
                      ),
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: chipColor.withAlpha(34),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: terpakai
                            ? _OwnerLabel(
                                santriId: activeSantriId,
                                color: chipColor,
                              )
                            : Text(
                                'Tersedia',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MobileText.caption.copyWith(
                                    color: chipColor,
                                    fontWeight: FontWeight.w700),
                              ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Aksi locker',
                  icon: const Icon(Icons.more_vert_rounded,
                      color: MobileColors.textDim),
                  onSelected: onMenu,
                  itemBuilder: (_) => [
                    _item('detail', Icons.open_in_new_rounded, 'Detail'),
                    if (canEdit)
                      _item('edit', Icons.edit_outlined, 'Edit perangkat'),
                    if (canGanti)
                      _item('ganti', Icons.swap_horiz_rounded, 'Ganti pemilik'),
                    if (canKosongkan)
                      _item('kosongkan', Icons.person_off_outlined, 'Kosongkan',
                          color: MobileColors.locked),
                    if (canEdit)
                      _item('hapus', Icons.delete_outline_rounded, 'Hapus',
                          color: MobileColors.denied),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Label pemilik pada kartu locker: tampil NAMA santri (cadangan: ID).
class _OwnerLabel extends StatelessWidget {
  final String santriId;
  final Color color;

  const _OwnerLabel({required this.santriId, required this.color});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('santri')
          .doc(santriId)
          .snapshots(),
      builder: (context, snapshot) {
        var nama = santriId;
        final data = snapshot.data?.data();
        final n = (data?['nama'] ?? '').toString().trim();
        if (n.isNotEmpty) nama = n;

        return Text(
          'Terpakai · $nama',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: MobileText.caption
              .copyWith(color: color, fontWeight: FontWeight.w700),
        );
      },
    );
  }
}
