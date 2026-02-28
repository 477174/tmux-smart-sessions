# ══════════════════════════════════════════════════════════════
#  tmux-smart-sessions — Shell init snippet
#  Add this to the TOP of your ~/.zshrc or ~/.bashrc
# ══════════════════════════════════════════════════════════════

# ── Block 1: Auto-start tmux (runs OUTSIDE tmux) ─────────────
if command -v tmux &>/dev/null && [ -z "$TMUX" ]; then
  # Kill stale ephemeral sessions (unattached)
  tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null \
    | awk '/^_ephemeral_/ && $2 == "0" { print $1 }' \
    | xargs -r -I{} tmux kill-session -t {} 2>/dev/null

  # Start ephemeral session (also starts tmux server if not running)
  tmux new-session -d -s "_ephemeral_$$" 2>/dev/null
  tmux attach -t "_ephemeral_$$"
fi

# ── Block 2: Restore saved sessions (runs INSIDE tmux) ───────
# When tmux attach starts a shell, $TMUX is set and block 1 is
# skipped. This block restores saved sessions in the background
# on the first terminal after a reboot. Uses a lockfile in /tmp
# (cleared automatically on reboot) so only one shell runs it.
if [ -n "$TMUX" ]; then
  _restore_lock="/tmp/.tmux_restore_done"
  if [ ! -f "$_restore_lock" ]; then
    if (set -C; echo $$ > "$_restore_lock") 2>/dev/null; then
      _resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
      if [ -f "$_resurrect_dir/last" ]; then
        # Capture current session name so we can snap back after restore
        _my_session="$(tmux display-message -p '#{session_name}')"
        (
          ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
          # restore.sh calls switch-client — snap back to ephemeral
          tmux switch-client -t "$_my_session" 2>/dev/null
        ) >/dev/null 2>&1 &
        disown
        unset _my_session
      fi
    fi
  fi
  unset _restore_lock _resurrect_dir
fi
