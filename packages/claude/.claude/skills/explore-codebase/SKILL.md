---
name: explore-codebase
description: |
  Efficient codebase exploration patterns for AI coding agents. Use when entering
  a new project, understanding unfamiliar code, or when the user asks to "explore",
  "understand", "find where X is implemented", or "how does Y work". Reduces token
  waste by using strategic search instead of sequential file reading.
license: MIT
metadata:
  author: pablodiazjorge
  url: https://github.com/pablodiazjorge/prompt-forge
  version: "2.0"
  tokens: "0.8k"
  sources: "simonwillison.net, github.com/openai/codex, agentskills.io"
---

# Codebase Exploration Playbook

## Agent Capabilities, Not Tool Names

Every agent exposes the same five capabilities under different names. This skill
refers to them by capability; use whichever your harness provides.

| Capability | Known as |
|---|---|
| **content search** | `Grep`, `grep_search`, `rg`, `search_file_content` |
| **glob search** | `Glob`, `file_search`, `find_files` |
| **semantic search** | `semantic_search`, `codebase_search` — absent in some agents |
| **read a range** | `Read`, `read_file`, `view` |
| **diagnostics** | `get_errors`, IDE problems panel, or the project's own lint/build command |

If a capability is missing, fall back: no semantic search → content search with
regex alternation; no diagnostics tool → run the project's build or lint command.

## Golden Rules

1. **Check for errors first.** Run diagnostics, or the project's lint/build command.
   Fixing what is already broken is priority zero.
2. **Never read files one by one.** Content search with regex alternation first.
3. **Semantic search for concepts, content search for exact symbols.**
4. **Glob search to learn the layout** before reading anything.
5. **Read 100+ lines at a time.** Fewer reads means fewer tokens.
6. **Read in parallel.** Two or three key files in a single turn.
7. **Prefer familiar formats.** Markdown and YAML cost fewer tokens to interpret
   than bespoke or binary formats.

## Progressive Disclosure

The same pattern this toolkit uses for skills applies to reading a codebase:

1. **Metadata** — names, paths, signatures. Cheap, load broadly.
2. **Instructions** — the one or two files that actually define the behavior.
3. **Resources** — everything else, on demand only.

## Strategy by Goal

| Goal | Approach |
|---|---|
| "Where is X?" | content search for the symbol → find its references → read the defining file |
| "How does this work?" | glob search for the source tree → semantic search for the concept → read ONE key file deeply |
| "Find tests for Y" | glob the project's test convention (`**/*_test.go`, `**/test_*.py`, `**/*Test.java`, `**/*.spec.*`, `**/*Tests.cs`) |
| "What are the dependencies?" | read the manifest once (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `pom.xml`, `*.csproj`, `Gemfile`) |
| "Are there errors?" | diagnostics FIRST — then search for the error symbols it reports |
| "Find all usages of X" | content search with regex, scoped by glob to the language's extensions |
| "What is the entry point?" | glob for `main.*`, `Program.cs`, `index.*`, `app.*`, or read the manifest's start/scripts section |

## Anti-Patterns

| Don't | Do |
|---|---|
| Read 15 files sequentially | Search first, then read 2-3 key files in parallel |
| Read 20-line chunks | Read 100-200 lines at a time |
| Single-keyword searches | Regex alternation: `class\|interface\|func` |
| Guess where files live | Glob search |
| Skip error checking | Diagnostics as step 1 |
| Assume one language's layout | Detect the manifest, then use that ecosystem's conventions |

## Token Economics

| Approach | Tokens |
|---|---|
| Sequential 15 files × 500 tokens | ~7,500 |
| With this playbook | ~700 |
| **Savings** | **~91%** |
