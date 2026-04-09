#!/bin/bash

# wsb2-webadmin-install.sh
# Installs the WSB2 web admin panel at http://teacher.domain/sitemanagement/
# Run as root: sudo bash wsb2-webadmin-install.sh

set -euo pipefail

_issue=$(cat /etc/issue.net)
if [[ "$_issue" != 'Debian GNU/Linux 12' && "$_issue" != 'Debian GNU/Linux 13' ]]; then
    echo -e "\nRequires Debian GNU/Linux 12 or 13. Current: $_issue\n"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo -e "\nRun as root: sudo bash wsb2-webadmin-install.sh\n"
    exit 1
fi

GITHUB_RAW="https://raw.githubusercontent.com/koo2018/websitebuilding2/main"
WRAPPER_DIR="/opt/wsb2-webadmin/bin"
SUDOERS_FILE="/etc/sudoers.d/wsb2-webadmin"

echo "
WSB2 Web Admin — Installation
================================
"

# --- Ask for teacher's username ---
read -p "Teacher's username [teacher]: " TEACHER
TEACHER=${TEACHER:-teacher}
echo

if ! id "$TEACHER" &>/dev/null; then
    echo "User '$TEACHER' not found. Run wsb2-install.sh first."
    exit 1
fi

TEACHER_HOME=$(getent passwd "$TEACHER" | cut -d: -f6)
BIN_DIR="$TEACHER_HOME/.wsb2/bin"
WWW_DIR="$TEACHER_HOME/.wsb2/www"
APP_DIR="$WWW_DIR/sitemanagement"

if [ ! -f "$BIN_DIR/wsb2-newstudent.sh" ]; then
    echo "Not found: $BIN_DIR/wsb2-newstudent.sh"
    echo "Make sure wsb2-install.sh has been run first."
    exit 1
fi

# Read domain that was embedded during wsb2-install.sh
DOMAIN=$(grep '^hname=' "$BIN_DIR/wsb2-newstudent.sh" | cut -d'"' -f2)
if [ -z "$DOMAIN" ]; then
    echo "Cannot read domain from wsb2-newstudent.sh"
    exit 1
fi

echo "Teacher : $TEACHER"
echo "Domain  : $DOMAIN"
echo "App URL : http://$TEACHER.$DOMAIN/sitemanagement/"
echo ""

# --- Ask for admin password ---
echo "Set a password for the web admin interface:"
while true; do
    read -s -p "Password: " PASS1; echo
    read -s -p "Repeat  : " PASS2; echo
    if [ -n "$PASS1" ] && [ "$PASS1" = "$PASS2" ]; then
        break
    fi
    echo "Passwords don't match or are empty. Try again."
done
echo ""

# Hash via PHP, passing password through env var to avoid shell escaping issues
HASH=$(WSB2_RAW="$PASS1" php -r "echo password_hash(getenv('WSB2_RAW'), PASSWORD_BCRYPT);")
unset PASS1 PASS2
if [ -z "$HASH" ]; then
    echo "Failed to hash password (is PHP installed?)"
    exit 1
fi

echo "Installing..."

# --- 1. Create root-owned wrapper directory ---
mkdir -p "$WRAPPER_DIR"
chown root:root /opt/wsb2-webadmin
chmod 755 /opt/wsb2-webadmin
chmod 700 "$WRAPPER_DIR"

# --- 2. Download and configure wrapper scripts ---
for script in wa-newstudent.sh wa-delstudent.sh wa-offsite.sh wa-onsite.sh wa-addgroup.sh wa-delgroup.sh; do
    wget -q -O "$WRAPPER_DIR/$script" "$GITHUB_RAW/webadmin/bin/$script" || {
        echo "Failed to download $script"
        exit 1
    }
done

# Patch TEACHER_BIN path into each wrapper
# sed-safe: escape special chars in BIN_DIR for use as replacement string
BIN_ESCAPED=$(printf '%s\n' "$BIN_DIR" | sed 's/[\/&]/\\&/g')
for script in "$WRAPPER_DIR"/*.sh; do
    sed -i "s|^TEACHER_BIN=\"\"|TEACHER_BIN=\"$BIN_ESCAPED\"|" "$script"
done

chown root:root "$WRAPPER_DIR"/*.sh
chmod 700 "$WRAPPER_DIR"/*.sh

# --- 3. Ensure helper scripts exist in teacher's bin ---
for script in wsb2-addgroup.sh wsb2-delgroup.sh wsb2-offsite.sh wsb2-onsite.sh; do
    if [ ! -f "$BIN_DIR/$script" ]; then
        echo "  Downloading missing $script ..."
        wget -q -O "$BIN_DIR/$script" "$GITHUB_RAW/$script" || {
            echo "Failed to download $script"
            exit 1
        }
        chown "$TEACHER:$TEACHER" "$BIN_DIR/$script"
        chmod 700 "$BIN_DIR/$script"
    fi
done

# --- 4. Configure sudoers ---
cat > "$SUDOERS_FILE" << SUDOERS
# WSB2 web admin — managed by wsb2-webadmin-install.sh
# Do not edit manually.
Defaults!${WRAPPER_DIR}/wa-newstudent.sh !requiretty
Defaults!${WRAPPER_DIR}/wa-delstudent.sh !requiretty
Defaults!${WRAPPER_DIR}/wa-offsite.sh    !requiretty
Defaults!${WRAPPER_DIR}/wa-onsite.sh     !requiretty
Defaults!${WRAPPER_DIR}/wa-addgroup.sh   !requiretty
Defaults!${WRAPPER_DIR}/wa-delgroup.sh   !requiretty
www-data ALL=(root) NOPASSWD: ${WRAPPER_DIR}/wa-newstudent.sh
www-data ALL=(root) NOPASSWD: ${WRAPPER_DIR}/wa-delstudent.sh
www-data ALL=(root) NOPASSWD: ${WRAPPER_DIR}/wa-offsite.sh
www-data ALL=(root) NOPASSWD: ${WRAPPER_DIR}/wa-onsite.sh
www-data ALL=(root) NOPASSWD: ${WRAPPER_DIR}/wa-addgroup.sh
www-data ALL=(root) NOPASSWD: ${WRAPPER_DIR}/wa-delgroup.sh
SUDOERS

chmod 440 "$SUDOERS_FILE"
visudo -c -f "$SUDOERS_FILE" || {
    echo "Sudoers syntax error — removing file."
    rm -f "$SUDOERS_FILE"
    exit 1
}

# --- 5. Download PHP application files ---
mkdir -p "$APP_DIR"
for file in index.php dashboard.php action.php logout.php auth.php exec_helper.php data.php; do
    wget -q -O "$APP_DIR/$file" "$GITHUB_RAW/webadmin/www/$file" || {
        echo "Failed to download $file"
        exit 1
    }
done

# --- 6. Generate config.php (never stored in the repository) ---
# Uses PHP's var_export() via env vars to safely handle any special chars.
export WSB2_CFG_HASH="$HASH"
export WSB2_CFG_BIN="$BIN_DIR"
export WSB2_CFG_TEACHER="$TEACHER"
export WSB2_CFG_DOMAIN="$DOMAIN"
export WSB2_CFG_PATH="$APP_DIR/config.php"

php -r '
$h = var_export(getenv("WSB2_CFG_HASH"),    true);
$b = var_export(getenv("WSB2_CFG_BIN"),     true);
$t = var_export(getenv("WSB2_CFG_TEACHER"), true);
$d = var_export(getenv("WSB2_CFG_DOMAIN"),  true);
$c  = "<?php\n";
$c .= "define('"'"'WSB2_PASSWORD_HASH'"'"', $h);\n";
$c .= "define('"'"'WSB2_SESSION_NAME'"'"',  '"'"'wsb2admin'"'"');\n";
$c .= "define('"'"'WSB2_TEACHER_BIN'"'"',   $b);\n";
$c .= "define('"'"'WSB2_TEACHER'"'"',       $t);\n";
$c .= "define('"'"'WSB2_DOMAIN'"'"',        $d);\n";
file_put_contents(getenv("WSB2_CFG_PATH"), $c);
'

unset WSB2_CFG_HASH WSB2_CFG_BIN WSB2_CFG_TEACHER WSB2_CFG_DOMAIN WSB2_CFG_PATH

# --- 7. Set ownership and permissions ---
chown -R "$TEACHER:www-data" "$APP_DIR"
chmod 755 "$APP_DIR"
find "$APP_DIR" -type f -exec chmod 644 {} \;
chmod 640 "$APP_DIR/config.php"  # config has password hash — tighter permissions

echo ""
echo "Done!"
echo ""
echo "  Web admin : http://$TEACHER.$DOMAIN/sitemanagement/"
echo ""
echo "  To remove : sudo bash wsb2-webadmin-remove.sh"
echo ""
