# tmux-smart-sessions

Smart tmux session management with ephemeral shells, auto-cleanup, and a protected session picker.

## The problem

Every time you open a terminal, tmux creates a session. These pile up as `0`, `1`, `2`, `3`... You end up with a mess of unnamed sessions you didn't ask for, and no clear way to manage the ones you actually care about.

## How this solves it

- **Ephemeral sessions**: New terminals get a hidden `_ephemeral_*` session — invisible to you, auto-cleaned when unused.
- **Session picker** (`Ctrl+A f`): A fuzzy picker that only shows sessions you explicitly created.
- **Current session protected**: The picker marks your current session with `●` and prevents accidental deletion.
- **Create on the fly**: Type a new name in the picker and hit Enter — session created instantly.
- **Auto-cleanup**: Stale ephemeral sessions are wiped on every new terminal launch.

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
2. Copy the `sesh-picker` script to `~/.local/bin/`
3. Set up `~/.tmux.conf` (backs up existing one)
4. Optionally add the auto-start snippet to your shell rc

## Dependencies

| Dependency | Required | Purpose |
|---|---|---|
| [tmux](https://github.com/tmux/tmux) | Yes | Terminal multiplexer |
| [fzf](https://github.com/junegunn/fzf) | Yes | Fuzzy finder for the picker |
| [sesh](https://github.com/joshmedeski/sesh) | Yes | Session management backend |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | No | Smarter directory tracking for sesh |

## Keybindings

### Session management

| Key | Action |
|---|---|
| `Ctrl+A f` | Open session picker |
| `Ctrl+D` (in picker) | Kill highlighted session |
| `Enter` (in picker) | Switch to / create session |
| `Esc` (in picker) | Cancel |

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
├── install.sh          # Portable installer
├── tmux.conf           # tmux configuration
├── bin/
│   └── sesh-picker     # Session picker script
├── shell-init.sh       # Snippet to add to .zshrc/.bashrc
└── README.md
```

## Uninstall

```bash
rm ~/.local/bin/sesh-picker
# Remove the ephemeral block from the top of your ~/.zshrc or ~/.bashrc
# Restore ~/.tmux.conf.bak if you had a previous config
```

## How it works

1. **Shell startup**: `.zshrc`/`.bashrc` creates a hidden `_ephemeral_<pid>` tmux session and cleans up any stale ones.
2. **Picker opens**: `Ctrl+A f` runs `sesh-picker`, which lists only non-ephemeral sessions via `tmux list-sessions`.
3. **Session switch**: When you pick or create a session, the picker switches to it and kills the ephemeral session you came from.
4. **Protection**: The current session is marked `●` and `Ctrl+D` is blocked on it.

## License

MIT
