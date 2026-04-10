#!/bin/bash

# wsb2-webadmin-update.sh
# Updates WSB2 web admin PHP files from GitHub (keeps config.php intact).
# Run as root: sudo wsb2-webadmin-update

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\nRun as root: sudo wsb2-webadmin-update\n"
    exit 1
fi

read -p "Teacher's username [teacher]: " TEACHER
TEACHER=${TEACHER:-teacher}

TEACHER_HOME=$(getent passwd "$TEACHER" 2>/dev/null | cut -d: -f6 || true)
if [ -z "$TEACHER_HOME" ]; then
    echo "User '$TEACHER' not found."
    exit 1
fi

APP_DIR="$TEACHER_HOME/.wsb2/www/sitemanagement"
if [ ! -d "$APP_DIR" ]; then
    echo "Not found: $APP_DIR"
    echo "Run wsb2-webadmin-install.sh first."
    exit 1
fi

GITHUB_RAW="https://raw.githubusercontent.com/koo2018/websitebuilding2/main"

FILES="action.php auth.php auth_check.php data.php dashboard.php exec_helper.php index.php logout.php"

echo "Updating web admin files in $APP_DIR ..."
echo ""

for f in $FILES; do
    printf "  %-30s" "$f"
    wget -q -O "$APP_DIR/$f" "$GITHUB_RAW/webadmin/www/$f" && echo "ok" || echo "FAILED"
done

chown "$TEACHER:www-data" "$APP_DIR"/*.php
chmod 644 "$APP_DIR"/*.php
chmod 640 "$APP_DIR/config.php"

echo ""
echo "Done."
