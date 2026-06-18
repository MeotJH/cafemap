# US-04: Submit Orchestration And Recovery

## User Story

As a maintainer, I want upload, payload building, create/update branching, and retry recovery to live in one orchestration boundary so that submit bugs can be debugged and verified independently from rendering.

## Scope

- Isolate submit orchestration from section rendering.
- Preserve current create/update behavior and auth/session retry behavior.

## Frontend Tasks

- Move into the dedicated review-write Riverpod controller:
  - pre-submit validation
  - payload building
  - media upload orchestration
  - create/update branching
  - recoverable auth/session retry
  - post-success provider invalidation
- Keep page-shell navigation and toast display explicit, based on the controller result.
- Make failure messages and retry path explicit.

## Backend Tasks

- None expected unless payload building reveals a current mismatch.

## Designer Tasks

- Confirm submit-state copy and failure-state copy.
- Confirm whether create/update success navigation stays as-is.

## Contract Or Dependency Notes

- Existing repository methods and provider invalidation behavior remain the integration contract.
- The controller returns a submission result object that the page shell can use for navigation and UI messaging.

## Acceptance Criteria

- Submit logic is readable as a single controller orchestration flow.
- Create and update branches are explicit.
- Recoverable auth/session failures are handled consistently.
- Success and failure side effects are easy to trace between controller and page shell.

## Verification Notes

- Run `flutter analyze`.
- Verify:
  - successful create
  - successful edit
  - upload failure path
  - recoverable auth/session retry path
  - provider invalidation and post-submit navigation
