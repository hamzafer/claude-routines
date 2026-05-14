---
name: bulk
description: Apply an operation across many routine .md files at once. Invoke when the user says "deploy all", "deploy everything in <dir>", "validate all", "diff all", "dry-run all", or "set enabled:false on all in <dir>".
---

# claude-routines:bulk

Fan out an operation across multiple files. Reports per-file status, stops on hard failures, continues on per-file 4xx.

## Common bulk requests

| Phrasing | Action |
|---|---|
| "deploy all" or "deploy everything" | Iterate `routines/**/*.md` (and any other configured location), run `deploy` on each |
| "deploy <dir>/" or "deploy everything in <dir>" | Iterate `<dir>/**/*.md` |
| "deploy all routines using <snippet-path>" | Grep for the include directive across `.md` files; deploy each match |
| "set enabled:false on all in <dir>" | Edit each file's frontmatter (set `enabled: false`), then deploy each |
| "validate all" | Run `validate` on every `.md` file in known routine locations |
| "diff all" | Run `diff` on every file with a `trigger_id` |
| "dry-run all" or "preview deploy all" | Same fanout as deploy, but no API writes |

## Output format

One line per file with status. Examples:

```
OK   routines/morning-brain-digest.md      (updated; cron unchanged, prompt +18 chars)
OK   routines/norway-news-digest.md        (created; trigger_id trig_01ABC...)
SKIP routines/draft-experimental.md        (validate failed: missing env_id)
ERR  routines/oslo-apartment-hunter.md     (HTTP 400: cron interval too short)
OK   personal/finn-tesla-scan.md           (no change)

5 files: 3 OK, 1 skipped, 1 error.
```

## Behavior on errors

- **Stop the entire bulk on hard failures** (HTTP 5xx, auth failure, file-system error). Report what's done, what failed, and abort.
- **Continue on per-file 4xx** (validation error, cron interval too short, etc.). Skip that file, log the reason, move on.
- **Always validate before deploying.** A single invalid file should NOT abort the whole bulk; just report and skip.

## Bulk dry-run

For `dry-run deploy all` or `preview deploy all`: same fan-out, but no API write calls. Per-file output shows which operation each would be (CREATE vs UPDATE) and which fields would change.

## See also

- `deploy <file>` for one routine at a time
- `validate <file>` to check one routine
- `diff <file>` to compare one routine
