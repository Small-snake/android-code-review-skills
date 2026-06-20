# Install in Cursor

Cursor can use these skills through project rules.

## Project setup

Copy these into your Android project:

```text
.cursor/rules/android-code-review-skills.mdc
skills/android-diff-reviewer/
skills/android-compose-diff-reviewer/
skills/android-coroutines-diff-reviewer/
```

The rule tells Cursor to use `skills/android-diff-reviewer/SKILL.md` as the entry point when you ask for Android code review.

## Prompt

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## Manual fallback

If rules are not loaded in your Cursor setup, attach or paste `skills/android-diff-reviewer/SKILL.md`, then provide:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```
