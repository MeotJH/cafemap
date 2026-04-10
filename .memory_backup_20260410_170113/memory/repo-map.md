# Repo Map

## Top Level

- `front/`: Flutter client application
- `back/`: FastAPI-style Python backend and local data tooling
- `stitch/`: supporting workspace area
- `skills/`: repo-local task skills
- `memory/`: task-routed harness memory

## Shared Domain Notes

- Rating dimension logic exists in both frontend and backend:
  - `front/lib/core/constants/rating_dimensions.dart`
  - `back/cafemap/core/rating_dimensions.py`

## Sensitive Surfaces

- `.env` files
- local databases
- deployment config
- serverless artifacts
- `.pem` keys
