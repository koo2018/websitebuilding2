#!/bin/bash
set -euo pipefail
TEACHER_BIN=""

if [ $# -ne 1 ]; then echo "Usage: wa-delgroup.sh GROUP" >&2; exit 1; fi

GROUP="$1"
if [[ ! "$GROUP" =~ ^[a-z][a-z0-9_-]{1,31}$ ]]; then echo "Invalid group name" >&2; exit 1; fi

exec "$TEACHER_BIN/wsb2-delgroup.sh" "$GROUP"
