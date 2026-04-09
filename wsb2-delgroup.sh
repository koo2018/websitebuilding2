#!/bin/bash
# Deletes a student group and its home directory (only if empty).
# Usage: wsb2-delgroup.sh <group>
# Run as root (directly or via sudo).

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: wsb2-delgroup.sh <group>" >&2
    exit 1
fi

GROUP="$1"

if ! grep -q "^$GROUP:" /etc/group; then
    echo "Group '$GROUP' does not exist" >&2
    exit 1
fi

# Check that no users have this as their primary group
GID=$(getent group "$GROUP" | cut -d: -f3)
COUNT=$(awk -F: -v gid="$GID" '$4 == gid' /etc/passwd | wc -l)
if [ "$COUNT" -gt 0 ]; then
    echo "Cannot delete group '$GROUP': $COUNT member(s) still exist" >&2
    exit 1
fi

# Check /home/<group>/ is empty
if [ -d "/home/$GROUP" ] && [ -n "$(ls -A "/home/$GROUP" 2>/dev/null)" ]; then
    echo "Cannot delete group '$GROUP': /home/$GROUP/ is not empty" >&2
    exit 1
fi

groupdel "$GROUP"
rmdir "/home/$GROUP" 2>/dev/null || true
echo "Group '$GROUP' deleted"
