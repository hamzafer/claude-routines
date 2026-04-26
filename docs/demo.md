# Demo

The README's animated GIF is recorded with [`vhs`](https://github.com/charmbracelet/vhs) — a tiny tool that turns a script into a terminal GIF. The script lives at [`docs/demo.tape`](demo.tape).

## Regenerating the GIF

```bash
brew install vhs       # macOS — see vhs docs for other platforms
vhs docs/demo.tape     # produces docs/demo.gif
```

The tape drives a **real** `claude` session in this repo, so the recording reflects whatever the framework actually does at the time it runs. If you change CLAUDE.md or refactor a routine, just re-run the command and commit the new GIF.

## What the demo covers

Six lines, ~30 seconds:

1. `ls personal/` — show the local routine library
2. `head -20 personal/oslo-apartment-hunter.md` — one real frontmatter + prompt body
3. `claude` — drop into Claude Code in the repo
4. `validate` — lint every routine against the schema
5. `diff personal/oslo-apartment-hunter.md` — confirm local matches cloud
6. `Ctrl+D` — exit

## Why a terminal GIF, not a polished video

Terminal recordings dominate OSS READMEs because they show the actual thing working. They're tiny (~200KB), authentic, and autoplay on GitHub.

For a launch-quality marketing video — split-screen, annotations, motion graphics — see the `docs/launch-video/` directory (TBD; will be Remotion-based).
