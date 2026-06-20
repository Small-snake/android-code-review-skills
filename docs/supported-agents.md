# Supported Agents

See [agent-support.md](agent-support.md) for the current cross-agent support matrix.

These skills are plain Markdown workflows. They are packaged as `SKILL.md` files so native skill systems can consume them directly, but they also work in agents that accept project instructions or pasted context.

The core rule is the same everywhere:

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

If an agent does not support skill folders, paste `skills/android-diff-reviewer/SKILL.md` into context and provide:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```
