Output docs/gifs/orphans.gif

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

# Show that there's a local file with a stale trigger_id
Type "ls personal/_demo_orphan.md"
Sleep 400ms
Enter
Sleep 2s

Type "claude --dangerously-skip-permissions"
Enter
Sleep 5s

Type "orphans"
Sleep 200ms
Enter
Sleep 35s

Ctrl+D
Sleep 1s
