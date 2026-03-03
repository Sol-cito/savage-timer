# Repository Guidelines

## Project Structure & Module Organization
- `lib/` contains app code: `models/`, `services/`, `screens/`, `widgets/`, and `utils/`.
- `test/` mirrors runtime modules (for example, `test/services/` for `lib/services/`) plus widget/screen tests.
- `assets/` stores images and audio packs (`mild/`, `medium/`, `savage/`, `neutral/`); keep `pubspec.yaml` asset entries aligned with any additions.
- `scripts/` contains tooling such as `build.dart` (release flow) and `split_audio.py` (asset prep).
- Platform projects live in `android/` and `ios/`; docs and policy pages are in `docs/`.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies.
- `flutter run -d ios` / `flutter run -d android` launches locally on device/simulator.
- `flutter analyze` runs static analysis using `flutter_lints`.
- `dart format lib test scripts` formats source and tests.
- `flutter test` runs the full test suite.
- `flutter test test/services/timer_service_test.dart` runs a targeted test file.
- `dart run scripts/build.dart --android-only` builds release artifacts via Shorebird (use `--ios-only` or no flag for both).

## Coding Style & Naming Conventions
- Follow Dart/Flutter defaults: 2-space indentation, trailing commas for multiline widget trees, and analyzer-clean code.
- File names use `snake_case.dart`; classes/enums use `PascalCase`; methods/variables use `camelCase`.
- Keep UI components focused and reusable in `lib/widgets/`; keep business logic in `lib/services/`.

## Testing Guidelines
- Use `flutter_test` (and `fake_async` where timing behavior matters).
- Name tests `*_test.dart` and group cases with clear behavior-driven descriptions.
- Add/update tests when changing timer flow, audio sequencing, or settings persistence.
- Before opening a PR, run at minimum: `flutter analyze` and `flutter test`.

## Commit & Pull Request Guidelines
- Match existing history style: concise, imperative summaries (for example, `Fix 30sec bell async race condition`).
- Keep commits scoped to one logical change.
- PRs should include: what changed, why, test evidence (`flutter analyze`/`flutter test`), and screenshots/video for UI changes.
- Link related issues/tasks and call out platform-specific impact (`iOS`, `Android`, or both).

## Security & Configuration Tips
- Never commit secrets; keep local values in `.env` only.
- After changing assets, verify `pubspec.yaml` and run `flutter pub get` to refresh bundles.
