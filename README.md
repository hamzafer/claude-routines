# claude-routines

> Cron jobs for Claude Code, managed as `.md` files. Edit, commit, ask Claude to deploy.

[![skills.sh](https://skills.sh/b/hamzafer/claude-routines)](https://skills.sh/hamzafer/claude-routines)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-D4A027.svg)](https://code.claude.com)

## Install

In any Claude Code session:

```
/plugin marketplace add hamzafer/claude-routines
/plugin install routines@claude-routines
```

That's it. Type `/routines:list` or just say "list my routines".

## See it

```console
$ deploy routines/daily-pr-review.md
Created trig_01ABC... (Daily PR Review, weekdays 09:00 UTC)

$ list
trig_01ABC...   Daily PR Review                weekdays 09:00 UTC   enabled
trig_01XYZ...   Alert Triage Responder         API trigger          enabled

$ diff personal/oslo-apartment-hunter.md
in sync

$ run trig_01ABC...
Started session: https://claude.ai/code/routines/trig_01ABC...
```

A routine is one `.md` file. Frontmatter sets schedule and permissions; body is the prompt that runs.

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

## Skills

- **Read state:** `list`, `get`, `pull`, `diff`, `orphans`
- **Write changes:** `deploy` (auto-routes), `create`, `update` (read-modify-write safe)
- **Pre-flight:** `validate`, `dry-run`
- **Other:** `run`, `bulk`, `delete`

Each activates by intent (`"validate this file"`) or by name (`/routines:validate <file>`).

## Caveats

- **Reverse-engineered.** The management API isn't public. Endpoints (`/v1/code/triggers`) may change.
- **No DELETE.** Use the [web UI](https://claude.ai/code/routines).
- **`update` enforces read-modify-write.** A partial `job_config` silently expands `allowed_tools` to a 19-tool default. If you call the API directly, beware.

## Also

- [`examples/`](examples): three reference routines to copy from
- [`docs/`](docs): design specs, demo recordings, API verification notes
- [`skills/<name>/SKILL.md`](skills): the actual skill bodies

Cross-agent install via `npx skills add hamzafer/claude-routines` is supported for [skills.sh](https://skills.sh/hamzafer/claude-routines) discoverability, but the skills call Claude Code's `RemoteTrigger` tool at runtime, so they only function in Claude Code.

## License

MIT. PRs welcome.
