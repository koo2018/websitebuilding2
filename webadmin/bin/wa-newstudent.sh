#!/bin/bash
# Wrapper called by www-data via sudo. Validates args, then calls the real script.
# Patched by wsb2-webadmin-install.sh: TEACHER_BIN is set to the actual path.

set -euo pipefail

TEACHER_BIN=""

if [ $# -ne 2 ]; then
    echo "Usage: wa-newstudent.sh GROUP STUDENT" >&2; exit 1
fi

GROUP="$1"
STUDENT="$2"

if [[ ! "$GROUP"   =~ ^[a-z][a-z0-9_-]{1,31}$ ]]; then echo "Invalid group name"   >&2; exit 1; fi
if [[ ! "$STUDENT" =~ ^[a-z][a-z0-9_-]{1,31}$ ]]; then echo "Invalid student name" >&2; exit 1; fi

RESERVED=(root daemon bin sys www-data nobody mail news uucp man)
for r in "${RESERVED[@]}"; do
    if [[ "$GROUP" == "$r" || "$STUDENT" == "$r" ]]; then
        echo "Reserved name: $r" >&2; exit 1
    fi
done

exec "$TEACHER_BIN/wsb2-newstudent.sh" "$GROUP" "$STUDENT"
