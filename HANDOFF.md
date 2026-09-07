# HANDOFF.md — 새 세션은 이 파일에서 현재 작업과 다음 행동만 확인한다.

Updated: 2026-09-07

## Current objective

공개 WordPress 플러그인을 격리된 로컬 환경에서 분석하여 Wordfence 또는 Patchstack에 책임 있게 보고할 수 있는 재현 가능한 취약점을 발굴한다.

## Active workstreams

| Task | Owner | Status | Next action |
| --- | --- | --- | --- |
| repository-bootstrap | root | complete | None |
| private-repository | root | complete | None |
| local-lab | root | complete | None |
| target-pilot | root | in-progress | Start a new session, re-check current program rules and target versions, then dynamically test only high-impact residual paths in `import-users` and `file-manager-advanced`; otherwise close the first pilot and select the next batch |

## Decisions and constraints

- 모든 동적 테스트는 localhost 격리 환경에서만 수행한다.
- 실제 운영 사이트와 제3자 서비스를 능동 테스트하지 않는다.
- 첫 파일럿은 무료 WordPress 플러그인 5개로 제한한다.
- 후보는 두 번 재현하고 독립 검토하기 전까지 취약점으로 표현하지 않는다.
- 보고서는 자동 제출하지 않으며 사용자 승인 후 한 프로그램에만 제출한다.
- 미공개 PoC와 증거는 `findings/`에 두고 Git에 올리지 않는다.

## Blockers

- 현재 작업을 막는 운영상 차단 요인은 없다.
- `UR-2026-001`은 공개 upstream PR과 중복되어 신규 보고 대상으로 진행하지 않는다.
- Import Users 2.4.17의 recurring-import 권한 패치와 File Manager Advanced 5.4.13의 중앙 권한·uploads sandbox 패치를 정적으로 대조했으나 아직 acceptance gate에 올릴 신규 경로는 없다.

## Open locations

- `AGENTS.md`: 프로젝트 규칙과 안전 경계
- `STATUS.md`: 완료 이정표
- `MEMORY.md`: 확정된 장기 사실과 결정
- `README.md`: 프로젝트 개요와 다음 단계
- `compose.yaml`: 격리된 로컬 WordPress 실험실 구성
- `Makefile`: 설치, 검증, 플러그인 로드와 초기화 명령
- `docs/targets.md`: 대상 버전, 선정 근거, 원본 해시와 프로그램 상태
- `findings/UR-2026-001/REPORT.md`: 공개 중복으로 종결한 로컬 검증 기록 (Git 제외)
- Local lab: `user-registration` 5.2.7 remains active; rotate plugins before the next runtime check
