import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_session.dart';

class NotificationService {
  static const _notificationId = 1;
  static const _channelId = 'savage_timer_timer';
  static const _defaultChannelName = 'Timer';
  static const _defaultChannelDescription = 'Savage Timer workout progress';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!Platform.isAndroid) return;

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            _defaultChannelName,
            description: _defaultChannelDescription,
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> update(WorkoutSession session) async {
    if (!_initialized) return;
    if (Platform.isAndroid) {
      await _updateAndroid(session);
    }
  }

  Future<void> dismiss() async {
    if (!_initialized) return;
    if (Platform.isAndroid) {
      await _plugin.cancel(_notificationId);
    }
  }

  Future<void> _updateAndroid(WorkoutSession session) async {
    final isRunning = session.state == SessionState.running;
    final isCompleted = session.state == SessionState.completed;

    String title;
    String body;

    if (isCompleted) {
      title = 'notification.workout_complete_title'.tr();
      body = 'notification.workout_complete_body'.tr();
    } else if (session.state == SessionState.paused) {
      final phase = _localizedPhaseLabel(session);
      title = 'notification.paused_title'.tr();
      body = 'notification.paused_body'.tr(
        namedArgs: {'phase': phase, 'time': session.formattedTime},
      );
    } else {
      final phase = _localizedPhaseLabel(session);
      title = 'notification.running_title'.tr(namedArgs: {'phase': phase});
      body = 'notification.running_body'.tr(
        namedArgs: {
          'current': '${session.currentRound}',
          'total': '${session.totalRounds}',
          'time': session.formattedTime,
        },
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final endTimestamp =
        isRunning ? now + session.remainingSeconds * 1000 : null;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _defaultChannelName,
      channelDescription: _defaultChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: !isCompleted,
      autoCancel: isCompleted,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      usesChronometer: isRunning,
      chronometerCountDown: isRunning,
      when: endTimestamp,
      showWhen: isRunning,
      category: AndroidNotificationCategory.status,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      _notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );

    if (isCompleted) {
      Future.delayed(const Duration(seconds: 3), () {
        _plugin.cancel(_notificationId);
      });
    }
  }

  String _localizedPhaseLabel(WorkoutSession session) {
    if (session.state == SessionState.idle) {
      return 'timer.phase.ready'.tr();
    }

    if (session.state == SessionState.preparing ||
        session.pausedDuringPreparation) {
      return 'timer.phase.get_ready'.tr();
    }

    if (session.state == SessionState.completed) {
      return 'timer.phase.done'.tr();
    }

    switch (session.phase) {
      case SessionPhase.warmUp:
        return 'timer.phase.warm_up'.tr();
      case SessionPhase.round:
        return 'timer.phase.round'.tr(
          namedArgs: {'round': '${session.currentRound}'},
        );
      case SessionPhase.rest:
        return 'timer.phase.rest'.tr();
      case SessionPhase.coolDown:
        return 'timer.phase.cool_down'.tr();
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
