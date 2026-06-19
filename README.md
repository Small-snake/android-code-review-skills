# Android Code Review Skills

Diff-first Android code review skills for AI coding agents.

This repository gives Codex, Claude Code, Cursor, Gemini CLI, and other coding agents a practical Android code review workflow. The default behavior is intentionally narrow: review the developer's local diff, not the entire repository.

## Quick Start

Ask your coding agent:

```text
Review my local Android changes using android-diff-reviewer.
```

The entry skill asks the agent to inspect:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

It then reviews only the staged and unstaged Android changes, with minimal surrounding context when a changed hunk cannot be understood by itself.

## Skills

| Skill | Purpose |
| --- | --- |
| `android-diff-reviewer` | Entry point for local Android diff review. Classifies changed files, filters noise, and produces review findings. |
| `android-compose-diff-reviewer` | Reviews Compose UI, lifecycle-aware collection, state modeling, side effects, previews, and UI test gaps. |
| `android-coroutines-diff-reviewer` | Reviews coroutine ownership, cancellation, dispatcher usage, Flow semantics, error handling, and testability. |

## Example Output

```text
Scope: local uncommitted Android diff only.

Changed files:
- app/src/main/java/com/example/calls/CallLogScreen.kt
- app/src/main/java/com/example/calls/CallLogViewModel.kt

Findings:
[P1] app/src/main/java/com/example/calls/CallLogScreen.kt:42
Collecting Flow without lifecycle awareness can keep work active when the screen is stopped.
Use collectAsStateWithLifecycle and verify with a lifecycle recreation test.

[P2] app/src/main/java/com/example/calls/CallLogViewModel.kt:88
The loading/error state can represent impossible combinations.
Consider a sealed UiState and add transition tests for loading, empty, content, and error.

Verification:
- ./gradlew test
- ./gradlew :app:lintDebug
- ./gradlew connectedDebugAndroidTest
```

## What These Skills Check

- Diff scope and changed-file classification.
- Compose state, recomposition, lifecycle collection, and side effects.
- Coroutine scope ownership, cancellation, dispatcher usage, and Flow behavior.
- Android-specific failure modes such as leaks, stale UI state, ANR risk, race conditions, and missing regression tests.
- Verification commands that should be run after the review.

## What These Skills Do Not Do

- They do not scan the whole repository by default.
- They do not replace compilation, lint, unit tests, UI tests, Macrobenchmark, Perfetto, or device validation.
- They do not guarantee correctness.
- They do not review generated files, binary assets, build outputs, or formatting-only churn unless the diff makes them relevant.

## Installation

For Codex-style agents, copy one or more skill folders under your agent's skills directory:

```text
skills/android-diff-reviewer/
skills/android-compose-diff-reviewer/
skills/android-coroutines-diff-reviewer/
```

For tool-neutral use, paste the relevant `SKILL.md` into your coding agent and ask it to follow the workflow.

## Recommended First Use

Start with the entry skill:

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## License

MIT
