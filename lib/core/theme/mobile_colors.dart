import 'package:flutter/material.dart';

/// Palet khusus MOBILE (gaya Front Door navy).
/// Terpisah dari app_colors.dart agar tema Web tidak berubah.
class MobileColors {
  MobileColors._();

  // Latar
  static const Color bgTop = Color(0xFF09163A);
  static const Color bgBottom = Color(0xFF050B1D);

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  // Permukaan
  static const Color card = Color(0xFF16306F);
  static const Color dock = Color(0xFF0F2250);

  // Transparansi card
  static const Color card70 = Color(0xB3FFFFFF);
  static const Color card24 = Color(0x3DFFFFFF);

  // Status
  static const Color locked = Color(0xFFF0B95F);
  static const Color open = Color(0xFF46D9A0);
  static const Color denied = Color(0xFFFF7A7A);

  // Aksen & teks
  static const Color softBlue = Color(0xFF9DB8FF);
  static const Color text = Color(0xFFEEF2FF);
  static const Color textDim = Color(0xFF8FA2CF);
}
