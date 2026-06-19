---
name: android-compose-diff-reviewer
description: Review changed Jetpack Compose UI code in a local Android diff, focusing on lifecycle collection, state modeling, side effects, recomposition risk, previews, and UI test gaps.
---

# Android Compose Diff Reviewer

Review changed Compose UI code in the local diff. Stay scoped to changed files and minimal required context.

## Inputs

Start from the diff collected by `android-diff-reviewer`. Focus on changed files containing:

- `@Composable`
- `collectAsState`
- `collectAsStateWithLifecycle`
- `remember`
- `derivedStateOf`
- `LaunchedEffect`
- `DisposableEffect`
- `SideEffect`
- `snapshotFlow`
- UI state rendering

## Checklist

- Is Flow or StateFlow collected with lifecycle awareness when the source is tied to a screen lifecycle?
- Does the Composable receive stable, explicit UI state instead of many loosely related booleans and nullable fields?
- Can the state model represent impossible UI combinations?
- Are `remember`, `rememberSaveable`, and state hoisting used at the correct ownership boundary?
- Are side-effect keys specific enough to avoid stale work and broad enough to avoid accidental restarts?
- Does the diff introduce heavy work in composition?
- Does a lazy list use stable keys when item identity matters?
- Does the changed UI have preview or UI test coverage when state rendering changed?

## Finding Examples

Good finding:

```text
[P1] app/src/main/java/com/example/ProfileScreen.kt:51
The diff collects a ViewModel Flow with collectAsState() in screen-level UI.
Use collectAsStateWithLifecycle() so collection follows STARTED lifecycle state, then verify with navigation-away or lifecycle recreation coverage.
```

Bad finding:

```text
Use better Compose practices.
```

The bad finding is too vague and does not identify behavior, fix, or verification.

## False Positives to Avoid

- Do not require `collectAsStateWithLifecycle()` for every state source. Local Compose state may not need lifecycle-aware collection.
- Do not flag every `LaunchedEffect(Unit)`. Flag it when the effect captures changing values, starts long-lived work, or should be keyed to an input.
- Do not require previews for every small UI change. Flag missing previews when the diff adds meaningful visual states.
- Do not claim recomposition bugs without a changed unstable input, heavy computation, or hot rendering path.

## Verification

Recommend commands based on the diff:

```bash
./gradlew test
./gradlew :app:lintDebug
./gradlew connectedDebugAndroidTest
```

For performance-sensitive UI changes, recommend Macrobenchmark or a manual Perfetto trace instead of pretending a static review proves performance.
