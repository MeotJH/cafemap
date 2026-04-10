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
- Preserve the `app` / `presentation` / `domain` / `data` layer split and do not bypass domain repository interfaces without a clear reason.
- Prefer a layered architecture where `presentation` depends on `domain`, and `data` implements `domain` contracts.
- Treat Riverpod providers and controller-like state objects as the view-model boundary; pages and widgets should focus on rendering, input wiring, and simple view state.
- Do not let a single page own too many responsibilities such as async loading, submit orchestration, error recovery, parsing helpers, and large widget trees at the same time.
- Extract complex page logic into smaller providers, controllers, helper classes, or presentation widgets when a screen becomes hard to scan.
- Favor maintainable object-oriented structure with clear class responsibilities over large procedural UI files.
- Keep design patterns practical and explicit: repository for data access, provider/notifier for state, small reusable widgets for repeated UI, and helper utilities only for pure logic.
- Aim for roughly 300 to 400 lines per Dart file when possible, but do not split mechanically if the file is still cohesive and easy to scan.
- If a page or widget file grows past roughly 400 lines, first check whether it is mixing multiple responsibilities before deciding how to split it.
- Prefer splitting by responsibility boundaries such as page composition, view-model state, async workflow, pure helpers, and reusable widgets rather than splitting only by file length.
- Keep page files centered on screen composition, user interaction wiring, and simple local UI state.
- Treat async orchestration, parsing, upload flows, recovery logic, and reusable transformation logic as extraction candidates before adding more code to a large page.
- Optimize for human maintainability: a reader should be able to understand a file's main responsibility without scrolling through several unrelated concerns.
- Every new or modified public class, major private class, and non-trivial function should have a short Korean comment immediately above it explaining its role.
- Avoid comment noise on trivial one-line getters or obvious assignments, but add Korean comments where a human reader would otherwise need to infer intent.
