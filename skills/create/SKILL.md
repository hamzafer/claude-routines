---
name: create
description: Create a new Claude Code routine from a local .md file. Invoke when the user says "create <file>" or when called as a sub-skill of deploy. The file's frontmatter must NOT contain a trigger_id.
---

# claude-routines:create

Create a new routine from a local `.md` file. Strict create: the file must NOT have a `trigger_id` in its frontmatter. (If it does, route to `update` instead.)

## Frontmatter spec

```yaml
---
name: "Display name"          # required
cron: "0 8 * * *"             # UTC; OR run_once_at: "2027-01-01T00:00:00Z" (exactly one)
enabled: true                 # default true
env_id: env_01...             # required; cloud environment ID
model: claude-sonnet-4-6      # optional; one of claude-opus-4-7, claude-opus-4-7[1m], claude-sonnet-4-6, claude-haiku-4-5
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, WebFetch, WebSearch]
sources:                      # optional; repos cloned at session start
  - url: https://github.com/owner/repo
    allow_unrestricted_git_push: false
mcp_connections:              # optional
  - connector_uuid: <v4 uuid>
    name: <name>
    url: <url>
    permitted_tools: []
---

(prompt body sent verbatim as the routine's user message)
```

## Procedure

1. Parse YAML frontmatter and body from the file.
2. If `trigger_id` is present, abort and tell the user to use `update` (or `deploy`, which routes automatically).
3. Run snippet expansion on the body (see below) if any `{{include <path>}}` directives appear.
4. Build the API body:

```jsonc
{
  "name": "<frontmatter.name>",
  "cron_expression": "<frontmatter.cron>",     // OR "run_once_at": ...
  "enabled": <frontmatter.enabled ?? true>,
  "job_config": {
    "ccr": {
      "environment_id": "<frontmatter.env_id>",
      "events": [{
        "data": {
          "uuid": "<generated lowercase v4 uuid>",
          "session_id": "",
          "type": "user",
          "parent_tool_use_id": null,
          "message": { "content": "<expanded prompt body>", "role": "user" }
        }
      }],
      "session_context": {
        "allowed_tools": <frontmatter.allowed_tools>,
        "model": "<frontmatter.model>",         // omit if not in frontmatter
        "sources": <frontmatter.sources>        // omit if not in frontmatter
      }
    }
  },
  "mcp_connections": <frontmatter.mcp_connections>  // omit if not in frontmatter
}
```

5. Call `RemoteTrigger` with `action: "create"` and the body.
6. On success, write the returned `trigger_id` into the file's frontmatter (add a `trigger_id:` line at the top of the frontmatter block).
7. Tell the user: routine name + URL `https://claude.ai/code/routines/<trigger_id>` + next run time.

## Snippet expansion (optional)

A line containing only `{{include <path>}}` expands to the contents of that file before the body is sent.

- Path resolution: relative to the routine `.md` file's directory; or relative to the workspace root if that fails.
- No nesting: included files must NOT contain their own `{{include}}` directives.
- If a path doesn't resolve, abort and tell the user which include is broken.
- The cloud sees the fully-expanded body. Includes are a write-side feature only.

## Model field placement on CREATE

The `model` field goes inside `job_config.ccr.session_context.model` for CREATE bodies. This is different from UPDATE (where it sits at the top level of the partial-update body). See the `update` skill for the update-side quirk.

## Common errors (surface verbatim)

- `cron interval too short`: Cron must run no more than once per hour. Suggest a less frequent schedule.
- `conflicting fields` (cron + run_once_at): Set exactly one.
- `environment_id` not found: The env doesn't exist or doesn't belong to this account.

## See also

- `deploy <file>` to route automatically (create or update based on trigger_id presence)
- `validate <file>` to lint before creating
- `dry-run deploy <file>` to preview the body
