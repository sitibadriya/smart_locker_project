import 'package:flutter/material.dart';

import '../models/santri.dart';
import '../repositories/fingerprint_repository.dart';
import 'fingerprint_screen.dart';
import 'locker_screen.dart';
import 'santri_screen.dart';
import 'system_status_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color navy = Color(0xFF0B1F3A);
  static const Color navyLight = Color(0xFF163E6D);
  static const Color background = Color(0xFFF4F7FB);
  static const Color teal = Color(0xFF00897B);
  static const Color green = Color(0xFF2E7D32);
  static const Color textDark = Color(0xFF172033);
  static const Color textGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final repository = FingerprintRepository();

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: StreamBuilder<List<Santri>>(
          stream: repository.watchSantriAktif(),
          builder: (context, santriSnapshot) {
            final santri = santriSnapshot.data ?? [];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: repository.watchAllFingerprintMapping(),
              builder: (context, mappingSnapshot) {
                final mapping = mappingSnapshot.data ?? [];

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeader(santri.length, mapping.length),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Sistem',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStat(
                                    context,
                                    icon: Icons.people_alt_rounded,
                                    title: 'Santri',
                                    value: santri.length.toString(),
                                    iconColor: navy,
                                    cardColor: const Color(0xFFE8EEF7),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SantriScreen(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStat(
                                    context,
                                    icon: Icons.fingerprint_rounded,
                                    title: 'Fingerprint',
                                    value: mapping.length.toString(),
                                    iconColor: teal,
                                    cardColor: const Color(0xFFE5F4F1),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FingerprintScreen(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStat(
                                    context,
                                    icon: Icons.lock_rounded,
                                    title: 'Locker',
                                    value: santri.length.toString(),
                                    iconColor: navyLight,
                                    cardColor: const Color(0xFFE9EFF8),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LockerScreen(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStat(
                                    context,
                                    icon: Icons.verified_user_rounded,
                                    title: 'Terdaftar',
                                    value: mapping
                                        .where(
                                          (item) => item['statusAktif'] == true,
                                        )
                                        .length
                                        .toString(),
                                    iconColor: green,
                                    cardColor: const Color(0xFFE8F5E9),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FingerprintScreen(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SystemStatusScreen(),
                            ),
                          ),
                          child: _buildSystemStatus(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    required Color cardColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: _StatCard(
        icon: icon,
        title: title,
        value: value,
        iconColor: iconColor,
        backgroundColor: cardColor,
      ),
    );
  }

  Widget _buildHeader(int jumlahSantri, int jumlahFingerprint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [navy, navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 9, color: Color(0xFF66BB6A)),
                      SizedBox(width: 3),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'Selamat Datang 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Kelola dan pantau Smart Locker dengan mudah.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeaderMiniInfo(
                  icon: Icons.people_alt_rounded,
                  value: jumlahSantri.toString(),
                  label: 'Santri Aktif',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeaderMiniInfo(
                  icon: Icons.fingerprint_rounded,
                  value: jumlahFingerprint.toString(),
                  label: 'Fingerprint',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.check_circle_rounded, color: green, size: 30),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Sistem',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pantau kondisi sistem Smart Locker.',
                  style: TextStyle(fontSize: 13, color: textGrey),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color backgroundColor;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: DashboardScreen.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: DashboardScreen.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMiniInfo extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderMiniInfo({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10,
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
