# Migrating from the web UI

You already have routines on [claude.ai/code/routines](https://claude.ai/code/routines)? Bring them in:

```bash
git clone https://github.com/hamzafer/claude-routines my-routines
cd my-routines
./scripts/install-hooks.sh
claude
> pull
```

Claude calls `RemoteTrigger.list` then `get` for each, writes one `.md` per routine into `routines/`. Filenames are kebab-cased slugs of the routine names.

## What gets pulled

Each `.md` file's frontmatter contains:

- `trigger_id`, `name`
- `cron` or `run_once_at`
- `enabled`
- `env_id`
- `model` (only if explicitly set; otherwise omitted = account default)
- `allowed_tools`
- `sources` (if any)
- `mcp_connections` (if any)

The markdown body is the routine's prompt, exactly as stored.

GitHub event triggers and API trigger tokens are stored on the routine but managed only via the web UI. They round-trip on `update` (we preserve them via read-modify-write) but you can't edit them through `claude-routines`.

## Sensitive routines

If your routines contain prompts with personal info (your apartment criteria, your shopping list, internal company logic), **don't keep them in `routines/`** — that folder is shareable. Move them to `personal/`:

```bash
mv routines/oslo-apartment-hunter.md personal/
```

`personal/` is gitignored. Operations (`deploy`, `update`, `run`) work on files in either folder.

## Round-tripping

You can edit a routine on the web UI, then `pull` again to refresh the local file. The next `deploy` will pick up your local edits and push them. Last-write-wins between the two surfaces — there's no conflict resolution.

## Tip: if cron looks weird

The web UI shows you cron in your local time zone, but stores it in UTC. After `pull`, expect UTC cron expressions. A daily 9am Oslo routine becomes `0 7 * * *` in UTC during summer DST, `0 8 * * *` in winter.

## Tip: connector UUIDs

`pull` writes `connector_uuid` for each MCP connection so a subsequent `deploy` round-trips cleanly. Don't change these UUIDs by hand — they're opaque tokens that the runtime uses to authenticate. Add or remove entries by adding/removing the whole object.
