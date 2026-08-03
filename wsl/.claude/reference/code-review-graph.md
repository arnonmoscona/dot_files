# code-review-graph

Read only when the tool is confirmed present (`mcp__code-review-graph__*` tools, or a
`.code-review-graph/` directory at the project root). Covers *when* to reach for it and what
to distrust -- for exact parameters use its own `get_docs_section_tool`, which tracks the
installed version.

## MANDATORY precondition: refresh the layers that don't auto-update

The `PostToolUse` hook runs `code-review-graph update --skip-flows`, which means signatures
and FTS only. Three layers drift silently, and the tools reading them keep answering from
stale data with no warning. Verified on toolguard 2026-07-25: `embeddings_count` hadn't moved
since install, and a semantic search for functions written that day returned five unrelated
older ones.

| Layer | Auto-updates | Tools depending on it |
|---|---|---|
| nodes, edges, signatures, FTS5 | **yes**, every Edit/Write/Bash | `query_graph`, `traverse_graph`, `get_impact_radius`, `get_review_context`, `get_minimal_context`, `detect_changes`, `refactor`, `find_large_functions`, `list_graph_stats` |
| **embeddings** | **no** | `semantic_search_nodes` (degrades silently toward keyword-only) |
| **flows** | **no** | `get_affected_flows`, `list_flows`, `get_flow` |
| **communities** | **no** | `get_architecture_overview`, `list_communities`, `get_community`, `get_hub_nodes`, `get_bridge_nodes`, `get_surprising_connections`, `generate_wiki` |

Before any tool in the bottom three rows:

```bash
uv run code-review-graph embed && uv run code-review-graph postprocess
```

About 4s total on a ~3000-node repo, mostly model load. Local, offline, writes only to the
gitignored `.code-review-graph/`. Cheap enough to just run rather than reason about. Row-one
tools need no refresh -- don't pay the 4s to ask "who calls this", and don't skip it before
asking "what execution paths does this touch".

There is no built-in automation: `embed` has no scheduling, `update` has no `--embed`, and
the watch daemon exposes no embed step. A project may wire it into `SessionStart` (toolguard
does, backgrounded) -- check `.claude/settings.json`. Otherwise the refresh is on you.

Suspect staleness even with a hook when semantic search stops surfacing recently added
functions or a concept query returns only older code. Confirm via `list_graph_stats`:
compare `embeddings_count` against Function + Class + Test node counts.

## Always apply: edge confidence

Edges carry a tier -- EXTRACTED / INFERRED / AMBIGUOUS. Resolution is AST-level and
heuristic, not compiler-backed, so dynamic dispatch, metaprogramming, and duck typing
produce inferred or ambiguous edges. Treat EXTRACTED as reliable; treat the other two as a
lead to verify by reading, never as settled fact -- and never as the basis for a Critical or
Major review finding, or for stating something as certain to Arnon.

## Known-unreliable pattern: `tests_for`

The `TESTED_BY` heuristic misses class-based `unittest.TestCase` methods, which is how
Arnon's projects write tests, so it returns false zeros. The underlying test-to-function
`CALLS` edges do exist. **Use `query_graph` `pattern="callers_of"` filtered to
`is_test:true`** to find a function's tests. Confirmed on toolguard 2026-06-29; assume it
holds on any unittest-based repo until shown otherwise.

## In a code review, the value is rigor, not token savings

A linear read of a diff can miss a caller three hops out, misjudge how central the changed
code is, or not notice an unusual dependency. The graph doesn't, because it was built from
parsed edges rather than an attention-limited read-through.

Every review, when present:

1. **`get_minimal_context(task=...)`** -- structural orientation before reading anything.
2. **`detect_changes`** -- maps the diff onto affected functions, flows, communities, and
   test gaps with structure-derived risk scores. Use it to decide what to read and in what
   order.
3. **`get_impact_radius` / `get_affected_flows`** -- blast radius beyond the literal diff.
   This is where a change silently breaks something the diff never shows.
4. **`callers_of` filtered to `is_test:true`** -- whether the change is actually
   safety-netted.

On substantial or cross-cutting changes: `list_communities` / `get_community` reveal real
cohesion boundaries (a change crossing several communities is riskier than its file count
suggests -- review community by community); `get_hub_nodes` / `get_bridge_nodes` give an
objective centrality measure, a signal to raise scrutiny rather than a finding on its own;
`get_surprising_connections` flags statistically unexpected coupling, exactly the class of
hidden coupling a linear read misses; `get_architecture_overview` orients you in unfamiliar
areas; `semantic_search_nodes` checks whether the change reimplements something that exists.

Lower priority for a single pass: `get_knowledge_gaps`, `get_suggested_questions`, graph diff
(better for tracking drift across releases).

**It does not tell you whether the code is correct, secure, or well designed.** It tells you
what is affected, where the tests are, how code clusters, and which connections are unusual.
The judgment stays yours, applied to the files it points you toward.

## The trial

**The incumbent is the `LSP` tool (pyright), and the bar moved up sharply on 2026-07-31.**

The history matters, because this framing has now changed twice. It began as a head-to-head
against the JetBrains MCP. That fell through: the reachable IDE build exposes no analysis tools
at all, which briefly left `ag` and plain reading as the only competition -- a low bar, and one
that made a positive verdict prove very little. Pyright is now configured for toolguard (and
being set up for featherhill), which restores a real compiler-informed incumbent, and a better
one than the IDE would have been.

**What the incumbent takes back.** Measured on toolguard, `findReferences` returns every
reference kind with import lines separated from call sites, and `incomingCalls` returns a call
hierarchy naming each calling function -- including class-based `unittest.TestCase` methods,
individually, by name. So pyright answers direct callers, callees, all-reference-kinds, and
**which tests cover this function** from the type checker rather than a heuristic. Note what
that last one means here: `tests_for` is documented as unreliable on this repo precisely because
it misses class-based test methods. The graph's known weak spot is the incumbent's clean win.

**What is left that is genuinely the graph's.** Multi-hop transitive traversal, execution flows,
communities, centrality, bridge/hub analysis, cross-repo questions, and semantic "is there
already a helper that does this?" search. That is a real set -- but it is much smaller than the
set the graph was being reached for a week ago, and it excludes the everyday questions.

So the standard is now: **would `LSP` have answered this, more accurately, in one call?** If yes,
the graph did not earn the invocation, however good its answer looked. Say so plainly -- that is
the finding, not a failure to find one. The honest risk to weigh is that the remaining
graph-only questions are also the *rarer* ones, which is a legitimate reason to retire a tool
even when it works.

**Record the development phase with each observation, and do not generalize across phases.**
What gets reached for depends heavily on what Arnon has asked for. Initial development, deep
testing, and refactoring/optimization exercise different capabilities -- and the graph's
exclusive ground (blast radius, dead code, transitive impact, centrality) clusters almost
entirely in the refactoring and optimization phase. A quiet trial during a stretch of
feature work is therefore weak evidence for retirement, and a strong showing during a
refactor is weak evidence for general value. Tag each entry with the phase so the eventual
verdict can be read per-phase rather than as one average that describes no real situation.

Each non-trivial use: add a one-line verdict to your reply. Did it answer something the
other lanes would have struggled with, or restate what a grep would have found faster? Was
it right when you checked? Did stale data mislead you? Report misses as readily as wins -- a
tool that only ever gets good reviews isn't being evaluated.

**Report observations, not verdicts.** Arnon's bar is ~100 real uses across several tools;
one instance is information, not a statistic. Raise a reservation only when a pattern emerges
across many uses, and check the running count before you're tempted to conclude anything.
Note whether a miss was the tool's fault or the query's.

Append every non-trivial use to `~/.claude/code-review-graph-evidence-log.md` -- global, not
per-project, so evidence accumulates across repos. Format and running tally are in that file,
along with the trial-exit checklist.

**A comparison is only usable if you refreshed first.** Arnon's concern, 2026-07-29: it is
unclear whether every past accuracy test forced an `embed` + `postprocess`, which means some
recorded inaccuracies may really be staleness. Those findings can't be leaned on. From now on,
note explicitly in each log entry that the refresh was done -- an entry that doesn't say so
should be read as inconclusive rather than negative.

For a proper head-to-head, follow the **three-lane comparison protocol** in
`~/.claude/reference/ide-mcp.md`: it fixes the refresh order, requires recording membership and
not just counts, and requires classifying each miss by cause (stale index / heuristic
resolution / text blind spot / bad query). It also explains why majority vote across the three
lanes is not truth, and specifies the ground-truth oracle that would settle disagreements.

<!--
Maintainer notes (stripped before entering context).

Merges code-review-graph-search.md (118) + code-review-graph-review.md (81) = 199 -> 96.
The evidence log (213 lines) is unchanged: it is an accumulating data file, not guidance, and
is read on demand.

Resolved a real contradiction: search.md recommended query_graph(pattern="tests_for") for
test coverage, while common-search.md and toolguard's CLAUDE.md both said tests_for is
unreliable on unittest repos and to use callers_of. Three files, two answers. Now stated once,
with the reason.

Removed as redundant: the "when NOT to bother" list (duplicated the search-lane table), the
per-tool restatements of what each tool does (the tool descriptions already say), the
tier-2/tier-3 numbering ceremony, and the second copy of the trial protocol.

Kept deliberately, despite being the largest remaining block: the staleness table and the
trial protocol. The first prevents confidently-wrong answers, which has already happened
once. The second is Arnon's explicit evaluation design -- not model scaffolding, and not
mine to trim. Worth noting though: the guidance about evaluating the tool is now roughly the
same size as the guidance for using it, and every non-trivial use carries a
log-plus-verdict cost. That is a real ongoing tax; the exit checklist is what ends it.
-->
