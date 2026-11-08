import 'package:flutter/material.dart';
import '../../core/theme/mobile_colors.dart';
import '../../core/theme/mobile_text_styles.dart';

/// Kartu angka ringkas (Riwayat, Fingerprint, Status sistem).
class MobileStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final Color color;

  const MobileStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    this.color = MobileColors.softBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MobileColors.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withAlpha(36),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value, style: MobileText.title.copyWith(fontSize: 26)),
          const SizedBox(height: 2),
          Text(title, style: MobileText.caption),
        ],
      ),
    );
  }
}

/// Chip filter bulat (sama gaya dengan chip L01/L02 di Beranda).
class MobileFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const MobileFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? MobileColors.softBlue
                : MobileColors.card.withAlpha(150),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            label,
            style: MobileText.body.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? MobileColors.bgTop : MobileColors.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

/// Nama bulan singkat untuk tanggal di Riwayat / Notifikasi.
String mobileDateTime(DateTime t) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${bulan[t.month - 1]} ${t.year} · $hh:$mm';
}
