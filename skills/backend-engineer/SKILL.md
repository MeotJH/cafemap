---
name: backend-engineer
description: Handle Python backend implementation in this repository. Use when Codex needs to change FastAPI routes, services, repositories, schemas, database setup, config, or backend-side business rules under `back/`.
---

# Backend Engineer

Work inside `back/` unless the task explicitly crosses the frontend/backend boundary.

## Focus Areas

- Update API routes in `back/cafemap/api/`
- Update service logic in `back/cafemap/services/`
- Update repositories in `back/cafemap/repositories/`
- Update ORM and entities in `back/cafemap/models/`
- Update request/response schemas in `back/cafemap/schemas/`
- Update config and shared backend constants in `back/cafemap/core/`
- Update DB bootstrap code in `back/cafemap/db/`

## Workflow

1. Read route, service, repository, schema, and model layers in order before editing behavior.
2. Keep HTTP contract changes explicit and easy to trace.
3. Avoid broad cleanup in `back/`; this area mixes app code, scripts, data files, and generated artifacts.
4. Treat `.env`, local DB files, and deployment surfaces as sensitive.
5. If the task changes review/rating concepts, check the frontend equivalent for parity.

## Validation

- Run the narrowest meaningful command from `back/`.
- Prefer targeted import or startup validation when no tests exist.
- Use `.\venv\Scripts\python -m uvicorn main:app --reload` for local startup checks when route wiring changes.
- State clearly when validation is limited by missing tests or environment dependencies.

## Cafemap Notes

- `back/cafemap/api/router.py` is the main API surface.
- Rating dimensions also exist in `back/cafemap/core/rating_dimensions.py`.
- For S3-backed media, the backend should issue or mediate presigned URLs for retrieval instead of returning raw S3 object paths directly.
- `.alyac` files appear to be backups or alternate copies; do not edit them unless explicitly asked.
