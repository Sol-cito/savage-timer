import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_session.dart';

class NotificationService {
  static const _notificationId = 1;
  static const _channelId = 'savage_timer_timer';
  static const _channelName = 'Timer';
  static const _channelDescription = 'Savage Timer workout progress';

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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
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
      title = 'Workout Complete!';
      body = 'Great work! All rounds finished.';
    } else if (session.state == SessionState.paused) {
      title = 'Savage Timer — Paused';
      body = '${session.phaseLabel} · ${session.formattedTime} remaining';
    } else {
      title = 'Savage Timer — ${session.phaseLabel}';
      body =
          'Round ${session.currentRound}/${session.totalRounds} · ${session.formattedTime}';
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final endTimestamp =
        isRunning ? now + session.remainingSeconds * 1000 : null;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
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
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
