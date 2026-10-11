#!/usr/bin/env python3
"""Preview or remove closed task directories after their durable record is verified."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil


def text_digest(text):
    return hashlib.sha256(text.encode()).hexdigest()


def digest(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def safe_path(root, value):
    path = Path(value)
    if path.is_absolute() or not path.parts or any(part in ('.', '..') for part in path.parts):
        raise ValueError(f'Expected explicit project-relative path: {value}')
    result = root
    for part in path.parts:
        result /= part
        if result.is_symlink():
            raise ValueError(f'Symlink refused: {value}')
        if os.path.ismount(result):
            raise ValueError(f'Mount refused: {value}')
    if not result.resolve().is_relative_to(root) or result == root:
        raise ValueError(f'Outside project: {value}')
    return result


def inventory(target, hash_files=False):
    entries = [target]
    for directory, folders, files in os.walk(target, followlinks=False):
        entries.extend(Path(directory) / name for name in folders + files)
    snapshot = []
    for entry in sorted(set(entries)):
        if entry.is_symlink() or os.path.ismount(entry):
            raise ValueError(f'Link or mount refused: {entry}')
        if not entry.is_dir() and not entry.is_file():
            raise ValueError(f'Special file refused: {entry}')
        stat = entry.stat()
        fingerprint = digest(entry) if hash_files and entry.is_file() else None
        snapshot.append((str(entry), stat.st_ino, stat.st_size, stat.st_mtime_ns, fingerprint))
    return snapshot


def service_row(root, task, slug):
    rows = []
    with (root / 'project/SERVICE.md').open(encoding='utf-8') as handle:
        for line in handle:
            exact_task = re.compile(rf'(?<![A-Za-z0-9-]){re.escape(task)}(?!\d)')
            if line.startswith('| S-') and f'`{slug}`' in line and exact_task.search(line):
                rows.append(line.rstrip('\n'))
    if len(rows) != 1:
        raise ValueError('Expected exactly one matching SERVICE row')
    return rows[0]


def documents(root):
    paths = {root / name for name in ('HANDOFF.md', 'STATUS.md', 'project/SERVICE.md', 'project/RULES.md')}
    paths.update(root.glob('report/F-*/REPORT.md'))
    return sorted(path for path in paths if path.exists())


def prepare(root, manifest_path):
    root = root.resolve()
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    task, slug = manifest['task_id'], manifest['slug']
    if not re.fullmatch(r'T-\d+', task) or not re.fullmatch(r'[a-z0-9][a-z0-9._-]*', slug):
        raise ValueError('Invalid task ID or slug')
    if manifest['state'] not in ('closed-no-candidate', 'closed-retained'):
        raise ValueError('Task is not closed')
    if manifest.get('resources_stopped') is not True or manifest.get('references_reviewed') is not True:
        raise ValueError('Resource shutdown and human reference review must be confirmed')

    row = service_row(root, task, slug)
    if text_digest(row) != manifest['service_row_sha256']:
        raise ValueError('Missing or changed SERVICE row')
    protected = [manifest_path.resolve()]
    retained_snapshot = []
    if manifest['state'] == 'closed-no-candidate':
        if not re.search(r'후보 없음|후보 0|no candidate', row, re.IGNORECASE):
            raise ValueError('No-candidate verdict must be explicit in SERVICE')
        if 'report' in manifest or 'submission_sha256' in manifest:
            raise ValueError('No-candidate state cannot claim a report package')
    else:
        report = safe_path(root, manifest['report'])
        parts = report.relative_to(root).parts
        if len(parts) != 2 or parts[0] != 'report' or not parts[1].startswith('F-'):
            raise ValueError('Retained result must be report/F-ID')
        submission = report / 'submission.json'
        video = report / 'video/poc.mp4'
        result = report / 'REPORT.md'
        if not all(path.is_file() for path in (submission, video, result)):
            raise ValueError('Incomplete report package')
        data = json.loads(submission.read_text(encoding='utf-8'))
        if data.get('status') not in ('ready', 'submitted', 'closed'):
            raise ValueError('Report package is not ready')
        if data.get('video', {}).get('playback_review') != 'PASS':
            raise ValueError('Video playback review is not PASS')
        if digest(submission) != manifest['submission_sha256']:
            raise ValueError('Missing or changed submission.json')
        protected.append(report)
        retained_snapshot = inventory(report, hash_files=True)

    allowed = {f'tmp/{task}'}
    allowed.update(str(path.relative_to(root)) for path in root.glob(f'inbox/[0-9]*/{task}'))
    requested = manifest['remove']
    if not requested or len(set(requested)) != len(requested):
        raise ValueError('Empty or duplicate deletion targets')
    if any(value not in allowed for value in requested):
        raise ValueError('Only this task whole tmp/inbox directories may be removed')
    targets = [safe_path(root, value) for value in requested]
    if any(not target.is_dir() for target in targets):
        raise ValueError('Deletion target must be an existing task directory')
    snapshots = []
    for target in targets:
        if any(path == target or path.is_relative_to(target) for path in protected):
            raise ValueError('Deletion overlaps a protected record')
        snapshots.extend(inventory(target))

    for document in documents(root):
        content = document.read_text(encoding='utf-8')
        for target in targets:
            relative = str(target.relative_to(root))
            if relative in content or str(target) in content:
                raise ValueError(f'Remaining path reference in {document.relative_to(root)}')
    approval = hashlib.sha256(json.dumps([manifest, snapshots, retained_snapshot], sort_keys=True).encode()).hexdigest()
    return targets, approval


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--approve-plan', default='')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    try:
        targets, approval = prepare(root, args.manifest)
        if args.apply:
            if args.approve_plan != approval:
                raise ValueError('Use the unchanged preview plan hash with --approve-plan')
            for target in targets:
                shutil.rmtree(target)
        print(json.dumps({'mode': 'applied' if args.apply else 'preview',
                          'plan_sha256': approval,
                          'paths': [str(path.relative_to(root)) for path in targets],
                          'warning': 'Deletion is permanent; files are not moved to trash.'}))
    except (OSError, ValueError, KeyError, TypeError, json.JSONDecodeError) as error:
        parser.exit(1, f'Cleanup refused: {error}\n')


if __name__ == '__main__':
    main()
