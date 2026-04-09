#!/bin/bash
set -euo pipefail
TEACHER_BIN=""

if [ $# -ne 1 ]; then echo "Usage: wa-addgroup.sh GROUP" >&2; exit 1; fi

GROUP="$1"
if [[ ! "$GROUP" =~ ^[a-z][a-z0-9_-]{1,31}$ ]]; then echo "Invalid group name" >&2; exit 1; fi

RESERVED=(root daemon bin sys www-data sudo nogroup)
for r in "${RESERVED[@]}"; do
    if [[ "$GROUP" == "$r" ]]; then echo "Reserved name" >&2; exit 1; fi
done

exec "$TEACHER_BIN/wsb2-addgroup.sh" "$GROUP"
