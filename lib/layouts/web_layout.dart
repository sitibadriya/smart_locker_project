import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../screens/web/dashboard/web_dashboard_screen.dart';
import '../screens/web/santri/web_santri_screen.dart';
import '../screens/web/locker/web_locker_screen.dart';
import '../screens/web/fingerprint/web_fingerprint_screen.dart';
import '../screens/web/riwayat/web_riwayat_screen.dart';
import '../screens/web/system/web_system_screen.dart';

class WebLayout extends StatefulWidget {
  const WebLayout({super.key});

  @override
  State<WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> {
  int selectedIndex = 0;

  final List<String> titles = const [
    'Dashboard',
    'Data Santri',
    'Manajemen Locker',
    'Fingerprint',
    'Riwayat Akses',
    'Status Sistem',
  ];

  final List<Widget> pages = const [
    WebDashboardScreen(),
    WebSantriScreen(),
    WebLockerScreen(),
    WebFingerprintScreen(),
    WebRiwayatScreen(),
    WebSystemScreen(),
  ];

  final List<IconData> icons = const [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.inventory_2_rounded,
    Icons.fingerprint_rounded,
    Icons.history_rounded,
    Icons.monitor_heart_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 245,
            color: AppColors.navy,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'SMART LOCKER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 12),
                  for (int index = 0; index < titles.length; index++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 3,
                      ),
                      child: ListTile(
                        selected: selectedIndex == index,
                        selectedTileColor: Colors.white.withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(
                          icons[index],
                          color: selectedIndex == index
                              ? Colors.white
                              : Colors.white70,
                        ),
                        title: Text(
                          titles[index],
                          style: TextStyle(
                            color: selectedIndex == index
                                ? Colors.white
                                : Colors.white70,
                            fontWeight: selectedIndex == index
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                          });
                        },
                      ),
                    ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'IoT • Firebase Connected',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        titles[selectedIndex],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.circle,
                        color: AppColors.success,
                        size: 10,
                      ),
                      const SizedBox(width: 8),
                      const Text('Sistem aktif'),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
