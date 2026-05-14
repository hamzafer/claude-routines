---
name: deploy
description: Deploy a Claude Code routine from a local .md file. Routes to create or update based on whether the file's frontmatter has a trigger_id. Invoke when the user says "deploy <file>", "push <file>", "ship <file>", or asks to publish a routine to the cloud.
---

# claude-routines:deploy

Smart router. Reads the file, decides if it needs `create` or `update`, then delegates.

## Procedure

1. Read the routine file at `<file>`.
2. Parse its YAML frontmatter.
3. If `trigger_id` is present in frontmatter -> use the `update` skill with `<file>`.
4. If `trigger_id` is absent -> use the `create` skill with `<file>`.

That's it. Both create and update handle their own snippet expansion, validation, API calls, and result reporting.

## Pre-deploy nudges

If the user hasn't validated the file recently, suggest:

- `validate <file>` to lint frontmatter and cron rules
- `dry-run deploy <file>` to see the exact API body
- `diff <file>` to preview field-by-field changes (UPDATE path only)

Don't block on these. The user can skip them if they're confident.

## Snippet expansion happens in create/update

Both downstream skills handle `{{include <path>}}` expansion. You don't need to expand here; just route.

## See also

- `create` for the create-side mechanics
- `update` for the update-side mechanics (especially read-modify-write)
- `bulk` for "deploy all" or "deploy everything in <dir>"
