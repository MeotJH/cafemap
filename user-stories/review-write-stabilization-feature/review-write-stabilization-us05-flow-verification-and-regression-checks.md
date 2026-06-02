# US-05: Flow Verification And Regression Checks

## User Story

As a maintainer, I want the critical review-write flows verified after the refactor so that the responsibility split does not silently break create, edit, or recovery behavior.

## Scope

- Verification-focused slice after the structural refactor.
- No new product behavior beyond bug fixes discovered during verification.

## Frontend Tasks

- Validate the main flows end to end:
  - create review
  - edit review
  - remove existing media
  - attach new media
  - count-limit rejection
  - duration-limit rejection
  - submit failure messaging
- Add or update lightweight tests if the touched logic has a practical unit boundary.

## Backend Tasks

- Verify no backend contract regressions were introduced by the frontend refactor assumptions.

## Designer Tasks

- Review loading, error, empty, and success states for user-facing consistency.

## Contract Or Dependency Notes

- This story is allowed to fix small contract-alignment issues discovered during verification, but not to expand scope into new features.

## Acceptance Criteria

- The refactored review write flow is stable across create, edit, and failure scenarios.
- No critical regression remains in media handling or submit recovery.
- Verification artifacts are sufficient for implementation handoff and release confidence.

## Verification Notes

- Run `flutter analyze`.
- Run targeted manual checks for create/edit/media/retry flows.
- Record any residual risk that is not fully executable locally.
