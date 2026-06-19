# Supported Agents

These skills are plain Markdown workflows. They are packaged as `SKILL.md` files so Codex-style agents can consume them directly, but they are also useful in generic coding agents.

## Codex-Style Skill Use

Copy a skill folder into the agent's skills directory and ask:

```text
Use android-diff-reviewer to review my local Android changes.
```

## Generic Agent Use

Paste the content of the relevant `SKILL.md` into the agent, then ask it to review the current local diff.

## Cursor or IDE Chat Use

Attach or paste the `SKILL.md`, then provide the output of:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

Ask the agent to stay scoped to the diff unless it needs nearby context.

## CI Comment Use

This first release is designed for human-triggered agent review. CI integration can be added later by packaging the diff and changed-file metadata into a prompt.
