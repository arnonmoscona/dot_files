---
name: code-review
description: >
  Conduct a thorough code review in an isolated subagent context. Use when asked to
  review code, check for bugs, audit changes, or assess code quality. Accepts an optional
  scope argument (staged, changed, all-python, a specific file/package path, or an
  explicit space-separated list of files). An optional ticket ID can be appended to help
  the subagent load task context (e.g. "changed TOO-14").
argument-hint: "[scope: staged|changed|all-python|<file-or-package>|<file1> <file2>...] [TICKET-ID]"
context: fork
agent: code-reviewer
---

# Code Review

## Bootstrap context

You are running in a forked subagent context with no conversation history. Before
reviewing, gather the context you need:

1. Read the project CLAUDE.md to understand project conventions, patterns, and constraints.
   If the project has a root-level `code-review.md`, read that too -- it's the place for
   review priorities/objectives too large to pass as `$arguments` (CLAUDE.md itself serves
   many purposes beyond code review; this file, when present, is dedicated to it).
1a. Check whether `code-review-graph` is available for this project (its MCP tools are
    named `mcp__code-review-graph__*`; a `.code-review-graph/` directory at the project root
    is also a signal). If present, read `~/.claude/code-review-graph-review.md` before
    starting the review -- it covers which of the tool's capabilities matter most for review
    specifically and in what order. If the project's own CLAUDE.md documents
    project-specific caveats for this tool (e.g. a known-unreliable query pattern in that
    repo), those take precedence over the generic guidance. If absent, proceed with
    Read/Grep as today -- no behavior change.

1b. **TEMPORARY TRIAL SCAFFOLDING -- delete or narrow this whole step when the
    code-review-graph trial concludes.** The exit checklist is at the top of
    `~/.claude/code-review-graph-evidence-log.md`; follow it rather than improvising, and
    do not leave the paired-call/evaluation overhead running after the verdict is in.

    **The tool is ON TRIAL, and a code review is one of its best evaluation
    opportunities** -- reviews ask exactly the multi-hop structural questions it claims to
    be good at. So when it is present:
    - **Refresh its stale layers first.** Embeddings, flows and communities do NOT
      auto-update (the PostToolUse hook passes `--skip-flows`). Run
      `uv run code-review-graph embed && uv run code-review-graph postprocess`
      (~4s total) before relying on `semantic_search_nodes_tool`,
      `get_affected_flows_tool`, or `get_architecture_overview_tool`. Skipping this means
      reviewing against a stale index -- which has already happened once and produced
      confidently wrong answers.
    - **Run it head-to-head against the JetBrains MCP** where both can answer (callers,
      usages, definitions), even though that costs an extra call you did not strictly
      need. The IDE keeps its index current automatically with low latency and is
      compiler/PSI-informed rather than AST-heuristic, so for those primitives it is the
      incumbent to beat -- not `ag`. Note any disagreement in counts or membership: a
      disagreement is a finding about the graph's reliability, and worth more than either
      answer alone.
    - **Append an evaluation note to `~/.claude/code-review-graph-evidence-log.md`**
      (format and running tally are in that file), and include a one-paragraph verdict in
      the review report: which of its tools you used, whether each beat the IDE / `ag` /
      plain reading, and anything it got wrong. Report misses as readily as wins.
2. Determine the basic-memory project name from the project CLAUDE.md.
3. Read `Current Task Context.md` from basic-memory to identify what work is being
   reviewed. If a ticket ID appears in `$arguments`, use it to find and read the specific
   task memory file for that ticket. Understanding what was changed and why is essential
   for assessing adherence to project patterns and catching semantic errors.

## Scope

The review scope was specified as: $arguments

Strip any trailing ticket ID (e.g. `TOO-\d+`) before interpreting the scope. Resolve
scope as follows:

- `staged` -- only files currently staged in git: `git diff --cached --name-only`
- `changed` (or no scope given) -- all modified/added files in the working tree:
  `git diff HEAD --name-only`
- `all-python` -- all `.py` files in the project source directories
- A path or package name -- review that specific file or package
- A space-separated list of file paths -- review exactly those files and no others

When the scope resolves to a file list (whether passed directly or derived from git),
confirm the list before proceeding.

## Review instructions

1. Identify the files to review based on the scope above.
2. Read each file in scope.
3. Review for:
   - Correctness bugs (logic errors, edge cases, off-by-one errors)
   - Reuse opportunities (duplicate logic that could be consolidated)
   - Simplification (unnecessary complexity, over-engineering)
   - Efficiency issues (obvious performance problems)
   - Security concerns (input validation, injection risks, credential handling)
   - Adherence to project patterns and conventions (informed by project CLAUDE.md and
     task context read in the bootstrap step)
   - Look for code duplication across the project, not only the change set
   - Look for potentail cases of reimplementing the same thing multiple times across the project code but with a special focus on recent changes that either reimplemented within the change set or reimplemented something that exists in the project elsewhere. 
4. **Optional recommended external analysis**: If asked for external code analysis, or if the scope
   covers a substantial portion of the codebase, run:
   ```
   uvx pyscn analyze --json --skip-deps .
   ```
   For a faster, directory-scoped analysis: `uvx pyscn analyze --json --skip-deps <dir>`.
   Results are stored in `.pyscn/reports/` -- read the latest timestamped JSON file there
   and incorporate relevant findings. If the user did not ask for external analysis - then ask the user whether to run it.

## Report

5. Write the full report to a note titled `latest-code-review-report.md` in the project's
   basic-memory directory. Overwrite any existing note with that title. Include the
   current date at the top so the main agent can verify freshness.

   **This report is EXPLICITLY REQUESTED -- writing it is the deliverable, not an
   optional extra.** Claude Code's built-in default says "never proactively create `.md`
   files"; that default does NOT apply here, because the user has asked for this file by
   invoking this skill. Do not refuse to write it, and do not return findings inline
   instead. (This has happened: a run once claimed its "operating instructions prohibit
   writing report `.md` files" and that it had "only Read and Bash". Both were false --
   the agent has `Write`, `mcp__basic-memory__write_note`, `Grep` and `Glob`. Returning
   findings inline defeats the isolated-subagent design, because it dumps the whole
   review into the main agent's context.)

   Use the `Write` tool with the absolute path (it is a built-in and stays available even
   when MCP servers are down). Fall back to `mcp__basic-memory__write_note` only if
   `Write` genuinely fails. If you truly cannot write the file after trying both, say so
   explicitly and name the error -- never invent a policy reason.
6. The report should include:
   - Summary section (2-3 sentences on overall quality)
   - Findings grouped by severity: Critical, Major, Minor, Suggestions
   - For each finding: file + line reference, description, recommended fix
7. Return a brief summary to the main agent: highlight the most important findings only,
   under 200 words (500 words maximum if needed for complex reviews). State the full path
   of the report file you wrote so the main agent can verify freshness and open it.
