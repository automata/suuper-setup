#!/bin/bash
#
# post_install.sh - Setup script for AI coding tools
# Requires: User must be in sudoers without password requirement
#

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# =============================================================================
# CONFIGURATION - Package Definitions
# =============================================================================
# Each package has: name, description, order, install function, check function
# Add new packages by defining install_<name> and check_<name> functions
# then adding them to the PACKAGES array

declare -A PACKAGE_DESCRIPTIONS=(
    ["apt_packages"]="Essential APT packages and CLI tools"
    ["gum"]="Gum - A tool for glamorous shell scripts"
    ["mosh"]="Mosh - Mobile shell for remote connections"
    ["nvm"]="NVM - Node Version Manager"
    ["nodejs"]="Node.js 22 - JavaScript runtime"
    ["bun"]="Bun - Fast JavaScript runtime and toolkit"
    ["rust"]="Rust - Systems programming language"
    ["python_uv"]="Python3 and uv - Python with fast package manager"
    ["tmux"]="Tmux - Terminal multiplexer"
    ["neovim"]="Neovim - Hyperextensible text editor"
    ["lazyvim"]="LazyVim - Neovim configuration framework"
    ["git_config"]="Git - Version control configuration"
    ["claude"]="Claude Code - Anthropic AI coding assistant"
    ["opencode"]="OpenCode - AI coding assistant"
    ["codex"]="Codex - OpenAI coding CLI"
    ["gemini"]="Gemini CLI - Google AI coding assistant"
)

# Installation order
PACKAGES=(
    "apt_packages"
    "gum"
    "mosh"
    "nvm"
    "nodejs"
    "bun"
    "rust"
    "python_uv"
    "tmux"
    "neovim"
    "lazyvim"
    "git_config"
    "claude"
    "opencode"
    "codex"
    "gemini"
)

# APT packages to install
APT_PACKAGES=(
    curl ca-certificates tar xz-utils build-essential sudo gnupg
    ripgrep fd-find fzf jq gh git-lfs rsync lsof dnsutils
    netcat-openbsd strace htop tree ncdu httpie entr mtr pv
    cmatrix bat lsd eza btop git-delta unzip git
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
NC='\033[0m' # No Color

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BOLD}${CYAN}"
    echo "=============================================="
    echo "  Suuper Setup - AI Coding Tools Installer"
    echo "=============================================="
    echo -e "${NC}"
}

print_section() {
    echo -e "\n${BOLD}${BLUE}>> $1${NC}"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_skip() {
    echo -e "${MAGENTA}[SKIP]${NC} $1 - already installed"
}

# Check if gum is available for pretty output
use_gum() {
    command -v gum &> /dev/null
}

# Pretty spinner using gum if available
run_with_spinner() {
    local title="$1"
    shift
    if use_gum; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        echo -n "$title... "
        if "$@" > /dev/null 2>&1; then
            echo "done"
        else
            echo "failed"
            return 1
        fi
    fi
}

# Confirm action using gum if available
confirm_action() {
    local prompt="$1"
    if use_gum; then
        gum confirm "$prompt"
    else
        read -p "$prompt [y/N] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Display styled message using gum if available
styled_print() {
    local style="$1"
    local message="$2"
    if use_gum; then
        gum style --foreground "$style" "$message"
    else
        echo "$message"
    fi
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

check_prerequisites() {
    print_section "Checking Prerequisites"

    # Check if user can sudo without password
    if ! sudo -n true 2>/dev/null; then
        print_error "This script requires passwordless sudo access"
        print_info "Run: echo '$USER ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/$USER"
        exit 1
    fi
    print_success "Passwordless sudo access verified"

    # Check if running on Linux
    if [[ "$(uname)" != "Linux" ]]; then
        print_error "This script is designed for Linux systems only"
        exit 1
    fi
    print_success "Linux system detected"
}

# =============================================================================
# INSTALL FUNCTIONS
# =============================================================================

install_apt_packages() {
    print_section "Installing APT Packages"

    sudo apt-get update -qq

    # Install packages one by one for better error handling
    for pkg in "${APT_PACKAGES[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            print_skip "$pkg"
        else
            if use_gum; then
                gum spin --spinner dot --title "Installing $pkg..." -- \
                    sudo apt-get install -y -qq "$pkg"
            else
                echo -n "Installing $pkg... "
                if sudo apt-get install -y -qq "$pkg" > /dev/null 2>&1; then
                    echo "done"
                else
                    echo "failed (continuing)"
                fi
            fi
        fi
    done

    print_success "APT packages installation complete"
}

check_apt_packages() {
    local missing=0
    for pkg in "${APT_PACKAGES[@]}"; do
        if ! dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            missing=$((missing + 1))
        fi
    done
    [[ $missing -eq 0 ]]
}

install_gum() {
    print_section "Installing Gum"

    if command -v gum &> /dev/null; then
        print_skip "Gum"
        return 0
    fi

    # Install gum from charm repository
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg 2>/dev/null || true
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq gum

    print_success "Gum installed successfully"
}

check_gum() {
    command -v gum &> /dev/null
}

install_mosh() {
    print_section "Installing Mosh"

    if command -v mosh &> /dev/null; then
        print_skip "Mosh"
        return 0
    fi

    sudo apt-get install -y -qq mosh
    print_success "Mosh installed successfully"
}

check_mosh() {
    command -v mosh &> /dev/null
}

install_nvm() {
    print_section "Installing NVM"

    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        print_skip "NVM"
        return 0
    fi

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    print_success "NVM installed successfully"
}

check_nvm() {
    [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]
}

install_nodejs() {
    print_section "Installing Node.js 24"

    # Ensure NVM is loaded
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if command -v node &> /dev/null && node --version 2>/dev/null | grep -q "^v24"; then
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
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    command -v node &> /dev/null && node --version 2>/dev/null | grep -q "^v24"
}

install_bun() {
    print_section "Installing Bun"

    if command -v bun &> /dev/null; then
        print_skip "Bun"
        return 0
    fi

    curl -fsSL https://bun.sh/install | bash

    # Add to current session
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"

    print_success "Bun installed successfully"
    print_info "Bun version: $(bun --version 2>/dev/null || echo 'reload shell to use')"
}

check_bun() {
    [[ -f "$HOME/.bun/bin/bun" ]] || command -v bun &> /dev/null
}

install_rust() {
    print_section "Installing Rust"

    if command -v rustc &> /dev/null; then
        print_skip "Rust"
        return 0
    fi

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # Add to current session
    source "$HOME/.cargo/env" 2>/dev/null || true

    print_success "Rust installed successfully"
    print_info "Rust version: $(rustc --version 2>/dev/null || echo 'reload shell to use')"
}

check_rust() {
    [[ -f "$HOME/.cargo/bin/rustc" ]] || command -v rustc &> /dev/null
}

install_python_uv() {
    print_section "Installing Python3 and uv"

    # Ensure Python3 is installed
    if ! command -v python3 &> /dev/null; then
        sudo apt-get install -y -qq python3 python3-pip python3-venv
    fi
    print_success "Python3 is available"

    # Install uv
    if command -v uv &> /dev/null; then
        print_skip "uv"
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
        print_success "uv installed successfully"
    fi

    print_info "Python version: $(python3 --version)"
}

check_python_uv() {
    command -v python3 &> /dev/null && { [[ -f "$HOME/.local/bin/uv" ]] || command -v uv &> /dev/null; }
}

install_tmux() {
    print_section "Installing Tmux"

    if command -v tmux &> /dev/null; then
        print_skip "Tmux"
        return 0
    fi

    sudo apt-get install -y -qq tmux
    print_success "Tmux installed successfully"
    print_info "Tmux version: $(tmux -V)"
}

check_tmux() {
    command -v tmux &> /dev/null
}

install_neovim() {
    print_section "Installing Neovim"

    if command -v nvim &> /dev/null; then
        print_skip "Neovim"
        return 0
    fi

    # Install latest Neovim from GitHub releases
    local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    local install_dir="/opt/nvim"

    curl -LO "$nvim_url"
    sudo rm -rf "$install_dir"
    sudo mkdir -p "$install_dir"
    sudo tar -C "$install_dir" -xzf nvim-linux-x86_64.tar.gz --strip-components=1
    rm nvim-linux-x86_64.tar.gz

    # Create symlink
    sudo ln -sf "$install_dir/bin/nvim" /usr/local/bin/nvim

    print_success "Neovim installed successfully"
    print_info "Neovim version: $(nvim --version | head -1)"
}

check_neovim() {
    command -v nvim &> /dev/null
}

install_lazyvim() {
    print_section "Installing LazyVim"

    local nvim_config="$HOME/.config/nvim"

    if [[ -d "$nvim_config" ]] && [[ -f "$nvim_config/lua/config/lazy.lua" ]]; then
        print_skip "LazyVim"
        return 0
    fi

    # Backup existing config if present
    if [[ -d "$nvim_config" ]]; then
        mv "$nvim_config" "${nvim_config}.backup.$(date +%s)"
        print_info "Existing config backed up"
    fi

    # Clone LazyVim starter
    git clone https://github.com/LazyVim/starter "$nvim_config"
    rm -rf "$nvim_config/.git"

    print_success "LazyVim installed successfully"
    print_info "Run 'nvim' to complete plugin installation"
}

check_lazyvim() {
    [[ -d "$HOME/.config/nvim" ]] && [[ -f "$HOME/.config/nvim/lua/config/lazy.lua" ]]
}

install_git_config() {
    print_section "Configuring Git"

    # Git should already be installed via APT packages
    if ! command -v git &> /dev/null; then
        sudo apt-get install -y -qq git
    fi

    # Set up delta as pager if not configured
    if ! git config --global core.pager &> /dev/null; then
        if command -v delta &> /dev/null; then
            git config --global core.pager delta
            git config --global interactive.diffFilter "delta --color-only"
            git config --global delta.navigate true
            git config --global delta.light false
            git config --global merge.conflictstyle diff3
            git config --global diff.colorMoved default
            print_success "Git configured with delta"
        fi
    else
        print_skip "Git config"
    fi

    print_info "Git version: $(git --version)"
}

check_git_config() {
    command -v git &> /dev/null
}

install_claude() {
    print_section "Installing Claude Code"

    if command -v claude &> /dev/null; then
        print_skip "Claude Code"
        return 0
    fi

    # Ensure npm is available
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if ! command -v npm &> /dev/null; then
        print_error "npm not found. Please install Node.js first"
        return 1
    fi

    npm install -g @anthropic-ai/claude-code

    print_success "Claude Code installed successfully"
}

check_claude() {
    command -v claude &> /dev/null
}

install_opencode() {
    print_section "Installing OpenCode"

    if command -v opencode &> /dev/null; then
        print_skip "OpenCode"
        return 0
    fi

    # Install via Go or download binary
    curl -fsSL https://opencode.ai/install | bash 2>/dev/null || {
        # Fallback: try npm
        export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        npm install -g opencode 2>/dev/null || {
            print_warning "OpenCode installation failed - may need manual installation"
            return 0
        }
    }

    print_success "OpenCode installed successfully"
}

check_opencode() {
    command -v opencode &> /dev/null
}

install_codex() {
    print_section "Installing Codex CLI"

    if command -v codex &> /dev/null; then
        print_skip "Codex"
        return 0
    fi

    # Ensure npm is available
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if ! command -v npm &> /dev/null; then
        print_error "npm not found. Please install Node.js first"
        return 1
    fi

    npm install -g @openai/codex

    print_success "Codex installed successfully"
}

check_codex() {
    command -v codex &> /dev/null
}

install_gemini() {
    print_section "Installing Gemini CLI"

    if command -v gemini &> /dev/null; then
        print_skip "Gemini CLI"
        return 0
    fi

    # Ensure npm is available
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if ! command -v npm &> /dev/null; then
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

check_gemini() {
    command -v gemini &> /dev/null
}

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

    local shell_rc=""
    if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    # Add PATH configurations if not present
    local config_marker="# Suuper Setup PATH Configuration"

    if ! grep -q "$config_marker" "$shell_rc" 2>/dev/null; then
        cat >> "$shell_rc" << 'EOF'

# Suuper Setup PATH Configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# NVM Configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
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

    # Install Gum first for pretty output
    install_gum

    # Welcome message with gum if available
    if use_gum; then
        echo
        gum style --border rounded --padding "1 2" --border-foreground 39 \
            "This script will install AI coding tools and development utilities." \
            "All operations are idempotent - safe to re-run."
        echo

        if ! gum confirm "Proceed with installation?"; then
            echo "Installation cancelled."
            exit 0
        fi
    fi

    # Install all packages in order
    for pkg in "${PACKAGES[@]}"; do
        local install_func="install_${pkg}"
        if declare -f "$install_func" > /dev/null; then
            $install_func || print_warning "Failed to install $pkg (continuing)"
        else
            print_warning "Install function not found for $pkg"
        fi
    done

    # Setup shell configuration
    setup_shell_config

    # Verify all installations
    verify_installations

    echo
    if use_gum; then
        gum style --foreground 82 --bold \
            "Setup complete! Please restart your shell or run: source ~/.bashrc"
    else
        print_success "Setup complete! Please restart your shell or run: source ~/.bashrc"
    fi
}

# Run main function
main "$@"
