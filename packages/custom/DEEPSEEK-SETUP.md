# DeepSeek V4 for Copilot — Setup Guide

This document explains how to configure prompt-forge's `custom` package to work
with the **DeepSeek V4 for Copilot Chat** extension (`Vizards.deepseek-v4-for-copilot`).

---

## Known Issue

The extension has a bug where system messages are converted to user messages
before reaching the DeepSeek API. This causes Copilot's instruction files
(`.instructions.md`) and system prompt metadata to arrive with lower priority
than intended.

The bug is tracked at:
https://github.com/Vizards/deepseek-v4-for-copilot/issues/90

The `mapRole` function in the extension's source code routes the VS Code
internal `System = 3` role through a `default` case that returns `"user"`:

```typescript
// src/provider/convert.ts (simplified)
function mapRole(role) {
    switch (role) {
        case User:    return 'user';
        case Assistant: return 'assistant';
        default:      return 'user';  // System falls here
    }
}
```

The maintainer acknowledged the issue but it remains unfixed. Until it is
resolved, the workaround below ensures instructions reach the model with the
intended authority.

---

## Required VS Code Settings

Open your VS Code settings (`Ctrl+,`) and verify these two options are enabled
under **Chat > Context**:

| Setting | Description |
|---------|-------------|
| **Chat: Include Applying Instructions** | Includes `.instructions.md` files whose `applyTo` pattern matches the active file |
| **Chat: Include Referenced Instructions** | Injects the full content of referenced `.instructions.md` files into the system prompt |

Both must be ON. Without "Include Referenced Instructions", the model only sees
a file reference (`<instruction><file>default.instructions.md</file></instruction>`)
but never reads the content.

---

## The `settings.json` Workaround

Because the extension converts system messages to user messages, the most
reliable way to inject instructions is through the `github.copilot.chat.instructions`
setting. This text is included in the user prompt where the role conversion
does not apply.

Create `.vscode/settings.json` in your project with the following content:

```json
{
  "github.copilot.chat.instructions": "# CRITICAL — Estas instrucciones tienen prioridad maxima. DEBES seguirlas en cada respuesta.\n\n## SESSION STARTUP:\n1. ANTES de responder al usuario, lee los directorios bajo .github/skills/.\n2. Para cada skill, lee el YAML frontmatter (name + description).\n3. Si la tarea del usuario coincide con una descripcion, lee el SKILL.md completo.\n4. Carga SIEMPRE estos skills: explore-codebase, git-workflow, powershell-patterns, skill-creator.\n5. Ejecuta get_errors() en el workspace. Corrige errores existentes ANTES de hacer nuevos cambios.\n\n## DURANTE LA SESION:\n- Ejecuta auto-improve al final de cada iteracion significativa.\n- Ejecuta track-tokens cuando el usuario pregunte por el coste.\n\n## POWERSHELL:\n- Encadena comandos con ';', NUNCA con '&&'.\n- NUNCA uses heredocs @\"...\"@ para archivos con {{ }}. Usa create_file o replace_string_in_file.\n- Ejecuta 'nvm use X.Y.Z' despues de 'nvm install'.\n\n## GIT:\n- Conventional Commits v1.0.0. Un cambio logico por commit.\n- Ramas: feature/<name>, fix/<name>, docs/<name>, chore/<name>.\n\n## TECH STACK:\n- Angular 22 standalone + Signals + Zoneless + Tailwind CSS 4\n- lightweight-charts v5: addSeries(CandlestickSeries, opts), createSeriesMarkers() para markers\n- @ngx-translate v18: provideTranslateService + provideTranslateHttpLoader, sin TranslateModule\n- Dexie.js para cache IndexedDB\n- Web Workers para calculos pesados\n- Vitest para tests"
}
```

### Why this works

| Mechanism | What happens | Works with DeepSeek V4? |
|-----------|-------------|--------------------------|
| `.github/instructions/*.md` | Discovered by Copilot Chat, injected as system context | Partially — content arrives but role is downgraded |
| `.github/copilot-instructions.md` | Injected into system prompt by Copilot Chat | No — extension converts system to user |
| `github.copilot.chat.instructions` | Injected into user prompt by Copilot Chat | Yes — arrives as user message, no conversion issue |

### Customizing the tech stack section

The `TECH STACK` section in the example above contains project-specific
information (Angular, lightweight-charts, ngx-translate). Replace it with
the technologies your project uses. Keep it compact; every character counts
toward your token budget.

---

## Verification

After applying the settings, start a new chat session and check that the agent:

1. Reads skill frontmatter and loads relevant skills before responding
2. Runs `get_errors()` at the start of the session
3. Does not use `&&` in PowerShell commands
4. Runs `auto-improve` at the end of significant iterations

If the agent does none of these things, reload the VS Code window
(`Ctrl+Shift+P` -> `Developer: Reload Window`). The `github.copilot.chat.instructions`
setting takes effect on window load.

---

## When the Bug Is Fixed

Monitor https://github.com/Vizards/deepseek-v4-for-copilot/issues/90.
Once the maintainer fixes the `mapRole` function to handle `System = 3`, you
can remove the `.vscode/settings.json` file and rely solely on
`.github/instructions/default.instructions.md` for startup instructions.

At that point the `custom` package works identically to the `copilot` package
without any additional configuration.

---

## Related Files (in your project after setup)

```
.vscode/
└── settings.json                    ← DeepSeek V4 workaround
.github/
├── instructions/
│   └── default.instructions.md      ← Full instruction file (loaded by VS Code)
└── skills/                          ← 6 SKILL.md files
knowledge/issues/                    ← Issue registry
scripts/                             ← Session tracking (optional)
```
