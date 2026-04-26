# Overview

## Problem

Anthropic shipped Claude Code Routines on 2026-04-14 — saved Claude Code configurations (prompt + repos + connectors + triggers) that run on Anthropic-managed cloud infrastructure. They're managed via three surfaces: web UI at `claude.ai/code/routines`, the desktop app, and the CLI's `/schedule` command. None of these surfaces support managing routines **as code in a repository**: no fork-and-edit workflow, no version history for prompts, no review process. Existing GitHub repos named "claude-routines" are prompt-template libraries or `/fire`-endpoint wrappers — none manage the routine resource itself.

`claude-routines` fills the gap: a single repo containing routine `.md` files (frontmatter + prompt body) and instructions for Claude Code to read them and call the management API.

## Positioning

Community framework, not a competitor to Anthropic. The README leads with that. When Anthropic ships official tooling, this project either deprecates gracefully or layers on top.

## Architecture

Single consumption form: **fork-as-starter**.

User clones the repo. The repo's `CLAUDE.md` instructs Claude Code on how to read frontmatter, build API call bodies, and invoke the in-process `RemoteTrigger` skill. **No executable code** — `claude-routines` is a CLAUDE.md plus example routines plus a frontmatter spec. Claude Code is the CLI.

```
git clone https://github.com/hamzafer/claude-routines my-routines
cd my-routines
claude
> deploy routines/morning-digest.md
> list
> run trig_01ABC...
```

> **Note:** earlier drafts proposed a v0.2 "Claude Code plugin" form (slash commands like `/routine deploy`). Dropped because it would just re-skin Anthropic's `/schedule` command without adding capability. CLAUDE.md handles file-based operations conversationally; no slash command layer needed. See [roadmap](08-roadmap.md).

## Auth

In-process via Claude Code's `RemoteTrigger` skill. The user is already authenticated to Claude Code; the OAuth token is added inside the skill call and never exposed. No `.env`, no token management, no secrets in the repo.
