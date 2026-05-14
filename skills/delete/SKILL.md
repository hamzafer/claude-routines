---
name: delete
description: Handle deletion requests for Claude Code routines. The RemoteTrigger API does not support delete. This skill explains that and points the user to the web UI. Invoke when the user says "delete <trigger_id>" or asks to remove a routine.
---

# claude-routines:delete

There is no API for deleting a routine. The `RemoteTrigger` skill only exposes `list`, `get`, `create`, `update`, and `run`.

## What to tell the user

> "There's no delete via the API. To remove a routine, open the web UI at https://claude.ai/code/routines, find the routine, and delete it from there. Once deleted, run the `orphans` skill to clean up any local `.md` file with a now-stale `trigger_id`."

## What NOT to do

- Don't attempt to PATCH or DELETE the trigger via raw HTTP. The endpoint doesn't exist.
- Don't suggest `enabled: false` as a substitute for delete. It pauses scheduled triggers but they still appear in `list` output.

## See also

- `orphans` to find local files whose `trigger_id` no longer exists in the cloud (after a web-UI delete)
