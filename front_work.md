# Cafemap Frontend Work

Goal: bring the frontend to 100% of `cafemap기획.md` for a local-cafe-first product while preserving franchise menu rankings.

Status: completed in this loop.

## F1. Ranking Structure

- [x] Make store ranking the default ranking experience.
- [x] Restore menu/franchise ranking as an explicit secondary tab or section.
- [x] Keep local-first recommendation ordering for the default store ranking tab.
- [x] Acceptance: users can switch between `카페 랭킹` and `메뉴 랭킹`.

## F2. Local-First Review Writing

- [x] Reduce brand-selection burden for local cafes.
- [x] Allow free-form menu names when a map-selected cafe is local or unknown.
- [x] Add store experience sliders matching backend keys:
  - `atmosphere`
  - `work_friendly`
  - `quietness`
  - `seat_comfort`
  - `outlet_access`
  - `service`
- [x] Submit menu scores and store experience scores separately.
- [x] Acceptance: local cafe reviews can be submitted without forcing a franchise-menu match.

## F3. Map Discovery Filters

- [x] Keep current `전체`, `로컬`, `프랜차이즈`, and `리뷰 많은 순` filters.
- [x] Add cafe-domain filters/sorts:
  - `작업하기 좋은`
  - `조용한`
  - `디저트 좋은`
- [x] Use backend-provided store summary signals instead of hardcoding UI-only assumptions.
- [x] Acceptance: map list can prioritize local cafes by work suitability, quietness, or dessert signal.

## F4. Store Detail Experience

- [x] Show local/franchise store type.
- [x] Show representative strengths.
- [x] Show work-friendly, quietness, and dessert summary scores when available.
- [x] Keep review list and menu context visible.
- [x] Acceptance: store detail explains why a cafe ranks well beyond a single average rating.

## F5. Verification

- [x] Run `dart format` on touched Dart files.
- [x] Run `flutter build web --debug --no-pub`.
- [x] Run `flutter analyze` and record any pre-existing lint failures separately from new errors.
