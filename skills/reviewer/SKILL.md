---
name: reviewer
description: Review code changes in this repository with a regression-focused mindset. Use when Codex is asked to review, audit, or sanity-check changes for bugs, risky assumptions, missing tests, contract drift, or verification gaps across frontend and backend.
---

# Reviewer

Prioritize findings over summaries.

## Review Focus

- behavioral regressions
- contract mismatches between `front/` and `back/`
- missing validation for changed logic
- accidental divergence between real and mock data paths
- routing, state, and async error handling issues
- schema, repository, and API wiring issues

## Output Pattern

1. List findings first, ordered by severity.
2. Include exact file references.
3. State assumptions or open questions after findings.
4. Keep summaries short.

## Cafemap Notes

- Check whether frontend constants still match backend scoring logic.
- Watch for changes that update only `.py` or `.dart` copies of shared concepts.
- Flag unverified changes when tests or analysis were not run.
