# 버그바운티 하네스

> 상속: 전역 Layer 1 `~/.codex/AGENTS.md`를 누적 적용하며, 이 파일은 이 저장소에 특화한다.

- Codex는 프로젝트 루트에서 직접 시작한다. 시작 시 `WORKFLOW.md`, `project/RULES.md`, `STATUS.md`, `HANDOFF.md`를 읽는다. `project/SERVICE.md` 전체 읽기는 금지한다. 컨트롤러는 `bash scripts/service-lookup.sh SLUG`로 관련 행만 검색하고 슬롯에는 필요한 항목·경로만 전달한다. 인증이 필요할 때만 `project/CREDENTIAL.md`를 읽는다.
- 대상·작업 방식은 `project/RULES.md`를 따른다.
- 사용자가 탐색 시작을 지시하면 현재 세션이 중앙 컨트롤러가 된다. `WORKFLOW.md`에 따라 독립 작업 슬롯 3개를 유지한다.
- 새 탐색 에이전트는 중앙 preflight 통과 후 `fork_turns: "none"`으로만 만들고, 짧은 계약과 필요한 파일 경로만 전달한다.
- 컨트롤러만 `project/SERVICE.md`, `STATUS.md`, `HANDOFF.md`와 `report/F-ID/`를 수정한다. 작업 에이전트는 배정된 `inbox/round/T-ID/`와 `tmp/T-ID/`만 쓴다. 자료 수명·정리는 `scripts/RETENTION.md`를 따르고 컨트롤러가 승인한다.
- `STATUS.md`는 최대 40줄·8KB로 유지하고 현재 목표·완료 조건·단계별 상태 최대 5행만 갱신한다. 과거 기록을 추가하지 않고 현재 상태로 교체한다. Round별 이력·T-ID·플러그인별 상세는 넣지 않는다. 조사 이력은 SERVICE의 해당 행, 제출 자료·제출 상태는 report, 즉시 할 일·작업 대기열·외부 미확인 사항은 HANDOFF에 둔다.
- 작업 반환은 `docs/agents/INBOX.md`, 제출 준비 결과는 `report/HOWTOUSE.md`를 따른다. 신규 `project/services/`와 중간 `evidence/F-ID/`는 만들지 않는다.
- WordPress 기술 후보는 별도 검토 에이전트를 만들지 않고 탐색 에이전트가 자체 검토한다. 최종 외부 제출문은 Layer 1에 따라 새 세션에서 독립 검토한다.
- 브라우저 영상 촬영 시 `scripts/RECORDING.md`를 읽고 `scripts/screen_record.ps1`을 사용한다. 실제 MP4 재생 검수 전에는 영상 완료로 보고하지 않는다.
- WordPress 보안 탐색 계약을 만들거나 수행할 때만 `docs/agents/WORDPRESS-AUDIT.md`를 읽고 공통 invariant와 bounded residual sweep을 적용한다.
- XSS source→sink를 탐색하거나 브라우저 PoC를 만들 때 `docs/agents/XSS-TESTING.md`를 읽고 최신 필수 probe를 포함한다.
- 외부 제출 보고서는 **재현과 판정에 필요한 정보만 최소한으로** 쓴다. 기본 상한은 Description 5문장, PoC 5단계, 환경 1문단이며 재현에 필수일 때만 넘긴다.
- 제출문에는 입력→sink, 최소 공격자 권한, 영향, 최소 재현 요청과 눈에 보이는 결과만 남긴다. 내부 증거 로그·해시·음성 probe·검토 이력·중복 조사·장황한 주석은 폼이 요구하거나 재현에 꼭 필요하지 않으면 넣지 않는다.
- XSS PoC는 안전한 로컬 환경에서 `alert(document.domain)`처럼 즉시 눈에 보이는 결과를 우선한다. AI 사용 공개는 폼의 전용 항목에만 짧게 적고 Description·PoC에 중복하지 않는다.
- 세션 종료 전 새 작업 생성을 멈추고 결과를 회수한 뒤 `STATUS.md`와 `HANDOFF.md`를 갱신한다.
