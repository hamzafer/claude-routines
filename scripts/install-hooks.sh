#!/usr/bin/env bash
# claude-routines — install pre-commit hooks
# Run once after cloning to enable the safety hook that prevents personal/ files from being committed.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -d "$REPO_ROOT/.git" ]]; then
  printf 'ERROR: %s is not a git repository. Run this after cloning.\n' "$REPO_ROOT" >&2
  exit 1
fi

# Make hooks executable (in case the bit was lost)
chmod +x "$REPO_ROOT/.githooks/pre-commit"

# Point git at the .githooks directory
git -C "$REPO_ROOT" config core.hooksPath .githooks

printf 'Installed. core.hooksPath set to .githooks\n'
printf 'Pre-commit hook will block staged files under personal/ (except README.md and .gitkeep).\n'
printf 'Bypass with: git commit --no-verify\n'
