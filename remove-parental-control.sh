#!/bin/bash

set -e

show_help() {
  echo "Usage: $0 <config.ini>"
  echo
  echo "Removes parental-control DNS configuration created by setup-kid-from-ini.sh"
  echo
  echo "INI file format must contain at least:"
  echo "[metadata]"
  echo "kid_name=jonas"
  exit 0
}

# Handle help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
  show_help
fi

# Require INI file
if [[ -z "$1" ]]; then
  echo "Error: No INI file provided."
  echo "Use --help for usage."
  exit 1
fi

INI_FILE="$1"

if [[ ! -f "$INI_FILE" ]]; then
  echo "Error: INI file '$INI_FILE' not found."
  exit 1
fi

### PARSE METADATA ###
kid_name=$(awk -F= '/^

\[metadata\]

/{flag=1;next}/^

\[/{flag=0}flag && $1=="kid_name"{print $2}' "$INI_FILE")

if [[ -z "$kid_name" ]]; then
  echo "Error: kid_name missing in [metadata] section."
  exit 1
fi

### PATHS ###
UNBOUND_DIR="/etc/unbound"
VIEW_FILE="$UNBOUND_DIR/unbound.conf.d/view-$kid_name.conf"
ALLOW_FILE="$UNBOUND_DIR/$kid_name-allow.conf"
BLOCK_FILE="$UNBOUND_DIR/$kid_name-blocklist.conf"
CURRENT_FILE="$UNBOUND_DIR/$kid_name-current.conf"
CRON_FILE="/etc/cron.d/${kid_name}-dns-schedule"

echo "=== Removing DNS parental controls for $kid_name ==="

### REMOVE VIEW ###
if [[ -f "$VIEW_FILE" ]]; then
  echo "Removing Unbound view..."
  rm -f "$VIEW_FILE"
else
  echo "View file not found (already removed)."
fi

### REMOVE ALLOW/BLOCK/CURRENT FILES ###
echo "Removing rule files..."
rm -f "$ALLOW_FILE" "$BLOCK_FILE" "$CURRENT_FILE"

### REMOVE CRON JOB ###
if [[ -f "$CRON_FILE" ]]; then
  echo "Removing cron schedule..."
  rm -f "$CRON_FILE"
else
  echo "Cron schedule not found (already removed)."
fi

### RELOAD UNBOUND ###
echo "Reloading Unbound..."
unbound-control reload || systemctl reload unbound

echo "=== DONE ==="
echo "Parental-control configuration for '$kid_name' has been removed."
