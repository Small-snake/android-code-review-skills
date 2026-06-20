# Agent Support

Cross-agent support works by keeping the real instructions in `skills/*/SKILL.md` and adding thin platform-specific entry points around them.

| Agent | Support level | How it works |
| --- | --- | --- |
| Codex | Native | Copy `skills/*` into the Codex skills directory and ask for `android-diff-reviewer`. |
| Claude Code | Native or project instructions | Copy `skills/*` into `~/.claude/skills`, or use `CLAUDE.md` in an Android project. |
| Cursor | Project rule | Copy `.cursor/rules/android-code-review-skills.mdc` and the `skills/` folder into the target project. |
| Gemini CLI | Project instructions | Copy `GEMINI.md` and the `skills/` folder into the target project. |
| OpenCode | Project skills directory | Copy the skill folders into `.opencode/skills/` and use OpenCode's skill loading. |
| Other coding agents | Prompt context | Use `AGENTS.md`, or paste `skills/android-diff-reviewer/SKILL.md` into the agent and ask for a local diff review. |

## Shared prompt

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## Shared commands

Every integration should inspect:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

The review must stay scoped to the local Android diff by default. Nearby context is allowed only when a changed hunk cannot be understood on its own.
