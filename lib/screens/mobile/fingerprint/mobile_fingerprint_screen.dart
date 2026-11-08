import 'package:flutter/material.dart';

import '../../../core/theme/mobile_colors.dart';
import '../../../core/theme/mobile_text_styles.dart';
import '../../../repositories/fingerprint_repository.dart';
import '../../../widgets/mobile/mobile_stat_card.dart';
import '../../../widgets/mobile/mobile_sub_header.dart';

/// Daftar fingerprint (halaman turunan dari Beranda/Akun).
/// Sumber data sama: FingerprintRepository.watchAllFingerprintMapping().
class MobileFingerprintScreen extends StatefulWidget {
  final VoidCallback onBack;
  const MobileFingerprintScreen({super.key, required this.onBack});

  @override
  State<MobileFingerprintScreen> createState() =>
      _MobileFingerprintScreenState();
}

class _MobileFingerprintScreenState extends State<MobileFingerprintScreen> {
  final FingerprintRepository _repository = FingerprintRepository();
  late final Stream<List<Map<String, dynamic>>> _stream =
      _repository.watchAllFingerprintMapping();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat fingerprint:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: MobileText.body,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: MobileColors.softBlue),
            );
          }

          final list = snapshot.data!;
          final aktif = list.where((e) => e['statusAktif'] == true).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              MobileSubHeader(
                title: 'Fingerprint',
                subtitle: 'Data sidik jari yang terdaftar',
                onBack: widget.onBack,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: MobileStatCard(
                      icon: Icons.fingerprint_rounded,
                      value: '${list.length}',
                      title: 'Total',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MobileStatCard(
                      icon: Icons.verified_user_rounded,
                      value: '$aktif',
                      title: 'Aktif',
                      color: MobileColors.open,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: MobileColors.card.withAlpha(170),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.fingerprint_rounded,
                          size: 46, color: MobileColors.textDim),
                      SizedBox(height: 12),
                      Text('Belum ada fingerprint', style: MobileText.body),
                      SizedBox(height: 6),
                      Text('Daftarkan lewat halaman Santri.',
                          textAlign: TextAlign.center,
                          style: MobileText.caption),
                    ],
                  ),
                )
              else
                ...list.map((f) => _FingerprintCard(fingerprint: f)),
            ],
          );
        },
      ),
    );
  }
}

class _FingerprintCard extends StatelessWidget {
  final Map<String, dynamic> fingerprint;
  const _FingerprintCard({required this.fingerprint});

  @override
  Widget build(BuildContext context) {
    final id = fingerprint['idFingerprint']?.toString() ?? '-';
    final sensor = fingerprint['idSensor']?.toString() ?? '-';
    final idSantri = fingerprint['idSantri']?.toString() ?? '-';
    final nama = fingerprint['namaSantri']?.toString() ?? '-';
    final locker = fingerprint['idLocker']?.toString() ?? '-';
    final aktif = fingerprint['statusAktif'] == true;
    final color = aktif ? MobileColors.open : MobileColors.denied;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MobileColors.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MobileColors.softBlue.withAlpha(36),
                ),
                child: const Icon(Icons.fingerprint_rounded,
                    color: MobileColors.softBlue, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MobileText.title.copyWith(fontSize: 17)),
                    const SizedBox(height: 3),
                    Text('Sensor ID: $sensor', style: MobileText.caption),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withAlpha(34),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(aktif ? 'Aktif' : 'Nonaktif',
                    style: MobileText.caption
                        .copyWith(color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _Info(Icons.person_outline_rounded, 'Santri', nama),
                const SizedBox(height: 10),
                _Info(Icons.badge_outlined, 'ID Santri', idSantri),
                const SizedBox(height: 10),
                _Info(Icons.inventory_2_outlined, 'Locker', locker),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Info(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MobileColors.textDim),
        const SizedBox(width: 10),
        Text(label, style: MobileText.caption),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: MobileText.body
                .copyWith(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
