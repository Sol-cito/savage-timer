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


# Savage Timer App - Development Guide

## 📋 Development Phases & Prompt Strategy

### **Phase 1: Project Structure & Basic Setup**
```
First Prompt:
"I'm building a boxing timer app in Flutter.
- App name: SavageTimer
- Create the following folder structure:
  - lib/models/ (data models)
  - lib/services/ (timer, audio services)
  - lib/screens/ (UI screens)
  - lib/widgets/ (reusable components)
  - lib/utils/ (helper functions)
- Add necessary packages to pubspec.yaml:
  - audioplayers (sound playback)
  - vibration (vibration)
  - provider or riverpod (state management)
  - shared_preferences (settings storage)
  - android_alarm_manager_plus (background execution)"
```

### **Phase 2: Data Model Definition**
```
Second Prompt:
"Create data models for the following features:
1. TimerSettings model:
   - roundDuration (Duration)
   - restDuration (Duration)
   - totalRounds (int)
   - enableLastSecondsAlert (bool)
   - lastSecondsThreshold (int, default 30)
   - savageLevel (1-3)
   
2. WorkoutSession model:
   - currentRound (int)
   - isResting (bool)
   - remainingTime (Duration)
   - sessionState (idle/running/paused/completed)

Include JSON serialization functionality."
```

### **Phase 3: Core Timer Logic**
```
Third Prompt:
"Create a TimerService class:
- Methods: startTimer(), pauseTimer(), resetTimer()
- Update remainingTime every second
- Automatically switch to rest time when round ends
- Switch to next round when rest ends
- Detect session completion
- Enable UI to receive real-time state updates via Stream"
```

### **Phase 4: Audio System**
```
Fourth Prompt:
"Create an AudioService class:
1. Play basic alarm sounds (round start/end, rest start/end)
2. Motivation voice playback logic:
   - Different quote lists per savageLevel
   - Situation-specific quotes (round mid, late, before rest)
   - Randomly select quotes
   - Apply cooldown to prevent too frequent playback (e.g., max once per 15 seconds)
3. Implement temporarily with Text-to-Speech, but make it replaceable with custom audio files later
4. Enable playback in background"
```

### **Phase 5: Motivation Quotes Database**
```
Fifth Prompt:
"Create utils/motivation_quotes.dart file:
- savageLevel 1 (Encouragement): 'You got this!', 'Keep going!', 'Stay strong!' etc.
- savageLevel 2 (Nagging): 'Focus!', 'Keep the pace!', 'Don't give up!' etc.
- savageLevel 3 (Harsh): 'Is that all you got?', 'Weak dies!', 'More!!' etc.
- Categorize by situation (roundStart, roundMid, roundFinal, restTime)
- Use English for global audience, structure for future multi-language expansion"
```

### **Phase 6: Main UI**
```
Sixth Prompt:
"Create 3 main screens:

1. SettingsScreen:
   - Round duration setting (Slider, 1-5 minutes)
   - Rest duration setting (Slider, 10-60 seconds)
   - Total rounds (NumberPicker, 1-12)
   - Last 30 seconds alert ON/OFF
   - Savage Level selection (SegmentedButton, 1-3)
   
2. TimerScreen:
   - Display remaining time in large numbers
   - Show current round / total rounds
   - Start/Pause/Reset buttons
   - Progress state display (In Round / Resting)
   - Visual representation with CircularProgressIndicator
   
3. Connect both screens with BottomNavigation"
```

### **Phase 7: Background Execution**
```
Seventh Prompt:
"Enable app to work in background:
- Add necessary permissions to android/app/src/main/AndroidManifest.xml
  - FOREGROUND_SERVICE
  - VIBRATE
  - WAKE_LOCK
- Keep timer running with Foreground Service
- Enable audio/vibration in background
- Display current state via Notification"
```

### **Phase 8: Vibration Feature**
```
Eighth Prompt:
"Add VibrationService:
- Round start: 2 short vibrations
- Round end: 1 long vibration
- Last 30 seconds: 3 short vibrations
- Rest end: 1 short vibration"
```

### **Phase 9: State Persistence**
```
Ninth Prompt:
"Save user settings with shared_preferences:
- Persist last settings even after app restart
- Create SettingsService class
- Load saved settings on app startup"
```

### **Phase 10: Testing & Finalization**
```
Final Prompt:
"1. Add basic error handling
2. Display loading states
3. Final check for buildable state
4. Create README.md (app description, build instructions)"
```

---

## 🎯 **Additional Tips**

### **Structure for Extensibility**
- Add `WorkoutType` enum (boxing, running, weightlifting)
- Enable different settings/quotes per workout type

### **Audio File Preparation**
- Use TTS initially
- Later add actual recorded files to `assets/sounds/` folder
- Consider hiring voice artists on Fiverr or Upwork

### **Debugging Strategy**
- Set round time to 10 seconds initially for quick testing
- Add sufficient logging

### **Release Strategy**
- I would like to release it both for IOS and Android. So make sure this flutter project can be built for both platform.
---

## 📱 **App Concept Summary**

**Name:** Savage Timer

**Core Features:**
1. User can set round duration (e.g., 1-3 minutes, various options)
2. User can set total number of rounds
3. User can configure additional sound effects when round time is running low (e.g., last 30 seconds)
4. **Key Feature:** During rounds, specific voices play at challenging moments to motivate users with various expressions
5. User can set savage level in 3 tiers:
    - Level 1: Simple encouragement
    - Level 2: Light nagging + encouragement
    - Level 3: Harsh criticism + push
6. Provides various "harsh comments" or "motivational quotes" that a coach might say, categorized by situation (during round, before end, rest time, etc.)
7. App must run in background (continue even when user leaves the screen)
8. Currently a timer for boxing, but should be structured to allow future expansion to running, weight lifting, and other activities

---

## 🚀 **Getting Started**

Follow the phases sequentially, submitting one prompt at a time to Claude Code CLI. Complete and test each phase before moving to the next.

**Recommended Approach:**
1. Start with Phase 1 (Project Setup)
2. Verify the folder structure is created correctly
3. Move to Phase 2 (Data Models)
4. Continue through each phase methodically

This systematic approach will help Claude Code CLI implement each component properly and maintain code quality throughout development.

Good luck with your Savage Timer app! 💪🥊
