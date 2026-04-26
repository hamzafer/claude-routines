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
- **"validate `<file>`"** or "lint `<file>`" → check the file against the rules in [Validate](#validate) below. Don't call the API. Report errors with line numbers when possible.
- **"validate"** with no file → validate every `.md` file under `routines/` and `personal/` (excluding `personal/snippets/` and READMEs). Print a one-line summary per file.
- **"deploy all"** / "deploy everything in `<dir>`" / similar bulk → see [Bulk operations](#bulk-operations) below.
- **"diff `<file>`"** or "what's changed in `<file>`" → see [Diff](#diff) below.
- **"orphans"** or "find orphans" or "list orphans" → list local routine files whose `trigger_id` no longer exists in the cloud (probably deleted via web UI). Pure-local check after a `RemoteTrigger.list`. Print one line per orphan: `<file path> → <trigger_id> (not in cloud)`. End with a count. Don't delete the files — that's the user's call.

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

## Validate

The `validate` operation checks a routine file against the rules below. It never calls the API — it's a pure-local lint. Use it before deploy.

For each file, run these checks in order. Stop at the first **error** per check group; collect all warnings.

**Frontmatter parses** — must be valid YAML between the opening and closing `---`. If parsing fails, report the YAML error and stop.

**Required fields:**
- `name` (string, non-empty)
- `env_id` (string starting with `env_`)
- Exactly one of `cron` (string) or `run_once_at` (RFC3339 UTC timestamp). Both present → error `conflicting fields`. Neither → error `missing trigger`.

**Cron rules** (when `cron` is set):
- Standard 5-field cron in UTC.
- Minimum interval is 1 hour. Reject `*/N * * * *` for `N < 60`. Reject expressions with `*` in the minute field unless paired with `0` in the minute. Easy heuristic: the minute field must be a single digit `0`–`59` or a comma list of single minutes (e.g. `0,30`) — but then the gap between firings is < 1h, so reject too. Safest rule: minute must be a single literal value, AND hour must not contain `*` alone (i.e. `0 * * * *` would fire every hour at :00 = OK; `*/30 * * * *` is rejected).

**`run_once_at` rules** — must be a future RFC3339 UTC timestamp like `2027-01-01T00:00:00Z`. Past timestamps → warning (still accepted by the API but will fire immediately).

**`enabled`** — must be bool if present. Default `true` if absent.

**`model`** — if set, must be one of: `claude-opus-4-7`, `claude-opus-4-7[1m]`, `claude-sonnet-4-6`, `claude-haiku-4-5`. Anything else → error.

**`allowed_tools`** — must be a list of strings. **Warn** if the list is empty (will inherit nothing). **Warn loudly** if it contains every common write-tool (`Bash`, `Write`, `Edit`, `NotebookEdit` all present) — that's the silent-expansion default-set; suggest the user explicitly trim.

**`sources`** — if present, must be a list of objects with `url` (string starting `https://github.com/`) and optional `allow_unrestricted_git_push` (bool).

**`mcp_connections`** — if present, must be a list of objects with `connector_uuid` (lowercase v4 UUID), `name`, `url`, and optional `permitted_tools`.

**Snippet includes** in the prompt body:
- Each `{{include <path>}}` line: the file at `<path>` must exist relative to the repo root.
- The included file must NOT itself contain `{{include}}` directives (no nesting).

**Prompt body** must be non-empty after stripping whitespace.

Output format:

```
✓ personal/morning-brain-digest.md
✗ personal/oslo-apartment-hunter.md
  - error: cron "0 0 * * *" expands to midnight which is fine, but allowed_tools includes the full default-set (Bash, Write, Edit, NotebookEdit) — recommend explicit trim
  - warning: run_once_at is in the past
```

When called without a file argument, validate every routine under `routines/` and `personal/` (skip READMEs and `snippets/`). Final line: `N files OK · M files with errors · W warnings`.

## Diff

The `diff <file>` operation compares a local routine file against its cloud state, field by field. It's read-only — no API writes.

**Procedure:**

1. Parse the file's frontmatter and body. Expand `{{include}}` directives in the body (same as deploy).
2. Read the file's `trigger_id`. If absent, abort with "no trigger_id in frontmatter — use `create` first."
3. `RemoteTrigger.get` to fetch live state.
4. Compare each tracked field. Skip read-only fields entirely (`created_at`, `updated_at`, `next_run_at`, `creator`, `ended_reason`, `api_token_hint`, `persist_session`, `enabled_plugins`, `extra_marketplaces`, `outcomes`).

**Tracked fields (compare and report differences):**

- `name` — string equality.
- `cron_expression` / `run_once_at` — string equality. Note: when the file has `cron`, the cloud's `run_once_at` should be empty string and vice versa; compare the populated one.
- `enabled` — bool equality.
- `job_config.ccr.environment_id` — string equality.
- `job_config.ccr.session_context.model` — string equality. Treat absent (file omits) and empty/missing (cloud omits) as equal.
- `job_config.ccr.session_context.allowed_tools` — set comparison. Report added/removed individually.
- `job_config.ccr.session_context.sources` — list of objects; compare by `url`. For matching urls, compare `allow_unrestricted_git_push`.
- `mcp_connections` — list of objects; compare by `connector_uuid`. Show added/removed entries.
- Prompt body — compare the file's expanded body against `job_config.ccr.events[0].data.message.content`. If different, show a unified diff (or first ±5 lines of difference) plus character-count delta.

**Output format:**

```
trig_01PXv5ejzp1t25HvsFtQ8cKi  Norway Daily News Digest

  cron:           "0 7 * * *"  →  "0 8 * * *"
  allowed_tools:  +Bash  -KillBash
  prompt:         3 lines changed (+42 chars)

  ---     -      Send a Norway news digest with ONLY NEW stories...
  +++     +      Send a Norway news digest from the last 24 hours...

3 fields differ
```

If everything matches:

```
trig_01PXv5ejzp1t25HvsFtQ8cKi  Norway Daily News Digest
✓ in sync
```

**Whitespace handling:** trailing whitespace and trailing newlines on the prompt body are sometimes added/stripped by Anthropic's normalization. Report these as a special note: `prompt: trailing whitespace differs (semantically identical)`. Don't show this as a hard difference — most users don't care.

**Bulk diff:** "diff all" iterates `routines/` and `personal/`. Print the per-file output, then a summary `N in sync · M differ · K errors`.

## Bulk operations

When the user says things like "deploy all routines that use `<snippet>`" or "deploy everything in `personal/`" or "set enabled:false on all of `<dir>/`", iterate the matching files and apply the operation to each.

**Common bulk requests:**

| Phrasing | Action |
|---|---|
| "deploy all" / "deploy everything" | Iterate `routines/*.md` and `personal/*.md`, run deploy on each. |
| "deploy `<dir>/`" or "deploy everything in `<dir>`" | Iterate `<dir>/*.md`. |
| "deploy all routines using `<snippet-path>`" | Grep for the include directive across `.md` files; deploy each match. Useful after editing a snippet. |
| "set enabled:false on all in `<dir>`" | Edit each file's frontmatter, then deploy each. |
| "validate all" | (See validate, no-file form.) |

**Output format for bulk:** one line per file with status. Stop the entire bulk on the first hard failure (e.g. an HTTP 5xx); 4xx-per-file errors are reported and we continue.

**Always validate before deploying in a bulk.** A single bad file should not abort the whole bulk; just report and skip.

## Snippet includes

A routine's prompt body may contain include directives that expand to the contents of another file. Expand these client-side before sending to the API:

**Syntax** — a line containing only `{{include <path>}}`:

```
... rest of prompt ...

{{include snippets/session-link.md}}
```

**Path resolution** — relative to the repo root.
- `{{include snippets/foo.md}}` → `<repo>/snippets/foo.md`
- `{{include personal/snippets/foo.md}}` → `<repo>/personal/snippets/foo.md`

**Expansion rules:**

1. On `create` and `update`, before building the API body, scan the prompt body for `{{include <path>}}` directives.
2. For each, read the file at the path and substitute the directive line with the file's contents (verbatim, no frontmatter — snippet files don't have any).
3. If a path doesn't resolve, abort the deploy and tell the user which include is broken.
4. Do not nest includes. A snippet file shall not contain its own `{{include}}` directives. If you encounter one, abort with an error.
5. The cloud sees the fully-expanded prompt. Includes are a write-side feature only.

**Pull caveat:** when running `pull` or `get`, write the expanded body verbatim — do NOT try to re-detect snippets. The user accepts that pull-after-deploy loses snippet references; this is documented in `snippets/README.md`.

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
