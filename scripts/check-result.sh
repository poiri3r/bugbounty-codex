#!/usr/bin/env bash
set -euo pipefail

candidate=false
if [[ "${1:-}" == --candidate ]]; then
  candidate=true
  shift
fi

if (($# != 1)); then
  printf 'Usage: %s [--candidate] RESULT.md\n' "$(basename "$0")" >&2
  exit 2
fi

result="$1"
[[ -f "$result" && "$(basename -- "$result")" == RESULT.md ]] || {
  printf 'Invalid RESULT path: %s\n' "$result" >&2
  exit 2
}

lines="$(wc -l <"$result")"
bytes="$(wc -c <"$result")"
if [[ "$candidate" == false ]]; then
  ((lines <= 80)) || { printf 'RESULT too long: %s lines (max 80)\n' "$lines" >&2; exit 1; }
  ((bytes <= 12000)) || { printf 'RESULT too large: %s bytes (max 12000)\n' "$bytes" >&2; exit 1; }
fi
raw_pattern='^[[:space:]]*(HTTP/[0-9]|(Set-Cookie|Cookie|Authorization):|```|[{}][,]?[[:space:]]*$|"[^"]+"[[:space:]]*:|(SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP)[[:space:]]|console\.|DevTools listening)'
if rg -qi "$raw_pattern" "$result"; then
  printf 'RESULT contains inline raw HTTP/JSON/log data; store it as an artifact and cite its path\n' >&2
  exit 1
fi
rg -q '후보|candidate|판정|결론' "$result" || { printf 'RESULT lacks a verdict\n' >&2; exit 1; }
rg -q '근거|evidence|Evidence' "$result" || { printf 'RESULT lacks evidence paths\n' >&2; exit 1; }
printf 'RESULT ok: %s lines, %s bytes, candidate=%s\n' "$lines" "$bytes" "$candidate"
