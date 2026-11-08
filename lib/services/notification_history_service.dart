import 'package:cloud_firestore/cloud_firestore.dart';

/// Akses realtime riwayat notifikasi yang ditulis oleh Python notifier.
class NotificationHistoryService {
  NotificationHistoryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String collectionName = 'notifications';

  /// Riwayat terbaru, realtime.
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchLatest({
    int limit = 100,
  }) {
    return _db
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Tandai notifikasi telah dibaca.
  static Future<void> markAsRead(String documentId) {
    return _db.collection(collectionName).doc(documentId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tandai seluruh notifikasi yang belum dibaca sebagai sudah dibaca.
  static Future<void> markAllAsRead(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final batch = _db.batch();
    for (final doc in docs) {
      if (doc.data()['read'] != true) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
    }
    await batch.commit();
  }

  /// Hapus satu notifikasi dari riwayat (opsional).
  static Future<void> delete(String documentId) {
    return _db.collection(collectionName).doc(documentId).delete();
  }
}
