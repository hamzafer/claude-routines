# claude-routines

**Manage Claude Code Routines as code.** Fork this repo, edit `.md` files, ask Claude to deploy them. No CLI to install, no tokens to manage — Claude Code IS the CLI.

## What this is

[Claude Code Routines](https://code.claude.com/docs/en/routines) (research preview, shipped 2026-04-14) let you save Claude Code configurations — prompt + repos + connectors + triggers — that run on Anthropic-managed cloud infrastructure. They're managed via the web UI at [claude.ai/code/routines](https://claude.ai/code/routines), the desktop app, or the CLI's `/schedule` command.

What none of those surfaces support: managing routines **as code in a repository**. No fork-and-edit, no version history for prompts, no PR review, no shared library. This repo fills that gap.

> **Why not another "claude-routines" repo?** Existing repos with this name are prompt-template libraries (copy-paste flow) or wrappers around the public `/fire` endpoint. None manage the routine resource itself. This one does — it CRUDs the routine via Claude Code's in-process `RemoteTrigger` skill.

## How it works

A routine is one `.md` file: YAML frontmatter for the config, markdown body for the prompt. Claude Code reads the file and calls the management API.

```yaml
---
name: "Daily PR Review"
cron: "0 9 * * 1-5"          # Mon–Fri, 9am UTC
env_id: env_01ABC...
allowed_tools: [Bash, Read, Edit, Grep, WebFetch]
sources:
  - url: https://github.com/your/repo
    allow_unrestricted_git_push: false
---

Review every PR opened in the last 24h. For each, leave inline comments...
```

Then in Claude Code:

```
> deploy routines/daily-pr-review.md
```

Claude reads the file, builds the API body, fires `RemoteTrigger.create`. On the next push, presence of `trigger_id` in the frontmatter makes it an update.

## Quickstart

```bash
git clone https://github.com/hamzafer/claude-routines my-routines
cd my-routines
./scripts/install-hooks.sh        # one-time: enables the pre-commit safety hook
claude                            # opens Claude Code in this repo
```

Then ask Claude:

- `pull` — import all your existing routines from claude.ai into `routines/`
- `deploy routines/daily-pr-review.md` — push a routine to the cloud
- `list` — show all routines on your account
- `run trig_01ABC...` — fire a routine now

The full operations reference is at [`docs/reference.md`](docs/reference.md).

## Personal vs. shareable routines

- `routines/` — generic templates anyone can copy. Committed to git.
- `personal/` — your real routines with your specific prompts/cron/env IDs. **Gitignored**, except for `personal/README.md`.

The pre-commit hook (`.githooks/pre-commit`) blocks any commit that stages a file under `personal/` (other than its README). Install it once with `./scripts/install-hooks.sh`.

If you want a single repo for everything, that's it. If you want a fully separate private repo for personal routines, fork this one as private and edit `routines/` directly.

## Important caveats

This is a community framework, not an Anthropic product. Read these before relying on it:

1. **The management API we use is undocumented.** Only the public `/fire` endpoint is in [Anthropic's official docs](https://code.claude.com/docs/en/routines). The endpoints `claude-routines` calls (`/v1/code/triggers`) are reverse-engineered from Claude Code's in-process `RemoteTrigger` skill. Anthropic may change them.

2. **Anthropic may ship official tooling.** When they do, this repo deprecates gracefully.

3. **Env vars are not real secrets.** Cloud-environment env vars are stored as plain text and visible to anyone with edit access to the environment. Don't put production credentials there.

4. **`update` has a security gotcha** — sending a partial `job_config` silently expands `allowed_tools` to a maximally-permissive 19-tool default set including Bash/Write/Edit. `claude-routines` solves this via mandatory read-modify-write. Anyone calling the API directly with curl should be aware.

5. **No DELETE via API.** The management API doesn't expose deletion. Delete routines via the web UI at [claude.ai/code/routines](https://claude.ai/code/routines).

6. **GitHub event triggers and API tokens are web-UI-only.** `claude-routines` preserves them on round-trip but cannot create or modify them.

Full risk list in [`docs/superpowers/specs/2026-04-26-claude-routines/09-risks.md`](docs/superpowers/specs/2026-04-26-claude-routines/09-risks.md).

## Status

**v0.1**: Form A (fork-as-starter), six operations, three example routines. Today, 2026-04-26.

**v0.2**: Form C plugin (`claude plugins add claude-routines`, slash commands). Soon.

**v0.3+**: validate, diff, list --orphans. Later.

## License

MIT. See [LICENSE](LICENSE).

## Contributing

PRs welcome — especially if you discover an undocumented API behavior we missed. The empirical verification record is at [`docs/verification/2026-04-26-routines-api-experiments.md`](docs/verification/2026-04-26-routines-api-experiments.md). Add to it.
