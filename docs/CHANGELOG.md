# Changelog

All notable changes to `claude-routines`. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [v0.2] — 2026-04-26

Snippets, validate, diff, bulk operations. Same-day v0.1.

### Added

- **`{{include path/to/snippet.md}}` directive** in routine prompt bodies. Includes are expanded client-side at deploy time; the cloud only ever sees the fully-expanded prompt.
  - New top-level `snippets/` directory for shareable fragments.
  - `personal/snippets/` (gitignored under existing `personal/` rule) for private fragments.
  - Documented in [`snippets/README.md`](snippets/README.md) including the pull-doesn't-re-snippet caveat.

- **`validate` operation** — pure-local lint against the schema:
  - Required-fields check (`name`, `env_id`, exactly one of `cron`/`run_once_at`).
  - Cron 1h-min rule.
  - `run_once_at` future-RFC3339 check.
  - `model` enum (Opus 4.7 / Opus 4.7 [1m] / Sonnet 4.6 / Haiku 4.5).
  - **Loud warning** when `allowed_tools` matches the silent-default-expansion footprint (Bash + Write + Edit + NotebookEdit all present).
  - `validate` on its own = bulk lint of `routines/` and `personal/`.

- **`diff` operation** — semantic field-aware compare between local routine `.md` and cloud state. Skips read-only fields. Reports added/removed list entries. For prompt body, shows a unified-style diff with character-count delta. `diff all` for the full sweep.

- **Bulk operations** — `deploy all`, `deploy <dir>/`, `deploy all routines using <snippet>`. Validates each file first; 4xx-per-file failures are reported and skipped, 5xx aborts.

### Changed

- README badge bumped from `v0.1` to `v0.2` and recoloured to green.
- Status table marks v0.2 as shipped (same day as v0.1).
- Quickstart bullets in README expanded with the four new commands.

### Removed (from roadmap, not from code)

- **Form C plugin** (`/routine deploy` slash commands) was on the v0.2 roadmap. Dropped because it would re-skin Anthropic's `/schedule` command without adding capability — exactly the "competing with Anthropic" thing this project explicitly avoids. Spec docs and roadmap updated to reflect this. CLAUDE.md handles file-based operations conversationally; no slash command layer needed.

## [v0.1] — 2026-04-26

Initial public release.

### Added

- **Form A — fork-as-starter.** Single repo with `.md` routine files. CLAUDE.md is the operational instruction surface for Claude Code. No executable code; Claude Code IS the CLI.
- **Six operations:** `list`, `get`, `pull`, `create`, `update`, `run`.
- **Frontmatter spec** with `trigger_id`, `name`, `cron`/`run_once_at`, `enabled`, `env_id`, `model`, `allowed_tools`, `sources`, `mcp_connections`.
- **Read-modify-write protocol** for `update` — mandatory because the management API silently expands `allowed_tools` to a 19-tool default set when nested fields are omitted.
- **`{{ clear_mcp_connections: true }}` translation** — sending `mcp_connections: []` is a no-op at the API layer; we translate empty lists to the proper clear flag.
- **`personal/` convention** with `.gitignore` rule and pre-commit hook to prevent accidental commits of personal routines.
- **Three example routines** in `routines/` (PR reviewer, alert triage, docs drift) using Anthropic's documented Routines use cases.
- **Empirical verification doc** ([`docs/verification/2026-04-26-routines-api-experiments.md`](docs/verification/2026-04-26-routines-api-experiments.md)) with 16 experiments documenting every API behavior we depend on. Includes findings the official docs miss (e.g. Issue events as a third GitHub event category).

### Known limitations

- No `delete` (web UI only — the management API doesn't expose it).
- GitHub event triggers and API trigger tokens are web-UI-only at the management API layer.
- Env vars are not real secrets (visible to anyone with edit access to the cloud env).
- The management API itself is undocumented; only `/fire` is in Anthropic's public docs.

[v0.2]: https://github.com/hamzafer/claude-routines/releases/tag/v0.2
[v0.1]: https://github.com/hamzafer/claude-routines/releases/tag/v0.1
