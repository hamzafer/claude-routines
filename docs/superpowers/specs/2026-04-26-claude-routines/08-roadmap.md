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

## v0.2 (revised — plugin form dropped)

The Claude Code plugin form (`/routine deploy`, `/routine list`, etc.) was dropped from v0.2. Reason: it would mostly re-skin `/schedule`, which Anthropic already ships. That's exactly the "competing with Anthropic" thing this project explicitly avoids. CLAUDE.md handles file-based operations conversationally — no slash command layer needed.

Real v0.2 ships features `/schedule` doesn't have because it isn't file-based:

- **`validate`** — offline lint before deploy: cron 1h-min, mutual exclusion of cron/run_once_at, required fields, model enum check, allowed_tools sanity. Surface errors locally instead of round-tripping for an HTTP 400.
- **`diff` command** — semantic compare local vs cloud (Anthropic normalizes some fields, so byte-wise diff is noisy). Field-aware comparison.
- **Bulk operations** — "set enabled:false on every routine in personal/" or "change cron to 0 6 * * * on every routine matching <pattern>." Concretely useful for users with many similar routines.
- **`{{include}}` snippets** in prompt bodies — share common blocks (Telegram delivery, error-surfacing rules, common-source clones) across routines. Updates to the snippet propagate to every routine on next deploy.
- More example routines.

## v0.3+

- **`pull --orphans`** — find local files whose `trigger_id` no longer exists in cloud (e.g., deleted via web UI).
- **API-trigger token management** — if Anthropic exposes the schema.
- **GitHub-trigger CRUD** — if Anthropic exposes the schema.
- **Multi-account / profile support**.

## Sunset criteria

When Anthropic ships official routines-as-code tooling, decide one of:

1. Deprecate this repo gracefully (README points to the official tool).
2. Layer on top — keep the parts that aren't redundant.
3. Continue as a niche tool if the official one is missing features users care about.
