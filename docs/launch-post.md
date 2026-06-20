# Launch Post

## Short version

I built `android-code-review-skills`: cross-agent, diff-first Android code review skills for AI coding agents.

Most agent reviews drift into whole-repo commentary. This project keeps review scoped to staged and unstaged Android changes, then checks for the bugs Android developers actually care about: Compose lifecycle mistakes, impossible UI state, coroutine ownership, Flow semantics, dispatcher misuse, ANR risk, and missing verification.

It works as portable Markdown skills with setup notes for Codex, Claude Code, Cursor, Gemini CLI, OpenCode, and generic coding agents.

Repo: https://github.com/Small-snake/android-code-review-skills

## Longer version

I often want an AI coding agent to review Android code before commit, but generic review prompts are too broad. They scan unrelated files, comment on style, and miss the Android-specific parts that tend to break production behavior.

So I built `android-code-review-skills`.

The entry skill tells the agent to review only the local diff:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

Then it applies Android-focused checks:

- Compose lifecycle-aware collection and state ownership.
- Coroutine scope ownership, cancellation, dispatcher usage, and Flow behavior.
- Main-thread blocking and ANR risk.
- Test gaps for changed lifecycle, state, persistence, parsing, or concurrency behavior.
- Clear separation between commands actually run and recommended verification.

It is small on purpose. You can use it in Codex, Claude Code, Cursor, Gemini CLI, OpenCode, or any coding agent that accepts Markdown instructions.

Repo: https://github.com/Small-snake/android-code-review-skills

Feedback from Android developers is welcome.
