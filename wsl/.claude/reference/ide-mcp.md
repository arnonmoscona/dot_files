# JetBrains IDE MCP: capabilities, recipes, and drift

Read this when doing non-trivial structural analysis with the IDE, or when running a
lane comparison. Not loaded at launch.

**Why this file gets its own space.** The IDE holds the best model of the code available to
us -- a real compiler/PSI index, kept current automatically with low latency. Its *potential*
precision is far above `ag` or any AST-heuristic graph. But its MCP surface changes with IDE
and plugin releases, and **the published docs run ahead of what a given build ships.** So the
capability inventory has to be treated as a measured fact with a date on it, not as
documentation. Everything below is measured.

## Current state (measured 2026-07-29)

| | |
|---|---|
| Server | `IntelliJ IDEA MCP Server` **2026.1.3** |
| Registration | user scope, key `jetbrains`, SSE `http://127.0.0.1:64342/sse` |
| Backend | JetBrains Remote Development (`remote-dev-serv`) |
| Tools advertised | **56** |
| MCP protocol | `2024-11-05` |

Re-measure with `uv run python ~/.claude/tools/ide_mcp_capabilities.py --verbose`; see
*Drift* below. Never restate the inventory from memory -- ask the script.

### Capability shape, in one pass

* **Semantic, read-only**: `search_symbol` (declaration index), `get_symbol_info` (resolve at
  a position), `get_file_problems` (inspections).
* **Semantic, write**: `rename_refactoring` -- reference-aware across the project.
* **Text/regex** (fast, IDE-indexed, *not* semantic): `search_text`, `search_regex`,
  `search_in_files_by_text`, `search_in_files_by_regex`.
* **Files**: `search_file`, `find_files_by_glob`, `find_files_by_name_keyword`,
  `list_directory_tree`, `read_file`, `get_file_text_by_path`.
* **Project/build/run**: `get_project_modules`, `get_project_dependencies`, `build_project`,
  `execute_run_configuration`, `get_run_configurations`, `get_repositories`.
* **Debugger** (16 `xdebug_*` tools): live stacks, frame values, breakpoints, expression
  evaluation. Largely unexplored by us -- see *Open questions*.
* **Inspections-as-code**: `run_inspection_kts`, `generate_inspection_kts_api`,
  `validate_inspection_kts`. **Java/Kotlin only** -- the API tool accepts no other language,
  and it NPE'd on a trivial script against a `.py` file. Not a Python route.
* **Database** (9 tools) and notebooks (`runNotebookCell`).

### What is missing, and what that costs

* **No `analyze_calls`** in this build, despite JetBrains documenting it and despite this
  server's own `search_symbol` description telling you to use it. Verified at the protocol
  level, not merely absent from the client registry.
* **No Find Usages / references tool** under any name (`find_usages`, `get_usages`,
  `search_usages`, `find_references` all absent).
* **No type hierarchy**, no file-outline tool.

`rename_refactoring` proves the reference engine *is* in the build -- it's simply not exposed
read-only. So this is a plugin-surface omission, plausibly fixed by an update, and worth
re-checking on every drift review rather than treated as permanent.

## Verified recipes

### `search_symbol` -- Go to Symbol, not Find Usages

A fragment-matching index over **declarations**. It cannot return callers: a call is a
reference, not a declaration. Measured: `q="find_project_root"` -> **2** hits (the two
declarations) against **33** textual occurrences in 11 files.

* **Fragment matching is broad and truncating.** `q="project_root"` -> 25 hits, `more: true`,
  mixing whole *modules* (`tools/project_root.py`, span 1-63), test methods whose names
  contain the fragment, and an incidental `self.project_root = None` in a test fake. Narrow
  with `paths`.
* **Output is coordinates only** -- no name, kind, or signature. Identifying a hit needs a
  follow-up `get_symbol_info`.
* **GOTCHA: spans start at the enclosing qualified expression, not the matched name.** For
  `self.project_root = None` the span starts on `self`, so
  `get_symbol_info(line, startColumn)` returns **`self`**. Offsetting onto the name
  (col 13 -> 18) returns `project_root`. Feeding `startColumn` straight in silently resolves
  the wrong symbol. The retired `intellij-mcp` guidance flagged this same class of error
  ("the column on the name, not column 1"); it survived the server change, so assume it
  survives the next one.

Two jobs it is genuinely good at:

* **Exact declaration spans.** `config.py:211-240` is precisely `find_project_root`'s extent
  (240 is its `return`). Makes the *callees* direction clean -- take the body range, resolve
  each call inside it, no boundary guessing.
* **Cheap duplicate-implementation detection.** One call surfaced `find_project_root` in both
  `config.py` and `env_config.py` plus `resolve_project_root` in `path_utils.py`.

### Resolve-verified callers (the `analyze_calls` substitute)

No single tool replaces it, but two compose into genuine resolution -- verified on Python:

1. `search_regex(q="target_fn\\(", paths=[...])` -> candidates **with coordinates on the
   identifier**. Use this, **not** `search_symbol`, because of the span gotcha above.
2. `get_symbol_info(filePath, line, column)` per candidate -> the **resolved**
   `declarationFile` / `declarationLine`. Keep matches; discard the rest.

Proof it disambiguates: two `find_project_root` declarations exist; call sites at
`log_writer.py:105` and `decision_ledger.py:268` both resolved to `config.py:211`.

* **Fixes**: same-name false positives, attribute-style `module.fn(`, import-line handling.
* **Does not fix**: aliased imports (`import fn as gf` never yields a candidate in step 1),
  dynamic dispatch, `getattr`.
* **Is not**: a hierarchy. One level, on candidates you enumerated. Cost is N+1 calls
  (~33 for `find_project_root`), so scope with `paths`.

**Never** use a `rename_refactoring` round-trip to enumerate references. It would catch
aliases, but it mutates the working tree to answer a read-only question, and Arnon owns all
write operations.

## Three-lane comparison protocol

For the ongoing evaluation, a result is only interpretable if the lanes were given a fair
shot and something independent arbitrates disagreement.

- [ ] **State the question precisely** and in a form all three lanes can answer (e.g. "every
      call site of `toolguard.config.find_project_root`").
- [ ] **Refresh `code-review-graph` FIRST**: `uv run code-review-graph embed && uv run
      code-review-graph postprocess`. Non-negotiable. An unrefreshed graph produces a
      *staleness* result mislabelled as an *accuracy* result, and we have at least one past
      comparison where it is unclear whether this was done -- which is why those findings
      can't be leaned on.
- [ ] **Record the IDE server version** from the capability snapshot, so a later re-run knows
      whether it is comparing like with like.
- [ ] **Run all three**: CLI (`ag`/AST), IDE MCP (recipe above), graph (`callers_of`).
- [ ] **Record counts AND membership**, not just counts. Two lanes agreeing on "6" while
      disagreeing on *which* 6 is the interesting case and a count-only note destroys it.
- [ ] **Arbitrate with the oracle, not by majority.** See below.
- [ ] **Classify each miss**: stale index, heuristic resolution error, text blind spot
      (alias/attribute/dynamic), or a badly-shaped query. "It was wrong" without a cause is
      not usable evidence.
- [ ] **Append to `~/.claude/ide-mcp-evidence.md`** for IDE findings, and to
      `~/.claude/code-review-graph-evidence-log.md` for graph findings, so each accumulates
      where its running tally lives.

### The missing piece: a ground-truth oracle

Three lanes that disagree cannot resolve each other, and majority vote is not truth. For
Python we can build a real arbiter cheaply with stdlib `ast`: parse every module, track
`import` / `from ... import ... as ...` bindings per module scope, then walk `ast.Call` nodes
resolving each callee name through those bindings to a fully qualified target. That yields an
exact, reviewable enumeration -- including the aliased imports every other lane misses -- and
turns this from "they disagreed" into measurable precision and recall per lane.

**Not built yet, deliberately.** It is a real piece of work (scope/shadowing, `self.method()`
needing class resolution, decorators, re-exports) and half of it would be worse than none,
since a buggy oracle would silently corrupt every comparison. Recommended as the next step if
the evaluation continues; until it exists, arbitrate by direct reading and say so.

## Drift: how we stay current cheaply

Two layers, deliberately: a **mechanical** check for the tool surface, and a **human-triggered
review** for everything a tool list cannot see.

**1. Mechanical, exact, free.** `~/.claude/tools/ide_mcp_capabilities.py` connects over SSE,
pulls the authoritative `tools/list` plus `serverInfo.version`, snapshots it to
`~/.claude/ide-mcp/`, and diffs against the previous snapshot. It reports added and removed
tools, added/removed/newly-required parameters, description changes, and version changes.

```bash
uv run python ~/.claude/tools/ide_mcp_capabilities.py            # silent unless drift
uv run python ~/.claude/tools/ide_mcp_capabilities.py --verbose  # always summarize
uv run python ~/.claude/tools/ide_mcp_capabilities.py --list     # current tool names
uv run python ~/.claude/tools/ide_mcp_capabilities.py --show search_symbol   # full schema
```

It prints **nothing** when nothing changed, and exits 2 quietly when the IDE isn't running.
Deliberately **not** wired to a SessionStart hook: the cost of a hook is paid every session
forever, and drift is a once-a-few-weeks event. Run it during the review instead.

**2. Human-triggered review.** The trigger lives in auto-memory
(`project_jetbrains_mcp_ide_review_cadence`) with the last-review date. **When more than ~2
weeks have passed, remind Arnon** rather than checking silently -- he wants to decide when to
spend the time. The review is what catches what a tool list cannot: behaviour changes in
existing tools, newly *documented* capabilities, and recipes that quietly stopped working.

Review checklist, when triggered:

- [ ] Run the capability script; if it reports drift, follow its instruction.
- [ ] Re-test `analyze_calls` presence specifically -- it is the single highest-value gap.
- [ ] Re-verify the `search_symbol` span gotcha and the resolve-verified recipe still behave
      as documented above; correct this file if not, and date the correction.
- [ ] Re-read https://www.jetbrains.com/help/idea/mcp-server.html and diff it against the
      *measured* inventory. Where they disagree, the measurement wins and the disagreement is
      itself worth noting -- it has happened before.
- [ ] Note the IDE build (Settings | Tools | MCP Server, or the script's `serverInfo`).
- [ ] Update the cadence memory's date and anything learned.

## Open questions worth a cheap experiment

Recorded so they are not rediscovered from scratch:

* **`get_file_problems` as a correctness lane.** It runs real IntelliJ inspections. Could it
  substitute for, or strengthen, part of a code review? Untested.
* **The 16 `xdebug_*` tools.** A live debugger is a *dynamic* analysis lane none of the other
  tools offer -- it could resolve exactly the dynamic dispatch that defeats every static
  approach. Entirely unexplored.
* **`get_project_modules` / `get_project_dependencies`** for orientation, versus
  `get_architecture_overview` from the graph.
* **Whether the client registry ever lags the server's `tools/list`.** The script reads the
  server directly; Claude Code exposes what it negotiated at connect time. If those diverge, a
  tool can be "present" and still uncallable, so a restart is the fix rather than an update.

<!--
Maintainer notes (stripped before entering context).

NEW FILE, written 2026-07-29 in response to Arnon's point that the IDE has the best code model
available and its MCP story is evolving faster than its docs.

Deliberate design decisions:
  - The deep IDE material was MOVED here out of reference/search.md, not copied. search.md keeps
    lane selection and now points here. Duplicating it would have recreated the exact
    copy-then-drift failure that FINDINGS.md §3 is about.
  - No SessionStart hook. I built one and then dropped it on Arnon's push-back: a hook costs
    something every session forever to detect an event that happens every few weeks. The memory
    reminder is the trigger; the script is what runs when triggered. Cheaper AND more accurate,
    because the review is measured rather than recalled.
  - Every capability claim carries a measurement date and a way to re-measure. This file must
    never become a from-memory restatement of the docs -- that is the failure mode it exists to
    prevent.
  - The oracle is specified but NOT built. Half an oracle is worse than none: it would silently
    corrupt every comparison it arbitrated. Flagged as the next step instead.
-->
