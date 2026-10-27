// Runs every check that applies to what exists in the repo, serially (the dev machine has 8 GB of RAM:
// never run Rust and Xcode builds at the same time, and keep cargo at -j2).
//
// node tools/verify.mjs           full: fmt, clippy, Rust tests, SwiftLint, Xcode unit + UI tests
// node tools/verify.mjs --quick   pre-commit: formatting only
//
// Environment:
//   ANKICORN_SCHEME  Xcode scheme (default Cornhub)
//   ANKICORN_SIM     simulator name (default "iPhone 17")
import fs from 'node:fs';
import { execSync } from 'node:child_process';

const quick = process.argv.includes('--quick');
const scheme = process.env.ANKICORN_SCHEME ?? 'Cornhub';
const sim = process.env.ANKICORN_SIM ?? 'iPhone 17';
const has = (cmd) => {
  try {
    execSync(`command -v ${cmd}`, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
};
const run = (label, cmd) => {
  console.log(`\n== ${label}\n$ ${cmd}`);
  execSync(cmd, { stdio: 'inherit', env: { ...process.env, CARGO_BUILD_JOBS: '2' } });
};

const hasRust = fs.existsSync('Cargo.toml');
const project = fs.existsSync('app') && fs.readdirSync('app').find((f) => f.endsWith('.xcodeproj'));
const ran = [];

if (hasRust) {
  run('rustfmt', 'cargo fmt --all --check');
  ran.push('fmt');
}
if (quick) {
  console.log(ran.length ? `verify --quick ok (${ran.join(', ')})` : 'verify --quick ok (nothing to check)');
  process.exit(0);
}
// Demo mode (default): no tests, just prove the app compiles. ANKICORN_FULL=1 runs everything.
if (!process.env.ANKICORN_FULL) {
  if (project) {
    run(
      'xcode build',
      `xcodebuild build -project app/${project} -scheme ${scheme} -destination 'platform=iOS Simulator,name=${sim}' -jobs 2 -quiet`,
    );
    ran.push('xcode-build');
  }
  console.log(`verify ok, demo mode (${ran.join(', ') || 'nothing'}); ANKICORN_FULL=1 for tests`);
  process.exit(0);
}
if (hasRust) {
  run('clippy', 'cargo clippy --workspace --all-targets -j 2 -- -D warnings');
  run('rust tests', 'cargo test --workspace -j 2');
  ran.push('clippy', 'cargo-test');
}
if (project) {
  if (has('swiftlint')) {
    run('swiftlint', 'swiftlint --strict');
    ran.push('swiftlint');
  }
  // Serial, one simulator, no parallel testing: keeps memory in check. UI tests attach screenshots
  // (XCTAttachment) to the result bundle; the implementing agent reviews them against PLAN.md.
  const bundle = 'test-results/Cornhub.xcresult';
  fs.rmSync(bundle, { recursive: true, force: true });
  run(
    'xcode tests',
    `xcodebuild test -project app/${project} -scheme ${scheme} -destination 'platform=iOS Simulator,name=${sim}' ` +
      `-parallel-testing-enabled NO -jobs 2 -resultBundlePath ${bundle}`,
  );
  ran.push('xcode-tests');
}
console.log(ran.length ? `verify ok (${ran.join(', ')})` : 'verify ok (no code yet)');
