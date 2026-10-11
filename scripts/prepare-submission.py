#!/usr/bin/env python3
"""Validate Wordfence form data and optionally render its human-readable report."""
import argparse
import json
import os
from pathlib import Path
import re
import sys


def require_text(value, name):
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f'Missing text field: {name}')
    return value.strip()


def checked_path(root, path, label):
    root = root.resolve()
    absolute = path.absolute()
    try:
        relative = absolute.relative_to(root)
    except ValueError as error:
        raise ValueError(f'{label} is outside its allowed root') from error
    current = root
    for part in relative.parts:
        current /= part
        if current.is_symlink() or os.path.ismount(current):
            raise ValueError(f'{label} symlink or mount refused')
    return absolute.resolve()


def load_package(project, folder):
    project = project.resolve()
    folder = checked_path(project, folder, 'Package')
    relative = folder.relative_to(project)
    parts = relative.parts
    inbox_package = (len(parts) == 3 and parts[0] == 'inbox' and parts[1].isdigit()
                     and re.fullmatch(r'T-\d+', parts[2]))
    report_package = len(parts) == 2 and parts[0] == 'report' and parts[1].startswith('F-')
    if not inbox_package and not report_package:
        raise ValueError('Package must be inbox/<round>/T-ID or report/F-ID')
    source = folder / 'submission.json'
    data = json.loads(source.read_text(encoding='utf-8'))

    allowed_status = ('ready',) if inbox_package else ('ready', 'submitted', 'closed')
    if data.get('status') not in allowed_status:
        raise ValueError('Invalid submission status')
    software = data['software']
    for field in ('type', 'name', 'slug', 'version', 'url'):
        require_text(software[field], f'software.{field}')
    vulnerability = data['vulnerability']
    for field in ('title', 'description', 'type', 'impact', 'cwe', 'authentication'):
        require_text(vulnerability[field], f'vulnerability.{field}')
    if len(vulnerability['impact']) > 200:
        raise ValueError('Impact statement exceeds 200 characters')
    poc = data['poc']
    require_text(poc['type'], 'poc.type')
    require_text(poc['body'], 'poc.body')
    environment = data['environment']
    for field in ('wordpress', 'php', 'database', 'settings', 'attacker_role'):
        require_text(environment[field], f'environment.{field}')
    video = data['video']
    video_path = Path(require_text(video['path'], 'video.path'))
    if video_path.as_posix() != 'video/poc.mp4':
        raise ValueError('Video must be video/poc.mp4')
    if video.get('playback_review') != 'PASS':
        raise ValueError('Video playback review must be PASS')
    require_text(video['visible_result'], 'video.visible_result')
    resolved_video = checked_path(folder, folder / video_path, 'Video')
    if not resolved_video.is_relative_to(folder) or not resolved_video.is_file():
        raise ValueError('Video file is missing or outside the package')
    certification = data['certification']
    for field in ('tested', 'ai_used', 'cve_requested_elsewhere', 'reported_to_other_vendor'):
        if not isinstance(certification.get(field), bool):
            raise ValueError(f'Expected boolean: certification.{field}')
    if certification['tested'] is not True:
        raise ValueError('Step-by-step PoC certification must be true')
    for field in ('affected_code_urls', 'references', 'contributors'):
        if not isinstance(data.get(field), list) or not all(isinstance(v, str) for v in data[field]):
            raise ValueError(f'Expected string array: {field}')
    if report_package:
        allowed_entries = {'submission.json', 'REPORT.md', 'video', 'poc'}
        unexpected = {entry.name for entry in folder.iterdir()} - allowed_entries
        video_entries = {entry.name for entry in (folder / 'video').iterdir()}
        if unexpected or video_entries != {'poc.mp4'}:
            raise ValueError('Report package contains non-submission material')
    return folder, data


def bullets(values):
    return '\n'.join(f'- {value}' for value in values) if values else '- None'


def render(data):
    software, vulnerability = data['software'], data['vulnerability']
    environment, certification = data['environment'], data['certification']
    submitted = data['submission']
    return f"""# {software['name']} {software['version']} — {vulnerability['title']}

## Software Details

- Type: {software['type']}
- Name: {software['name']}
- Slug: {software['slug']}
- Affected version: {software['version']}
- Official URL: {software['url']}

## Vulnerability Details

- Vulnerability type: {vulnerability['type']}
- CWE: {vulnerability['cwe']}
- Authentication required: {vulnerability['authentication']}
- Impact statement: {vulnerability['impact']}

### Description

{vulnerability['description'].strip()}

### Affected Code

{bullets(data['affected_code_urls'])}

### References

{bullets(data['references'])}

### Contributing Researchers

{bullets(data['contributors'])}

## Proof of Concept

- Type: {data['poc']['type']}

{data['poc']['body'].strip()}

## Video Demonstration

- File: `{data['video']['path']}`
- Playback review: PASS
- Visible result: {data['video']['visible_result']}

## Environment

- WordPress: {environment['wordpress']}
- PHP: {environment['php']}
- Database: {environment['database']}
- Settings: {environment['settings']}
- Attacker role: {environment['attacker_role']}

## Declarations

- PoC step-by-step tested: Yes
- AI used: {'Yes' if certification['ai_used'] else 'No'}
- CVE requested from another CNA: {'Yes' if certification['cve_requested_elsewhere'] else 'No'}
- Reported to another vendor: {'Yes' if certification['reported_to_other_vendor'] else 'No'}
- Submission status: {data['status']}
- Submitted at: {submitted.get('submitted_at') or 'Not submitted'}
- Submission ID: {submitted.get('submission_id') or 'None'}
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder', type=Path)
    parser.add_argument('--write-report', action='store_true')
    args = parser.parse_args()
    project = Path(__file__).resolve().parent.parent
    try:
        folder, data = load_package(project, args.folder)
        report = render(data)
        if args.write_report:
            (folder / 'REPORT.md').write_text(report, encoding='utf-8')
        print(json.dumps({'valid': True, 'report': str((folder / 'REPORT.md').relative_to(project)),
                          'written': args.write_report}))
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        parser.exit(1, f'Submission refused: {error}\n')


if __name__ == '__main__':
    main()
