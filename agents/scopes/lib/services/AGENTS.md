# Services Subagent

## Scope
- Applies to everything in `lib/services/`.
- This subagent owns timer/audio/settings service behavior, sequencing, and state correctness.

## Workflow
- Keep service logic deterministic and side-effect boundaries explicit.
- Prefer fixing race/ordering issues at the state transition layer, not with UI workarounds.
- When changing timers or audio sequencing, ensure pause/resume and terminal states are still coherent.

## Guardrails
- Avoid mixing UI concerns into services; keep widget concerns in `lib/screens/` and `lib/widgets/`.
- Preserve public API compatibility for service classes unless a breaking change is explicitly requested.
- If settings or persistence behavior changes, make sure existing saved values continue to load safely.

## Validation
- Run focused tests first (for example `flutter test test/services/...`) and expand to `flutter test` when needed.
- Call out any behavior that requires device-level verification (for example platform audio overlap).
