# `personal/` — your local routines

Drop your real routine `.md` files here. They are **gitignored** and stay on your machine — they will never be pushed to the public `claude-routines` repo.

## What goes here

Anything you don't want to share publicly:

- Prompts with personal data (your apartment criteria, shopping lists, internal company logic)
- Cron expressions tied to your specific schedule
- Env IDs and connector UUIDs from your account
- Routines that target private repos

## What stays in `routines/`

Generic templates that other people would benefit from. If you write a clean template, contribute it via PR.

## Operations

Operations from CLAUDE.md work on files in either `routines/` or `personal/` — same format, same commands. Ask Claude:

```
> deploy personal/morning-digest.md
> update personal/shoe-deals.md
```

## Safety

The `.gitignore` rules at the repo root exclude everything in `personal/` except this README. To prevent accidents (e.g., `git add -A` while a personal file is unstaged), install the pre-commit hook once after cloning:

```bash
./scripts/install-hooks.sh
```

The hook rejects any commit that has a file under `personal/` (other than this README) staged. If you ever need to bypass it for a one-off reason, use `git commit --no-verify` — but don't make a habit of it.

## First-time setup

```bash
git clone https://github.com/hamzafer/claude-routines my-routines
cd my-routines
./scripts/install-hooks.sh

# Pull your existing routines from claude.ai
claude
> pull

# Move the personal ones out of routines/ into here:
mv routines/your-personal-thing.md personal/
```

Now your personal routines are local-only and the public repo stays clean.
