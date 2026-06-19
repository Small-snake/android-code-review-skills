# Install in Codex

This repository is a set of portable Markdown skills. Install the entry skill first, then add the Compose and coroutine companion skills if you want deeper Android review coverage.

## 1. Choose your Codex skills directory

If `CODEX_HOME` is set, use:

```bash
$CODEX_HOME/skills
```

Otherwise use the default user skills directory:

```bash
~/.codex/skills
```

## 2. Copy the skills

From this repository:

```bash
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills"
cp -R skills/android-diff-reviewer "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R skills/android-compose-diff-reviewer "${CODEX_HOME:-$HOME/.codex}/skills/"
cp -R skills/android-coroutines-diff-reviewer "${CODEX_HOME:-$HOME/.codex}/skills/"
```

## 3. Ask Codex to use the entry skill

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## 4. Expected behavior

Codex should inspect:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

It should review only the local Android diff, list findings by severity, separate commands actually run from recommended verification, and avoid scanning the whole repository by default.

## Agent-neutral use

If your tool does not support skill folders, paste `skills/android-diff-reviewer/SKILL.md` into the agent context and use the same prompt.
