# claude-routines

Manage [Claude Code Routines](https://code.claude.com/docs/en/routines) as code. Edit `.md` files, ask Claude to deploy them. No CLI, no tokens, no boilerplate.

[![skills.sh](https://skills.sh/b/hamzafer/claude-routines)](https://skills.sh/hamzafer/claude-routines)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Built for Claude Code](https://img.shields.io/badge/built%20for-Claude%20Code-D4A027.svg)](https://code.claude.com)

## Install

```bash
npx skills add hamzafer/claude-routines -g
```

That's it. The skills land in `~/.claude/skills/` and Claude Code picks them up on next session. No repo to clone, no working directory to maintain.

## What's a routine

One `.md` file with YAML frontmatter (the config) plus a markdown body (the prompt that runs on schedule):

```yaml
---
name: "Daily PR Review"
cron: "0 9 * * 1-5"          # weekdays, 9am UTC
env_id: env_01ABC...
allowed_tools: [Bash, Read, Edit, Grep, WebFetch]
sources:
  - url: https://github.com/your-org/your-repo
    allow_unrestricted_git_push: false
---

Review every PR opened in the last 24 hours. For each, leave inline comments...
```

## A session

Once the skills are installed, you can say things like:

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

Claude routes to the right skill based on what you ask.

## Skills included

| Skill | What it does |
|---|---|
| `deploy` | Smart router: create or update based on the file's `trigger_id` |
| `create` | Strict create (file must lack `trigger_id`) |
| `update` | Strict update with read-modify-write safety (file must have `trigger_id`) |
| `list` | Show every routine on your account |
| `get` | Fetch one routine and write it to a local `.md` |
| `pull` | Fetch every routine to local `.md` files |
| `run` | Fire a routine immediately, bypassing schedule |
| `validate` | Lint a file (or all files) against the schema |
| `diff` | Compare local file to cloud state |
| `dry-run` | Preview the API body without sending |
| `orphans` | Find local files whose `trigger_id` no longer exists in cloud |
| `bulk` | Apply any operation across many files at once |
| `delete` | Explains there's no delete API and points to the web UI |

## Why

Anthropic's [Routines](https://code.claude.com/docs/en/routines) (research preview, 2026-04-14) run a saved prompt on a schedule, on GitHub events, or via API. You can manage them through the web UI, desktop app, or `/schedule` in the CLI.

None of those let you keep routines as code. No fork-and-edit, no version history, no PR review, no bulk ops, no diff between local and cloud.

These skills fill that gap. Each routine is one `.md` file with YAML config and a prompt body. Claude reads the file and calls the management API.

Use `/schedule` for quick conversational changes. Use these skills when you want to **version, review, share, or bulk-edit**.

## Examples

The `examples/` folder has three reference routines you can copy and adapt:

- `examples/alert-triage.md` (API-triggered incident responder)
- `examples/docs-drift.md` (weekly docs-vs-code consistency check)
- `examples/pr-reviewer.md` (daily PR review at 9am)

These are not installed by `npx skills add`. They live in the repo for browsing and copying.

## Legacy documentation

The `docs/` folder preserves the original reference material from when this project shipped as a clone-and-fork template (pre-skills version):

- `docs/CLAUDE.md` is the original operating manual (now distributed across the `skills/` folder, kept for reference).
- `docs/reference.md`, `docs/features.md`, `docs/migration-from-web.md` are user-facing guides.
- `docs/gifs/` and `docs/tapes/` are the recorded `vhs` demos showing each operation. The flows shown there reflect the old "clone the repo" workflow and will need re-recording for the new `npx skills add` model; kept for now as a snapshot of how things looked.
- `docs/superpowers/specs/2026-04-26-claude-routines/` is the original design spec and rationale.
- `docs/verification/2026-04-26-routines-api-experiments.md` is the empirical record of every API behavior we depend on.
- `docs/snippets/` shows the optional `{{include <path>}}` snippet feature still supported by the `create` and `update` skills.
- `docs/CHANGELOG.md` is the pre-skills release log.

If you're using the skills, you don't need any of this. If you're contributing or want to understand the design choices, start with `docs/superpowers/specs/2026-04-26-claude-routines/00-overview.md`.

## Caveats

- **The management API is undocumented.** Only `/fire` is in [Anthropic's docs](https://code.claude.com/docs/en/routines). The endpoints these skills call (`/v1/code/triggers`) are reverse-engineered. They may change.
- **Anthropic may ship official tooling.** When they do, these skills deprecate gracefully.
- **Env vars are not real secrets.** Visible to anyone with edit access on the environment.
- **`update` has a safety gotcha.** A partial `job_config` silently expands `allowed_tools` to a 19-tool default set. The `update` skill prevents this via mandatory read-modify-write. Anyone calling the API directly should be aware.
- **No DELETE via API.** Use the [web UI](https://claude.ai/code/routines).
- **GitHub triggers and API tokens are web-UI-only.** These skills preserve them on round-trip but can't create or modify them.
- **`model` field is asymmetric.** On UPDATE the field sits at the top level of the body; on CREATE it sits inside `job_config.ccr.session_context.model`. The GET response does not echo `model` at all; the web UI is the only reliable visual check.

## Migrating from the older fork-the-repo workflow

Earlier versions of this project were a template you cloned and consumed. That model is deprecated. If you have an old clone:

1. Save your routine `.md` files somewhere (they're just markdown, fully portable).
2. Install the skills: `npx skills add hamzafer/claude-routines -g`.
3. Delete the old clone.
4. Keep your routine files wherever you like; the skills work from any path.

## License

MIT. See [LICENSE](LICENSE).

## Contributing

PRs welcome. The skills are in `skills/<name>/SKILL.md`; each one is self-contained. Examples live under `examples/`.
