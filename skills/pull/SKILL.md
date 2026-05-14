---
name: pull
description: Fetch all Claude Code routines from the cloud and write each one to a local .md file. Invoke when the user says "pull", "pull all", "sync from cloud", or asks to download everything to local files.
---

# claude-routines:pull

Mirror the cloud to local `.md` files. Useful for a fresh checkout or to recover after a local file loss.

## Procedure

1. Call `RemoteTrigger` with `action: "list"`.
2. For each trigger in the response, invoke the `get` skill's procedure: fetch by `trigger_id`, strip read-only fields, build YAML frontmatter, write to `routines/<kebab-case-slug>.md`.
3. If a local file with the same slug already exists, overwrite it (the cloud is the source of truth for `pull`).
4. Report a summary: `Pulled N routines. Wrote to routines/.`

## Default destination

Default write location is `routines/<slug>.md`. If the user has a different convention (e.g., grouping by project under `routines/<project>/<slug>.md`), ask before writing, or use whatever pattern existed before.

## Pull caveat

The cloud sees the FULLY EXPANDED prompt body. If a routine was originally deployed using `{{include <path>}}` directives, the expanded version is what gets written locally. The original snippet structure is lost. The user accepts this tradeoff.

## Common errors

- HTTP 401: token expired. Re-authenticate.
- Partial failures (one routine 404s mid-pull): continue with the rest and report which failed.

## See also

- `get <trigger_id>` to pull just one routine
- `orphans` to identify local files no longer in the cloud (the reverse direction)
