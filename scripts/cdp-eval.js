#!/usr/bin/env node
import fs from 'node:fs';

const args = Object.fromEntries(process.argv.slice(2).map((value, index, all) =>
  value.startsWith('--') ? [value.slice(2), all[index + 1] ?? ''] : null
).filter(Boolean));
const port = args.port || '9223';
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const target = targets.find(item => item.type === 'page' && item.url.includes(args['url-contains']));
if (!target) throw new Error(`page not found: ${args['url-contains']}`);

const ws = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  ws.addEventListener('open', resolve, { once: true });
  ws.addEventListener('error', reject, { once: true });
});
let id = 0;
const call = (method, params = {}) => new Promise((resolve, reject) => {
  const current = ++id;
  const onMessage = event => {
    const message = JSON.parse(event.data);
    if (message.id !== current) return;
    ws.removeEventListener('message', onMessage);
    message.error ? reject(new Error(JSON.stringify(message.error))) : resolve(message.result || {});
  };
  ws.addEventListener('message', onMessage);
  ws.send(JSON.stringify({ id: current, method, params }));
});

if (args['bring-to-front'] !== undefined) await call('Page.bringToFront');
if (args.navigate) {
  await call('Page.navigate', { url: args.navigate });
  await new Promise(resolve => setTimeout(resolve, 2500));
}
if (args['file-selector']) {
  const node = await call('Runtime.evaluate', {
    expression: `document.querySelector(${JSON.stringify(args['file-selector'])})`,
  });
  const objectId = node.result?.objectId;
  if (!objectId) throw new Error(`file input not found: ${args['file-selector']}`);
  await call('DOM.setFileInputFiles', { files: [args.file], objectId });
}
if (args.screenshot) {
  const shot = await call('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync(args.screenshot, Buffer.from(shot.data, 'base64'));
  console.log(JSON.stringify({ screenshot: args.screenshot }));
  ws.close();
  process.exit(0);
}

const expression = fs.readFileSync(0, 'utf8') || 'location.href';
const result = await call('Runtime.evaluate', {
  expression,
  awaitPromise: true,
  returnByValue: true,
});
if (result.exceptionDetails) throw new Error(JSON.stringify(result.exceptionDetails));
const value = result.result?.value;
if (args.output && typeof value === 'string' && value.startsWith('data:')) {
  const bytes = Buffer.from(value.slice(value.indexOf(',') + 1), 'base64');
  fs.writeFileSync(args.output, bytes);
  console.log(JSON.stringify({ output: args.output, bytes: bytes.length }));
} else {
  console.log(args.raw && typeof value === 'string' ? value : JSON.stringify(value, null, 2));
}
ws.close();
