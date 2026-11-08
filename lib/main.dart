import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';
import 'layouts/web_layout.dart';
import 'layouts/mobile_layout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Inisialisasi Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Inisialisasi Notification Service
    await NotificationService.initialize();

    // 3. Registrasi FCM khusus Web
    if (kIsWeb) {
      await _initializeWebFCM();
    }

    // 4. Jalankan aplikasi
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('INISIALISASI APLIKASI GAGAL: $e');
    debugPrintStack(stackTrace: stackTrace);

    runApp(const StartupErrorApp());
  }
}

/// Inisialisasi FCM hanya untuk platform Web.
Future<void> _initializeWebFCM() async {
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'STATUS IZIN NOTIFIKASI WEB: ${settings.authorizationStatus}',
    );

    final token = await FirebaseMessaging.instance.getToken(
      vapidKey:
          'BK20WcgvslOWcyrDr_5CLoDVRZPyahSWlYGgNQBGr4tmDD-7a97-SdXSEjEILxRdHVgMGG2lj3r3RJo7SOqPfZQ',
    );

    if (token != null && token.isNotEmpty) {
      debugPrint('FCM TOKEN WEB: $token');

      await NotificationService.saveFcmToken(
        token,
        platform: 'web',
      );

      debugPrint('TOKEN WEB BERHASIL DISIMPAN KE FIRESTORE');
    } else {
      debugPrint('FCM TOKEN WEB TIDAK TERSEDIA');
    }
  } catch (e, stackTrace) {
    debugPrint('GAGAL REGISTRASI FCM WEB: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Locker IoT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // Web dan Mobile menggunakan layout berbeda.
      home: kIsWeb ? const WebLayout() : const MobileLayout(),
    );
  }
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 56,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aplikasi belum siap',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Periksa konfigurasi Firebase, '
                  'kemudian coba buka aplikasi kembali.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
