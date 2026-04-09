#!/bin/bash
set -euo pipefail
TEACHER_BIN=""

if [ $# -ne 1 ]; then echo "Usage: wa-delstudent.sh STUDENT" >&2; exit 1; fi

STUDENT="$1"
if [[ ! "$STUDENT" =~ ^[a-z][a-z0-9_-]{1,31}$ ]]; then echo "Invalid student name" >&2; exit 1; fi

RESERVED=(root daemon bin sys www-data nobody mail)
for r in "${RESERVED[@]}"; do
    if [[ "$STUDENT" == "$r" ]]; then echo "Reserved name" >&2; exit 1; fi
done

exec "$TEACHER_BIN/wsb2-delstudent.sh" "$STUDENT"
