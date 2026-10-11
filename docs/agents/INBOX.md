<!-- 탐색 작업의 반환 위치와 승격 조건을 확인할 때 읽는다. -->
# Inbox 사용법

- 작업 에이전트는 배정된 `inbox/<round>/<T-ID>/`와 `tmp/<T-ID>/`만 쓴다. F-ID는 컨트롤러가 부여한다.
- 후보 없음·기각은 `RESULT.md`만 반환한다. 컨트롤러가 SERVICE 한 행에 통합한 뒤 승인된 정리 절차로 inbox와 tmp를 삭제한다.
- 실제 후보는 같은 폴더에 `submission.json`, 생성된 `REPORT.md`, 실제 재생 검수 PASS인 `video/poc.mp4`, 필요할 때만 `poc/`를 둔다.
- 전체 플러그인 소스·ZIP·검색 결과·Docker lab·중간 로그는 `tmp/T-ID/` 밖으로 복사하지 않는다.
- 자체 검토, 영상 재생 검수, `prepare-submission.py`, 최종 제출문 독립 검토가 모두 PASS하면 컨트롤러가 필요한 파일만 `report/F-ID/`로 이동한다.
- 미완료·영상 대기는 inbox에 유지한다. 작업 에이전트는 직접 삭제하거나 `project/services/`, `evidence/`, `report/`를 만들지 않는다.
