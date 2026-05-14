# Frontmatter format

One `.md` file per routine. YAML frontmatter for config; markdown body is the prompt sent to the routine.

```yaml
---
# Identity
trigger_id: trig_01ABCDEF...    # presence = update; absence = create
name: "Morning Brain Digest"

# Trigger (exactly one of these two — mutually exclusive at API layer)
cron: "0 8 * * *"               # UTC, minimum 1-hour interval
# run_once_at: "2027-01-01T00:00:00Z"

# Lifecycle
enabled: true                   # default true; false creates a dormant routine

# Execution
env_id: env_01FCvqo69RstowerFv1GKNXf
model: claude-sonnet-4-6        # optional; account default if omitted
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]

# Repos to clone at session start (optional)
sources:
  - url: https://github.com/owner/repo
    allow_unrestricted_git_push: false

# MCP connectors (optional; absent = leave existing untouched on update)
mcp_connections:
  - connector_uuid: a30d9132-0d59-4f1a-a15f-123bf3abba89
    name: Excalidraw
    url: https://mcp.excalidraw.com/mcp
    permitted_tools: []
---

You are the Morning Digest agent for a personal knowledge vault...
(rest of the prompt body is sent verbatim as the routine's user message)
```

## Field reference

| Field | Type | Notes |
|---|---|---|
| `trigger_id` | string, optional | Presence = update; absence = create. |
| `name` | string, required | Display name. |
| `cron` | string, optional | UTC cron, minimum 1-hour interval. Sub-1h returns HTTP 400 `cron interval too short`. |
| `run_once_at` | RFC3339 UTC, optional | Mutually exclusive with `cron` — sending both returns HTTP 400 `conflicting fields`. |
| `enabled` | bool | Defaults `true`. `false` = dormant: scheduled triggers are paused, but **manual `run` still fires** (matches the web UI's "Run now" behavior). |
| `env_id` | string, required | Cloud environment ID. Manage envs at `claude.ai/code` → env selector → gear icon. |
| `model` | string, optional | One of `claude-opus-4-7`, `claude-opus-4-7[1m]`, `claude-sonnet-4-6`, `claude-haiku-4-5`. Omit = account default. |
| `allowed_tools` | string[] | **Always set explicitly.** See [Update safety](03-update-safety.md). |
| `sources` | object[], optional | Each: `{url, allow_unrestricted_git_push}`. Repos cloned at session start. |
| `mcp_connections` | object[], optional | Each: `{connector_uuid, name, url, permitted_tools}`. See [MCP semantics](04-mcp-and-clear.md). |

## Prompt body

The markdown body (everything after the closing `---`) is sent verbatim as the routine's saved user message. Variables like `$CLAUDE_CODE_REMOTE_SESSION_ID`, `$TELEGRAM_BOT_TOKEN`, etc. are expanded by the cloud session at runtime.

## Validation

v0.1: `claude-routines` does not lint frontmatter — the API rejects bad input with structured errors that are surfaced verbatim. v0.3+ adds a `validate` command for offline checking.
