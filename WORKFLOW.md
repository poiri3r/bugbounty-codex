<!-- 중앙 컨트롤러와 작업 에이전트의 실행 규칙. 탐색 시작·재개 시 읽는다. -->
# WORKFLOW

## 0. 토큰 절약 원칙

`project/SERVICE.md`는 시작 시 전체 읽지 않는다. 컨트롤러가 `bash scripts/service-lookup.sh SLUG`로 관련 행만 조회하고 버전·검사 날짜·범위·판정을 확인한다. 같은 slug라도 공식 최신 버전이 달라졌거나 마지막 감사 후 365일이 지났으면 preflight가 재감사를 허용한다. 날짜가 없는 같은 버전은 중복 방지를 위해 거절한다. 슬롯에 SERVICE 전체 읽기를 지시하지 않는다.

1. 에이전트를 만들기 전에 컨트롤러가 `scripts/preflight-target.sh`로 공식 metadata, 기본 10,000+ installs, 갱신 시점, 기존 원장 버전·감사일, 공개 동일 root와 VDP를 확인한다. 최근 12개월 갱신을 기본으로 하며, 12~24개월 대상은 구체적인 patch diff 또는 새 attack surface를 `--change-signal`로 제공할 때만 허용하고 24개월 초과는 제외한다. CVE/NVD·Wordfence·Patchstack·changelog·최근 보안 commit에서 동일 root가 없음을 확인한 경우에만 `--public-duplicate-check no-match`를 사용한다. Stored XSS·SQLi 또는 high-threat의 구체적인 사전 신호가 있을 때만 `--min-installs`로 프로그램 예외 기준을 적용한다. 중복 확인이나 VDP가 `unknown`이거나 gate가 실패하면 배정하지 않는다.
2. 탐색 에이전트는 반드시 대화 이력 없이 `fork_turns: "none"`으로 만들고, `scripts/task-contract.sh`가 출력한 짧은 계약만 전달한다. 계약에는 관련 plugin-specific invariant를 최대 3개만 넣고, 공통 모델은 `docs/agents/WORDPRESS-AUDIT.md`를 참조한다.
3. 검증 순서는 `entry point → 저권한 source → authorization/validation → Medium+ sink → 실제 호출 가능성 → 동적 검증`이다. 앞 단계가 실패하면 해당 경로를 즉시 종료한다.
4. 구버전 A/B는 최신판에서 구체적인 우회 신호가 있거나 최신판 음성을 검증할 positive control이 필요할 때만 한다. Chrome은 실행 가능한 XSS source→sink가 정적으로 성립한 뒤에만 실행한다.
5. 후보가 없는 `RESULT.md`는 80줄·12KB 이하로 유지하고 `scripts/check-result.sh`로 검사한다. 실제 후보는 `--candidate`를 붙여 크기 제한만 해제한다. 원본 코드·HTTP·DB·브라우저 로그는 본문에 복사하지 않고 경로만 적는다.
6. 완료 여부를 재촉하는 중간 메시지는 보내지 않는다. 결과 알림을 기다리고, 상태 문서는 슬롯 3개를 회수한 뒤 한 번에 갱신한다. WordPress 기술 후보는 탐색 에이전트가 자체 검토하며 별도 검토 슬롯을 만들지 않는다.

## 1. 컨트롤러 루프

1. `STATUS.md`에서 전체 단계만 확인하고 `HANDOFF.md`의 재개 작업과 작업 대기열을 우선한다.
2. preflight를 통과하고 활성 작업과 겹치지 않는 작업을 골라 `fork_turns: "none"`인 별도 에이전트를 만든다. `scripts/task-contract.sh`가 만든 계약과 고유한 `inbox/<round>/<T-ID>/`만 전달한다. T-ID는 재사용하지 않으며 하위 에이전트 생성은 금지한다.
3. 생성 때 활성 슬롯을 기록하고, 종료 결과 3개를 회수한 뒤 `HANDOFF.md`를 한 번 갱신한다. 작업이 끝나면 `RESULT.md`만 먼저 읽고, 원본 자료는 후보 확인이나 검토에 필요할 때만 연다.
4. 빈 슬롯에는 활성 작업과의 중복을 확인한 뒤 RESULT의 다음 단서와 HANDOFF의 작업 대기열에서 새 작업을 골라 즉시 투입한다. WordPress 외의 독립 검토가 필요하면 그 슬롯을 검토 에이전트가 사용하고, 종료 후 다시 탐색으로 채운다.
5. 사용자가 중지하거나, 범위·인증이 막히거나, 세션을 인계해야 할 때까지 작업 슬롯 3개를 유지한다.

## 2. 탐색 에이전트 계약

컨트롤러는 다음 내용을 포함해 한정된 작업 하나를 배정한다.

```text
목표: <서비스 하나와 확인할 관점 하나>
범위: project/RULES.md
인증: 필요할 때만 project/CREDENTIAL.md
참고: 관련 SERVICE 항목과 기존 후보 경로
출력: inbox/<round>/<T-ID>/RESULT.md 및 관련 자료
임시 작업: tmp/<T-ID>/ (자료 수명: scripts/RETENTION.md)

공유 문서는 수정하지 않는다. 배정 범위를 넘기거나 하위 에이전트를 만들지 않는다.
RESULT.md에는 수행 범위, 새 서비스 사실, 후보와 근거 경로, 확인한 범위, 다음 단서만 짧게 적는다.
후보가 없으면 80줄·12KB를 넘기지 않는다. raw 로그·코드·HTTP 응답은 붙이지 않고 상대 경로만 적는다.
최종 응답은 `완료: <RESULT 경로>` 또는 `차단: <이유> · <RESULT 경로>` 한 줄만 반환한다.
```

정적 gate에서 Contributor+·비기본 설정·허용되지 않은 영향·호출 불가를 확인하면 동적 환경을 만들지 않고 종료한다. 최신판에 구체적인 우회 신호가 없으면 구버전 A/B를 하지 않는다. 배정된 invariant 검사가 끝나면 기존 invariant 밖의 entry/sink를 한 번만 훑고 가장 강한 가설 최대 2개만 추가 추적한다.

## 3. 결과 통합

- 컨트롤러가 slug·버전·활성 사용자 수·공식 ZIP SHA-256·감사 날짜와 `T-ID · 확인 범위 · 판정 · 미확인 한계`를 `project/SERVICE.md` 한 행에 병합한다. 상세 폴더나 상세 경로는 만들지 않는다.
- 후보 없음·기각은 SERVICE 행만 남긴다. 제출 준비가 끝난 후보는 다음 F-ID를 정해 `submission.json`, 생성된 `REPORT.md`, 검수한 `video/poc.mp4`, 선택적 `poc/`만 `report/F-ID/`로 이동한다. 중간 `evidence/F-ID/`는 만들지 않는다.
- 미완료 후보는 T-ID 상태로 inbox에 둔다. 자체 검토·영상 재생 검수·최종 제출문 독립 검토가 모두 PASS하기 전에는 F-ID로 승격하지 않는다.
- 자료 삭제 전에 `scripts/RETENTION.md`에 따라 SERVICE 행·report 보존본·남은 참조·실행 자원 종료를 확인한다. `cleanup-task.py`의 미리보기 목록을 사용자에게 제시하고 명시적 승인 후에만 해당 `tmp/T-ID`와 통합 완료된 `inbox/round/T-ID`를 삭제한다.

## 4. 검토와 제출 준비

- WordPress 기술 후보는 탐색 에이전트가 새 격리 환경 1개에서 전체 흐름 1회, 필요한 양성·음성 대조군, 공개 중복, program gate와 증거 경로를 자체 검토해 같은 RESULT에 기록한다. race·cache·migration·불안정 결과일 때만 추가 재현한다. 이 단계에는 별도 검토 에이전트나 새 T-ID를 만들지 않는다.
- 자체 검토를 통과한 신규 WordPress 제출 후보는 재현 환경을 유지한 채 `scripts/RECORDING.md`의 촬영·실제 재생 검수를 완료한다. 미촬영·실패·미검수는 `영상 대기`이며 제출 준비 완료로 표시하지 않는다.
- 자체 검토와 영상 검수를 통과하면 `scripts/prepare-submission.py`로 제출 필드를 검증하고 REPORT를 생성한다. 전용 Chrome·Docker를 종료하고 쿠키가 있는 `browser-profile/`과 전체 소스·중간 로그는 제외한다.
- 최종 외부 제출문은 새 독립 세션에 제출문, 필요한 증거, 적용 정책만 전달해 검토한다. SERVICE 전체, 전체 대화, 무관한 STATUS/HANDOFF는 전달하지 않는다. 중요한 결함 수정 후에는 수정 부분과 영향 범위만 재검토한다.
- 주장·영향·증거가 바뀌면 탐색 에이전트 자체 검토부터 다시 한다. 외부 제출은 사용자 요청이 있을 때만 한다.

## 5. 세션 인계

새 작업 생성을 멈추고 실행 중 작업을 회수한다. 회수하지 못한 작업은 중단 위치를 `HANDOFF.md`에 적는다. `STATUS.md`와 `HANDOFF.md`를 갱신한 뒤 세션을 끝낸다.
