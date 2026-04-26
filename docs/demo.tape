# claude-routines — README demo tape (charm.sh/vhs)
#
# Generate the GIF:
#   brew install vhs
#   vhs docs/demo.tape
#
# Output lands at docs/demo.gif (referenced from README.md).
#
# This drives a real `claude` session in the repo. Output is authentic.
# Each Wait line waits for a regex match before the next command fires,
# so the timing self-adjusts to Claude's actual response speed.

Output docs/demo.gif

Set Shell "bash"
Set FontSize 14
Set Width 1280
Set Height 760
Set Theme "Dracula"
Set TypingSpeed 30ms
Set Padding 20
Set PlaybackSpeed 1.2

# Hidden setup — cd into the repo and clear the screen before recording starts
Hide
Type "cd ~/developer/ai/playground/claude-routines"
Enter
Type "clear"
Enter
Show

# 1. Show the file shape
Type "ls personal/"
Sleep 400ms
Enter
Sleep 2s

# 2. Show a real routine file
Type "head -20 personal/oslo-apartment-hunter.md"
Sleep 400ms
Enter
Sleep 3s

# 3. Drop into Claude Code and run the operations
Type "claude"
Enter
Wait />/

# Validate everything
Type "validate"
Sleep 300ms
Enter
Wait /OK/

# Diff a single routine to show in-sync state
Type "diff personal/oslo-apartment-hunter.md"
Sleep 300ms
Enter
Wait /sync/

# Exit cleanly
Ctrl+D
Sleep 1s
