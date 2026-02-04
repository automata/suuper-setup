# Specs for suuper-setup

Bash scripts to setup a remote Linux box with latest AI coding tools.

Requirements for both scripts:
- Install Gum first and use it to make the script TUI beautiful
- DO NOT USE EMOJIS! But user colors
- All operations should be idempotent: users should be able to re-run safely
- It should use apt to install packages, or snap
- The script should be devided in functions, following the best practices on bash programming
- The packages to be installed should be defined in the beginning of the script, following a data structure with the following keys (per package): name, description, order (number with order to be installed, index), install (commands to install), check (commands to check if installed with success)
- It should be pretty easy to extend the script to install new packages and config files (eg adding a new function)
- Run a post operation to check if everything was installed as expected

# install.sh

Requirements:
- The user running the script should be root. If not, fail
- Before anything, create a user called `suuper` (default name, allow changing it as `--user` param) and make it part of sudoers and configure it to do not require password for sudo

What to install:
- Read the `setup.sh` and install whatever we installed there

# post_install.sh

Requirements:
- The user running the script should be part of sudoers and do not require password to run commands with sudo

What to install:
- Mosh
- Nodejs 22 (through NVM)
- Bun
- Rust
- Python3 and uv
- Tmux
- Neovim and Lazyvim
- Git
- Gum
- Claude
- OpenCode
- Codex
- Gemini CLI

APT packages to install:
curl ca-certificates tar xz-utils build-essential sudo gnupg ripgrep fd-find fzf jq gh git-lfs rsync lsof dnsutils netcat-openbsd strace htop tree ncdu httpie entr mtr pv cmatrix bat lsd eza btop git-delta unzip