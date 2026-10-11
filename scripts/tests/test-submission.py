"""Submission package tests; no browser or network use."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('prepare_submission', SCRIPTS / 'prepare-submission.py')
submission = importlib.util.module_from_spec(spec)
spec.loader.exec_module(submission)


class SubmissionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='submission-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.folder = self.root / 'inbox/1/T-001'
        (self.folder / 'video').mkdir(parents=True)
        (self.folder / 'video/poc.mp4').write_bytes(b'fixture')
        self.data = {
            'status': 'ready',
            'software': {'type': 'WordPress Plugin', 'name': 'Fixture', 'slug': 'fixture',
                         'version': '1.0', 'url': 'https://wordpress.org/plugins/fixture/'},
            'vulnerability': {'title': 'Fixture issue', 'description': 'A concise description.',
                              'type': 'Stored Cross-Site Scripting',
                              'impact': 'Unauthenticated users can execute script in an administrator session.',
                              'cwe': 'CWE-79', 'authentication': 'Unauthenticated'},
            'affected_code_urls': ['https://example.test/code'], 'references': [], 'contributors': [],
            'poc': {'type': 'Walkthrough', 'body': '1. Send the fixture request.\n2. Open the local admin page.'},
            'video': {'path': 'video/poc.mp4', 'playback_review': 'PASS',
                      'visible_result': 'An alert appears.'},
            'environment': {'wordpress': '6.8', 'php': '8.3', 'database': 'MariaDB 11',
                            'settings': 'Defaults', 'attacker_role': 'Unauthenticated'},
            'certification': {'tested': True, 'ai_used': True, 'cve_requested_elsewhere': False,
                              'reported_to_other_vendor': False},
            'submission': {'submitted_at': None, 'submission_id': None},
        }

    def write(self):
        (self.folder / 'submission.json').write_text(json.dumps(self.data))

    def test_valid_package_renders_form_fields(self):
        self.write()
        _, data = submission.load_package(self.root, self.folder)
        report = submission.render(data)
        self.assertIn('## Proof of Concept', report)
        self.assertIn('Impact statement:', report)
        self.assertIn('AI used: Yes', report)

    def test_rejects_bad_impact_video_and_status(self):
        for mutate in ('impact', 'playback', 'missing-video', 'status'):
            with self.subTest(mutate=mutate):
                original = json.loads(json.dumps(self.data))
                if mutate == 'impact': self.data['vulnerability']['impact'] = 'x' * 201
                if mutate == 'playback': self.data['video']['playback_review'] = 'PENDING'
                if mutate == 'missing-video': self.data['video']['path'] = 'video/missing.mp4'
                if mutate == 'status': self.data['status'] = 'unknown'
                self.write()
                with self.assertRaises(ValueError):
                    submission.load_package(self.root, self.folder)
                self.data = original

    def test_rejects_noncanonical_package_and_video_path(self):
        self.write()
        wrong = self.root / 'inbox/not-a-round/not-a-task'
        wrong.mkdir(parents=True)
        with self.assertRaises(ValueError):
            submission.load_package(self.root, wrong)
        self.data['video']['path'] = 'video/demo.mp4'
        (self.folder / 'video/demo.mp4').write_bytes(b'fixture')
        self.write()
        with self.assertRaisesRegex(ValueError, 'video/poc.mp4'):
            submission.load_package(self.root, self.folder)

    def test_report_rejects_extra_material(self):
        report = self.root / 'report/F-FIXTURE'
        report.parent.mkdir(parents=True)
        self.folder.rename(report)
        self.folder = report
        self.write()
        (report / 'REPORT.md').write_text('# report\n')
        (report / 'source.zip').write_bytes(b'not allowed')
        with self.assertRaisesRegex(ValueError, 'non-submission material'):
            submission.load_package(self.root, report)

    def test_rejects_package_and_video_symlinks(self):
        self.write()
        linked = self.root / 'inbox/1/T-002'
        linked.symlink_to(self.folder, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            submission.load_package(self.root, linked)
        (self.folder / 'video/poc.mp4').unlink()
        outside = self.root / 'outside.mp4'
        outside.write_bytes(b'fixture')
        (self.folder / 'video/poc.mp4').symlink_to(outside)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            submission.load_package(self.root, self.folder)

    def test_rejects_outside_package(self):
        outside = Path(self.temp.name).parent / 'outside-submission'
        with self.assertRaisesRegex(ValueError, 'outside'):
            submission.load_package(self.root, outside)


if __name__ == '__main__':
    unittest.main()
