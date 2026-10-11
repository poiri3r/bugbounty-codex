<!-- 브라우저 영상 촬영 전에 읽는다. 실제 화면 녹화·검수 절차이며 재현 동작 자동화는 포함하지 않는다. -->
# 브라우저 녹화 계약

## 원칙

- Windows Chrome + Xbox Game Bar + `screen_record.ps1`을 사용한다. 임의로 다른 방식으로 전환하지 않는다. Game Bar 사용이 불가능하면 차단 사유를 보고하고 사용자에게 대안을 묻는다.
- 허용된 localhost에서 WordPress 탐색 에이전트의 자체 검토를 통과한 사례만 촬영한다. 스크립트는 브라우저·녹화·파일 수집만 담당한다. 공격 입력 생성이나 재현 동작은 실행하지 않는다.
- 실제 주소창과 동작 전후 화면을 녹화한다. Canvas/슬라이드/이미지 합성 설명 영상을 실제 증거로 제출하지 않는다.
- XSS는 실제 사례 흐름에서 발생한 무해하고 눈에 띄는 실행 결과를 보여준다. 기존 지침의 로컬 alert 같은 결과 없이 단순 이미지 표시를 XSS 실행 증거로 판정하지 않는다. DevTools/CDP에서 직접 실행해 결과를 꾸미지 않는다.
- 이미지·정보 노출은 연구자 소유의 고유 표식이 있는 테스트 자료로 실제 노출을 보여준다. alert는 필요 없다. 원래 보이면 안 되는 조건과 실제 보이는 결과를 구분한다. 실제 개인정보는 사용하지 않는다.
- 케이스별 재현 조작은 RESULT에 자체 검토된 절차를 따른다. 영상은 기술 증거·대조군·자체 검토를 대신하지 않는다.

## 고정 순서

1. 계획에 대상/버전, 역할, 전후 상태, 기대하는 가시적 결과를 한 줄씩 적는다. 다른 녹화를 모두 종료하고 알림·비밀값을 숨긴다. Game Bar 활성화·저장 경로를 확인한다.
2. 배정된 출력 폴더 아래 새 `video-01` 디렉터리로 `Open`한다. 전용 Chrome 프로필에서 필요한 로컬 로그인·준비를 끝낸다. 다른 Chrome을 추가 실행하지 않는다.
3. `Start` 후 **녹화 타이머/표시를 화면에서 확인**한다. 명령 exit 0은 시작 성공 증거가 아니다. 표시가 없거나 다른 창이면 실패로 기록하고 단축키를 무작정 다시 누르지 않는다.
4. 동작 전 상태 → 검토된 수동 동작 → 실제 결과를 보여준다. 결과는 읽을 수 있게 최소 3초 유지한다. 민감한 준비 작업은 찍지 않는다.
5. 녹화가 진행 중임을 확인한 뒤 `Stop -RecordingIndicatorConfirmed`한다. 타임아웃 후 같은 Stop은 파일 수집만 재시도한다. Captures 원본 MP4는 보존한다.
6. 저장된 MP4를 실제 재생한다. 처음/동작/결과/끝을 확인한다. 다른 창·검은 화면·주소창 누락·결과 누락·비밀값 노출이면 FAIL이다. 파일 존재·해시만으로 PASS하지 않는다.
7. `REPORT.md` 또는 배정된 `RESULT.md`에 영상 상대 경로, 확인한 타임스탬프, 가시적 결과, 검수 PASS/FAIL·한계를 짧게 적는다. 미촬영·실패·미검수는 `영상 대기`로 남기며 제출 준비 완료로 표시하지 않는다.

후보 환경은 7단계 PASS와 필요한 증거 보존이 끝난 뒤에만 종료한다. `영상 대기`면 제출 요청 때 재구축하지 않도록 전용 환경과 재현 상태를 유지하고 위치를 RESULT에 적는다.

## 호출 (Windows PowerShell, 프로젝트 루트)

```powershell
$session = 'C:\Users\LACUC\Desktop\bugbounty-codex\inbox\<round>\<T-ID>\video-01'
.\scripts\screen_record.ps1 -Action Open -SessionDirectory $session -Url 'http://localhost:8080/'
.\scripts\screen_record.ps1 -Action Start -SessionDirectory $session
# 화면에서 녹화 표시 확인 후 검토된 수동 시연
.\scripts\screen_record.ps1 -Action Stop -SessionDirectory $session -RecordingIndicatorConfirmed
```

- 저장 위치가 다르면 Start에 `-CaptureDirectory 'D:\Captures'`를 명시한다. 기본은 Windows Videos/Captures다.
- 일반 CDP 조작에는 기존 `cdp-eval.js`를 전용 브라우저 포트(기본 9223)에 연결한다. CDP 도구 자체는 녹화기가 아니다.
- 재촬영은 새 `video-02`를 사용한다. 기존 MP4를 덮어쓰지 않는다. 녹화 중 다른 녹화기나 Captures 파일 이동을 하지 않는다.
- 완료 후 전용 Chrome 창을 닫는다. `browser-profile/`에는 쿠키가 있으므로 제출하지 않는다. Chrome 종료 후 그 프로필만 정리하고 MP4·상태 파일은 보존한다. 사용자 Chrome 프로필은 건드리지 않는다.
- 시작 상태나 영상 내용은 자동 판정하지 못한다. 실제 Windows 녹화 테스트를 하지 않았다면 그 한계를 보고한다.
