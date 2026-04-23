#!/bin/bash
#
# install_macos.sh - Install script for AI coding tools on macOS
# Run as your normal user. Do NOT run the whole script with sudo.
#

set -euo pipefail

# =============================================================================
# CONFIGURATION - Package Definitions
# =============================================================================

declare -A PACKAGE_DESCRIPTIONS=(
  ["xcode_clt"]="Xcode Command Line Tools"
  ["homebrew"]="Homebrew package manager"
  ["brew_packages"]="Essential Homebrew packages and CLI tools"
  ["gum"]="Gum - A tool for glamorous shell scripts"
  ["mosh"]="Mosh - Mobile shell for remote connections"
  ["nvm"]="NVM - Node Version Manager"
  ["nodejs"]="Node.js 24 - JavaScript runtime"
  ["pnpm"]="pnpm - Fast, disk space efficient package manager"
  ["bun"]="Bun - Fast JavaScript runtime and toolkit"
  ["rust"]="Rust - Systems programming language"
  ["python_uv"]="Python3 and uv - Python with fast package manager"
  ["tmux"]="Tmux - Terminal multiplexer"
  ["tmux_config"]="Tmux Config - TPM and beautiful configuration"
  ["neovim"]="Neovim - Hyperextensible text editor"
  ["lazyvim"]="LazyVim - Neovim configuration framework"
  ["lazyvim_tmux"]="LazyVim Tmux - Seamless tmux/nvim integration"
  ["git_config"]="Git - Version control configuration"
  ["claude"]="Claude Code - Anthropic AI coding assistant"
  ["opencode"]="OpenCode - AI coding assistant"
  ["codex"]="Codex - OpenAI coding CLI"
  ["gemini"]="Gemini CLI - Google AI coding assistant"
  ["pi"]="Pi - AI coding agent"
)

PACKAGES=(
  "xcode_clt"
  "homebrew"
  "brew_packages"
  "gum"
  "mosh"
  "nvm"
  "nodejs"
  "pnpm"
  "bun"
  "rust"
  "python_uv"
  "tmux"
  "tmux_config"
  "neovim"
  "lazyvim"
  "lazyvim_tmux"
  "git_config"
  "claude"
  "opencode"
  "codex"
  "gemini"
  "pi"
)

BREW_PACKAGES=(
  curl ca-certificates gnu-tar xz gum mosh gnupg
  ripgrep fd fzf jq gh git-lfs rsync
  htop tree ncdu httpie entr mtr pv
  cmatrix bat lsd eza btop git-delta
  git nginx the_silver_searcher neofetch
  tmux neovim python uv
  coreutils findutils gawk gnu-sed
  bind
)

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_header() {
  echo -e "${BOLD}${CYAN}"
  echo "=============================================="
  echo "  Suuper Setup - macOS Installer"
  echo "=============================================="
  echo -e "${NC}"
}

print_section() { echo -e "\n${BOLD}${BLUE}>> $1${NC}"; }
print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_skip() { echo -e "${MAGENTA}[SKIP]${NC} $1 - already installed"; }

use_gum() {
  command -v gum &>/dev/null
}

brew_prefix() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    echo "/opt/homebrew"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    echo "/usr/local"
  else
    echo ""
  fi
}

load_homebrew_env() {
  local prefix
  prefix="$(brew_prefix)"
  if [[ -n "$prefix" ]] && [[ -x "$prefix/bin/brew" ]]; then
    eval "$($prefix/bin/brew shellenv)"
  fi
}

load_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}

ensure_line_in_file() {
  local file="$1"
  local marker="$2"
  local content="$3"

  touch "$file"
  if ! grep -qF "$marker" "$file" 2>/dev/null; then
    printf "\n%s\n" "$content" >>"$file"
    return 0
  fi
  return 1
}

run_with_spinner() {
  local title="$1"
  shift
  if use_gum; then
    gum spin --spinner dot --title "$title" -- "$@"
  else
    echo -n "$title... "
    if "$@" >/dev/null 2>&1; then
      echo "done"
    else
      echo "failed"
      return 1
    fi
  fi
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

check_prerequisites() {
  print_section "Checking Prerequisites"

  if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed for macOS systems only"
    exit 1
  fi
  print_success "macOS system detected"

  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    print_error "Do not run this script with sudo or as root"
    print_info "Run it as your normal user so tools install into your home directory"
    exit 1
  fi
  print_success "Running as current user: $USER"
}

# =============================================================================
# INSTALL FUNCTIONS
# =============================================================================

install_xcode_clt() {
  print_section "Checking Xcode Command Line Tools"

  if xcode-select -p &>/dev/null; then
    print_skip "Xcode Command Line Tools"
    return 0
  fi

  print_warning "Xcode Command Line Tools are required by Homebrew and some build steps"
  print_info "A macOS installer dialog may open now"
  xcode-select --install || true

  print_info "After the installation completes, re-run this script"
  return 1
}

check_xcode_clt() {
  xcode-select -p &>/dev/null
}

install_homebrew() {
  print_section "Installing Homebrew"

  if command -v brew &>/dev/null || [[ -x "/opt/homebrew/bin/brew" ]] || [[ -x "/usr/local/bin/brew" ]]; then
    load_homebrew_env
    print_skip "Homebrew"
    return 0
  fi

  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew_env

  print_success "Homebrew installed successfully"
}

check_homebrew() {
  command -v brew &>/dev/null || [[ -x "/opt/homebrew/bin/brew" ]] || [[ -x "/usr/local/bin/brew" ]]
}

install_brew_packages() {
  print_section "Installing Homebrew Packages"
  load_homebrew_env

  brew update >/dev/null

  for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
      print_skip "$pkg"
    else
      if use_gum; then
        gum spin --spinner dot --title "Installing $pkg..." -- brew install "$pkg"
      else
        echo -n "Installing $pkg... "
        if brew install "$pkg" >/dev/null 2>&1; then
          echo "done"
        else
          echo "failed (continuing)"
        fi
      fi
    fi
  done

  print_success "Homebrew packages installation complete"
}

check_brew_packages() {
  load_homebrew_env
  local missing=0
  for pkg in "${BREW_PACKAGES[@]}"; do
    if ! brew list "$pkg" &>/dev/null; then
      missing=$((missing + 1))
    fi
  done
  [[ $missing -eq 0 ]]
}

install_gum() {
  print_section "Installing Gum"
  load_homebrew_env

  if command -v gum &>/dev/null; then
    print_skip "Gum"
    return 0
  fi

  brew install gum
  print_success "Gum installed successfully"
}

check_gum() { command -v gum &>/dev/null; }

install_mosh() {
  print_section "Installing Mosh"
  load_homebrew_env

  if command -v mosh &>/dev/null; then
    print_skip "Mosh"
    return 0
  fi

  brew install mosh
  print_success "Mosh installed successfully"
}

check_mosh() { command -v mosh &>/dev/null; }

install_nvm() {
  print_section "Installing NVM"

  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    print_skip "NVM"
    return 0
  fi

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
  load_nvm

  print_success "NVM installed successfully"
}

check_nvm() {
  [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]
}

install_nodejs() {
  print_section "Installing Node.js 24"
  load_nvm

  if command -v node &>/dev/null && node --version 2>/dev/null | grep -q "^v24"; then
    print_skip "Node.js 24"
    return 0
  fi

  nvm install 24
  nvm use 24
  nvm alias default 24

  print_success "Node.js 24 installed successfully"
  print_info "Node version: $(node --version)"
}

check_nodejs() {
  load_nvm
  command -v node &>/dev/null && node --version 2>/dev/null | grep -q "^v24"
}

install_pnpm() {
  print_section "Installing pnpm"
  load_nvm

  if command -v pnpm &>/dev/null; then
    print_skip "pnpm"
    return 0
  fi

  if ! command -v npm &>/dev/null; then
    print_error "npm not found. Please install Node.js first"
    return 1
  fi

  npm install -g pnpm

  print_success "pnpm installed successfully"
  print_info "pnpm version: $(pnpm --version 2>/dev/null || echo 'reload shell to use')"
}

check_pnpm() { command -v pnpm &>/dev/null; }

install_bun() {
  print_section "Installing Bun"

  if command -v bun &>/dev/null || [[ -x "$HOME/.bun/bin/bun" ]]; then
    print_skip "Bun"
    return 0
  fi

  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"

  print_success "Bun installed successfully"
  print_info "Bun version: $(bun --version 2>/dev/null || echo 'reload shell to use')"
}

check_bun() {
  [[ -x "$HOME/.bun/bin/bun" ]] || command -v bun &>/dev/null
}

install_rust() {
  print_section "Installing Rust"

  if command -v rustc &>/dev/null || [[ -x "$HOME/.cargo/bin/rustc" ]]; then
    print_skip "Rust"
    return 0
  fi

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env" 2>/dev/null || true

  print_success "Rust installed successfully"
  print_info "Rust version: $(rustc --version 2>/dev/null || echo 'reload shell to use')"
}

check_rust() {
  [[ -x "$HOME/.cargo/bin/rustc" ]] || command -v rustc &>/dev/null
}

install_python_uv() {
  print_section "Installing Python3 and uv"
  load_homebrew_env

  if ! command -v python3 &>/dev/null; then
    brew install python
  fi
  print_success "Python3 is available"

  if command -v uv &>/dev/null; then
    print_skip "uv"
  else
    brew install uv
    print_success "uv installed successfully"
  fi

  print_info "Python version: $(python3 --version)"
}

check_python_uv() {
  command -v python3 &>/dev/null && command -v uv &>/dev/null
}

install_tmux() {
  print_section "Installing Tmux"
  load_homebrew_env

  if command -v tmux &>/dev/null; then
    print_skip "Tmux"
    return 0
  fi

  brew install tmux
  print_success "Tmux installed successfully"
  print_info "Tmux version: $(tmux -V)"
}

check_tmux() { command -v tmux &>/dev/null; }

install_tmux_config() {
  print_section "Configuring Tmux"

  local tpm_dir="$HOME/.tmux/plugins/tpm"
  local tmux_conf="$HOME/.tmux.conf"
  local config_marker="# Suuper Setup Tmux Configuration"

  if [[ ! -d "$tpm_dir" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    print_success "TPM installed"
  else
    print_skip "TPM"
  fi

  if [[ -f "$tmux_conf" ]] && grep -q "$config_marker" "$tmux_conf" 2>/dev/null; then
    print_skip "Tmux configuration"
    return 0
  fi

  if [[ -f "$tmux_conf" ]]; then
    mv "$tmux_conf" "${tmux_conf}.backup.$(date +%s)"
    print_info "Existing tmux.conf backed up"
  fi

  cat >"$tmux_conf" <<'TMUX_EOF'
# Suuper Setup Tmux Configuration

set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
set -g display-time 4000
set -g status-interval 5
set -g focus-events on
setw -g aggressive-resize on
set -sg escape-time 0
set -g set-clipboard on

unbind C-b
set -g prefix C-a
bind C-a send-prefix
bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind \\ split-window -h -c "#{pane_current_path}"
unbind '"'
unbind %
bind c new-window -c "#{pane_current_path}"
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5
bind -r p previous-window
bind -r n next-window
bind S setw synchronize-panes

is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
bind-key -T copy-mode-vi 'C-h' select-pane -L
bind-key -T copy-mode-vi 'C-j' select-pane -D
bind-key -T copy-mode-vi 'C-k' select-pane -U
bind-key -T copy-mode-vi 'C-l' select-pane -R
bind C-l send-keys 'C-l'

setw -g mode-keys vi
bind v copy-mode
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

set -g pane-border-style 'fg=#313244'
set -g pane-active-border-style 'fg=#89b4fa'
set -g status-position bottom
set -g status-justify left
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
set -g status-left-length 40
set -g status-left '#[bg=#89b4fa,fg=#1e1e2e,bold] #S #[bg=#1e1e2e,fg=#89b4fa]'
set -g status-right-length 60
set -g status-right '#[fg=#45475a]#[bg=#45475a,fg=#cdd6f4] %Y-%m-%d #[fg=#585b70]#[bg=#585b70,fg=#cdd6f4] %H:%M #[fg=#89b4fa]#[bg=#89b4fa,fg=#1e1e2e,bold] #h '
setw -g window-status-format '#[fg=#1e1e2e,bg=#313244]#[fg=#cdd6f4,bg=#313244] #I:#W #[fg=#313244,bg=#1e1e2e]'
setw -g window-status-current-format '#[fg=#1e1e2e,bg=#f9e2af]#[fg=#1e1e2e,bg=#f9e2af,bold] #I:#W #[fg=#f9e2af,bg=#1e1e2e]'
set -g message-style 'bg=#f9e2af fg=#1e1e2e bold'

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-nvim 'session'
set -g @continuum-restore 'on'

run '~/.tmux/plugins/tpm/tpm'
TMUX_EOF

  print_success "Tmux configuration created"
  print_info "Run 'tmux source ~/.tmux.conf' then 'prefix + I' to install plugins"
}

check_tmux_config() {
  [[ -d "$HOME/.tmux/plugins/tpm" ]] && [[ -f "$HOME/.tmux.conf" ]]
}

install_neovim() {
  print_section "Installing Neovim"
  load_homebrew_env

  if command -v nvim &>/dev/null; then
    print_skip "Neovim"
    return 0
  fi

  brew install neovim
  print_success "Neovim installed successfully"
  print_info "Neovim version: $(nvim --version | head -1)"
}

check_neovim() { command -v nvim &>/dev/null; }

install_lazyvim() {
  print_section "Installing LazyVim"

  local nvim_config="$HOME/.config/nvim"

  if [[ -d "$nvim_config" ]] && [[ -f "$nvim_config/lua/config/lazy.lua" ]]; then
    print_skip "LazyVim"
    return 0
  fi

  if [[ -d "$nvim_config" ]]; then
    mv "$nvim_config" "${nvim_config}.backup.$(date +%s)"
    print_info "Existing config backed up"
  fi

  git clone https://github.com/LazyVim/starter "$nvim_config"
  rm -rf "$nvim_config/.git"

  print_success "LazyVim installed successfully"
  print_info "Run 'nvim' to complete plugin installation"
}

check_lazyvim() {
  [[ -d "$HOME/.config/nvim" ]] && [[ -f "$HOME/.config/nvim/lua/config/lazy.lua" ]]
}

install_lazyvim_tmux() {
  print_section "Configuring LazyVim Tmux Integration"

  local plugins_dir="$HOME/.config/nvim/lua/plugins"
  local tmux_plugin="$plugins_dir/tmux.lua"
  local options_file="$HOME/.config/nvim/lua/config/options.lua"
  local options_marker="-- Tmux integration options"

  if [[ -f "$tmux_plugin" ]]; then
    print_skip "LazyVim tmux integration"
    return 0
  fi

  mkdir -p "$plugins_dir"

  cat >"$tmux_plugin" <<'NVIM_TMUX_EOF'
return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left (tmux-aware)" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down (tmux-aware)" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up (tmux-aware)" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right (tmux-aware)" },
    },
  },
  {
    "aserowy/tmux.nvim",
    opts = {
      copy_sync = {
        enable = true,
        sync_clipboard = true,
        sync_registers = true,
      },
      navigation = {
        enable_default_keybindings = false,
      },
      resize = {
        enable_default_keybindings = true,
        resize_step_x = 5,
        resize_step_y = 5,
      },
    },
  },
}
NVIM_TMUX_EOF

  print_success "LazyVim tmux plugin created"

  if [[ -f "$options_file" ]] && ! grep -q "$options_marker" "$options_file" 2>/dev/null; then
    cat >>"$options_file" <<'NVIM_OPTIONS_EOF'

-- Tmux integration options
vim.opt.updatetime = 100
vim.opt.termguicolors = true

if vim.env.TMUX then
  vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20"
end
NVIM_OPTIONS_EOF
    print_success "LazyVim options updated for tmux"
  else
    print_skip "LazyVim options"
  fi

  print_info "Run 'nvim' to install tmux plugins"
}

check_lazyvim_tmux() {
  [[ -f "$HOME/.config/nvim/lua/plugins/tmux.lua" ]]
}

install_git_config() {
  print_section "Configuring Git"

  if ! command -v git &>/dev/null; then
    load_homebrew_env
    brew install git
  fi

  if ! git config --global core.pager &>/dev/null; then
    if command -v delta &>/dev/null; then
      git config --global core.pager delta
      git config --global interactive.diffFilter "delta --color-only"
      git config --global delta.navigate true
      git config --global delta.light false
      git config --global merge.conflictstyle diff3
      git config --global diff.colorMoved default
      git config --global core.editor "nvim"
      print_success "Git configured with delta"
    fi
  else
    print_skip "Git config"
  fi

  print_info "Git version: $(git --version)"
}

check_git_config() { command -v git &>/dev/null; }

install_claude() {
  print_section "Installing Claude Code"
  load_nvm

  if command -v claude &>/dev/null; then
    print_skip "Claude Code"
    return 0
  fi

  if ! command -v npm &>/dev/null; then
    print_error "npm not found. Please install Node.js first"
    return 1
  fi

  npm install -g @anthropic-ai/claude-code
  print_success "Claude Code installed successfully"
}

check_claude() { command -v claude &>/dev/null; }

install_opencode() {
  print_section "Installing OpenCode"
  load_nvm

  if command -v opencode &>/dev/null; then
    print_skip "OpenCode"
    return 0
  fi

  curl -fsSL https://opencode.ai/install | bash 2>/dev/null || {
    npm install -g opencode 2>/dev/null || {
      print_warning "OpenCode installation failed - may need manual installation"
      return 0
    }
  }

  print_success "OpenCode installed successfully"
}

check_opencode() { command -v opencode &>/dev/null; }

install_codex() {
  print_section "Installing Codex CLI"
  load_nvm

  if command -v codex &>/dev/null; then
    print_skip "Codex"
    return 0
  fi

  if ! command -v npm &>/dev/null; then
    print_error "npm not found. Please install Node.js first"
    return 1
  fi

  npm install -g @openai/codex
  print_success "Codex installed successfully"
}

check_codex() { command -v codex &>/dev/null; }

install_gemini() {
  print_section "Installing Gemini CLI"
  load_nvm

  if command -v gemini &>/dev/null; then
    print_skip "Gemini CLI"
    return 0
  fi

  if ! command -v npm &>/dev/null; then
    print_error "npm not found. Please install Node.js first"
    return 1
  fi

  npm install -g @anthropic-ai/gemini-cli 2>/dev/null || \
    npm install -g @google/gemini-cli 2>/dev/null || {
    print_warning "Gemini CLI not found in npm - may need manual installation"
    return 0
  }

  print_success "Gemini CLI installed successfully"
}

check_gemini() { command -v gemini &>/dev/null; }

install_pi() {
  print_section "Installing Pi Coding Agent"
  load_nvm

  if command -v pi &>/dev/null; then
    print_skip "Pi"
    return 0
  fi

  if ! command -v npm &>/dev/null; then
    print_error "npm not found. Please install Node.js first"
    return 1
  fi

  npm install -g @mariozechner/pi-coding-agent
  print_success "Pi Coding Agent installed successfully"
}

check_pi() { command -v pi &>/dev/null; }

# =============================================================================
# POST-INSTALLATION VERIFICATION
# =============================================================================

verify_installations() {
  print_section "Verifying Installations"
  echo

  local total=${#PACKAGES[@]}
  local passed=0
  local failed=0

  if use_gum; then
    echo
    gum style --border rounded --padding "1 2" --border-foreground 212 \
      "Installation Verification Report"
    echo
  else
    echo "=============================================="
    echo "  Installation Verification Report"
    echo "=============================================="
  fi

  for pkg in "${PACKAGES[@]}"; do
    local check_func="check_${pkg}"
    local desc="${PACKAGE_DESCRIPTIONS[$pkg]:-$pkg}"

    if $check_func 2>/dev/null; then
      print_success "$desc"
      passed=$((passed + 1))
    else
      print_error "$desc - FAILED"
      failed=$((failed + 1))
    fi
  done

  echo
  echo "----------------------------------------------"
  echo -e "${BOLD}Results: ${GREEN}$passed passed${NC}, ${RED}$failed failed${NC} out of $total"
  echo "----------------------------------------------"

  if [[ $failed -eq 0 ]]; then
    if use_gum; then
      gum style --foreground 82 --bold "All installations completed successfully!"
    else
      print_success "All installations completed successfully!"
    fi
  else
    print_warning "Some installations failed. Review the output above."
  fi
}

# =============================================================================
# SHELL CONFIGURATION
# =============================================================================

setup_shell_config() {
  print_section "Setting up Shell Configuration"

  local shell_rc="$HOME/.zshrc"
  if [[ "$SHELL" == *"bash"* ]]; then
    shell_rc="$HOME/.bashrc"
  fi

  local config_block='# Suuper Setup PATH Configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

alias cc="claude --dangerously-skip-permissions"
alias v="nvim"
alias vi="nvim"
alias vim="nvim"
alias ls="lsd"

export TERM=xterm-256color

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi'

  if ensure_line_in_file "$shell_rc" "# Suuper Setup PATH Configuration" "$config_block"; then
    print_success "Shell configuration updated in $shell_rc"
  else
    print_skip "Shell configuration"
  fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  print_header
  check_prerequisites

  install_xcode_clt || exit 1
  install_homebrew
  load_homebrew_env
  install_gum

  if use_gum; then
    echo
    gum style --border rounded --padding "1 2" --border-foreground 39 \
      "This script will install AI coding tools and development utilities on macOS." \
      "All operations are idempotent - safe to re-run." \
      "Run it as your normal user, not with sudo."
    echo

    if ! gum confirm "Proceed with installation?"; then
      echo "Installation cancelled."
      exit 0
    fi
  fi

  for pkg in "${PACKAGES[@]}"; do
    local install_func="install_${pkg}"
    if declare -f "$install_func" >/dev/null; then
      $install_func || print_warning "Failed to install $pkg (continuing)"
    else
      print_warning "Install function not found for $pkg"
    fi
  done

  setup_shell_config
  verify_installations

  echo
  if use_gum; then
    gum style --foreground 82 --bold \
      "Setup complete! Restart your shell or run: source $HOME/.zshrc"
  else
    print_success "Setup complete! Restart your shell or run: source $HOME/.zshrc"
  fi
}

main "$@"
