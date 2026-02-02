import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _warningPlayer = AudioPlayer();
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

  void resetQuoteCooldown() {
    _lastQuoteTime = null;
  }

  Future<void> stop() async {
    await _tts.stop();
    await _bellPlayer.stop();
    await _warningPlayer.stop();
  }

  Future<void> dispose() async {
    await stop();
    await _bellPlayer.dispose();
    await _warningPlayer.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
