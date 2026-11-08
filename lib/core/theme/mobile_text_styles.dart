import 'package:flutter/material.dart';
import 'mobile_colors.dart';

/// Gaya teks MOBILE. Memakai font bawaan sistem (tanpa tambahan paket).
class MobileText {
  MobileText._();

  static const TextStyle display = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
    color: MobileColors.text,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: MobileColors.text,
  );

  /// Teks status besar di kartu Beranda (warna diatur per status).
  static const TextStyle status = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -0.8,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: MobileColors.text,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: MobileColors.textDim,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: MobileColors.textDim,
  );
}
