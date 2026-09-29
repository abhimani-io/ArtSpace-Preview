// ---------------------------------------------------------------------------
// WallAngleDetector — derives wall-tilt angles from the device accelerometer.
//
// When the user points the camera at a wall:
//   • pitch  = vertical tilt  (positive = device top tilted toward wall)
//   • yaw    = horizontal tilt (positive = device right side tilted toward wall)
//
// Both are in degrees, clamped to ±90°.
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

// ── Immutable snapshot of wall angles ─────────────────────────────────────────
class WallAngle {
  final double pitchDeg; // vertical tilt   (-90 → +90)
  final double yawDeg;   // horizontal tilt (-90 → +90)

  const WallAngle({
    this.pitchDeg = 0.0,
    this.yawDeg = 0.0,
  });

  /// 3-D perspective intensity (0 = flat-on, 1 = 45° tilt)
  double get intensity =>
      math.sqrt(pitchDeg * pitchDeg + yawDeg * yawDeg) / 45.0;

  /// Human-readable angle indicator label
  String get label {
    if (intensity < 0.1) return 'Straight-on ✓';
    if (intensity < 0.35) return 'Slight angle';
    if (intensity < 0.70) return 'Moderate angle';
    return 'Steep angle';
  }

  WallAngle copyWith({double? pitchDeg, double? yawDeg}) => WallAngle(
        pitchDeg: pitchDeg ?? this.pitchDeg,
        yawDeg: yawDeg ?? this.yawDeg,
      );

  @override
  String toString() =>
      'WallAngle(pitch: ${pitchDeg.toStringAsFixed(1)}°, yaw: ${yawDeg.toStringAsFixed(1)}°)';
}

// ── Detector class ────────────────────────────────────────────────────────────
class WallAngleDetector {
  final ValueNotifier<WallAngle> angle = ValueNotifier(const WallAngle());

  StreamSubscription<AccelerometerEvent>? _sub;

  /// Start listening to accelerometer.
  void start() {
    _sub ??= accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 80),
    ).listen(_onAccel, onError: (_) {});
  }

  /// Stop listening and release resources.
  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  /// Returns a frozen snapshot of the current angle (call at photo-capture time).
  WallAngle capture() => angle.value;

  void _onAccel(AccelerometerEvent e) {
    // Gravity vector: (x, y, z)
    //   • x: right (+) / left (-)
    //   • y: up (+) / down (-)
    //   • z: toward screen (+) / away from screen (-)
    //
    // When device faces a wall perpendicular, z ≈ 9.8 (straight at wall).
    // Pitch: arctan(y / z)  — tilt up/down
    // Yaw : arctan(x / z)  — tilt left/right

    final pitchRad = math.atan2(e.y, e.z);
    final yawRad = math.atan2(e.x, e.z);

    final pitchDeg = (pitchRad * 180 / math.pi).clamp(-90.0, 90.0);
    final yawDeg = (yawRad * 180 / math.pi).clamp(-90.0, 90.0);

    // Smooth with simple exponential filter (α=0.2) to reduce jitter
    final prev = angle.value;
    angle.value = WallAngle(
      pitchDeg: _lerp(prev.pitchDeg, pitchDeg, 0.2),
      yawDeg: _lerp(prev.yawDeg, yawDeg, 0.2),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  void dispose() {
    stop();
    angle.dispose();
  }
}
