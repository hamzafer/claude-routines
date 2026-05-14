Output docs/demo.gif

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

# 1. Show the routine — frontmatter
Type "head -8 personal/oslo-apartment-hunter.md"
Sleep 400ms
Enter
Sleep 3s

# 2. Make the edit (script does sed cleanly without escape gymnastics)
Type "/tmp/cr-demo-edit.sh"
Sleep 300ms
Enter
Sleep 1500ms

# 3. Confirm the edit
Type "head -8 personal/oslo-apartment-hunter.md"
Sleep 400ms
Enter
Sleep 3s

# 4. Drop into Claude Code and deploy
Type "claude"
Enter
Sleep 5s

Type "deploy personal/oslo-apartment-hunter.md"
Sleep 300ms
Enter
Sleep 38s

Ctrl+D
Sleep 1s
