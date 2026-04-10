# Workflow

## Default Execution Pattern

1. Read the relevant files first.
2. Load only the task-specific memory files needed for the current work.
3. If the user assigns a feature or substantial change, create a planning note in `backlog/` named for the feature before implementation.
4. Break the requested feature into the smallest meaningful implementation slices and record those tasks in the backlog note.
5. State the intended change briefly.
6. Edit only the necessary files.
7. Run the smallest meaningful verification from `memory/verification.md` when behavior or risk warrants it.
8. Report what changed, what was verified, and any remaining risk.

## Working Rules

- Understand the affected flow before editing.
- Do not rewrite unrelated files unless the task requires it.
- Preserve UTF-8 and check Korean text for encoding corruption before and after edits.
- Route task-specific decisions to `frontend.md`, `backend.md`, `deployment.md`, or `contracts.md` instead of duplicating those rules here.
- For feature requests, create or update a `backlog/<feature-name>.md` note that captures the feature goal, small work slices, and actionable TODOs before or alongside implementation.
