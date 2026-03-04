# Subagents Guide

This repo uses multiple `AGENTS.md` files as scoped subagents.

## How It Works
1. The root `AGENTS.md` applies to the whole repository.
2. If a task touches files inside a folder with its own `AGENTS.md`, that folder rule set is added automatically.
3. If there is a conflict, the deeper (more specific) `AGENTS.md` wins.
4. `agents/scopes/` is a centralized mirror for maintenance only; runtime behavior still depends on live scoped files.

## Available Subagents
- `test/AGENTS.md` (`Test Subagent`)
  - Specializes in deterministic tests, coverage for behavior changes, and test execution flow.
- `ios/AGENTS.md` (`iOS Subagent`)
  - Specializes in `Podfile`/`Info.plist`/Xcode-safe edits and iOS build validation.
- `android/AGENTS.md` (`Android Subagent`)
  - Specializes in Gradle/Kotlin/manifest changes and Android compatibility validation.
- `lib/services/AGENTS.md` (`Services Subagent`)
  - Specializes in timer/audio/settings service logic, sequencing, and state transitions.
- `AGENTS.md` root (`Reviewer Subagent` trigger)
  - If prompt includes `review`, `code review`, or `reviewer`, the assistant switches to findings-first review mode.

## Centralized Folder Workflow
- Pull live instructions into centralized mirror:
  - `bash agents/sync.sh pull`
- Edit the files under `agents/scopes/...`.
- Push updated instructions back to live scoped locations:
  - `bash agents/sync.sh push`
- Verify mapping:
  - `bash agents/sync.sh list`

## Example Prompts
- "Use the test subagent: add tests for timer pause/resume edge cases."
- "Use the iOS subagent: investigate background audio behavior in `ios/Runner/Info.plist`."
- "Use the Android subagent: fix Android audio overlap issue and validate build."
- "Use the services subagent: investigate timer/audio sequencing race in `lib/services`."
- "Do a reviewer subagent pass for this PR."
