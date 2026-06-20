# Install Android Code Review Skills for OpenCode

Copy the skill folders into the target project's `.opencode/skills` directory:

```bash
mkdir -p .opencode/skills
cp -R skills/android-diff-reviewer .opencode/skills/
cp -R skills/android-compose-diff-reviewer .opencode/skills/
cp -R skills/android-coroutines-diff-reviewer .opencode/skills/
```

Then ask OpenCode:

```text
use skill tool to load android-diff-reviewer
```

Review prompt:

```text
Use android-diff-reviewer to review my staged and unstaged Android changes. Stay scoped to the local diff unless a changed hunk requires nearby context.
```
