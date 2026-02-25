# ══════════════════════════════════════════════════════════════
#  tmux-smart-sessions — Shell init snippet
#  Add this to the TOP of your ~/.zshrc or ~/.bashrc
# ══════════════════════════════════════════════════════════════

if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  # Kill stale ephemeral sessions (unattached)
  tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null \
    | awk '/^_ephemeral_/ && $2 == "0" { print $1 }' \
    | xargs -r -I{} tmux kill-session -t {}
  exec tmux new-session -s "_ephemeral_$$"
fi
