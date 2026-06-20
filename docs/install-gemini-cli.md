# Install in Gemini CLI

Gemini CLI can use these skills through project instructions.

## Project setup

Copy these into your Android project:

```text
GEMINI.md
skills/android-diff-reviewer/
skills/android-compose-diff-reviewer/
skills/android-coroutines-diff-reviewer/
```

`GEMINI.md` points Gemini at `skills/android-diff-reviewer/SKILL.md` as the entry point.

## Prompt

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## Manual fallback

Paste `skills/android-diff-reviewer/SKILL.md` into the session and ask Gemini to inspect:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```
