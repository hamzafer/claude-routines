# Features

Per-feature walkthrough with GIFs. For schema and field details, see [`reference.md`](reference.md). For design rationale, see [`superpowers/specs/2026-04-26-claude-routines/`](superpowers/specs/2026-04-26-claude-routines/).

---

## `pull` — import existing routines

Have routines on [claude.ai/code/routines](https://claude.ai/code/routines)? One command brings them down as files in `personal/`.

> _GIF: `pull` — empty `personal/` → N files appear_

```
> pull
✓ Wrote 9 routines to personal/
```

Each file gets a kebab-case slug from the routine name. Frontmatter contains the live config (cron, env_id, allowed_tools, etc.); the body is the prompt verbatim.

---

## `deploy <file>` — edit + push

The core loop. Edit a routine `.md` locally, ask Claude to deploy it. The framework reads the file, fetches live state, merges, and updates the cloud — without silently expanding `allowed_tools` (see [Update safety](superpowers/specs/2026-04-26-claude-routines/03-update-safety.md)).

> _GIF: `deploy` — edit a cron, ask Claude, cloud updates_

```
> deploy personal/oslo-apartment-hunter.md
✓ Updated trig_018DCw7cufB9naM71eRoFYVi — Oslo Apartment Hunter
  cron: "0 7 * * *" → "0 9 * * *"
```

Smart create-or-update: presence of `trigger_id` in frontmatter means update; absence means create.

---

## `validate` — catch errors before deploy

Pure-local lint against the schema. No API call. Catches sub-1h crons, conflicting cron/run_once_at, bad model enum, missing snippet includes, frontmatter parse errors, and the silent-default-expansion footprint in `allowed_tools`.

> _GIF: `validate` — paste a routine with `*/30 * * * *`, watch the lint catch it_

```
✗ personal/broken.md
  - error: cron "*/30 * * * *" — minimum 1-hour interval
  - warning: allowed_tools includes the full default write-set (Bash + Write + Edit + NotebookEdit)
✓ personal/morning-brain-digest.md
✓ personal/oslo-apartment-hunter.md
...

8 OK · 1 error · 1 warning
```

Run `validate` on its own to lint every routine in `routines/` and `personal/`.

---

## `diff <file>` — semantic compare with cloud

Field-aware comparison between a local routine and its cloud state. Skips read-only fields (created_at, next_run_at, etc.). For lists like `allowed_tools`, reports added/removed individually. For prompt body, shows a unified diff with character-count delta.

> _GIF: `diff` — drift a routine on the web UI, then run `diff` to spot it_

```
trig_018DCw7cufB9naM71eRoFYVi  Oslo Apartment Hunter

  cron:           "0 7 * * *"  →  "0 9 * * *"
  prompt:         3 lines changed (+42 chars)

3 fields differ
```

`diff all` runs the full sweep across `routines/` and `personal/`.

---

## `{{include}}` snippets — DRY across routines

Routine prompt bodies can include shared fragments via `{{include path/to/snippet.md}}` on a line by itself. Expanded client-side at deploy time; the cloud sees the full prompt.

> _GIF: snippets — edit `personal/snippets/telegram-card.md`, redeploy 5 routines that use it_

```yaml
---
name: "Daily News Digest"
cron: "0 8 * * *"
...
---

Send a Norway news digest with ONLY NEW stories from the last 24 hours.

{{include personal/snippets/telegram-card-universal.md}}
```

Caveats: pull doesn't re-snippet (you get the expanded body back); snippet files don't have frontmatter; includes don't nest.

---

## Bulk operations

When you say "deploy all", "deploy `personal/`", or "deploy all routines using `<snippet>`", the framework iterates the matching files. Validation runs first; per-file 4xx errors are reported and skipped, 5xx aborts the whole bulk.

> _GIF: bulk — edit a snippet, run "deploy all routines using this snippet", watch the fan-out_

```
> deploy all routines using personal/snippets/telegram-card-universal.md
✓ personal/norway-daily-news-digest.md
✓ personal/oslo-apartment-hunter.md
✓ personal/phd-it-tech-scraper.md
✓ personal/daily-finn-tesla-model-y-scan.md
✓ personal/daily-norway-life-hacks.md

5 deployed · 0 skipped · 0 errors
```

---

## `dry-run deploy <file>` — preview without firing

Build the API body exactly as `deploy` would, but don't call the API. Pretty-prints the body and lists which fields would change. Pairs with `diff` for full pre-deploy confidence.

> _GIF: dry-run — show the JSON that would be sent + the field-change summary_

```
> dry-run deploy personal/oslo-apartment-hunter.md
operation: update (trigger_id present)
fields to change: cron, prompt body (+42 chars)

{
  "name": "Oslo Apartment Hunter",
  "cron_expression": "0 9 * * *",
  ...
}
```

Bulk dry-run is supported via "dry-run deploy all".

---

## `list` and `run`

Basic visibility and manual fire.

```
> list
trig_018DCw7cufB9naM71eRoFYVi   Oslo Apartment Hunter            0 9 * * *    enabled
trig_017LRW1aqy25Hpu6PF6GgGw4   Norway Daily News Digest         0 8 * * *    enabled
trig_0193kngfLtWbMYHDoEBGSm5D   Running Shoe Deal Tracker        0 9 * * *    enabled
...

> run trig_018DCw7cufB9naM71eRoFYVi
✓ Started session for "Oslo Apartment Hunter"
  https://claude.ai/code/routines/trig_018DCw7cufB9naM71eRoFYVi
```

`run` works even on `enabled: false` routines — only scheduled triggers respect the pause flag. Manual fires don't count against the daily routine cap.

---

## `orphans` — detect deletes-via-web-UI

Local files whose `trigger_id` no longer exists in the cloud (you deleted the routine via web UI). Pure-local check after a `list` call. Doesn't delete the files automatically — that's your call.

```
> orphans
personal/old-tracker.md → trig_01ABC... (not in cloud)
personal/dead-routine.md → trig_01XYZ... (not in cloud)

2 orphans
```

---

## What's not here

| | Why |
|---|---|
| `delete` via API | The management API doesn't expose deletion. Use [claude.ai/code/routines](https://claude.ai/code/routines). |
| GitHub event triggers (CRUD) | Web UI only at the management API. We preserve them on round-trip but can't create or modify. |
| API trigger token mint / rotate | Web UI only. |
| Cloud environment management | Web UI only. References by `env_id`, doesn't manage the env itself. |

Full design rationale: [`superpowers/specs/2026-04-26-claude-routines/07-out-of-scope.md`](superpowers/specs/2026-04-26-claude-routines/07-out-of-scope.md).
