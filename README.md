# Bug Bounty Codex

Codex-assisted research for responsibly finding vulnerabilities in public WordPress plugins and themes.

## Scope

- Static analysis of publicly distributed source code
- Dynamic validation in an isolated localhost WordPress environment
- Evidence-backed disclosure through an explicitly selected bug bounty program

Live websites, third-party infrastructure, denial-of-service testing, automated submissions, and access to non-test data are out of scope.

## Current state

The Docker Compose lab runs WordPress and MariaDB on an egress-blocked internal network. A dedicated Nginx gateway exposes WordPress only on `127.0.0.1`, and WP-CLI loads local plugin archives without giving WordPress external network access.

## Local lab

```bash
cp .env.example .env
make install
make verify
```

Open `http://127.0.0.1:8080`. To install an official plugin archive copied into the ignored `plugins/` directory:

```bash
make plugin PLUGIN=example.zip
```

Use `make down` to stop the lab. `make reset` also deletes the lab database and WordPress volumes.

Read `AGENTS.md`, `HANDOFF.md`, `STATUS.md`, and `MEMORY.md` before starting work.
