# Backend Memory

## Scope

Use this file for FastAPI routes, services, repositories, schemas, DB behavior, and local data tooling under `back/`.

## Current Notes

- Backend currently mixes application code with scripts and data files.
- Avoid broad cleanup unless explicitly requested.
- SQLite is used locally in `back/data/`.

## Rules

- Keep route/service/repository responsibilities clear.
- Favor narrow validation for touched modules.
- Avoid accidental changes to local DBs, `.env`, and deployment-related artifacts.
