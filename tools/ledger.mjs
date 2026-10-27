// Appends one entry to ledger/LEDGER.jsonl. Never rewrites existing lines.
//
// node tools/ledger.mjs --agent spec-reports --model claude-sonnet-5-5 --change baseline-specs \
//   --task "Draft ui/reports-* specs" --event finish --files "openspec/specs/ui/reports-requests/spec.md" \
//   --commit HEAD --verification "openspec validate --strict: 5/5 pass"
//
// --commit HEAD is resolved to the current short hash. --files takes a comma-separated list.
import fs from 'node:fs';
import { execSync } from 'node:child_process';

const LEDGER = new URL('../ledger/LEDGER.jsonl', import.meta.url);
const EVENTS = ['start', 'finish', 'review', 'correction'];
const REQUIRED = ['agent', 'model', 'change', 'task', 'event'];

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i]?.replace(/^--/, '');
    if (!key || argv[i + 1] === undefined) throw new Error(`Missing value for ${argv[i]}`);
    args[key] = argv[i + 1];
  }
  return args;
}

const args = parseArgs(process.argv.slice(2));
for (const key of REQUIRED) {
  if (!args[key]) throw new Error(`--${key} is required`);
}
if (!EVENTS.includes(args.event)) throw new Error(`--event must be one of ${EVENTS.join(', ')}`);

const commit =
  args.commit === 'HEAD'
    ? execSync('git rev-parse --short HEAD').toString().trim()
    : (args.commit ?? null);

const entry = {
  ts: new Date().toISOString(),
  agent: args.agent,
  model: args.model,
  change: args.change,
  task: args.task,
  event: args.event,
  files: args.files
    ? args.files
        .split(',')
        .map((f) => f.trim())
        .filter(Boolean)
    : [],
  commit,
  verification: args.verification ?? null,
};

const existing = fs.existsSync(LEDGER) ? fs.readFileSync(LEDGER, 'utf8') : '';
const prefix = existing.length > 0 && !existing.endsWith('\n') ? '\n' : '';
fs.appendFileSync(LEDGER, `${prefix}${JSON.stringify(entry)}\n`);
console.log(JSON.stringify(entry));
