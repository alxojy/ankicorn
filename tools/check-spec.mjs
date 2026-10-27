// Mechanical proof for spec work: every spec and change must pass OpenSpec's strict validation.
//
// node tools/check-spec.mjs
//
// With no specs or changes yet there is nothing to validate, so it passes.
import fs from 'node:fs';
import { execSync } from 'node:child_process';

const entries = (dir) =>
  fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => !f.startsWith('.') && f !== 'archive') : [];

if (entries('openspec/specs').length === 0 && entries('openspec/changes').length === 0) {
  console.log('spec check ok (no specs or changes yet)');
  process.exit(0);
}
try {
  execSync('npx --no-install openspec validate --all --strict', { stdio: 'inherit' });
} catch {
  console.error('spec check failed: openspec validate --all --strict');
  process.exit(1);
}
console.log('spec check ok');
