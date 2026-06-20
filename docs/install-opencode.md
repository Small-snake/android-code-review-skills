# Install in OpenCode

OpenCode can use these skills through project skills.

## Project setup

Copy the skills into your Android project's OpenCode skills directory:

```bash
mkdir -p .opencode/skills
cp -R skills/android-diff-reviewer .opencode/skills/
cp -R skills/android-compose-diff-reviewer .opencode/skills/
cp -R skills/android-coroutines-diff-reviewer .opencode/skills/
```

Then ask OpenCode to load the entry skill:

```text
use skill tool to load android-diff-reviewer
```

## Prompt

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## Manual fallback

Paste the entry skill into the chat and provide the local diff commands:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```
