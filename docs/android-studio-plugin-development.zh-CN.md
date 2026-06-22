# Android Studio 插件开发计划

[English](android-studio-plugin-development.md)

本文档描述如何把 `android-code-review-skills` 从一组 Markdown skills，升级成一个可在 Android Studio 中使用的 AI Review 插件。

核心目标不是简单地“把 review 结果打印得好看一点”，而是让 Android 开发者在 IDE 里完成完整闭环：

- 在 Android Studio 中发起本地 diff review。
- 复用现有 `android-diff-reviewer` skill 作为审查规则。
- 支持两种 review 方式：
  - **Claude Code Provider**：调用用户本机已配置好的 Claude Code，让 Claude Code 使用这个 skill 完成 review。
  - **内置 Skill Provider**：插件内置 review skill，用户自己配置模型、API key 和 endpoint。
- 把结果保存为 Markdown 和 JSON。
- 在 Android Studio 的 Tool Window 中展示 findings。
- 点击 finding 跳转到对应文件和行。
- 在编辑器里显示 gutter marker / annotation / inlay hint。
- 后续再把 findings 显示到 Diff Viewer 里，形成类似代码评审评论的体验。

## 1. 产品定位

这个插件可以叫：

```text
Android Code Review Assistant
```

它的定位是：

> 面向 Android 开发者的本地 diff AI review 插件。它不是通用聊天机器人，而是专注于 staged / unstaged Android 变更，检查 Compose、Coroutine、Flow、ViewModel、Repository、状态建模、ANR 风险和测试缺口。

第一版不追求把所有功能做满，而是先形成一个真实可用的产品闭环：

```text
Android Studio 点击 Run Review
-> 调用 Claude Code 或内置模型
-> 使用 android-diff-reviewer skill
-> 生成 .android-review/review.json
-> Tool Window 展示结果
-> 点击 finding 跳转代码行
```

## 2. 不做什么

第一版明确不做：

- 不自动修改用户代码。
- 不默认上传代码到远程模型。
- 不默认扫描整个仓库。
- 不强制用户必须使用 Claude Code。
- 不把插件架构绑定到某一个模型厂商。
- 不把 Diff Viewer inline comment 作为 MVP 阻塞项。

Diff Viewer 是最终体验的一部分，但不是第一阶段必须完成的能力。

## 3. 用户工作流

### 3.1 Claude Code 联动模式

适合已经在本机配置好 Claude Code 的用户。

流程：

1. 用户在 Android Studio 打开 Android 项目。
2. 插件设置里选择 `Claude Code`。
3. 用户配置 Claude 可执行文件路径，或者插件从 `PATH` 查找 `claude`。
4. 用户点击 `Run Android Diff Review`。
5. 插件通过非交互模式调用 Claude Code。
6. Prompt 要求 Claude Code 使用 `android-diff-reviewer`。
7. Claude Code 检查本地 diff：

```bash
git status --short
git diff --stat
git diff
git diff --cached
```

8. Claude Code 输出：

```text
.android-review/review.json
.android-review/review.md
```

9. 插件读取 `review.json`。
10. Tool Window 展示 findings。
11. 用户点击 finding，跳转到对应代码行。

这个模式的优点是：用户继续使用自己熟悉的 Claude Code，插件只负责触发和可视化。

### 3.2 内置 Skill 模式

适合不想依赖 Claude Code 的用户。

流程：

1. 用户在插件设置里选择 `Built-in Skill`。
2. 用户配置模型提供方、model name、API key、base URL、超时时间等。
3. 插件从自身资源中读取内置 skill：

```text
android-diff-reviewer/SKILL.md
android-compose-diff-reviewer/SKILL.md
android-coroutines-diff-reviewer/SKILL.md
```

4. 插件收集本地 diff。
5. 插件把 skill + diff + JSON schema 发送给用户配置的模型。
6. 模型返回严格结构化的 `review.json`。
7. 插件生成对应的 `review.md`。
8. UI 层用同一套逻辑展示 findings。

这个模式的优点是：插件可以独立工作，不要求用户安装 Claude Code。

### 3.3 外部结果同步模式

适合用户仍然想在终端里运行 review，但希望 Android Studio 可视化结果。

流程：

1. 用户在终端里运行 Claude Code 或其他 agent。
2. agent 生成：

```text
.android-review/review.json
```

3. 插件监听这个文件。
4. 文件变化后自动刷新 Tool Window。

这个模式非常重要，因为它能让 skill 和插件解耦：即使插件还不能直接调用某个 agent，只要能读 `review.json`，就能展示结果。

## 4. 总体架构

```text
Android Studio Plugin
├── UI Layer
│   ├── Tool Window
│   ├── Findings 列表
│   ├── Finding 详情面板
│   ├── Run / Cancel / Refresh 按钮
│   └── Settings 页面
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
    ├── 跳转文件和行
    ├── Editor gutter marker
    ├── Editor annotation
    ├── Inlay hint
    └── 后续 Diff Viewer 集成
```

核心原则：

- Provider 只负责产出标准 `review.json`。
- UI 只消费 `review.json`，不关心结果来自 Claude Code 还是内置模型。
- `.android-review/` 是 skill、插件、外部 agent 之间的中间协议目录。

## 5. Provider 抽象

所有 review 后端都实现同一个接口：

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

`ReviewRequest` 包含：

- project root
- review 范围：staged、unstaged 或两者都包含
- 可选的 selected files
- severity threshold
- provider settings
- output directory

`ReviewRunResult` 包含：

- 是否成功
- `review.json` 路径
- `review.md` 路径
- provider logs
- 执行耗时
- 错误信息

这个抽象可以避免后面每接一个模型都重写 UI。

## 6. Claude Code Provider

### 6.1 调用方式

Claude Code 可以通过 print mode 被外部程序调用。插件推荐使用类似下面的调用形态：

```bash
claude -p \
  --output-format json \
  --json-schema '<review-json-schema>' \
  '<prompt>'
```

Prompt 需要明确要求：

- 使用 `android-diff-reviewer`。
- 只审查本地 diff。
- 输出 `.android-review/review.json`。
- 输出 `.android-review/review.md`。
- 不修改代码。
- 默认不扫描整个仓库。
- finding 尽量给出准确文件路径和行号。

### 6.2 Skill 来源

Claude Code Provider 支持两种 skill 来源：

1. 用户已经安装 skill
   Claude Code 直接使用用户环境中的 `android-diff-reviewer`。

2. Prompt 注入 skill
   如果用户没有安装 skill，插件把 `SKILL.md` 内容注入 prompt。

推荐优先使用第 1 种，因为这更符合 Claude Code 原生工作方式。第 2 种作为 fallback。

### 6.3 错误处理

需要处理：

- 找不到 `claude`。
- Claude Code 未登录。
- Claude Code 版本太旧，不支持所需参数。
- review 超时。
- 用户取消任务。
- 模型输出不是合法 JSON。
- finding 指向的文件不存在。
- finding 指向的行号已经过期。

错误信息要能让用户知道下一步怎么修。

## 7. 内置 Skill Provider

### 7.1 模型配置

设置项：

- provider 类型：OpenAI-compatible、Anthropic API、本地 endpoint、自定义 HTTP。
- model name。
- API key。
- base URL。
- request timeout。
- max tokens。
- temperature。
- proxy。

API key 必须存到 IDE 的 password safe，不应该明文写入普通配置文件。

### 7.2 Prompt 构造

Prompt 由这些部分组成：

1. Review system role。
2. `android-diff-reviewer/SKILL.md`。
3. 可选 companion skills：
   - Compose reviewer
   - Coroutine reviewer
4. Git metadata：
   - `git status --short`
   - `git diff --stat`
5. Diff 内容：
   - `git diff --cached`
   - `git diff`
6. 严格 JSON schema。
7. Markdown report 输出要求。

### 7.3 隐私控制

发送代码到远程模型前必须清楚告诉用户：

- 将使用哪个 provider。
- 将发送到哪个 endpoint。
- 会发送 staged diff、unstaged diff，还是两者都有。
- 是否有文件排除规则。
- 是否启用了 secrets redaction。

默认不要发送：

- binary files
- generated files
- build outputs
- ignored files

## 8. Review Result 协议

插件和所有 Provider 都通过 `.android-review/review.json` 通信。

### 8.1 文件布局

```text
.android-review/
├── review.json
├── review.md
└── logs/
    └── 2026-06-22T10-15-30-claude-code.log
```

### 8.2 JSON 示例

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

### 8.3 协议规则

- `file` 使用 repo-relative path。
- `line` 是从 1 开始的行号。
- `diffSide` 可选值：`LEFT`、`RIGHT`、`UNKNOWN`。
- 如果没有可靠行号，`line` 可以是 `null`，但必须保留 `file`。
- 每个 finding 必须有具体 suggestion。
- Provider 不能声称运行过没运行的验证命令。

## 9. IDE 交互设计

### 9.1 Tool Window

第一版主界面使用 Tool Window。

内容：

- Header：
  - 当前 provider
  - 最近一次运行时间
  - findings 总数
  - P0/P1/P2/P3 统计
- Toolbar：
  - Run Review
  - Cancel
  - Refresh
  - Open Markdown Report
  - Open Settings
- Findings 列表：
  - 按 severity 分组
  - 展示 title、file、line
- Finding 详情：
  - title
  - file / line
  - problem explanation
  - suggestion
  - recommended verification
  - source skill / provider
- Empty state：
  - 还没运行 review
  - 没有 finding
  - JSON 无效

Tool Window 适合承载项目级 review 结果，因为这些结果不只属于当前打开的一个编辑器。

### 9.2 编辑器展示

第一版：

- 在有 finding 的行显示 gutter icon。
- hover 显示 severity 和 title。
- 点击 gutter icon 打开 Tool Window 里的 finding detail。
- 用不同颜色高亮 P0/P1/P2/P3。

第二版：

- 在相关代码附近显示 inlay hint。
- 提供 copy suggestion 操作。

第三版：

- 对能确定修改方式的问题提供 quick fix。

注意：quick fix 必须非常谨慎。AI review finding 不等于 deterministic lint rule，不能随便自动改。

### 9.3 Diff Viewer 计划

Diff Viewer inline comment 是最终体验，但建议放在后续阶段。

原因：

- Diff Viewer API 比普通 editor API 更复杂。
- staged-only、unstaged-only、rename、line moved 都会影响映射。
- review 结束后用户继续改代码，line 可能过期。

推荐路线：

1. `review.json` 先保留 `diffSide` 和 line mapping 信息。
2. 先在普通 editor 里完成 gutter marker。
3. 等 finding 定位稳定后再做 Diff Viewer。
4. Diff Viewer 显示失败时 fallback 到普通 editor 跳转。

## 10. 插件模块结构

建议后续新建插件工程：

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

## 11. 插件配置

`plugin.xml` 需要声明：

- Action：`RunAndroidReviewAction`
- Tool Window：`AndroidReviewToolWindowFactory`
- Project service：`ReviewProjectService`
- Settings page：`ReviewSettingsConfigurable`
- 可选 editor annotator：`ReviewAnnotator`

建议稳定使用这个 plugin id：

```text
com.smallsnake.androidcodereview
```

## 12. 设置页面

### Provider 设置

- Provider mode：
  - Claude Code
  - Built-in Skill
  - External Result Only
- Review scope：
  - staged and unstaged
  - staged only
  - unstaged only

### Claude Code 设置

- Claude executable path。
- extra CLI args。
- timeout。
- 是否要求用户已安装 skill。
- 是否允许 prompt 注入 skill 作为 fallback。

### 内置 Skill 设置

- provider type。
- model。
- base URL。
- API key。
- timeout。
- max tokens。
- temperature。

### 隐私设置

- 发送远程模型前是否二次确认。
- 文件排除规则。
- 最大 diff 大小。
- secrets redaction。

### UI 设置

- 是否展示 gutter markers。
- 是否展示 editor annotations。
- 是否展示 inlay hints。
- 最低展示 severity。

## 13. 错误处理

常见错误：

- 当前项目不是 Git 仓库。
- 没有 Android 相关 diff。
- 找不到 Claude Code。
- Claude Code 未登录。
- 模型 API key 缺失。
- review 超时。
- JSON 格式无效。
- finding 对应文件不存在。
- finding 行号已经过期。

每个错误都应该包含：

- 简短错误信息。
- 详细日志入口。
- 建议修复方式。

## 14. 安全和隐私

规则：

- 未经用户明确配置，不发送代码到远程模型。
- 第一次运行前说明会发送哪些 diff。
- API key 存到 IDE password safe。
- 默认不记录 API key、request headers、完整 prompt。
- 发送前尝试 redaction 常见 secret。
- `.android-review/` 默认只存在本地。

建议用户项目 `.gitignore` 增加：

```gitignore
.android-review/
```

## 15. 实施里程碑

### Milestone 1：Result Protocol

交付：

- 定义 `review.json` schema。
- 修改 skill 输出要求，让它生成 `review.md` 和 `review.json`。
- 添加 sample `review.json`。
- 控制台只输出摘要和文件路径。

验收：

- review 可以生成合法 JSON。
- Markdown 报告可读。
- console 不再刷大段 review 结果。

### Milestone 2：Plugin Shell

交付：

- 创建 IntelliJ Platform plugin 工程。
- 添加 Tool Window。
- 读取现有 `.android-review/review.json`。
- 按 severity 展示 findings。
- 点击 finding 跳转文件和行。

验收：

- 手工放一个 `review.json`，Android Studio 能展示。
- 这一阶段不需要 AI 调用。

### Milestone 3：Claude Code Provider

交付：

- 配置 Claude executable path。
- 插件内调用 Claude Code。
- 生成 `review.json`。
- Tool Window 显示执行进度。
- 支持 cancel。

验收：

- 用户点击 `Run Review`。
- Claude Code 使用 `android-diff-reviewer`。
- 插件自动刷新结果。

### Milestone 4：内置 Skill Provider

交付：

- 插件资源中内置 skills。
- 添加模型配置。
- 调用用户配置的模型。
- 生成相同的 `review.json`。

验收：

- 不安装 Claude Code 也能 review。
- UI 层不需要关心 Provider 来源。

### Milestone 5：Editor Integration

交付：

- Gutter marker。
- Editor annotation。
- Hover tooltip。
- Tool Window selection sync。

验收：

- finding 能在代码附近被看到。
- 点击 marker 能打开详情。

### Milestone 6：Diff Viewer Integration

交付：

- finding 到 diff hunk 的映射。
- 在 diff 上下文中展示 comment。
- 映射失败时 fallback 到普通 editor。

验收：

- 常见变更文件能在 diff workflow 中看到 findings。
- rename、stale line 等复杂情况能优雅降级。

## 16. 测试策略

### Unit Tests

- JSON parsing。
- severity grouping。
- file path normalization。
- line mapping。
- provider command construction。
- prompt construction。

### Integration Tests

- 加载 sample `review.json`。
- 渲染 Tool Window。
- 跳转文件和行。
- 处理 invalid JSON。
- 处理 missing file。

### Manual Test Matrix

- Android Studio stable on macOS。
- Kotlin file diff。
- Compose UI diff。
- coroutine / repository diff。
- staged-only review。
- unstaged-only review。
- no findings。
- invalid provider config。
- canceled run。

## 17. 关键开放问题

- 插件应该放在当前仓库里，还是新建 `android-code-review-assistant` 仓库？
- 是否先把 `.android-review/review.json` 协议做成 skill 的正式 contract？
- 内置模型第一版先支持 OpenAI-compatible API，还是先支持 Anthropic API？
- 第一个公开 demo 是否只演示 Claude Code Provider？
- Diff Viewer 是否阻塞 MVP？建议：不阻塞。

## 18. 推荐第一阶段构建顺序

建议按这个顺序做：

1. 修改 `android-diff-reviewer`，让它输出 `review.json`。
2. 添加 sample `review.json`。
3. 创建插件 shell 和 Tool Window。
4. 读取 sample result 并展示。
5. 点击 finding 跳转文件和行。
6. 增加 Claude Code Provider。
7. 增加 editor gutter marker。
8. 增加内置模型 Provider。
9. 最后再做 Diff Viewer 集成。

这条路线的好处是：第一阶段就能做出能演示的产品，不会一开始就卡在最难的 IDE Diff Viewer 扩展点上。

## 19. 参考资料

- JetBrains Plugin Configuration File: https://plugins.jetbrains.com/docs/intellij/plugin-configuration-file.html
- JetBrains Tool Windows: https://plugins.jetbrains.com/docs/intellij/tool-windows.html
- JetBrains Annotator: https://plugins.jetbrains.com/docs/intellij/annotator.html
- JetBrains Inlay Hints: https://plugins.jetbrains.com/docs/intellij/inlay-hints.html
- JetBrains Code Inspections: https://plugins.jetbrains.com/docs/intellij/code-inspections.html
- Claude Code CLI Reference: https://code.claude.com/docs/en/cli-reference
- Claude Agent SDK Overview: https://code.claude.com/docs/en/agent-sdk/overview
