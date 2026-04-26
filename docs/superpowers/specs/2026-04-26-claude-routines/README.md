# claude-routines — design spec (v0.1)

Date: 2026-04-26
Status: ready for implementation

## Index

1. [Overview](00-overview.md) — problem, positioning, architecture
2. [Frontmatter format](01-frontmatter.md) — the YAML schema for a routine `.md` file
3. [Operations](02-operations.md) — `list`, `get`, `pull`, `create`, `update`, `run`
4. [Update safety](03-update-safety.md) — why read-modify-write is mandatory
5. [MCP connections semantics](04-mcp-and-clear.md) — the `clear_mcp_connections` flag
6. [CLAUDE.md flow](05-claude-md-flow.md) — how Claude Code is the CLI
7. [Repo structure](06-repo-structure.md) — file layout, gitignore, hooks
8. [Out of scope](07-out-of-scope.md) — what v0.1 deliberately doesn't cover
9. [Roadmap](08-roadmap.md) — v0.1, v0.2, v0.3+
10. [Risks](09-risks.md) — caveats to surface in the README

Empirical verification of every claim in these specs lives in `docs/verification/2026-04-26-routines-api-experiments.md`.
