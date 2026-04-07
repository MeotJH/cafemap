# Cafemap Deployment Backlog

Status: completed on 2026-04-07

Goal: prepare and run a Cafemap deployment flow by referencing the sibling `chickenmap` project, after explicit deployment approval.

## Deployment Result

- Firebase project: `painting-diary-fd8b3`
- Firebase Hosting site: `cafemap`
- Frontend URL: `https://cafemap.web.app/`
- Backend URL: `https://cafemap.3.36.208.227.nip.io`
- Backend container: `cafemap-back`
- Backend port mapping: host `2027` -> container `8000`
- Chickenmap port retained: host `2026` -> container `8000`
- SSH key path used: `../chickenmap/LightsailDefaultKey-ap-northeast-2.pem`

## Scope

- Create a repo-local `devops-developer` skill under `skills/`.
- Inspect the sibling project at `../chickenmap` for comparable backend, frontend, deployment script, service, and hosting patterns.
- Reference the `.pem` location used by `../chickenmap` only as a deployment credential path; do not print, copy, or commit key contents.
- Configure Cafemap backend to run similarly to Chickenmap, but on a separate non-conflicting port.
- Configure Cafemap frontend deployment similarly as one deployable project.
- Create or update `.sh` deployment scripts for the backend, frontend, or an integrated deployment flow.

## Safety Constraints

- Do not run remote deployment commands until explicitly approved.
- Do not expose `.pem`, `.env`, local database, serverless, or deployment secret contents.
- Do not commit generated build artifacts or secret-bearing files.
- Prefer small, reversible changes and document any assumed ports, hosts, or service names.
- Check existing `deploy.sh` before adding new scripts to avoid duplicate deployment entrypoints.

## Backlog Items

### D1. DevOps Skill

- [x] Add `skills/devops-developer/SKILL.md`.
- [x] Include guidance for SSH key handling, service/port checks, deployment scripts, backend health checks, and frontend hosting verification.
- [x] Keep the skill concise and repo-specific.
- [x] Acceptance: the skill can be triggered for Cafemap deployment, service, CI/CD, and server operations tasks.

### D2. Chickenmap Reference Audit

- [x] Inspect `../chickenmap` deployment files and service scripts.
- [x] Identify backend runtime, port, process manager or container strategy, environment file handling, and health check route.
- [x] Identify frontend build and hosting strategy.
- [x] Identify `.pem` path and required SSH user/host without exposing file contents.
- [x] Acceptance: write down the relevant Chickenmap patterns before changing Cafemap deployment files.

### D3. Cafemap Backend Deployment Plan

- [x] Compare Cafemap `back/` runtime with Chickenmap backend runtime.
- [x] Select a non-conflicting backend host port.
- [x] Define service/container name, remote directory, env-file location, and data volume behavior.
- [x] Add or update a backend deploy script only after confirming the existing `deploy.sh` behavior.
- [x] Add a narrow health check, for example `/api/cafemap/rankings` or a better backend health endpoint if available.
- [x] Acceptance: backend deployment can be run via a documented `.sh` command and verified with a local or remote health check.

### D4. Cafemap Frontend Deployment Plan

- [x] Compare Cafemap `front/` Flutter web deploy flow with Chickenmap frontend deploy flow.
- [x] Reuse `front/scripts/deploy_web.sh` if it already matches the target hosting strategy.
- [x] If needed, add a top-level wrapper script that builds and deploys the frontend consistently.
- [x] Acceptance: frontend deployment can be run via a documented `.sh` command and has a post-deploy URL/check.

### D5. Integrated Deploy Script

- [x] Decide whether to keep one top-level `deploy.sh` or split scripts by `scripts/deploy_backend.sh` and `scripts/deploy_frontend.sh`.
- [x] Support flags such as `--front`, `--back`, and `--all`.
- [x] Support environment overrides for host, user, key path, remote directory, container/service name, and port binding.
- [x] Add guardrails for missing SSH key, missing env file, failed remote build, and failed health check.
- [x] Acceptance: script fails fast with clear messages and does not leak secrets.

### D6. Verification

- [x] Run shell syntax validation on touched `.sh` files.
- [x] Run the narrowest backend validation available before deployment.
- [x] Run `fvm flutter analyze` or a narrower frontend validation for touched Flutter deployment files.
- [x] For actual deployment, verify backend health URL and frontend hosted URL after the user approves execution.
- [x] Acceptance: report what was changed, what was verified, and any deployment steps intentionally left unrun.

## Open Questions

- Resolved: Cafemap uses host `3.36.208.227` and SSH user `ec2-user`, matching the active Chickenmap deployment target.
- Resolved: Cafemap reserves host port `2027`, while Chickenmap keeps host port `2026`.
- Resolved: Cafemap keeps the existing root `deploy.sh` with `--front`, `--back`, and `--all`.
- Resolved: Frontend hosting remains Firebase Hosting, using site `cafemap` under project `painting-diary-fd8b3`.
