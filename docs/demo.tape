# claude-routines — README demo tape (charm.sh/vhs)
#
# Generate the GIF:
#   brew install vhs
#   vhs docs/demo.tape
#
# Output lands at docs/demo.gif (referenced from README.md).
#
# Drives a real `claude` session in the repo. Output is authentic.
# Sleep durations are tuned generously to give Claude time to respond.

Output docs/demo.gif

Set Shell "bash"
Set FontSize 14
Set Width 1280
Set Height 760
Set Theme "Dracula"
Set TypingSpeed 40ms
Set Padding 20

# Hidden setup — cd into the repo and clear the screen
Hide
Type "cd ~/developer/ai/playground/claude-routines"
Enter
Type "clear"
Enter
Sleep 500ms
Show

# 1. Show the routine library
Type "ls personal/"
Sleep 400ms
Enter
Sleep 2s

# 2. Show a real routine — frontmatter + first lines of prompt
Type "head -25 personal/oslo-apartment-hunter.md"
Sleep 400ms
Enter
Sleep 4s

# 3. Drop into Claude Code in this repo
Type "claude"
Enter
Sleep 6s

# 4. Validate every routine — pure local lint, fast
Type "validate"
Sleep 300ms
Enter
Sleep 18s

# 5. Diff a single routine vs cloud — proves local matches what's deployed
Type "diff personal/oslo-apartment-hunter.md"
Sleep 300ms
Enter
Sleep 18s

# 6. Exit Claude
Ctrl+D
Sleep 1s
