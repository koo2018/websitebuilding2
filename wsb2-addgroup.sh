#!/bin/bash
# Creates a student group and its home directory.
# Usage: wsb2-addgroup.sh <group>
# Run as root (directly or via sudo).

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: wsb2-addgroup.sh <group>" >&2
    exit 1
fi

GROUP="$1"

if grep -q "^$GROUP:" /etc/group; then
    echo "Group '$GROUP' already exists"
    exit 0
fi

addgroup "$GROUP"
mkdir -p "/home/$GROUP"
chown "root:$GROUP" "/home/$GROUP"
chmod 711 "/home/$GROUP"
echo "Group '$GROUP' created"
