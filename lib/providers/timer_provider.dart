import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../services/timer_foreground_service.dart';

class TimerProvider with ChangeNotifier {
  // ── Platform check ───────────────────────────────────────────────────────
  bool get _useForegroundService =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  // ── Fallback local timer (for Web & Desktop) ──────────────────────────────
  Timer? _localTicker;

  // ── Task label ───────────────────────────────────────────────────────────
  String _taskType = 'Focus Session';
  String get taskType => _taskType;

  void setTaskType(String type) {
    final t = type.isEmpty ? 'Focus Session' : type;
    if (_taskType != t) {
      _taskType = t;
      // Let the background isolate know about the new label (mobile only).
      if (_isRunning && _useForegroundService) {
        FlutterForegroundTask.sendDataToTask({'cmd': 'update_type', 'value': t});
      }
      notifyListeners();
    }
  }

  // ── Timer state ──────────────────────────────────────────────────────────
  Duration _totalDuration = const Duration(minutes: 5);
  Duration get totalDuration => _totalDuration;

  int _remainingSeconds = 5 * 60;
  int get remainingSeconds => _remainingSeconds;

  Duration get remainingDuration => Duration(seconds: _remainingSeconds);

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  bool _isSetupMode = true;
  bool get isSetupMode => _isSetupMode;

  // ── Callback for "done" event ─────────────────────────────────────────────
  /// Called when the timer finishes.
  VoidCallback? onTimerDone;

  // ── Task data listener ────────────────────────────────────────────────────
  TimerProvider() {
    if (_useForegroundService) {
      FlutterForegroundTask.addTaskDataCallback(_onTaskData);
    }
  }

  @override
  void dispose() {
    _localTicker?.cancel();
    if (_useForegroundService) {
      FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    }
    super.dispose();
  }

  void _onTaskData(Object data) {
    if (data is Map<String, dynamic>) {
      final type = data['type'] as String?;
      if (type == 'tick') {
        _remainingSeconds = (data['remaining'] as int?) ?? _remainingSeconds;
        notifyListeners();
      } else if (type == 'done') {
        _isRunning = false;
        _isSetupMode = true;
        _remainingSeconds = 0;
        notifyListeners();
        // Fire the UI callback so the screen can play celebrations.
        onTimerDone?.call();
      }
    }
  }

  // ── Local ticker for Web / Desktop ────────────────────────────────────────
  void _startLocalTicker() {
    _localTicker?.cancel();
    _localTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _localTicker?.cancel();
        _isRunning = false;
        _isSetupMode = true;
        notifyListeners();
        onTimerDone?.call();
      }
    });
  }

  // ── Timer controls ────────────────────────────────────────────────────────

  /// Call this when the user changes the duration in setup mode.
  void setDuration(Duration d) {
    if (_isSetupMode) {
      _totalDuration = d;
      _remainingSeconds = d.inSeconds;
      notifyListeners();
    }
  }

  Future<void> startTimer() async {
    _isSetupMode = false;
    _isRunning = true;
    _remainingSeconds = _totalDuration.inSeconds;
    notifyListeners();

    if (_useForegroundService) {
      await TimerForegroundService.start(
        remainingSeconds: _remainingSeconds,
        taskType: _taskType,
      );
    } else {
      _startLocalTicker();
    }
  }

  Future<void> pauseTimer() async {
    _isRunning = false;
    notifyListeners();
    if (_useForegroundService) {
      await TimerForegroundService.pause();
    } else {
      _localTicker?.cancel();
    }
  }

  Future<void> resumeTimer() async {
    _isRunning = true;
    notifyListeners();
    if (_useForegroundService) {
      await TimerForegroundService.resume();
    } else {
      _startLocalTicker();
    }
  }

  Future<void> resetTimer() async {
    _isRunning = false;
    _isSetupMode = true;
    _remainingSeconds = _totalDuration.inSeconds;
    notifyListeners();
    if (_useForegroundService) {
      await TimerForegroundService.stop();
    } else {
      _localTicker?.cancel();
    }
  }
}
