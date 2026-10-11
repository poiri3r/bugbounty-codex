<!-- 프로그램의 대상 범위와 작업 제한. 작업 계획 수립 전과 대상·실행 방식이 바뀔 때 읽는다. -->
# RULES

## 사용법

- 공식 정책과 명시적 승인에서 작업 제한을 요약하고 출처·확인일을 기록한다. 요약이 원문과 다르면 원문을 따른다.
- 정책·대상 버전은 대상 선정 직전과 제출 직전에 다시 확인한다.
- 범위·허용 여부가 불명확하거나 서비스 영향·민감정보 노출 가능성이 생기면 능동 테스트를 중단한다.

## 선택 프로그램과 버그바운티 정책

- 선택 프로그램: Wordfence Bug Bounty Program
- 공식 규칙 확인: 2026-10-03
- Wordfence terms: https://www.wordfence.com/bug-bounty-program-terms/
- Wordfence program: https://www.wordfence.com/threat-intel/bug-bounty-program/
- Wordfence submission: https://www.wordfence.com/threat-intel/vulnerabilities/submit/
- Patchstack rules: https://patchstack.com/articles/bug-bounty-guidelines-rules/
- Patchstack accepted types/submission: https://patchstack.com/database/report
- WordPress.org metadata and official ZIPs: https://api.wordpress.org/plugins/info/1.2/
- 선택 근거: Wordfence는 unauthenticated 또는 stock Subscriber/Customer의 high-threat 취약점과 500개 이상 설치된 대상의 SQLi·Stored XSS를 명시적으로 포함한다. Round 2는 Standard tier의 다른 취약점 기준도 만족하도록 50,000+ 설치 대상에서 High 이상 경로를 우선한다.
- Wordfence 설치 수 gate: high-threat 7종은 25+, Stored XSS/SQLi는 500+, 그 밖의 허용 유형은 Standard/New 50,000+, Resourceful 10,000+, 1337 500+다. 티어가 별도로 확인되지 않으면 Standard/New 기준을 사용한다.
- Patchstack은 2026 규칙에서 XSS를 site-wide 영향 또는 reflected로 제한하므로, 단일 공개 listing에 저장되는 현재 후보에는 사용하지 않는다.

## 허용 방식과 제한

- WordPress.org, 공식 개발사 배포처 또는 공식 공개 저장소의 공개 소스만 분석한다.
- 동적 검증은 이 프로젝트의 localhost 컨테이너와 연구자 소유 테스트 데이터에서만 수행한다.
- 공개 포트는 `127.0.0.1`에만 바인딩하고 테스트 네트워크의 외부 egress를 차단한다.
- 외부 통신 기능은 비활성화하거나 localhost mock으로 대체한다.
- 실제 운영 사이트, 개발사 서비스, 제3자 API·인프라를 능동 테스트하지 않는다.
- 무단 스캔, 무차별 대입, DoS, 사회공학, 피싱, 계정 탈취와 비시험 데이터 열람·변경·삭제를 하지 않는다.
- 외부 제출, commit, push는 사용자의 명시적 요청 전에는 수행하지 않는다.

## in-scope

- 최신 안정판이고 최근 12개월 안에 갱신됐으며 기본 10,000개 이상 활성 설치된 공개 WordPress 플러그인·테마. 12~24개월 대상은 구체적인 patch diff 또는 새 attack surface가 있고 공개 동일 root가 없을 때만 탐색하며, 24개월 초과는 제외한다. 10,000 미만은 Stored XSS·SQLi 또는 high-threat의 구체적인 사전 신호가 있고 해당 Wordfence 예외 설치 수 gate를 충족할 때만 탐색한다.
- 공개 소스 정적 분석과 격리된 localhost 재현.
- 기본 설정의 unauthenticated, stock Subscriber 또는 WooCommerce Customer에서 도달 가능한 Medium 이상 경로만 취급하고 High 이상을 우선한다.
- SQL injection, 실행 가능한 site-wide/reflected XSS, 완전한 경로·확장자 제어가 있는 파일 작업, RCE, PHP object injection, 중요 option 변경, 권한 상승과 명확한 고영향 access control 문제를 우선한다.
- 한 batch는 최대 5개 대상이다.

## out-of-scope

- 별도 버그바운티가 우선하는 제품 또는 현재 Wordfence/Patchstack 규칙에서 제외된 대상·취약점 유형.
- 단순 scanner 출력, 호출 불가능한 코드, 이론적 가능성, 단순 crash·DoS와 관리자 전용 동작.
- 낮은 영향, 중복 가능성이 큰 경로, 비기본 설정 의존, 프로그램 적격성이 불명확한 finding은 core 후보로 승격하지 않는다.
- Wordfence 현행 제외인 business-logic-only, API key update/overwrite/read, DoS, SSRF, 단순 Missing Authorization/IDOR 분류는 core 후보로 승격하지 않는다. 누락된 권한 검사가 arbitrary content/file deletion·파일 read·privilege escalation 등 별도 허용 영향으로 완전히 입증된 경우에는 최종 impact 분류와 설치 수 gate로 다시 판정한다.
- 사용자가 제외한 Patchstack Active VDP 24시간 독점 경로.
- AC:H, Contributor 이상, 작은 정보 노출·변조·가용성 영향, blind SSRF, PII-only IDOR와 attachment·ticket·event·order·appointment IDOR.

## finding acceptance gate

후보는 다음 조건을 모두 충족하기 전까지 취약점으로 표현하지 않는다.

1. 최신 영향 버전과 공식 원본 파일 해시를 기록했다.
2. 공격자 입력, 전체 호출 경로와 보안 민감 sink를 실제 코드 라인으로 확인했다.
3. 누락되거나 무효한 권한·nonce·검증 통제를 확인했다.
4. 기본 설정과 허용된 최소 사용자 권한에서 도달 가능하다.
5. 격리된 새 환경에서 최소 PoC 전체 흐름을 한 번 재현하고 필요한 양성·음성 대조군을 확인했다. race·cache·migration·불안정 결과일 때만 추가 재현한다.
6. 테스트 데이터만으로 보안 영향을 입증했다.
7. Wordfence, Patchstack, CVE/NVD, changelog, issue와 최근 보안 commit에서 중복을 확인했다.
8. 탐색 에이전트가 기본 설정, 단일 clean 전체 재현, 대조군, 공개 중복, program gate와 증거 경로를 자체 검토해 PASS로 기록했다.

## 증거·비밀·제출

- 자료 보존·정리는 `../scripts/RETENTION.md`를 따른다. 완료·후보 없음으로 확인된 작업은 최소 조사 기록을 보존하고 참조가 없는 임시본만 승인 후 정리한다. 검토 중·공유 근거·별도 보존 지정 자료는 유지한다.
- 보고서에는 slug, 버전, 해시, 환경, 권한, 요청, 응답, 재현 명령과 실제 결과를 기록한다.
- 쿠키, token, password, 개인정보와 원본 민감 데이터는 채팅·Git·상태 문서에 넣지 않는다.
- 계정값은 로컬 `.env` 또는 ignored `project/CREDENTIAL.md`에만 두고 예시는 가짜 값만 사용한다.
- 작업 자료는 ignored `inbox/round/T-ID/`에 두고 제출 준비를 모두 통과한 자료만 ignored `report/F-ID/`에 저장한다. 신규 `project/services/`나 `evidence/F-ID/`는 만들지 않는다.
- rejected legacy `findings/`와 `work/` archive는 2026-09-30 사용자 요청으로 삭제했다. 자동 복원하거나 다시 만들지 않는다.
- 동일 취약점을 여러 프로그램이나 제조사에 중복 제출하지 않는다.
- 보고서는 자동 제출하지 않으며 사용자 승인 후 한 프로그램에만 제출한다.
- 최종 외부 제출문은 새 독립 세션에서 제출문·필요한 증거·적용 정책만 검토한다.
- 엠바고, 공개, 패치와 CVE 시점은 접수 프로그램 정책을 따른다.

## 확정된 사용자 결정

- 2026-10-01부터 Contributor·Author·Editor·Administrator 이상이 필요한 경로는 탐색하지 않는다. 정적 추적 중 최소 역할이 Contributor 이상으로 확인되면 즉시 종료하며, 기술 기록·동적 재현·하향 가능성 확장에도 추가 시간을 쓰지 않는다. 탐색 actor는 기본 unauthenticated·stock Subscriber 또는 적합한 stock WooCommerce Customer로만 제한한다.
- 2026-09-30 `coming-soon` 6.20.10의 Contributor·Author·Editor 확장 탐색은 기술 커버리지와 기록용으로 완료했다. Contributor/Author `PR:L`과 Editor/Admin `PR:H`는 현행 Wordfence/Patchstack 표준 보상 후보에서 제외한다.
- 보상 후보는 CVSS `PR` 문자값이 아니라 최소 WordPress 역할을 먼저 확인한다. 기본 unauthenticated·stock Subscriber 또는 해당 적합 플러그인의 stock Customer에서 도달할 때만 core 후보로 승격하고, 그다음 CVSS `PR:N/L/H`를 산정한다.
- `seedprodwpwidget` late-decode Stored XSS는 유효한 distinct patch sibling이지만 최소 Author/Contributor 역할이다. T-235–T-245의 Subscriber/actual WooCommerce Customer writer·consumer·promotion·REST/AJAX/Abilities·patch-sibling 검증에서 보상 범위로 낮출 기본 경로를 찾지 못했다. 사용자가 Wordfence에 제출한 ID `0a2bdf06-9618-460e-806a-aa6ec89107fe`는 공식 Author/Contributor Out-of-Scope role gate와 일치하게 즉시 Rejected됐다. 동일 root를 다시 제출하지 않는다.
- 사용자가 디스크 정리를 명시하기 전까지 `coming-soon` 랩 container·network·volume·증거를 삭제하지 않는다.
- 초기 무료 플러그인 5개 pilot은 완료됐다. 후속 탐색은 batch당 최대 5개다.
- 2026-09-12 strict core-only 결정에 따라 조건부·저영향·중복·프로그램 모호 finding은 현재 queue에서 제외한다. 관련 private archive는 2026-09-30 삭제했다.
- High 이상을 우선한다.
- `SSVG-2026-001`, `PG-2026-001`, `AHB-2026-001`, `WMA-2026-001`, `CS-2026-001`, `TPAE-2026-001`, `KB-2026-001`은 사용자가 제외한 24시간 독점 프로그램 경로이므로 현재 제출하지 않는다.
- `NF-2026-001`은 최신판의 공개 patch·다른 연구자 credit 확인으로 종료됐다.
- `UR-2026-002`는 Patchstack 중복으로 종료됐으며 다른 프로그램에 제출하지 않는다.
- 제출·엠바고 이력과 유효 제출 증거만 보존한다. rejected 후보 처분 이력은 `../STATUS.md`를 기준으로 한다.
