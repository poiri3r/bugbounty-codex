# STATUS.md — 완료된 이정표를 시간순으로 기록하며 새 세션은 진행 이력을 확인할 때 읽는다.

## 2026-09-07

- 바탕화면에 독립된 `bugbounty-codex` 프로젝트를 만들었다.
- 로컬 WordPress 분석 전용 안전 경계, finding acceptance gate와 독립 검토 절차를 정의했다.
- `HANDOFF.md`, `STATUS.md`, `MEMORY.md` 상태 문서의 역할을 분리했다.
- 플러그인 원본, 작업 디렉터리, 비밀값과 미공개 finding 자료를 Git 제외 대상으로 지정했다.
- GitHub에 `poiri3r/bugbounty-codex` 비공개 저장소를 만들고 `origin`으로 연결했다.
- WordPress 7.1.0, MariaDB 11.8.9와 WP-CLI 2.12.0 기반 Docker Compose 구성을 작성했다.
- Docker Desktop 엔진이 정지된 상태임을 확인하여 로컬 실험실 동적 검증은 차단 상태로 남겼다.
- Compose YAML 파싱, Make 명령 dry-run과 `.env` Git 제외를 정적으로 검증했다.
- Docker Desktop을 시작하고 WP-CLI entrypoint 및 내부망 포트 게시 문제를 수정했다.
- WordPress를 egress 차단 내부망에 유지하면서 localhost Nginx 게이트웨이로만 접근하도록 구성했다.
- 깨끗한 볼륨에서 WordPress 설치, localhost 바인딩, 외부 egress 차단과 HTTP 200 응답을 두 번 재현했다.
- Compose 이미지 참조를 전체 digest로 고정했다: MariaDB `2439dcd7…`, WordPress `5a93c470…`, WP-CLI `2b5e9d4d…`, Nginx `dc5069ad…`.
- Wordfence와 Patchstack의 공식 범위·제외·제출 규칙을 2026-09-07 기준으로 다시 확인했다.
- WordPress.org의 최신 안정 버전 플러그인 5개를 선정하고 공식 ZIP과 SHA-256을 `docs/targets.md`에 고정했다.
- JWT Authentication for WP REST API, File Manager Advanced와 Backup Migration의 주요 공개 진입점 및 권한 경계를 검토했으며 acceptance gate에 올릴 후보는 확인하지 못했다.
- Import Users from CSV with Meta의 import·cron·파일 관리 AJAX 경로에서 nonce와 `create_users` 권한 통제를 확인했으며 저권한 후보 검토를 계속한다.
- User Registration 5.2.7을 고정 ZIP에서 로컬 설치·활성화하고 격리 조건과 HTTP 응답을 다시 검증했다.
- User Registration의 공개 AJAX, 등록 역할 결정, 프로필 변경, 멤버십 선택과 결제 완료 경로를 검토했다. 저장된 폼·플랜과 요청 세션에 결합된 통제가 있어 현재 acceptance gate에 올릴 후보는 확인하지 못했다.
- `UR-2026-001`을 격리된 실험실에서 테스트 계정 두 개로 재현하고 정상 결제 대기 경로를 대조군으로 확인했다. 세부 증거는 Git 제외 경로 `findings/UR-2026-001/`에만 저장했다.
- 공개 upstream PR #1392가 동일한 멤버십 필드 누락 및 결제 전 로그인 경로와 후속 수정안을 명시하고 있어 `UR-2026-001`을 `closed-known-duplicate`로 종결했다. 신규 취약점으로 제출하지 않는다.
- File Manager Advanced 5.4.12→5.4.13 보안 변경분을 대조했다. 최신판은 파일 관리자 AJAX에 중앙 권한 확인을 추가하고 비관리자 파일 루트를 uploads로 제한하며 위험 확장자와 여러 쓰기 명령을 차단한다. 현재 신규 후보는 확인하지 못했다.
- Backup Migration 2.1.6→2.1.7의 cron, 다운로드와 autologin 인증 변경분을 대조했다. 최신판의 관리자 AJAX 선행 권한과 다운로드 nonce·토큰·내부 secret 경계를 확인했으며 현재 신규 후보는 확인하지 못했다.
- Import Users 2.4.16→2.4.17의 recurring import 권한 전달을 추적했다. unattended 실행은 설정 저장자의 `promote_users` 여부를 사용하고, 로그인 호출자는 실제 호출자 권한을 사용하며, 배치 후속 단계에도 값을 전달한다. 현재 신규 후보는 확인하지 못했다.
- 초기 커밋의 1차 독립 검토에서 gateway egress, egress 검사 오탐과 이미지 digest 불일치를 확인했다.
- gateway가 localhost ingress를 유지하면서 기본 외부 경로를 제거하고 비관리자 Nginx로 실행되도록 수정했다. `make verify`가 WordPress와 gateway의 라우팅 테이블에서 외부 gateway 경로 부재를 각각 검증하도록 보강하고 모든 Compose 이미지 참조를 전체 digest로 고정했다.
- 변경된 초기 커밋 후보를 독립 재검토하여 `docker compose exec` 실패가 `blocked` 출력으로 오인될 수 있는 검증 결함을 찾고 종료 상태를 명시적으로 확인하도록 수정했다.
- 정상 격리 환경, 합성 라우팅 입력, 임시 default route 주입과 명령 실패 모의 시험으로 `make verify`의 성공·실패 경계를 확인했다.
