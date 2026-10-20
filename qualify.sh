#!/usr/bin/env bash
set -euo pipefail
payload="$PWD"
base=1b58cb9a1b4f4353e1add63c8506db4d890962e8
free_kb=$(df -Pk . | awk 'NR==2 {print $4}')
(( free_kb > 11000000 )) || { echo 'Insufficient initial disk'; exit 1; }
free -h
df -h .
# No upstream workflows are executed; only source at the exact public commit is fetched.
mkdir source
cd source
git init -q
git remote add origin https://github.com/openclaw/openclaw.git
git fetch --depth=1 origin "$base"
git checkout --detach FETCH_HEAD
test "$(git rev-parse HEAD)" = "$base"
git apply --check "$payload/repair.patch"
git apply "$payload/repair.patch"
sha256sum "$payload/repair.patch"
npm install --global pnpm@12.9.0
pnpm install --frozen-lockfile
# New regressions against byte-exact unpatched production code.
git checkout "$base" -- src/auto-reply/command-auth.ts src/channels/message-access/participant-input.ts
set +e
pnpm test src/channels/message-access/operator-authority.test.ts -t 'preserves configured ownership independently of linked operator role revocation' > "$RUNNER_TEMP/baseline-red.log" 2>&1
red=$?
set -e
cat "$RUNNER_TEMP/baseline-red.log"
test "$red" -eq 1
grep -q 'preserves configured ownership independently of linked operator role revocation' "$RUNNER_TEMP/baseline-red.log"
grep -Eq 'AssertionError|expected .* to (deeply )?equal' "$RUNNER_TEMP/baseline-red.log"
! grep -Eiq 'heap out of memory|allocation failed|SIGKILL|Killed|no test files found' "$RUNNER_TEMP/baseline-red.log"
git apply --include=src/auto-reply/command-auth.ts --include=src/channels/message-access/participant-input.ts "$payload/repair.patch"
# Create a privacy-neutral candidate commit; no private historical commit metadata.
git config user.name 'OpenClaw Repair Build'
git config user.email 'repair-build@users.noreply.github.com'
git add src
git commit -m 'fix: retain independently current linked authority for configured owners'
candidate=$(git rev-parse HEAD)
echo "Candidate: $candidate"
pnpm test src/channels/message-access/operator-authority.test.ts src/channels/message-access/participant-input.test.ts src/channels/message-access/message-access.test.ts src/channels/message-access/identifier-authentication.test.ts src/channels/message-access/runtime-identity.test.ts src/channels/message-access/child-session-publication.test.ts src/auto-reply/command-auth.owner-default.test.ts src/auto-reply/reply/route-reply.recovery-owner.test.ts src/auto-reply/reply/get-reply.binding-route-owner.test.ts src/auto-reply/reply/get-reply.explicit-owner.test.ts src/gateway/server-plugin-in-process-dispatch.authorization.test.ts src/gateway/server-plugin-in-process-dispatch.scopes.test.ts src/gateway/server-plugin-in-process-dispatch.continuation.test.ts
pnpm tsgo:core
changed=(src/auto-reply/command-auth.ts src/channels/message-access/operator-assignment.test-support.ts src/channels/message-access/operator-authority.test.ts src/channels/message-access/participant-input.ts)
node scripts/run-oxlint.mjs --type-aware --tsconfig config/tsconfig/oxlint.core.json "${changed[@]}"
pnpm exec oxfmt --check "${changed[@]}"
pnpm build:package
mkdir -p "$RUNNER_TEMP/candidate"
node scripts/package-openclaw-for-docker.mjs --skip-build --allow-unreleased-changelog --output-dir "$RUNNER_TEMP/candidate" --output-name openclaw-configured-owner-repair.tgz
artifact="$RUNNER_TEMP/candidate/openclaw-configured-owner-repair.tgz"
sha256sum "$artifact" | tee "$RUNNER_TEMP/candidate/SHA256SUMS"
tar -tzf "$artifact" > "$RUNNER_TEMP/inventory.txt"
! grep -Eq '(^/|(^|/)\.\.(/|$)|(^|/)\.git/|(^|/)\.env$)' "$RUNNER_TEMP/inventory.txt"
grep -q 'package/LICENSE' "$RUNNER_TEMP/inventory.txt"
# Private disposable state and no connection to a live Gateway.
smoke=$(mktemp -d)
mkdir -p "$smoke/home" "$smoke/state" "$smoke/prefix"
export HOME="$smoke/home" OPENCLAW_STATE_DIR="$smoke/state" OPENCLAW_CONFIG_PATH="$smoke/config.json"
npm install --prefix "$smoke/prefix" "$artifact" --no-audit --no-fund
node "$smoke/prefix/node_modules/openclaw/openclaw.mjs" --version
node "$smoke/prefix/node_modules/openclaw/openclaw.mjs" --help > "$RUNNER_TEMP/cli-help.txt"
node --input-type=module - "$smoke/prefix/node_modules/openclaw/dist/build-info.json" "$candidate" <<'NODE'
import fs from 'node:fs';
const info = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
console.log(JSON.stringify(info));
if (!JSON.stringify(info).includes(process.argv[3])) throw new Error('Build commit does not match candidate');
NODE
{
  echo '## Qualification passed'
  echo "Upstream: $base"
  echo "Candidate: $candidate"
  echo 'Baseline failed by assertion; patched focused boundaries passed; core typecheck, changed-file type-aware lint, full package build, canonical package and isolated install/CLI smoke passed.'
  cat "$RUNNER_TEMP/candidate/SHA256SUMS"
  echo 'Package intentionally not uploaded: free artifact storage entitlement is unverified. No activation performed.'
} >> "$GITHUB_STEP_SUMMARY"
