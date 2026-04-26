# claude-routines — operational instructions for Claude Code

This repo manages Claude Code Routines as code. Each routine is a `.md` file with YAML frontmatter (config) and a markdown body (the prompt). When the user asks you to operate on a routine, follow the instructions below.

You execute these operations in-process via the `RemoteTrigger` skill that ships with Claude Code. Auth is handled automatically — do not look for tokens or env vars.

---

## When the user says…

- **"deploy `<file>`"** or "push `<file>`" → if the file's frontmatter has a `trigger_id`, do **update**; else do **create**.
- **"create `<file>`"** → strict create. Frontmatter must NOT have `trigger_id`. Add the returned `trigger_id` to the file's frontmatter after success.
- **"update `<file>`"** → strict update. Frontmatter must have `trigger_id`. Use the read-modify-write protocol.
- **"list"** or "show my routines" → list action.
- **"pull"** → list, then get each, write all to `routines/`.
- **"get `<trigger_id>`"** → fetch one, write to `routines/<slug>.md`.
- **"run `<trigger_id>`"** → fire the routine now.
- **"delete `<trigger_id>`"** → tell the user this isn't supported via API; they need to delete via web UI at https://claude.ai/code/routines.

---

## Frontmatter spec (full reference: `docs/reference.md`)

```yaml
---
trigger_id: trig_01ABC...     # presence = update; absence = create
name: "Display name"          # required

# Trigger — exactly one of:
cron: "0 8 * * *"             # UTC, minimum 1-hour interval
# run_once_at: "2027-01-01T00:00:00Z"

enabled: true                 # default true; false = scheduled triggers paused, manual run still works
env_id: env_01...             # required; cloud environment ID
model: claude-sonnet-4-6      # optional; one of claude-opus-4-7, claude-opus-4-7[1m], claude-sonnet-4-6, claude-haiku-4-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
sources:                      # optional, repos cloned at session start
  - url: https://github.com/owner/repo
    allow_unrestricted_git_push: false
mcp_connections:              # optional
  - connector_uuid: <v4 uuid>
    name: <name>
    url: <url>
    permitted_tools: []
---

(prompt body — sent verbatim as the routine's user message)
```

---

## How to call `RemoteTrigger`

`RemoteTrigger` accepts `action` plus an optional `trigger_id` and `body`. Available actions: `list`, `get`, `create`, `update`, `run`. There is no `delete`.

### create

```
RemoteTrigger({
  action: "create",
  body: {
    name: <frontmatter.name>,
    cron_expression: <frontmatter.cron>,         // OR run_once_at: <frontmatter.run_once_at>
    enabled: <frontmatter.enabled ?? true>,
    job_config: {
      ccr: {
        environment_id: <frontmatter.env_id>,
        events: [{
          data: {
            uuid: <generated lowercase v4 uuid>,
            session_id: "",
            type: "user",
            parent_tool_use_id: null,
            message: { content: <prompt body>, role: "user" }
          }
        }],
        session_context: {
          allowed_tools: <frontmatter.allowed_tools>,
          model: <frontmatter.model>,            // omit if not in frontmatter
          sources: <frontmatter.sources>         // omit if not in frontmatter
        }
      }
    },
    mcp_connections: <frontmatter.mcp_connections>  // omit if not in frontmatter
  }
})
```

After success, write `trigger_id` from the response back into the file's frontmatter.

### update — read-modify-write (MANDATORY)

The API resets missing nested fields inside `job_config` to maximally-permissive defaults (see `docs/superpowers/specs/2026-04-26-claude-routines/03-update-safety.md`). To update safely:

```
1. live = RemoteTrigger({ action: "get", trigger_id: <frontmatter.trigger_id> })
2. Drop these read-only fields from `live`:
     id, created_at, updated_at, next_run_at, creator, ended_reason,
     api_token_hint, persist_session,
     job_config.ccr.session_context.outcomes
3. merged = deep-merge frontmatter values onto `live`:
     - top-level name, cron_expression, run_once_at, enabled
     - job_config.ccr.environment_id
     - job_config.ccr.events[0].data.message.content (the prompt body)
     - job_config.ccr.session_context.allowed_tools / model / sources
     - mcp_connections (see special handling below)
4. RemoteTrigger({ action: "update", trigger_id, body: merged })
```

### mcp_connections — special handling on update

| Frontmatter | Body to send |
|---|---|
| Field absent | Don't include `mcp_connections` in body. Live state preserved. |
| Field is non-empty list | `mcp_connections: [...]` (replace). |
| Field is empty list (`[]`) | **Use `clear_mcp_connections: true`** (NOT `mcp_connections: []`, which is a no-op). |

### list

```
RemoteTrigger({ action: "list" })
```
Returns `{ data: [trigger, ...], has_more: bool }`. Print a compact table: id, name, schedule (`cron_expression` or `run_once_at`), `enabled`, `updated_at`.

### get

```
RemoteTrigger({ action: "get", trigger_id })
```
Strip read-only fields, derive a kebab-case slug from `name`, write to `routines/<slug>.md`.

### run

```
RemoteTrigger({ action: "run", trigger_id })
```
Returns the trigger object. After success, tell the user: "Started session for <name>. View at https://claude.ai/code/routines/<trigger_id>". The session URL is not in the response — that link is the routine's run history page.

---

## File location convention

- `routines/*.md` — public-shareable routines, committed to git.
- `personal/*.md` — user's personal routines, gitignored. Only `personal/README.md` is committed (it documents the convention). Treat `.md` files in `personal/` exactly like ones in `routines/` — same operations apply.

When the user says "deploy this" while looking at a file in either folder, both work.

---

## Critical rules

1. **Always read-modify-write on update.** Never send a partial `job_config`. The API will silently expand `allowed_tools` to a permissive default set including Bash/Write/Edit if you do.
2. **Use `clear_mcp_connections: true` to clear connectors, not `mcp_connections: []`.**
3. **`enabled: false` does NOT block manual run.** It only pauses scheduled triggers. Manual `run` still fires (matches the web UI's "Run now" button). Tell the user this if they're confused.
4. **There is no DELETE.** Direct users to the web UI for deletion.
5. **Surface API errors verbatim.** When the API returns 4xx, show `error.message` to the user and stop. Don't retry, don't silently fall back.

---

## Common errors and what they mean

| API error | What to tell the user |
|---|---|
| `cron interval too short` | Cron must run no more than once per hour. Pick a less frequent schedule. |
| `conflicting fields` (cron + run_once_at) | Set exactly one of `cron:` or `run_once_at:`, not both. |
| `environment_id` not found | The env doesn't exist or doesn't belong to this account. Check `claude.ai/code` → env selector. |
| 404 on `get` / `update` | The `trigger_id` doesn't exist. Maybe deleted via web UI. Run `list` to confirm. |

---

## When in doubt

- Read `docs/reference.md` for the user-facing quick reference.
- Read `docs/superpowers/specs/2026-04-26-claude-routines/` for design rationale.
- Read `docs/verification/2026-04-26-routines-api-experiments.md` for the empirical record of every API behavior we depend on.
