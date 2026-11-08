import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/mobile_colors.dart';
import 'mobile_lock_state.dart';

/// Ilustrasi pintu locker dengan sensor fingerprint. Warna mengikuti status.
class DoorIllustration extends StatelessWidget {
  final MobileLockState state;
  final double height;
  const DoorIllustration({super.key, required this.state, this.height = 220});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pintu locker ${state.label.toLowerCase()}',
      child: SizedBox(
        height: height,
        width: height * 0.78,
        child: CustomPaint(
          painter: _DoorPainter(state.color, state == MobileLockState.open),
        ),
      ),
    );
  }
}

class _DoorPainter extends CustomPainter {
  final Color color;
  final bool open;
  _DoorPainter(this.color, this.open);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Rangka
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .06, h * .02, w * .88, h * .96),
      Radius.circular(w * .10),
    );
    canvas.drawRRect(frame, Paint()..color = const Color(0xFF0C1C4A));
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = MobileColors.softBlue.withAlpha(90),
    );

    final inner = Rect.fromLTWH(w * .13, h * .075, w * .74, h * .85);
    final innerR = RRect.fromRectAndRadius(inner, Radius.circular(w * .06));

    if (open) {
      // Ruang dalam menyala + daun pintu terbuka (engsel di kiri)
      canvas.drawRRect(
        innerR,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withAlpha(110), color.withAlpha(15)],
          ).createShader(inner),
      );
      final leaf = Path()
        ..moveTo(inner.left, inner.top)
        ..lineTo(inner.left + inner.width * .30, inner.top + inner.height * .05)
        ..lineTo(inner.left + inner.width * .30, inner.bottom - inner.height * .05)
        ..lineTo(inner.left, inner.bottom)
        ..close();
      canvas.drawPath(leaf, Paint()..color = const Color(0xFF1D3F8F));
    } else {
      // Daun pintu tertutup
      canvas.drawRRect(
        innerR,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F449A), MobileColors.card],
          ).createShader(inner),
      );
      final groove = Paint()
        ..color = Colors.white.withAlpha(16)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(inner.left + 14, inner.top + inner.height * .14),
          Offset(inner.right - 14, inner.top + inner.height * .14), groove);
      canvas.drawLine(Offset(inner.left + 14, inner.bottom - inner.height * .14),
          Offset(inner.right - 14, inner.bottom - inner.height * .14), groove);
      // Gagang
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(inner.right - 16, h * .62, 6, h * .12),
          const Radius.circular(3),
        ),
        Paint()..color = color,
      );
    }

    // Sensor fingerprint
    final c = Offset(w * .5, h * .42);
    canvas.drawCircle(
      c,
      w * .20,
      Paint()
        ..color = color.withAlpha(70)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.drawCircle(c, w * .15, Paint()..color = const Color(0xFF0C1C4A));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2
      ..color = color;
    for (var i = 1; i <= 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: w * .035 * i),
        -math.pi * (0.9 - i * 0.05),
        math.pi * (1.45 + i * 0.1),
        false,
        ring,
      );
    }
    canvas.drawCircle(c, 2.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DoorPainter old) =>
      old.color != color || old.open != open;
}
