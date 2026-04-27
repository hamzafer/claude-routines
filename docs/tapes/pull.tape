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

# 1. Show empty personal/ (only README + snippets dir)
Type "ls personal/"
Sleep 400ms
Enter
Sleep 3s

# 2. Drop into Claude and pull everything from the cloud
Type "claude --dangerously-skip-permissions"
Enter
Sleep 5s

Type "pull"
Sleep 200ms
Enter
Sleep 100s

Ctrl+D
Sleep 1s

# 3. Show the populated personal/
Type "ls personal/"
Sleep 400ms
Enter
Sleep 3s
