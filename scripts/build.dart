// ignore_for_file: avoid_print
import 'dart:io';

/// Build script for Savage Timer.
///
/// Usage:
///   dart run scripts/build.dart               # Build both Android AAB and iOS
///   dart run scripts/build.dart --android-only # Build Android AAB only
///   dart run scripts/build.dart --ios-only     # Build iOS only
///   dart run scripts/build.dart --no-increment # Skip build number increment
void main(List<String> args) async {
  final androidOnly = args.contains('--android-only');
  final iosOnly = args.contains('--ios-only');
  final noIncrement = args.contains('--no-increment');

  final buildAndroid = !iosOnly;
  final buildIos = !androidOnly;

  // 1. Read current version from pubspec.yaml
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml not found. Run from the project root.');
    exit(1);
  }

  var pubspecContent = pubspecFile.readAsStringSync();
  final versionMatch = RegExp(
    r'^version:\s*(\S+)$',
    multiLine: true,
  ).firstMatch(pubspecContent);
  if (versionMatch == null) {
    stderr.writeln('Error: Could not find version in pubspec.yaml');
    exit(1);
  }

  final fullVersion = versionMatch.group(1)!;
  final parts = fullVersion.split('+');
  if (parts.length != 2) {
    stderr.writeln(
      'Error: Version must be in format X.Y.Z+buildNumber, got: $fullVersion',
    );
    exit(1);
  }

  final versionName = parts[0];
  var buildNumber = int.tryParse(parts[1]);
  if (buildNumber == null) {
    stderr.writeln('Error: Build number is not a valid integer: ${parts[1]}');
    exit(1);
  }

  // 2. Increment build number
  if (!noIncrement) {
    buildNumber++;
    final newVersion = '$versionName+$buildNumber';
    pubspecContent = pubspecContent.replaceFirst(
      'version: $fullVersion',
      'version: $newVersion',
    );
    pubspecFile.writeAsStringSync(pubspecContent);
    print('Version bumped: $fullVersion -> $newVersion');
  } else {
    print('Skipping version bump (--no-increment). Current: $fullVersion');
  }

  final currentVersion = '$versionName+$buildNumber';
  final fileLabel = '${versionName}_$buildNumber';

  // Ensure build_output directory exists
  final outputDir = Directory('build_output');
  if (!outputDir.existsSync()) {
    outputDir.createSync();
  }

  String? aabOutputPath;
  String? iosNote;

  // 3. Build Android AAB
  if (buildAndroid) {
    print('\n--- Building Android AAB ---');
    final aabResult = await Process.run('flutter', [
      'build',
      'appbundle',
      '--release',
    ]);
    stdout.write(aabResult.stdout);
    stderr.write(aabResult.stderr);

    if (aabResult.exitCode != 0) {
      stderr.writeln('Error: Android AAB build failed.');
      exit(1);
    }

    // Copy AAB to build_output
    final aabSource = File('build/app/outputs/bundle/release/app-release.aab');
    if (aabSource.existsSync()) {
      aabOutputPath = 'build_output/savage_timer_$fileLabel.aab';
      aabSource.copySync(aabOutputPath);
      print('AAB copied to $aabOutputPath');
    } else {
      stderr.writeln('Warning: AAB file not found at expected path.');
    }
  }

  // 4. Build iOS
  if (buildIos) {
    print('\n--- Building iOS Archive ---');
    final iosResult = await Process.run('flutter', [
      'build',
      'ipa',
      '--release',
    ]);
    stdout.write(iosResult.stdout);
    stderr.write(iosResult.stderr);

    if (iosResult.exitCode != 0) {
      stderr.writeln('Error: iOS build failed.');
      exit(1);
    }

    iosNote =
        'iOS archive built. Use Xcode or Transporter to upload to App Store Connect.';
    print(iosNote);
  }

  // 5. Print summary
  print('\n========== BUILD SUMMARY ==========');
  print('Version: $currentVersion');
  if (aabOutputPath != null) {
    print('AAB:     $aabOutputPath');
  }
  if (iosNote != null) {
    print('iOS:     $iosNote');
  }
  print('===================================');
}
