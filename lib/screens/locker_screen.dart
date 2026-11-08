import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'locker_detail_screen.dart';
import '../services/notification_service.dart';

class LockerScreen extends StatefulWidget {
  const LockerScreen({super.key});

  @override
  State<LockerScreen> createState() => _LockerScreenState();
}

class _LockerScreenState extends State<LockerScreen> {
  static const Color navy = Color(0xFF0B1F3A);
  static const Color navyLight = Color(0xFF163E6D);
  static const Color background = Color(0xFFF4F7FB);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color green = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    try {
      await NotificationService.requestPermission();
    } catch (e) {
      debugPrint('Gagal meminta izin notifikasi: $e');
    }
  }

  // DIALOG TAMBAH / EDIT LOKER
  void _showLockerFormDialog(
    BuildContext context, {
    String? lockerId,
    String? currentDeviceId,
  }) {
    final isEdit = lockerId != null;
    final idController = TextEditingController(text: lockerId ?? '');

    final initialDevice = (currentDeviceId == null ||
            currentDeviceId.trim().isEmpty ||
            currentDeviceId == '-')
        ? 'esp32-locker-01'
        : currentDeviceId;

    final deviceController = TextEditingController(text: initialDevice);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEdit ? 'Edit Unit Loker $lockerId' : 'Tambah Unit Loker Baru',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                enabled: !isEdit,
                decoration: InputDecoration(
                  labelText: 'ID Locker',
                  hintText: 'Contoh: L01',
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: deviceController,
                decoration: InputDecoration(
                  labelText: 'ID Perangkat ESP32',
                  hintText: 'Contoh: esp32-locker-01',
                  prefixIcon: const Icon(Icons.developer_board_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final id = idController.text.trim();
                      final deviceId = deviceController.text.trim();

                      if (id.isEmpty || deviceId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'ID loker dan ID perangkat wajib diisi.',
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final docRef = FirebaseFirestore.instance
                            .collection('locker-config')
                            .doc(id);

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

                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDialogState(() => isLoading = false);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menyimpan loker: $e'),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  // KONFIRMASI HAPUS LOKER
  void _confirmDeleteLocker(BuildContext context, String lockerId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Hapus Loker $lockerId?'),
        content: const Text(
          'Dokumen konfigurasi unit loker ini akan dihapus permanen dari sistem.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('locker-config')
                    .doc(lockerId)
                    .delete();

                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus loker: $e'),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Data Locker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: navy,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showLockerFormDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('locker-config').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Terjadi kesalahan:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 70,
                    color: textGrey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Belum Ada Unit Loker',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Klik tombol (+) di bawah untuk menambah unit loker.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textGrey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final lockerId = docs[index].id;

              String deviceId = (data['idPerangkat'] ??
                      data['deviceId'] ??
                      data['device_id'] ??
                      '')
                  .toString()
                  .trim();

              if (deviceId.isEmpty) {
                deviceId = '-';
              }

              final activeSantriId = (data['activeSantriId'] ?? '').toString();
              final isTerpakai = activeSantriId.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LockerDetailScreen(
                                  idLocker: lockerId,
                                  idPerangkat: deviceId == '-'
                                      ? 'esp32-locker-01'
                                      : deviceId,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [navy, navyLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(17),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white,
                                  size: 29,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lockerId,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Perangkat: $deviceId',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: textGrey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 7),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: isTerpakai ? navy : green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isTerpakai
                                                ? 'Terpakai ($activeSantriId)'
                                                : 'Perangkat Aktif (Tersedia)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isTerpakai ? navy : green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: navy,
                              size: 20,
                            ),
                            onPressed: () => _showLockerFormDialog(
                              context,
                              lockerId: lockerId,
                              currentDeviceId: deviceId,
                            ),
                            tooltip: 'Edit Loker',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () =>
                                _confirmDeleteLocker(context, lockerId),
                            tooltip: 'Hapus Loker',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
