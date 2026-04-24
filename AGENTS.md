# CAFEMAP AGENTS

## Purpose

This repository uses Codex as the primary coding harness.
Apply ECC-style harness engineering here by keeping instructions stable, task execution explicit, and verification mandatory.

## Repository Map

- `front/`: Flutter client application
- `back/`: FastAPI-style Python backend and local data tooling
- `stitch/`: supporting workspace area

## Working Rules

- Prefer small, reversible changes.
- Understand the affected flow before editing.
- When changing shared domain concepts, check both frontend and backend copies.
- Do not rewrite unrelated files or generated artifacts unless the task requires it.
- If a task changes behavior, include the smallest relevant verification step before finishing.
- Treat UTF-8 as the default encoding for source files, config, and user-facing text.
- When editing files that include Korean text, check for encoding corruption before and after changes.
- Do not overwrite visibly garbled text blindly; verify file encoding first and preserve or restore UTF-8 text safely.
- Follow commit message prefixes: `feat(scope): ...`, `fix(scope): ...`, `refactor(scope): ...`, `chore(scope): ...`, `docs(scope): ...`, `style(scope): ...`, `test(scope): ...`.

## Project-Specific Notes

- Rating dimension logic exists in both frontend and backend:
  - `front/lib/core/constants/rating_dimensions.dart`
  - `back/cafemap/core/rating_dimensions.py`
- Backend currently mixes application code with local scripts and data files. Avoid broad cleanup unless requested.
- Production backend deploys to AWS Lightsail over SSH and Docker, not serverless.
- The Lightsail SSH key in this workspace is `LightsailDefaultKey-ap-northeast-2.pem`; treat `.pem` files, `.env` files, local databases, deployment config, and serverless artifacts as sensitive surfaces.

## Commands

### Frontend

- Install deps: `flutter pub get`
- Static analysis: `flutter analyze`
- Tests: `flutter test`
- Web run: `flutter run -d chrome`
- Web deploy flow: `./scripts/deploy_web.sh`
- Combined production deploy entrypoint: `../deploy.sh --front`

Run frontend commands from `front/`.

### Backend

- Install deps: `.\venv\Scripts\python -m pip install -r requirements.txt`
- Run API locally: `.\venv\Scripts\python -m uvicorn main:app --reload`
- Ad hoc script run: `.\venv\Scripts\python <script>.py`
- Production deploy target: AWS Lightsail
- Production deploy flow from repo root: `./deploy.sh --back`
- Full stack deploy flow from repo root: `./deploy.sh --all`

Run backend commands from `back/`.

## Verification Policy

- Flutter UI or Dart changes: run at least `flutter analyze` in `front/`.
- Backend Python changes: run the narrowest executable validation available for the touched path.
- Cross-cutting domain changes: verify both sides if the concept is duplicated across `front/` and `back/`.
- If a change touches Korean strings, API payload text, logs, or localized UI copy, include a quick encoding sanity check in the relevant file or response path.

## Task Execution Pattern

1. Read the relevant files first.
2. State the intended change briefly.
3. Edit only the necessary files.
4. Run the smallest meaningful verification.
5. Report what changed, what was verified, and any remaining risk.

## Harness Direction

Use this file as the stable base prompt for Codex in this repo.
If ECC components are added later, keep this file as the local source of truth and import only the parts that clearly improve workflow:

- planning/review agents
- verification loops
- security scanning
- reusable project skills

## Local Skills

Use these repo-local skills when the task clearly matches the role:

- `frontend-engineer`: Flutter UI, state, routing, widgets, and client API integration
- `backend-engineer`: FastAPI routes, services, repositories, schema, and DB-side behavior
- `product-planner`: feature framing, scope definition, acceptance criteria, and execution sequencing
- `contract-sync`: frontend/backend contract changes that must stay aligned
- `reviewer`: change review focused on regressions, missing validation, and risky assumptions
- `ui-ux-designer`: modern mobile UI/UX hierarchy, spacing, copy, and visual simplification

Skill folders live under `skills/`.
