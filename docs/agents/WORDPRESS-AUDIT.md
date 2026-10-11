<!-- WordPress 보안 탐색 계약을 만들거나 수행할 때만 읽는다. -->
# WordPress invariant 기반 감사

## Threat model

- 공격자는 기본 설정의 unauthenticated 사용자, stock Subscriber 또는 해당 플러그인의 stock Customer다.
- 보호 자산은 privileged options와 state, 사용자·콘텐츠·주문 같은 객체, secrets, 파일시스템, 관리자와 공개 페이지의 실행 컨텍스트다.
- 주요 trust boundary는 REST, `wp_ajax_*`/`wp_ajax_nopriv_*`, `admin_post_*`, public form, shortcode/block, upload/import, webhook/cron이다.
- nonce는 CSRF 방어 수단이지 authorization 증거가 아니다. capability, object ownership, target binding을 별도로 확인한다.
- 최종 범위와 acceptance gate는 `project/RULES.md`가 결정한다.

## 공통 invariant

1. 비인증 사용자는 문서화된 public feature를 제외한 privileged durable state를 변경할 수 없어야 한다.
2. Subscriber/Customer는 관리자 기능이나 다른 사용자의 객체를 읽기·변경·삭제할 수 없어야 한다.
3. 공격자 입력은 출력 컨텍스트에 맞는 escaping 없이 관리자·공개 페이지의 active HTML/JavaScript가 될 수 없어야 한다.
4. 외부 entry point에서 민감한 sink까지 가는 모든 경로에는 actor와 target에 맞는 authorization, validation, object binding이 있어야 한다.
5. 업로드·import·경로 입력은 허용 root 밖의 read/write/delete, 위험한 파일 형식 저장, 실행 가능한 파일 생성으로 이어질 수 없어야 한다.
6. 공격자 입력은 SQL 구조나 query target을 변경할 수 없어야 한다.

## 작업 절차

1. 배정된 관점에 해당하는 등록된 entry point와 trust boundary만 먼저 목록화한다.
2. plugin 기능에서 공통 invariant로 설명되지 않는 특화 invariant를 최대 3개 정한다. 계약에 제공됐으면 그대로 사용한다.
3. `actor-controlled source -> guards/transformations -> security-relevant sink` 전체 경로를 추적한다.
4. source, in-scope sink, 실제 호출 가능성 중 하나가 없으면 근거를 남기고 그 경로를 종료한다.
5. 배정 검사가 끝나면 기존 invariant 밖의 entry/sink 조합을 한 번 훑고, 가장 강한 가설 최대 2개만 추가 추적한다.

Sanitization과 escaping을 같은 통제로 취급하지 않는다. 등록되지 않은 handler, 관리자 전용 nonce만 가진 경로, Contributor+ 전용 경로는 호출 가능한 저권한 경로로 보고하지 않는다.

## RESULT 최소 형식

- threat-model delta: plugin 기능, 새 trust boundary, plugin-specific invariant 최대 3개
- coverage: entry cluster, actor-controlled source, guard, sink, 판정
- 후보 또는 종료 근거: 실제 코드와 artifact 상대 경로
- residual sweep: 확인한 invariant 밖 영역과 추가 가설 또는 `없음`
- 후보 자체 검토: 기본 설정, 새 환경 1개의 전체 재현 1회, 대조군, 공개 중복, program gate, 증거 경로의 PASS/FAIL과 미확정 사항. race·cache·migration·불안정 결과만 추가 재현
- 후보 영상: 자체 검토 PASS 뒤 같은 환경에서 촬영한 MP4 경로와 실제 재생 검수 결과. 없으면 `영상 대기`

탐색 로그와 원본 응답은 RESULT에 복사하지 않는다.
