#!/usr/bin/env bash
set -euo pipefail

if (($# < 5 || $# > 8)); then
  printf 'Usage: %s ROUND T-ID SLUG VERSION FOCUS [PLUGIN_INVARIANT ...]\n' "$(basename "$0")" >&2
  exit 2
fi

round="$1"
task_id="$2"
slug="$3"
version="$4"
focus="$5"
plugin_invariants='- 작업 초기에 plugin 기능에서 최대 3개를 도출한다.'
if (($# > 5)); then
  plugin_invariants=""
  for invariant in "${@:6}"; do
    [[ -n "$invariant" && "$invariant" != *$'\n'* ]] || {
      printf 'Each plugin invariant must be one non-empty line.\n' >&2
      exit 2
    }
    plugin_invariants+="${plugin_invariants:+$'\n'}- $invariant"
  done
fi

[[ "$round" =~ ^[0-9]+$ && "$task_id" =~ ^T-[0-9]+$ && "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
  printf 'Invalid round, task ID, or slug.\n' >&2
  exit 2
}

cat <<EOF
Use fork_turns="none". Do not spawn subagents.
목표: $slug $version · $focus
규칙: WORKFLOW.md, project/RULES.md, docs/agents/WORDPRESS-AUDIT.md, docs/agents/INBOX.md를 읽고 준수한다.
출력: inbox/$round/$task_id/RESULT.md와 그 하위 자료만 쓴다. 공유 문서, project/services, evidence/F-ID를 수정·생성하지 않는다.
임시 자료: tmp/$task_id/만 사용한다. scripts/RETENTION.md를 읽고 필요한 근거를 inbox에 남긴다. SERVICE 전체를 읽지 말고 컨트롤러가 준 관련 행만 사용한다. 정리 목록을 제출하고 삭제는 컨트롤러 승인 절차에 맡긴다.
actor: 기본 unauthenticated·stock Subscriber/Customer만. Contributor+ 확인 즉시 종료한다.
plugin invariants:
$plugin_invariants
순서: entry point → attacker-controlled source → authorization/validation → Medium+ sink → 호출 가능성. 하나라도 없으면 해당 경로를 정적으로 종료한다.
잔여 탐색: 배정 검사가 끝나면 기존 invariant 밖의 entry/sink를 한 번 훑고 가장 강한 가설 최대 2개만 추적한다.
동적: 위 3개가 성립할 때만 localhost를 만든다. XSS일 때만 docs/agents/XSS-TESTING.md와 Chrome을 사용한다.
A/B: 최신판 우회 신호 또는 positive control 필요성이 있을 때만 구버전을 사용한다.
제외: DoS, 단순 Missing Auth/IDOR, SSRF, API key, business logic, cache-only low impact.
RESULT: 후보 없으면 80줄·12KB 이하. threat-model delta, invariant별 coverage, 판정, 근거 경로, residual sweep, 다음 단서만 적고 raw 로그는 복사하지 않는다. 완료 전 scripts/check-result.sh로 검사하고, 실제 후보만 --candidate를 붙인다.
후보 주장 전 기본 설정, 새 격리 환경 1개의 전체 흐름 1회, controls, 공개 중복, program gate를 충족한다. race·cache·migration·불안정 결과일 때만 추가 재현한다.
자체 검토: 후보는 위 항목과 증거 경로를 같은 RESULT에 PASS/FAIL로 기록한다. 별도 검토 에이전트나 새 T-ID를 만들지 않는다.
영상: 자체 검토 PASS 후보는 환경을 종료하기 전에 scripts/RECORDING.md에 따라 촬영하고 MP4를 실제 재생 검수한다. 실패·미촬영·미검수면 영상 대기로 기록하고 환경을 보존한다.
제출 자료: 자체 검토와 영상 재생 검수 PASS 후보는 inbox/$round/$task_id/submission.json을 작성하고 python3 scripts/prepare-submission.py inbox/$round/$task_id --write-report 명령을 통과한다. 전체 소스·ZIP·중간 로그는 tmp에만 두며 candidate-* 하위 폴더를 만들지 않는다.
종료: 후보 없음·자체 검토 FAIL 또는 영상 재생 검수 PASS 뒤에만 전용 Docker/브라우저 자원을 정리한다. "완료: inbox/$round/$task_id/RESULT.md" 또는 "차단: 영상 대기 · inbox/$round/$task_id/RESULT.md" 한 줄만 반환한다.
EOF
