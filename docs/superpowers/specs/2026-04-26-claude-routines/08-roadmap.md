# Roadmap

## v0.1 (target: today, 2026-04-26)

- Form A fork-as-starter
- `CLAUDE.md` with the six operations: list, get, pull, create, update, run
- `routines/` with 3 generic examples (PR reviewer, alert triage, docs drift)
- `personal/` convention with `.gitignore` rule and `personal/README.md`
- Pre-commit hook in `.githooks/pre-commit` to block accidental staging
- `docs/reference.md` (user-facing frontmatter + commands quick reference)
- `docs/migration-from-web.md` (how to import existing routines via `pull`)
- README with positioning paragraph that names the gap explicitly
- MIT license
- Public on GitHub at `hamzafer/claude-routines`

## v0.2

- **Form C plugin** — `.claude-plugin/plugin.json` + `commands/` so `claude plugins add claude-routines` exposes `/routine list`, `/routine deploy <file>`, etc.
- **`diff` command** — semantic compare local vs cloud (Anthropic normalizes some fields, so byte-wise diff is noisy).
- **Snippets/includes** in prompt bodies (e.g., the Telegram-card block we want to share across routines).
- More example routines.

## v0.3+

- **`validate`** — offline lint (cron 1h-min, mutual exclusion, required fields, error before round-trip).
- **`list --orphans`** — find local files whose `trigger_id` no longer exists in cloud.
- **API-trigger token management** — if Anthropic exposes the schema.
- **GitHub-trigger CRUD** — if Anthropic exposes the schema.
- **Multi-account / profile support**.

## Sunset criteria

When Anthropic ships official routines-as-code tooling, decide one of:

1. Deprecate this repo gracefully (README points to the official tool).
2. Layer on top — keep the parts that aren't redundant.
3. Continue as a niche tool if the official one is missing features users care about.
