#!/bin/bash

# wsb2-webadmin-passwd.sh
# Changes the password for the WSB2 web admin interface (/sitemanagement/).
# Run as root: sudo wsb2-webadmin-passwd

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo -e "\nRun as root: sudo wsb2-webadmin-passwd\n"
    exit 1
fi

read -p "Teacher's username [teacher]: " TEACHER
TEACHER=${TEACHER:-teacher}

TEACHER_HOME=$(getent passwd "$TEACHER" 2>/dev/null | cut -d: -f6 || true)
if [ -z "$TEACHER_HOME" ]; then
    echo "User '$TEACHER' not found."
    exit 1
fi

CONFIG="$TEACHER_HOME/.wsb2/www/sitemanagement/config.php"
if [ ! -f "$CONFIG" ]; then
    echo "Not found: $CONFIG"
    echo "Run wsb2-webadmin-install.sh first."
    exit 1
fi

while true; do
    read -s -p "New password: " P1; echo
    read -s -p "Repeat      : " P2; echo
    [ -n "$P1" ] && [ "$P1" = "$P2" ] && break
    echo "Passwords don't match or are empty. Try again."
done

HASH=$(WSB2_RAW="$P1" php -r "echo password_hash(getenv('WSB2_RAW'), PASSWORD_BCRYPT);")
unset P1 P2

if [ -z "$HASH" ]; then
    echo "Failed to hash password (is PHP installed?)"
    exit 1
fi

sed -i "s|define('WSB2_PASSWORD_HASH'.*|define('WSB2_PASSWORD_HASH', '$HASH');|" "$CONFIG"

echo "Password updated."
