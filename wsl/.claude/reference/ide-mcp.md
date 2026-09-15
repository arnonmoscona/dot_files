# JetBrains IDE MCP: capabilities, recipes, and drift

Read this when doing non-trivial structural analysis with the IDE, or when running a
lane comparison. Not loaded at launch.

**Why this file gets its own space.** The IDE holds the best model of the code available to
us -- a real compiler/PSI index, kept current automatically with low latency. Its *potential*
precision is far above `ag` or any AST-heuristic graph. But its MCP surface changes with IDE
and plugin releases, and **the published docs run ahead of what a given build ships.** So the
capability inventory has to be treated as a measured fact with a date on it, not as
documentation. Everything below is measured.

## Current state (measured 2026-09-09)

| | |
|---|---|
| Server | `IntelliJ IDEA MCP Server` **2026.2.2** (was 2026.2.1 GA, 2026.2.1 RC, 2026.1.3) |
| Registration | user scope, key `jetbrains`, SSE `http://127.0.0.1:64342/sse` |
| Backend | **Windows-native IDE over `\\wsl.localhost`** — no longer Remote Development |
| Tools advertised | **59** (was 60) |
| MCP protocol | `2024-11-05` |

**The backend changed and it is the single most disruptive fact here.** `pgrep -f remote-dev-serv`
finds nothing in WSL; the IDE runs on Windows and reaches the project over the 9p share. Every
tool call must now carry a `projectPath` in Windows UNC form -- see the next section, which is the
first thing to read.

### `projectPath` is mandatory, and the POSIX path does not work (measured 2026-08-25)

Nine variants tried against one fixed `search_file` query:

| value | result |
|---|---|
| *omitted* | **rejected** -- no auto-resolve, even with exactly one project open |
| `/home/arnon/projects/toolguard` | **rejected** |
| `\\wsl$\Ubuntu-26.04\home\arnon\projects\toolguard` | **rejected** |
| `//wsl$/Ubuntu-26.04/home/arnon/projects/toolguard` | **rejected** |
| `//wsl.localhost/Ubuntu/...` (distro alias) | **rejected** |
| `//wsl.localhost/Ubuntu-26.04/home/arnon/projects/toolguard` | works |
| same with backslashes, mixed slashes, `//WSL.Localhost/ubuntu-26.04/...`, trailing `/` | works |
| any **subdirectory** of the project | works -- resolves to the containing project |

So it normalizes slash direction and case, tolerates a trailing slash, and does containment
resolution from a subdirectory (an agent may pass its cwd). It does **not** resolve `wsl$` -- a
genuine Windows alias for the identical share -- nor the distro alias, nor the POSIX path.
**That pins the mechanism: a normalized string comparison against the registered project path, not
a filesystem resolution.** Same directory, wrong spelling, no match.

Do not hardcode the literal. It is derivable in-process, which generalizes to any project here:

```bash
//wsl.localhost/$WSL_DISTRO_NAME$PWD      # WSL_DISTRO_NAME=Ubuntu-26.04
```

Failure is loud and distinguishable: a bad `projectPath` says *"doesn't correspond to any open
project"* and lists the open ones. **That error is not a capability result** -- do not record a
tool as broken on the strength of it.

### Drift 2026-08-25 -> 2026-09-09, measured by the script

Version `2026.2.1` -> `2026.2.2`. **REMOVED (1):** `skill_search`. **CHANGED:**
`xdebug_get_frame_values` description. No additions.

`skill_search` was the unified `mode=file|text|regex|symbol` entry point. **Nothing depended on
it**: a grep of `~/.claude/` finds it only in this file and the capability snapshots -- no agent
allowlist, no memory. Use the four underlying tools directly. This is the first removal here
with no fallout, which is worth noting only because the 2026-08-09 removals had plenty.

**`projectPath` re-verified 2026-09-09**, per the checklist: the POSIX path is still rejected
with the "doesn't correspond to any open project" error, the `//wsl.localhost/Ubuntu-26.04/...`
form still works. No change.

**NOT re-verified this round: the `search_symbol` span gotcha and the resolve-verified caller
recipe.** Both are documented against `config.py:211`, and TOO-78 was moving that very file
while the review ran, so any measurement would have recorded the refactor rather than the tool.
Carried to the next review. Stated rather than silently skipped, because a checklist item that
disappears without a line is indistinguishable from one that passed.

#### No move / move-file refactoring exists (measured and doc-confirmed 2026-09-09)

`rename_refactoring` is still the **only** refactoring tool advertised, and the JetBrains page
documents no move, no type hierarchy and no find-usages tool. Worth stating explicitly because
the IDE's *interactive* Move is reliable and reference-aware, so it is an obvious thing to want
to drive from here. It is not on the MCP surface: reorganizing packages is a manual UI
operation, and the agent's role is to prepare and verify around it.

#### Doc-vs-measurement disagreements, this round

* **The page still documents `skill_search`** and still counts 60 tools. For this removal the
  docs *lag* the build, where previously they *ran ahead* of it. Both directions have now been
  seen; the measurement wins either way.
* **`analyze_calls` is documented with no Python caveat** -- *"Builds the IDE Call Hierarchy
  tree for a method, function, constructor, or supported type target. Use it to see who calls a
  symbol or what the symbol calls."* It still does not work on Python here. This is exactly the
  disagreement this file exists to record, and it does **not** reopen the retired re-test item.

### Drift 2026-08-09 -> 2026-08-25, measured by the script

Version `2026.2.1 RC` -> `2026.2.1`. **NEW (2):** `get_python_environment`,
`configure_python_interpreter` -- both Python-specific, and the first is how you diagnose a missing
interpreter (see the `analyze_calls` section). No removals. The tool surface is stable; **the
backend change, which the script cannot see, was the disruptive part.**

### Drift 2026-07-29 -> 2026-08-09, measured by the script

**NEW (9):** `analyze_calls`, `lint_files`, `git_status`, `skill_search`, `execute_tool`, `create_database_connection`, `edit_database_connection`, `fetch_query_result`, `introspect_schema`.

**REMOVED (7):** `find_files_by_glob`, `find_files_by_name_keyword`, `get_file_text_by_path`, `replace_text_in_file`, `search_in_files_by_text`, `search_in_files_by_regex`, `runNotebookCell`.

**CHANGED:** `reformat_file` (`path` → `files`, now required), `xdebug_set_breakpoint` and `xdebug_list_breakpoints` (new `sessionId`), `list_database_schemas` (`selectedOnly` dropped), plus description changes on `execute_run_configuration` and `get_project_dependencies`.

**The removals matter more than the additions here.** `replace_text_in_file`, `get_file_text_by_path`, `find_files_by_glob`, `find_files_by_name_keyword` and both `search_in_files_by_*` tools are enumerated by name in `~/.claude/agents/*.md` allowlists and referenced by auto-memory. Those references are now dangling — see *Fallout* below.

### `analyze_calls`: RE-TESTED AT GA, still NOT usable on Python (measured 2026-08-25)

**The GA re-test the checklist demanded is done. The answer is unchanged.** Four `symbolFqn` forms
x both `INCOMING_CALLS` and `OUTGOING_CALLS` = 8 calls, every one `No callable symbol found`, same
provider message. The control matters: `search_symbol` succeeded on the *same* `projectPath` in the
same batch, so this is symbol resolution failing, not project resolution.

**Three competing explanations have now been tried and all three are dead:**

| explanation | status |
|---|---|
| EAP/RC on WSL + Remote Development | **dead** -- this is GA, and `pgrep` finds no `remote-dev-serv`; the IDE is Windows-native over `\\wsl.localhost` |
| Plugin version skew (tool not advertised) | **dead** -- advertised and reachable; it returns a provider error, not an absence |
| **No Python interpreter** (IDE auto-detects uv, cannot see `/home/arnon/.local/bin/uv` from Windows) -- the 2026-08-23 "CAUSE FOUND" | **dead** -- interpreter now configured, and the fix did not change the behaviour |

**The interpreter refutation is direct, not inferred.** The Python SDK is demonstrably live:
`get_symbol_info` on a `Path` annotation resolves into **typeshed stubs**, into a
`sys.version_info >= (3, 14)` branch matching the configured 3.14.5 interpreter; `get_symbol_info`
on a project call site resolves across files and picks correctly between two same-named twins; and
`lint_files` emits **type-inference** diagnostics. A full semantic model exists.

So what survives is the original hypothesis: **the Python call-hierarchy provider is simply not
wired to `analyze_calls`.** A JVM project in the same IDE remains the only clean proof, and is not
worth building.

**Method note worth keeping.** Each of the three rounds found a plausible cause, fixed it, and
wrote "CAUSE FOUND" *without re-measuring*. A cause is established only when removing it changes
the behaviour.

**Stop re-testing this on the drift cadence.** Two re-tests across an RC->GA transition and a
backend change produced the identical result. Re-test when a JVM project is open anyway, or when
release notes mention Python call hierarchy -- not otherwise. **And it no longer costs anything:
pyright covers the capability (see below), so this is a curiosity, not a gap.**

### The original measurement (2026-08-09), retained for the reasoning

This was the single highest-value gap and the checklist item to re-test first. It now exists. **It does not resolve Python symbols.**

Four `symbolFqn` forms tried against a symbol `search_symbol` locates without trouble:

| passed | result |
|---|---|
| `toolguard.config.find_project_root` | `No callable symbol found` |
| `find_project_root` | `No callable symbol found` |
| `config.find_project_root` | `No callable symbol found` |
| `toolguard.config.Configuration.governed_tools` (class method, full path) | `No callable symbol found` |

`search_symbol(q="find_project_root", paths=["toolguard/**"])` returns both declarations correctly in the same session, so the symbol index sees the code; only the **call-hierarchy provider** does not. The error text is consistent with that: *"Type roots are supported only when the language call hierarchy provider maps them to a callable target."*

**Cause is NOT established, and my first reading of it was wrong.** I concluded "JVM-only, same as `run_inspection_kts`". Arnon's competing hypothesis is better supported by outside evidence:

> The version we have now in the IDE is an EAP, not a final release. And I think the EAP still has issues with WSL. I suspect that this is the core reason. There are other tools that fail in the IDE as well (like generating diagrams) and there were bugs reported by people about such failures in WSL environments going back at least a year.

So there are two live explanations and **this measurement does not discriminate between them**:

1. The call-hierarchy provider does not map Python (a language-support gap).
2. **2026.2.1 is an EAP/RC on a WSL + Remote Development backend**, where whole IDE subsystems are known to fail — diagram generation being another local example, with reports going back a year.

Hypothesis 2 explains more: it predicts unrelated failures in unrelated subsystems, which is what is actually observed. Hypothesis 1 predicts only this one.

**A discriminating test needs a JVM project in the same IDE and backend.** If `analyze_calls` fails there too, it is the environment; if it works, it is language support. Not worth building a throwaway Java project for — **Arnon's call: revisit at the final release rather than now.**

**Consequence either way: nothing changes for Python today.** The resolve-verified recipe below remains the IDE route, and pyright/LSP remains the preferred semantic lane. Re-test at GA, not on the normal cadence.

Re-measure with `uv run python ~/.claude/tools/ide_mcp_capabilities.py --verbose`; see
*Drift* below. Never restate the inventory from memory -- ask the script.

### pyright DOES cover the `analyze_calls` gap (measured 2026-08-25)

The gap that justified two re-tests is closed by the other lane. `LSP incomingCalls` /
`outgoingCalls` on `toolguard.config.find_project_root`:

* **21 incoming calls** with exact call-site line:column, plus 1 outgoing.
* **Disambiguates same-named twins.** `config.find_project_root` and `env_config.find_project_root`
  both exist; each list contains only its own callers. Validated against 41 textual
  `find_project_root(` occurrences -- every one of the 20 exclusions was checked by hand and every
  one was correct (the twin's own callers, the twin's internal calls, and `patch("...")` **strings**,
  which are not calls at all).
* **Resolves class-based `unittest` methods individually**, which is the thing the graph's
  `tests_for` cannot do.

**Measured blind spot: aliased imports.** `test_config.py:13` does
`from toolguard.env_config import find_project_root as env_find_project_root`, and the two calls
through that alias (`523`, `526`) are **absent** from `env_config.find_project_root`'s incoming
list. Two false negatives, silent. This is the *same* blind spot the IDE recipe below documents, so
neither lane covers it -- when a symbol is aliased anywhere, add a text pass.

### `lint_files` / `get_file_problems`: a real correctness lane (measured 2026-08-25)

Previously listed as an untested open question. **Tested, and it earns its place.**

`lint_files` over 7 files returned ~70 problems and one **ERROR** that no other lane here caught:
`toolguard/env_config.py:134`, `-> Dict[str, any]` -- the builtin `any`, not `typing.Any`.
`uv run ruff check` reports "All checks passed" on that file.

* `get_file_problems` **defaults to errors only.** An empty `errors: []` means no ERRORs, *not* a
  clean file -- `config.py` returned `[]` and `lint_files` found 22 warnings in it. Pass
  `errorsOnly: false`, or use `lint_files` with `min_severity`.
* `lint_files` takes a batch and reports per file; it analyses Markdown too (it flagged a malformed
  table in `README.md`).
* **Not noise-free**: `Cannot find reference 'SEEK_END' in 'os'` in `log_writer.py` is a false
  positive. Treat output as triage, not verdict.

### GOTCHA: `read_file`'s `limit` is ignored (measured 2026-08-25)

`offset=199, limit=6` returned three lines, then `...2052 lines truncated...`, then the file's
**tail**. It reads offset->EOF and elides the middle. **It is not a windowing tool** -- use
`Read`/`sed` for a slice. Asking for a large limit blows the token budget and spills to a temp file.

### Capability shape, in one pass

* **Semantic, read-only**: `search_symbol` (declaration index), `get_symbol_info` (resolve at
  a position), `get_file_problems` (inspections).
* **Semantic, write**: `rename_refactoring` -- reference-aware across the project.
* **Text/regex** (fast, IDE-indexed, *not* semantic): `search_text`, `search_regex`. Both verified
  working 2026-08-25; they replace the removed `search_in_files_by_*`.
* **Files**: `search_file` (glob; replaces `find_files_by_glob`), `list_directory_tree`,
  `read_file` (replaces `get_file_text_by_path`; **see the `limit` gotcha above**). All verified
  2026-08-25.
* ~~**Unified search**: `skill_search`~~ -- **removed in 2026.2.2**. Call the four tools above
  directly.
* **Python** (new at GA): `get_python_environment` reports the interpreter for a file -- correct
  `.venv` path and version here, but `environmentType` and `packageManager` both come back
  `unknown`, so **it does not detect uv**. `configure_python_interpreter` writes config; untested.
* **VCS**: `git_status` -- correct branch and counts, verified 2026-08-25.
* **Project/build/run**: `get_project_modules`, `get_project_dependencies`, `build_project`,
  `execute_run_configuration`, `get_run_configurations`, `get_repositories`.
* **Debugger** (16 `xdebug_*` tools): live stacks, frame values, breakpoints, expression
  evaluation. Largely unexplored by us -- see *Open questions*.
* **Inspections-as-code**: `run_inspection_kts`, `generate_inspection_kts_api`,
  `validate_inspection_kts`. **Java/Kotlin only** -- the API tool accepts no other language,
  and it NPE'd on a trivial script against a `.py` file. Not a Python route.
* **Database** (9 tools) and notebooks (`runNotebookCell`).

### Fallout from the 2026-08-09 removals — fix before relying on any agent

Seven tools vanished, and several were named in configuration rather than merely used:

* `~/.claude/agents/*.md` allowlists enumerate `mcp__jetbrains__*` **by name**. Entries for
  `replace_text_in_file`, `get_file_text_by_path`, `find_files_by_glob`,
  `find_files_by_name_keyword`, `search_in_files_by_text` and `search_in_files_by_regex` now
  point at nothing. A dangling allowlist entry fails silently — the agent simply never gets
  the tool — which is the same class of failure the naming memory already warns about.
* Auto-memory `feedback_edit_via_ide_mcp` instructs using `mcp__jetbrains__replace_text_in_file`
  for files Arnon is watching. **That tool no longer exists.** The surviving write path is
  `apply_patch` (verify its shape before recommending it).
* `reformat_file` changed its required parameter from `path` to `files`. Any caller passing
  `path` now fails.

### What is still missing, and what that costs

* **No Find Usages / references tool** under any name (`find_usages`, `get_usages`,
  `search_usages`, `find_references` all absent). `analyze_calls` was supposed to be this and
  is JVM-only in practice — see above.
* **No type hierarchy**, no file-outline tool.
* **No move / move-file refactoring** (measured 2026-09-09, and the docs agree). The IDE's
  interactive Move is reference-aware and reliable; it is simply not exposed. A package
  reorganization is therefore a manual UI operation with the agent preparing and verifying
  around it.
* **`analyze_calls` for Python.** Present, advertised, unusable here across two builds and a
  backend change. **No longer a cost** -- pyright supplies the capability; see above. Stop
  re-testing it every review.

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
- [ ] **Confirm `projectPath` still resolves** -- one cheap `search_file` call. A backend or distro
      change breaks *every* tool at once, and the error is easy to misread as a broken tool.
- [ ] ~~Re-test `analyze_calls`~~ -- retired as a cadence item 2026-08-25. Two re-tests, same
      result, and pyright covers the capability.
- [ ] Re-verify the `search_symbol` span gotcha and the resolve-verified recipe still behave
      as documented above; correct this file if not, and date the correction.
- [ ] Re-read https://www.jetbrains.com/help/idea/mcp-server.html and diff it against the
      *measured* inventory. Where they disagree, the measurement wins and the disagreement is
      itself worth noting -- it has happened before.
- [ ] Note the IDE build (Settings | Tools | MCP Server, or the script's `serverInfo`).
- [ ] Update the cadence memory's date and anything learned.

## Open questions worth a cheap experiment

Recorded so they are not rediscovered from scratch:

* ~~**`get_file_problems` as a correctness lane.**~~ **ANSWERED 2026-08-25: yes** -- see the
  `lint_files` section above. Remaining sub-question: is it worth wiring into `/code-review` as a
  standing step, given the false-positive rate?
* **The 16 `xdebug_*` tools.** A live debugger is a *dynamic* analysis lane none of the other
  tools offer -- it could resolve exactly the dynamic dispatch that defeats every static
  approach. Entirely unexplored.
* **`get_project_modules` / `get_project_dependencies`** for orientation, versus
  `get_architecture_overview` from the graph.
* **Whether the client registry ever lags the server's `tools/list`.** Still open, but narrowed
  2026-09-09. What was measured: the server's 59-tool `tools/list` and the list `execute_tool`
  reports it can dispatch are **identical sets** (diffed both directions, both empty) -- and
  this session's client registry also lacks the removed `skill_search`. **That is weaker
  evidence than it looks**: both of those lists are server-side, and this session happened to
  connect after the upgrade. The case that could actually diverge is an IDE upgrade *during* a
  session, which is untested. If it happens, a tool can be "present" and still uncallable, and
  a restart is the fix rather than an update.

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
