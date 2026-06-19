#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "README.md"
  "LICENSE"
  "docs/review-scope.md"
  "docs/severity-model.md"
  "docs/supported-agents.md"
  "skills/android-diff-reviewer/SKILL.md"
  "skills/android-diff-reviewer/examples/review-output.md"
  "skills/android-compose-diff-reviewer/SKILL.md"
  "skills/android-compose-diff-reviewer/examples/lifecycle-flow-before.kt"
  "skills/android-compose-diff-reviewer/examples/lifecycle-flow-after.kt"
  "skills/android-coroutines-diff-reviewer/SKILL.md"
  "skills/android-coroutines-diff-reviewer/examples/dispatcher-before.kt"
  "skills/android-coroutines-diff-reviewer/examples/dispatcher-after.kt"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$ROOT/$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
done

placeholder_pattern="T""BD|TO""DO|implement ""later|fill in ""details"
if rg -n "$placeholder_pattern" "$ROOT"; then
  echo "Placeholder text found." >&2
  exit 1
fi

rg -n "local diff|git diff|git diff --cached" "$ROOT/README.md" >/dev/null
rg -n "Do not scan the whole repository|Do not review the whole repository|not the default" "$ROOT" >/dev/null
rg -n "P0|P1|P2|P3" "$ROOT/docs/severity-model.md" >/dev/null
rg -n "collectAsStateWithLifecycle" "$ROOT/skills/android-compose-diff-reviewer" >/dev/null
rg -n "GlobalScope|withContext|flowOn|cancellation" "$ROOT/skills/android-coroutines-diff-reviewer" >/dev/null

echo "Content verification passed."
