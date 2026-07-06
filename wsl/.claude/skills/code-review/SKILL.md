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

5. Write the full report to a basic-memory note titled `latest-code-review-report.md` in
   the project's memory. Overwrite any existing note with that title. Include the current
   date at the top so the main agent can verify freshness.
6. The report should include:
   - Summary section (2-3 sentences on overall quality)
   - Findings grouped by severity: Critical, Major, Minor, Suggestions
   - For each finding: file + line reference, description, recommended fix
7. Return a brief summary to the main agent: highlight the most important findings only,
   under 200 words (500 words maximum if needed for complex reviews). State the full path
   of the report file you wrote so the main agent can verify freshness and open it.
