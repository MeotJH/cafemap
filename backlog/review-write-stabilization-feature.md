# Feature: Review Write Stabilization

## Problem

`front/lib/presentation/pages/review_write_page.dart` currently owns too many responsibilities in one page state:

- edit-mode bootstrap and initial review recovery
- brand/menu loading and derived form state
- coffee/store score state and attribute state
- media selection, count limit, duration limit, and removal logic
- upload orchestration and create/update submit recovery
- user-facing UI rendering for all sections

This makes small changes risky. Media policy changes, edit-mode fixes, and submit recovery changes can easily regress each other because the state and async flows are tightly coupled inside one widget.

## Goal

- Reframe the review-write screen around the current Flutter layering used in this repo.
- Keep `ReviewWritePage` as the route shell, but move mutable form state and async orchestration into a Riverpod controller.
- Make edit-mode bootstrap, media policy, and submit recovery independently understandable and verifiable.

## In Scope

- Reframe `review_write_page.dart` into a route shell that owns only route wiring and ephemeral UI concerns.
- Introduce a dedicated Riverpod provider/controller for review-write state, bootstrap, media policy, and submit orchestration.
- Move page-local rendering helpers into page-local widget files or a sibling page folder instead of keeping them as inline page logic or extension-based splits.
- Verify the critical flows:
  - create review
  - edit existing review
  - mixed photo/video attachments
  - max 5 media items
  - max 30-second video rule
  - upload failure and retry messaging

## Out of Scope

- New review features or policy changes beyond current 5-item and 30-second limits
- Backend contract redesign
- Visual redesign of the review write screen
- Draft autosave, offline support, or background upload queues
- Review write route restructuring

## Data And Architecture Assumptions

- The route remains `ReviewWritePage` and still supports both create and edit modes.
- Existing backend media contract remains valid and should not be expanded in this feature unless required for bug fixes.
- Media item count and duration rules stay unchanged in this feature.
- Riverpod providers are the state/orchestration boundary for frontend business logic in this feature.
- Page-local `TextEditingController`, picker, dialog, toast, and navigation concerns may remain in the page shell when they are tied to `BuildContext` or device APIs.

## Proposed Direction

### Recommended structure

- `front/lib/presentation/pages/review_write_page.dart`
  - route entry
  - `BuildContext`-bound shell behavior only
  - text-controller sync
  - picker invocation
  - toast/dialog/navigation handling
- `front/lib/presentation/providers/review_write_provider.dart`
  - immutable `ReviewWriteState`
  - `ReviewWriteController`
  - edit bootstrap and hydration
  - derived form state
  - media policy and state mutation
  - submit orchestration and provider invalidation
- `front/lib/presentation/pages/review_write/`
  - page-local widgets and painters that are only used by the review-write route
  - render helpers for media tiles, option lists, and similar UI-only pieces

### Why this split

- Route pages should remain aligned to route boundaries, not become long-lived state containers.
- Riverpod controller state is easier to reason about than page-owned mutable state spread across extension files.
- UI sections should not know upload recovery details.
- Media rules should not be mixed into brand/menu loading.
- Submit and retry logic should be review-flow logic, not view-tree logic.
- Edit-mode hydration should be testable without rendering every section.

## Completion Criteria

- `review_write_page.dart` acts as a route shell rather than the main owner of business state.
- Review-write business state lives in a dedicated Riverpod controller/state object.
- Media logic has a clear boundary for:
  - existing media
  - newly selected media
  - count limit
  - duration limit
  - removal
- Submit logic has a clear boundary for:
  - payload construction
  - upload
  - create/update branch
  - recoverable auth/session retry
- Page-local widgets live in page-local files rather than extension-based logic splits.
- The create, edit, failure, and retry paths are documented and verifiable.
- `flutter analyze` passes after the refactor.

## User Story Files

- `review-write-stabilization-us01-page-boundary-and-section-split.md`
- `review-write-stabilization-us02-bootstrap-and-edit-mode-state.md`
- `review-write-stabilization-us03-media-selection-and-policy-guardrails.md`
- `review-write-stabilization-us04-submit-orchestration-and-recovery.md`
- `review-write-stabilization-us05-flow-verification-and-regression-checks.md`
