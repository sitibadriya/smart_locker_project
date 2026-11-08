import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/mobile_colors.dart';
import '../core/theme/mobile_theme.dart';
import '../repositories/locker_repository.dart';
import '../services/notification_service.dart';
import '../widgets/mobile/mobile_dock.dart';

import '../screens/mobile/akun/mobile_akun_screen.dart';
import '../screens/mobile/dashboard/mobile_dashboard_screen.dart';
import '../screens/mobile/fingerprint/mobile_fingerprint_screen.dart';
import '../screens/mobile/locker/mobile_locker_screen.dart';
import '../screens/mobile/login/mobile_login_screen.dart';
import '../screens/mobile/notifikasi/mobile_notifikasi_screen.dart';
import '../screens/mobile/riwayat/mobile_riwayat_screen.dart';
import '../screens/mobile/santri/mobile_santri_screen.dart';
import '../screens/mobile/system/mobile_system_screen.dart';

/// Lima pertama = tab dock; fingerprint, sistem, notifikasi = halaman turunan
/// (punya tombol kembali sendiri di header).
enum _Page {
  beranda,
  locker,
  santri,
  riwayat,
  akun,
  fingerprint,
  sistem,
  notifikasi,
}

/// Pintu masuk mobile: Pilih peran -> Masuk -> Beranda/Akun -> Keluar.
///
/// - [requireLogin] true (default): tampilkan pilih peran + masuk dulu.
///   false: langsung masuk memakai [isSarpras]/[userName]/[userEmail].
/// - [onSignIn]: opsional, untuk menghubungkan autentikasi proyek. Peran
///   sungguhan tetap dibatasi oleh Security Rules; peran di sini mengatur tampilan.
class MobileLayout extends StatefulWidget {
  final bool requireLogin;
  final bool isSarpras;
  final String userName;
  final String? userEmail;
  final Future<void> Function()? onLogout;
  final Future<MobileSession?> Function(
      MobileRole role, String email, String password)? onSignIn;

  /// Opsional: menimpa fungsi remote-unlock. Jika kosong dipakai
  /// LockerRepository().sendRemoteUnlockCommand(idLocker) yang sudah ada.
  final Future<void> Function(String idLocker)? onRemoteUnlock;

  const MobileLayout({
    super.key,
    this.requireLogin = true,
    this.isSarpras = false,
    this.userName = 'Pengguna',
    this.userEmail,
    this.onLogout,
    this.onSignIn,
    this.onRemoteUnlock,
  });

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  final LockerRepository _lockerRepository = LockerRepository();

  MobileSession? _session;
  _Page _tab = _Page.beranda;
  _Page? _sub;

  /// Halaman dibangun saat pertama dibuka (bukan semuanya sekaligus),
  /// lalu dipertahankan agar posisi scroll dan input tidak hilang.
  final Set<_Page> _visited = {_Page.beranda};

  // Notifikasi dalam aplikasi: akses DITOLAK dari stream locker-activity.
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitySub;
  List<Map<String, dynamic>> _denied = [];
  DateTime _seenAt = DateTime.now();

  bool get _sarpras => _session?.role == MobileRole.sarpras;

  int get _unread => _denied.where((e) {
        final t = e['waktu'];
        return t is Timestamp && t.toDate().isAfter(_seenAt);
      }).length;

  @override
  void initState() {
    super.initState();
    if (!widget.requireLogin) {
      _resetFor(MobileSession(
        role: widget.isSarpras ? MobileRole.sarpras : MobileRole.admin,
        name: widget.userName,
        email: widget.userEmail,
      ));
      _afterStart();
    }
  }

  @override
  void dispose() {
    _activitySub?.cancel();
    super.dispose();
  }

  void _resetFor(MobileSession s) {
    _session = s;
    _tab = _Page.beranda;
    _sub = null;
    _visited
      ..clear()
      ..add(_Page.beranda);
    _seenAt = DateTime.now();
    _denied = [];
  }

  void _startSession(MobileSession s) {
    setState(() => _resetFor(s));
    _afterStart();
  }

  void _afterStart() {
    // Daftarkan token FCM perangkat ini (fungsi lama, tidak diubah).
    unawaited(NotificationService.enableAndRegisterDevice());

    _activitySub?.cancel();
    _activitySub = FirebaseFirestore.instance
        .collection('locker-activity')
        .orderBy('waktu', descending: true)
        .limit(30)
        .snapshots()
        .listen((snap) {
      final denied = snap.docs
          .map((d) => d.data())
          .where((d) => d['hasilAkses'] == 'DITOLAK')
          .toList();
      if (mounted) setState(() => _denied = denied);
    }, onError: (_) {});
  }

  Future<void> _logout() async {
    try {
      await widget.onLogout?.call();
    } catch (_) {}
    _activitySub?.cancel();
    if (!mounted) return;
    setState(() {
      _session = null;
      _tab = _Page.beranda;
      _sub = null;
      _visited
        ..clear()
        ..add(_Page.beranda);
      _denied = [];
    });
  }

  List<_Page> get _dockTabs => [
        _Page.beranda,
        _Page.locker,
        if (!_sarpras) _Page.santri,
        _Page.riwayat,
        _Page.akun,
      ];

  void _selectTab(int dockIndex) {
    setState(() {
      _tab = _dockTabs[dockIndex];
      _sub = null;
      _visited.add(_tab);
    });
  }

  /// Penjaga tampilan: Sarpras tidak boleh membuka Santri / Fingerprint.
  void _open(_Page page) {
    if (_sarpras && (page == _Page.santri || page == _Page.fingerprint)) {
      return;
    }
    setState(() {
      _visited.add(page);
      if (page == _Page.notifikasi) _seenAt = DateTime.now();
      if (page == _Page.fingerprint ||
          page == _Page.sistem ||
          page == _Page.notifikasi) {
        _sub = page;
      } else {
        _tab = page;
        _sub = null;
      }
    });
  }

  void _back() => setState(() => _sub = null);

  /// Tombol kembali Android: tutup halaman turunan -> kembali ke Beranda -> keluar.
  void _onSystemBack() {
    if (_sub != null) {
      _back();
    } else if (_tab != _Page.beranda) {
      setState(() => _tab = _Page.beranda);
    } else {
      SystemNavigator.pop();
    }
  }

  Widget _themed(Widget child) {
    return Theme(
      data: MobileTheme.dark,
      child: MobileBackground(
        child: Material(type: MaterialType.transparency, child: child),
      ),
    );
  }

  Widget _pageFor(_Page p) {
    if (!_visited.contains(p)) return const SizedBox.shrink();
    switch (p) {
      case _Page.beranda:
        return MobileDashboardScreen(
          onLockerTap: () => _open(_Page.locker),
          onFingerprint: _sarpras ? null : () => _open(_Page.fingerprint),
          onHistory: () => _open(_Page.riwayat),
          onBell: () => _open(_Page.notifikasi),
          unreadCount: _unread,
          // Sarpras = mode pantau: tidak diberi fungsi unlock
          onUnlock: _sarpras
              ? null
              : (widget.onRemoteUnlock ??
                  _lockerRepository.sendRemoteUnlockCommand),
        );
      case _Page.locker:
        // Sarpras (mode pantau): tanpa tambah/edit/hapus/kosongkan.
        return MobileLockerScreen(
          canManageOwner: !_sarpras,
          canEdit: !_sarpras,
          onRemoteUnlock: widget.onRemoteUnlock,
        );
      case _Page.santri:
        return const MobileSantriScreen();
      case _Page.riwayat:
        return const MobileRiwayatScreen();
      case _Page.akun:
        return MobileAkunScreen(
          userName: _session!.name,
          userEmail: _session!.email,
          roleLabel: _session!.role.label,
          onFingerprint: _sarpras ? null : () => _open(_Page.fingerprint),
          onSistem: () => _open(_Page.sistem),
          onLogout: _logout,
        );
      case _Page.fingerprint:
        return MobileFingerprintScreen(onBack: _back);
      case _Page.sistem:
        return MobileSystemScreen(onBack: _back);
      default:
        return MobileNotifikasiScreen(events: _denied, onBack: _back);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    if (session == null) {
      return Scaffold(
        backgroundColor: MobileColors.bgBottom,
        body: _themed(
          MobileLoginScreen(
            onSignedIn: _startSession,
            onSignIn: widget.onSignIn,
          ),
        ),
      );
    }

    final current = _sub ?? _tab;
    final dockIndex = _dockTabs.indexOf(_tab);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _onSystemBack();
      },
      child: Scaffold(
        backgroundColor: MobileColors.bgBottom,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _Page.values.indexOf(current),
            children: [
              for (final p in _Page.values) _themed(_pageFor(p)),
            ],
          ),
        ),
        bottomNavigationBar: MobileDock(
          items: MobileDock.defaultItems(withSantri: !_sarpras),
          currentIndex: dockIndex < 0 ? 0 : dockIndex,
          onTap: _selectTab,
        ),
      ),
    );
  }
}
