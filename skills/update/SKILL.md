---
name: update
description: Update an existing Claude Code routine via the read-modify-write protocol. Invoke when the user says "update <file>" or as a sub-skill of deploy. The file's frontmatter MUST contain a trigger_id. Critical safety rules apply, especially around mcp_connections and permissions.
---

# claude-routines:update

Update an existing routine. The file's frontmatter MUST have a `trigger_id`. (If it doesn't, route to `create` instead.)

## CRITICAL: read-modify-write is mandatory

The API resets missing nested fields inside `job_config` to maximally-permissive defaults. If you send a partial `job_config`, the API will silently expand `allowed_tools` to a default set including Bash, Write, Edit, NotebookEdit. NEVER send a partial `job_config`.

## Procedure

1. Parse YAML frontmatter and body from the file.
2. If `trigger_id` is absent, abort and route to `create`.
3. Call `RemoteTrigger` with `action: "get"` and `trigger_id: <id>`. Capture the response as `live`.
4. Drop these read-only fields from `live` before modifying:
   - `id`, `created_at`, `updated_at`, `next_run_at`, `creator`, `ended_reason`
   - `api_token_hint`, `persist_session`, `last_fired_at`, `enabled_plugins`, `extra_marketplaces`
   - `job_config.ccr.session_context.outcomes`
5. Deep-merge frontmatter values onto `live`:
   - Top-level: `name`, `cron_expression`, `run_once_at`, `enabled`
   - `job_config.ccr.environment_id`
   - `job_config.ccr.events[0].data.message.content` (the expanded prompt body)
   - `job_config.ccr.session_context.allowed_tools` / `model` / `sources`
   - `mcp_connections` (see special handling below)
6. Expand `{{include <path>}}` directives in the prompt body before merging (same as `create`).
7. Call `RemoteTrigger` with `action: "update"`, `trigger_id: <id>`, and the merged body.
8. Surface the result and the URL `https://claude.ai/code/routines/<trigger_id>`.

## mcp_connections special handling on update

| Frontmatter `mcp_connections` | Body to send |
|---|---|
| Field absent | Don't include `mcp_connections` in the body. Live state preserved. |
| Non-empty list | `mcp_connections: [...]` (replaces live state) |
| Empty list (`[]`) | Use `clear_mcp_connections: true` (NOT `mcp_connections: []`, which is a no-op) |

## Model field placement on partial update

For UPDATE, the `model` field can be sent at the TOP LEVEL of the body, as a shortcut:

```jsonc
// Top-level form (works for partial update; sets model without touching anything else)
{"model": "claude-opus-4-7[1m]"}

// Full-config form (model lives inside job_config.ccr.session_context.model)
{"job_config": {"ccr": {..., "session_context": {"model": "claude-opus-4-7[1m]", ...}}}}
```

Use the top-level form ONLY when nothing else is changing. For any full read-modify-write, put `model` inside `session_context` as part of the merged body.

## API quirk: GET does not echo model

The `get` response does NOT include the `model` field, even when the routine is clearly running on a non-default model. This means:

- You cannot verify a model change by re-GET'ing. The web UI at `https://claude.ai/code/routines/<id>` is the only reliable visual confirmation.
- When merging live state from `get`, you won't have the current model. Use whatever's in frontmatter; if the user wants to preserve an unknown current model, ask them.

## Hard rules

1. Always read-modify-write. Never send a partial `job_config`. The cost of forgetting: silent permission expansion.
2. Use `clear_mcp_connections: true` to clear connectors. `mcp_connections: []` is a no-op.
3. `enabled: false` does NOT block manual run. It only pauses scheduled triggers. Tell the user this if they're confused.
4. There is no DELETE via API. If asked to delete, use the `delete` skill.
5. Surface API errors verbatim. On 4xx, show `error.message` to the user and stop. Don't retry, don't silently fall back.

## Common errors

- `cron interval too short`: Pick a less frequent schedule.
- `conflicting fields` (cron + run_once_at): Set exactly one.
- HTTP 404: The `trigger_id` doesn't exist. Maybe deleted via web UI. Suggest `list`.

## See also

- `deploy <file>` to route automatically
- `diff <file>` to preview the changeset
- `dry-run deploy <file>` to preview the body
- `validate <file>` to lint frontmatter and cron rules first
