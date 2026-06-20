# Android Code Review Skills

[English](README.en.md)

面向多种 AI coding agent 的 Android 本地 diff 代码审查 skills。

![Android](https://img.shields.io/badge/Android-code%20review-3DDC84)
![Skills](https://img.shields.io/badge/AI%20agents-skills-111827)
![License](https://img.shields.io/badge/license-MIT-blue)

## 为什么做这个

很多 AI code review 提示词会越看越大：扫完整个仓库、点评无关风格，却漏掉 Android 真正容易出问题的地方。这个项目默认只审查开发者当前的本地 diff，包括 staged 和 unstaged changes。

它重点检查 Android 开发里更容易踩坑的问题：

- Compose 生命周期、状态建模和副作用问题。
- Coroutine、Flow、dispatcher、cancellation 使用错误。
- 主线程阻塞、ANR 风险、状态陈旧和竞态问题。
- 缺少针对本次改动的验证命令或回归测试。
- 明确区分“已经执行的命令”和“建议执行但未执行的验证”。

## 快速开始

对你的 coding agent 说：

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

入口 skill 会要求 agent 检查：

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

默认只审查 staged 和 unstaged Android changes。只有当 diff hunk 本身看不懂时，才读取少量附近上下文。

## Agent 支持

这些 skills 首先是普通 Markdown。不同平台的文件只是薄薄一层适配，核心内容都在 `skills/*/SKILL.md`。

| Agent | 支持方式 | 安装 |
| --- | --- | --- |
| Codex | 原生 skills 目录 | [docs/install-codex.md](docs/install-codex.md) |
| Claude Code | skills 目录或 `CLAUDE.md` | [docs/install-claude-code.md](docs/install-claude-code.md) |
| Cursor | `.cursor/rules` 项目规则 | [docs/install-cursor.md](docs/install-cursor.md) |
| Gemini CLI | `GEMINI.md` 项目指令 | [docs/install-gemini-cli.md](docs/install-gemini-cli.md) |
| OpenCode | 项目 skills 目录 | [docs/install-opencode.md](docs/install-opencode.md) |
| 其他 agent | `AGENTS.md` 或粘贴 `SKILL.md` | [docs/agent-support.md](docs/agent-support.md) |

## 30 秒示例

Prompt:

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

示例发现：

```text
Scope: local uncommitted Android diff only.

[P1] app/src/main/java/com/example/calls/CallLogScreen.kt:14
The screen collects uiState with collectAsState(), so upstream Flow work can remain active when the lifecycle is stopped.

Use collectAsStateWithLifecycle() and verify with a lifecycle recreation or navigation-away test.

[P1] app/src/main/java/com/example/calls/CallRepository.kt:21
GlobalScope.launch creates work that can outlive the caller and hide failures.

Move the refresh into an owned scope, keep the suspend API cancellable, and add a cancellation test.
```

查看完整示例：

- [Sample diff](examples/sample-diff-review/sample-diff.md)
- [Sample review result](examples/sample-diff-review/review.md)

## Skills 列表

| Skill | 用途 |
| --- | --- |
| `android-diff-reviewer` | 本地 Android diff review 入口。分类变更文件、过滤噪音、输出 review findings。 |
| `android-compose-diff-reviewer` | 深入审查 Compose UI、生命周期感知收集、状态建模、副作用、Preview 和 UI test gaps。 |
| `android-coroutines-diff-reviewer` | 深入审查 coroutine ownership、cancellation、dispatcher、Flow 语义、错误处理和可测试性。 |

## 输出示例

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

## 会检查什么

- 本地 diff 范围和 changed-file classification。
- Compose state、recomposition、lifecycle collection、side effects。
- Coroutine scope ownership、cancellation、dispatcher usage、Flow behavior。
- Android 特有失败模式：leak、stale UI state、ANR risk、race condition、missing regression tests。
- 本次 review 后应该执行的验证命令。

## 不做什么

- 默认不会扫描整个仓库。
- 不能替代 compilation、lint、unit tests、UI tests、Macrobenchmark、Perfetto 或真机验证。
- 不保证代码一定正确。
- 不审查 generated files、binary assets、build outputs 或纯格式化变更，除非它们和本次 diff 直接相关。

## 安装

选择你的 agent：

- [Codex](docs/install-codex.md)
- [Claude Code](docs/install-claude-code.md)
- [Cursor](docs/install-cursor.md)
- [Gemini CLI](docs/install-gemini-cli.md)
- [OpenCode](docs/install-opencode.md)
- [Agent support matrix](docs/agent-support.md)

## 推荐第一次使用

建议先用入口 skill，不要一开始就让 agent 扫完整个项目：

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```

## 分享

如果你想介绍这个项目，可以从这里改：

- [docs/launch-post.md](docs/launch-post.md)

## 许可证

MIT
