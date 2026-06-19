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

check_contains() {
  local file_or_dir="$1"
  local pattern="$2"
  local label="$3"
  if ! rg -n "$pattern" "$file_or_dir" >/dev/null; then
    echo "Missing required content: $label" >&2
    exit 1
  fi
}

placeholder_pattern="T""BD|TO""DO|implement ""later|fill in ""details"
if rg -n "$placeholder_pattern" "$ROOT"; then
  echo "Placeholder text found." >&2
  exit 1
fi

check_contains "$ROOT/README.md" "local diff" "README local diff wording"
check_contains "$ROOT/README.md" "git diff" "README git diff wording"
check_contains "$ROOT/README.md" "git diff --cached" "README staged diff wording"
check_contains "$ROOT" "Do not scan the whole repository|Do not review the whole repository|not the default" "whole repository is not default"
check_contains "$ROOT/docs/severity-model.md" "P0" "severity model P0"
check_contains "$ROOT/docs/severity-model.md" "P1" "severity model P1"
check_contains "$ROOT/docs/severity-model.md" "P2" "severity model P2"
check_contains "$ROOT/docs/severity-model.md" "P3" "severity model P3"
check_contains "$ROOT/skills/android-compose-diff-reviewer" "collectAsStateWithLifecycle" "Compose lifecycle-aware state collection"
check_contains "$ROOT/skills/android-coroutines-diff-reviewer" "GlobalScope" "coroutines GlobalScope guidance"
check_contains "$ROOT/skills/android-coroutines-diff-reviewer" "withContext" "coroutines withContext guidance"
check_contains "$ROOT/skills/android-coroutines-diff-reviewer" "flowOn" "coroutines flowOn guidance"
check_contains "$ROOT/skills/android-coroutines-diff-reviewer" "cancellation" "coroutines cancellation guidance"

echo "Content verification passed."
