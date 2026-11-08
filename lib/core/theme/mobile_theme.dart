import 'package:flutter/material.dart';
import 'mobile_colors.dart';
import 'mobile_text_styles.dart';

/// Cara pakai (di layouts/mobile_layout.dart):
///   Theme(
///     data: MobileTheme.dark,
///     child: MobileBackground(child: ...),
///   )
/// ThemeData web tidak disentuh.
class MobileTheme {
  MobileTheme._();

  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'Roboto', // sama dengan AppTheme web
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent, // latar digambar MobileBackground
      colorScheme: const ColorScheme.dark(
        primary: MobileColors.softBlue,
        onPrimary: MobileColors.bgTop,
        secondary: MobileColors.locked,
        onSecondary: MobileColors.bgTop,
        surface: MobileColors.card,
        onSurface: MobileColors.text,
        error: MobileColors.denied,
        onError: MobileColors.bgTop,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: MobileColors.text,
        displayColor: MobileColors.text,
      ),
      iconTheme: const IconThemeData(color: MobileColors.text),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: MobileColors.text,
        titleTextStyle: MobileText.title,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: MobileColors.card,
        contentTextStyle: MobileText.body,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: const Color(0xFF1B3A82),
        textStyle: MobileText.body,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MobileColors.card.withAlpha(150),
        hintStyle: MobileText.label,
        prefixIconColor: MobileColors.textDim,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
      dividerColor: Colors.white.withAlpha(20),
    );
  }
}

/// Latar gradasi #09163A -> #050B1D untuk semua layar mobile.
class MobileBackground extends StatelessWidget {
  final Widget child;
  const MobileBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: MobileColors.background),
      child: child,
    );
  }
}
