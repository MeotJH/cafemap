# Frontend Memory

## Scope

Use this file for Flutter UI, state, routing, provider, widget, and web-client integration work.

## Current Notes

- Flutter web is hosted via Firebase Hosting.
- Production API base URL is managed through frontend env files.
- `review_write_page.dart` is currently oversized and mixes view and domain logic; planned refactoring exists in [`해야할일.md`](/c:/Users/kimjh0417/work_space/cafemap/해야할일.md).

## Rules

- Keep UI logic and domain logic separated when possible.
- When editing Korean copy, verify encoding before and after changes.
- Prefer small validations over broad frontend churn.
