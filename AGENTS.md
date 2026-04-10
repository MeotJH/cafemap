# CAFEMAP AGENTS

## Purpose

This repository uses Codex as the primary coding harness.

Treat this file as the lightweight entrypoint only.
Read additional guidance from `memory/` based on the task instead of loading one long monolithic prompt.

## Read Order

1. Read this file first.
2. Read [`memory/index.md`](/c:/Users/kimjh0417/work_space/cafemap/memory/index.md).
3. Open only the memory files that match the task.

## Base Rules

- Prefer small, reversible changes.
- When changing shared domain concepts, check both frontend and backend copies.
- Treat UTF-8 as the default encoding for source files, config, and user-facing text.
- When editing files that include Korean text, check for encoding corruption before and after changes.
- Do not overwrite visibly garbled text blindly; verify file encoding first and preserve or restore UTF-8 text safely.
- Use the repo commit prefix convention:
  `feat(scope): ...`, `fix(scope): ...`, `refactor(scope): ...`, `chore(scope): ...`, `docs(scope): ...`, `style(scope): ...`, `test(scope): ...`.

## Memory Routing

- Read [`memory/workflow.md`](/c:/Users/kimjh0417/work_space/cafemap/memory/workflow.md) for execution steps and editing discipline.
- Read [`memory/verification.md`](/c:/Users/kimjh0417/work_space/cafemap/memory/verification.md) when behavior changes or verification is needed.
- Read [`memory/repo-map.md`](/c:/Users/kimjh0417/work_space/cafemap/memory/repo-map.md) when you need repository shape or sensitive-surface context.
- Frontend/UI/state/widget work:
  read [`memory/frontend.md`](/c:/Users/kimjh0417/work_space/cafemap/memory/frontend.md)
- Backend/API/service/repository work:
  read [`memory/backend.md`](/c:/Users/kimjh0417/work_space/cafemap/memory/backend.md)
- Deployment/server/hosting work:
  read [`memory/deployment.md`](/c:/Users/kimjh0417/work_space/cafemap/memory/deployment.md)
- Shared frontend/backend contract work:
  read [`memory/contracts.md`](/c:/Users/kimjh0417/work_space/cafemap/memory/contracts.md)

## Skills

Repo-local skills currently live under `skills/`.

Use these when the task clearly matches:

- `frontend-engineer`
- `backend-engineer`
- `product-planner`
- `contract-sync`
- `reviewer`
- `ui-ux-designer`
- `devops-developer`
