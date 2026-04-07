# Cafemap Backend Work

Goal: bring the backend to 100% of `cafemap기획.md` for a local-cafe-first product while preserving franchise menu rankings.

## B1. Store Type Contract

- Add explicit `store_type` to `Store`: `local`, `franchise`, or `unknown`.
- Backfill existing seed stores from brand context.
- Keep `isLocal` for frontend compatibility, but derive it from `store_type`.
- Expose `storeType` on store list, store detail, and store ranking responses.
- Acceptance: `/api/cafemap/stores` and `/api/cafemap/store-rankings` return both `storeType` and `isLocal`.

## B2. Store Experience Scoring

- Split review score handling into menu scores and store experience scores.
- Add store experience dimensions: `atmosphere`, `work_friendly`, `quietness`, `seat_comfort`, `outlet_access`, `service`.
- Store reviews should persist combined score data, but brand-menu aggregates should use menu scores only.
- Store aggregates should use menu scores plus store experience scores.
- Acceptance: a review can include `storeScores`, and store aggregates expose cafe-experience strengths.

## B3. Store Summary Signals

- Add experience signals to store summary and ranking responses:
  - `workFriendlyScore`
  - `quietnessScore`
  - `dessertScore`
  - `topLabelA/topScoreA`
  - `topLabelB/topScoreB`
- Acceptance: map and ranking screens can filter/sort without duplicating backend scoring rules.

## B4. Local Place Deduplication

- When creating a review from a map/search result, reuse an existing store if normalized name and address match.
- Keep brand-scoped matching as the first path, then fallback to name/address matching.
- Acceptance: repeated local cafe reviews do not create duplicate stores for the same place/address.

## B5. Verification

- Run backend compile/import validation.
- Run a TestClient smoke check for:
  - `/api/cafemap/stores`
  - `/api/cafemap/store-rankings`
  - `/api/cafemap/rankings`
- Confirm local/franchise store typing and experience score fields are present.
