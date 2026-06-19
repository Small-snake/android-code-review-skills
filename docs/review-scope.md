# Review Scope

The default review scope is the developer's local Git diff.

## Inspect First

Agents should start with:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

## Priority

1. Review staged changes from `git diff --cached`.
2. Review unstaged changes from `git diff`.
3. Read nearby context only when a changed hunk is ambiguous.
4. Read direct callers or interfaces only when the diff changes a contract.

## Ignore by Default

- Generated files.
- Build outputs.
- Binary assets.
- Lock files unless dependency resolution changed intentionally.
- Formatting-only churn.
- Files outside the changed Android workflow.

## Expand Scope Only When Necessary

It is acceptable to read extra files when:

- A changed public API has direct callers.
- A changed state model is consumed by UI code not shown in the diff.
- A changed coroutine or Flow contract depends on a lifecycle owner or scope defined elsewhere.
- A changed Gradle file affects test, lint, benchmark, or module wiring.

When expanding scope, the agent should state why it did so.
