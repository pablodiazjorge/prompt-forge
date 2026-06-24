# prompt-forge: Architecture Document

## Purpose and Scope

This document describes the architecture of prompt-forge, a drop-in toolkit that
adds Agent Skills, an auto-improvement loop, and session tracking to any
software project. It is written for contributors and maintainers who need to
understand why the system is shaped the way it is, and for users evaluating
whether prompt-forge fits their development workflow.

The document follows the conventions of Architectural Decision Records (ADR) as
popularized by Michael Nygard and formalized by the MADR project. Each
architecturally significant choice is presented with its context, the options
considered, the decision made, and the resulting consequences.

---

## System Context

prompt-forge is not a standalone application. It is a set of inert files that
are copied into a host project, where they are interpreted by an AI coding agent
at runtime. The agent -- typically GitHub Copilot, Claude Code, or Codex -- reads
the Markdown skill files on demand and follows their instructions to enhance its
own behavior.

```
Host Project
+------------------------------------------+
|  .github/skills/          (6 SKILL.md files)    |
|  .github/instructions/    (agent instructions)  |
|  knowledge/issues/        (registry + issues)   |
|  scripts/                 (PowerShell utilities) |
|  .github/copilot-instructions.md                |
+------------------------------------------+
         |
         | read & execute on demand
         v
+-------------------+
|   AI Coding Agent |
|  (Copilot, Claude |
|   Code, Codex)    |
+-------------------+
```

There is no runtime, no server process, no database, and no build step. The
toolkit is purely declarative: Markdown files encode instructions, PowerShell
scripts perform side effects like logging, and the agent is the interpreter.

---

## Architectural Principles

These principles are non-negotiable. Every design decision in this document is
evaluated against them.

**Principle 1: Zero runtime dependencies.**
The toolkit must work in any project without requiring npm installs, Python
virtual environments, or any other package manager invocation. The only
assumption is that the host machine has PowerShell 5.1 or later, which is
preinstalled on all supported Windows versions.

**Principle 2: Host-project safety.**
prompt-forge files must never interfere with the host project's own build
system, testing framework, linting configuration, or version control hygiene.
The `.gitignore` shipped with prompt-forge covers only prompt-forge artifacts;
it does not impose opinions about how the host project should structure its own
ignore rules.

**Principle 3: Progressive disclosure.**
AI agents have limited context windows, and every token loaded is a token that
cannot be used for the actual task. Skills expose minimal metadata at discovery
time and load their full instruction body only when the conversation context
matches the skill's trigger description. This is the same principle used by
Codex and Claude Code in their own skill systems.

**Principle 4: Git-native knowledge persistence.**
The issue registry uses the filesystem as its database. Each issue is a
Markdown file in a directory. This means knowledge is version-controlled,
diffable, mergeable, and survives independently of any external service.

**Principle 5: Agent-agnostic design.**
No skill or script assumes a specific AI coding agent. While
`copilot-instructions.md` is loaded automatically by GitHub Copilot, the skills
themselves reference only agent tools that are common across platforms (read
file, search code, run terminal commands).

---

## Decision Log

### ADR-001: Markdown as the Skill Format

**Context.**
Agent Skills need a format that is human-writable, machine-parseable, and
compatible with multiple AI coding platforms. The format must support structured
metadata so agents can discover skills without loading their full content.

**Options considered.**

A. JSON or YAML files with embedded instruction text. Structured but unpleasant
to write by hand, especially for multi-paragraph instructional content.

B. Plain text files with conventions for metadata boundaries. Simple but fragile;
no standard way to separate metadata from instructions.

C. Markdown files with YAML frontmatter, following the agentskills.io standard.
Combines the readability of Markdown with the structure of YAML for metadata.
Already supported by major AI coding platforms.

**Decision.**
Use Markdown with YAML frontmatter conforming to the agentskills.io standard.

**Rationale.**
Markdown is the lingua franca of AI coding agents. Every major agent platform
reads it natively for system prompts, custom instructions, and skills. YAML
frontmatter provides a machine-parseable metadata block that agents can read in
a single token-efficient operation (`read_file` with a small line range). The
agentskills.io standard adds a `name` and `description` field that enables
progressive disclosure: the agent can scan all skill descriptions (~100 tokens
each) and load only the matching skill body (~500-1500 tokens).

**Consequences.**
Skills are easy to write, review, and version-control. The frontmatter schema
is extensible (we added `url`, `sources`, and `tokens` fields without breaking
anything). The trade-off is that YAML frontmatter parsing is slightly fragile;
a single misplaced character can break the metadata block. This is mitigated by
keeping the frontmatter minimal.

---

### ADR-002: Filesystem-Based Issue Registry

**Context.**
The auto-improvement loop needs persistent storage for tracking issues across
sessions. Issues must survive agent restarts, be shareable across developers,
and integrate with existing development workflows.

**Options considered.**

A. Embedded database (SQLite). Would require a runtime dependency and a schema
migration strategy. Overkill for the expected data volume (tens to hundreds of
issues, not millions).

B. External service (GitHub Issues, Jira, Linear). Would couple the toolkit to
a specific platform and require API credentials. Breaks Principle 1.

C. Markdown files in a directory structure, versioned with Git. Each issue is a
file. The index is a file. No dependencies, no credentials, no migration scripts.

**Decision.**
Store issues as individual Markdown files under `knowledge/issues/`, with an
`INDEX.md` file serving as a human-and-machine-readable catalog. Each issue file
uses YAML frontmatter for structured fields (id, occurrences, certainty) and
Markdown body for qualitative evidence.

**Rationale.**
The filesystem is the most portable database in existence. Git provides
versioning, diffing, and collaboration for free. A developer can browse issues
with any text editor, not just through the AI agent. The structure is
self-documenting: reading `INDEX.md` gives an overview; reading an individual
issue file gives the details. No schema migrations are needed because the
frontmatter format is extensible.

**Consequences.**
The index table can produce merge conflicts when two developers add rows
simultaneously. This is addressed by the UUID-based ID scheme (ADR-005) and the
conflict resolution instructions embedded in `INDEX.md`. The trade-off is
acceptable because merge conflicts on a Markdown table are trivial to resolve
compared to database migration failures or API rate limits.

---

### ADR-003: PowerShell for Session Scripts

**Context.**
Token tracking requires scripts that create log files and read environment
variables. These scripts are optional; the toolkit works without them. They must
run on Windows without additional installations.

**Options considered.**

A. Python scripts. Would require Python to be installed and on PATH. Many
Windows development machines have Python, but not all. Breaks Principle 1.

B. Node.js scripts. Same dependency problem as Python, plus the overhead of npm
package management for what amounts to file I/O and date formatting.

C. Batch files (.bat or .cmd). Limited string manipulation, no native JSON
support, fragile error handling. Not appropriate for structured logging.

D. PowerShell scripts (.ps1). Preinstalled on Windows 10 and later. Native
JSON support via `ConvertFrom-Json` and `ConvertTo-Json`. Rich error handling.
Object-oriented pipeline makes data transformation straightforward.

**Decision.**
Use PowerShell 5.1 scripts for session start and end logging.

**Rationale.**
PowerShell is the only scripting runtime guaranteed to exist on every Windows
machine that runs VS Code. Its JSON handling is excellent for structured
logging. The scripts are intentionally kept under 100 lines each so they are
easy to audit and modify. The trade-off is that these scripts do not run on
macOS or Linux without installing PowerShell Core, but the toolkit's core
functionality (skills, issue registry, auto-improve) is platform-independent
Markdown; the scripts are an optional Windows bonus.

**Consequences.**
Cross-platform users on macOS/Linux cannot use the session tracking scripts
without installing PowerShell Core. The `track-tokens` skill provides an
alternative: it queries VS Code's internal session store directly, which works
on all platforms. The scripts remain the recommended approach for Windows users
who want cumulative cost tracking across sessions.

---

### ADR-004: Progressive Disclosure for Skill Loading

**Context.**
An AI coding agent may have access to dozens of skills in a project. Loading
all skill bodies eagerly would consume context window tokens that could be used
for the actual coding task. A mechanism is needed to defer loading until a skill
is relevant.

**Options considered.**

A. Load all skills eagerly at session start. Simple but wasteful. Every skill
body (total ~6.8k tokens across all six skills) would be loaded into every
conversation, even if none are triggered.

B. Keyword-based triggering. The agent scans user messages for keywords and
loads matching skills. Fragile; a user saying "I need to commit" might not
trigger the git-workflow skill if the keyword list is too narrow.

C. Description-based triggering using frontmatter. Each skill declares its
trigger conditions in natural language in the `description` field. The agent
reads only the frontmatter of all skills (~100 tokens each, ~500 tokens total)
and loads the full body only when the conversation context semantically matches
a description.

**Decision.**
Use description-based progressive disclosure. Each `SKILL.md` contains a
`description` field in its YAML frontmatter that describes when the skill should
be loaded. The agent reads all frontmatter blocks (approximately 600 tokens for
six skills) and loads the body of only the skills whose descriptions match the
current task context.

**Rationale.**
This is the pattern used by Codex, Claude Code, and the agentskills.io
standard. It provides the best balance of token efficiency and triggering
accuracy. Six hundred tokens is negligible compared to the context window of
modern models (1M tokens for DeepSeek V4, Claude Opus 4.8, GPT-5.4). The
descriptions act as an embedding-free semantic router: the model itself
determines relevance, which is more accurate than keyword matching.

**Consequences.**
The skill author must write descriptions that accurately reflect the trigger
conditions. A poorly written description either causes the skill to be loaded
when irrelevant (wasting tokens) or not loaded when needed (missing the
opportunity to help). This is mitigated by keeping descriptions concise and
specific. The `tokens` field in frontmatter helps the agent decide whether the
skill is worth loading: a 0.5k skill like git-workflow can be loaded eagerly
with minimal cost, while a 1.5k skill like auto-improve should be loaded only
when the user explicitly signals session-end or review.

---

### ADR-005: UUID-Based Issue Identifiers

**Context.**
The issue registry assigns an identifier to each issue. The initial design used
sequential numeric IDs (ISSUE-001, ISSUE-002). This created two problems: first,
the agent had to read `INDEX.md` to determine the next available number, adding
a token cost to every issue creation. Second, and more critically, two
developers running auto-improve simultaneously would both read the same highest
ID, both create a file with the same name, and produce a Git conflict.

**Options considered.**

A. Per-developer sequential IDs (ISSUE-pablodiazjorge-001). Eliminates
collisions but requires the agent to discover the developer's identity and
track per-developer sequences. Adds complexity.

B. Timestamp-only IDs (ISSUE-20260624-143000). Nearly unique but can still
collide if two developers generate an ID in the same second. Also verbose.

C. Full UUIDs (ISSUE-a1b2c3d4-e5f6-7890-abcd-ef1234567890). Collision-proof but
extremely verbose. Hard to reference in conversations.

D. Date-prefixed short UUIDs (ISSUE-YYYYMMDD-XXXX where XXXX is the first 4
hex characters of a UUID). Combines chronological grouping with collision
resistance. The date prefix makes issues sortable; 4 hex characters provide
65,536 unique values per day, making collisions virtually impossible in any
practical team size.

**Decision.**
Use ISSUE-YYYYMMDD-XXXX format, where XXXX is generated from the first 4
hexadecimal characters of a random UUID.

**Rationale.**
The date prefix provides immediate temporal context without reading the file.
The 4-character hex suffix eliminates the need to read `INDEX.md` before
creating an issue; the agent generates the ID autonomously. With 2^16 possible
suffixes per day, the birthday paradox predicts a 50% collision probability only
after approximately 300 developers create issues on the same day -- well beyond
any realistic team size. The total length (20 characters including the ISSUE-
prefix) is short enough to reference naturally in commit messages and
conversations.

**Consequences.**
Issue filenames are no longer sequentially ordered in directory listings, but
the date prefix preserves chronological sorting. The `INDEX.md` table remains
the canonical source for issue ordering and status; file listings are
supplementary. Merge conflicts on `INDEX.md` table rows are still possible but
the instructions embedded in the file tell the resolver to keep all rows from
both branches.

---

### ADR-006: Three-Occurrence Promotion Threshold

**Context.**
The auto-improve loop detects patterns -- errors, API changes, workarounds -- and
promotes confirmed patterns to persistent knowledge (skills or memory files).
A threshold is needed to separate genuine patterns from noise.

**Options considered.**

A. Promote on first occurrence. Would flood the skill and memory system with
every minor observation. Most one-off issues are not worth encoding permanently.

B. Promote on second occurrence. Still too aggressive. Two occurrences could be
coincidence, especially if they happen in the same session.

C. Promote on third occurrence. The standard heuristic in scientific and
engineering contexts: one is an anecdote, two is a coincidence, three is a
pattern.

**Decision.**
Promote issues to skills or memory after three confirmed occurrences across
sessions. Use a tiered certainty scale: low (1 occurrence), medium (2
occurrences), high (3 or more occurrences). Only high-certainty issues are
eligible for promotion.

**Rationale.**
Three occurrences strikes the balance between sensitivity and specificity. It
filters out one-off bugs that happen to look similar (false positives) while
capturing genuine recurring problems before they waste too much developer time.
The tiered scale also provides visibility: a medium-certainty issue is a
warning flag that the agent can mention to the developer without taking action.

**Consequences.**
A genuine pattern must occur three times before it is promoted. This means the
first two occurrences still cost tokens and developer time. However, the
alternative -- promoting prematurely -- would pollute the skill system with
noise, making skills less trustworthy and ultimately less useful. The
auto-improve skill's Phase 5 periodic cleanup automatically discards low-
certainty issues older than 30 days, preventing the registry from accumulating
stale single-occurrence entries.

---

### ADR-007: Category-Based Promotion Routing

**Context.**
When an issue reaches promotion threshold, the system must decide where to
store the resulting knowledge. Different types of knowledge belong in different
locations: a PowerShell pitfall should extend the powershell-patterns skill; a
library API version change should go into user memory; a project-specific quirk
should go into repo memory.

**Options considered.**

A. Promote everything to a single knowledge file. Simple but creates a
monolithic, hard-to-navigate document. Defeats the progressive disclosure
principle.

B. Let the agent decide ad-hoc where to put each promoted issue. Flexible but
inconsistent. Different agents or sessions might make different choices for the
same type of issue.

C. Define a routing table keyed by issue category. Each category maps to a
specific promotion target. The agent follows the table, ensuring consistency
across sessions and agents.

**Decision.**
Use a category routing table in `INDEX.md` that maps each issue category to a
promotion target. Categories include `library-api`, `powershell`, `angular`,
`git`, `skill-creation`, `project-specific`, and `unknown`. The routing table is co-located with
the issue index so it can evolve alongside the issue corpus.

**Rationale.**
Explicit routing rules make promotion behavior predictable and auditable. A
developer can look at the table and understand exactly where each type of
knowledge will end up. New categories can be added by extending the table. The
`unknown` category acts as a safety valve: issues that do not fit any known
category stay in the open state until their category is clarified.

**Consequences.**
The routing table must be maintained. If a new category of issue emerges (for
example, `docker` or `kubernetes`), the table needs a new row. This is an
intentional friction point: it forces a conscious decision about where new
knowledge types belong, rather than allowing ad-hoc scattering.

---

### ADR-008: Minimal .gitignore Footprint

**Context.**
prompt-forge ships with a `.gitignore` file that is copied into the host
project. An overly broad `.gitignore` would interfere with the host project's
own ignore rules. An empty `.gitignore` would cause prompt-forge's session logs
to be accidentally committed.

**Options considered.**

A. Comprehensive `.gitignore` covering common build artifacts, dependencies,
and IDE files for all popular tech stacks. Would conflict with host project
conventions and potentially mask files the host project intentionally tracks.

B. No `.gitignore` at all. Would force every user to manually add the
`.prompt-forge/` entry. Friction on setup, and some users would forget.

C. Minimal `.gitignore` covering only prompt-forge's own runtime artifacts
(the `.prompt-forge/` logs directory). The user merges this with their existing
`.gitignore` or replaces it if the project has none.

**Decision.**
Ship a `.gitignore` that contains only the `.prompt-forge/` entry, with a
comment explaining that the host project should maintain its own ignore rules
separately.

**Rationale.**
This is the only option that satisfies Principle 2 (host-project safety). The
comment educates the user about the intended usage pattern. The single entry
is trivially auditable and mergeable.

**Consequences.**
Users with existing `.gitignore` files must manually add the entry or replace
their file. The README documents this explicitly. The trade-off of a small
setup burden is worth the guarantee that prompt-forge never accidentally
excludes files the host project needs.

---

### ADR-009: Six Curated Skills

**Context.**
The toolkit needs an initial set of skills that demonstrate value. Too few
skills would make the toolkit feel empty. Too many would increase the
discovery token cost (each skill costs ~100 tokens for its frontmatter) and
create maintenance burden.

**Options considered.**

A. Single monolithic instruction file. No discovery overhead, but no
progressive disclosure either. The full instruction set would be loaded into
every conversation regardless of relevance.

B. Dozens of specialized skills covering every imaginable scenario. High
discovery cost and maintenance burden. Most skills would rarely trigger.

C. A small set of skills covering the most common failure modes of AI coding
agents: codebase exploration (reading too many files), Git operations
(incorrect commit formats, bad branching), PowerShell on Windows (chaining
with &&, template escaping), session management (not learning from past
sessions), and cost awareness (not tracking token spend).

**Decision.**
Ship six skills: auto-improve, explore-codebase, git-workflow,
powershell-patterns, skill-creator, and track-tokens.

**Rationale.**
These six skills address the areas where AI coding agents most frequently
need guidance. Explore-codebase saves tokens by teaching efficient search
strategies. Git-workflow enforces Conventional Commits and atomic commits.
PowerShell-patterns prevents the most common Windows scripting errors.
Skill-creator enables the auto-improve loop to create new skills when patterns
are promoted, and helps developers add skills manually. Track-tokens gives
visibility into costs. Auto-improve ties them together by learning from each
session. The total discovery overhead is approximately 600 tokens (six
frontmatter blocks), which is negligible.

**Consequences.**
Areas not covered by these six skills (e.g., Docker, Kubernetes, specific
testing frameworks) rely on the auto-improve loop to eventually generate new
skills or memory entries when patterns emerge. The skill-creator skill ensures
that when promotion targets a new skill, the creation follows the
agentskills.io spec and prompt-forge conventions consistently. This is
intentional: the toolkit starts lean and grows organically based on actual
usage, rather than trying to anticipate every need upfront.

---

### ADR-010: YAML Frontmatter as the Extension Point

**Context.**
The skill format needs to evolve over time. New fields may be added to support
new features (source attribution, version tracking, compatibility hints).
Changes must not break existing skills or require migration scripts.

**Options considered.**

A. Fixed schema with required fields. Rigid; adding a field requires updating
all existing skills simultaneously.

B. Separate metadata files (one JSON file per skill directory). Decouples
metadata from content but adds file management complexity.

C. Extensible YAML frontmatter with required and optional fields. The core
fields (name, description) are required; all others are optional and ignored
by parsers that do not recognize them.

**Decision.**
Use YAML frontmatter with only `name` and `description` as required fields.
All other fields (`license`, `metadata`, `disable-model-invocation`, `url`,
`sources`, `tokens`, `version`) are optional. The `metadata` block itself is
a nested optional namespace for extended attributes.

**Rationale.**
This is the standard pattern for static site generators (Jekyll, Hugo) and
has proven robust over decades. Parsers that do not understand a field simply
ignore it. New fields can be added to individual skills without updating all
skills in lockstep. The `metadata` namespace provides a second level of
organization for fields that are not part of the core agentskills.io spec
but are useful for prompt-forge's own operation.

**Consequences.**
The frontmatter format has no schema validation. A typo in a field name
creates a silently ignored field rather than an error. This is mitigated by
keeping the frontmatter minimal and reviewing skill files during normal code
review. The `tokens` field, in particular, should be verified periodically
using a character-counting script as described in the maintenance section
below.

---

### ADR-011: Provider-Specific Distribution Packages

**Context.**
Different AI coding agents discover skills and instructions from different
paths. GitHub Copilot loads skills from `.github/skills/` and instructions from
`copilot-instructions.md` or `.instructions.md` files. Claude Code loads skills
from `.claude/skills/` and instructions from `CLAUDE.md` at the project root.
Third-party model providers (DeepSeek V4 via extensions, OpenRouter) may not
support `copilot-instructions.md` at all but do support `.instructions.md`
files discovered by the VS Code agent host.

A single file layout cannot serve all three audiences without requiring the user
to understand these path differences and manually reorganize files after
installation, which violates the drop-in principle.

**Options considered.**

A. Single layout with documentation telling users to rearrange files per
provider. Low maintenance burden but poor user experience. Most users would
not read the documentation and would end up with skills in the wrong paths.

B. Separate Git branches per provider. Clean per-branch but impossible to
keep in sync. Changes to a skill would require three separate commits across
three branches.

C. Monorepo with duplicated skill copies in provider-specific `packages/`
directories, plus a synchronization script. Each package is a self-contained
drop-in: the user copies one directory and gets the correct file layout for
their provider. A PowerShell script keeps the copies in sync from a single
source of truth.

**Decision.**
Organize distribution into `packages/copilot/`, `packages/claude/`, and
`packages/custom/`, each containing a full copy of the skills and the
appropriate instruction files for that provider. Use `.github/skills/` and
`.github/instructions/` at the project root as the source of truth. Provide a
`sync-skills.ps1` script that copies changes from the source of truth to all
packages.

**Rationale.**
The user experience is the overriding factor. A developer using Claude Code
should copy `packages/claude/*` and have everything work without reading about
VS Code discovery paths. The maintenance cost of triplicated skill files is
paid by the prompt-forge maintainer, not by every user. The synchronization
script eliminates the risk of manual copy errors. Provider-specific
instruction files (`CLAUDE.md`) are maintained directly in their package
directory since they have no equivalent in other providers.

**Consequences.**
Adding or editing a skill requires running `sync-skills.ps1` after the change.
Forgetting to run the script leaves packages out of sync, which is detectable
by comparing file hashes. The three packages are identical copies for skills
and shared instructions; only the instruction file format and skill directory
path differ per provider. The `.gitkeep` files in `knowledge/issues/`
subdirectories must also be duplicated to ensure Git preserves empty
directories in each package.

---

## Component Architecture

### Skill System

Each skill is a self-contained directory under `.github/skills/<name>/`
containing exactly one `SKILL.md` file. The directory structure allows future
extension: a skill could add supplementary files (examples, templates,
references) without changing the core format.

The `SKILL.md` file has two parts. The YAML frontmatter block between `---`
delimiters contains structured metadata. The Markdown body after the second
`---` contains the instructions the agent follows when the skill is triggered.

The frontmatter schema used by prompt-forge extends the base agentskills.io
schema with additional fields:

```
Field                   Required    Purpose
name                    Yes         Machine-readable skill identifier
description             Yes         Natural-language trigger conditions
license                 No          SPDX license identifier
disable-model-invocation No         If true, skill is only loaded on explicit user request
metadata.author         No          Skill author (GitHub username)
metadata.url            No          Canonical URL for the skill source
metadata.version        No          Semantic version of the skill
metadata.tokens         No          Estimated token count of the body
metadata.sources        No          Comma-separated list of reference URLs
```

### Issue Registry

The issue registry uses a flat-file structure under `knowledge/issues/`. The
entry point is `INDEX.md`, which maintains three tables (Open, Promoted,
Discarded) and a summary count. Individual issue files live in the `open/`,
`promoted/`, or `discarded/` subdirectory corresponding to their status.

When an issue is promoted from open to promoted, the file is physically moved
from `open/` to `promoted/` and its frontmatter is updated. The `INDEX.md`
table is updated to reflect the move. The same process applies to discarding.

The promotion routing table in `INDEX.md` maps issue categories to promotion
targets. This table is the single source of truth for where knowledge ends up.
It can be extended by editing `INDEX.md` directly.

### Session Tracking (Optional Subsystem)

The session tracking subsystem consists of two PowerShell scripts and the
`track-tokens` skill. The scripts are optional; the toolkit functions fully
without them.

`session-start.ps1` creates a JSON log file in `.prompt-forge/logs/` with
metadata about the session start (timestamp, hostname, user, working directory).
It exports a session ID as an environment variable.

`session-end.ps1` reads the session ID from the environment, calculates cost
based on token counts and provider pricing, updates the session log file, and
appends to a cumulative JSONL log. It prints a formatted report to the console.

The `track-tokens` skill provides an alternative path: it queries VS Code's
internal session store directly, which works cross-platform and does not require
PowerShell. It also provides the estimation logic when exact token counts are
unavailable.

---

## Data Flow: The Auto-Improve Cycle

A complete auto-improve cycle spans three phases:

**Phase 1: Detection (during session).**
As the developer works, the AI agent encounters errors, discovers API changes,
or finds workarounds. The agent notes these mentally. The base skills
(explore-codebase, git-workflow, powershell-patterns) provide immediate
guidance to resolve the current problem.

**Phase 2: Recording (end of session).**
When the developer ends the session or explicitly invokes auto-improve, the
skill scans the conversation for signals. Each signal is cross-referenced with
existing issues in `open/`. New signals create new issue files. Existing signals
increment occurrence counts and update certainty levels.

**Phase 3: Promotion (any session).**
When an issue reaches three occurrences, the auto-improve skill evaluates it
against the promotion criteria. If the category has a routing target, the issue
is promoted: the issue file moves to `promoted/`, and the knowledge is encoded
in the target location (a skill file, a memory file, or a repo note).

The cycle is intentionally asynchronous. Detection and recording can happen in
different sessions. Promotion can happen days or weeks after the first
occurrence. This decoupling means the system does not need to be "always on";
it accumulates knowledge passively as developers work normally.

---

## Token Economics

The token cost of prompt-forge breaks down into three components:

```
Component                  Token cost          When incurred
Skill discovery            5 x ~100 = ~500     Start of every session
Skill body (if triggered)  ~500-1,500 each     On first trigger per session
Auto-improve scan          Variable            End of session (explicit)
```

The discovery cost of 500 tokens is a fixed overhead per session. In a session
that consumes 50,000 input tokens, this represents 1% overhead. If the
auto-improve skill runs at session end, it scans the full conversation, which
may cost several thousand additional tokens. However, this cost is amortized
across future sessions that benefit from the promoted knowledge.

The explore-codebase skill saves tokens by teaching the agent to use strategic
search instead of sequential file reading. The skill's own documentation
estimates a 91% reduction in exploration tokens. Even conservatively assuming
a 50% reduction, the skill pays for itself within one or two sessions.

---

## Multi-Developer Considerations

The UUID-based issue ID scheme (ADR-005) eliminates filename collisions between
developers. Two developers can create new issues simultaneously without
coordination.

The `INDEX.md` table remains a potential merge conflict point. When Developer A
and Developer B both add rows to the Open Issues table in separate branches,
Git will flag a conflict on merge. The resolution instructions embedded in
`INDEX.md` guide the resolver: keep all rows from both branches and re-count
the directories to update summary numbers. This is a manual step but a trivial
one.

Skill files are modified less frequently than `INDEX.md`, but the same merge
logic applies. When auto-improve promotes an issue to a skill, it uses
`replace_string_in_file` to add a new section. If two developers promote to the
same skill simultaneously, the second promotion will see a stale file and need
to re-read before editing. The auto-improve skill instructs the agent to always
read the current file state before editing, which mitigates but does not
eliminate this race condition.

---

## Security Considerations

prompt-forge does not handle secrets, credentials, or user data. The session
tracking scripts log the current working directory path and the Windows
username, which could be considered sensitive in some environments. The log
files are written to `.prompt-forge/logs/`, which is excluded from version
control by the shipped `.gitignore`. Users in high-security environments should
audit the scripts before use.

The skills instruct the AI agent to read, write, and edit files within the
project. This is the agent's normal mode of operation; the skills do not grant
any additional capabilities. No skill instructs the agent to make network
requests or execute code outside the project boundary.

---

## Known Limitations

**Platform dependency.**
The PowerShell session tracking scripts require Windows with PowerShell 5.1 or
PowerShell Core on macOS/Linux. The core skills and issue registry are
platform-independent.

**No concurrent write safety.**
The filesystem-based issue registry has no locking mechanism. Two agents
writing to `INDEX.md` simultaneously in the same working copy will produce a
write conflict at the filesystem level. In practice, AI coding sessions are
serial per developer, so this is unlikely to occur. The merge-time conflict
resolution instructions handle the Git-level case.

**No automated issue deduplication.**
The auto-improve skill uses keyword overlap and category matching to detect
duplicate issues, but this is heuristic. Two issues describing the same
underlying problem with different wording may be created as separate files.
Manual deduplication during code review is the safety net.

**Token estimates are approximate.**
The `tokens` field in skill frontmatter uses the 4-characters-per-token
estimate, which varies by model and tokenizer. Actual token counts may differ
by 10-20%. The field is intended as a relative comparison tool, not an
accounting-grade measurement.

---

## Maintenance

**Verifying token metadata.**
Run the following command from the project root to compare declared token
counts with actual character counts:

```powershell
Get-ChildItem .github/skills/*/SKILL.md | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $parts = $content -split '---', 3
    $chars = $parts[2].Length
    $est = [Math]::Round($chars / 4)
    $declared = ($content -split "`n" | Select-String 'tokens:').ToString().Trim()
    Write-Host "$($_.Directory.Name): $chars chars = ~$est tokens | $declared"
}
```

**Adding a new skill.**
Create a directory under `.github/skills/<name>/` with a `SKILL.md` file.
Follow the frontmatter schema documented above. Add the skill's trigger
description. Measure the body token count using the script above and set the
`tokens` field. The skill will be discovered automatically by the agent on
the next session.

**Adding a new promotion category.**
Edit the category routing table in `knowledge/issues/INDEX.md`. Add a row
mapping the new category to its promotion target. If the target is a new skill,
create the skill first.

---

## References

- Architectural Decision Records: https://adr.github.io/
- MADR (Markdown Architectural Decision Records): https://adr.github.io/madr/
- agentskills.io standard: https://agentskills.io
- Conventional Commits v1.0.0: https://www.conventionalcommits.org/
- Prompt caching (Anthropic): https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching
- Context window documentation (OpenAI): https://platform.openai.com/docs/models
