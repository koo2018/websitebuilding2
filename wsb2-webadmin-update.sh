#!/bin/bash

# wsb2-webadmin-update.sh
# Updates WSB2 web admin PHP files from GitHub (keeps config.php intact).
# Run as teacher: wsb2-webadmin-update

set -euo pipefail

TEACHER_HOME=$(eval echo ~"$(whoami)")
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

chmod 644 "$APP_DIR"/*.php
chmod 640 "$APP_DIR/config.php"

echo ""
echo "Done."
