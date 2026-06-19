# Example Review Output

Scope: local uncommitted Android diff only.

Changed files:

- `app/src/main/java/com/example/calls/CallLogScreen.kt`
- `app/src/main/java/com/example/calls/CallLogViewModel.kt`
- `app/src/test/java/com/example/calls/CallLogViewModelTest.kt`

Findings:

`[P1] app/src/main/java/com/example/calls/CallLogScreen.kt:42`

The screen collects `uiState` without lifecycle awareness. If this Composable remains in composition while the lifecycle is stopped, upstream work can continue longer than intended.

Use `collectAsStateWithLifecycle()` and verify with a lifecycle recreation or navigation-away test.

`[P2] app/src/main/java/com/example/calls/CallLogViewModel.kt:88`

The new `isLoading`, `errorMessage`, and `items` fields can represent impossible states such as loading with stale content and an error at the same time. This makes UI rendering and tests harder to reason about.

Consider replacing the boolean/null combination with a sealed `CallLogUiState` and add transition tests for loading, content, empty, and error.

Verification:

- `./gradlew test`
- `./gradlew :app:lintDebug`
- `./gradlew connectedDebugAndroidTest`

Residual risk:

- Runtime jank and startup behavior were not measured.
- Generated files and binary files were not reviewed.
