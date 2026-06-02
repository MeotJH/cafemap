# US-01: Review Write Page Boundary And Section Split

## User Story

As a maintainer, I want the review write route to stay as a page shell with page-local widgets so that route-level UI changes do not require touching business-state logic.

## Scope

- Keep the current route and visible flow.
- Keep `ReviewWritePage` as the route shell.
- Move page-only rendering concerns into page-local widgets or helper files.
- Do not change backend contracts in this story.

## Frontend Tasks

- Reduce `review_write_page.dart` to route-shell responsibilities:
  - app bar and route entry
  - `BuildContext`-bound dialog, toast, and navigation behavior
  - local `TextEditingController` / picker integration
- Extract page-only widgets or helper files for:
  - media tiles
  - autocomplete option list behavior
  - other route-local render helpers
- Keep section rendering dependent on explicit state inputs and callbacks from the controller-facing page shell.

## Backend Tasks

- None expected in this story.

## Designer Tasks

- Confirm that no visual redesign is required.
- Confirm labels and hierarchy stay consistent after section extraction.

## Contract Or Dependency Notes

- Existing route parameters remain unchanged.
- The page shell consumes a dedicated Riverpod review-write controller rather than owning the full form state.

## Acceptance Criteria

- `ReviewWritePage` is clearly a route shell rather than the main business-state owner.
- Page-local widgets are render-focused and do not directly perform repository calls.
- No visible behavior change is introduced by this story alone.

## Verification Notes

- Run `flutter analyze`.
- Smoke-check create mode rendering and edit mode rendering.
