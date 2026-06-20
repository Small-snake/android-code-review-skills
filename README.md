# Android Code Review Skills

Cross-agent, diff-first Android code review skills for AI coding agents.

![Android](https://img.shields.io/badge/Android-code%20review-3DDC84)
![Skills](https://img.shields.io/badge/AI%20agents-skills-111827)
![License](https://img.shields.io/badge/license-MIT-blue)

Give Codex, Claude Code, Cursor, Gemini CLI, OpenCode, and other coding agents a practical Android review workflow. The default behavior is intentionally narrow: review the developer's local diff, not the entire repository.

Use it when you want an agent to catch Android-specific issues before commit:

- Compose lifecycle and state bugs.
- Coroutine, Flow, dispatcher, and cancellation mistakes.
- Main-thread blocking and ANR risk.
- Missing verification for changed Android behavior.
- Review output that separates commands actually run from recommended checks.

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

## Agent support

These skills are plain Markdown first. Platform-specific files are thin adapters, similar to how Superpowers keeps reusable skills under `skills/` and adds harness-specific entry points around them.

| Agent | Support | Install |
| --- | --- | --- |
| Codex | Native skills folder | [docs/install-codex.md](docs/install-codex.md) |
| Claude Code | Skills folder or `CLAUDE.md` project instructions | [docs/install-claude-code.md](docs/install-claude-code.md) |
| Cursor | `.cursor/rules` project rule | [docs/install-cursor.md](docs/install-cursor.md) |
| Gemini CLI | `GEMINI.md` project instructions | [docs/install-gemini-cli.md](docs/install-gemini-cli.md) |
| OpenCode | Project skills directory | [docs/install-opencode.md](docs/install-opencode.md) |
| Other agents | `AGENTS.md` or pasted `SKILL.md` context | [docs/agent-support.md](docs/agent-support.md) |

## 30-second demo

Prompt:

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

Example finding:

```text
Scope: local uncommitted Android diff only.

[P1] app/src/main/java/com/example/calls/CallLogScreen.kt:14
The screen collects uiState with collectAsState(), so upstream Flow work can remain active when the lifecycle is stopped.

Use collectAsStateWithLifecycle() and verify with a lifecycle recreation or navigation-away test.

[P1] app/src/main/java/com/example/calls/CallRepository.kt:21
GlobalScope.launch creates work that can outlive the caller and hide failures.

Move the refresh into an owned scope, keep the suspend API cancellable, and add a cancellation test.
```

Try the full example:

- [Sample diff](examples/sample-diff-review/sample-diff.md)
- [Sample review result](examples/sample-diff-review/review.md)

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

Install for your agent:

- [Codex](docs/install-codex.md)
- [Claude Code](docs/install-claude-code.md)
- [Cursor](docs/install-cursor.md)
- [Gemini CLI](docs/install-gemini-cli.md)
- [OpenCode](docs/install-opencode.md)
- [Agent support matrix](docs/agent-support.md)

## Share

Want to introduce the project publicly? Start from [docs/launch-post.md](docs/launch-post.md).

## Recommended First Use

Start with the entry skill:

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## License

MIT
