import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry-point callback — MUST be top-level and annotated with vm:entry-point.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void timerTaskCallback() {
  FlutterForegroundTask.setTaskHandler(TimerTaskHandler());
}

// ─────────────────────────────────────────────────────────────────────────────
// TaskHandler — runs inside the background isolate.
// ─────────────────────────────────────────────────────────────────────────────
class TimerTaskHandler extends TaskHandler {
  Timer? _ticker;
  int _remainingSeconds = 0;
  bool _paused = false;
  String _taskType = 'Focus Session';

  /// Format seconds → "MM:SS"
  static String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Read initial data saved by the main isolate before starting.
    final dynamic storedSecs =
        await FlutterForegroundTask.getData(key: 'remaining_seconds');
    final dynamic storedType =
        await FlutterForegroundTask.getData(key: 'task_type');

    _remainingSeconds = (storedSecs is int) ? storedSecs : 0;
    _taskType = (storedType is String) ? storedType : 'Focus Session';

    _startTicking();
  }

  void _startTicking() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;

      if (_remainingSeconds > 0) {
        _remainingSeconds--;

        // Update notification text with live countdown.
        FlutterForegroundTask.updateService(
          notificationTitle: '⏱ $_taskType',
          notificationText: _fmt(_remainingSeconds),
        );

        // Send remaining seconds to the main isolate.
        FlutterForegroundTask.sendDataToMain({
          'type': 'tick',
          'remaining': _remainingSeconds,
        });
      } else {
        // Timer finished — notify main isolate.
        FlutterForegroundTask.sendDataToMain({'type': 'done'});
        _ticker?.cancel();
        // Stop the foreground service after signalling done.
        FlutterForegroundTask.stopService();
      }
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // We use our own Timer.periodic, so nothing needed here.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _ticker?.cancel();
  }

  /// Handle commands sent from the main isolate.
  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final cmd = data['cmd'] as String?;
      switch (cmd) {
        case 'pause':
          _paused = true;
          FlutterForegroundTask.updateService(
            notificationTitle: '⏸ $_taskType — Paused',
            notificationText: _fmt(_remainingSeconds),
          );
          break;

        case 'resume':
          _paused = false;
          FlutterForegroundTask.updateService(
            notificationTitle: '⏱ $_taskType',
            notificationText: _fmt(_remainingSeconds),
          );
          break;

        case 'update_type':
          _taskType = (data['value'] as String?) ?? _taskType;
          break;

        case 'update_remaining':
          _remainingSeconds = (data['value'] as int?) ?? _remainingSeconds;
          break;
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'btn_pause_resume') {
      if (_paused) {
        onReceiveData({'cmd': 'resume'});
      } else {
        onReceiveData({'cmd': 'pause'});
      }
    }
  }

  @override
  void onNotificationPressed() {
    // App will be brought to foreground automatically via PendingIntent.
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Static helper — initialises and controls the foreground service.
// ─────────────────────────────────────────────────────────────────────────────
class TimerForegroundService {
  /// Call once at app startup (in main).
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'smarttingo_timer',
        channelName: 'Smarttingo Timer',
        channelDescription: 'Shows the running focus timer countdown.',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Request notification permission (Android 13+).
  static Future<void> requestPermissions() async {
    final perm = await FlutterForegroundTask.checkNotificationPermission();
    if (perm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!kIsWeb && Platform.isAndroid) {
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  /// Start the foreground timer service.
  static Future<void> start({
    required int remainingSeconds,
    required String taskType,
  }) async {
    // Store initial state so the background isolate can read it on start.
    await FlutterForegroundTask.saveData(
        key: 'remaining_seconds', value: remainingSeconds);
    await FlutterForegroundTask.saveData(key: 'task_type', value: taskType);

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 1001,
        notificationTitle: '⏱ $taskType',
        notificationText: _fmt(remainingSeconds),
        notificationButtons: [
          const NotificationButton(id: 'btn_pause_resume', text: '⏸ Pause'),
        ],
        callback: timerTaskCallback,
      );
    }
  }

  /// Send a pause command to the running service.
  static Future<void> pause() async {
    FlutterForegroundTask.sendDataToTask({'cmd': 'pause'});
  }

  /// Send a resume command to the running service.
  static Future<void> resume() async {
    FlutterForegroundTask.sendDataToTask({'cmd': 'resume'});
  }

  /// Stop the foreground service.
  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  static String _fmt(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
