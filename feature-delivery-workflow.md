# Feature Delivery Workflow

## Purpose

This document defines how feature planning artifacts are created and maintained in this repository.

Use this workflow whenever a new feature is proposed, refined, or implemented.

## Folder Structure

- `backlog/`
  - feature-level briefs only
- `user-stories/`
  - one folder per feature brief
  - the folder name must match the feature brief file name without the `.md` extension

## Required Flow

1. Create or update a feature brief in `backlog/`.
2. Create a matching folder in `user-stories/`.
3. Write the implementation slices as user-story `.md` files inside that folder.
4. Keep the feature brief and user stories aligned as scope changes.

## Feature Brief Rules

Each feature brief in `backlog/` should describe:

- problem
- goal
- in-scope items
- out-of-scope items
- data or architecture assumptions
- completion criteria
- the list of user-story files expected under `user-stories/<feature-name>/`

## User Story Rules

Each user-story file must be small enough to implement and verify independently.

Each user-story file must include:

- title with a stable `US-xx` identifier
- user story
- scope
- frontend tasks
- backend tasks
- designer tasks
- contract or dependency notes when relevant
- acceptance criteria
- verification notes

## Role Expectations

### Frontend

- route and screen impact
- state/provider impact
- repository or API adapter impact
- UI states: loading, error, empty, success

### Backend

- API or service changes
- data and schema impact
- ranking/filter/business logic changes
- validation and fallback rules

### Designer

- entry points
- layout and hierarchy
- copy and labels
- state and interaction expectations

## Naming Convention

- feature brief example:
  - `backlog/recommendation-home-feature.md`
- matching user-story folder:
  - `user-stories/recommendation-home-feature/`
- user-story file examples:
  - `recommendation-home-us01-purpose-catalog.md`
  - `recommendation-home-us02-home-section.md`

## Maintenance Rules

- Do not mix feature briefs and user stories in the same folder.
- Do not scatter one feature's user stories across multiple folders.
- If a feature is renamed, rename both the backlog file and the matching `user-stories/` folder.
- When implementation scope changes, update the feature brief first, then the affected user stories.

## Implementation Handoff

Before implementation starts, the relevant feature brief and user stories should be sufficient for:

- frontend implementation
- backend implementation
- design review
- verification planning

If the work is not clear enough for those four activities, the documents are not finished.
