# Update safety — why read-modify-write is mandatory

## The trap

The management API treats `job_config` as **replace-not-merge with default expansion**. If you send a `job_config` object that omits any nested field, the missing field is reset to its **platform default** — which for `allowed_tools` is the maximally-permissive 19-tool set including `Bash`, `Write`, `Edit`, `NotebookEdit`, `WebFetch`, `KillBash`, `Skill`, `Tmux`, etc.

A naive "update just the prompt" call that sends only `events[0].data.message.content` inside `job_config` silently grants the routine more privileges than its file says.

## Verified empirically (2026-04-26)

Sent:
```json
{ "job_config": { "ccr": { "environment_id": "...", "events": [...] } } }
```

Got back:
```json
{ "job_config": { "ccr": { "session_context": { "allowed_tools": [
  "preset:default", "Task", "Bash", "Glob", "Grep", "Read", "Edit",
  "MultiEdit", "Write", "NotebookEdit", "WebFetch", "TodoWrite",
  "WebSearch", "BashOutput", "KillBash", "Skill", "Tmux", "Monitor",
  "SendUserFile", "REPL"
] } } } }
```

The original `["Read"]` was overwritten silently. No warning, no error.

Top-level fields (name, cron, enabled, mcp_connections) **do** merge correctly — only `job_config` has this behavior.

## What `claude-routines update` does

```
1. RemoteTrigger.get(trigger_id) → live
2. Drop read-only fields: id, created_at, updated_at, next_run_at, creator, ended_reason, api_token_hint, job_config.ccr.session_context.outcomes
3. Apply file's frontmatter values on top of `live`
4. RemoteTrigger.update(trigger_id, body=merged)
```

This is non-negotiable for v0.1 and forever. Even a "rename only" change goes through the full read-modify-write cycle if it touches `job_config` (renaming via top-level `name` doesn't, so that's the one shortcut).

## What we tell users

CLAUDE.md and `docs/reference.md` document this as the central safety property. Anyone curl-ing the API directly will hit it; we surface the gotcha so others writing tooling don't repeat it.
