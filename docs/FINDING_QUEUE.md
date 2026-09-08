# FINDING_QUEUE.md — 후보 검증·제출 우선순위를 정할 때 읽는 공개 안전 큐다.

Updated: 2026-09-08

이 파일에는 finding ID, 내부 상태, 추천 채널, 다음 gate만 기록한다.

Official references checked 2026-09-08:

- <https://www.wordfence.com/bug-bounty-program-terms/>
- <https://www.wordfence.com/threat-intel/vulnerabilities/submit/>
- <https://patchstack.com/articles/bug-bounty-guidelines-rules/>
- <https://patchstack.com/database/report>

## P0 — close the last gates first

| ID | State | Recommended channel | Next gate |
| --- | --- | --- | --- |
| `NF-2026-001` | independent-review-pass | Wordfence | Human rerun, same-day duplicate check and explicit user approval |
| `BDP-2026-001` | independent-review-pass-hold | Patchstack mVDP | Confirm the 24-hour discovery policy, run same-day checks and obtain explicit user approval |
| `WCAR-2026-001` | candidate-reproduced | Patchstack mVDP | Independent impact and eligibility review |
| `ET-2026-001` | candidate-reproduced | Patchstack mVDP | Independent impact and eligibility review |
| `NWS-2026-001` | candidate-reproduced | Wordfence scope check | Independent impact and policy review |
| `EP-2026-001` | candidate-two-clean-runs | Patchstack mVDP | Independent review and submission-day duplicate check |
| `PR-2026-001` | candidate-reproduced | Patchstack scope check | Significant-impact and policy review |
| `SCT-2026-001` | candidate-reproduced | Patchstack mVDP | Consistency, novelty and independent review |
| `NGG-2026-001` | candidate-reproduced-conditions-open | Wordfence scope check | Deployment-condition and independent review |

## P1 — strong evidence; channel decision required

| ID | State | Recommended channel | Next gate |
| --- | --- | --- | --- |
| `BWU-2026-001` | candidate-reproduced | Vendor / hold | Channel eligibility and independent review |
| `EVF-2026-002` | candidate-reproduced | Patchstack mVDP check | Eligibility and consolidation decision |
| `EVF-2026-003` | candidate-reproduced | Patchstack mVDP check | Impact and consolidation decision |
| `METFORM-2026-001` | candidate-reproduced | Patchstack mVDP check | Type eligibility and independent review |
| `WVB-2026-002` | candidate-reproduced | Wordfence scope check | Prerequisite classification and independent review |
| `UWP-2026-001` | candidate-reproduced | Wordfence scope check | Configuration, reach and independent review |
| `HMWP-2026-002` | candidate-reproduced | Vendor / hold | Prerequisite and duplicate review |
| `EVF-2026-001` | candidate-reproduced | Patchstack mVDP check | Significant-impact and eligibility review |
| `EVF-2026-004` | candidate-reproduced | Patchstack mVDP check | Eligibility and independent review |
| `EKIT-2026-001` | candidate-reproduced | Patchstack mVDP check | Impact and eligibility review |
| `PPP-2026-001` | candidate-reproduced | Patchstack mVDP check | Impact and eligibility review |
| `AGR-2026-001` | candidate-reproduced | Patchstack mVDP check | Impact and eligibility review |

## P2 — unresolved prerequisite or program fit

| ID | State | Recommended channel | Next gate |
| --- | --- | --- | --- |
| `CTX-2026-001` | candidate-reproduced | Vendor / hold | Independent review and vendor-channel check |
| `DIR-2026-001` | candidate-reproduced | Hold | Program eligibility review |
| `MSA-2026-001` | candidate-reproduced | Vendor / hold | VDP and vendor-channel check |
| `MSA-2026-002` | candidate-reproduced | Vendor / hold | VDP and vendor-channel check |
| `MSA-2026-003` | candidate-reproduced | Vendor / hold | VDP and vendor-channel check |
| `TUTOR-2026-001` | candidate-reproduced | Vendor / hold | Channel eligibility and independent review |
| `PPC-2026-001` | candidate-reproduced | Vendor / hold | Default-configuration and channel review |
| `FEA-2026-001` | candidate-reproduced-gates-open | Hold | Discovery-condition and duplicate review |
| `HMWP-2026-001` | candidate-reproduced | Vendor / hold | Practical-impact and independent review |
| `WUF-2026-001` | candidate-reproduced | Hold | Program eligibility and independent review |
| `WVB-2026-001` | candidate-reproduced | Hold | Prerequisite and interaction review |
| `WDM-2026-001` | candidate-reproduced | Vendor / hold | Channel and independent review |
| `WPM-2026-001` | candidate-reproduced | Vendor / hold | Channel and independent review |

## P3 — preserve; do not draft yet

| ID | State | Recommended channel | Next gate |
| --- | --- | --- | --- |
| `BOOKING-2026-001` | candidate-reproduced | Hold | Program-impact review |
| `CEV-2026-001` | candidate-reproduced | Hold | Program-impact review |
| `CL-2026-001` | candidate-reproduced | Patchstack mVDP check | Eligibility review |
| `COC-2026-001` | candidate-reproduced | Vendor | Vendor-channel review |
| `DOKAN-2026-001` | candidate-reproduced | Hold | Program-impact review |
| `EM-2026-001` | candidate-reproduced | Hold | Program-impact review |
| `FORMIDABLE-2026-001` | candidate-reproduced | Hold | Program-impact review |
| `GEO-2026-001` | candidate-reproduced | Vendor / hold | Channel eligibility review |
| `LATEPOINT-2026-001` | candidate-reproduced | Hold | Program-impact review |
| `MYCRED-2026-001` | candidate-reproduced-lineage-open | Hold | Novelty and program review |
| `WPD-2026-001` | candidate-reproduced | Vendor / hold | Channel and impact review |

## Closed — do not submit

| ID | State | Recommended channel | Next gate |
| --- | --- | --- | --- |
| `ASE-LEAD-ATTACHMENT-URL` | closed-below-gate | Do not submit | None |
| `CFDB7-2026-001` | closed-below-gate | Do not submit | None |
| `PAFE-2026-001` | closed-below-gate | Do not submit | None |
| `RFW-2026-001` | closed-gate-failed | Do not submit | None |
| `SJL-2026-001` | closed-gate-failed | Do not submit | None |
| `SWPM-2026-001` | closed-known-lineage-below-gate | Do not submit | None |
| `UR-2026-001` | closed-known-duplicate | Do not submit | None |
| `WPD-LEAD-OAUTH` | closed-below-gate | Do not submit | None |
| `WPEM-2026-001` | closed-known-duplicate | Do not submit | None |
