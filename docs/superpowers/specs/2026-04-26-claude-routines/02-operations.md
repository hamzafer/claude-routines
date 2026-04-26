# Operations

Six commands, each maps directly to a `RemoteTrigger` action. No clever abstractions.

## `list`

Calls `RemoteTrigger.list`. Prints a table: id, name, schedule, enabled, last-edited.

## `get <trigger_id>`

Calls `RemoteTrigger.get`. Writes a `.md` file to `routines/<slug>.md` (slug derived from the routine name, kebab-case). Used to import an existing routine into the repo.

## `pull`

Bulk: `list`, then `get` each, write all to `routines/`. Used to seed the repo from an existing account. Subsequent `pull` calls overwrite existing files, so users can round-trip edits made via the web UI.

## `create <file>`

Frontmatter has no `trigger_id`. Reads the file, builds the API body, calls `RemoteTrigger.create`. On success, writes the returned `trigger_id` back into the file's frontmatter so the next deploy is an `update`.

## `update <file>`

Frontmatter has `trigger_id`. **Always read-modify-write** — see [Update safety](03-update-safety.md):

1. `RemoteTrigger.get` to fetch the live config.
2. Strip read-only fields (id, created_at, updated_at, next_run_at, creator, ended_reason, outcomes, api_token_hint).
3. Apply the file's writable fields on top.
4. `RemoteTrigger.update` with the merged result.

## `run <trigger_id>`

Calls `RemoteTrigger.run`. Returns 200 with the trigger object — no session URL in response. CLI output: routine name + a link to `https://claude.ai/code/routines/<trigger_id>` so the user can watch the new session in the routine's Runs panel.

Verified: fires real cloud sessions even on `enabled: false` routines (manual run bypasses the pause flag, matching web UI behavior). Manual runs do not count against the 15/day routine cap.

## Deploy alias

`deploy <file>` is shorthand: if `trigger_id` is in the frontmatter, it's `update`; otherwise it's `create`. The CLAUDE.md instructions cover this so users say "deploy this" and Claude figures it out.

## What v0.1 deliberately omits

- `delete` — not exposed by the management API. Web UI only.
- `validate`, `diff` — see [roadmap](08-roadmap.md).
- GitHub trigger CRUD, API-trigger token management — web UI only at this layer.
