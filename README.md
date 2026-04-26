# claude-routines

> Manage [Claude Code Routines](https://code.claude.com/docs/en/routines) as code. Edit `.md` files, ask Claude to deploy them. No CLI to install, no tokens to manage.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Status: v0.2](https://img.shields.io/badge/status-v0.2-green.svg)](#status)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-D4A027.svg)](https://code.claude.com)

## What problem this solves

Claude Code Routines (research preview, shipped 2026-04-14) let you save Claude Code configurations — prompt + repos + connectors + triggers — that run on Anthropic-managed cloud infrastructure. They're managed via three surfaces: the web UI at [claude.ai/code/routines](https://claude.ai/code/routines), the desktop app, and the CLI's `/schedule` command.

**None of those let you manage routines as code in a repository.** No fork-and-edit. No version history for prompts. No PR review. No shared library across teammates. No bulk operations. No diff between local and cloud.

`claude-routines` fills that gap. Each routine is one `.md` file (YAML frontmatter + prompt body). You edit files, ask Claude in plain English to deploy them, and Claude calls the management API for you using its built-in `RemoteTrigger` skill.

## Why this if `/schedule` already exists?

`/schedule` is great for conversational create/list/update/run on a single routine. It's not great for:

- Editing a prompt that's 200 lines long (you don't want to dictate 200 lines into a slash command)
- Versioning prompt changes over time
- Reviewing a teammate's routine in a PR
- Bulk-changing all your routines at once
- Validating a routine offline before deploying
- Diffing local intent vs. cloud state

This framework is for those cases. It complements `/schedule` — they share the same management API. (Verified empirically. See [the verification record](docs/verification/2026-04-26-routines-api-experiments.md).)

## How it works

A routine is one `.md` file:

```yaml
---
name: "Daily PR Review"
cron: "0 9 * * 1-5"          # Mon–Fri, 9am UTC
enabled: true
env_id: env_01ABC...
allowed_tools: [Bash, Read, Edit, Grep, WebFetch]
sources:
  - url: https://github.com/your-org/your-repo
    allow_unrestricted_git_push: false
---

Review every PR opened in the last 24 hours. For each, leave inline comments...
```

Then in Claude Code:

```
> deploy routines/daily-pr-review.md
✓ Created trig_01ABC... — Daily PR Review (Mon–Fri 9:00 UTC)

> list
trig_01ABC...   Daily PR Review                Mon–Fri 9:00 UTC   enabled
trig_01XYZ...   Alert Triage Responder         API trigger        enabled
trig_01PQR...   Weekly Docs Drift Check        Mon 14:00 UTC      enabled

> run trig_01ABC...
✓ Started session for "Daily PR Review"
  https://claude.ai/code/routines/trig_01ABC...
```

That's it. Claude reads the `.md` file, builds the API body, fires the right `RemoteTrigger` action, writes any returned `trigger_id` back into your file. Six operations: `list`, `get`, `pull`, `create`, `update`, `run`. (No `delete` — the management API doesn't expose it. Use the web UI.)

## Quickstart

```bash
git clone https://github.com/hamzafer/claude-routines my-routines
cd my-routines
./scripts/install-hooks.sh        # one-time: enables the pre-commit safety hook
claude                            # opens Claude Code in this repo
```

If you already have routines on claude.ai:

```
> pull
✓ Wrote 9 routines to routines/
```

If you're starting fresh, copy one of the example routines in `routines/` (PR reviewer, alert triage, docs drift) and customize it.

Other things you can ask Claude:

- `validate` — lint every routine against the schema (no API calls)
- `diff personal/foo.md` — see what's changed vs. the cloud
- `deploy all` — bulk deploy every routine in `routines/` and `personal/`
- `run trig_01ABC...` — fire a routine now (works even on `enabled: false` routines)

The full operations reference is at [`docs/reference.md`](docs/reference.md). For migrating existing routines, see [`docs/migration-from-web.md`](docs/migration-from-web.md).

## Personal vs. shareable routines

- `routines/` — generic templates anyone can copy. Committed to git.
- `personal/` — your real routines with specific prompts, cron, env IDs. **Gitignored**, except for `personal/README.md`.

The pre-commit hook in `.githooks/pre-commit` blocks any commit that stages a file under `personal/`. Belt-and-suspenders: even if you `git add -A` carelessly, your private routines stay private.

Both folders use the same format. Operations work on `.md` files in either.

## Important caveats — read before relying on this

This is a community framework, not an Anthropic product.

1. **The management API we use is undocumented.** Only the public `/fire` endpoint is in [Anthropic's official docs](https://code.claude.com/docs/en/routines). The endpoints `claude-routines` calls (`/v1/code/triggers`) are reverse-engineered from Claude Code's in-process `RemoteTrigger` skill. Anthropic may change them without notice.

2. **Anthropic may ship official tooling.** When they do, this repo deprecates gracefully — or layers on top.

3. **Env vars are not real secrets.** Cloud-environment env vars are stored as plain text, visible to anyone with edit access to the environment. Don't put production credentials there until Anthropic ships a real secrets store.

4. **`update` has a real security gotcha.** Sending a partial `job_config` silently expands `allowed_tools` to a 19-tool default set including Bash/Write/Edit/NotebookEdit. `claude-routines` prevents this via mandatory read-modify-write. Anyone calling the API directly with curl should be aware. Details in [`docs/superpowers/specs/2026-04-26-claude-routines/03-update-safety.md`](docs/superpowers/specs/2026-04-26-claude-routines/03-update-safety.md).

5. **No DELETE via API.** Web UI only at [claude.ai/code/routines](https://claude.ai/code/routines).

6. **GitHub event triggers and API tokens are web-UI-only at the management API.** This framework preserves them on round-trip but cannot create or modify them.

Full risk list: [`docs/superpowers/specs/2026-04-26-claude-routines/09-risks.md`](docs/superpowers/specs/2026-04-26-claude-routines/09-risks.md).

## Status

| | What |
|---|---|
| **v0.1 — shipped 2026-04-26** | Form A (fork-as-starter): CLAUDE.md + 3 example routines + frontmatter spec. Six operations end-to-end (`list`, `get`, `pull`, `create`, `update`, `run`). Round-trip verified empirically. |
| **v0.2 — shipped 2026-04-26** | `{{include}}` snippets in prompt bodies. `validate` (offline lint). `diff` (semantic local-vs-cloud). `bulk` operations ("deploy all", "deploy `<dir>/`"). |
| **v0.3+ — later** | `pull --orphans` (find local files whose trigger_id no longer exists in cloud), multi-account profiles, GitHub-trigger CRUD if Anthropic exposes the schema. |

> **Note:** an earlier draft roadmap mentioned a Claude Code plugin (`/routine deploy`) — that's been scrapped. It would just re-skin Anthropic's `/schedule` command without adding capability. Real v0.2 work is in features `/schedule` doesn't have because it isn't file-based.

## License

MIT. See [LICENSE](LICENSE).

## Contributing

PRs welcome — especially if you discover an undocumented API behavior we missed. The empirical verification record is at [`docs/verification/2026-04-26-routines-api-experiments.md`](docs/verification/2026-04-26-routines-api-experiments.md). Add to it.
