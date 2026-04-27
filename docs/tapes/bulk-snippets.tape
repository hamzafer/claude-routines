Output docs/gifs/bulk-snippets.gif

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

# 1. Show the snippet that 5 routines share
Type "cat personal/snippets/telegram-card-universal.md"
Sleep 400ms
Enter
Sleep 4s

# 2. Show which routines use it
Type "grep -l telegram-card-universal personal/*.md"
Sleep 400ms
Enter
Sleep 3s

# 3. Drop into Claude and bulk-deploy them all
Type "claude --dangerously-skip-permissions"
Enter
Sleep 5s

Type "deploy all routines that use personal/snippets/telegram-card-universal.md"
Sleep 300ms
Enter
Sleep 110s

Ctrl+D
Sleep 1s
