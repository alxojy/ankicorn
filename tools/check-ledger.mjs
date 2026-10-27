// Fails if ledger/LEDGER.jsonl was changed in any way other than appending valid lines.
//
// node tools/check-ledger.mjs            compare the working tree with HEAD (pre-commit)
// node tools/check-ledger.mjs <base-ref> compare HEAD with <base-ref> (review / CI)
// node tools/check-ledger.mjs <base-ref> --final  also require every task started in the range to be
//                                         finished, with a "GATE PASSED @<sha>" verification (pre-push to main)
import fs from 'node:fs';
import { execSync } from 'node:child_process';

const PATH = 'ledger/LEDGER.jsonl';
const argv = process.argv.slice(2);
const final = argv.includes('--final');
const base = argv.find((a) => !a.startsWith('--'));

function show(ref) {
  try {
    return execSync(`git show ${ref}:${PATH}`, { stdio: ['ignore', 'pipe', 'ignore'] }).toString();
  } catch {
    return '';
  }
}

const before = base ? show(base) : show('HEAD');
const after = base ? show('HEAD') : fs.readFileSync(PATH, 'utf8');

const fail = (msg) => {
  console.error(`ledger check failed: ${msg}`);
  process.exit(1);
};

if (!after.startsWith(before))
  fail('existing lines were edited or removed (the ledger is append-only)');

const added = after
  .slice(before.length)
  .split('\n')
  .filter((l) => l.trim() !== '');
for (const [i, line] of added.entries()) {
  let entry;
  try {
    entry = JSON.parse(line);
  } catch {
    fail(`added line ${i + 1} is not valid JSON`);
  }
  for (const key of ['ts', 'agent', 'model', 'change', 'task', 'event']) {
    if (!entry[key]) fail(`added line ${i + 1} is missing "${key}"`);
  }
}
if (final) {
  const entries = (text) =>
    text
      .split('\n')
      .filter((l) => l.trim() !== '')
      .map((l) => JSON.parse(l));
  const addedEntries = entries(after.slice(before.length));
  const all = entries(after);
  for (const start of addedEntries.filter((e) => e.event === 'start')) {
    const finished = all.some(
      (e) => e.event === 'finish' && e.change === start.change && e.task === start.task,
    );
    if (!finished) {
      fail(
        `"${start.change}" (${start.task}) has a start entry but no finish entry; add one with --event finish and the GATE PASSED line`,
      );
    }
  }
  for (const finish of addedEntries.filter((e) => e.event === 'finish')) {
    if (!/GATE PASSED @|node tools\/check-spec/.test(finish.verification ?? '')) {
      fail(
        `finish entry for "${finish.change}" does not quote a GATE PASSED line in "verification"`,
      );
    }
  }
}
console.log(`ledger ok (${added.length} new entr${added.length === 1 ? 'y' : 'ies'})`);
