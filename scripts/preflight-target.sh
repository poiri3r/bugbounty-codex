#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s --slug SLUG --patchstack-vdp no|active --manufacturer-vdp no|active --public-duplicate-check no-match|found [--change-signal TEXT] [--metadata FILE] [--min-installs N] [--reaudit-after-days N]\n' "$(basename "$0")"
}

slug=""
patchstack_vdp="unknown"
manufacturer_vdp="unknown"
public_duplicate_check="unknown"
change_signal=""
metadata_file=""
min_installs=10000
reaudit_after_days=365

while (($#)); do
  case "$1" in
    --slug) slug="${2:-}"; shift ;;
    --patchstack-vdp) patchstack_vdp="${2:-}"; shift ;;
    --manufacturer-vdp) manufacturer_vdp="${2:-}"; shift ;;
    --public-duplicate-check) public_duplicate_check="${2:-}"; shift ;;
    --change-signal) change_signal="${2:-}"; shift ;;
    --metadata) metadata_file="${2:-}"; shift ;;
    --min-installs) min_installs="${2:-}"; shift ;;
    --reaudit-after-days) reaudit_after_days="${2:-}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown or incomplete option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]] || { printf 'rejected: invalid slug\n'; exit 3; }
[[ "$min_installs" =~ ^[0-9]+$ ]] || { printf 'rejected: invalid min installs\n'; exit 3; }
[[ "$reaudit_after_days" =~ ^[1-9][0-9]*$ ]] || { printf 'rejected: invalid reaudit age\n'; exit 3; }
[[ "$patchstack_vdp" == no && "$manufacturer_vdp" == no ]] || {
  printf 'rejected: VDP must be explicitly no (patchstack=%s manufacturer=%s)\n' "$patchstack_vdp" "$manufacturer_vdp"
  exit 3
}
[[ "$public_duplicate_check" == no-match ]] || {
  printf 'rejected: public duplicate check must be explicitly no-match (result=%s)\n' "$public_duplicate_check"
  exit 3
}
[[ "$change_signal" != *$'\n'* ]] || { printf 'rejected: change signal must be one line\n'; exit 3; }

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
project_root="$(cd -- "$script_dir/.." && pwd -P)"
ledger="$project_root/project/SERVICE.md"
[[ -f "$ledger" ]] || { printf 'Missing target ledger: %s\n' "$ledger" >&2; exit 1; }
temporary=""
if [[ -z "$metadata_file" ]]; then
  command -v curl >/dev/null || { printf 'curl is required\n' >&2; exit 1; }
  temporary="$(mktemp)"
  trap 'rm -f -- "$temporary"' EXIT
  curl -fsSLG 'https://api.wordpress.org/plugins/info/1.2/' \
    --data-urlencode 'action=plugin_information' \
    --data-urlencode "request[slug]=$slug" >"$temporary" || {
      printf 'rejected: WordPress.org current target unavailable\n'
      exit 3
    }
  metadata_file="$temporary"
fi

command -v python3 >/dev/null || { printf 'python3 is required\n' >&2; exit 1; }
python3 - "$metadata_file" "$slug" "$min_installs" "$change_signal" "$ledger" "$reaudit_after_days" <<'PY'
import json
import re
import sys
from datetime import date, datetime, timezone

path, expected_slug, minimum, change_signal, ledger_path, reaudit_days = (
    sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4].strip(), sys.argv[5], int(sys.argv[6])
)
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

slug = data.get("slug")
version = str(data.get("version") or "")
installs = int(data.get("active_installs") or 0)
updated_raw = str(data.get("last_updated") or "")
download = str(data.get("download_link") or "")
if slug != expected_slug or not version or not download:
    print("rejected: incomplete official metadata")
    raise SystemExit(3)
if installs < minimum:
    print(f"rejected: active installs {installs} < {minimum}")
    raise SystemExit(3)

updated = None
for fmt in ("%Y-%m-%d %I:%M%p %Z", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
    try:
        updated = datetime.strptime(updated_raw, fmt).replace(tzinfo=timezone.utc)
        break
    except ValueError:
        pass
now = datetime.now(timezone.utc)
if updated is None:
    print(f"rejected: stale or invalid last_updated {updated_raw!r}")
    raise SystemExit(3)

def years_ago(years):
    try:
        return now.replace(year=now.year - years)
    except ValueError:
        return now.replace(year=now.year - years, day=28)

if updated < years_ago(2):
    print(f"rejected: last_updated exceeds 24 months {updated_raw!r}")
    raise SystemExit(3)
if updated < years_ago(1) and not change_signal:
    print("rejected: 12-24 month target requires a concrete patch diff or new attack-surface signal")
    raise SystemExit(3)

existing = []
with open(ledger_path, encoding="utf-8") as handle:
    for line in handle:
        if not re.match(r"^\| S-\d+\s*\|", line):
            continue
        cells = [cell.strip() for cell in line.split("|")[1:-1]]
        if len(cells) < 6 or f"`{expected_slug}`" not in cells[1]:
            continue
        match = re.search(rf"`{re.escape(expected_slug)}`\)\s+([^\s|(]+)", cells[1])
        recorded_version = "" if cells[1].endswith("버전 미기록") else (match.group(1) if match else "")
        try:
            audited = date.fromisoformat(cells[4])
        except ValueError:
            audited = None
        existing.append((recorded_version, audited))

reaudit = "new-target"
if existing:
    matching_dates = [audited for recorded, audited in existing if recorded == version and audited]
    recorded_versions = {recorded for recorded, _ in existing if recorded}
    if version not in recorded_versions:
        if any(not recorded for recorded, _ in existing):
            print(f"rejected: ledger version missing slug={expected_slug}")
            raise SystemExit(3)
        reaudit = "new-version"
    elif matching_dates and (now.date() - max(matching_dates)).days >= reaudit_days:
        reaudit = "audit-age"
    else:
        last = max(matching_dates).isoformat() if matching_dates else "unknown"
        print(f"rejected: already audited slug={expected_slug} version={version} last_audit={last}")
        raise SystemExit(3)

print("eligible")
print(f"slug={slug}")
print(f"version={version}")
print(f"active_installs={installs}")
print(f"last_updated={updated_raw}")
print(f"freshness={'conditional-change-signal' if updated < years_ago(1) else 'default'}")
print(f"reaudit={reaudit}")
print(f"download_link={download}")
PY
