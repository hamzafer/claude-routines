---
name: list
description: List all Claude Code routines for the current user. Invoke when the user says "list", "list my routines", "show my routines", "show triggers", or similar phrasings asking to see what scheduled routines exist on their account.
---

# claude-routines:list

Show every routine on the current user's account in a compact table.

## Procedure

1. Call `RemoteTrigger` with `action: "list"`. No arguments.
2. The response is `{ data: [trigger, ...], has_more: bool }`.
3. For each trigger, print a row with: `id`, `name`, schedule (`cron_expression` or `run_once_at`, whichever is populated), `enabled`, `updated_at`.
4. If `has_more` is true, mention it. Pagination is not currently exposed in the API.

## Output format

```
trig_01ABC...  Morning Brain Digest         cron "0 7 * * *"       enabled  2026-05-10T08:21Z
trig_01DEF...  Norway News Daily            cron "0 8 * * *"       enabled  2026-05-12T08:30Z
trig_01GHI...  Conference Application Scan  run_once_at 2027-01-01 disabled 2026-04-22T10:15Z
```

Keep columns aligned. Don't dump the prompt body. If the user asks for details on one trigger, suggest the `get` skill.

## Common errors

- HTTP 401: token expired or missing. Tell the user to re-authenticate via Claude Code.
- Empty `data` array: account has zero routines. Say so plainly.

## See also

- `get <trigger_id>` to inspect one routine
- `pull` to fetch all routines and write them to local `.md` files
- `orphans` to find local files whose `trigger_id` no longer exists in the cloud
