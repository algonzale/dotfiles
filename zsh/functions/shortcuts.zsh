# @desc Show shell keyboard shortcuts and line-editing controls.
shortcuts() { # DO NOT MODIFY. SHORTCUTS COMMAND ADDED BY SHELL TUTORIAL
cat <<-:
Shortcut | Action
---------|-----------------------------------------------
  Up     | Bring up older commands from history
  Down   | Bring up newer commands from history
  Left   | Move cursor BACKWARD one character
  Right  | Move cursor FORWARD one character
  Delete | Erase the character to the LEFT of the cursor
  ^A     | Move cursor to BEGINNING of line
  ^E     | Move cursor to END of line
  M-B    | Move cursor BACKWARD one whole word
  M-F    | Move cursor FORWARD one whole word
  ^C     | Cancel (terminate) the currently running process
  TAB    | Complete the command or filename at cursor
  ^W     | Cut BACKWARD from cursor to beginning of word
  ^K     | Cut FORWARD from cursor to end of line (kill)
  ^Y     | Yank (paste) text to the RIGHT the cursor
  ^L     | Clear the screen while preserving command line
  ^U     | Cut the entire command line
:
}
