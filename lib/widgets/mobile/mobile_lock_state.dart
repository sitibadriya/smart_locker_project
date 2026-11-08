import 'package:flutter/material.dart';
import '../../core/theme/mobile_colors.dart';

/// Status tampilan locker. Hanya untuk lapisan UI;
/// petakan dari data/stream yang sudah ada (jangan ubah model lama).
enum MobileLockState { locked, open, denied }

extension MobileLockStateX on MobileLockState {
  Color get color {
    switch (this) {
      case MobileLockState.locked:
        return MobileColors.locked;
      case MobileLockState.open:
        return MobileColors.open;
      case MobileLockState.denied:
        return MobileColors.denied;
    }
  }

  String get label {
    switch (this) {
      case MobileLockState.locked:
        return 'Terkunci';
      case MobileLockState.open:
        return 'Terbuka';
      case MobileLockState.denied:
        return 'Ditolak';
    }
  }
}
