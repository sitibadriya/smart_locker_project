SMART LOCKER - LIB REVISI TERSTRUKTUR

Isi: folder lib/ yang sudah dipisah core, layouts, screens/web dan screens/mobile.
Integrasi Firebase, FCM, model, repository dan service dari source asli DIPERTAHANKAN.

PENERAPAN:
1. Backup folder lib lama.
2. Ekstrak folder lib dari paket ini ke root project Flutter (replace).
3. Jalankan flutter pub get lalu flutter run -d chrome / flutter run -d <device>.

Catatan jujur: file page adapter saat ini memanggil screen lama agar alur Firebase/Firestore existing tidak putus. UI shell Web dan Mobile sudah dipisah; screen isi belum seluruhnya ditulis ulang secara visual per platform.
