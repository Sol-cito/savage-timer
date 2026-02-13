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
  final double volume; // 0.0 = mute, 1.0 = max
  final bool enableMotivationalSound;

  const TimerSettings({
    this.roundDurationSeconds = 180, // 3 minutes
    this.restDurationSeconds = 30,
    this.totalRounds = 3,
    this.enableLastSecondsAlert = true,
    this.lastSecondsThreshold = 30,
    this.savageLevel = SavageLevel.level2,
    this.volume = 0.8,
    this.enableMotivationalSound = true,
  });

  bool get isMuted => volume == 0.0;

  TimerSettings copyWith({
    int? roundDurationSeconds,
    int? restDurationSeconds,
    int? totalRounds,
    bool? enableLastSecondsAlert,
    int? lastSecondsThreshold,
    SavageLevel? savageLevel,
    double? volume,
    bool? enableMotivationalSound,
  }) {
    return TimerSettings(
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      totalRounds: totalRounds ?? this.totalRounds,
      enableLastSecondsAlert:
          enableLastSecondsAlert ?? this.enableLastSecondsAlert,
      lastSecondsThreshold: lastSecondsThreshold ?? this.lastSecondsThreshold,
      savageLevel: savageLevel ?? this.savageLevel,
      volume: volume ?? this.volume,
      enableMotivationalSound:
          enableMotivationalSound ?? this.enableMotivationalSound,
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
      'volume': volume,
      'enableMotivationalSound': enableMotivationalSound,
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
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      enableMotivationalSound:
          json['enableMotivationalSound'] as bool? ?? true,
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
    volume,
    enableMotivationalSound,
  ];
}
