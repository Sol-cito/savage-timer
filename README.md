# Savage Timer

**The boxing timer that doesn't let you quit.**

A cross-platform interval timer app for iOS and Android that pushes you through your workouts with motivational (and savage) voice coaching.

---

## Features

### Core Timer Functionality
- **Customizable Rounds** - Set 1-12 rounds per session
- **Flexible Durations** - Round time from 1-5 minutes, rest from 10-60 seconds
- **Visual Countdown** - Clean circular progress indicator with large time display
- **Background Support** - Timer keeps running when you leave the app

### Savage Motivation System
Choose your coaching intensity with 3 savage levels:

| Level | Style | Example |
|-------|-------|---------|
| **Level 1** | Encouraging | *"You got this!"*, *"Keep pushing!"* |
| **Level 2** | Demanding | *"Focus!"*, *"Don't slow down!"* |
| **Level 3** | Brutal | *"Is that all you got?"*, *"Weak quits, you don't!"* |

### Multi-Sensory Alerts
- **Voice Coaching** - Text-to-speech motivation during rounds
- **Vibration Patterns** - Distinct haptic feedback for round start, end, and warnings
- **Audio Cues** - Sound alerts for transitions
- **30-Second Warning** - Optional alert when time is running low

### Settings Persistence
Your preferences are saved automatically and restored when you reopen the app.

---

## Screenshots

<p align="center">
  <i>Screenshots coming soon</i>
</p>

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.0 or higher)
- For iOS: Xcode 14+ and CocoaPods
- For Android: Android Studio with SDK 24+ (Android 7.0 Nougat)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Sol-cito/savage-timer.git
   cd savage-timer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on your device**
   ```bash
   # iOS
   flutter run -d ios

   # Android
   flutter run -d android
   ```

---

## Building for Release

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Or for App Bundle (recommended for Play Store)
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
# Then open ios/Runner.xcworkspace in Xcode to archive
```

---

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/
│   ├── timer_settings.dart    # Timer configuration model
│   └── workout_session.dart   # Session state model
├── screens/
│   ├── settings_screen.dart   # Settings UI
│   └── timer_screen.dart      # Main timer UI
├── services/
│   ├── audio_service.dart     # TTS and sound playback
│   ├── settings_service.dart  # Preferences persistence
│   ├── timer_service.dart     # Core timer logic
│   └── vibration_service.dart # Haptic feedback
├── utils/
│   └── motivation_quotes.dart # Quote database by level
└── widgets/
    ├── circular_timer.dart    # Progress ring widget
    ├── control_button.dart    # Play/pause/reset buttons
    ├── round_indicator.dart   # Round counter display
    └── savage_level_selector.dart  # Level picker
```

---

## Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Audio**: flutter_tts, audioplayers
- **Haptics**: vibration
- **Storage**: shared_preferences
- **Notifications**: flutter_local_notifications

---

## Roadmap

- [ ] Custom audio file support for motivation quotes
- [ ] Workout history tracking
- [ ] Multiple workout types (HIIT, running, weightlifting)
- [ ] Custom quote creation
- [ ] Apple Watch / Wear OS companion app
- [ ] Widget support for quick timer access

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Built for fighters, by fighters
- Inspired by the need for a timer that actually pushes you

---

<p align="center">
  <b>Train hard. Stay savage.</b>
</p>
