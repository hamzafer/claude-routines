# Repo structure

```
claude-routines/                      # public, MIT
├── CLAUDE.md                         # the operational instructions for Claude Code (form A's "executable")
├── README.md                         # public-facing positioning, install, quickstart, limitations
├── LICENSE                           # MIT
├── .gitignore                        # excludes personal/ + .DS_Store + .playwright-mcp/ etc.
├── routines/                         # generic example routines, anyone can copy
│   ├── pr-reviewer.md
│   ├── alert-triage.md
│   └── docs-drift.md
├── personal/                         # GITIGNORED — users put their real routines here
│   ├── README.md                     # explains the convention; this file IS committed
│   └── (user's .md files)            # everything else here is local-only
├── docs/
│   ├── reference.md                  # frontmatter + commands + errors quick reference (user-facing)
│   ├── migration-from-web.md         # for users with existing routines on claude.ai/code
│   ├── superpowers/specs/            # design history (this directory)
│   └── verification/                 # empirical API verification (this directory)
├── .githooks/
│   └── pre-commit                    # blocks staging files in personal/
└── scripts/
    └── install-hooks.sh              # one-time: `git config core.hooksPath .githooks`
```

## The `personal/` convention

Every user has personal routines they don't want to publish (API keys baked into prompts, personal preferences, etc.). The convention:

- `personal/` is in `.gitignore` (everything except `personal/README.md`, which is committed and explains the convention).
- The root CLAUDE.md tells Claude Code that `.md` files in `personal/` are valid routines (same operations apply), they just don't get pushed.
- A pre-commit hook in `.githooks/pre-commit` rejects any `git commit` that has `personal/<anything-not-README>.md` staged. Belt-and-suspenders against the one-bad-`git-add-A` failure mode.

Users opt into the hook by running `scripts/install-hooks.sh` once after cloning (sets `git config core.hooksPath .githooks`).

## Why `personal/README.md` is committed

- Users who clone see what `personal/` is for without having to read the root README.
- Git keeps the directory present in the repo (otherwise empty `personal/` wouldn't survive a clone).
- The README explains: "Drop your routine `.md` files here. This directory is gitignored except for this file. Run `scripts/install-hooks.sh` once to enable the safety hook."

## Out of scope for v0.1 directory

`plugin/` directory and `snippets/` directory are deferred to v0.2.
