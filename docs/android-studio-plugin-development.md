# Android Studio Plugin Development Plan

[中文](android-studio-plugin-development.zh-CN.md)

This document defines the product and engineering plan for turning `android-code-review-skills` into an Android Studio plugin that can run Android diff reviews and display findings inside the IDE.

## 1. Product Goal

Build an Android Studio plugin that makes AI review feel like a normal Android development workflow:

- Run review from Android Studio.
- Use the existing `android-diff-reviewer` skill as the review rule set.
- Support two review providers:
  - **Claude Code Provider**: call a locally configured Claude Code installation and ask it to use this skill.
  - **Built-in Skill Provider**: bundle the review skill inside the plugin and call a user-configured model/API.
- Persist results as Markdown and JSON.
- Display findings in a Tool Window.
- Jump from a finding to the changed file and line.
- Show editor gutter markers or annotations for findings.
- Later, show review comments directly in the Diff Viewer.

The plugin should feel useful even before Diff Viewer inline comments are implemented.

## 2. Non-Goals

- Do not edit user code automatically in the first version.
- Do not upload code without explicit user configuration and consent.
- Do not scan the entire repository by default.
- Do not require users to use Claude Code if they prefer a direct model provider.
- Do not depend on one model vendor in the plugin architecture.

## 3. User Workflows

### 3.1 Claude Code Review Workflow

User has Claude Code installed and configured locally.

Flow:

1. User opens an Android project in Android Studio.
2. User opens the plugin settings and selects `Claude Code`.
3. User sets the Claude executable path, or lets the plugin find `claude` from `PATH`.
4. User clicks `Run Android Diff Review`.
5. Plugin runs Claude Code in non-interactive print mode with a prompt that requires `android-diff-reviewer`.
6. Claude Code inspects:

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

7. Claude Code writes `.android-review/review.json` and `.android-review/review.md`.
8. Plugin watches or reloads the JSON file.
9. Tool Window displays grouped findings.
10. User clicks a finding and Android Studio opens the file at the target line.

### 3.2 Built-in Skill Review Workflow

User does not use Claude Code, or wants to call a model directly from the plugin.

Flow:

1. User opens plugin settings and selects `Built-in Skill`.
2. User configures provider, model, API key, endpoint, and optional proxy.
3. Plugin reads the bundled skill files from plugin resources.
4. Plugin collects local diff context.
5. Plugin sends a review prompt to the configured model.
6. Model returns strict `review.json`.
7. Plugin writes `.android-review/review.json` and `.android-review/review.md`.
8. UI displays findings in the same way as Claude Code mode.

### 3.3 External Result Sync Workflow

User runs Claude Code manually in a terminal, but wants Android Studio visualization.

Flow:

1. User runs review outside Android Studio.
2. Review writes `.android-review/review.json`.
3. Plugin file watcher detects the file change.
4. Plugin refreshes findings automatically.

This workflow is important because it lets the skill and plugin evolve independently.

## 4. Architecture

```text
Android Studio Plugin
├── UI Layer
│   ├── Tool Window
│   ├── Findings tree/list
│   ├── Finding detail panel
│   ├── Run/Cancel/Refresh actions
│   └── Settings page
├── Review Orchestration
│   ├── ReviewController
│   ├── ReviewProvider interface
│   ├── ClaudeCodeReviewProvider
│   ├── BuiltInSkillReviewProvider
│   └── ExternalResultWatcher
├── Result Model
│   ├── ReviewReport
│   ├── ReviewFinding
│   ├── ReviewSeverity
│   └── ReviewLocation
├── Persistence
│   ├── .android-review/review.json
│   ├── .android-review/review.md
│   └── .android-review/logs/
└── IDE Presentation
    ├── Navigation to file/line
    ├── Editor gutter markers
    ├── Editor annotations
    ├── Optional inlay hints
    └── Future Diff Viewer integration
```

## 5. Provider Model

All review backends must implement one interface:

```kotlin
interface ReviewProvider {
    val id: String
    val displayName: String

    suspend fun isAvailable(project: Project): ProviderAvailability

    suspend fun runReview(
        project: Project,
        request: ReviewRequest,
        progress: ReviewProgressSink
    ): ReviewRunResult
}
```

`ReviewRequest` contains:

- project root
- diff scope: staged, unstaged, or both
- selected files, optional
- severity threshold, optional
- provider settings
- output directory

`ReviewRunResult` contains:

- success/failure
- path to `review.json`
- path to `review.md`
- provider logs
- execution duration
- error message if failed

## 6. Claude Code Provider

### 6.1 Invocation

Claude Code supports print mode with `claude -p`, and the CLI reference documents JSON/stream JSON output flags and `--json-schema` for structured output in print mode.

Recommended invocation shape:

```bash
claude -p \
  --output-format json \
  --json-schema '<review-json-schema>' \
  '<prompt>'
```

Provider prompt requirements:

- Tell Claude Code to use `android-diff-reviewer`.
- Require local diff scope only.
- Require writing `.android-review/review.json`.
- Require writing `.android-review/review.md`.
- Require no code edits.
- Require no whole-repository scan by default.
- Require exact file path and line number for each finding when available.

### 6.2 Skill Access

The provider supports two modes:

- User-installed skill mode: Claude Code already has `android-diff-reviewer` installed.
- Prompt-injected skill mode: plugin includes the `SKILL.md` content in the prompt when the skill is not installed.

Prompt-injected mode is a fallback. User-installed mode is preferred because it behaves closer to the normal Claude Code workflow.

### 6.3 Failure Handling

Handle these cases:

- `claude` executable not found.
- Claude Code not authenticated.
- Claude Code version too old for required flags.
- Review times out.
- JSON output invalid.
- Findings refer to files that no longer exist.
- User cancels the run.

## 7. Built-in Skill Provider

### 7.1 Model Configuration

Settings:

- provider: OpenAI-compatible, Anthropic API, local endpoint, or custom HTTP
- model name
- API key storage via IDE password safe
- base URL
- request timeout
- max tokens
- temperature
- proxy

### 7.2 Prompt Construction

Prompt sections:

1. System review role.
2. `android-diff-reviewer/SKILL.md`.
3. Optional companion skill summaries:
   - Compose reviewer
   - Coroutine reviewer
4. Local git metadata:
   - `git status --short`
   - `git diff --stat`
5. Diff content:
   - `git diff --cached`
   - `git diff`
6. Strict JSON schema.
7. Markdown report requirement.

### 7.3 Privacy Controls

Before sending code to a remote model:

- Show provider name and endpoint.
- Show whether staged and unstaged diffs will be sent.
- Allow file exclusion patterns.
- Allow local-only mode.
- Never send binary files, generated files, build outputs, or ignored files.

## 8. Result Protocol

The plugin and all providers communicate through `.android-review/review.json`.

### 8.1 File Layout

```text
.android-review/
├── review.json
├── review.md
└── logs/
    └── 2026-06-22T10-15-30-claude-code.log
```

### 8.2 JSON Schema

```json
{
  "schemaVersion": "1.0",
  "run": {
    "id": "2026-06-22T10-15-30",
    "provider": "claude-code",
    "startedAt": "2026-06-22T10:15:30+08:00",
    "finishedAt": "2026-06-22T10:16:12+08:00",
    "scope": "staged-and-unstaged-local-diff",
    "repositoryRoot": "/path/to/project",
    "commitBase": "HEAD",
    "commandsRun": [
      "git status --short",
      "git diff --stat",
      "git diff",
      "git diff --cached"
    ]
  },
  "summary": {
    "totalFindings": 3,
    "p0": 0,
    "p1": 2,
    "p2": 1,
    "p3": 0
  },
  "findings": [
    {
      "id": "f-001",
      "severity": "P1",
      "category": "compose-lifecycle",
      "title": "Flow collection is not lifecycle-aware",
      "file": "app/src/main/java/com/example/calls/CallLogScreen.kt",
      "line": 42,
      "endLine": 42,
      "diffSide": "RIGHT",
      "message": "The screen collects uiState with collectAsState(), so upstream Flow work can remain active when the lifecycle is stopped.",
      "suggestion": "Use collectAsStateWithLifecycle() and verify with a lifecycle recreation or navigation-away test.",
      "verification": [
        "./gradlew test",
        "./gradlew :app:lintDebug"
      ],
      "confidence": "high",
      "sourceSkill": "android-diff-reviewer"
    }
  ],
  "recommendedVerification": [
    "./gradlew test",
    "./gradlew :app:lintDebug",
    "./gradlew connectedDebugAndroidTest"
  ],
  "residualRisk": [
    "Runtime jank and device behavior were not measured."
  ]
}
```

### 8.3 JSON Rules

- `file` is repository-relative.
- `line` is one-based.
- `diffSide` is `LEFT`, `RIGHT`, or `UNKNOWN`.
- Findings without a reliable line use `line: null` and must still include `file`.
- Every finding must include a concrete suggestion.
- Providers must never claim verification commands were run unless they were actually run.

## 9. IDE UI Design

### 9.1 Tool Window

Primary UI.

Sections:

- Header: run status, provider, last run time, total findings.
- Toolbar:
  - Run Review
  - Cancel
  - Refresh
  - Open Markdown Report
  - Open Settings
- Findings list grouped by severity.
- Finding detail panel:
  - title
  - file and line
  - explanation
  - suggestion
  - recommended verification
  - provider/source skill
- Empty state:
  - no review run yet
  - no findings
  - invalid result file

JetBrains Tool Window APIs are a good fit because the review result is a project-level view, not only an editor decoration.

### 9.2 Editor Presentation

First version:

- Gutter icon for findings with line numbers.
- Hover tooltip with title and severity.
- Click gutter icon to open finding details in the Tool Window.
- Highlight line range with severity color.

Second version:

- Inlay hint under changed lines for compact findings.
- Quick action: copy suggested fix text.

Third version:

- Quick fix support for findings that can be safely transformed.

JetBrains annotators can flag or highlight code ranges. Code inspections can integrate deeper with the IDE inspection system and quick fixes, but they are better once findings are stable and deterministic.

### 9.3 Diff Viewer Plan

Diff Viewer inline comments are the target experience, but should be a later milestone.

Plan:

1. Keep `diffSide` and line mapping in `review.json`.
2. Build reliable mapping from unified diff hunks to file/line.
3. Display findings in editor gutter first.
4. Add Diff Viewer integration only after the result protocol and line mapping are stable.

Risk:

- Diff Viewer APIs are more specialized than normal editor APIs.
- Review results generated after the diff changes can point to stale lines.
- Merge conflicts, renames, and staged-only changes need careful mapping.

Fallback:

- Open the regular file editor at the target line.
- Show finding detail in Tool Window.
- Keep Diff Viewer inline display optional.

## 10. Plugin Modules

Suggested Gradle structure:

```text
android-review-assistant/
├── build.gradle.kts
├── settings.gradle.kts
├── gradle.properties
├── src/main/kotlin/
│   └── com/smallsnake/androidreview/
│       ├── action/
│       │   └── RunAndroidReviewAction.kt
│       ├── model/
│       │   ├── ReviewReport.kt
│       │   ├── ReviewFinding.kt
│       │   └── ReviewSeverity.kt
│       ├── provider/
│       │   ├── ReviewProvider.kt
│       │   ├── ClaudeCodeReviewProvider.kt
│       │   └── BuiltInSkillReviewProvider.kt
│       ├── service/
│       │   ├── ReviewProjectService.kt
│       │   ├── ReviewResultStore.kt
│       │   └── GitDiffCollector.kt
│       ├── ui/
│       │   ├── AndroidReviewToolWindowFactory.kt
│       │   ├── FindingsPanel.kt
│       │   └── FindingDetailPanel.kt
│       ├── editor/
│       │   ├── ReviewAnnotator.kt
│       │   └── ReviewLineMarkerProvider.kt
│       └── settings/
│           ├── ReviewSettingsState.kt
│           └── ReviewSettingsConfigurable.kt
├── src/main/resources/
│   ├── META-INF/plugin.xml
│   └── skills/
│       ├── android-diff-reviewer/SKILL.md
│       ├── android-compose-diff-reviewer/SKILL.md
│       └── android-coroutines-diff-reviewer/SKILL.md
└── src/test/kotlin/
```

## 11. Plugin Configuration

`plugin.xml` declares actions, extensions, listeners, and services for IntelliJ Platform plugins.

Initial extension points:

- Action: `RunAndroidReviewAction`
- Tool Window: `AndroidReviewToolWindowFactory`
- Project service: `ReviewProjectService`
- Settings configurable: `ReviewSettingsConfigurable`
- Optional annotator: `ReviewAnnotator`

Keep plugin ID stable before marketplace release:

```text
com.smallsnake.androidcodereview
```

## 12. Settings

Settings groups:

### Provider

- Provider mode:
  - Claude Code
  - Built-in Skill
  - External Result Only
- Review scope:
  - staged and unstaged
  - staged only
  - unstaged only

### Claude Code

- executable path
- extra CLI args
- timeout
- require installed skill
- fallback to prompt-injected skill

### Built-in Skill

- provider type
- model
- base URL
- API key
- timeout
- max tokens
- temperature

### Privacy

- confirm before sending diff to remote model
- excluded file patterns
- max diff size
- redact secrets before request

### UI

- show gutter markers
- show editor annotations
- show inlay hints
- minimum severity to display

## 13. Error Handling

User-facing errors:

- No Git repository found.
- No Android-related diff found.
- Claude Code executable not found.
- Claude Code not authenticated.
- Model API key missing.
- Review timed out.
- Invalid JSON result.
- Finding line no longer exists.

Every error should include:

- short message
- detailed log link
- suggested fix

## 14. Security and Privacy

Rules:

- Never send code to a remote model without explicit provider configuration.
- Show what will be sent before the first run.
- Store API keys in the IDE password safe, not plain text.
- Do not log API keys, request headers, or full prompts by default.
- Redact common secret patterns before sending prompts.
- Keep `.android-review/` local by default.

Recommended `.gitignore` entry for consuming projects:

```gitignore
.android-review/
```

## 15. Implementation Milestones

### Milestone 1: Result Protocol

Deliverables:

- Define `review.json` schema.
- Update skill output instructions to require `review.md` and `review.json`.
- Add sample `review.json`.
- Keep console output short.

Acceptance:

- Running review produces valid JSON.
- Markdown report is still human-readable.
- Console output shows only summary and file paths.

### Milestone 2: Plugin Shell

Deliverables:

- Create IntelliJ Platform plugin project.
- Add Tool Window.
- Load existing `.android-review/review.json`.
- Render findings grouped by severity.
- Click finding to navigate to file/line.

Acceptance:

- User can manually place `review.json` and see findings in Android Studio.
- No AI call is required.

### Milestone 3: Claude Code Provider

Deliverables:

- Configure Claude executable path.
- Run Claude Code from plugin.
- Generate `review.json`.
- Stream progress to Tool Window.
- Support cancel.

Acceptance:

- User can click `Run Review`.
- Claude Code uses `android-diff-reviewer`.
- Plugin refreshes results automatically.

### Milestone 4: Built-in Skill Provider

Deliverables:

- Bundle skills as plugin resources.
- Add model settings.
- Call configured model.
- Generate same `review.json`.

Acceptance:

- User can review without Claude Code.
- Provider output is indistinguishable to the UI layer.

### Milestone 5: Editor Integration

Deliverables:

- Gutter markers.
- Editor annotations.
- Finding hover tooltip.
- Tool Window selection sync.

Acceptance:

- Findings are visible near code.
- Clicking a marker opens the finding detail.

### Milestone 6: Diff Viewer Integration

Deliverables:

- Map findings to diff hunks.
- Show comments in diff context where APIs allow.
- Fallback to editor markers when mapping fails.

Acceptance:

- Findings appear in diff workflow for common changed-file cases.
- Renames and stale lines degrade gracefully.

## 16. Testing Strategy

### Unit Tests

- JSON parsing.
- severity grouping.
- file path normalization.
- line mapping.
- provider command construction.
- prompt construction.

### Integration Tests

- load sample `review.json`.
- render Tool Window.
- navigate to file/line.
- handle invalid JSON.
- handle missing files.

### Manual Test Matrix

- Android Studio stable on macOS.
- IntelliJ IDEA with Android project, if supported.
- Kotlin file diff.
- Compose UI diff.
- coroutine/repository diff.
- staged-only review.
- unstaged-only review.
- no findings.
- invalid provider config.
- canceled run.

## 17. Open Questions

- Should the plugin live in this repository or a separate `android-code-review-assistant` repository?
- Should `.android-review/review.json` be part of the skill contract before plugin work starts?
- Should built-in model calls support only OpenAI-compatible APIs first, or Anthropic API first?
- Should the first public demo use Claude Code provider only?
- Should Diff Viewer integration block MVP release? Recommendation: no.

## 18. Recommended First Build

Build this order:

1. Update `android-diff-reviewer` to produce `review.json`.
2. Add sample `review.json`.
3. Create plugin shell with Tool Window.
4. Load and display the sample result.
5. Add navigation to file/line.
6. Add Claude Code provider.
7. Add editor gutter markers.
8. Add built-in model provider.
9. Add Diff Viewer integration.

This gives a complete product path without making the hardest IDE integration block the first usable demo.

## 19. References

- JetBrains Plugin Configuration File: https://plugins.jetbrains.com/docs/intellij/plugin-configuration-file.html
- JetBrains Tool Windows: https://plugins.jetbrains.com/docs/intellij/tool-windows.html
- JetBrains Annotator: https://plugins.jetbrains.com/docs/intellij/annotator.html
- JetBrains Inlay Hints: https://plugins.jetbrains.com/docs/intellij/inlay-hints.html
- JetBrains Code Inspections: https://plugins.jetbrains.com/docs/intellij/code-inspections.html
- Claude Code CLI Reference: https://code.claude.com/docs/en/cli-reference
- Claude Agent SDK Overview: https://code.claude.com/docs/en/agent-sdk/overview
