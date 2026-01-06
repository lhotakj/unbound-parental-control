#!/bin/bash

set -e
echo "♦ AmanaGate - uninstall Unbound"

show_help() {
  cat <<EOF
Usage: $0 [--force]

This script completely removes Unbound and all AmanaGate configurations.

Options:
  --force    Skip confirmation prompt

The following will be removed:
  - Unbound packages (unbound, unbound-anchor, dnsutils)
  - All AmanaGate cron schedules (/etc/cron.d/amanagate-*)
  - Entire Unbound configuration directory (/etc/unbound)

EOF
  exit 0
}

# Handle help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
fi

# Check for force flag
FORCE=false
if [[ "$1" == "--force" ]]; then
  FORCE=true
fi

# Confirmation prompt
if [[ "$FORCE" != true ]]; then
  echo "WARNING: This will completely remove Unbound and all AmanaGate configurations."
  echo "The following will be deleted:"
  echo "  - Unbound packages"
  echo "  - /etc/cron.d/amanagate-*"
  echo "  - /etc/unbound (entire directory)"
  echo
  read -p "Are you sure you want to continue? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "=== Stopping Unbound service ==="
if systemctl is-active --quiet unbound 2>/dev/null; then
  systemctl stop unbound
  echo "Unbound service stopped."
else
  echo "Unbound service not running."
fi

echo "=== Disabling Unbound service ==="
if systemctl is-enabled --quiet unbound 2>/dev/null; then
  systemctl disable unbound
  echo "Unbound service disabled."
else
  echo "Unbound service not enabled."
fi

echo "=== Removing AmanaGate cron schedules ==="
CRON_FILES=(/etc/cron.d/amanagate-*)
if [[ -e "${CRON_FILES[0]}" ]]; then
  rm -f /etc/cron.d/amanagate-*
  echo "Removed cron files: ${CRON_FILES[*]}"
else
  echo "No AmanaGate cron files found."
fi

echo "=== Uninstalling Unbound packages ==="
apt remove -y unbound unbound-anchor dnsutils 2>/dev/null || true
apt autoremove -y 2>/dev/null || true
echo "Packages removed."

echo "=== Removing Unbound configuration directory ==="
if [[ -d "/etc/unbound" ]]; then
  rm -rf /etc/unbound
  echo "Removed /etc/unbound"
else
  echo "/etc/unbound not found (already removed)."
fi

echo "=== Removing Unbound data directory ==="
if [[ -d "/var/lib/unbound" ]]; then
  rm -rf /var/lib/unbound
  echo "Removed /var/lib/unbound"
else
  echo "/var/lib/unbound not found (already removed)."
fi

echo "=== DONE ==="
echo "Unbound and all AmanaGate configurations have been removed."
