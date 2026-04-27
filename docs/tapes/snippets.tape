Output docs/gifs/snippets.gif

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

# 1. Show the routine that uses {{include}}
Type "tail -5 personal/norway-daily-news-digest.md"
Sleep 400ms
Enter
Sleep 3s

# 2. Show the snippet it includes
Type "cat personal/snippets/telegram-card-universal.md"
Sleep 400ms
Enter
Sleep 4s

# 3. Drop into Claude and dry-run deploy the routine to show snippet expansion
Type "claude --dangerously-skip-permissions"
Enter
Sleep 5s

Type "dry-run deploy personal/norway-daily-news-digest.md"
Sleep 200ms
Enter
Sleep 55s

Ctrl+D
Sleep 1s
