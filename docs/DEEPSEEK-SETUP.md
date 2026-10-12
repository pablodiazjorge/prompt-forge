# DeepSeek V4 for Copilot — Setup Guide

How to make the prompt-forge `vscode` package work with the **DeepSeek V4 for
Copilot Chat** extension (`Vizards.deepseek-v4-for-copilot`).

Every other provider in that package works out of the box. DeepSeek V4 needs a
workaround because of an upstream bug.

---

## Known Issue

The extension converts system messages to user messages before they reach the
DeepSeek API, so instruction files arrive with lower priority than intended.

Tracked at https://github.com/Vizards/deepseek-v4-for-copilot/issues/90.

The `mapRole` function routes VS Code's internal `System = 3` role through a
`default` case that returns `"user"`:

```typescript
// src/provider/convert.ts (simplified)
function mapRole(role) {
    switch (role) {
        case User:      return 'user';
        case Assistant: return 'assistant';
        default:        return 'user';  // System falls here
    }
}
```

The maintainer acknowledged it but it remains unfixed.

---

## Required VS Code Settings

Under **Chat > Context**, confirm:

| Setting | Why |
|---------|-----|
| `chat.useAgentsMdFile` | Loads `AGENTS.md` from the workspace root. Required — it is the only instruction file prompt-forge ships. |
| **Chat: Include Referenced Instructions** | Injects the full content of referenced instruction files rather than just a filename reference. |

Without the second one the model sees a file reference but never its content.

---

## The `settings.json` Workaround

Because the extension downgrades system messages, the reliable channel is
`github.copilot.chat.instructions`, which lands in the user prompt where the role
conversion does not apply.

Create `.vscode/settings.json` with a compressed restatement of the startup
sequence. Keep it short — every character costs tokens on every request.

```json
{
  "github.copilot.chat.instructions": "# CRITICAL - highest priority, follow in every response.\n\n## SESSION STARTUP:\n1. Before replying, list the directories under .github/skills/.\n2. For each skill read only the YAML frontmatter (name + description).\n3. If the task matches a description, read that full SKILL.md.\n4. ALWAYS load the 'developer' skill.\n5. Check for existing errors before making new changes.\n\n## DURING THE SESSION:\n- Run the 'developer' skill at the end of each significant iteration.\n- Run 'ai-engineer' as a subagent when asked to organize knowledge.\n\n## TERMINAL (Windows):\n- Sequence commands with ';'. '&&' is a parser error in PowerShell 5.1.\n- Check $LASTEXITCODE after a native executable.\n- Never write files containing {{ }} through shell redirection; use the file-creation tool.\n\n## GIT:\n- Conventional Commits v1.0.0. One logical change per commit.\n- Branches: feature/<name>, fix/<name>, docs/<name>, chore/<name>.\n\n## TECH STACK:\n- <replace with your project's languages, frameworks and versions>"
}
```

### Customize the tech stack section

The `TECH STACK` line is a placeholder. Replace it with the languages,
frameworks, and pinned versions your project actually uses — that is the context
the model cannot derive on its own. Keep it compact.

### Why this channel works

| Mechanism | What happens | Works with DeepSeek V4? |
|-----------|-------------|--------------------------|
| `AGENTS.md` | Injected into the system prompt by VS Code | Partially — content arrives, role is downgraded |
| `github.copilot.chat.instructions` | Injected into the user prompt | Yes — no role conversion involved |

---

## Verification

Start a new chat and check that the agent:

1. Reads skill frontmatter and loads relevant skills before responding
2. Checks for existing errors at the start of the session
3. Sequences shell commands with `;` rather than `&&`
4. Runs the `developer` skill at the end of significant iterations

If none of that happens, reload the window (`Ctrl+Shift+P` →
`Developer: Reload Window`). The `github.copilot.chat.instructions` setting takes
effect on window load.

---

## When the Bug Is Fixed

Once `mapRole` handles `System = 3`, delete `.vscode/settings.json` and rely on
`AGENTS.md` alone. At that point DeepSeek behaves like any other provider in the
`vscode` package.
