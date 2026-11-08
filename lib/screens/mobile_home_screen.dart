import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'mobile_dashboard_screen.dart';
import 'santri_screen.dart';
import 'locker_screen.dart';
import 'riwayat_screen.dart';
import '../services/notification_service.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _selectedIndex = 0;

  static const Color navy = Color(0xFF9DB8FF);
  static const Color background = Color(0xFF07132F);

  late final List<Widget> _pages = [
    const MobileDashboardScreen(),
    LockerScreen(),
    SantriScreen(),
    RiwayatScreen(),
  ];

  Future<void> _aktifkanNotifikasi() async {
    try {
      debugPrint('Meminta izin notifikasi...');

      final token = await NotificationService.enableAndRegisterDevice();
      final settings = await NotificationService.getPermissionStatus();

      debugPrint(
        'Status izin: ${settings.authorizationStatus}',
      );

      if (!mounted) return;

      final status = settings.authorizationStatus;

      final String pesan;

      if (status == AuthorizationStatus.authorized) {
        pesan = token != null
            ? 'Notifikasi aktif dan perangkat terdaftar.'
            : 'Izin aktif, tetapi token belum tersedia. Periksa konfigurasi Firebase.';
      } else if (status == AuthorizationStatus.denied) {
        pesan = 'Notifikasi ditolak. Periksa pengaturan situs di Chrome.';
      } else if (status == AuthorizationStatus.notDetermined) {
        pesan = 'Izin belum ditentukan. Periksa pengaturan situs Chrome.';
      } else {
        pesan = 'Status izin: $status';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan)),
      );
    } catch (e, stackTrace) {
      debugPrint('Gagal meminta izin notifikasi: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal meminta izin: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _aktifkanNotifikasi,
                  icon: const Icon(
                    Icons.notifications_active_outlined,
                  ),
                  label: const Text('Aktifkan Notifikasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: const Color(0xFF102653),
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFF9DB8FF),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: const Color(0xFFF4F7FF),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              );
            }

            return const TextStyle(
              color: const Color(0xFF9AAED8),
              fontSize: 11,
            );
          },
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: navy,
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.door_sliding_outlined),
            selectedIcon: Icon(
              Icons.door_sliding,
              color: navy,
            ),
            label: 'Locker',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(
              Icons.people,
              color: navy,
            ),
            label: 'Santri',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(
              Icons.history_rounded,
              color: navy,
            ),
            label: 'Riwayat',
          ),
        ],
      ),
    );
  }
}
