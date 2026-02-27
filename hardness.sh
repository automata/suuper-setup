#!/usr/bin/env bash
set -Eeuo pipefail

# Hardness Script
#
# - Make sure no root access with password through ssh

SSHD_CONFIG="/etc/ssh/sshd_config"
DROPIN_DIR="/etc/ssh/sshd_config.d"
DROPIN_FILE="$DROPIN_DIR/99-disable-root-password.conf"
BEGIN_MARK="# BEGIN no_root.sh managed block"
END_MARK="# END no_root.sh managed block"

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo bash "$0" "$@"
  else
    echo "[ERROR] Run as root (or install sudo)." >&2
    exit 1
  fi
fi

sshd_effective() {
  local key="$1"
  local out

  if out="$(/usr/sbin/sshd -T -f "$SSHD_CONFIG" -C user=root -C host="$(hostname -f 2>/dev/null || hostname)" -C addr=127.0.0.1 2>/dev/null)"; then
    awk -v k="$key" '$1==k { print $2; found=1; exit } END { if (!found) print "<unknown>" }' <<<"$out"
  else
    echo "<error>"
  fi
}

print_status() {
  echo "permitrootlogin $(sshd_effective permitrootlogin)"
  echo "passwordauthentication $(sshd_effective passwordauthentication)"
  echo "kbdinteractiveauthentication $(sshd_effective kbdinteractiveauthentication)"
}

on_error() {
  local line="$1"
  echo "[ERROR] Script failed near line $line" >&2
  echo "== SSH auth status (current) =="
  print_status || true
}
trap 'on_error $LINENO' ERR

comment_password_yes_in_dropins() {
  mkdir -p "$DROPIN_DIR"
  shopt -s nullglob
  local f tmp changed=0

  for f in "$DROPIN_DIR"/*.conf; do
    [[ "$f" == "$DROPIN_FILE" ]] && continue

    tmp="$(mktemp)"
    awk '
      BEGIN { IGNORECASE=1 }
      {
        if ($0 ~ /^[[:space:]]*#/) { print; next }
        if ($0 ~ /^[[:space:]]*PasswordAuthentication[[:space:]]+yes([[:space:]]*(#.*)?)?$/) {
          print "# " $0
          next
        }
        print
      }
    ' "$f" >"$tmp"

    if ! cmp -s "$f" "$tmp"; then
      mv "$tmp" "$f"
      chmod 600 "$f" 2>/dev/null || true
      echo "[INFO] Commented 'PasswordAuthentication yes' in $f"
      changed=1
    else
      rm -f "$tmp"
    fi
  done

  shopt -u nullglob
  if [[ "$changed" -eq 0 ]]; then
    echo "[INFO] No drop-in file had active 'PasswordAuthentication yes'."
  fi
}

apply_dropin() {
  mkdir -p "$DROPIN_DIR"
  cat >"$DROPIN_FILE" <<'EOF'
# Managed by /home/suuper/no_root.sh
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
  chmod 600 "$DROPIN_FILE"
}

apply_main_config_block() {
  local tmp
  tmp="$(mktemp)"

  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '
    $0==b {skip=1; next}
    $0==e {skip=0; next}
    !skip {print}
  ' "$SSHD_CONFIG" >"$tmp"

  {
    cat "$tmp"
    echo
    echo "$BEGIN_MARK"
    echo "PasswordAuthentication no"
    echo "KbdInteractiveAuthentication no"
    echo "PermitRootLogin no"
    echo "$END_MARK"
  } >"$SSHD_CONFIG"

  rm -f "$tmp"
}

validate_and_reload() {
  /usr/sbin/sshd -t -f "$SSHD_CONFIG"

  if systemctl is-active --quiet ssh; then
    systemctl reload ssh
  elif systemctl is-active --quiet sshd; then
    systemctl reload sshd
  else
    echo "[WARN] Could not detect active ssh/sshd service to reload."
    echo "[WARN] Reload manually: sudo systemctl reload ssh"
  fi
}

echo "== SSH auth status (before) =="
print_status

comment_password_yes_in_dropins
apply_dropin
validate_and_reload

pa="$(sshd_effective passwordauthentication)"
pr="$(sshd_effective permitrootlogin)"

if [[ "$pa" == "yes" || "$pr" != "no" ]]; then
  echo "[WARN] Settings still insecure after drop-in (passwordauthentication=$pa, permitrootlogin=$pr)."
  echo "[INFO] Applying managed hardening block to $SSHD_CONFIG (end of file override)."
  apply_main_config_block
  validate_and_reload
fi

echo "== SSH auth status (after) =="
print_status

final_pa="$(sshd_effective passwordauthentication)"
final_pr="$(sshd_effective permitrootlogin)"

if [[ "$final_pa" == "no" && "$final_pr" == "no" ]]; then
  echo "[OK] Password SSH auth disabled and root SSH login disabled."
else
  echo "[ERROR] Hardening did not fully apply (passwordauthentication=$final_pa, permitrootlogin=$final_pr)." >&2
  exit 2
fi
