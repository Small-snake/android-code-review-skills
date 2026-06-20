# Install in Claude Code

Claude Code can use these skills either as installed skill folders or as project instructions.

## Option 1. Install as skills

From this repository:

```bash
mkdir -p "$HOME/.claude/skills"
cp -R skills/android-diff-reviewer "$HOME/.claude/skills/"
cp -R skills/android-compose-diff-reviewer "$HOME/.claude/skills/"
cp -R skills/android-coroutines-diff-reviewer "$HOME/.claude/skills/"
```

Then ask:

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## Option 2. Use project instructions

Copy these into your Android project:

```text
CLAUDE.md
skills/android-diff-reviewer/
skills/android-compose-diff-reviewer/
skills/android-coroutines-diff-reviewer/
```

Claude Code should read `CLAUDE.md`, then use `skills/android-diff-reviewer/SKILL.md` as the entry point when you ask for Android review.
