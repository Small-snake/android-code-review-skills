# Android Code Review Skills

[中文](README.md)

Cross-agent, diff-first Android code review skills for AI coding agents.

![Android](https://img.shields.io/badge/Android-code%20review-3DDC84)
![Skills](https://img.shields.io/badge/AI%20agents-skills-111827)
![License](https://img.shields.io/badge/license-MIT-blue)

## Why this exists

Many AI code review prompts drift into broad repository commentary: they scan unrelated files, comment on style, and miss the Android-specific problems that tend to break production behavior. This project keeps review scoped to the developer's local diff, including staged and unstaged changes.

It focuses on Android-specific risks:

- Compose lifecycle, state modeling, and side-effect issues.
- Coroutine, Flow, dispatcher, and cancellation mistakes.
- Main-thread blocking, ANR risk, stale state, and race conditions.
- Missing verification commands or regression tests for the changed behavior.
- Clear separation between commands actually run and recommended verification.

## Quick Start

Ask your coding agent:

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

The entry skill asks the agent to inspect:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

By default, it reviews only staged and unstaged Android changes. It reads nearby context only when a changed hunk cannot be understood by itself.

## Agent support

These skills are plain Markdown first. Platform-specific files are thin adapters; the real instructions live in `skills/*/SKILL.md`.

| Agent | Support | Install |
| --- | --- | --- |
| Codex | Native skills folder | [docs/install-codex.md](docs/install-codex.md) |
| Claude Code | Skills folder or `CLAUDE.md` | [docs/install-claude-code.md](docs/install-claude-code.md) |
| Cursor | `.cursor/rules` project rule | [docs/install-cursor.md](docs/install-cursor.md) |
| Gemini CLI | `GEMINI.md` project instructions | [docs/install-gemini-cli.md](docs/install-gemini-cli.md) |
| OpenCode | Project skills directory | [docs/install-opencode.md](docs/install-opencode.md) |
| Other agents | `AGENTS.md` or pasted `SKILL.md` | [docs/agent-support.md](docs/agent-support.md) |

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

Commands run:
- git status --short
- git diff --stat
- git diff

Recommended verification (not run):
- ./gradlew test
- ./gradlew :app:lintDebug
- ./gradlew connectedDebugAndroidTest
```

## What these skills check

- Diff scope and changed-file classification.
- Compose state, recomposition, lifecycle collection, and side effects.
- Coroutine scope ownership, cancellation, dispatcher usage, and Flow behavior.
- Android-specific failure modes such as leaks, stale UI state, ANR risk, race conditions, and missing regression tests.
- Verification commands that should be run after the review.

## What these skills do not do

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

## Recommended first use

Start with the entry skill. Do not ask the agent to scan the whole repository first:

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## Share

Want to introduce the project publicly? Start from:

- [docs/launch-post.md](docs/launch-post.md)

## License

MIT
