# Out of scope for v0.1

Calling these out so the README and CLAUDE.md don't promise them.

## Operations

- **`delete`** — the management API doesn't expose deletion. Users delete via web UI at `claude.ai/code/routines`. v0.3+ may add `claude-routines list --orphans` (lists local files whose `trigger_id` no longer exists in cloud).
- **`validate`** — offline frontmatter linting (cron 1h-min, mutual exclusion of cron/run_once_at, required fields). v0.3+.
- **`diff`** — semantic compare between local file and cloud state, accounting for fields Anthropic normalizes on round-trip. v0.2.

## Trigger types

- **GitHub event triggers** — adding, editing, removing webhooks. The web UI exposes three event categories (Pull request, Release, Issue) with rich filters; the management API silently drops the corresponding fields. Web-UI-only at the API layer. Round-trips on `pull`/`update` for routines that already have them, but cannot be created via `claude-routines`.
- **API trigger token management** — generate, rotate, revoke. The token-mint endpoint is not in the management API surface. Web-UI only.

## Resources outside the routine

- **Environment management** — create, edit, archive cloud environments (`claude.ai/code` → env selector → gear). Not in management API.
- **Account-level connector registration** — adding a new MCP connector to the user's account (`claude.ai/settings/connectors`). The management API will accept any UUID/URL pair on a routine, but it doesn't appear in the user's account-level Connectors list.
- **GitHub App installation** — required for GitHub event webhooks. Github-side concern, not routine config.
- **Secrets/env-var management** — there is no real secrets store. Env vars in cloud envs are visible to anyone with edit access. Document in README; don't pretend otherwise.

## Form C (plugin)

`.claude-plugin/plugin.json`, slash commands like `/routine deploy <file>`. v0.2.

## Body-level features

- **Includes / snippets** (`{{include}}` syntax in the prompt body) — v0.2 if useful in practice.
- **Per-event multi-prompt routines** — the `events[]` array in the schema implies multiple events per routine, but no observed routine uses more than one. v0.1 ships single-event only.

## Multi-account / org support

A routine belongs to a single claude.ai account. v1 is single-account; multi-account ergonomics (env switching, profile selection) is v0.3+.
