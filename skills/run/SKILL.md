---
name: run
description: Fire a Claude Code routine immediately, bypassing its schedule. Invoke when the user says "run <trigger_id>", "trigger <name>", "fire <name> now", or asks to manually invoke a routine.
---

# claude-routines:run

Trigger a routine to start a session right now, independent of its cron or run_once_at schedule.

## Procedure

1. Call `RemoteTrigger` with `action: "run"` and `trigger_id: <id>`.
2. The response includes the trigger object but does NOT include the run session URL directly.
3. Tell the user: `"Started session for <name>. View at https://claude.ai/code/routines/<trigger_id>"`. The session URL appears on that page once the run begins.

## Manual run works even when disabled

`enabled: false` only pauses SCHEDULED triggers. Manual `run` still fires (matches the web UI's "Run now" button). If the user is surprised, tell them this explicitly.

## Common errors

- HTTP 404: invalid `trigger_id`. Run `list` to find it.
- HTTP 429: rate limit. Tell the user and stop. Don't retry automatically.

## See also

- `list` to find the `trigger_id`
- `get <trigger_id>` if the user wants to inspect the routine before running it
