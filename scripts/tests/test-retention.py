"""Storage-only tests; no browser, network, or audit actions."""
import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SCRIPTS = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('cleanup_task', SCRIPTS / 'cleanup-task.py')
cleanup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(cleanup)


class RetentionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='retention-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'project').mkdir()
        self.row = '| S-001 | Fixture (`fixture`) 1.0 | 10,000 | `hash` | 2026-10-11 | T-001 · REST · no candidate |'
        (self.root / 'project/SERVICE.md').write_text('# services\n' + self.row + '\n')
        self.tmp = self.root / 'tmp/T-001'
        self.inbox = self.root / 'inbox/1/T-001'
        for path in (self.tmp, self.inbox):
            path.mkdir(parents=True)
            (path / 'fixture.txt').write_text('fixture')
        self.manifest_path = self.root / 'approval.json'
        self.manifest = {
            'task_id': 'T-001', 'slug': 'fixture', 'state': 'closed-no-candidate',
            'resources_stopped': True, 'references_reviewed': True,
            'service_row_sha256': cleanup.text_digest(self.row),
            'remove': ['tmp/T-001', 'inbox/1/T-001'],
        }

    def prepare(self, data=None):
        self.manifest_path.write_text(json.dumps(data or self.manifest))
        return cleanup.prepare(self.root, self.manifest_path)

    def test_preview_and_change_detection(self):
        targets, approval = self.prepare()
        self.assertEqual(targets, [self.tmp, self.inbox])
        (self.tmp / 'fixture.txt').write_text('changed')
        self.assertNotEqual(approval, self.prepare()[1])

    def test_refuses_bad_boundaries_and_state(self):
        cases = [('state', 'pending'), ('resources_stopped', False),
                 ('references_reviewed', False), ('service_row_sha256', 'bad'),
                 ('remove', ['tmp']), ('remove', ['../outside']),
                 ('remove', ['project/services/S-001']), ('remove', ['tmp/T-002']),
                 ('remove', ['tmp/T-001/fixture.txt']),
                 ('remove', ['tmp/T-001', 'tmp/T-001'])]
        for field, value in cases:
            with self.subTest(field=field, value=value):
                data = copy.deepcopy(self.manifest)
                data[field] = value
                with self.assertRaises((ValueError, OSError)):
                    self.prepare(data)

    def test_refuses_links_mounts_and_references(self):
        (self.tmp / 'link').symlink_to(self.root / 'project/SERVICE.md')
        with self.assertRaisesRegex(ValueError, 'Link or mount'):
            self.prepare()
        (self.tmp / 'link').unlink()
        with patch.object(cleanup.os.path, 'ismount', side_effect=lambda path: Path(path) == self.tmp):
            with self.assertRaisesRegex(ValueError, 'Mount'):
                self.prepare()
        (self.root / 'HANDOFF.md').write_text('open: `tmp/T-001`\n')
        with self.assertRaisesRegex(ValueError, 'Remaining path reference'):
            self.prepare()

    def test_retained_report_is_verified(self):
        report = self.root / 'report/F-FIXTURE'
        (report / 'video').mkdir(parents=True)
        submission = report / 'submission.json'
        submission.write_text(json.dumps({'status': 'ready', 'video': {'playback_review': 'PASS'}}))
        (report / 'REPORT.md').write_text('# report\n')
        (report / 'video/poc.mp4').write_bytes(b'fixture')
        self.row = '| S-001 | Fixture (`fixture`) 1.0 | 10,000 | `hash` | 2026-10-11 | T-001 · REST · 제출 후보 F-FIXTURE |'
        (self.root / 'project/SERVICE.md').write_text(self.row + '\n')
        data = copy.deepcopy(self.manifest)
        data.update(state='closed-retained', service_row_sha256=cleanup.text_digest(self.row),
                    report='report/F-FIXTURE', submission_sha256=cleanup.digest(submission))
        _, approval = self.prepare(data)
        (report / 'REPORT.md').write_text('# changed\n')
        self.assertNotEqual(approval, self.prepare(data)[1])
        submission.write_text('{}')
        with self.assertRaises(ValueError):
            self.prepare(data)

    def test_task_id_match_is_exact(self):
        self.row = '| S-001 | Fixture (`fixture`) 1.0 | 10,000 | `hash` | 2026-10-11 | T-20 · REST · 후보 없음 |'
        (self.root / 'project/SERVICE.md').write_text(self.row + '\n')
        data = copy.deepcopy(self.manifest)
        data.update(task_id='T-2', service_row_sha256=cleanup.text_digest(self.row), remove=['tmp/T-001'])
        with self.assertRaisesRegex(ValueError, 'matching SERVICE row'):
            self.prepare(data)

    def test_no_candidate_cannot_claim_report(self):
        data = copy.deepcopy(self.manifest)
        data['report'] = 'report/F-X'
        with self.assertRaisesRegex(ValueError, 'cannot claim'):
            self.prepare(data)

    def test_apply_requires_preview_hash(self):
        local_script = self.root / 'scripts/cleanup-task.py'
        local_script.parent.mkdir()
        local_script.write_bytes((SCRIPTS / 'cleanup-task.py').read_bytes())
        _, approval = self.prepare()
        base = ['python3', str(local_script), str(self.manifest_path), '--apply']
        result = subprocess.run(base, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        result = subprocess.run(base + ['--approve-plan', approval], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.tmp.exists())
        self.assertFalse(self.inbox.exists())

    def test_lookup_exact_slug_only(self):
        lookup = self.root / 'scripts/service-lookup.sh'
        lookup.parent.mkdir()
        lookup.write_bytes((SCRIPTS / 'service-lookup.sh').read_bytes())
        (self.root / 'project/SERVICE.md').write_text(
            '# mention `fixture`\n'
            '| S-001 | Fixture (`fixture`) 1.0 | date | no candidate | result |\n'
            '| S-002 | Other (`fixture-more`) 1.0 | date | mentions `fixture` | result |\n')
        result = subprocess.run(['bash', str(lookup), 'fixture'], capture_output=True, text=True, check=True)
        self.assertIn('S-001', result.stdout)
        self.assertNotIn('S-002', result.stdout)


if __name__ == '__main__':
    unittest.main()
