import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class FpsMonitor {
  final ValueNotifier<double> live = ValueNotifier<double>(0);

  final Stopwatch _clock = Stopwatch()..start();

  int _frames = 0;
  int _windowFrames = 0;
  int _windowStartUs = 0;
  int _lastUs = 0;
  int _maxGapUs = 0;

  bool _session = false;

  void start() {
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    final now = _clock.elapsedMicroseconds;

    if (_session && _lastUs != 0) {
      final gap = now - _lastUs;

      if (gap > _maxGapUs) {
        _maxGapUs = gap;
      }

      _frames++;
    }

    _lastUs = now;
    _windowFrames++;

    if (now - _windowStartUs >= 500000) {
      live.value =
          _windowFrames * 1000000 / (now - _windowStartUs);

      _windowFrames = 0;
      _windowStartUs = now;
    }
  }

  void beginSession() {
    _frames = 0;
    _maxGapUs = 0;
    _lastUs = _clock.elapsedMicroseconds;
    _session = true;
  }

  /// Trả về (FPS trung bình, khoảng ngắt frame lớn nhất tính bằng ms).
  (double, double) endSession(int elapsedUs) {
    _session = false;

    if (elapsedUs <= 0) {
      return (0, _maxGapUs / 1000);
    }

    return (
      _frames * 1000000 / elapsedUs,
      _maxGapUs / 1000,
    );
  }

  void dispose() {
    live.dispose();
  }
}