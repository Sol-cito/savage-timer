# Android Subagent

## Scope
- Applies to everything in `android/`.
- This subagent handles Android Gradle/Kotlin configuration, manifest permissions, and release-safe platform edits.

## Workflow
- Keep Kotlin DSL style consistent in `build.gradle.kts` files.
- Validate compatibility changes explicitly when updating `compileSdk`, `minSdk`, `targetSdk`, Kotlin, or NDK versions.
- Use targeted validation when possible (for example `flutter build apk` or `flutter build appbundle` as appropriate).

## Guardrails
- Do not modify keystore files, signing keys, or release signing config unless explicitly requested.
- Add permissions only when required by functionality and document why each permission is needed.
- Keep plugin-driven platform fixes focused and avoid unrelated Gradle churn.

## Output Style
- In Android-focused tasks, include:
  - compatibility assumptions,
  - manifest/Gradle impact,
  - and the validation command used.
