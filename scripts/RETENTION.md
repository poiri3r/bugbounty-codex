<!-- 작업 자료를 정리하기 전에 읽는다. -->
# 작업 자료 수명

## 저장 위치

- 분석 중 소스·ZIP·로그·실험실은 `tmp/T-ID/`에 둔다.
- 작업 결과는 `inbox/<round>/T-ID/`에 둔다.
- 조사 이력은 `project/SERVICE.md`의 정확한 한 행으로만 남긴다. 전체 파일을 읽지 말고 `bash scripts/service-lookup.sh SLUG`를 사용한다.
- 제출 가능한 후보만 `report/F-ID/`에 둔다. 기본 구성은 `submission.json`, `REPORT.md`, `video/poc.mp4`, 필요할 때만 `poc/`이다.
- 새 `project/services/`나 `evidence/F-ID/`를 만들지 않는다. 전체 소스, ZIP, Docker 실험실, 원시 로그를 report에 복사하지 않는다.

## 종료 기록

- 후보 없음: SERVICE 한 행에 slug·버전·사용자 수·공식 ZIP SHA-256·감사 날짜와 `T-ID · 확인 범위 · 후보 없음 · 미확인 한계`를 한 줄로 기록한다. 이는 안전성 증명이 아니다.
- 제출 후보: 자체 검토, 한 번의 clean 전체 재현과 대조군, MP4 재생 검수, 제출 자료 검증 및 최종 제출 검토를 통과한 뒤 SERVICE 한 줄 결과에 `제출 후보 F-ID`를 기록한다.
- 경쟁 조건·캐시·마이그레이션·비결정성 문제에만 추가 clean 재현을 한다.
- 완료되지 않은 자료는 inbox에 유지한다. 컨트롤러만 통합·정리를 승인한다.

## 안전 정리

컨트롤러가 SERVICE 행, report 보존본, 참조 제거, 실행 자원 종료를 확인한 뒤 manifest를 만든다.

```json
{
  "task_id": "T-001",
  "slug": "example-plugin",
  "state": "closed-no-candidate",
  "resources_stopped": true,
  "references_reviewed": true,
  "service_row_sha256": "<exact-service-row-sha256>",
  "remove": ["tmp/T-001", "inbox/1/T-001"]
}
```

후보 보존 작업은 `state`를 `closed-retained`로 하고 다음 두 값을 추가한다.

```json
{
  "report": "report/F-ID",
  "submission_sha256": "<submission.json-sha256>"
}
```

```bash
python3 scripts/cleanup-task.py project/cleanup/T-ID.json
python3 scripts/cleanup-task.py project/cleanup/T-ID.json --apply --approve-plan <plan_sha256>
```

- 도구는 해당 T-ID의 `tmp/T-ID`와 `inbox/<숫자>/T-ID` 전체만 허용한다.
- symlink, mount, 특수 파일, 다른 T-ID, 부분 하위 경로, 변경된 SERVICE/report, 남은 표준 문서 참조를 거부한다.
- 미리보기 후 목록·크기·수정 시간이 바뀌면 승인 해시도 바뀐다.
- 삭제는 휴지통으로 이동하지 않아 복구를 보장할 수 없다.
