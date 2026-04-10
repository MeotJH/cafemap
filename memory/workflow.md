# Workflow

## Default Execution Pattern

1. Read the relevant files first.
2. State the intended change briefly.
3. Edit only the necessary files.
4. Run the smallest meaningful verification.
5. Report what changed, what was verified, and any remaining risk.

## Working Rules

- Prefer small, reversible changes.
- Understand the affected flow before editing.
- Do not rewrite unrelated files unless the task requires it.
- If behavior changes, verify it before finishing.
- Preserve UTF-8 and check Korean text for encoding corruption before and after edits.
