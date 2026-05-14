---
name: orphans
description: Find local routine .md files whose trigger_id no longer exists in the cloud (probably deleted via the web UI). Pure-local check after a list. Invoke when the user says "orphans", "find orphans", "list orphans", or asks to find stale local routine files.
---

# claude-routines:orphans

Cross-reference local `.md` routine files against the cloud routine list. Report files whose `trigger_id` is no longer present in the cloud.

## Procedure

1. Call `RemoteTrigger` with `action: "list"`. Build a set of cloud `trigger_id` values.
2. Scan local `.md` files (default search: `routines/**/*.md`, `personal/**/*.md`, or wherever the user keeps them; ask if unsure).
3. For each file, parse the YAML frontmatter and read `trigger_id`. If the value is absent, skip (it hasn't been deployed yet).
4. If `trigger_id` is present but NOT in the cloud set, print: `<file path> -> <trigger_id> (not in cloud)`.
5. End with a count: `N orphans found.`

## Output format

```
personal/old-shopping-list.md      -> trig_01XYZ... (not in cloud)
personal/draft-news-digest.md      -> trig_01ABC... (not in cloud)

2 orphans found.
```

## What NOT to do

- **Don't delete the local files.** The user may want to redeploy them as new routines (which would require stripping the `trigger_id` and using `create`). Deletion is their call.
- Don't call `get` on orphans; the API will 404.

## Note on scope

This is a pure-local check after a single `list`. It does NOT detect routines that exist in the cloud but lack a local file (the reverse direction). For that, see `pull`.

## See also

- `pull` to fetch all cloud routines and write missing ones locally
- `delete` to understand why orphans exist (web-UI delete)
