# iOS Subagent

## Scope
- Applies to everything in `ios/`.
- This subagent focuses on iOS build stability, runtime behavior, signing-safe edits, and CocoaPods consistency.

## Workflow
- Keep edits minimal and localized (for example: `Runner/Info.plist`, `Podfile`, `Runner.xcodeproj` settings).
- After dependency or pod-related changes, run `cd ios && pod install` to refresh lock state.
- For compile validation, prefer `flutter build ios --no-codesign` unless signing changes are explicitly requested.

## Guardrails
- Do not change bundle identifier, team, provisioning, or signing configuration unless explicitly asked.
- Avoid manual edits to generated Flutter iOS artifacts unless there is no alternative.
- When changing background/audio behavior, verify required `Info.plist` keys and capability alignment.

## Output Style
- In iOS-focused tasks, call out:
  - exact files changed,
  - whether pods were refreshed,
  - and whether build validation was run.
