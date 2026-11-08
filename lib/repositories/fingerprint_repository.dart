import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/santri.dart';

class FingerprintRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // DATA SANTRI AKTIF
  // ==========================================

  Stream<List<Santri>> watchSantriAktif() {
    return _firestore
        .collection('santri')
        .where('statusAktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Santri.fromFirestore(doc.data()))
          .toList();
    });
  }

  // ==========================================
  // FINGERPRINT MILIK SANTRI
  // ==========================================

  // Di dalam FingerprintRepository
  Stream<List<Map<String, dynamic>>> watchFingerprintSantri(String idSantri) {
    return _firestore
        .collection('fingerprint-mapping')
        .where('idSantri', isEqualTo: idSantri)
        .where('statusAktif', isEqualTo: true) // <--- PASTIKAN FILTER INI ADA
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ==========================================
  // HITUNG FINGERPRINT AKTIF
  // ==========================================

  Future<int> hitungFingerprintSantri(String idSantri) async {
    final snapshot = await _firestore
        .collection('fingerprint-mapping')
        .where('idSantri', isEqualTo: idSantri)
        .where('statusAktif', isEqualTo: true)
        .get();

    return snapshot.docs.length;
  }

  // ==========================================
  // BATAS MAKSIMAL 5 FINGERPRINT
  // ==========================================

  Future<bool> bisaDaftarFingerprint(String idSantri) async {
    final jumlah = await hitungFingerprintSantri(idSantri);
    return jumlah < 5;
  }

  // ==========================================
  // NONAKTIFKAN MAPPING LAMA
  // Hanya dipanggil jika memang diperlukan.
  // Tidak dijalankan otomatis saat enrollment.
  // ==========================================

  Future<void> nonaktifkanMappingLama(String idSantri) async {
    final snapshot = await _firestore
        .collection('fingerprint-mapping')
        .where('idSantri', isEqualTo: idSantri)
        .where('statusAktif', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'statusAktif': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // ==========================================
  // MULAI ENROLLMENT
  // ==========================================

  Future<String> mulaiEnrollment({
    required String idSantri,
    required String namaSantri,
    required String idLocker,
    required String idPerangkat,
  }) async {
    // 1. Periksa jumlah fingerprint aktif.
    final jumlah = await hitungFingerprintSantri(idSantri);

    if (jumlah >= 5) {
      throw Exception('Santri sudah memiliki 5 fingerprint aktif.');
    }

    // 2. Buat batch enrollment baru.
    final batchId =
        'B${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

    // 3. Siapkan referensi dokumen konfigurasi locker.
    final configRef = _firestore.collection('locker-config').doc(idLocker);

    // 4. Perbarui konfigurasi melalui transaksi.
    // Nilai perintah yang sudah ada tetap dipertahankan.
    await _firestore.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(configRef);

      final data = snapshot.data() ?? <String, dynamic>{};

      final remoteCommand = (data['remoteCommand'] ?? 'IDLE').toString();

      final resetCommand = (data['resetCommand'] ?? 'IDLE').toString();

      // Jangan memulai enrollment ketika ada perintah lain
      // yang masih aktif.
      if (remoteCommand != 'IDLE') {
        throw Exception(
          'Locker sedang memiliki perintah remote: $remoteCommand',
        );
      }

      if (resetCommand != 'IDLE') {
        throw Exception(
          'Locker sedang memiliki perintah reset: $resetCommand',
        );
      }

      final configUpdate = <String, dynamic>{
        'activeBatchId': batchId,
        'activeSantriId': idSantri,
        'idLocker': idLocker,
        'idPerangkat': idPerangkat,
        'remoteCommand': remoteCommand,
        'resetCommand': resetCommand,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      transaction.set(
        configRef,
        configUpdate,
        SetOptions(merge: true),
      );
    });

    // 5. Kirim perintah enrollment ke ESP32.
    final commandRef =
        _firestore.collection('enrollment-commands').doc(idPerangkat);

    await commandRef.set({
      'command': 'START_ENROLL',
      'idSantri': idSantri,
      'namaSantri': namaSantri,
      'idLocker': idLocker,
      'idPerangkat': idPerangkat,
      'batchId': batchId,
      'status': 'pending',
      'errorMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return batchId;
  }

  // ==========================================
  // SIMPAN MAPPING LANGSUNG
  // Tidak membutuhkan fingerprint-pending.
  // ==========================================

  Future<void> simpanMapping({
    String? pendingDocumentId,
    required int idSensor,
    required String idFingerprint,
    required String idSantri,
    required String namaSantri,
    required String idLocker,
    required String idPerangkat,
    required String jari,
    required int urutanJari,
  }) async {
    // Validasi ID dan urutan jari.
    if (idSensor <= 0) {
      throw Exception('ID sensor tidak valid.');
    }

    if (urutanJari < 1 || urutanJari > 5) {
      throw Exception('Urutan jari harus antara 1 sampai 5.');
    }

    const labelJari = {
      1: ('FP01', 'JEMPOL'),
      2: ('FP02', 'TELUNJUK'),
      3: ('FP03', 'TENGAH'),
      4: ('FP04', 'MANIS'),
      5: ('FP05', 'KELINGKING'),
    };

    final label = labelJari[urutanJari]!;

    if (idFingerprint != label.$1 || jari != label.$2) {
      throw Exception('Label fingerprint tidak sesuai dengan urutan jari.');
    }

    // Ambil konfigurasi locker untuk memperoleh batch aktif.
    final configSnapshot =
        await _firestore.collection('locker-config').doc(idLocker).get();

    if (!configSnapshot.exists) {
      throw Exception('Konfigurasi locker $idLocker tidak ditemukan.');
    }

    final configData = configSnapshot.data();
    final batchId = configData?['activeBatchId']?.toString() ?? '';
    final activeSantriId = configData?['activeSantriId']?.toString() ?? '';

    if (batchId.isEmpty) {
      throw Exception('Batch enrollment belum tersedia.');
    }

    if (activeSantriId != idSantri) {
      throw Exception('Santri tidak sesuai dengan sesi enrollment locker.');
    }

    // Format ID dokumen harus sama dengan yang dibaca ESP32.
    final documentId = '${idLocker}_${batchId}_${idFingerprint}';

    final mappingRef =
        _firestore.collection('fingerprint-mapping').doc(documentId);

    // Cegah satu ID sensor dipetakan ke dua label
    // dalam batch yang sama.
    final existingMappings = await _firestore
        .collection('fingerprint-mapping')
        .where('idLocker', isEqualTo: idLocker)
        .where('batchId', isEqualTo: batchId)
        .where('idSensor', isEqualTo: idSensor)
        .where('statusAktif', isEqualTo: true)
        .get();

    for (final doc in existingMappings.docs) {
      if (doc.id != documentId) {
        throw Exception(
          'ID sensor $idSensor sudah digunakan pada mapping lain.',
        );
      }
    }

    // Simpan mapping secara langsung ke Firestore.
    await mappingRef.set({
      'batchId': batchId,
      'idFingerprint': idFingerprint,
      'idSensor': idSensor,
      'idSantri': idSantri,
      'namaSantri': namaSantri,
      'idLocker': idLocker,
      'idPerangkat': idPerangkat,
      'jari': jari,
      'urutanJari': urutanJari,
      'statusAktif': true,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================================
  // SEMUA FINGERPRINT MAPPING AKTIF
  // ==========================================

  Stream<List<Map<String, dynamic>>> watchAllFingerprintMapping() {
    return _firestore
        .collection('fingerprint-mapping')
        .where('statusAktif', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {...doc.data(), 'documentId': doc.id};
      }).toList();
    });
  }
}
