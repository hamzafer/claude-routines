---
name: dry-run
description: Preview the exact API body that "deploy <file>" would send, without calling the API. Useful sanity check before shipping. Invoke when the user says "dry-run deploy <file>", "preview deploy <file>", or "what would deploy send".
---

# claude-routines:dry-run

Build the API body that `deploy` would send and show it to the user. No API calls.

## Procedure

1. Parse the file's frontmatter and body. Expand `{{include}}` directives.
2. Determine the operation:
   - If frontmatter has `trigger_id` -> would be an UPDATE
   - Else -> would be a CREATE
3. If UPDATE, simulate the read-modify-write protocol:
   - Call `RemoteTrigger` with `action: "get"` (this IS a real call but it's read-only)
   - Build the merged body as `update` would (deep-merge frontmatter onto live state, strip read-only fields)
4. If CREATE, build the body as `create` would (full job_config with frontmatter values).
5. Pretty-print the resulting JSON body.
6. Add a one-line summary: which operation, and which fields would change vs. live state (for UPDATE only).

## Output format

```
Operation:  UPDATE  (trigger_id present: trig_01ABC...)
Fields differing vs live: cron_expression, allowed_tools, prompt body (+42 chars)

Body that would be sent:
{
  "name": "Norway News Digest",
  "cron_expression": "0 8 * * *",
  "enabled": true,
  "job_config": {
    "ccr": {
      "environment_id": "env_01...",
      "events": [...],
      "session_context": {
        "allowed_tools": ["Bash", "Read", "WebFetch"]
      }
    }
  },
  "mcp_connections": [...]
}
```

## Pairs well with `diff`

For a complete pre-deploy check: `diff <file>` shows field-by-field changes; `dry-run deploy <file>` shows the exact payload. Together they give full confidence.

## See also

- `validate <file>` to lint the file's structure first
- `diff <file>` for a field-by-field changeset
- `deploy <file>` to actually ship
