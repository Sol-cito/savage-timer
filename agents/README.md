# Agents Folder

This folder is a structured mirror of all live scoped `AGENTS.md` files.

## Why This Exists
- Scoped `AGENTS.md` files must stay in their real directories (`test/`, `ios/`, etc.) to be applied automatically by coding agents.
- A central folder is useful for discoverability, review, and bulk edits.
- This pattern is feasible and practical, but not a required standard in Codex itself.

## Structure
- `agents/scopes/root/AGENTS.md` mirrors `AGENTS.md`
- `agents/scopes/lib/AGENTS.md` mirrors `lib/AGENTS.md`
- `agents/scopes/test/AGENTS.md` mirrors `test/AGENTS.md`
- `agents/scopes/ios/AGENTS.md` mirrors `ios/AGENTS.md`
- `agents/scopes/android/AGENTS.md` mirrors `android/AGENTS.md`
- `agents/scopes/lib/services/AGENTS.md` mirrors `lib/services/AGENTS.md`

## Sync Commands
- Pull live files into this folder:
  - `bash agents/sync.sh pull`
- Push this folder back to live scoped files:
  - `bash agents/sync.sh push`
- View mapping:
  - `bash agents/sync.sh list`
