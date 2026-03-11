import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:audio_session/audio_session.dart' as audio_session;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/timer_settings.dart';

class AudioService {
  static const _defaultVoiceLanguageCode = 'en';
  static const Set<String> _supportedVoiceLanguageCodes = {'en', 'es', 'ko'};

  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _warningPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _countPlayer = AudioPlayer();
  final AudioPlayer _clapPlayer = AudioPlayer();
  final AudioPlayer _keepAlivePlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  DateTime? _lastQuoteTime;
  static const _quoteCooldown = Duration(seconds: 15);

  bool _isInitialized = false;

  bool _soundsLoaded = false;
  String _voiceLanguageCode = _defaultVoiceLanguageCode;
  Map<String, dynamic>? _assetManifestCache;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configure audio session for background playback (critical for iOS)
    final session = await audio_session.AudioSession.instance;
    await session.configure(
      audio_session.AudioSessionConfiguration(
        avAudioSessionCategory: audio_session.AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            audio_session.AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: audio_session.AVAudioSessionMode.defaultMode,
        androidAudioAttributes: const audio_session.AndroidAudioAttributes(
          contentType: audio_session.AndroidAudioContentType.music,
          usage: audio_session.AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: audio_session.AndroidAudioFocusGainType.gain,
      ),
    );
    await session.setActive(true);

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    await _configurePlayersForMixing();

    // Try to pre-load sound assets (optional - falls back to TTS)
    try {
      await _bellPlayer.setSource(AssetSource('sounds/bell.mp3'));
      await _warningPlayer.setSource(AssetSource('sounds/warning.mp3'));
      _soundsLoaded = true;
    } catch (e) {
      // Sound files not available, will use TTS fallback
      _soundsLoaded = false;
    }

    _isInitialized = true;
  }

  Future<void> _configurePlayersForMixing() async {
    // Android can otherwise request exclusive audio focus per player,
    // which prevents overlap between bell/count/clap cues.
    final mixingContext =
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build();

    await _bellPlayer.setAudioContext(mixingContext);
    await _warningPlayer.setAudioContext(mixingContext);
    await _countPlayer.setAudioContext(mixingContext);
    await _clapPlayer.setAudioContext(mixingContext);
    await _voicePlayer.setAudioContext(mixingContext);
    await _keepAlivePlayer.setAudioContext(mixingContext);

    // Keep cue latency low for simultaneous trigger points.
    await _bellPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _warningPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _countPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _clapPlayer.setPlayerMode(PlayerMode.lowLatency);
  }

  void setVoiceLanguage(String languageCode) {
    _voiceLanguageCode = _normalizeVoiceLanguageCode(languageCode);
  }

  String _normalizeVoiceLanguageCode(String languageCode) {
    final normalized =
        languageCode.toLowerCase().replaceAll('_', '-').split('-').first;

    return _supportedVoiceLanguageCodes.contains(normalized)
        ? normalized
        : _defaultVoiceLanguageCode;
  }

  List<String> _voiceLanguageSearchOrder() {
    if (_voiceLanguageCode == _defaultVoiceLanguageCode) {
      return const [_defaultVoiceLanguageCode];
    }
    return [_voiceLanguageCode, _defaultVoiceLanguageCode];
  }

  Future<void> playBell() async {
    if (_soundsLoaded) {
      try {
        await _bellPlayer.stop();
        await _bellPlayer.seek(Duration.zero);
        await _bellPlayer.resume();
        return;
      } catch (e) {
        // Fall through to TTS
      }
    }
    // Fallback: use TTS for bell sound effect
    await _tts.speak('Ding!');
  }

  Future<void> playWarning() async {
    if (_soundsLoaded) {
      try {
        await _warningPlayer.stop();
        await _warningPlayer.seek(Duration.zero);
        await _warningPlayer.resume();
        return;
      } catch (e) {
        // Fall through to TTS
      }
    }
    // Fallback: use TTS
    await _tts.speak('Warning!');
  }

  Future<void> play30SecBell() async {
    await playBell3Times();
  }

  Future<void> playBell3Times() async {
    try {
      await _warningPlayer.stop();
      await _warningPlayer.setSource(AssetSource('sounds/bell_3times.mp3'));
      await _warningPlayer.resume();
    } catch (e) {
      // Fall back to generic bell
      await playBell();
    }
  }

  Future<void> playBell1Time() async {
    try {
      await _warningPlayer.stop();
      await _warningPlayer.setSource(AssetSource('sounds/bell_1time.mp3'));
      await _warningPlayer.resume();
    } catch (e) {
      // Fall back to generic bell
      await playBell();
    }
  }

  /// Plays only the level-specific count_30seconds.mp3.
  Future<void> play30SecBellThenCount(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await playCount30Seconds(level, enableMotivationalSound);
  }

  Future<void> speakQuote(String quote) async {
    final now = DateTime.now();
    if (_lastQuoteTime != null &&
        now.difference(_lastQuoteTime!) < _quoteCooldown) {
      return;
    }

    _lastQuoteTime = now;
    await _tts.speak(quote);
  }

  Future<void> speakQuoteForced(String quote) async {
    _lastQuoteTime = DateTime.now();
    await _tts.speak(quote);
  }

  Future<void> playMotivationVoice(String assetPath) async {
    try {
      await _voicePlayer.stop();
      await _voicePlayer.setSource(AssetSource(assetPath));
      await _voicePlayer.resume();
    } catch (e) {
      // Voice file not available, silently fail
    }
  }

  String _getLevelFolder(SavageLevel level) {
    return switch (level) {
      SavageLevel.level1 => 'mild',
      SavageLevel.level2 => 'medium',
      SavageLevel.level3 => 'savage',
    };
  }

  Future<Map<String, dynamic>> _loadAssetManifest() async {
    if (_assetManifestCache != null) {
      return _assetManifestCache!;
    }
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final manifest = json.decode(manifestJson) as Map<String, dynamic>;
    _assetManifestCache = manifest;
    return manifest;
  }

  String _voiceAssetPrefix(
    String languageCode,
    SavageLevel level,
    String subfolder,
  ) {
    final levelFolder = _getLevelFolder(level);
    return 'assets/sounds/$languageCode/$levelFolder/$subfolder/';
  }

  List<String> _voiceAssetsForPrefix(
    Map<String, dynamic> manifest,
    String prefix,
  ) {
    return manifest.keys
        .where(
          (key) =>
              key.startsWith(prefix) &&
              key.endsWith('.mp3') &&
              !key.contains('_full'),
        )
        .toList();
  }

  bool _hasAssetPath(Map<String, dynamic> manifest, String relativeAssetPath) {
    return manifest.containsKey('assets/$relativeAssetPath');
  }

  String? _pickLocalizedVoiceAsset(
    Map<String, dynamic> manifest,
    SavageLevel level,
    String subfolder,
  ) {
    for (final languageCode in _voiceLanguageSearchOrder()) {
      final prefix = _voiceAssetPrefix(languageCode, level, subfolder);
      final files = _voiceAssetsForPrefix(manifest, prefix);
      if (files.isNotEmpty) {
        return files[Random().nextInt(files.length)];
      }
    }
    return null;
  }

  Future<void> _playRandomAsset(SavageLevel level, String subfolder) async {
    try {
      final manifest = await _loadAssetManifest();
      final selected = _pickLocalizedVoiceAsset(manifest, level, subfolder);
      if (selected == null) return;
      final relativePath = selected.replaceFirst('assets/', '');

      await _voicePlayer.stop();
      await _voicePlayer.setSource(AssetSource(relativePath));
      await _voicePlayer.resume();
    } catch (e) {
      // Audio files not available, silently fail
    }
  }

  Future<void> playExampleVoice(SavageLevel level) async {
    await _playRandomAsset(level, 'examples');
  }

  Future<void> playRandomRestVoice(SavageLevel level) async {
    await _playRandomAsset(level, 'rest');
  }

  /// Picks a random rest voice and only plays it if it can finish before
  /// the next-round countdown starts. [countdownThreshold] is typically `3`.
  /// [getRemainingSeconds] must return current remaining rest seconds at call
  /// time to account for async asset loading delays.
  Future<bool> playRandomRestVoiceIfFits(
    SavageLevel level,
    int countdownThreshold,
    int Function() getRemainingSeconds,
  ) async {
    try {
      final manifest = await _loadAssetManifest();
      final selected = _pickLocalizedVoiceAsset(manifest, level, 'rest');
      if (selected == null) return false;
      final relativePath = selected.replaceFirst('assets/', '');

      await _voicePlayer.stop();
      await _voicePlayer.setSource(AssetSource(relativePath));

      // iOS may return null/zero immediately after setSource().
      Duration? duration = await _voicePlayer.getDuration();
      if (duration == null || duration.inMilliseconds <= 0) {
        try {
          duration = await _voicePlayer.onDurationChanged.first.timeout(
            const Duration(seconds: 2),
          );
        } catch (_) {
          return false;
        }
      }

      final currentRemaining = getRemainingSeconds();
      final msUntilCountdown = (currentRemaining - countdownThreshold) * 1000;

      // Keep a 1-second safety margin for tick jitter.
      if (duration.inMilliseconds > msUntilCountdown - 1000) {
        return false;
      }

      await _voicePlayer.resume();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> playRandomExerciseVoice(SavageLevel level) async {
    await _playRandomAsset(level, 'exercise');
  }

  /// Picks a random exercise voice and only plays it if its duration fits
  /// before the 30-second bell. [bellThreshold] is the last-seconds threshold
  /// (e.g. 30). [getRemainingSeconds] returns the **current** remaining seconds
  /// at the moment it is called — this is critical because async asset loading
  /// can take several seconds, so we must re-check right before playback.
  Future<bool> playRandomExerciseVoiceIfFits(
    SavageLevel level,
    int bellThreshold,
    int Function() getRemainingSeconds,
  ) async {
    try {
      final manifest = await _loadAssetManifest();
      final selected = _pickLocalizedVoiceAsset(manifest, level, 'exercise');
      if (selected == null) return false;
      final relativePath = selected.replaceFirst('assets/', '');

      await _voicePlayer.stop();
      await _voicePlayer.setSource(AssetSource(relativePath));

      // getDuration() can return null or Duration.zero on iOS immediately
      // after setSource(). Use onDurationChanged to get a reliable value.
      Duration? duration = await _voicePlayer.getDuration();
      if (duration == null || duration.inMilliseconds <= 0) {
        try {
          duration = await _voicePlayer.onDurationChanged.first.timeout(
            const Duration(seconds: 2),
          );
        } catch (_) {
          // Timed out — can't determine duration, skip to be safe.
          return false;
        }
      }

      // Re-check timing RIGHT before playing. Async work above may have
      // consumed several seconds, so the original estimate is stale.
      final currentRemaining = getRemainingSeconds();
      final msUntilBell = (currentRemaining - bellThreshold) * 1000;

      // Add 1-second safety margin for timer tick jitter.
      if (duration.inMilliseconds > msUntilBell - 1000) {
        return false;
      }

      await _voicePlayer.resume();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> playRandomStartVoice(SavageLevel level) async {
    await _playRandomAsset(level, 'start');
  }

  /// Returns the count sound folder based on motivational sound setting.
  /// If motivational sound is enabled, uses the level-specific folder;
  /// otherwise uses 'neutral'.
  String _getCountFolder(SavageLevel level, bool enableMotivationalSound) {
    return enableMotivationalSound ? _getLevelFolder(level) : 'neutral';
  }

  Future<void> _playCountSound(
    String fileName,
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    final folder = _getCountFolder(level, enableMotivationalSound);
    try {
      final manifest = await _loadAssetManifest();
      for (final languageCode in _voiceLanguageSearchOrder()) {
        final path = 'sounds/$languageCode/$folder/count/$fileName';
        if (_hasAssetPath(manifest, path)) {
          await _playCountPath(path);
          return;
        }
      }
    } catch (_) {
      // Asset manifest unavailable, skip cue playback.
    }
  }

  Future<bool> _playCountPath(String path) async {
    try {
      await _countPlayer.stop();
      await _countPlayer.setSource(AssetSource(path));
      await _countPlayer.resume();
      return true;
    } catch (e) {
      // Count sound not available, silently fail
      return false;
    }
  }

  Future<void> playCount(
    int number,
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound('count_$number.mp3', level, enableMotivationalSound);
  }

  Future<void> playCountFinish(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound('count_finish.mp3', level, enableMotivationalSound);
  }

  Future<void> playCountRest(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound('count_rest.mp3', level, enableMotivationalSound);
  }

  Future<void> playCountStart(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound('count_start.mp3', level, enableMotivationalSound);
  }

  /// Warm-up cue uses the savage count asset so warm-up cue loudness is
  /// consistent with the current motivational mode and savage level.
  Future<void> playCountStartWarmUp(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    final folder = _getCountFolder(level, enableMotivationalSound);
    try {
      final manifest = await _loadAssetManifest();
      for (final languageCode in _voiceLanguageSearchOrder()) {
        final path =
            'sounds/$languageCode/$folder/count/count_start_warmingup.mp3';
        if (_hasAssetPath(manifest, path)) {
          await _playCountPath(path);
          return;
        }
      }
    } catch (_) {
      // Asset manifest unavailable, skip cue playback.
    }
  }

  /// Cool-down cue uses the same localized count folder routing.
  Future<void> playCountStartCoolDown(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    final folder = _getCountFolder(level, enableMotivationalSound);
    try {
      final manifest = await _loadAssetManifest();
      for (final languageCode in _voiceLanguageSearchOrder()) {
        final path =
            'sounds/$languageCode/$folder/count/count_start_cooldown.mp3';
        if (_hasAssetPath(manifest, path)) {
          await _playCountPath(path);
          return;
        }
      }
    } catch (_) {
      // Asset manifest unavailable, skip cue playback.
    }
  }

  Future<void> playCount30Seconds(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound(
      'count_30seconds.mp3',
      level,
      enableMotivationalSound,
    );
  }

  Future<void> playCount10Seconds(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound(
      'count_10seconds.mp3',
      level,
      enableMotivationalSound,
    );
  }

  Future<void> playClapping() async {
    try {
      await _clapPlayer.stop();
      await _clapPlayer.setSource(AssetSource('sounds/clapping.mp3'));
      await _clapPlayer.resume();
    } catch (e) {
      // Clapping sound not available, silently fail
    }
  }

  Future<void> playCount10SecondsWithClapping(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    unawaited(playClapping());
    unawaited(playCount10Seconds(level, enableMotivationalSound));
  }

  /// Updates the volume for all audio players and TTS.
  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    await _bellPlayer.setVolume(clamped);
    await _warningPlayer.setVolume(clamped);
    await _voicePlayer.setVolume(clamped);
    await _countPlayer.setVolume(clamped);
    await _clapPlayer.setVolume(clamped);
    await _tts.setVolume(clamped);
  }

  /// Stops only the voice player (used to cut exercise voices before
  /// a higher-priority announcement like count_30seconds).
  Future<void> stopVoice() async {
    await _voicePlayer.stop();
  }

  void resetQuoteCooldown() {
    _lastQuoteTime = null;
  }

  /// Starts a silent audio loop to keep the Dart isolate alive on iOS.
  /// iOS suspends the isolate when no audio is playing; this prevents that.
  Future<void> startKeepAlive() async {
    await _keepAlivePlayer.setReleaseMode(ReleaseMode.loop);
    await _keepAlivePlayer.setSource(AssetSource('sounds/silence.wav'));
    await _keepAlivePlayer.resume();
  }

  /// Stops the silent keepalive audio loop.
  Future<void> stopKeepAlive() async {
    await _keepAlivePlayer.stop();
  }

  Future<void> stop() async {
    await _tts.stop();
    await _bellPlayer.stop();
    await _warningPlayer.stop();
    await _voicePlayer.stop();
    await _countPlayer.stop();
    await _clapPlayer.stop();
  }

  Future<void> dispose() async {
    await stop();
    await stopKeepAlive();
    await _bellPlayer.dispose();
    await _warningPlayer.dispose();
    await _voicePlayer.dispose();
    await _countPlayer.dispose();
    await _clapPlayer.dispose();
    await _keepAlivePlayer.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
