#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s <destination>\n' "$(basename "$0")"
}

destination=""

while (($#)); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -*) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *)
      if [[ -n "$destination" ]]; then
        printf 'Only one destination is allowed.\n' >&2
        usage >&2
        exit 2
      fi
      destination="$1"
      ;;
  esac
  shift
done

if [[ -z "$destination" ]]; then
  usage >&2
  exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
template_root="$(cd -- "$script_dir/.." && pwd -P)"
destination="$(realpath -m -- "$destination")"

if [[ "$destination" == "$template_root" ]]; then
  printf 'Destination cannot be the template root.\n' >&2
  exit 2
fi

files=(
  .gitignore
  AGENTS.md
  README.md
  Makefile
  WORKFLOW.md
  lab/.env.example
  lab/compose.yaml
  lab/nginx.conf
  docs/agents/WORDPRESS-AUDIT.md
  docs/agents/XSS-TESTING.md
  docs/agents/INBOX.md
  report/HOWTOUSE.md
  scripts/new-project.sh
  scripts/preflight-target.sh
  scripts/task-contract.sh
  scripts/check-result.sh
  scripts/service-lookup.sh
  scripts/cleanup-task.py
  scripts/prepare-submission.py
  scripts/fill-wordfence-form.js
  scripts/RETENTION.md
  scripts/RECORDING.md
  scripts/screen_record.ps1
  scripts/cdp-eval.js
  scripts/test-efficient-workflow.sh
  scripts/tests/RESULT.md
  scripts/tests/plugin-info.json
  scripts/tests/test-retention.py
  scripts/tests/test-screen-record.ps1
  scripts/tests/test-submission.py
  scripts/templates/HANDOFF.md
  scripts/templates/STATUS.md
  scripts/templates/RULES.md
  scripts/templates/SERVICE.md
  scripts/templates/submission.json
  scripts/templates/CREDENTIAL.md
)

for relative_path in "${files[@]}"; do
  if [[ ! -f "$template_root/$relative_path" ]]; then
    printf 'Missing template file: %s\n' "$relative_path" >&2
    exit 1
  fi
done

if [[ "$destination" == "/" || -L "$destination" ]]; then
  printf 'Invalid destination: %s\n' "$destination" >&2
  exit 2
fi

destination_existed=false
if [[ -e "$destination" ]]; then
  if [[ ! -d "$destination" ]]; then
    printf 'Destination is not a directory: %s\n' "$destination" >&2
    exit 1
  fi
  if find "$destination" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
    printf 'Destination must be empty: %s\n' "$destination" >&2
    exit 1
  fi
  destination_existed=true
fi

destination_parent="$(dirname -- "$destination")"
destination_name="$(basename -- "$destination")"
mkdir -p -- "$destination_parent"
staging_dir="$(mktemp -d -- "$destination_parent/.${destination_name}.tmp.XXXXXX")"

cleanup() {
  if [[ -n "${staging_dir:-}" && -d "$staging_dir" ]]; then
    rm -rf -- "$staging_dir"
  fi
}
trap cleanup EXIT

for relative_path in "${files[@]}"; do
  mkdir -p -- "$staging_dir/$(dirname -- "$relative_path")"
  cp -- "$template_root/$relative_path" "$staging_dir/$relative_path"
done
mkdir -p -- "$staging_dir/project" "$staging_dir/tmp" "$staging_dir/inbox"
cp -- "$template_root/scripts/templates/HANDOFF.md" "$staging_dir/HANDOFF.md"
cp -- "$template_root/scripts/templates/STATUS.md" "$staging_dir/STATUS.md"
cp -- "$template_root/scripts/templates/RULES.md" "$staging_dir/project/RULES.md"
cp -- "$template_root/scripts/templates/SERVICE.md" "$staging_dir/project/SERVICE.md"
cp -- "$template_root/scripts/templates/CREDENTIAL.md" "$staging_dir/project/CREDENTIAL.md"

find "$staging_dir" -type f -exec chmod 0644 {} +
chmod 0755 -- "$staging_dir/scripts/new-project.sh" \
  "$staging_dir/scripts/preflight-target.sh" "$staging_dir/scripts/task-contract.sh" \
  "$staging_dir/scripts/check-result.sh" "$staging_dir/scripts/service-lookup.sh" \
  "$staging_dir/scripts/cleanup-task.py" "$staging_dir/scripts/prepare-submission.py" \
  "$staging_dir/scripts/fill-wordfence-form.js" "$staging_dir/scripts/test-efficient-workflow.sh"

if [[ "$destination_existed" == true ]]; then
  rmdir -- "$destination"
fi
mv -T -- "$staging_dir" "$destination"
staging_dir=""
trap - EXIT

printf 'Created: %s\n' "$destination"
