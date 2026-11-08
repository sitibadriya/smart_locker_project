import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/mobile_colors.dart';
import '../../core/theme/mobile_text_styles.dart';

/// Slider "Geser untuk buka".
/// - [onUnlock]: panggil fungsi remote-unlock LAMA di sini (tanpa mengubah namanya).
/// - Setelah berhasil, tampil "terbuka" selama [holdDuration] (4 detik), lalu kembali terkunci.
/// - [onRelock] opsional, dipanggil saat hitungan selesai.
/// - [enabled] = false untuk mode pantau (Sarpras).
class SlideToUnlock extends StatefulWidget {
  final Future<void> Function() onUnlock;
  final VoidCallback? onRelock;
  final bool enabled;
  final String label;
  final String disabledLabel;
  final String doneLabel;
  final Duration holdDuration;

  const SlideToUnlock({
    super.key,
    required this.onUnlock,
    this.onRelock,
    this.enabled = true,
    this.label = 'Geser untuk buka',
    this.disabledLabel = 'Mode pantau',
    this.doneLabel = 'Perintah terkirim',
    this.holdDuration = const Duration(seconds: 4),
  });

  @override
  State<SlideToUnlock> createState() => _SlideToUnlockState();
}

class _SlideToUnlockState extends State<SlideToUnlock> {
  static const double _thumb = 56;
  static const double _pad = 4;

  double _drag = 0;
  bool _dragging = false;
  bool _busy = false;
  bool _done = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    if (!mounted) return;
    setState(() {
      _drag = 0;
      _busy = false;
      _done = false;
      _dragging = false;
    });
  }

  Future<void> _complete(double max) async {
    setState(() {
      _drag = max;
      _busy = true;
      _dragging = false;
    });
    try {
      await widget.onUnlock();
    } catch (_) {
      _reset(); // gagal: kembali ke awal; penanganan error tetap di pemanggil
      return;
    }
    if (!mounted) return;
    setState(() => _done = true);
    _timer = Timer(widget.holdDuration, () {
      _reset();
      widget.onRelock?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled;
    final accent = _done ? MobileColors.open : MobileColors.locked;

    return LayoutBuilder(builder: (context, box) {
      final max = box.maxWidth - _thumb - _pad * 2;
      final progress = max <= 0 ? 0.0 : (_drag / max).clamp(0.0, 1.0);

      return Semantics(
        button: true,
        enabled: active && !_busy,
        label: active ? widget.label : widget.disabledLabel,
        child: Container(
          height: _thumb + _pad * 2,
          decoration: BoxDecoration(
            color: (_done ? MobileColors.open : Colors.white).withAlpha(_done ? 36 : 18),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withAlpha(22)),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Opacity(
                  opacity: _done
                      ? 1.0
                      : (active ? (1 - progress).clamp(0.0, 1.0) : 0.7),
                  child: Text(
                    !active
                        ? widget.disabledLabel
                        : (_done ? widget.doneLabel : widget.label),
                    style: MobileText.label,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration:
                    _dragging ? Duration.zero : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: _pad + _drag,
                child: GestureDetector(
                  onHorizontalDragStart: (active && !_busy)
                      ? (_) => setState(() => _dragging = true)
                      : null,
                  onHorizontalDragUpdate: (active && !_busy)
                      ? (d) => setState(
                          () => _drag = (_drag + d.delta.dx).clamp(0.0, max))
                      : null,
                  onHorizontalDragEnd: (active && !_busy)
                      ? (_) {
                          if (_drag >= max * 0.85) {
                            _complete(max);
                          } else {
                            setState(() {
                              _drag = 0;
                              _dragging = false;
                            });
                          }
                        }
                      : null,
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? accent : MobileColors.textDim.withAlpha(90),
                    ),
                    child: Icon(
                      !active
                          ? Icons.lock_rounded
                          : (_done ? Icons.lock_open_rounded : Icons.chevron_right_rounded),
                      color: MobileColors.bgTop,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
