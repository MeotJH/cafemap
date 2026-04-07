# Cafemap Deployment Backlog

Status: backlog

Goal: prepare a Cafemap deployment flow by referencing the sibling `chickenmap` project, without performing deployment until explicitly requested.

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

- [ ] Add `skills/devops-developer/SKILL.md`.
- [ ] Include guidance for SSH key handling, service/port checks, deployment scripts, backend health checks, and frontend hosting verification.
- [ ] Keep the skill concise and repo-specific.
- [ ] Acceptance: the skill can be triggered for Cafemap deployment, service, CI/CD, and server operations tasks.

### D2. Chickenmap Reference Audit

- [ ] Inspect `../chickenmap` deployment files and service scripts.
- [ ] Identify backend runtime, port, process manager or container strategy, environment file handling, and health check route.
- [ ] Identify frontend build and hosting strategy.
- [ ] Identify `.pem` path and required SSH user/host without exposing file contents.
- [ ] Acceptance: write down the relevant Chickenmap patterns before changing Cafemap deployment files.

### D3. Cafemap Backend Deployment Plan

- [ ] Compare Cafemap `back/` runtime with Chickenmap backend runtime.
- [ ] Select a non-conflicting backend host port.
- [ ] Define service/container name, remote directory, env-file location, and data volume behavior.
- [ ] Add or update a backend deploy script only after confirming the existing `deploy.sh` behavior.
- [ ] Add a narrow health check, for example `/api/cafemap/rankings` or a better backend health endpoint if available.
- [ ] Acceptance: backend deployment can be run via a documented `.sh` command and verified with a local or remote health check.

### D4. Cafemap Frontend Deployment Plan

- [ ] Compare Cafemap `front/` Flutter web deploy flow with Chickenmap frontend deploy flow.
- [ ] Reuse `front/scripts/deploy_web.sh` if it already matches the target hosting strategy.
- [ ] If needed, add a top-level wrapper script that builds and deploys the frontend consistently.
- [ ] Acceptance: frontend deployment can be run via a documented `.sh` command and has a post-deploy URL/check.

### D5. Integrated Deploy Script

- [ ] Decide whether to keep one top-level `deploy.sh` or split scripts by `scripts/deploy_backend.sh` and `scripts/deploy_frontend.sh`.
- [ ] Support flags such as `--front`, `--back`, and `--all`.
- [ ] Support environment overrides for host, user, key path, remote directory, container/service name, and port binding.
- [ ] Add guardrails for missing SSH key, missing env file, failed remote build, and failed health check.
- [ ] Acceptance: script fails fast with clear messages and does not leak secrets.

### D6. Verification

- [ ] Run shell syntax validation on touched `.sh` files.
- [ ] Run the narrowest backend validation available before deployment.
- [ ] Run `fvm flutter analyze` or a narrower frontend validation for touched Flutter deployment files.
- [ ] For actual deployment, verify backend health URL and frontend hosted URL after the user approves execution.
- [ ] Acceptance: report what was changed, what was verified, and any deployment steps intentionally left unrun.

## Open Questions

- Which exact host and SSH user should Cafemap use if Chickenmap has multiple deployment targets?
- Which backend port should be reserved for Cafemap after checking Chickenmap's active port?
- Should Cafemap use the existing root `deploy.sh`, or should deployment be split into separate scripts?
- Should frontend hosting remain Firebase Hosting, or should it mirror Chickenmap if Chickenmap uses a different host?
