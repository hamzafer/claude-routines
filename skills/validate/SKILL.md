---
name: validate
description: Validate a routine .md file's structure without calling the API. Checks frontmatter, cron schedule rules, model field, allowed_tools, sources, mcp_connections, and prompt body. Invoke when the user says "validate <file>", "lint <file>", or "validate" (no file = validate everything in the workspace).
---

# claude-routines:validate

Lint a routine file before deploying. Never calls the API. Run this whenever you're about to `deploy`.

## Per-file checks

Run these in order. Stop the file at the first error; collect all warnings.

### 1. Frontmatter parses

Must be valid YAML between the opening and closing `---`. If parsing fails, report the YAML error and stop.

### 2. Required fields

- `name` (string, non-empty)
- `env_id` (string starting with `env_`)
- Exactly one of `cron` (string) or `run_once_at` (RFC3339 UTC timestamp). Both present is an error (`conflicting fields`). Neither present is an error (`missing trigger`).

### 3. Cron rules

When `cron` is set:

- Standard 5-field cron in UTC.
- Minimum interval is 1 hour. The minute field must be a single literal value (e.g. `0` or `30`). Reject patterns like `*/30 * * * *` or comma-lists like `0,30 * * * *` (under 1h gap).
- Hour field may use lists or ranges; that's fine since gaps are at least 1h.

### 4. run_once_at rules

Must be a future RFC3339 UTC timestamp like `2027-01-01T00:00:00Z`. Past timestamps are a warning (the API still accepts them; they fire immediately).

### 5. enabled

Must be a bool if present. Default `true`.

### 6. model

If set, must be one of: `claude-opus-4-7`, `claude-opus-4-7[1m]`, `claude-sonnet-4-6`, `claude-haiku-4-5`. Anything else is an error.

### 7. allowed_tools

Must be a list of strings. Warn if empty (inherits nothing). Warn loudly if it contains every default write-tool (`Bash`, `Write`, `Edit`, `NotebookEdit` all present): that's the silent-expansion default-set; suggest an explicit trim.

### 8. sources

If present, must be a list of objects with `url` (string starting `https://github.com/`) and optional `allow_unrestricted_git_push` (bool).

### 9. mcp_connections

If present, must be a list of objects with `connector_uuid` (lowercase v4 UUID), `name`, `url`, and optional `permitted_tools`.

### 10. Snippet includes (optional feature)

If the prompt body contains `{{include <path>}}` lines: the file at `<path>` must exist relative to the routine file's directory or the workspace root. Included files must NOT themselves contain `{{include}}` directives (no nesting).

### 11. Prompt body

Must be non-empty after stripping whitespace.

## Output format

```
OK   personal/morning-brain-digest.md
ERR  personal/oslo-apartment-hunter.md
  - error: cron "*/30 * * * *" violates minimum 1-hour interval
  - warning: allowed_tools includes Bash, Write, Edit, NotebookEdit (full default-set). Consider trimming.
```

When called without a file argument, validate every `.md` file under common routine locations (`routines/`, `personal/`, or anywhere with frontmatter). Skip READMEs. Print a one-line summary per file.

Final line: `N files OK | M files with errors | W warnings`.

## See also

- `dry-run deploy <file>` to preview the API payload after validation passes
- `deploy <file>` to actually ship
