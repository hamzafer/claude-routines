---
name: diff
description: Compare a local routine .md file against its cloud state field by field. Read-only, no API writes. Invoke when the user says "diff <file>", "what's changed in <file>", or wants to preview drift between local and cloud before deploying.
---

# claude-routines:diff

Compare local vs cloud. Useful before `deploy` to see exactly what would change.

## Procedure

1. Parse the file's frontmatter and body. Expand `{{include}}` directives in the body (same as deploy does).
2. Read the file's `trigger_id`. If absent, abort with: `"no trigger_id in frontmatter; use create first"`.
3. Call `RemoteTrigger` with `action: "get"` and `trigger_id: <id>`.
4. Compare each tracked field. Skip read-only fields entirely.

## Tracked fields (compare and report differences)

- `name` (string equality)
- `cron_expression` or `run_once_at` (string equality on whichever is populated)
- `enabled` (bool equality)
- `job_config.ccr.environment_id` (string equality)
- `job_config.ccr.session_context.model` (string equality; treat absent on either side as equal)
- `job_config.ccr.session_context.allowed_tools` (set comparison; report added/removed individually)
- `job_config.ccr.session_context.sources` (list of objects; compare by `url`)
- `mcp_connections` (list of objects; compare by `connector_uuid`)
- Prompt body (compare file's expanded body against `job_config.ccr.events[0].data.message.content`)

## Read-only fields to skip

`created_at`, `updated_at`, `next_run_at`, `creator`, `ended_reason`, `api_token_hint`, `persist_session`, `enabled_plugins`, `extra_marketplaces`, `outcomes`, `last_fired_at`.

## Output format

```
trig_01ABC...  Norway News Digest

  cron:           "0 7 * * *"  ->  "0 8 * * *"
  allowed_tools:  +Bash  -KillBash
  prompt:         3 lines changed (+42 chars)

  ---  Send a Norway news digest with ONLY NEW stories...
  +++  Send a Norway news digest from the last 24 hours...

3 fields differ.
```

If everything matches:

```
trig_01ABC...  Norway News Digest
in sync.
```

## Whitespace handling

Trailing whitespace and trailing newlines are sometimes added or stripped by Anthropic's normalization. Report these as a special note: `prompt: trailing whitespace differs (semantically identical)`. Don't show this as a hard difference.

## Note on the model field

The API GET response does NOT echo the `model` field even when it's set. If your local file has `model: claude-opus-4-7` but the cloud response shows no model, treat this as `unknown - cannot verify`. Don't report it as a diff. (Verified 2026-05-14.)

## Bulk diff

For `diff all`, see the `bulk` skill.

## See also

- `dry-run deploy <file>` to see the exact body that would be sent on deploy
- `deploy <file>` to apply the changes after reviewing the diff
