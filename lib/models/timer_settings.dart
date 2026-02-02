import 'package:equatable/equatable.dart';

enum SavageLevel {
  level1, // Encouraging
  level2, // Nagging
  level3, // Harsh
}

class TimerSettings extends Equatable {
  final int roundDurationSeconds;
  final int restDurationSeconds;
  final int totalRounds;
  final bool enableLastSecondsAlert;
  final int lastSecondsThreshold;
  final SavageLevel savageLevel;

  const TimerSettings({
    this.roundDurationSeconds = 180, // 3 minutes
    this.restDurationSeconds = 30,
    this.totalRounds = 3,
    this.enableLastSecondsAlert = true,
    this.lastSecondsThreshold = 30,
    this.savageLevel = SavageLevel.level2,
  });

  TimerSettings copyWith({
    int? roundDurationSeconds,
    int? restDurationSeconds,
    int? totalRounds,
    bool? enableLastSecondsAlert,
    int? lastSecondsThreshold,
    SavageLevel? savageLevel,
  }) {
    return TimerSettings(
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      totalRounds: totalRounds ?? this.totalRounds,
      enableLastSecondsAlert:
          enableLastSecondsAlert ?? this.enableLastSecondsAlert,
      lastSecondsThreshold: lastSecondsThreshold ?? this.lastSecondsThreshold,
      savageLevel: savageLevel ?? this.savageLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundDurationSeconds': roundDurationSeconds,
      'restDurationSeconds': restDurationSeconds,
      'totalRounds': totalRounds,
      'enableLastSecondsAlert': enableLastSecondsAlert,
      'lastSecondsThreshold': lastSecondsThreshold,
      'savageLevel': savageLevel.index,
    };
  }

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    return TimerSettings(
      roundDurationSeconds: json['roundDurationSeconds'] as int? ?? 180,
      restDurationSeconds: json['restDurationSeconds'] as int? ?? 30,
      totalRounds: json['totalRounds'] as int? ?? 3,
      enableLastSecondsAlert: json['enableLastSecondsAlert'] as bool? ?? true,
      lastSecondsThreshold: json['lastSecondsThreshold'] as int? ?? 30,
      savageLevel: SavageLevel.values[json['savageLevel'] as int? ?? 1],
    );
  }

  @override
  List<Object?> get props => [
    roundDurationSeconds,
    restDurationSeconds,
    totalRounds,
    enableLastSecondsAlert,
    lastSecondsThreshold,
    savageLevel,
  ];
}
