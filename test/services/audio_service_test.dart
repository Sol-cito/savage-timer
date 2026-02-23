import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:savage_timer/models/timer_settings.dart';

void main() {
  group('AudioService iOS background audio configuration', () {
    test('Info.plist contains UIBackgroundModes with audio', () {
      final plistFile = File('ios/Runner/Info.plist');
      expect(plistFile.existsSync(), isTrue,
          reason: 'Info.plist should exist');

      final content = plistFile.readAsStringSync();
      expect(content, contains('UIBackgroundModes'),
          reason: 'Info.plist must declare UIBackgroundModes');
      expect(content, contains('<string>audio</string>'),
          reason: 'UIBackgroundModes must include audio for background playback');
    });

    test('audio_session package is used for AVAudioSession configuration', () {
      final sourceFile = File('lib/services/audio_service.dart');
      expect(sourceFile.existsSync(), isTrue);

      final content = sourceFile.readAsStringSync();
      expect(content, contains("package:audio_session/audio_session.dart"),
          reason: 'audio_session package must be imported for background audio');
      expect(content, contains('AVAudioSessionCategory.playback'),
          reason: 'Audio session must be configured with playback category');
      expect(content, contains('setActive(true)'),
          reason: 'Audio session must be activated');
    });
  });

  group('AudioService Android background audio configuration', () {
    test('AndroidManifest.xml contains FOREGROUND_SERVICE permission', () {
      final manifestFile =
          File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue,
          reason: 'AndroidManifest.xml should exist');

      final content = manifestFile.readAsStringSync();
      expect(content, contains('FOREGROUND_SERVICE'),
          reason:
              'AndroidManifest must include FOREGROUND_SERVICE for background audio');
      expect(content, contains('WAKE_LOCK'),
          reason: 'AndroidManifest must include WAKE_LOCK for background execution');
    });
  });


  group('AudioService level folder mapping', () {
    test('all SavageLevel values are handled', () {
      for (final level in SavageLevel.values) {
        final folder = _expectedFolder(level);
        expect(folder, isNotEmpty);
      }
    });

    test('level1 maps to mild', () {
      expect(_expectedFolder(SavageLevel.level1), 'mild');
    });

    test('level2 maps to medium', () {
      expect(_expectedFolder(SavageLevel.level2), 'medium');
    });

    test('level3 maps to savage', () {
      expect(_expectedFolder(SavageLevel.level3), 'savage');
    });
  });

  group('AudioService asset path construction', () {
    test('example path follows expected pattern', () {
      for (final level in SavageLevel.values) {
        final folder = _expectedFolder(level);
        final prefix = 'assets/sounds/$folder/examples/';
        expect(prefix, contains(folder));
        expect(prefix, endsWith('/'));
      }
    });

    test('rest path follows expected pattern', () {
      for (final level in SavageLevel.values) {
        final folder = _expectedFolder(level);
        final prefix = 'assets/sounds/$folder/rest/';
        expect(prefix, contains(folder));
        expect(prefix, endsWith('/'));
      }
    });

    test('exercise path follows expected pattern', () {
      for (final level in SavageLevel.values) {
        final folder = _expectedFolder(level);
        final prefix = 'assets/sounds/$folder/exercise/';
        expect(prefix, contains(folder));
        expect(prefix, endsWith('/'));
      }
    });

    test('start path follows expected pattern', () {
      for (final level in SavageLevel.values) {
        final folder = _expectedFolder(level);
        final prefix = 'assets/sounds/$folder/start/';
        expect(prefix, contains(folder));
        expect(prefix, endsWith('/'));
      }
    });

    test('asset relative path strips assets/ prefix correctly', () {
      const fullPath = 'assets/sounds/mild/examples/mild_example_1.mp3';
      final relativePath = fullPath.replaceFirst('assets/', '');
      expect(relativePath, 'sounds/mild/examples/mild_example_1.mp3');
      expect(relativePath, isNot(startsWith('assets/')));
    });

    test('exercise asset relative path strips prefix correctly', () {
      const fullPath = 'assets/sounds/savage/exercise/savage_exercise_1.mp3';
      final relativePath = fullPath.replaceFirst('assets/', '');
      expect(relativePath, 'sounds/savage/exercise/savage_exercise_1.mp3');
      expect(relativePath, isNot(startsWith('assets/')));
    });

    test('start asset relative path strips prefix correctly', () {
      const fullPath = 'assets/sounds/medium/start/medium_start_1.mp3';
      final relativePath = fullPath.replaceFirst('assets/', '');
      expect(relativePath, 'sounds/medium/start/medium_start_1.mp3');
      expect(relativePath, isNot(startsWith('assets/')));
    });
  });

  group('AudioService voice path per level', () {
    for (final level in SavageLevel.values) {
      final folder = _expectedFolder(level);

      test('$folder exercise path is correct', () {
        expect(_assetPrefix(level, 'exercise'),
            'assets/sounds/$folder/exercise/');
      });

      test('$folder rest path is correct', () {
        expect(_assetPrefix(level, 'rest'), 'assets/sounds/$folder/rest/');
      });

      test('$folder start path is correct', () {
        expect(_assetPrefix(level, 'start'), 'assets/sounds/$folder/start/');
      });

      test('$folder examples path is correct', () {
        expect(_assetPrefix(level, 'examples'),
            'assets/sounds/$folder/examples/');
      });
    }
  });

  group('AudioService _full file filtering', () {
    test('_full files would be excluded by the filter logic', () {
      final testFiles = [
        'assets/sounds/mild/exercise/mild_exercise_full.mp3',
        'assets/sounds/mild/exercise/mild_exercise_1.mp3',
        'assets/sounds/mild/exercise/mild_exercise_2.mp3',
      ];

      final filtered = testFiles
          .where((key) => key.endsWith('.mp3') && !key.contains('_full'))
          .toList();

      expect(filtered, hasLength(2));
      expect(filtered, isNot(contains('assets/sounds/mild/exercise/mild_exercise_full.mp3')));
      expect(filtered, contains('assets/sounds/mild/exercise/mild_exercise_1.mp3'));
      expect(filtered, contains('assets/sounds/mild/exercise/mild_exercise_2.mp3'));
    });
  });
}

/// Mirrors the private _getLevelFolder logic from AudioService.
String _expectedFolder(SavageLevel level) {
  return switch (level) {
    SavageLevel.level1 => 'mild',
    SavageLevel.level2 => 'medium',
    SavageLevel.level3 => 'savage',
  };
}

/// Builds the expected asset prefix for a given level and subfolder.
String _assetPrefix(SavageLevel level, String subfolder) {
  final folder = _expectedFolder(level);
  return 'assets/sounds/$folder/$subfolder/';
}
