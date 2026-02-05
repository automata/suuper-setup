# Suuper Setup

Setup a Linux box with all AI coding tools and a beautiful development environment.

## Install

```bash
curl -fsSL http://suuper.space:5000/suuper-setup/post_install.sh | bash
```

## Scripts

- `setup.sh` - For initial Linux box setup
- `post_install.sh` - For installing development tools on a running Linux box

## Packages

### System & CLI Tools

| Package | Description |
|---------|-------------|
| **APT Packages** | Essential tools: `curl`, `ripgrep`, `fd-find`, `fzf`, `jq`, `gh`, `htop`, `bat`, `eza`, `btop`, `git-delta`, and more |
| **Gum** | Glamorous shell scripts - pretty prompts, spinners, and confirmations |
| **Mosh** | Mobile shell for reliable remote connections over unstable networks |

### Language Runtimes & Package Managers

| Package | Description |
|---------|-------------|
| **NVM** | Node Version Manager - manage multiple Node.js versions |
| **Node.js 24** | JavaScript runtime (installed via NVM) |
| **Bun** | Fast all-in-one JavaScript runtime and toolkit |
| **Rust** | Systems programming language (via rustup) |
| **Python3 + uv** | Python with uv - an extremely fast Python package manager |

### Terminal & Editor

| Package | Description |
|---------|-------------|
| **Tmux** | Terminal multiplexer for managing multiple terminal sessions |
| **Tmux Config** | Beautiful tmux configuration with TPM and plugins (see below) |
| **Neovim** | Hyperextensible Vim-based text editor (latest release) |
| **LazyVim** | Neovim configuration framework for a full IDE experience |
| **LazyVim Tmux** | Seamless tmux/nvim integration plugins |

### Version Control

| Package | Description |
|---------|-------------|
| **Git Config** | Git configured with delta for beautiful diffs |

### AI Coding Assistants

| Package | Description |
|---------|-------------|
| **Claude Code** | Anthropic's AI coding assistant CLI (`@anthropic-ai/claude-code`) |
| **OpenCode** | AI coding assistant |
| **Codex** | OpenAI's coding CLI (`@openai/codex`) |
| **Gemini CLI** | Google's AI coding assistant |
| **Pi** | AI coding agent (`@mariozechner/pi-coding-agent`) |

## Tmux + Neovim Integration

The setup configures tmux and neovim to work seamlessly together.

### Tmux Configuration

**Prefix:** `Ctrl+a` (instead of default `Ctrl+b`)

**Key Bindings:**

| Key | Action |
|-----|--------|
| `Ctrl+a \|` or `Ctrl+a \` | Split pane horizontally |
| `Ctrl+a -` | Split pane vertically |
| `Ctrl+a c` | New window (in current path) |
| `Ctrl+a r` | Reload config |
| `Ctrl+h/j/k/l` | Navigate panes (vim-aware) |
| `Ctrl+a H/J/K/L` | Resize panes |
| `Ctrl+a p/n` | Previous/next window |
| `Ctrl+a v` | Enter copy mode |
| `Ctrl+a S` | Toggle pane synchronization |

**Features:**
- True color support
- Mouse support
- Vi-style copy mode
- Catppuccin-inspired statusline theme
- Session persistence (tmux-resurrect + tmux-continuum)
- Clipboard integration (tmux-yank)

**Plugins (via TPM):**
- `tmux-plugins/tmux-sensible` - Sensible defaults
- `tmux-plugins/tmux-yank` - Clipboard integration
- `tmux-plugins/tmux-resurrect` - Session persistence
- `tmux-plugins/tmux-continuum` - Auto-save/restore sessions

After installation, press `Ctrl+a I` to install plugins.

### Neovim/LazyVim Tmux Plugins

**vim-tmux-navigator:**
- Seamless navigation between tmux panes and nvim splits
- Use `Ctrl+h/j/k/l` to move in any direction
- Works transparently whether you're in a vim split or tmux pane

**tmux.nvim:**
- Clipboard synchronization between tmux and nvim
- Pane resizing utilities

## Post-Installation

After running the install script:

1. **Restart your shell** or run `source ~/.bashrc`
2. **Install tmux plugins:** Start tmux, then press `Ctrl+a I`
3. **Initialize LazyVim:** Run `nvim` and wait for plugins to install
4. **Configure AI tools:** Set up API keys for Claude, Codex, Gemini, Pi as needed

## Requirements

- Linux system (Debian/Ubuntu-based)
- Passwordless sudo access

To enable passwordless sudo:
```bash
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
```

## Idempotent

The script is safe to re-run. It will skip already-installed packages and only install what's missing.
