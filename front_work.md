# Cafemap Frontend Work

Goal: bring the frontend to 100% of `cafemap기획.md` for a local-cafe-first product while preserving franchise menu rankings.

## F1. Ranking Structure

- Make store ranking the default ranking experience.
- Restore menu/franchise ranking as an explicit secondary tab or section.
- Keep local-first recommendation ordering for the default store ranking tab.
- Acceptance: users can switch between `카페 랭킹` and `메뉴 랭킹`.

## F2. Local-First Review Writing

- Reduce brand-selection burden for local cafes.
- Allow free-form menu names when a map-selected cafe is local or unknown.
- Add store experience sliders matching backend keys:
  - `atmosphere`
  - `work_friendly`
  - `quietness`
  - `seat_comfort`
  - `outlet_access`
  - `service`
- Submit menu scores and store experience scores separately.
- Acceptance: local cafe reviews can be submitted without forcing a franchise-menu match.

## F3. Map Discovery Filters

- Keep current `전체`, `로컬`, `프랜차이즈`, and `리뷰 많은 순` filters.
- Add cafe-domain filters/sorts:
  - `작업하기 좋은`
  - `조용한`
  - `디저트 좋은`
- Use backend-provided store summary signals instead of hardcoding UI-only assumptions.
- Acceptance: map list can prioritize local cafes by work suitability, quietness, or dessert signal.

## F4. Store Detail Experience

- Show local/franchise store type.
- Show representative strengths.
- Show work-friendly, quietness, and dessert summary scores when available.
- Keep review list and menu context visible.
- Acceptance: store detail explains why a cafe ranks well beyond a single average rating.

## F5. Verification

- Run `dart format` on touched Dart files.
- Run `flutter build web --debug --no-pub`.
- Run `flutter analyze` and record any pre-existing lint failures separately from new errors.
