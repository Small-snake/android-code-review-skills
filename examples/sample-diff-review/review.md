# Sample Review Result

Scope: local uncommitted Android diff only.

Changed files:

- `app/src/main/java/com/example/calls/CallLogScreen.kt`
- `app/src/main/java/com/example/calls/CallRepository.kt`

Findings:

`[P1] app/src/main/java/com/example/calls/CallLogScreen.kt:10`

The screen collects `uiState` with `collectAsState()`, which is not lifecycle-aware. If the Composable remains in composition while the screen is stopped, upstream Flow work can continue and UI state can be updated outside the active lifecycle.

Use `collectAsStateWithLifecycle()` from `androidx.lifecycle.compose` and verify with a lifecycle recreation or navigation-away test.

`[P1] app/src/main/java/com/example/calls/CallRepository.kt:11`

`GlobalScope.launch` makes refresh work outlive the caller and hides failure/cancellation from the ViewModel or use case that requested the refresh. This can leave database writes running after the screen is gone and makes the operation difficult to test.

Keep `refreshCalls` as a cancellable `suspend` API, or inject an owned application scope only if the work is intentionally app-wide. Add a cancellation test and an error propagation test.

`[P2] app/src/main/java/com/example/calls/CallLogScreen.kt:12`

The UI state shape appears to allow `isLoading`, `errorMessage`, and `items` at the same time. That can render stale content together with loading and error UI.

Consider a sealed state model for loading, content, empty, and error, then add transition tests for each state.

Commands run:

- `git status --short`
- `git diff --stat`
- `git diff`

Recommended verification (not run):

- `./gradlew test`
- `./gradlew :app:lintDebug`
- `./gradlew connectedDebugAndroidTest`

Residual risk:

- Runtime jank, startup cost, and database behavior were not measured.
- Nearby callers were not inspected beyond the changed diff.
