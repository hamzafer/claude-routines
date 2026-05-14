# CLAUDE.md flow (form A)

The repo's `CLAUDE.md` is the entire executable surface in v0.1. When the user clones the repo and runs `claude` inside it, Claude Code reads CLAUDE.md and follows its instructions for any operation the user asks for in plain English ("deploy this", "list my routines", "run the digest").

## Structure of CLAUDE.md

1. **Purpose** — one paragraph: this repo manages Claude Code routines as code; here's what to do when the user asks for `<operation>`.
2. **Frontmatter spec** — concise version of the schema; full version is in `docs/reference.md`.
3. **Operations** — for each of `list / get / pull / create / update / run`, the exact `RemoteTrigger` call shape and any pre/post processing.
4. **Critical rules** — read-modify-write for `update`; `clear_mcp_connections: true` for empty `mcp_connections`; no DELETE via API.
5. **Error surfacing** — when the API returns a 4xx, surface `error.message` to the user verbatim and stop.
6. **File layout** — where to find routines (`routines/`), where personal stuff lives (`personal/`, gitignored), where the reference doc is (`docs/reference.md`).

## Why CLAUDE.md and not a Python/Node CLI

- Claude Code already has `RemoteTrigger` as a built-in skill (in-process auth, no token leakage).
- A traditional CLI would need to handle OAuth, environment, error formatting — Claude Code has all of that for free.
- "Just write instructions in markdown" is the simpler unit. Updates to the management API surface require updating instructions, not shipping a new CLI version.

## What Claude Code reads vs. user reads

| Reader | Files |
|---|---|
| Claude Code (during a session) | `CLAUDE.md` (root) |
| Users (humans) | `README.md` (root), `docs/reference.md`, `docs/migration-from-web.md` |
| Internal/maintainers | `docs/superpowers/specs/`, `docs/verification/` |

## Failure modes

- **CLAUDE.md drift**: as the management API evolves, CLAUDE.md needs updates. v0.2's plugin form makes this easier (versioned plugin updates). For v0.1, users `git pull` to get fresh instructions.
- **Hallucinated fields**: if Claude reads the .md file and invents a field that's not in the spec, the API rejects it with a 400. The user sees the error verbatim. Acceptable failure mode for v0.1.
