import 'package:equatable/equatable.dart';

enum SavageLevel {
  level1, // Encouraging
  level2, // Nagging
  level3, // Harsh
}

class TimerSettings extends Equatable {
  final int roundDurationSeconds;
  final bool enableSeparateRoundDurations;
  final List<int> roundDurationsSeconds;
  final int restDurationSeconds;
  final bool enableWarmUpSet;
  final int warmUpDurationSeconds;
  final int totalRounds;
  final bool enableLastSecondsAlert;
  final bool enableLast10SecondsClappingAlert;
  final int lastSecondsThreshold;
  final SavageLevel savageLevel;
  final double volume; // 0.0 = mute, 1.0 = max
  final bool enableMotivationalSound;
  final bool enableVibration;
  final bool enableKeepScreenOn;

  const TimerSettings({
    this.roundDurationSeconds = 180, // 3 minutes
    this.enableSeparateRoundDurations = false,
    this.roundDurationsSeconds = const [],
    this.restDurationSeconds = 30,
    this.enableWarmUpSet = false,
    this.warmUpDurationSeconds = 60,
    this.totalRounds = 3,
    this.enableLastSecondsAlert = true,
    this.enableLast10SecondsClappingAlert = false,
    this.lastSecondsThreshold = 30,
    this.savageLevel = SavageLevel.level2,
    this.volume = 0.8,
    this.enableMotivationalSound = true,
    this.enableVibration = true,
    this.enableKeepScreenOn = true,
  });

  bool get isMuted => volume == 0.0;

  int roundDurationForRound(int roundNumber) {
    if (roundNumber <= 0) return roundDurationSeconds;
    final roundIndex = roundNumber - 1;
    if (enableSeparateRoundDurations &&
        roundIndex < roundDurationsSeconds.length) {
      return roundDurationsSeconds[roundIndex];
    }
    return roundDurationSeconds;
  }

  List<int> get resolvedRoundDurationsSeconds {
    return List<int>.generate(totalRounds, (index) {
      if (enableSeparateRoundDurations &&
          index < roundDurationsSeconds.length) {
        return roundDurationsSeconds[index];
      }
      return roundDurationSeconds;
    });
  }

  TimerSettings copyWith({
    int? roundDurationSeconds,
    bool? enableSeparateRoundDurations,
    List<int>? roundDurationsSeconds,
    int? restDurationSeconds,
    bool? enableWarmUpSet,
    int? warmUpDurationSeconds,
    int? totalRounds,
    bool? enableLastSecondsAlert,
    bool? enableLast10SecondsClappingAlert,
    int? lastSecondsThreshold,
    SavageLevel? savageLevel,
    double? volume,
    bool? enableMotivationalSound,
    bool? enableVibration,
    bool? enableKeepScreenOn,
  }) {
    return TimerSettings(
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      enableSeparateRoundDurations:
          enableSeparateRoundDurations ?? this.enableSeparateRoundDurations,
      roundDurationsSeconds:
          roundDurationsSeconds ?? this.roundDurationsSeconds,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      enableWarmUpSet: enableWarmUpSet ?? this.enableWarmUpSet,
      warmUpDurationSeconds:
          warmUpDurationSeconds ?? this.warmUpDurationSeconds,
      totalRounds: totalRounds ?? this.totalRounds,
      enableLastSecondsAlert:
          enableLastSecondsAlert ?? this.enableLastSecondsAlert,
      enableLast10SecondsClappingAlert:
          enableLast10SecondsClappingAlert ??
          this.enableLast10SecondsClappingAlert,
      lastSecondsThreshold: lastSecondsThreshold ?? this.lastSecondsThreshold,
      savageLevel: savageLevel ?? this.savageLevel,
      volume: volume ?? this.volume,
      enableMotivationalSound:
          enableMotivationalSound ?? this.enableMotivationalSound,
      enableVibration: enableVibration ?? this.enableVibration,
      enableKeepScreenOn: enableKeepScreenOn ?? this.enableKeepScreenOn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundDurationSeconds': roundDurationSeconds,
      'enableSeparateRoundDurations': enableSeparateRoundDurations,
      'roundDurationsSeconds': roundDurationsSeconds,
      'restDurationSeconds': restDurationSeconds,
      'enableWarmUpSet': enableWarmUpSet,
      'warmUpDurationSeconds': warmUpDurationSeconds,
      'totalRounds': totalRounds,
      'enableLastSecondsAlert': enableLastSecondsAlert,
      'enableLast10SecondsClappingAlert': enableLast10SecondsClappingAlert,
      'lastSecondsThreshold': lastSecondsThreshold,
      'savageLevel': savageLevel.index,
      'volume': volume,
      'enableMotivationalSound': enableMotivationalSound,
      'enableVibration': enableVibration,
      'enableKeepScreenOn': enableKeepScreenOn,
    };
  }

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    final rawRoundDurations = json['roundDurationsSeconds'];
    final roundDurations =
        rawRoundDurations is List
            ? rawRoundDurations
                .whereType<num>()
                .map((value) => value.toInt())
                .toList()
            : const <int>[];

    return TimerSettings(
      roundDurationSeconds: json['roundDurationSeconds'] as int? ?? 180,
      enableSeparateRoundDurations:
          json['enableSeparateRoundDurations'] as bool? ?? false,
      roundDurationsSeconds: roundDurations,
      restDurationSeconds: json['restDurationSeconds'] as int? ?? 30,
      enableWarmUpSet: json['enableWarmUpSet'] as bool? ?? false,
      warmUpDurationSeconds: json['warmUpDurationSeconds'] as int? ?? 60,
      totalRounds: json['totalRounds'] as int? ?? 3,
      enableLastSecondsAlert: json['enableLastSecondsAlert'] as bool? ?? true,
      enableLast10SecondsClappingAlert:
          json['enableLast10SecondsClappingAlert'] as bool? ?? false,
      lastSecondsThreshold: json['lastSecondsThreshold'] as int? ?? 30,
      savageLevel: SavageLevel.values[json['savageLevel'] as int? ?? 1],
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
      enableMotivationalSound: json['enableMotivationalSound'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      enableKeepScreenOn: json['enableKeepScreenOn'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    roundDurationSeconds,
    enableSeparateRoundDurations,
    roundDurationsSeconds,
    restDurationSeconds,
    enableWarmUpSet,
    warmUpDurationSeconds,
    totalRounds,
    enableLastSecondsAlert,
    enableLast10SecondsClappingAlert,
    lastSecondsThreshold,
    savageLevel,
    volume,
    enableMotivationalSound,
    enableVibration,
    enableKeepScreenOn,
  ];
}
