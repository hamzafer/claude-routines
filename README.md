# claude-routines

Manage [Claude Code Routines](https://code.claude.com/docs/en/routines) as code. Edit `.md` files, ask Claude to deploy them.

[![skills.sh](https://skills.sh/b/hamzafer/claude-routines)](https://skills.sh/hamzafer/claude-routines)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-D4A027.svg)](https://code.claude.com)

## Install

### Claude Code (recommended)

```bash
/plugin marketplace add hamzafer/claude-routines
/plugin install routines@claude-routines
```

Skills activate as `/routines:list`, `/routines:deploy`, etc. Natural language also works ("list my routines", "deploy this file", "diff routines/foo.md").

### Cross-agent via skills.sh

```bash
npx skills add hamzafer/claude-routines -g
```

Cursor, Copilot, Gemini, etc. Skills install with flat names (no `routines:` prefix).

## A routine

```yaml
---
name: "Daily PR Review"
cron: "0 9 * * 1-5"
env_id: env_01ABC...
allowed_tools: [Bash, Read, Edit, Grep, WebFetch]
sources:
  - url: https://github.com/your-org/your-repo
---

Review every PR opened in the last 24 hours. Leave inline comments...
```

## A session

```
> deploy routines/daily-pr-review.md
Created trig_01ABC... (Daily PR Review, weekdays 09:00 UTC)

> list
trig_01ABC...   Daily PR Review                weekdays 09:00 UTC   enabled
trig_01XYZ...   Alert Triage Responder         API trigger          enabled

> diff personal/oslo-apartment-hunter.md
in sync

> run trig_01ABC...
Started session: https://claude.ai/code/routines/trig_01ABC...
```

## Skills

| Skill | What it does |
|---|---|
| `deploy` | Smart router: create or update based on `trigger_id` |
| `create` | Strict create (no `trigger_id` in file) |
| `update` | Strict update with read-modify-write safety |
| `list` | Show every routine on your account |
| `get` | Fetch one routine to a local `.md` |
| `pull` | Fetch every routine to local `.md` files |
| `run` | Fire a routine now, bypassing schedule |
| `validate` | Lint a file against the schema |
| `diff` | Compare local file to cloud state |
| `dry-run` | Preview the API body without sending |
| `orphans` | Local files whose `trigger_id` is gone from cloud |
| `bulk` | Any op across many files |
| `delete` | Redirects to the web UI (no DELETE API) |

## Caveats

- **The management API is undocumented.** Endpoints (`/v1/code/triggers`) are reverse-engineered; may change.
- **No DELETE.** Use the [web UI](https://claude.ai/code/routines).
- **`update` safety gotcha.** A partial `job_config` silently expands `allowed_tools` to a 19-tool default. The `update` skill prevents this via mandatory read-modify-write; anyone calling the API directly should be aware.

Reference docs, design specs, and demo recordings preserved under `docs/`. Three reference routines under `examples/`.

## License & contributing

MIT. PRs welcome. Skills live in `skills/<name>/SKILL.md`.
