import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

class VibrationService {
  Future<bool> _hasVibrator() async {
    return await Vibration.hasVibrator() == true;
  }

  Future<void> roundStart() async {
    if (!await _hasVibrator()) return;
    // Double short pulse for round start
    Vibration.vibrate(pattern: [0, 200, 100, 200]);
  }

  Future<void> roundEnd() async {
    if (!await _hasVibrator()) return;
    // Long pulse for round end
    Vibration.vibrate(duration: 500);
  }

  Future<void> lastSecondsAlert() async {
    if (!await _hasVibrator()) return;
    // Triple short pulse for warning
    Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100]);
  }

  Future<void> restEnd() async {
    if (!await _hasVibrator()) return;
    // Strong double pulse for rest end
    Vibration.vibrate(pattern: [0, 300, 150, 300]);
  }

  Future<void> sessionComplete() async {
    if (!await _hasVibrator()) return;
    // Long celebration pattern
    Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 500]);
  }
}

final vibrationServiceProvider = Provider<VibrationService>((ref) {
  return VibrationService();
});
