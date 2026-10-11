# WordPress 버그바운티 하네스

공개 WordPress 플러그인과 테마를 조사하고, 로컬 환경에서 취약점을 검증해 제출 자료를 만드는 작업 폴더입니다.

운영 중인 웹사이트나 제3자 서버는 테스트하지 않습니다. 동적 검증은 이 컴퓨터의 격리된 WordPress 환경에서만 진행합니다.

## 시작 방법

1. Codex를 이 프로젝트 루트에서 시작합니다.
2. `탐색 시작해줘`처럼 원하는 작업을 말합니다.
3. Codex가 대상 적격성과 기존 조사 여부를 확인한 뒤 탐색 작업을 배정합니다.

현재 진행 상태는 `STATUS.md`, 다음에 할 일과 미확인 사항은 `HANDOFF.md`에서 확인합니다.

## 폴더 역할

| 위치 | 용도 |
|---|---|
| `project/RULES.md` | 허용 범위와 대상 선정 기준 |
| `project/SERVICE.md` | 지금까지 조사한 플러그인 원장 |
| `tmp/T-ID/` | 소스 ZIP, 압축 해제본, 로그, 로컬 실험 자료 |
| `inbox/<round>/T-ID/` | 탐색 에이전트가 반환한 결과와 제출 준비 자료 |
| `report/F-ID/` | 검토와 영상 준비를 마친 제출 후보 |
| `lab/` | WordPress·MariaDB·Nginx 로컬 실험실 설정 |
| `scripts/` | 대상 검사, 결과 확인, 녹화, 정리 도구 |

과거 조사 여부를 확인할 때 `project/SERVICE.md` 전체를 열지 않고 다음 명령으로 플러그인 이름만 검색합니다.

```bash
bash scripts/service-lookup.sh PLUGIN-SLUG
```

같은 버전은 마지막 감사 후 365일이 지나면, 공식 최신 버전이 달라지면 즉시 preflight 재감사 대상이 됩니다. 감사 날짜가 없는 같은 버전은 중복 방지를 위해 제외합니다.

## 탐색 결과가 저장되는 과정

```text
탐색 중: tmp/T-ID/ (소스·실험 자료) + inbox/<round>/T-ID/ (RESULT·관련 자료)
승격:    inbox/<round>/T-ID/ -- 모든 검토 통과 --> report/F-ID/ (최소 제출 자료)
```

- 후보가 없거나 기각된 작업은 조사 결과만 `project/SERVICE.md`에 남깁니다.
- 제출 가능한 후보만 `report/`에 보존합니다.
- 외부 제출은 사용자가 요청할 때만 진행합니다.

## 로컬 WordPress 실험실

처음 사용할 때 환경 파일을 만들고 설치·검증합니다.

```bash
cp lab/.env.example lab/.env
make install
make verify
```

기본 브라우저 주소는 `http://127.0.0.1:8080`이며, `lab/.env`의 `WP_PORT`로 바꿀 수 있습니다.

공식 플러그인 ZIP을 작업별 `tmp/T-ID/`에 두었다면 다음처럼 설치합니다.

```bash
make plugin PLUGIN=T-001/example.zip
```

실험실 종료:

```bash
make down
```

`make reset`은 WordPress와 데이터베이스 볼륨까지 삭제하므로 새 환경이 필요할 때만 사용합니다. 실제 실행·검증 여부는 `STATUS.md`를 기준으로 확인합니다.

## 자료 정리

작업이 끝난 뒤 임시 자료는 `scripts/RETENTION.md` 기준으로 확인합니다. 삭제 대상은 먼저 미리보기로 검증하고, 사용자가 목록을 승인한 뒤에만 `tmp/T-ID/`와 통합 완료된 `inbox/<round>/T-ID/`를 삭제합니다.

`report/`의 제출 후보와 `project/SERVICE.md`의 조사 이력은 임시 자료 정리 대상이 아닙니다.

## 운영 문서

- `AGENTS.md`: 프로젝트 핵심 규칙
- `WORKFLOW.md`: 컨트롤러와 탐색 에이전트의 실행 절차
- `STATUS.md`: 프로젝트 전체 진행 상태
- `HANDOFF.md`: 다음 작업과 미확인 사항
