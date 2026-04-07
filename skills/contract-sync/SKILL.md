---
name: contract-sync
description: Keep frontend and backend interfaces aligned in this repository. Use when Codex changes API payloads, schema fields, rating dimensions, entity names, repository contracts, request/response shapes, or any feature that must stay consistent across `front/` and `back/`.
---

# Contract Sync

Use this skill when a change can silently break frontend/backend compatibility.

## Checkpoints

- request parameters
- response fields
- enum-like values and labels
- rating dimension keys and ordering
- nullability and default values
- naming mismatches between Dart and Python layers

## Workflow

1. Find the backend source of truth for the contract.
2. Find the matching frontend entity, repository, API adapter, and UI surface.
3. Edit both sides in the same task when compatibility would otherwise break.
4. Search for duplicated constants before finishing.
5. Verify both sides with the smallest meaningful commands.

## Cafemap Notes

- Rating dimensions are duplicated and must remain aligned:
  - `front/lib/core/constants/rating_dimensions.dart`
  - `back/cafemap/core/rating_dimensions.py`
- Review, ranking, and store detail flows are likely to surface contract drift quickly.
