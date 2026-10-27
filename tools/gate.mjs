// The one command that proves a branch is mergeable. There is no human review:
// if the gate passes (locally and in CI), the work is accepted.
//
// node tools/gate.mjs [--base <ref>] [--full] [--final]
//   --base   ref the branch is compared with (default origin/main)
//   --full   run verify even if an earlier pass covers the code (CI always does)
//   --final  also require every started task to have a finish entry (the pre-push hook to main sets it)
//
// Steps:
//   protected   files that define the proof only change with `Protected-Change-By: orchestrator`
//   ledger      ledger/LEDGER.jsonl only grows
//   specs       openspec validation
//   tests-req   every code change ships tests, and tests are never skipped
//   verify      fmt, lint, Rust tests, Xcode unit + UI tests (whatever exists; see tools/verify.mjs)
// Prints a one-line summary to quote in the ledger's "verification" field.
import fs from 'node:fs';
import { execSync } from 'node:child_process';

const args = process.argv.slice(2);
const base = args.includes('--base') ? args[args.indexOf('--base') + 1] : 'origin/main';
const final = args.includes('--final');
const full = args.includes('--full') || process.env.GATE_FULL === '1';
const sh = (cmd) => execSync(cmd, { stdio: ['ignore', 'pipe', 'pipe'] }).toString();

// Files that define the proof itself.
const PROTECTED = [
  /^tools\/(gate|check-ledger|check-spec|ledger|verify)\.mjs$/,
  /^\.githooks\//,
  /^\.github\/workflows\//,
  /^\.swiftlint\.yml$/,
  /^(rustfmt|clippy)\.toml$/,
  /^rust-toolchain\.toml$/,
];
const CODE =
  /^(app\/|crates\/|web\/|scripts\/|package(-lock)?\.json$|Cargo\.(toml|lock)$|rust-toolchain\.toml$)/;

function rangeCommits() {
  try {
    return sh(`git log --format=%H ${base}..HEAD`).trim().split('\n').filter(Boolean);
  } catch {
    return [];
  }
}
function changedFiles() {
  try {
    return sh(`git diff --name-only ${base}...HEAD`).trim().split('\n').filter(Boolean);
  } catch {
    return [];
  }
}

function checkProtected() {
  for (const sha of rangeCommits()) {
    const files = sh(`git show --name-only --format= ${sha}`).split('\n').filter(Boolean);
    const hit = files.filter((f) => PROTECTED.some((re) => re.test(f)));
    if (files.includes('package.json')) {
      // npm scripts define what "verify" means; dependency changes are fine.
      const scripts = (ref) => {
        try {
          return JSON.stringify(JSON.parse(sh(`git show ${ref}:package.json`)).scripts ?? {});
        } catch {
          return '{}';
        }
      };
      if (scripts(`${sha}^`) !== scripts(sha)) hit.push('package.json (scripts)');
    }
    if (hit.length === 0) continue;
    const body = sh(`git show -s --format=%B ${sha}`);
    if (!/^Protected-Change-By: orchestrator$/m.test(body)) {
      throw new Error(
        `commit ${sha.slice(0, 7)} changes protected files without approval: ${hit.join(', ')}`,
      );
    }
  }
}

// Swift tests live in app/<Target>Tests/ and app/<Target>UITests/; Rust integration tests in crates/<name>/tests/.
const isTestFile = (f) => /^app\/[^/]*Tests\//.test(f) || /^crates\/[^/]+\/tests\//.test(f);
const SKIPPED = /XCTSkip|XCTExpectFailure|#\[ignore\]|\.disabled\(|\.enabled\(if: false/;

function checkTestsRequired() {
  const files = changedFiles();
  const read = (f) => (fs.existsSync(f) ? fs.readFileSync(f, 'utf8') : '');

  const swiftSrc = files.filter((f) => /^app\/.+\.swift$/.test(f) && !isTestFile(f) && fs.existsSync(f));
  const swiftTests = files.filter((f) => /^app\/[^/]*Tests\/.+\.swift$/.test(f) && fs.existsSync(f));
  if (swiftSrc.length > 0 && swiftTests.length === 0) {
    throw new Error(
      `app/ changed (${swiftSrc.slice(0, 5).join(', ')}${swiftSrc.length > 5 ? ', …' : ''}) but no app/*Tests/ file changed`,
    );
  }

  const rustSrc = files.filter((f) => /^crates\/[^/]+\/src\/.+\.rs$/.test(f) && fs.existsSync(f));
  const rustTests = files.filter(
    (f) =>
      fs.existsSync(f) &&
      (/^crates\/[^/]+\/tests\/.+\.rs$/.test(f) ||
        (/^crates\/[^/]+\/src\/.+\.rs$/.test(f) && /#\[test\]/.test(read(f)))),
  );
  if (rustSrc.length > 0 && rustTests.length === 0) {
    throw new Error(
      `crates/ changed (${rustSrc.slice(0, 5).join(', ')}) but no Rust test was added or changed (#[test] or crates/*/tests/)`,
    );
  }

  for (const f of swiftTests) {
    if (!/func test|@Test\b/.test(read(f))) throw new Error(`${f} contains no tests`);
  }
  for (const f of files.filter((x) => /\.(swift|rs)$/.test(x) && fs.existsSync(x))) {
    const hit = SKIPPED.exec(read(f));
    if (hit && (isTestFile(f) || /#\[ignore\]/.test(hit[0]))) {
      throw new Error(`${f} skips or disables a test (${hit[0]}); fix the test instead`);
    }
  }
}

const codeChanged = () => {
  const files = changedFiles();
  return files.length === 0 || files.some((f) => CODE.test(f));
};

// A pass is remembered in the git common dir (shared by worktrees). A later run skips `verify` when
// the stamped commit is an ancestor of HEAD and only non-code files changed since.
const stampFile = () => `${sh('git rev-parse --git-common-dir').trim()}/ankicorn-gate-stamp.json`;
function stampCovers() {
  if (full) return null;
  try {
    const stamp = JSON.parse(fs.readFileSync(stampFile(), 'utf8'));
    sh(`git merge-base --is-ancestor ${stamp.sha} HEAD`);
    const since = sh(`git diff --name-only ${stamp.sha} HEAD`).trim().split('\n').filter(Boolean);
    return since.some((f) => CODE.test(f)) ? null : stamp.sha.slice(0, 7);
  } catch {
    return null;
  }
}

function verify() {
  if (!codeChanged()) return 'skip';
  const covered = stampCovers();
  if (covered) return `stamp:${covered}`;
  execSync('npm run verify', { stdio: 'inherit' });
  fs.writeFileSync(stampFile(), JSON.stringify({ sha: sh('git rev-parse HEAD').trim() }));
  return 'ok';
}

const steps = [
  ['protected', checkProtected],
  ['ledger', `node tools/check-ledger.mjs ${base}${final ? ' --final' : ''}`],
  ['specs', 'node tools/check-spec.mjs'],
  ['tests-req', checkTestsRequired],
  ['verify', verify],
];

const results = [];
for (const [name, step] of steps) {
  const started = Date.now();
  try {
    const out = typeof step === 'function' ? step() : execSync(step, { stdio: 'inherit' });
    const secs = Math.round((Date.now() - started) / 1000);
    const note =
      out === 'skip'
        ? 'skip(no code changes)'
        : typeof out === 'string' && out.startsWith('stamp:')
          ? `skip(already passed @${out.slice(6)})`
          : `pass(${secs}s)`;
    results.push(`${name}:${note}`);
  } catch (err) {
    if (typeof step === 'function' && err?.message) console.error(err.message);
    results.push(`${name}:FAIL`);
    console.error(`\nGATE FAILED at "${name}"`);
    console.error(`summary: ${results.join(' ')}`);
    process.exit(1);
  }
}
const head = sh('git rev-parse --short HEAD').trim();
console.log(`\nGATE PASSED @${head}: ${results.join(' ')}`);
