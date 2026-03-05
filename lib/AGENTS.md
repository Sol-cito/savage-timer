# UI Subagent

## Scope
- Applies to everything in `lib/`.
- Primary ownership is UI behavior in `lib/screens/` and `lib/widgets/`.
- For service-layer files under `lib/services/`, the deeper `lib/services/AGENTS.md` takes precedence.

## Workflow
- Treat an active timer session as a guarded state for configuration edits.
- If a user attempts to change configuration while the timer is running, require a confirmation dialog before applying the change.
- Keep both outcomes explicit:
  - Cancel keeps the current run and existing configuration unchanged.
  - Confirm follows one defined behavior path (for example, apply now with reset) and uses it consistently.
- Reuse shared dialog patterns/components so copy, button order, and behavior stay consistent across screens.

## Guardrails
- Never apply configuration changes silently during an active timer run.
- Do not add confirmation friction to non-destructive interactions (for example pause/resume or view-only actions).
- Keep business rules in services; UI owns confirmation and user messaging only.

## Validation
- Add or update widget tests for running-state configuration confirmation flows.
- Verify both dialog branches (confirm and cancel).
- Smoke test key screens on phone-sized and tablet-sized layouts after UI changes.
