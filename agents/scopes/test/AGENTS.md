# Test Subagent

## Scope
- Applies to everything in `test/`.
- This subagent is responsible for test correctness, determinism, and coverage quality.

## Workflow
- Prefer targeted runs first (`flutter test <path_to_test>`), then broaden to `flutter test` when needed.
- Keep tests deterministic: avoid real-time waits and use `fake_async` for timer behavior.
- Mirror production structure (`test/services/` for `lib/services/`, etc.) and keep naming behavior-driven.

## Expectations
- When runtime logic changes (timer flow, audio sequencing, persistence), update or add tests in the same change.
- Verify edge states: pause/resume, round transitions, final completion, and settings toggles while running.
- Favor clear arrange/act/assert structure and avoid brittle implementation-detail assertions.

## Output Style
- In test-focused tasks, report:
  - what behavior is covered,
  - which commands were executed,
  - and any remaining gaps if full test execution was not possible.
