# WORKSTREAMS.md — 지속 탐색을 재개하거나 병렬 세션을 시작할 때 읽는다.

Updated: 2026-09-08

이 문서는 `AGENTS.md`, `HANDOFF.md`, `STATUS.md`, `MEMORY.md`를 대체하지 않는다.
안전 경계와 finding acceptance gate는 항상 `AGENTS.md`가 우선한다.

## Session startup

Coordinator는 다음 순서로 시작한다.

1. 저장소의 세션 시작 절차를 완료한다.
2. `docs/FINDING_QUEUE.md`가 있으면 읽고 없으면 queue worker가 생성하게 한다.
3. 가능한 경우 아래 세 worker를 동시에 시작한다. submission worker는 기존
   `REPORT-READY` 후보가 없으면 queue의 최상위 후보에 남은 gate를 닫는다.
4. worker에게 `HANDOFF.md`, `STATUS.md`, `docs/targets.md`를 수정하지 말라고 명시한다.
5. 결과를 받은 뒤 coordinator만 상태 문서를 갱신한다.

## Workstream D — continuous discovery

목적: 새 후보 탐색을 멈추지 않고 `HANDOFF.md`의 활성 대상부터 이어간다.

- 최신 공식 배포본과 해시를 먼저 고정한다.
- 공개 소스 정적 분석과 localhost 격리 환경만 사용한다.
- lead는 source-to-sink와 통제 실패를 확인하기 전까지 finding으로 승격하지 않는다.
- 공개 소스 검토 메모는 Git 제외 `work/`에 둘 수 있다. PoC, 원본 캡처와
  미공개 취약점 세부는 Git 제외 `findings/`에만 둔다.
- 한 대상을 닫으면 검토 공격면과 폐기 근거를 coordinator에게 전달하고 다음 대상을 선정한다.

완료 신호: 새 candidate와 증거 경로, 또는 후보 없음과 검토 범위가 보고됐다.

## Workstream Q — priority queue

목적: 발견 수가 아니라 제출 성공 가능성과 기대 보안을 기준으로 후보를 정렬한다.

- 공개 요약은 `docs/FINDING_QUEUE.md` 한 파일에 유지한다.
- 각 후보에는 ID, 내부 상태, 추천 제출처, 프로그램 적합성과 다음 gate만 기록한다.
  영향, 최소 권한, 영향 버전, 재현 횟수와 중복 세부는 private report에만 기록한다.
- 우선순위는 `program eligibility → demonstrated impact → reproducibility → novelty`
  순으로 판단한다.
- Shop Manager/Editor/Author/Contributor 전제, 설정 의존, race, payment/price 문제처럼
  프로그램별 제외 가능성이 큰 항목은 기술 심각도와 제출 우선순위를 분리한다.
- 공격 payload, 쿠키, nonce, 계정값과 미공개 상세는 이 공개 문서에 넣지 않는다.

완료 신호: 제출 가능 후보가 위에서부터 정렬되고 각 항목의 다음 행동이 하나로 정해졌다.

## Workstream S — submission package

목적: queue의 최상위 후보 하나를 실제 제출 가능한 영문 보고서 상태로 전진시킨다.

- 제출 당일 최신 버전, 공식 ZIP 해시와 프로그램 규칙을 다시 확인한다.
- 원격 공격자 관점의 전체 재현 절차, 실제 HTTP 요청, 무해한 payload, 기대 결과,
  음성 대조, 코드 참조, 영향, CVSS 근거, 수정안을 포함한다.
- 폼에 직접 붙여넣을 초안은 Git 제외
  `findings/<ID>/SUBMISSION-WORDFENCE.md` 또는
  `findings/<ID>/SUBMISSION-PATCHSTACK.md`에 둔다.
- 스크린샷·영상·원시 요청은 만료되는 외부 링크 대신 첨부 파일 체크리스트로 정리한다.
- AI 지원 사용 사실을 숨기지 않고, 제출자가 모든 절차를 수동 검증해야 한다.
- 동일 finding을 Wordfence와 Patchstack 양쪽에 제출하지 않는다.
- 실제 제출, 개발사 연락, CVE 요청은 사용자 승인 전 수행하지 않는다.

완료 신호: acceptance gate와 독립 검토를 통과한 동일 지문의 보고서 및 첨부물이
준비됐거나, 남은 gate와 필요한 증거가 정확히 기록됐다.

## Coordinator merge

- Worker 결과의 경로와 증거를 직접 확인한다.
- `docs/FINDING_QUEUE.md`, `HANDOFF.md`, `STATUS.md`를 이 순서로 갱신한다.
- 제출 보고서가 바뀌면 작성 맥락을 공유하지 않은 새 세션에서 다시 검토한다.
- 공개 가능한 상태 문서만 명시적으로 stage한다. `findings/`, `work/`, 비밀값은 commit하지 않는다.
- 사용자가 명시적으로 승인하기 전에는 commit, push 또는 외부 제출을 하지 않는다.
