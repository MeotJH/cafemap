# Deployment Memory

## Scope

Use this file for Lightsail, Docker, SSH, Firebase Hosting, and production environment work.

## Current Deployment Shape

- Frontend hosting: Firebase Hosting
- Backend hosting: Lightsail
- Backend public URL: `https://cafemap.13.124.77.254.nip.io`
- Frontend public URL: `https://cafemap.web.app`

## Rules

- Treat `.pem`, `.env`, remote DBs, and deployment configs as sensitive.
- Verify target host, port, and public URL before editing deploy scripts.
- Prefer explicit, reversible deployment script changes.
