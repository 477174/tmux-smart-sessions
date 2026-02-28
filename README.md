# tmux-smart-sessions

Smart tmux session management with ephemeral shells, auto-cleanup, session persistence, and a protected session picker.

## The problem

Every time you open a terminal, tmux creates a session. These pile up as `0`, `1`, `2`, `3`... You end up with a mess of unnamed sessions you didn't ask for, and no clear way to manage the ones you actually care about. Reboot your machine and everything is gone.

## How this solves it

- **Ephemeral sessions**: New terminals get a hidden `_ephemeral_*` session — invisible to you, auto-cleaned when unused.
- **Session picker** (`Ctrl+A f`): A fuzzy picker that only shows sessions you explicitly created.
- **Current session protected**: The picker marks your current session with `●` and prevents accidental deletion.
- **Create on the fly**: Type a new name in the picker and hit Enter — session created instantly.
- **Auto-cleanup**: Stale ephemeral sessions are wiped on every new terminal launch.
- **Session persistence**: Sessions auto-save every 15 minutes and restore after reboot — ephemeral sessions are stripped from save files so they never pollute your saved state.

## What it looks like

```
┌──────────────────────────────────────────┐
│   Ctrl+D = kill  │  type new name = create │
│                                            │
│  ● my-project (attached)                   │
│    api-server                              │
│    dotfiles                                │
│                                            │
│  > _                                       │
└──────────────────────────────────────────┘
```

## Install

```bash
git clone https://github.com/477174/tmux-smart-sessions.git
cd tmux-smart-sessions
chmod +x install.sh
./install.sh
```

The installer will:
1. Install dependencies (`tmux`, `fzf`, `sesh`, `zoxide`) if missing
2. Install TPM (Tmux Plugin Manager) and plugins (resurrect, continuum)
3. Copy `sesh-picker` and `resurrect-strip-ephemeral` to `~/.local/bin/`
4. Set up `~/.tmux.conf` (backs up existing one)
5. Optionally add the auto-start snippet to your shell rc

## Dependencies

| Dependency | Required | Purpose |
|---|---|---|
| [tmux](https://github.com/tmux/tmux) | Yes | Terminal multiplexer |
| [fzf](https://github.com/junegunn/fzf) | Yes | Fuzzy finder for the picker |
| [sesh](https://github.com/joshmedeski/sesh) | Yes | Session management backend |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | No | Smarter directory tracking for sesh |

Installed automatically by the installer:
| Plugin | Purpose |
|---|---|
| [TPM](https://github.com/tmux-plugins/tpm) | Tmux plugin manager |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Save/restore tmux sessions |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Auto-save every 15 min |

## Keybindings

### Session management

| Key | Action |
|---|---|
| `Ctrl+A f` | Open session picker |
| `Ctrl+D` (in picker) | Kill highlighted session |
| `Enter` (in picker) | Switch to / create session |
| `Esc` (in picker) | Cancel |

### Session persistence

| Key | Action |
|---|---|
| `Ctrl+A Ctrl+S` | Manual save |
| `Ctrl+A Ctrl+R` | Manual restore |

### Tabs (windows)

| Key | Action |
|---|---|
| `Ctrl+A c` | New tab |
| `Alt+1`…`Alt+5` | Jump to tab by number |
| `Alt+N` / `Alt+P` | Next / previous tab |

### Panes (splits)

| Key | Action |
|---|---|
| `Ctrl+A \|` | Vertical split |
| `Ctrl+A -` | Horizontal split |
| `Alt+H/J/K/L` | Move between panes |
| `Ctrl+A H/J/K/L` | Resize panes |

### Other

| Key | Action |
|---|---|
| `Ctrl+A r` | Reload tmux config |
| `Ctrl+A s` | List all sessions (tmux native) |

## File structure

```
tmux-smart-sessions/
├── install.sh                    # Portable installer
├── tmux.conf                     # tmux config (with plugin setup)
├── bin/
│   ├── sesh-picker               # Session picker script
│   └── resurrect-strip-ephemeral # Post-save hook for resurrect
├── shell-init.sh                 # Snippet to add to .zshrc/.bashrc
└── README.md
```

## How it works

### Ephemeral sessions
1. **Shell startup** (block 1): `.zshrc`/`.bashrc` creates a hidden `_ephemeral_<pid>` tmux session, cleans up stale ones, and attaches.
2. **Picker opens**: `Ctrl+A f` runs `sesh-picker`, which lists only non-ephemeral sessions.
3. **Session switch**: Pick or create a session — the picker switches to it and kills the ephemeral you came from.
4. **Protection**: Current session is marked `●` and `Ctrl+D` is blocked on it.

### Session persistence
1. **Auto-save**: Continuum saves all sessions every 15 minutes via resurrect.
2. **Post-save cleanup**: `resurrect-strip-ephemeral` removes `_ephemeral_*` entries from save files so they never pollute your saved state.
3. **Auto-restore** (block 2): On the first terminal after reboot, the shell (now inside tmux) triggers `resurrect restore` in the background. A lockfile in `/tmp` ensures only one terminal runs the restore. After restore completes, the client snaps back to the ephemeral session — you always land in a fresh shell.

### Why two blocks in the shell init?

- **Block 1** runs outside tmux (`$TMUX` unset): creates the ephemeral session and attaches.
- **Block 2** runs inside tmux (`$TMUX` set): the shell started by tmux sources the rc file again, skips block 1, and runs the restore. This ensures `$TMUX` is properly set so resurrect can find the tmux server socket.

## Uninstall

```bash
rm ~/.local/bin/sesh-picker
rm ~/.local/bin/resurrect-strip-ephemeral
# Remove the two blocks from the top of your ~/.zshrc or ~/.bashrc
# Restore ~/.tmux.conf.bak if you had a previous config
# Optionally: rm -rf ~/.tmux/plugins/
```

## License

MIT
