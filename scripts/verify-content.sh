#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "README.md"
  "README.en.md"
  "LICENSE"
  "docs/review-scope.md"
  "docs/severity-model.md"
  "docs/install-codex.md"
  "docs/install-claude-code.md"
  "docs/install-cursor.md"
  "docs/install-gemini-cli.md"
  "docs/install-opencode.md"
  "docs/agent-support.md"
  "docs/android-studio-plugin-development.md"
  "docs/android-studio-plugin-development.zh-CN.md"
  "docs/supported-agents.md"
  ".opencode/INSTALL.md"
  "AGENTS.md"
  "CLAUDE.md"
  "GEMINI.md"
  ".cursor/rules/android-code-review-skills.mdc"
  "examples/sample-diff-review/sample-diff.md"
  "examples/sample-diff-review/review.md"
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

check_contains "$ROOT/README.md" "本地 diff" "README Chinese local diff wording"
check_contains "$ROOT/README.md" "安装" "README Chinese installation wording"
check_contains "$ROOT/README.md" "English" "README English version link"
check_contains "$ROOT/README.en.md" "local diff" "English README local diff wording"
check_contains "$ROOT/README.en.md" "中文" "English README Chinese version link"
check_contains "$ROOT/README.en.md" "Installation" "English README installation wording"
check_contains "$ROOT/README.en.md" "Agent support" "English README agent support section"
check_contains "$ROOT/README.md" "git diff" "README git diff wording"
check_contains "$ROOT/README.md" "git diff --cached" "README staged diff wording"
check_contains "$ROOT/README.md" "30 秒示例" "README fast demo section"
check_contains "$ROOT/README.md" "docs/install-codex.md" "README Codex install link"
check_contains "$ROOT/README.md" "Agent 支持" "README agent support section"
check_contains "$ROOT/README.md" "Claude Code" "README Claude Code support"
check_contains "$ROOT/README.md" "Cursor" "README Cursor support"
check_contains "$ROOT/README.md" "Gemini CLI" "README Gemini CLI support"
check_contains "$ROOT/README.md" "OpenCode" "README OpenCode support"
check_contains "$ROOT/README.md" "sample-diff-review" "README sample diff review link"
check_contains "$ROOT" "Do not scan the whole repository|Do not review the whole repository|not the default" "whole repository is not default"
check_contains "$ROOT/docs/agent-support.md" "Cross-agent" "agent support positioning"
check_contains "$ROOT/docs/agent-support.md" "Codex" "agent support Codex row"
check_contains "$ROOT/docs/agent-support.md" "Claude Code" "agent support Claude row"
check_contains "$ROOT/docs/agent-support.md" "Cursor" "agent support Cursor row"
check_contains "$ROOT/docs/agent-support.md" "Gemini CLI" "agent support Gemini row"
check_contains "$ROOT/docs/agent-support.md" "OpenCode" "agent support OpenCode row"
check_contains "$ROOT/docs/android-studio-plugin-development.md" "Android Studio Plugin" "Android Studio plugin development doc title"
check_contains "$ROOT/docs/android-studio-plugin-development.md" "Claude Code" "plugin doc Claude Code integration"
check_contains "$ROOT/docs/android-studio-plugin-development.md" "review.json" "plugin doc review JSON protocol"
check_contains "$ROOT/docs/android-studio-plugin-development.md" "Tool Window" "plugin doc Tool Window UI"
check_contains "$ROOT/docs/android-studio-plugin-development.md" "Diff Viewer" "plugin doc Diff Viewer plan"
check_contains "$ROOT/docs/android-studio-plugin-development.md" "Built-in Skill" "plugin doc built-in skill mode"
check_contains "$ROOT/docs/android-studio-plugin-development.zh-CN.md" "Android Studio 插件开发计划" "Chinese Android Studio plugin doc title"
check_contains "$ROOT/docs/android-studio-plugin-development.zh-CN.md" "Claude Code" "Chinese plugin doc Claude Code integration"
check_contains "$ROOT/docs/android-studio-plugin-development.zh-CN.md" "review.json" "Chinese plugin doc review JSON protocol"
check_contains "$ROOT/docs/android-studio-plugin-development.zh-CN.md" "Tool Window" "Chinese plugin doc Tool Window UI"
check_contains "$ROOT/docs/android-studio-plugin-development.zh-CN.md" "Diff Viewer" "Chinese plugin doc Diff Viewer plan"
check_contains "$ROOT/docs/android-studio-plugin-development.zh-CN.md" "内置 Skill" "Chinese plugin doc built-in skill mode"
check_contains "$ROOT/docs/install-codex.md" "android-diff-reviewer" "Codex install entry skill"
check_contains "$ROOT/docs/install-codex.md" "CODEX_HOME" "Codex install environment wording"
check_contains "$ROOT/docs/install-claude-code.md" "CLAUDE.md" "Claude Code install instructions"
check_contains "$ROOT/docs/install-cursor.md" ".cursor/rules" "Cursor rules instructions"
check_contains "$ROOT/docs/install-gemini-cli.md" "GEMINI.md" "Gemini CLI install instructions"
check_contains "$ROOT/docs/install-opencode.md" ".opencode/skills" "OpenCode install instructions"
check_contains "$ROOT/.opencode/INSTALL.md" ".opencode/skills" "OpenCode install helper"
check_contains "$ROOT/CLAUDE.md" "android-diff-reviewer" "Claude root adapter entry skill"
check_contains "$ROOT/GEMINI.md" "android-diff-reviewer" "Gemini root adapter entry skill"
check_contains "$ROOT/AGENTS.md" "android-diff-reviewer" "Generic agent adapter entry skill"
check_contains "$ROOT/.cursor/rules/android-code-review-skills.mdc" "android-diff-reviewer" "Cursor rule entry skill"
check_contains "$ROOT/examples/sample-diff-review/sample-diff.md" "collectAsState" "sample diff Compose lifecycle issue"
check_contains "$ROOT/examples/sample-diff-review/sample-diff.md" "GlobalScope" "sample diff coroutine issue"
check_contains "$ROOT/examples/sample-diff-review/review.md" "Commands run" "sample review executed commands section"
check_contains "$ROOT/examples/sample-diff-review/review.md" "Recommended verification" "sample review recommended verification section"
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
