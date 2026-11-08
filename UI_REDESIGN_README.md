# Smart Locker - UI Web & Mobile Update

Paket ini adalah project Flutter lengkap (bukan hanya folder UI) yang mempertahankan konfigurasi Firebase, model, repository, layanan notifikasi, dan fitur yang sudah ada.

## Pemisahan platform
- Web (`kIsWeb`): `HomeScreen` dengan sidebar administrasi dan menu Dashboard, Data Santri, Manajemen Locker, Fingerprint, Riwayat Akses, Status Sistem.
- Android/iOS: `MobileHomeScreen` dengan header ringkas, bottom navigation Beranda/Locker/Santri/Riwayat, dan shortcut Fingerprint/Status Sistem.
- Keduanya memakai Firebase dan repository yang sama.

## Menjalankan
```bash
flutter pub get
flutter run -d chrome
flutter run -d <device-id-android>
```

Tidak perlu `flutter clean` kecuali cache/build bermasalah. File `firebase_options.dart` tetap milik project asli.

## Catatan
Paket mempertahankan screen dan alur data asli. Beberapa screen konten (Santri/Locker/Riwayat) masih memakai widget konten yang sama lintas platform; navigasi dan shell sudah dipisahkan. Untuk UX yang benar-benar native per menu, screen konten perlu migrasi bertahap ke widget `web/*` dan `mobile/*` tanpa mengganti repository.
