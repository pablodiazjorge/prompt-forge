@AGENTS.md

## Claude Code

Claude Code discovers skills and subagents natively, so skip steps 1-3 of the
startup sequence above — you do not need to enumerate frontmatter by hand.

- Skills live in `.claude/skills/`. They load on demand when the task matches
  their description.
- The `ai-engineer` subagent is defined in `.claude/agents/ai-engineer.md`.
  Launch it with the Task tool when the user asks to organize knowledge.
- `developer` is the one skill to load every session, per the startup sequence.

For step 5 (check for existing errors), run this project's lint or build command;
there is no separate diagnostics tool.
