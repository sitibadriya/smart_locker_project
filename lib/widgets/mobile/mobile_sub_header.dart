import 'package:flutter/material.dart';
import '../../core/theme/mobile_colors.dart';
import '../../core/theme/mobile_text_styles.dart';

/// Header halaman turunan (Fingerprint, Status sistem, Notifikasi):
/// tombol kembali bulat + judul besar, sama gaya dengan header tab utama.
class MobileSubHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;

  const MobileSubHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Kembali',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MobileColors.card.withAlpha(170),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: MobileText.display),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: MobileText.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
