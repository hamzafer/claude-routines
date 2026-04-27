# claude-routines

> Manage [Claude Code Routines](https://code.claude.com/docs/en/routines) as code. Edit `.md` files. Ask Claude to deploy them. No CLI, no tokens.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Release: v0.2.0](https://img.shields.io/badge/release-v0.2.0-green.svg)](https://github.com/hamzafer/claude-routines/releases/tag/v0.2.0)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-D4A027.svg)](https://code.claude.com)

![demo](docs/demo.gif)

> [!TIP]
> 🎬 **See every feature in action → [`docs/features.md`](docs/features.md)**
> Ten GIFs walking through `pull`, `deploy`, `validate`, `diff`, `{{include}}` snippets, bulk operations, `dry-run`, `list`, `run`, and `orphans`.

## Why

Anthropic's [Routines](https://code.claude.com/docs/en/routines) (research preview, 2026-04-14) run a saved prompt on a schedule, on GitHub events, or via API. You manage them through the web UI, the desktop app, or `/schedule` in the CLI.

I wanted to migrate my [openclaw](https://github.com/openclaw/openclaw) onto it.

**None of those let you keep routines as code.** No fork-and-edit. No version history. No PR review. No bulk ops. No diff between local and cloud.

This repo fills that gap. Each routine = one `.md` file with YAML config + prompt body. Claude reads the file and calls the management API for you.

Use `/schedule` for quick conversational changes. Use this when you want to **version, review, share, or bulk-edit**.

## A routine

```yaml
---
name: "Daily PR Review"
cron: "0 9 * * 1-5"          # Mon–Fri, 9am UTC
env_id: env_01ABC...
allowed_tools: [Bash, Read, Edit, Grep, WebFetch]
sources:
  - url: https://github.com/your-org/your-repo
    allow_unrestricted_git_push: false
---

Review every PR opened in the last 24 hours. For each, leave inline comments...
```

## A session

```
> deploy routines/daily-pr-review.md
✓ Created trig_01ABC... — Daily PR Review (Mon–Fri 9:00 UTC)

> list
trig_01ABC...   Daily PR Review                Mon–Fri 9:00 UTC   enabled
trig_01XYZ...   Alert Triage Responder         API trigger        enabled

> diff personal/oslo-apartment-hunter.md
✓ in sync

> run trig_01ABC...
✓ Started session — https://claude.ai/code/routines/trig_01ABC...
```

## Quickstart

```bash
git clone https://github.com/hamzafer/claude-routines my-routines
cd my-routines
./scripts/install-hooks.sh        # enables the pre-commit safety hook
claude                            # opens Claude Code in this repo
```

Then ask Claude:

- `pull` — import existing routines from claude.ai
- `validate` — lint every routine against the schema
- `deploy <file>` — push a single routine
- `deploy all` — bulk deploy every routine
- `diff <file>` — what's changed vs. the cloud
- `run <trigger_id>` — fire now

Full reference: [`docs/reference.md`](docs/reference.md). Migrating from the web UI: [`docs/migration-from-web.md`](docs/migration-from-web.md).

## Personal vs. shareable

- `routines/` — generic templates. Committed.
- `personal/` — your real routines. Gitignored. Pre-commit hook blocks accidental staging.

Same format, same operations. Both folders work.

## Caveats

- **The management API is undocumented.** Only `/fire` is in [Anthropic's docs](https://code.claude.com/docs/en/routines). The endpoints we call (`/v1/code/triggers`) are reverse-engineered. They may change.
- **Anthropic may ship official tooling.** When they do, this deprecates gracefully.
- **Env vars are not real secrets.** Visible to anyone with edit access on the environment.
- **`update` has a security gotcha.** A partial `job_config` silently expands `allowed_tools` to a 19-tool default set. We prevent it via mandatory read-modify-write. Anyone calling the API directly should be aware. [Details](docs/superpowers/specs/2026-04-26-claude-routines/03-update-safety.md).
- **No DELETE via API.** Use the [web UI](https://claude.ai/code/routines).
- **GitHub triggers / API tokens are web-UI-only.** This framework preserves them on round-trip but can't create or modify them.

Full risk list: [`docs/superpowers/specs/2026-04-26-claude-routines/09-risks.md`](docs/superpowers/specs/2026-04-26-claude-routines/09-risks.md).

## License

MIT. See [LICENSE](LICENSE).

## Contributing

PRs welcome. If you find undocumented API behavior we missed, add to [`docs/verification/2026-04-26-routines-api-experiments.md`](docs/verification/2026-04-26-routines-api-experiments.md).
