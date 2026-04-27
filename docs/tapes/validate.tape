Output docs/gifs/validate.gif

Set Shell "bash"
Set FontSize 14
Set Width 1200
Set Height 700
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

# 1. Show the deliberately-broken routine
Type "cat personal/_demo_broken.md"
Sleep 300ms
Enter
Sleep 4s

# 2. Drop into Claude and validate the single broken file
Type "claude"
Enter
Sleep 5s

Type "validate personal/_demo_broken.md"
Sleep 200ms
Enter
Sleep 30s

Ctrl+D
Sleep 1s
