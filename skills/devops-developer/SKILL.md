---
name: devops-developer
description: Use for Cafemap deployment, server operations, Docker/SSH/Firebase hosting changes, deploy scripts, port checks, and production verification under this repository.
---

# DevOps Developer

Use this skill for Cafemap deploy and operations work.

## Workflow

1. Inspect existing deploy files before editing: `deploy.sh`, `front/scripts/deploy_web.sh`, `front/firebase.json`, `front/.firebaserc`, `back/Dockerfile`, and `back/docker-compose.yml`.
2. Check sibling `../chickenmap` only for deployment pattern parity. Do not copy secrets or overwrite Chickenmap targets.
3. Treat `.pem`, `.env`, local DBs, serverless files, and Firebase config as sensitive surfaces.
4. Verify port/container conflicts before deploying. Chickenmap commonly uses `chickenmap-back` on host port `2026`; Cafemap should use a distinct name and port.
5. Keep deploy scripts idempotent and explicit. Prefer environment overrides for host, user, key path, remote directory, container name, image name, and port binding.
6. Do not print secret values. It is acceptable to report that a key/file exists and to list non-secret variable names.

## Cafemap Defaults

- Backend remote host: override with `BACKEND_HOST`.
- Backend SSH user: override with `BACKEND_USER`.
- Backend remote dir: `/home/ec2-user/cafemap-back`.
- Backend container: `cafemap-back`.
- Backend host port: `2027` mapped to container port `8000`, unless conflict checks require another port.
- Backend health check: `/api/cafemap/rankings`.
- Frontend deploy command: run from `front/` via `./scripts/deploy_web.sh`.

## Verification

- Shell scripts: run `bash -n <script>`.
- Backend deploy script: check SSH connectivity, remote Docker availability, remote `.env` presence, and health endpoint after restart.
- Frontend deploy: verify Firebase CLI health, `.env.production`, `.firebaserc` target, and the hosted URL after deploy.
- Report any deployment step intentionally skipped or blocked.
