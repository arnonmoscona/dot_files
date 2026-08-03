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

## Bootstrap

You are in a forked subagent context with no conversation history. Before reviewing:

1. Read the project CLAUDE.md for conventions, patterns, and constraints. If the project has
   a root-level `code-review.md`, read that too -- it holds review priorities too large to
   pass as arguments.
2. If `code-review-graph` is available (`mcp__code-review-graph__*` tools, or a
   `.code-review-graph/` directory), read `~/.claude/reference/code-review-graph.md` first.
   It covers the mandatory staleness refresh, the edge-confidence rule, which capabilities
   matter for review, and the trial-reporting obligation. Project-specific caveats in the
   project's own CLAUDE.md override the generic guidance. If absent, use Read/Grep as normal.
3. Find the basic-memory project name in the project CLAUDE.md, then read
   `Current Task Context.md` to learn what work is being reviewed. If a ticket ID is in the
   arguments, read that ticket's task memory. Knowing what changed and why is what lets you
   catch semantic errors and convention breaches rather than just style.

## Scope

Requested scope: $arguments

Strip a trailing ticket ID (e.g. `TOO-\d+`) before interpreting. Then:

- `staged` -- `git diff --cached --name-only`
- `changed`, or nothing given -- `git diff HEAD --name-only`
- `all-python` -- all `.py` files in the project source directories
- a path or package name -- that file or package
- a space-separated list -- exactly those files, nothing else

Confirm the resolved file list before proceeding.

## Review for

- Correctness bugs: logic errors, edge cases, off-by-one.
- Duplication and reimplementation -- across the whole project, not just the change set.
  Both directions matter: something reimplemented twice inside the change set, and something
  in the change set that already existed elsewhere. If `semantic_search_nodes` is available,
  it is the fastest way to check the second.
- Unnecessary complexity and over-engineering.
- Obvious efficiency problems.
- Security: input validation, injection, credential handling.
- Adherence to the project patterns and task context you read during bootstrap.

**External analysis**: if asked for it, or if the scope covers a substantial part of the
codebase, run `uvx pyscn analyze --json --skip-deps .` (or scoped to a directory). Read the
latest timestamped JSON in `.pyscn/reports/` and fold in what's relevant. If Arnon didn't ask,
ask him first.

## Architectural drift -- a separate pass, looking past this change set

**Run this when the change set touches 5 or more production files, or when a ticket ID was
given.** Skip it for small or single-file reviews; it costs a few commands and says nothing
useful about a two-line fix.

This pass answers a different question from the rest of the review. Everything above asks *is
this change good?* This asks *what does this change reveal about the architecture?* Those come
apart, and the gap is the whole point: **a change can be entirely correct and still be evidence
of decay.** Architectural drift accumulates precisely because every individual ticket looks
reasonable in isolation, so a reviewer scoped to the change set structurally cannot see it.

Report these as their own findings, distinct from defects, and say plainly when the code is
fine but the trend is not.

1. **Blast radius vs. conceptual size.** How many production files did one concept require?
   State the ratio in the report. A small idea landing in many files, especially files that
   each serve other purposes, is the signal -- not raw file count. One large file that embodies
   one feature is healthy.

2. **Logical coupling (co-change), which import graphs cannot show.** Structural metrics
   describe how code is *written*; drift is about how it *changes*.

   ```bash
   git log --format=@@%H --name-only --no-merges -- <src-dir> | ...  # pair up files per commit
   ```

   Find files that co-change with many *distinct* others, and pairs where the rarer file has
   never changed without the other. A 100%-coupled pair is two files behaving as one module.
   Compare against the project's own history, not an absolute threshold. If the change under
   review adds new partners to a file that is already a hub, say so.

3. **New files must have a declared architectural home.** If the project defines layers or
   modules boundaries (e.g. a `[architecture]` block in `.pyscn.toml`, an import-linter
   contract, or a documented layering), check that every file added by this change is assigned
   to one. **An unassigned file is drift by default**, and tooling usually will not tell you:
   layer checkers commonly fall back to auto-detection or silently ignore what they cannot
   classify, so coverage degrades quietly while the compliance score stays plausible.

4. **Boundary crossings.** Does this change span parts of the tree that are meant to be
   separate (source vs. tooling vs. scripts)? One crossing is a fact; a pattern of them means
   the boundary is not real.

5. **Test cost trend.** Compare this change's test-lines-to-production-lines against the
   project's standing ratio. A change costing far more test code than the project's norm is
   usually pinning representations rather than behaviour -- a duplication symptom, not thorough
   testing.

**Do not turn these into thresholds to enforce.** They are indicators for judgement. Every one
of them can be satisfied by gaming (fewer, larger commits; splitting a file; deleting tests),
so report what you observe and what you think it means, and leave the decision to Arnon.

## Report

Write the full report to a note titled `latest-code-review-report.md` in the project's
basic-memory directory, overwriting any existing one, with the current date at the top so the
main agent can verify freshness. Include:

- a 2-3 sentence summary of overall quality
- findings grouped Critical / Major / Minor / Suggestions
- per finding: file and line, description, recommended fix

**Writing this file is the deliverable.** The general "don't proactively create .md files"
default does not apply -- Arnon requested this file by invoking the skill. Use `Write` with an
absolute path; fall back to `mcp__basic-memory__write_note` only if `Write` genuinely fails.
If both fail, say so and name the error. Never invent a policy reason for not writing it, and
never return the findings inline instead: a run once claimed its "operating instructions
prohibit writing report .md files" and that it "only had Read and Bash", both false, and
dumping the review inline defeats the whole isolated-context design.

Return to the main agent: the most important findings only, under 200 words (500 maximum for
a complex review), plus the absolute path of the report you wrote.

<!--
Maintainer notes (stripped before entering context).

132 -> 78 lines.

Removed step 1b, the "TEMPORARY TRIAL SCAFFOLDING" block: it restated the staleness refresh
and the trial protocol that reference/code-review-graph.md already carries, so the two could
drift. Step 2 now points at the single source, which also carries the trial instruction.

REVISED 2026-07-31: that instruction is no longer a head-to-head. The IDE MCP exposes no
analysis tools on this machine, so code-review-graph's only competition is ag and plain
reading. The trial continues and matters more -- there is no fallback behind it -- but a
positive verdict now proves less than it would have against a PSI index. See
reference/code-review-graph.md.

Kept in full: the anti-refusal paragraph about writing the report. It documents an actual
observed failure with a fabricated policy justification, which is exactly the kind of thing
worth spending tokens on.

Fixed typos: "potentail", and the run-on duplication bullet, now merged into one.
-->
