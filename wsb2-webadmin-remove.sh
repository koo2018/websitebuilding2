#!/bin/bash

# wsb2-webadmin-remove.sh
# Removes the WSB2 web admin panel.
# Run as root: sudo bash wsb2-webadmin-remove.sh

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\nRun as root: sudo bash wsb2-webadmin-remove.sh\n"
    exit 1
fi

echo "
WSB2 Web Admin — Removal
=========================
"

read -p "Teacher's username [teacher]: " TEACHER
TEACHER=${TEACHER:-teacher}
echo ""

TEACHER_HOME=$(getent passwd "$TEACHER" 2>/dev/null | cut -d: -f6 || true)
APP_DIR="${TEACHER_HOME:+$TEACHER_HOME/.wsb2/www/sitemanagement}"

echo "This will remove:"
echo "  $APP_DIR"
echo "  /opt/wsb2-webadmin/"
echo "  /etc/sudoers.d/wsb2-webadmin"
echo ""
read -p "Continue? [y/N]: " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

if [ -n "$APP_DIR" ] && [ -d "$APP_DIR" ]; then
    rm -rf "$APP_DIR"
    echo "Removed: $APP_DIR"
fi

if [ -d "/opt/wsb2-webadmin" ]; then
    rm -rf /opt/wsb2-webadmin
    echo "Removed: /opt/wsb2-webadmin"
fi

if [ -f "/etc/sudoers.d/wsb2-webadmin" ]; then
    rm -f /etc/sudoers.d/wsb2-webadmin
    echo "Removed: /etc/sudoers.d/wsb2-webadmin"
fi

echo ""
echo "Web admin removed."
