# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Savage Timer is a Flutter cross-platform timer application targeting iOS, Android, and Web.

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app in debug mode
flutter run

# Run static analysis (linting)
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Format code
dart format .

# Build for specific platforms
flutter build ios
flutter build android
flutter build web

# Clean build artifacts
flutter clean
```

## Architecture

Currently a starter Flutter project with all application code in `lib/main.dart`. The project uses:
- Material Design theming (deepPurple color scheme)
- StatefulWidget pattern for state management
- Standard Flutter widget testing in `test/`

## Platform Configuration

- **Android**: App ID is `com.solcito.savagetimer.savage_timer`, uses Kotlin for build scripts
- **iOS**: Display name "Savage Timer"
- **Web**: PWA-capable with manifest.json

## Dependencies

- `cupertino_icons` - iOS-style icons
- `flutter_lints` - Recommended lint rules (configured in analysis_options.yaml)
