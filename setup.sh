#!/bin/bash
#
# setup.sh - Bootstrap minimal requirements (user with sudoers) in a fresh Ubuntu box
# Requires: Must be run as root
#
# Usage: ./setup.sh [--user USERNAME]
#

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# =============================================================================
# CONFIGURATION
# =============================================================================

DEFAULT_USERNAME="suuper"
USERNAME="${DEFAULT_USERNAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

print_header() {
  echo -e "${BOLD}${CYAN}"
  echo "=============================================="
  echo "  Suuper Setup - Setup Script"
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
  echo -e "${MAGENTA}[SKIP]${NC} $1 - already configured"
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --user)
      if [[ -n "${2:-}" ]]; then
        USERNAME="$2"
        shift 2
      else
        print_error "--user requires a username argument"
        exit 1
      fi
      ;;
    --user=*)
      USERNAME="${1#*=}"
      shift
      ;;
    -h | --help)
      echo "Usage: $0 [--user USERNAME]"
      echo ""
      echo "Options:"
      echo "  --user USERNAME    Create user with specified name (default: suuper)"
      echo "  -h, --help         Show this help message"
      exit 0
      ;;
    *)
      print_warning "Unknown option: $1"
      shift
      ;;
    esac
  done
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

check_prerequisites() {
  print_section "Checking Prerequisites"

  # Check if running as root
  if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root"
    print_info "Try: sudo $0"
    exit 1
  fi
  print_success "Running as root"

  # Check if running on Linux
  if [[ "$(uname)" != "Linux" ]]; then
    print_error "This script is designed for Linux systems only"
    exit 1
  fi
  print_success "Linux system detected"
}

# =============================================================================
# USER MANAGEMENT
# =============================================================================

create_user() {
  print_section "Creating User: $USERNAME"

  # Check if user already exists
  if id "$USERNAME" &>/dev/null; then
    print_skip "User $USERNAME"
  else
    # Create user with home directory
    useradd -m -s /bin/bash "$USERNAME"
    print_success "User $USERNAME created"
  fi

  # Ensure user has a home directory
  local home_dir="/home/$USERNAME"
  if [[ ! -d "$home_dir" ]]; then
    mkdir -p "$home_dir"
    chown "$USERNAME:$USERNAME" "$home_dir"
    print_success "Home directory created at $home_dir"
  fi
}

configure_sudoers() {
  print_section "Configuring Sudoers"

  local sudoers_file="/etc/sudoers.d/$USERNAME"

  # Check if user is already in sudoers with NOPASSWD
  if [[ -f "$sudoers_file" ]] && grep -q "NOPASSWD:ALL" "$sudoers_file" 2>/dev/null; then
    print_skip "Sudoers configuration for $USERNAME"
    return 0
  fi

  # Add user to sudo group
  usermod -aG sudo "$USERNAME" 2>/dev/null || true
  print_success "User $USERNAME added to sudo group"

  # Configure passwordless sudo
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >"$sudoers_file"
  chmod 440 "$sudoers_file"
  print_success "Passwordless sudo configured for $USERNAME"

  # Validate sudoers file
  if visudo -c -f "$sudoers_file" &>/dev/null; then
    print_success "Sudoers file validated"
  else
    print_error "Sudoers file validation failed"
    rm -f "$sudoers_file"
    exit 1
  fi
}

# =============================================================================
# ESSENTIAL SYSTEM PACKAGES
# =============================================================================

install_system_packages() {
  print_section "Installing Essential System Packages"

  apt-get update -qq

  # Essential packages needed before running post_install.sh
  local packages=(
    curl
  )

  for pkg in "${packages[@]}"; do
    if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
      print_skip "$pkg"
    else
      echo -n "Installing $pkg... "
      apt-get install -y -qq "$pkg" >/dev/null 2>&1 && echo "done" || echo "failed"
    fi
  done

  print_success "Essential system packages installed"
}

# =============================================================================
# VERIFICATION
# =============================================================================

verify_setup() {
  print_section "Verifying Setup"

  local errors=0

  # Check user exists
  if id "$USERNAME" &>/dev/null; then
    print_success "User $USERNAME exists"
  else
    print_error "User $USERNAME not found"
    errors=$((errors + 1))
  fi

  # Check sudoers
  if sudo -l -U "$USERNAME" 2>/dev/null | grep -q "NOPASSWD"; then
    print_success "User $USERNAME has passwordless sudo"
  else
    print_error "Passwordless sudo not configured for $USERNAME"
    errors=$((errors + 1))
  fi

  # Check home directory
  if [[ -d "/home/$USERNAME" ]]; then
    print_success "Home directory exists at /home/$USERNAME"
  else
    print_error "Home directory missing"
    errors=$((errors + 1))
  fi

  echo
  if [[ $errors -eq 0 ]]; then
    print_success "All verifications passed!"
  else
    print_warning "$errors verification(s) failed"
  fi

  return $errors
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
  parse_arguments "$@"

  print_header
  print_info "Username: $USERNAME"

  check_prerequisites

  # Create and configure user
  create_user
  configure_sudoers

  # Install minimal system packages
  install_system_packages

  # Verify everything
  verify_setup

  echo
  echo -e "${GREEN}${BOLD}Setup complete!${NC}"
  echo
  echo "To switch to the new user, run:"
  echo "  su - $USERNAME"
  echo
  echo "Or login directly as $USERNAME"
}

# Run main function
main "$@"
