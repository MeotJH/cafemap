# Contracts Memory

## Scope

Use this file when frontend/backend payloads, duplicated constants, or domain contracts change.

## Current Contract Notes

- Rating dimensions are duplicated across frontend and backend:
  - `front/lib/core/constants/rating_dimensions.dart`
  - `back/cafemap/core/rating_dimensions.py`

## Rules

- When shared concepts change, verify both sides.
- Prefer one explicit contract update over silent divergence.
