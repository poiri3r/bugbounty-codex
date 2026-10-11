<!-- XSS 탐색·PoC를 시작할 때 읽는다. 공용 최소 probe와 증거 기준만 유지한다. -->
# XSS 탐색 지침

## 필수 신규 probe

- HTML 태그·속성 allowlist, sanitizer, parser/reparse, 저장 후 관리자·프런트 출력 경계를 확인할 때 다음 형태를 포함한다.

  ```html
  <camera onvalidationstatuschange=alert(1)>
  <microphone onvalidationstatuschange=alert(1)>
  ```

- 실제 PoC에서는 `alert(1)` 대신 고유한 무해 DOM marker를 우선 사용한다. 제출 영상처럼 사람이 확인해야 할 최종 증거에서만 명확한 alert를 사용한다.
- entity, mixed-case, quoted/unquoted attribute, DOM 재파싱(`innerHTML`, jQuery `.html()`, template/Select2 등), server-side KSES 전후를 함께 본다. 단순 문자열 잔존만으로 실행을 주장하지 않는다.

## 판정 기준

- PortSwigger XSS Cheat Sheet의 2026-09-21 갱신본은 `onvalidationstatuschange`를 사용자 상호작용 없는 이벤트로 설명하고 `<camera onvalidationstatuschange=alert(1)>`를 Chrome 지원, Firefox·Safari 미지원으로 표시한다.
- `<microphone>` 변형은 같은 원문에 별도 등록돼 있지 않다. companion probe로만 검사하며, 대상 브라우저의 실제 event firing과 JavaScript 실행을 확인하기 전에는 지원·취약점·영향 근거로 쓰지 않는다.
- 브라우저·버전, DOM 최종 형태, event firing 전후 marker, 사용자 상호작용 유무를 증거에 기록한다. sanitizer 통과만 하고 event가 발화하지 않으면 negative/conditional 결과다.
- 기존 공개 root와 동일한 payload가 동작해도 신규 취약점으로 승격하지 않는다. source, parser mutation, final sink, actor, 영향이 distinct한지 별도로 대조한다.

## 출처

- PortSwigger Web Security Academy, Cross-site scripting cheat sheet, `onvalidationstatuschange`: https://portswigger.net/web-security/cross-site-scripting/cheat-sheet#onvalidationstatuschange
