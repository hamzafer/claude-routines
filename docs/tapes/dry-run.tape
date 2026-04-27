Output docs/gifs/dry-run.gif

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

# Edit AI Conference cron locally so dry-run has something to preview
Type "/tmp/cr-demo-dry-edit.sh"
Sleep 300ms
Enter
Sleep 1s

Type "claude --dangerously-skip-permissions"
Enter
Sleep 5s

Type "dry-run deploy personal/ai-conference-digest.md"
Sleep 200ms
Enter
Sleep 55s

Ctrl+D
Sleep 1s
