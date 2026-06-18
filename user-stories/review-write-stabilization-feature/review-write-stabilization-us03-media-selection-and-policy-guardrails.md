# US-03: Media Selection And Policy Guardrails

## User Story

As a maintainer, I want media selection and media policy checks to be isolated so that count-limit and video-duration changes do not leak into unrelated form logic.

## Scope

- Isolate media-specific state and actions.
- Preserve current rules:
  - max 5 total media items
  - max 30-second video duration
- Cover both create and edit flows with existing plus newly selected media.

## Frontend Tasks

- Move media state and policy mutation into the dedicated review-write Riverpod controller.
- Keep device and browser picker integration in the page shell, but pass picked media into the controller as explicit inputs.
- Separate handling for:
  - existing media
  - newly selected media
  - removal
  - policy validation
  - toast/error feedback contract between controller and page shell
- Ensure the media section consumes explicit inputs and callbacks instead of reaching into unrelated form state.

## Backend Tasks

- None expected unless a validation mismatch is discovered.

## Designer Tasks

- Confirm the copy for:
  - count limit reached
  - invalid duration
  - picker failure
  - upload-related feedback before submit

## Contract Or Dependency Notes

- Media item contract stays aligned with the current backend implementation.
- Media policy decisions should come from controller state/methods, not page-owned mutable collections.

## Acceptance Criteria

- Media rules are defined in one clear controller responsibility area.
- Existing and newly selected media are handled consistently in edit mode.
- Count and duration checks are enforced before submit.

## Verification Notes

- Run `flutter analyze`.
- Verify:
  - attach photos only
  - attach video only
  - mixed photo/video
  - 5-item cap
  - 30-second cap
  - remove existing and new media in edit mode
