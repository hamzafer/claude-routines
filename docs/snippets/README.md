# `snippets/` — shareable prompt fragments

This directory holds reusable prompt fragments that any routine can include with the `{{include path/to/snippet.md}}` directive.

## How it works

In a routine's prompt body, write:

```
... rest of your prompt ...

{{include snippets/session-link.md}}
```

When `claude-routines` deploys the routine, it expands the include client-side before sending to the API. The cloud session sees the fully-expanded prompt; the local file stays compact.

## Caveats

- **Pull does not re-snippet.** When you `pull` a routine from the cloud, you get the expanded body — the include reference is gone. If you re-deploy without re-adding the include, the snippet relationship is lost. Treat snippets as a write-side optimization, not a round-trip-stable feature.
- **Path is relative to the repo root.** `{{include snippets/foo.md}}` resolves to `<repo>/snippets/foo.md`. Same path syntax for personal snippets: `{{include personal/snippets/foo.md}}`.
- **Snippet files have no YAML frontmatter.** They're pure prompt text. The first character is the first character that gets inlined.
- **Includes don't nest.** A snippet file can't include another snippet file. v0.2 keeps it flat.
- **Missing snippet = deploy fails.** If the path doesn't resolve, the deploy aborts before calling the API.

## Public vs personal snippets

- `snippets/` (this directory) — committed, shareable across teams or via PRs.
- `personal/snippets/` — gitignored, your private snippet library.

The directive syntax is the same regardless; only the path differs.

## Examples

- [`session-link.md`](session-link.md) — one-line footer pointing at the cloud session URL.
