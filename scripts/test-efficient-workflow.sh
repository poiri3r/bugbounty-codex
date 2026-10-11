#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

freshness_root="$(mktemp -d)"
trap 'rm -rf -- "$freshness_root"' EXIT
preflight_root="$freshness_root/preflight"
mkdir -p "$preflight_root/scripts" "$preflight_root/project"
cp "$script_dir/preflight-target.sh" "$preflight_root/scripts/preflight-target.sh"
preflight="$preflight_root/scripts/preflight-target.sh"
python3 - "$script_dir/tests/plugin-info.json" "$freshness_root" "$preflight_root/project/SERVICE.md" <<'PY'
import json
import sys
from datetime import datetime, timedelta, timezone

source, destination, ledger = sys.argv[1:]
with open(source, encoding="utf-8") as handle:
    fixture = json.load(handle)
for name, age in (("recent", 30), ("conditional", 500), ("expired", 800)):
    data = dict(fixture)
    data["last_updated"] = (datetime.now(timezone.utc) - timedelta(days=age)).strftime("%Y-%m-%d %I:%M%p GMT")
    with open(f"{destination}/{name}.json", "w", encoding="utf-8") as handle:
        json.dump(data, handle)
data = dict(fixture)
data["slug"] = "login-as-users"
data["last_updated"] = (datetime.now(timezone.utc) - timedelta(days=30)).strftime("%Y-%m-%d %I:%M%p GMT")
with open(f"{destination}/mention-only.json", "w", encoding="utf-8") as handle:
    json.dump(data, handle)
for name, version in (("existing-same", "5.4.13"), ("existing-new", "5.4.14")):
    data = dict(fixture)
    data["slug"] = "file-manager-advanced"
    data["version"] = version
    data["download_link"] = f"https://downloads.wordpress.org/plugin/file-manager-advanced.{version}.zip"
    data["last_updated"] = (datetime.now(timezone.utc) - timedelta(days=30)).strftime("%Y-%m-%d %I:%M%p GMT")
    with open(f"{destination}/{name}.json", "w", encoding="utf-8") as handle:
        json.dump(data, handle)
data = dict(fixture)
data["slug"] = "unknown-version-fixture"
data["version"] = "1.2.3"
data["download_link"] = "https://downloads.wordpress.org/plugin/unknown-version-fixture.1.2.3.zip"
data["last_updated"] = (datetime.now(timezone.utc) - timedelta(days=30)).strftime("%Y-%m-%d %I:%M%p GMT")
with open(f"{destination}/unknown-version.json", "w", encoding="utf-8") as handle:
    json.dump(data, handle)
audited = (datetime.now(timezone.utc) - timedelta(days=30)).date().isoformat()
with open(ledger, "w", encoding="utf-8") as handle:
    handle.write(
        "| S-001 | Fixture (`file-manager-advanced`) 5.4.13 | 100,000 | `hash` | "
        f"{audited} | T-001 · fixture · 후보 없음 |\n"
    )
    handle.write(
        "| S-002 | Unknown (`unknown-version-fixture`) 버전 미기록 | 미기록 | 미기록 | "
        "미기록 | historical fixture |\n"
    )
PY

output="$($preflight \
  --slug token-efficient-fixture \
  --patchstack-vdp no \
  --manufacturer-vdp no \
  --public-duplicate-check no-match \
  --metadata "$freshness_root/recent.json")"
grep -qx eligible <<<"$(head -n 1 <<<"$output")"

output="$($preflight \
  --slug login-as-users \
  --patchstack-vdp no \
  --manufacturer-vdp no \
  --public-duplicate-check no-match \
  --metadata "$freshness_root/mention-only.json")"
grep -qx eligible <<<"$(head -n 1 <<<"$output")"

if output="$($preflight \
  --slug file-manager-advanced \
  --patchstack-vdp no \
  --manufacturer-vdp no \
  --public-duplicate-check no-match \
  --metadata "$freshness_root/existing-same.json" 2>&1)"; then
  printf 'Expected recently audited same version to fail.\n' >&2
  exit 1
fi
grep -q '^rejected: already audited slug=file-manager-advanced version=5.4.13 ' <<<"$output"

output="$($preflight \
  --slug file-manager-advanced \
  --patchstack-vdp no \
  --manufacturer-vdp no \
  --public-duplicate-check no-match \
  --metadata "$freshness_root/existing-new.json")"
grep -qx 'reaudit=new-version' <<<"$(grep '^reaudit=' <<<"$output")"

output="$($preflight \
  --slug file-manager-advanced \
  --patchstack-vdp no \
  --manufacturer-vdp no \
  --public-duplicate-check no-match \
  --reaudit-after-days 1 \
  --metadata "$freshness_root/existing-same.json")"
grep -qx 'reaudit=audit-age' <<<"$(grep '^reaudit=' <<<"$output")"

if output="$($preflight \
  --slug unknown-version-fixture \
  --patchstack-vdp no \
  --manufacturer-vdp no \
  --public-duplicate-check no-match \
  --metadata "$freshness_root/unknown-version.json" 2>&1)"; then
  printf 'Expected unknown ledger version to fail conservatively.\n' >&2
  exit 1
fi
grep -qx 'rejected: ledger version missing slug=unknown-version-fixture' <<<"$output"

if "$preflight" \
  --slug token-efficient-fixture \
  --patchstack-vdp unknown \
  --manufacturer-vdp no \
  --public-duplicate-check no-match \
  --metadata "$freshness_root/recent.json" >/dev/null; then
  printf 'Expected unknown VDP to fail.\n' >&2
  exit 1
fi

if "$preflight" \
  --slug token-efficient-fixture \
  --patchstack-vdp no \
  --manufacturer-vdp no \
  --public-duplicate-check unknown \
  --metadata "$freshness_root/recent.json" >/dev/null; then
  printf 'Expected unknown public duplicate check to fail.\n' >&2
  exit 1
fi

if "$preflight" \
  --slug token-efficient-fixture --patchstack-vdp no --manufacturer-vdp no \
  --public-duplicate-check no-match --metadata "$freshness_root/conditional.json" >/dev/null; then
  printf 'Expected 12-24 month target without change signal to fail.\n' >&2
  exit 1
fi
"$preflight" \
  --slug token-efficient-fixture --patchstack-vdp no --manufacturer-vdp no \
  --public-duplicate-check no-match --change-signal 'new public REST route' \
  --metadata "$freshness_root/conditional.json" >/dev/null
if "$preflight" \
  --slug token-efficient-fixture --patchstack-vdp no --manufacturer-vdp no \
  --public-duplicate-check no-match --change-signal 'new public REST route' \
  --metadata "$freshness_root/expired.json" >/dev/null; then
  printf 'Expected target older than 24 months to fail.\n' >&2
  exit 1
fi

contract="$($script_dir/task-contract.sh 41 T-001 token-efficient-fixture 1.2.3 'public REST write')"
grep -q 'fork_turns="none"' <<<"$contract"
grep -q 'docs/agents/WORDPRESS-AUDIT.md' <<<"$contract"
grep -q -- '- 작업 초기에 plugin 기능에서 최대 3개를 도출한다' <<<"$contract"
grep -q '가장 강한 가설 최대 2개' <<<"$contract"
grep -q '80줄·12KB' <<<"$contract"
grep -q '별도 검토 에이전트나 새 T-ID를 만들지 않는다' <<<"$contract"
grep -q '환경을 종료하기 전에 scripts/RECORDING.md' <<<"$contract"
grep -q '차단: 영상 대기' <<<"$contract"
grep -q '영상 재생 검수 PASS 뒤에만' <<<"$contract"
grep -q '완료: inbox/41/T-001/RESULT.md' <<<"$contract"
grep -q 'prepare-submission.py inbox/41/T-001 --write-report' <<<"$contract"
grep -q 'project/services, evidence/F-ID를 수정·생성하지 않는다' <<<"$contract"
grep -q '^#' "$script_dir/../project/RULES.md"

contract="$($script_dir/task-contract.sh 41 T-002 token-efficient-fixture 1.2.3 'public REST write' \
  'Booking token은 다른 사용자 booking을 변경할 수 없어야 한다.' \
  'Public input은 admin HTML에서 실행되면 안 된다.' \
  'Upload는 intended root 밖에 기록되면 안 된다.')"
grep -q -- '- Booking token은 다른 사용자 booking을 변경할 수 없어야 한다.' <<<"$contract"
grep -q -- '- Upload는 intended root 밖에 기록되면 안 된다.' <<<"$contract"

if "$script_dir/task-contract.sh" 41 T-003 token-efficient-fixture 1.2.3 focus one two three four >/dev/null 2>&1; then
  printf 'Expected more than three plugin invariants to fail.\n' >&2
  exit 1
fi
if "$script_dir/task-contract.sh" 41 T-003 token-efficient-fixture 1.2.3 focus $'one\ntwo' >/dev/null 2>&1; then
  printf 'Expected multiline plugin invariant to fail.\n' >&2
  exit 1
fi

"$script_dir/check-result.sh" "$script_dir/tests/RESULT.md" >/dev/null

test_root="$freshness_root/workflow"
mkdir -p "$test_root/candidate" "$test_root/raw"

{
  printf '# candidate\n\n## 판정\n\n- 후보 있음.\n\n## 근거\n\n- artifacts/evidence.txt\n'
  for number in $(seq 1 82); do printf -- '- detail %s\n' "$number"; done
} >"$test_root/candidate/RESULT.md"
if "$script_dir/check-result.sh" "$test_root/candidate/RESULT.md" >/dev/null 2>&1; then
  printf 'Expected oversized non-candidate mode to fail.\n' >&2
  exit 1
fi
"$script_dir/check-result.sh" --candidate "$test_root/candidate/RESULT.md" >/dev/null

printf '# result\n\n## 판정\n- 후보 없음.\n\n## 근거\n- artifacts/raw.http\n\nHTTP/1.1 200 OK\n' >"$test_root/raw/RESULT.md"
if "$script_dir/check-result.sh" "$test_root/raw/RESULT.md" >/dev/null 2>&1; then
  printf 'Expected inline raw HTTP to fail.\n' >&2
  exit 1
fi

for raw_case in json sql console; do mkdir -p "$test_root/$raw_case"; done
printf '# result\n\n## 판정\n- 후보 없음.\n\n## 근거\n- artifacts/raw.json\n\n{\n  "secret": "fixture"\n}\n' >"$test_root/json/RESULT.md"
printf '# result\n\n## 판정\n- 후보 없음.\n\n## 근거\n- artifacts/raw.sql\n\nSELECT * FROM wp_users;\n' >"$test_root/sql/RESULT.md"
printf '# result\n\n## 판정\n- 후보 없음.\n\n## 근거\n- artifacts/browser.log\n\nconsole.log("fixture");\n' >"$test_root/console/RESULT.md"
for raw_case in json sql console; do
  if "$script_dir/check-result.sh" "$test_root/$raw_case/RESULT.md" >/dev/null 2>&1; then
    printf 'Expected inline raw %s data to fail.\n' "$raw_case" >&2
    exit 1
  fi
done

"$script_dir/new-project.sh" "$test_root/generated" >/dev/null
test -f "$test_root/generated/docs/agents/XSS-TESTING.md"
test -f "$test_root/generated/docs/agents/WORDPRESS-AUDIT.md"
test -f "$test_root/generated/docs/agents/INBOX.md"
test -f "$test_root/generated/README.md"
test -f "$test_root/generated/Makefile"
test -f "$test_root/generated/lab/.env.example"
test -f "$test_root/generated/lab/compose.yaml"
test -f "$test_root/generated/lab/nginx.conf"
test -f "$test_root/generated/scripts/RECORDING.md"
test -f "$test_root/generated/scripts/screen_record.ps1"
test -f "$test_root/generated/scripts/cdp-eval.js"
test -f "$test_root/generated/scripts/service-lookup.sh"
test -f "$test_root/generated/scripts/cleanup-task.py"
test -f "$test_root/generated/scripts/prepare-submission.py"
test -f "$test_root/generated/scripts/fill-wordfence-form.js"
test -f "$test_root/generated/scripts/templates/submission.json"
test -f "$test_root/generated/scripts/RETENTION.md"
test -f "$test_root/generated/scripts/test-efficient-workflow.sh"
test -f "$test_root/generated/scripts/tests/test-retention.py"
test -f "$test_root/generated/scripts/tests/test-screen-record.ps1"
test -f "$test_root/generated/scripts/tests/test-submission.py"
test -d "$test_root/generated/tmp"
test -d "$test_root/generated/inbox"
test ! -e "$test_root/generated/SETUP.md"
test ! -e "$test_root/generated/scripts/start-controller.sh"
grep -qx '/tmp/' "$test_root/generated/.gitignore"
grep -qx '/inbox/' "$test_root/generated/.gitignore"
python3 -B "$script_dir/tests/test-retention.py"
python3 -B "$script_dir/tests/test-submission.py"
node "$script_dir/fill-wordfence-form.js" --self-test >/dev/null
test ! -e "$test_root/generated/scripts/cdp-eval.py"
"$test_root/generated/scripts/preflight-target.sh" \
  --slug token-efficient-fixture \
  --patchstack-vdp no \
  --manufacturer-vdp no \
  --public-duplicate-check no-match \
  --metadata "$freshness_root/recent.json" | grep -qx eligible
printf 'efficient workflow tests passed\n'
