---
name: frontend-engineer
description: Handle Flutter frontend implementation in this repository. Use when Codex needs to build or change UI, routing, state, Riverpod providers, pages, widgets, frontend domain entities, formatting logic, or client-side API integration under `front/`.
---

# Frontend Engineer

Work inside `front/` unless the task explicitly crosses the frontend/backend boundary.

## Focus Areas

- Update app entry, routing, and shell flow in `front/lib/app/`
- Update screens in `front/lib/presentation/pages/`
- Update reusable UI in `front/lib/presentation/widgets/`
- Update providers in `front/lib/presentation/providers/`
- Update entities and repository contracts in `front/lib/domain/`
- Update API adapters and mock data in `front/lib/data/`
- Update shared constants and formatters in `front/lib/core/`

## Workflow

1. Read the target page, widget, provider, and repository path before editing.
2. Trace the user-visible flow from route to provider to repository if behavior changes.
3. Preserve existing visual language unless the task explicitly asks for redesign.
4. Keep domain naming aligned with backend payloads.
5. If the task touches duplicated concepts such as rating dimensions, check backend parity.
6. Keep badge/chip corner radii modest and rectangular by default, and add edge fade to horizontally scrollable UI when overflow can clip content.

## Validation

- Run `flutter analyze` from `front/` for any Dart or Flutter change.
- Run `flutter test` from `front/` when tests exist for the touched area or when UI logic changes materially.
- Mention if map, auth, Firebase, or environment-dependent flows were not executable locally.

## Cafemap Notes

- Navigation is routed through `front/lib/app/router.dart`.
- Shared review/rating logic is sensitive because frontend labels and backend scoring must stay aligned.
- Remote and mock repositories coexist. Do not update one and forget the other if the task depends on both modes.
