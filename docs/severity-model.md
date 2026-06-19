# Severity Model

Use severity to prioritize review findings, not to make the output sound dramatic.

## P0

Likely release-blocking behavior:

- Crash on a common path.
- Data loss.
- Privacy or permission regression.
- Security-sensitive behavior.
- Broken app startup or broken critical workflow.

## P1

Serious Android correctness or stability risk:

- Lifecycle leak.
- ANR risk.
- Race condition.
- Incorrect cancellation behavior.
- Stale UI state after lifecycle recreation.
- Flow collection that outlives the screen.
- Incorrect dispatcher use that can block the main thread.

## P2

Important maintainability, testability, or performance risk:

- Missing regression test for changed state transitions.
- Impossible UI state combinations.
- Architecture boundary drift.
- Recomposition risk in a hot UI path.
- Error handling that hides failure from the UI.

## P3

Small cleanup:

- Naming clarity.
- Local readability issue.
- Non-blocking style consistency.
- Documentation mismatch in changed files.

## No Finding

Do not invent findings. If no Android-specific issue is found, say so and list residual risk such as tests not run or runtime traces not inspected.
