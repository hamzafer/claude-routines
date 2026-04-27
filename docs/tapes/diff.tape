Output docs/gifs/diff.gif

Set Shell "bash"
Set FontSize 14
Set Width 1280
Set Height 720
Set Theme "Dracula"
Set TypingSpeed 35ms
Set Padding 20

Hide
Type "cd ~/developer/ai/playground/claude-routines"
Enter
Type "clear"
Enter
Show

# Drift Daily Norway Life Hacks cron locally to show diff catching it
Type "/tmp/cr-demo-diff-edit.sh"
Sleep 300ms
Enter
Sleep 1s

Type "claude --dangerously-skip-permissions"
Enter
Sleep 5s

Type "diff personal/daily-norway-life-hacks.md"
Sleep 200ms
Enter
Sleep 60s

Ctrl+D
Sleep 1s
