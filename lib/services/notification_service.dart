import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Push diterima di background: ${message.messageId}');
  debugPrint('Data push: ${message.data}');
}

/// NotificationService untuk Android dan Web.
///
/// Android:
/// - Push foreground ditampilkan memakai flutter_local_notifications.
/// - Push background/terminated ditangani Firebase Messaging.
///
/// Web:
/// - Push foreground diteruskan ke callback [onWebForegroundMessage].
/// - Push background ditampilkan oleh firebase-messaging-sw.js.
/// - Pastikan service worker dan VAPID key dikonfigurasi.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  // Samakan dengan channel Android yang digunakan Python notifier.
  static const String infoChannel = 'smart_locker_alerts';
  static const String warningChannel = 'smart_locker_alerts';
  static const String dangerChannel = 'smart_locker_alerts';

  static const String deviceCollection = 'notification-devices';

  static bool _initialized = false;
  static bool _listenersRegistered = false;

  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static StreamSubscription<String>? _tokenRefreshSubscription;

  /// Callback opsional untuk UI Web.
  /// Pasang callback ini dari halaman utama Flutter Web.
  static void Function(RemoteMessage message)? onWebForegroundMessage;

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    infoChannel,
    'Smart Locker Alerts',
    description: 'Informasi dan peringatan Smart Locker.',
    importance: Importance.max,
  );

  /// Inisialisasi listener setelah Firebase.initializeApp berhasil.
  static Future<void> initialize() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    if (!kIsWeb) {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const settings = InitializationSettings(
        android: androidSettings,
      );

      await _local.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notifikasi lokal diketuk: ${response.payload}');
          // TODO: arahkan ke detail locker/riwayat sesuai payload.
        },
      );

      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await android?.createNotificationChannel(_channel);
    }

    _registerListeners();
    _initialized = true;
  }

  /// Meminta izin notifikasi.
  /// Panggil dari tombol/aksi pengguna, terutama untuk Web.
  static Future<NotificationSettings> requestPermission() {
    return FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  static Future<NotificationSettings> getPermissionStatus() {
    return FirebaseMessaging.instance.getNotificationSettings();
  }

  /// Simpan token ke notification-devices.
  /// Document ID memakai token FCM.
  static Future<void> saveFcmToken(
    String token, {
    String? platform,
  }) async {
    final devicePlatform =
        platform ?? (kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase());

    await FirebaseFirestore.instance
        .collection(deviceCollection)
        .doc(token)
        .set({
      'token': token,
      'platform': devicePlatform,
      'enabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Mendapatkan token FCM.
  /// Web wajib menggunakan VAPID public key.
  static Future<String?> getDeviceToken({
    String? vapidKey,
  }) async {
    try {
      if (kIsWeb && (vapidKey == null || vapidKey.trim().isEmpty)) {
        debugPrint('Token Web gagal diminta: VAPID public key kosong.');
        return null;
      }

      final token = kIsWeb
          ? await FirebaseMessaging.instance.getToken(vapidKey: vapidKey)
          : await FirebaseMessaging.instance.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('FCM token kosong.');
        return null;
      }

      // Hindari mencetak token lengkap ke log produksi.
      debugPrint('FCM token berhasil diperoleh (${kIsWeb ? "Web" : "HP"}).');

      await saveFcmToken(token);
      debugPrint('FCM token berhasil disimpan ke Firestore.');

      return token;
    } catch (e, stackTrace) {
      debugPrint('Gagal mendapatkan FCM token: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Meminta izin, mengambil token, dan mendaftarkan perangkat.
  static Future<String?> enableAndRegisterDevice({
    String? vapidKey,
  }) async {
    try {
      final settings = await requestPermission();

      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!allowed) {
        debugPrint(
          'Izin notifikasi tidak diberikan: ${settings.authorizationStatus}',
        );
        return null;
      }

      final token = await getDeviceToken(vapidKey: vapidKey);
      if (token == null || token.isEmpty) return null;

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          await saveFcmToken(newToken);
          debugPrint('FCM token diperbarui dan disimpan.');
        } catch (e, stackTrace) {
          debugPrint('Gagal menyimpan token baru: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      });

      return token;
    } catch (e, stackTrace) {
      debugPrint('Gagal mendaftarkan perangkat FCM: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static void _registerListeners() {
    if (_listenersRegistered) return;
    _listenersRegistered = true;

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(_showForegroundNotification(message));
    });

    _openedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    unawaited(_handleInitialMessage());
  }

  static Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null) _handleNotificationTap(message);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    debugPrint(
      'Notifikasi dibuka. '
      'Jenis: ${data['type'] ?? data['category']}, '
      'Locker: ${data['idLocker'] ?? data['locker_id']}',
    );

    // TODO: navigasi ke halaman notifikasi/locker.
    // Gunakan data['idLocker'] atau data['locker_id'].
  }

  static String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return fallback;
  }

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final data = message.data;

    final title = message.notification?.title ??
        _readString(data, ['title', 'judul'], fallback: 'Smart Locker');

    final body = message.notification?.body ??
        _readString(
          data,
          ['body', 'message', 'pesan', 'description'],
          fallback: 'Ada aktivitas baru pada Smart Locker.',
        );

    if (kIsWeb) {
      // Firebase Messaging Web foreground tidak otomatis menampilkan
      // notification system untuk pesan data-only.
      onWebForegroundMessage?.call(message);
      debugPrint('Push Web foreground diterima: $title');
      return;
    }

    final rawLevel = _readString(data, ['level', 'severity'], fallback: 'info')
        .toLowerCase();

    final isDanger = rawLevel == 'danger' ||
        rawLevel == 'critical' ||
        rawLevel == 'error';

    final isWarning = rawLevel == 'warning' || rawLevel == 'warn';

    final priority = isDanger
        ? Priority.max
        : isWarning
            ? Priority.high
            : Priority.defaultPriority;

    final importance = isDanger
        ? Importance.max
        : isWarning
            ? Importance.high
            : Importance.defaultImportance;

    final lockerId = _readString(data, ['idLocker', 'locker_id', 'locker']);
    final notificationId =
        message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch;

    await _local.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: importance,
          priority: priority,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      payload: lockerId,
    );
  }

  /// Menonaktifkan token perangkat di Firestore.
  /// Tidak menghapus dokumen agar riwayat registrasi tetap ada.
  static Future<void> disableCurrentDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await FirebaseFirestore.instance
          .collection(deviceCollection)
          .doc(token)
          .set({
        'enabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseMessaging.instance.deleteToken();
      debugPrint('Perangkat berhasil dinonaktifkan dari notifikasi.');
    } catch (e) {
      debugPrint('Gagal menonaktifkan perangkat: $e');
    }
  }

  static Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();

    _foregroundSubscription = null;
    _openedSubscription = null;
    _tokenRefreshSubscription = null;
    _listenersRegistered = false;
    _initialized = false;
  }
}
