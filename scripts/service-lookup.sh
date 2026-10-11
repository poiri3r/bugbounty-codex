#!/usr/bin/env bash
# Print only ledger rows for one exact slug; never dump the ledger.
set -euo pipefail
if (($# != 1)) || [[ ! "$1" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  printf 'Usage: %s SLUG\n' "$(basename "$0")" >&2
  exit 2
fi
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ledger="$script_dir/../project/SERVICE.md"
[[ -f "$ledger" ]] || { printf 'Missing SERVICE ledger\n' >&2; exit 1; }
awk -v slug="$1" -v needle="\`$1\`" '
  /^\| S-[0-9]+[[:space:]]*\|/ {
    row = $0
    sub(/^\|[^|]*\|/, "", row)
    split(row, cells, "|")
    if (index(cells[1], needle)) { print NR ":" $0; found = 1 }
  }
  END { if (!found) print "not-found: " slug }
' "$ledger"
