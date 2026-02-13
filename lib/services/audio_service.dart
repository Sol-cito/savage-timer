import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/timer_settings.dart';

class AudioService {
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _warningPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();
  final AudioPlayer _countPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  DateTime? _lastQuoteTime;
  static const _quoteCooldown = Duration(seconds: 15);

  bool _isInitialized = false;

  bool _soundsLoaded = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

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

  Future<void> _playRandomAsset(SavageLevel level, String subfolder) async {
    final levelFolder = _getLevelFolder(level);
    final prefix = 'assets/sounds/$levelFolder/$subfolder/';

    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final manifest = json.decode(manifestJson) as Map<String, dynamic>;

      final files = manifest.keys
          .where((key) =>
              key.startsWith(prefix) &&
              key.endsWith('.mp3') &&
              !key.contains('_full'))
          .toList();

      if (files.isEmpty) return;

      final selected = files[Random().nextInt(files.length)];
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

  Future<void> playRandomExerciseVoice(SavageLevel level) async {
    await _playRandomAsset(level, 'exercise');
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
    final path = 'sounds/$folder/count/$fileName';
    try {
      await _countPlayer.stop();
      await _countPlayer.setSource(AssetSource(path));
      await _countPlayer.resume();
    } catch (e) {
      // Count sound not available, silently fail
    }
  }

  Future<void> playCount(
    int number,
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound(
      'count_$number.mp3',
      level,
      enableMotivationalSound,
    );
  }

  Future<void> playCountFinish(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound(
      'count_finish.mp3',
      level,
      enableMotivationalSound,
    );
  }

  Future<void> playCountRest(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound(
      'count_rest.mp3',
      level,
      enableMotivationalSound,
    );
  }

  Future<void> playCountStart(
    SavageLevel level,
    bool enableMotivationalSound,
  ) async {
    await _playCountSound(
      'count_start.mp3',
      level,
      enableMotivationalSound,
    );
  }

  void resetQuoteCooldown() {
    _lastQuoteTime = null;
  }

  Future<void> stop() async {
    await _tts.stop();
    await _bellPlayer.stop();
    await _warningPlayer.stop();
    await _voicePlayer.stop();
    await _countPlayer.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _bellPlayer.dispose();
    await _warningPlayer.dispose();
    await _voicePlayer.dispose();
    await _countPlayer.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
