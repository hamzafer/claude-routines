Output docs/gifs/pull.gif

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
Sleep 500ms
Show

# Drop into Claude Code
Type "claude --dangerously-skip-permissions"
Enter
Sleep 5s

# Show empty personal/ via shell escape (everything stays inside claude)
Type "!ls personal/"
Sleep 300ms
Enter
Sleep 3s

# Pull all routines from the cloud
Type "pull"
Sleep 200ms
Enter
Sleep 100s

# Show populated personal/ via shell escape
Type "!ls personal/"
Sleep 300ms
Enter
Sleep 3s

Ctrl+D
Sleep 1s
