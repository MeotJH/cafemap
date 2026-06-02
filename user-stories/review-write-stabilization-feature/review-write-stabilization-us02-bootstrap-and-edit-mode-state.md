# US-02: Bootstrap And Edit-Mode State Separation

## User Story

As a maintainer, I want edit-mode bootstrap and initial review hydration to live in the Riverpod controller so that edit-only bugs can be fixed without destabilizing create mode or page rendering.

## Scope

- Separate bootstrap state handling from steady-state form rendering.
- Clarify responsibilities for:
  - initial review fetch
  - initial brand/menu resolution
  - initial score/attribute/media hydration

## Frontend Tasks

- Move bootstrap logic into the dedicated review-write Riverpod controller.
- Separate controller states for:
  - bootstrapping
  - bootstrap error
  - ready
- Make edit-mode hydration explicit and readable inside the controller.
- Ensure create mode does not depend on edit-mode-only branches.
- Keep the page shell responsible only for reacting to bootstrap state in the UI.

## Backend Tasks

- None expected unless an existing edit-flow bug reveals a contract mismatch.

## Designer Tasks

- Confirm loading, error, and ready states for create and edit modes.
- Confirm bootstrap failure copy expectations if the initial review cannot be loaded.

## Contract Or Dependency Notes

- `reviewDetail` fetch behavior and existing review payload remain unchanged.
- The page shell reads bootstrap state from the controller instead of owning bootstrap fields directly.

## Acceptance Criteria

- Edit-mode initialization is readable as a distinct controller flow.
- Create mode and edit mode no longer share hidden implicit state assumptions.
- Bootstrap loading and bootstrap error states are clearly represented through controller state.

## Verification Notes

- Run `flutter analyze`.
- Verify:
  - create mode entry
  - edit mode with `initialReview`
  - edit mode requiring server fetch
  - edit-mode bootstrap failure handling
