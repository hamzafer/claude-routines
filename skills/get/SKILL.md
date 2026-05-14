---
name: get
description: Fetch a single Claude Code routine by its trigger_id and write it to a local .md file. Invoke when the user says "get <trigger_id>" or asks to download/inspect one specific routine from the cloud.
---

# claude-routines:get

Fetch one routine and write it as a local `.md` file the user can edit.

## Procedure

1. Call `RemoteTrigger` with `action: "get"` and `trigger_id: <id>`.
2. Strip read-only fields from the response: `id`, `created_at`, `updated_at`, `next_run_at`, `creator`, `ended_reason`, `api_token_hint`, `persist_session`, `last_fired_at`, `enabled_plugins`, `extra_marketplaces`, and `job_config.ccr.session_context.outcomes`.
3. Build YAML frontmatter from the remaining fields: `trigger_id`, `name`, `cron` (or `run_once_at`), `enabled`, `env_id` (from `job_config.ccr.environment_id`), `allowed_tools` (from `job_config.ccr.session_context.allowed_tools`), optional `model` (from `job_config.ccr.session_context.model` if present), optional `sources` (from `job_config.ccr.session_context.sources` if present), optional `mcp_connections`.
4. The prompt body comes from `job_config.ccr.events[0].data.message.content`.
5. Derive a kebab-case slug from `name`. Write to `routines/<slug>.md` (or wherever the user prefers; default `routines/`).

## File format

```yaml
---
trigger_id: trig_01ABC...
name: "Morning Brain Digest"
cron: "0 7 * * *"
enabled: true
env_id: env_01...
allowed_tools: [Bash, Read, Write, Edit, WebFetch]
model: claude-opus-4-7
---

(prompt body verbatim)
```

## Pull caveat

If you fetched the body of a routine that originally used `{{include <path>}}` directives, the cloud has the FULLY EXPANDED body. The `get` skill writes that expanded body verbatim. The user accepts that pull-after-deploy loses snippet references; this is by design.

## Common errors

- HTTP 404: the `trigger_id` doesn't exist. Maybe it was deleted via the web UI. Suggest `list` to confirm.

## See also

- `pull` for fetching all routines at once
- `list` to find a `trigger_id` if the user only knows the routine's name
