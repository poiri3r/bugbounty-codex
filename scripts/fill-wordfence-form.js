#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const values = process.argv.slice(2);
const isWordfenceUrl = value => {
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && (url.hostname === 'wordfence.com' || url.hostname.endsWith('.wordfence.com'));
  } catch {
    return false;
  }
};
if (values.includes('--self-test')) {
  const accepted = ['https://wordfence.com/form', 'https://www.wordfence.com/form'].every(isWordfenceUrl);
  const rejected = ['http://wordfence.com/form', 'https://evilwordfence.com/form',
    'https://wordfence.com.evil.test/form', 'not-a-url'].every(value => !isWordfenceUrl(value));
  if (!accepted || !rejected) throw new Error('Wordfence URL boundary self-test failed');
  console.log('form URL boundary self-test passed');
  process.exit(0);
}
const option = name => {
  const index = values.indexOf(`--${name}`);
  return index >= 0 ? values[index + 1] : undefined;
};
const folderArg = option('folder');
if (!folderArg || values.includes('--help')) {
  console.error('Usage: fill-wordfence-form.js --folder report/F-ID [--port 9223] [--fill]');
  process.exit(folderArg ? 0 : 2);
}
const project = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const folder = path.resolve(folderArg);
if (!folder.startsWith(`${path.join(project, 'report')}${path.sep}`)) throw new Error('Folder must be under report/');
const data = JSON.parse(fs.readFileSync(path.join(folder, 'submission.json'), 'utf8'));
if (data.status !== 'ready' || data.video?.playback_review !== 'PASS' || data.certification?.tested !== true) {
  throw new Error('Package must be ready, playback-reviewed, and step-by-step tested');
}
const video = path.resolve(folder, data.video.path);
if (!video.startsWith(`${folder}${path.sep}`) || !fs.statSync(video).isFile()) throw new Error('Video is missing or outside package');

const environment = data.environment;
const fields = [
  ['Type of Software', data.software.type],
  ['Description of Vulnerability', data.vulnerability.description],
  ['Vulnerability Type', data.vulnerability.type],
  ['Impact Statement', data.vulnerability.impact],
  ['Common Weakness (CWE) Type', data.vulnerability.cwe],
  ['Authentication Level Required', data.vulnerability.authentication],
  ['References to Affected Code', data.affected_code_urls.join('\n')],
  ['References', data.references.join('\n')],
  ['What is your Proof of Concept?', data.poc.type],
  ['Provide a working concept', data.poc.body],
  ['Please provide all environment', `WordPress ${environment.wordpress}; PHP ${environment.php}; ${environment.database}; settings: ${environment.settings}; attacker: ${environment.attacker_role}`],
  ['Please certify that you have tested', data.certification.tested ? 'Yes' : 'No'],
  ['Did you use AI', data.certification.ai_used ? 'Yes' : 'No'],
  ['Have you requested a CVE', data.certification.cve_requested_elsewhere ? 'Yes' : 'No'],
  ['Have you reported this to another vendor', data.certification.reported_to_other_vendor ? 'Yes' : 'No'],
];

const port = option('port') || '9223';
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = targets.find(item => {
  return item.type === 'page' && isWordfenceUrl(item.url);
});
if (!target) throw new Error('Open the Wordfence form in the dedicated Chrome first');
const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  ws.addEventListener('open', resolve, { once: true });
  ws.addEventListener('error', reject, { once: true });
});
let id = 0;
const pending = new Map();
ws.addEventListener('message', event => {
  const message = JSON.parse(event.data);
  const done = pending.get(message.id);
  if (!done) return;
  pending.delete(message.id);
  message.error ? done.reject(new Error(JSON.stringify(message.error))) : done.resolve(message.result || {});
});
const call = (method, params = {}) => new Promise((resolve, reject) => {
  const current = ++id;
  pending.set(current, { resolve, reject });
  ws.send(JSON.stringify({ id: current, method, params }));
});

const scanForm = function scanForm(requested, fill) {
    const clean = value => (value || '').replace(/\\s+/g, ' ').trim();
    const labels = [...document.querySelectorAll('label')];
    const result = [];
    const setNative = (element, value) => {
      if (element.tagName === 'SELECT') {
        const option = [...element.options].find(item => clean(item.textContent) === value || clean(item.textContent).includes(value));
        if (!option) return false;
        element.value = option.value;
      } else if (element.type === 'radio' || element.type === 'checkbox') {
        element.checked = true;
      } else {
        element.value = value;
      }
      element.dispatchEvent(new Event('input', { bubbles: true }));
      element.dispatchEvent(new Event('change', { bubbles: true }));
      return true;
    };
    for (const [name, value] of requested) {
      if (/terms|release|privacy|agree/i.test(name)) throw new Error('Legal agreement fields are forbidden');
      const matches = labels.filter(label => clean(label.textContent).toLowerCase().startsWith(name.toLowerCase()));
      let controls = [];
      for (const label of matches) {
        if (label.htmlFor) controls.push(document.getElementById(label.htmlFor));
        controls.push(label.querySelector('input,textarea,select'));
        const container = label.closest('fieldset,div');
        if (container) controls.push(...container.querySelectorAll('input,textarea,select'));
      }
      controls = [...new Set(controls.filter(Boolean))];
      let control = controls.find(item => ['INPUT', 'TEXTAREA', 'SELECT'].includes(item.tagName));
      if (control?.type === 'radio' || control?.type === 'checkbox') {
        control = controls.find(item => clean(item.closest('label')?.textContent).includes(value)) || control;
      }
      result.push({ name, labels: matches.length, controls: controls.length, filled: Boolean(fill && control && setNative(control, value)) });
    }
    const videoInputs = [...document.querySelectorAll('input[type=file]')];
    const submit = [...document.querySelectorAll('button,input[type=submit]')].map(item => clean(item.textContent || item.value));
    return { fields: result, videoInputs: videoInputs.length, submitControlsSeenButUntouched: submit.length };
  };
const evaluateForm = fill => call('Runtime.evaluate', {
  expression: `(${scanForm.toString()})(${JSON.stringify(fields)}, ${fill})`,
  returnByValue: true,
});
const scan = await evaluateForm(false);
if (scan.exceptionDetails) throw new Error(JSON.stringify(scan.exceptionDetails));
const summary = scan.result.value;
const missing = summary.fields.filter(item => item.labels !== 1 || item.controls < 1);
if (missing.length || summary.videoInputs !== 1) {
  ws.close();
  throw new Error(`Form mismatch; nothing is submitted: ${JSON.stringify({ missing, videoInputs: summary.videoInputs })}`);
}
if (values.includes('--fill')) {
  const filled = await evaluateForm(true);
  if (filled.exceptionDetails || filled.result.value.fields.some(item => !item.filled)) {
    ws.close();
    throw new Error('Form changed during fill; review the page manually');
  }
  const input = await call('Runtime.evaluate', { expression: 'document.querySelector("input[type=file]")' });
  if (!input.result?.objectId) throw new Error('Video input disappeared');
  await call('DOM.setFileInputFiles', { files: [video], objectId: input.result.objectId });
}
console.log(JSON.stringify({ mode: values.includes('--fill') ? 'filled-not-submitted' : 'dry-run',
  ...summary, fields: values.includes('--fill') ? summary.fields.map(item => ({ ...item, filled: true })) : summary.fields }, null, 2));
ws.close();
