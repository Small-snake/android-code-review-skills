---
name: android-coroutines-diff-reviewer
description: Review changed Android coroutine and Flow code in a local diff, focusing on scope ownership, cancellation, dispatcher usage, lifecycle collection, error handling, and tests.
---

# Android Coroutines Diff Reviewer

Review changed coroutine and Flow code in the local Android diff. Stay scoped to changed files and minimal required context.

## Inputs

Start from the diff collected by `android-diff-reviewer`. Focus on changed files containing:

- `launch`
- `async`
- `withContext`
- `viewModelScope`
- `lifecycleScope`
- `GlobalScope`
- `CoroutineScope`
- `Flow`
- `StateFlow`
- `SharedFlow`
- `callbackFlow`
- `channelFlow`
- `flowOn`
- `catch`

## Checklist

- Is the coroutine scope owned by the right lifecycle or component?
- Can the work be cancelled when the screen or operation is no longer needed?
- Does the diff use `GlobalScope` or manually created scopes without clear ownership?
- Does blocking, CPU-heavy, or unknown-dispatcher IO, database, network, JSON parsing, or bitmap work run away from the main dispatcher?
- Does `flowOn` apply to the intended upstream work?
- Does `catch` handle only expected failures without swallowing cancellation?
- Does the diff change hot vs cold Flow behavior?
- Does the diff expose mutable Flow types outside the owner?
- Does the changed code have deterministic tests for success, failure, cancellation, and ordering when those behaviors changed?

## Finding Examples

Good finding:

```text
[P1] app/src/main/java/com/example/calls/CallRepository.kt:34
The new suspend function calls a legacy blocking DAO and parses JSON before switching dispatchers.
Move the blocking or unknown dispatcher work into withContext(ioDispatcher), inject the dispatcher, and verify with a coroutine test using StandardTestDispatcher.
```

Bad finding:

```text
This coroutine code may be risky.
```

The bad finding is too vague and does not explain ownership, dispatcher behavior, or verification.

## False Positives to Avoid

- Do not require every suspend function to switch dispatchers. Flag dispatcher issues when the changed work is blocking, CPU-heavy, or has unknown dispatcher behavior.
- Do not require dispatcher switching for well-known non-blocking suspend APIs, such as Retrofit suspend calls or Room suspend DAOs, unless the diff adds blocking work around them.
- Do not complain about missing `SupervisorJob` unless sibling failure isolation is required by the changed behavior.
- Do not flag every `catch`. Check whether cancellation is swallowed or error state is hidden.
- Do not demand tests for trivial call-through code. Ask for tests when the diff changes concurrency, ordering, cancellation, retries, persistence, parsing, or UI state transitions.

## Verification

Do not imply verification commands were run unless you actually ran them. Separate executed commands from recommendations:

```text
Commands run:
- git status --short
- git diff --stat

Recommended verification (not run):
- ./gradlew test
- ./gradlew :app:testDebugUnitTest
- ./gradlew :app:lintDebug
- ./gradlew connectedDebugAndroidTest
```

Recommend module-specific Gradle commands based on changed files. Include `connectedDebugAndroidTest` for lifecycle or UI collection behavior.
