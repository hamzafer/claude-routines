# Reference

User-facing quick reference for `claude-routines`. For design rationale, see [`docs/superpowers/specs/2026-04-26-claude-routines/`](superpowers/specs/2026-04-26-claude-routines/).

## Frontmatter fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `trigger_id` | string | no | Presence = update; absence = create. |
| `name` | string | yes | Display name. |
| `cron` | string | one of cron / run_once_at | UTC, minimum 1-hour interval. |
| `run_once_at` | RFC3339 UTC | one of cron / run_once_at | Mutually exclusive with `cron`. |
| `enabled` | bool | no (default `true`) | `false` pauses scheduled firing. Manual `run` still works. |
| `env_id` | string | yes | Cloud environment ID. |
| `model` | string | no | `claude-opus-4-7`, `claude-opus-4-7[1m]`, `claude-sonnet-4-6`, `claude-haiku-4-5`. Omit = account default. |
| `allowed_tools` | string[] | yes (recommended) | E.g. `[Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]`. **Always set explicitly** — see "Update safety" below. |
| `sources` | object[] | no | `[{url, allow_unrestricted_git_push}]`. Repos cloned at session start. |
| `mcp_connections` | object[] | no | `[{connector_uuid, name, url, permitted_tools}]`. See "MCP semantics" below. |

The markdown body (after the closing `---`) is the routine's saved prompt, sent verbatim as the user message at session start.

## Operations

| Command | What it does |
|---|---|
| `pull` | Import all your routines from claude.ai into `routines/`. |
| `list` | Show all routines on your account. |
| `get <trigger_id>` | Fetch one routine and write it to `routines/<slug>.md`. |
| `deploy <file>` | Smart create-or-update based on whether `trigger_id` is in the frontmatter. |
| `create <file>` | Strict create. Fails if `trigger_id` exists in the frontmatter. |
| `update <file>` | Strict update. Fails if `trigger_id` is missing. Always read-modify-write. |
| `run <trigger_id>` | Fire the routine now. Works even on `enabled: false` routines. |

There is no `delete`. Delete routines via the web UI at [claude.ai/code/routines](https://claude.ai/code/routines).

## Update safety

When `update` is called, the API treats `job_config` as **replace-not-merge with default expansion**: missing nested fields are reset to maximally-permissive platform defaults. A naive partial update silently grants the routine more privileges than its file says.

`claude-routines` always does read-modify-write:

1. `RemoteTrigger.get` to fetch live state.
2. Strip read-only fields.
3. Apply your file's frontmatter on top.
4. `RemoteTrigger.update` with the full merged body.

You don't have to do anything — this is automatic. But: **always set `allowed_tools` explicitly in your frontmatter** so the merged body has the value you intend, not whatever the live state happens to contain.

## MCP semantics

| Frontmatter | Effect on update |
|---|---|
| `mcp_connections:` field absent | Live connections preserved. |
| `mcp_connections: [{...}, ...]` | Replace with the new list. |
| `mcp_connections: []` (empty list) | Wipe all connections. (Implementation: `claude-routines` translates to `clear_mcp_connections: true` because the API treats `mcp_connections: []` as "no change.") |

The API does not validate `connector_uuid` — any v4 UUID + name + URL is accepted. So you can attach custom MCP servers (self-hosted Telegram MCP, internal company MCPs) without going through the web UI's "Connect" flow. Caveat: runtime behavior with unreachable MCPs is untested.

## Common errors

| API error | Fix |
|---|---|
| `cron interval too short` | Cron must run no more than once per hour. |
| `conflicting fields` | Set exactly one of `cron:` or `run_once_at:`, not both. |
| `environment_id` not found | Check `claude.ai/code` → env selector for valid env IDs. |
| 404 on `update` / `get` / `run` | The `trigger_id` doesn't exist (maybe deleted via web UI). |

## File layout

```
routines/           public-shareable routines (committed)
personal/           your private routines (gitignored)
snippets/           public reusable prompt fragments (committed)
personal/snippets/  your private prompt fragments (gitignored)
```

`routines/` and `personal/` use the same format — operations work on `.md` files in either.

## Snippet includes

A routine's prompt body can include shared fragments via the `{{include path}}` directive on a line by itself:

```yaml
---
name: "Daily Digest"
cron: "0 8 * * *"
...
---

Do the daily digest stuff. ...

{{include snippets/session-link.md}}
```

`claude-routines` expands includes client-side at deploy time. The cloud sees the fully-expanded prompt. The local file stays compact.

**Caveats:**
- Path is relative to the repo root.
- Snippet files have no YAML frontmatter — they're pure prompt text.
- Includes don't nest (a snippet can't include another snippet).
- Missing snippet = deploy aborts before any API call.
- **Pull does not re-snippet.** After `pull`, the include reference is gone — you'll see the expanded text instead. Treat includes as a write-side optimization.

See [`snippets/README.md`](../snippets/README.md) for examples.

## Cron tips

- Cron is **UTC** at the API layer. The web UI auto-converts to local time. If you `pull` after editing on the web, expect UTC cron in the .md files.
- Minimum interval is 1 hour. `*/30 * * * *` is rejected.
- Runs are staggered by a few minutes to spread server load. Don't be surprised if a 9:00 cron runs at 9:03.
