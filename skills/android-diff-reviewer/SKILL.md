---
name: android-diff-reviewer
description: Review local staged and unstaged Android changes before commit. Use when the user asks for Android code review, pre-commit review, diff review, or review of local changes.
---

# Android Diff Reviewer

Review the local Android diff only. This skill is the entry point for pre-commit Android review.

## Scope

Inspect:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

Review staged changes first, then unstaged changes. Do not scan the whole repository by default.

Read nearby context only when a changed hunk cannot be understood from the diff. Read direct callers or interfaces only when the diff changes a contract.

## Ignore

- Generated files.
- Build outputs.
- Binary assets.
- Lock files unless dependency resolution changed intentionally.
- Formatting-only churn.
- Unrelated files outside the changed workflow.

## Classification

Classify changed files as:

- Compose UI.
- ViewModel or UI state.
- Coroutine or Flow.
- Repository or data source.
- Gradle or build logic.
- Tests.
- Documentation.
- Unknown.

Apply these embedded mini-checks before relying on any optional companion skill.

Compose mini-checks:

- Lifecycle-aware Flow collection, especially `collectAsStateWithLifecycle()` for UI state.
- Impossible UI state combinations caused by independent booleans, nullable fields, or stale content.
- `remember` versus `rememberSaveable` ownership for state that should or should not survive recreation.
- Side-effect keys for `LaunchedEffect`, `DisposableEffect`, `produceState`, and similar APIs.
- Heavy work in composition, including parsing, allocation-heavy mapping, IO, locks, or repeated sorting/filtering.
- Lazy list keys when item identity matters for state, animations, or stable updates.

Coroutines/Flow mini-checks:

- Scope ownership and whether work is tied to the correct lifecycle, ViewModel, repository, or application scope.
- Cancellation behavior, including child job ownership and cleanup.
- Dispatcher use for blocking work such as IO, database, network, parsing, compression, or locks.
- `GlobalScope` or manual scopes that can outlive their owner.
- `flowOn` placement and whether the upstream dispatcher intent is still correct.
- `catch` blocks that swallow cancellation or hide terminal errors.
- Mutable Flow exposure, such as exposing `MutableStateFlow` or `MutableSharedFlow` outside the owning class.

If installed, use companion Compose or coroutine skills only for deeper review after these mini-checks. The android-diff-reviewer skill must remain useful on its own.

## Checklist

- Does the diff introduce a lifecycle leak, stale UI state, or collection that outlives the screen?
- Does the diff block the main thread with IO, database, network, parsing, or locks?
- Does the diff change coroutine scope ownership, cancellation, dispatcher use, or Flow semantics?
- Does the diff create impossible UI state combinations?
- Does the diff change a public contract without updating direct callers?
- Does the diff need unit, UI, lifecycle, or regression tests?
- Does the diff need lint, connected tests, Macrobenchmark, Perfetto, or manual device verification?

## Output Format

Start with:

```text
Scope: local uncommitted Android diff only.
```

Then list changed files, findings ordered by severity, commands actually run, recommended verification not run, and residual risk.

Do not imply verification commands were run unless you actually ran them. Separate executed commands from recommendations:

```text
Commands run:
- git status --short
- git diff --stat

Recommended verification (not run):
- ./gradlew test
- ./gradlew :app:lintDebug
```

Use severity:

- `P0`: likely crash, data loss, privacy issue, or broken release behavior.
- `P1`: serious bug, lifecycle leak, ANR risk, race condition, or incorrect state behavior.
- `P2`: maintainability, test gap, performance risk, or architecture boundary issue.
- `P3`: readability or small cleanup.

Finding format:

```text
[P1] path/to/File.kt:42
Short problem statement.
Explain why this matters for Android behavior.
Suggest a concrete fix and verification step.
```

If there are no findings, say:

```text
No Android review findings found in the reviewed diff.
```

Then list residual risk, especially tests or runtime traces not run.

## False Positives to Avoid

- Do not flag every missing test. Flag missing tests when the diff changes state transitions, lifecycle behavior, concurrency behavior, parsing, persistence, or public contracts.
- Do not complain about architecture style unless the diff creates a concrete coupling, ownership, or testability problem.
- Do not assume Compose recomposition problems without a changed hot path, unstable parameter, or state ownership issue.
- Do not ask for whole-repo inspection when direct context is enough.
