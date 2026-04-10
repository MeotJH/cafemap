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
- Preserve the `api` / `services` / `repositories` / `models` / `schemas` / `db` split under `back/cafemap` and do not bypass those boundaries without a clear reason.
- Prefer a layered backend where `api` handles HTTP concerns, `services` handle business rules and orchestration, `repositories` handle persistence and external data access, and `schemas` define request and response contracts.
- Keep route handlers thin: parsing, auth entry, dependency wiring, and response mapping are acceptable there, but domain decisions and persistence logic should move downward.
- Do not let routers accumulate large blocks of derived-field mapping, snapshot parsing, or repeated response assembly when those can be extracted into service or mapper helpers.
- Keep service modules focused on business workflows; if a service grows to include validation, matching logic, aggregate updates, geocoding, sanitization, and persistence details all at once, split by responsibility.
- Favor maintainable object-oriented structure and explicit responsibilities over large procedural modules.
- Keep design patterns practical and explicit: repository for data access, service for business workflows, schema for API contracts, and small helper functions or classes for pure transformation logic.
- Aim for roughly 300 to 400 lines per Python module when possible, but do not split mechanically if the module is still cohesive and easy to scan.
- If a router or service file grows past roughly 400 lines, first check whether it is mixing multiple responsibilities before deciding how to split it.
- Prefer splitting by responsibility boundaries such as route layer, orchestration flow, domain validation, persistence access, external API integration, and pure helper logic rather than splitting only by file length.
- Keep direct SQLAlchemy session usage concentrated in repositories when practical. If a service must touch the session directly for a transaction boundary or aggregate update, keep that scope explicit and small.
- Avoid mixing application modules with one-off scripts, generated artifacts, local databases, backups, and deployment tooling in the same mental path; treat `back/cafemap/` as the application boundary and keep cleanup changes narrow.
- Optimize for human maintainability: a reader should be able to understand a module's main responsibility without scrolling through several unrelated concerns.
- Every new or modified public class, major private class, and non-trivial function should have a short Korean comment immediately above it explaining its role.
- Avoid comment noise on trivial one-line accessors or obvious assignments, but add Korean comments where a human reader would otherwise need to infer why code exists.
