# Target pilot — 대상 선정과 원본 고정 기록

Checked: 2026-09-07

초기 파일럿은 WordPress.org에서 최신 안정 버전을 내려받을 수 있는 무료 플러그인 5개로 제한한다. 활성 설치 수와 갱신일은 선정일의 WordPress.org API 응답을 기준으로 기록했다.

| Priority | Slug | Version | Active installs | Last updated | Surface | ZIP SHA-256 | Program note |
| --- | --- | --- | ---: | --- | --- | --- | --- |
| 1 | `user-registration` | 5.2.7 | 50,000 | 2026-08-12 | registration, roles, account lifecycle | `0eeef4df9ebfaba369d720157e011c93ce858ed0fe3b65427d956dcbb1ccf15a` | Patchstack Active VDP |
| 2 | `import-users-from-csv-with-meta` | 2.4.17 | 70,000 | 2026-09-01 | CSV import, user creation and updates | `f2929be3c8b15dae34dcec1d5ec7881c6ac8f804093de2baf01689d068b479b6` | Patchstack Active VDP |
| 3 | `file-manager-advanced` | 5.4.13 | 100,000 | 2026-08-13 | file operations and AJAX connector | `6427b8d3b4881bf2c83dd9709b565222ab01d7fde6be90721d3fae56d15bf3a4` | Patchstack Active VDP |
| 4 | `backup-backup` | 2.1.7 | 80,000 | 2026-08-11 | backup, restore and archive download | `24c85f6a221dba334ed326b8ad713da4cd5d23a4179e0f3e72226434451acebc` | No Patchstack VDP observed |
| 5 | `jwt-authentication-for-wp-rest-api` | 1.5.0 | 60,000 | 2026-02-18 | REST authentication and token validation | `97c21033394de71c60acee8fe307c3ce89dae9227fad5fbee9569bc323202498` | VDP status not yet confirmed |

## Official sources

- Plugin metadata and ZIPs: `https://api.wordpress.org/plugins/info/1.2/`
- Wordfence Bug Bounty Program Terms: `https://www.wordfence.com/bug-bounty-program-terms/`
- Patchstack bug bounty rules: `https://patchstack.com/articles/bug-bounty-guidelines-rules/`
- Patchstack accepted vulnerability types: `https://patchstack.com/database/report`

## Handling

- Exact upstream ZIP files are kept under ignored `plugins/` and are not committed.
- Extracted source and analysis work stay under ignored `work/` or temporary local storage.
- An item remains a `candidate` until every acceptance gate in `AGENTS.md` is satisfied.
