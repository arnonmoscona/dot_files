# code-review-graph for searching (read only when the tool is confirmed present)

This extends `common-search.md`'s two lanes (`ag`/`ack` for text, JetBrains MCP for
symbol-precise lookups) with a third: a persistent structural graph (calls, imports,
inheritance, tests) that survives across sessions and doesn't need an IDE running.

For the full tool/command reference, use the tool's own `get_docs_section_tool` (e.g.
section `"commands"`) rather than assuming details here -- this file covers *when* to reach
for it, not the full API. It changes across versions; the tool's own docs are the source of
truth for exact parameters.

## When this beats the other two lanes

- **Multi-hop questions**: "what could break if I change this file" (callers + dependents +
  their tests in one call via `get_impact_radius_tool`), "who calls the callers of X"
  (`traverse_graph_tool` or repeated `query_graph_tool`), "what execution paths touch this"
  (`get_affected_flows_tool`) -- each hop otherwise costs another grep+read+reasoning round.
- **"What tests cover this"**: `query_graph_tool(pattern="tests_for")` maps code to tests via
  parsed edges plus naming convention, not by grepping for the function name inside test
  files.
- **Conceptual/semantic queries** where you don't know the exact symbol name:
  `semantic_search_nodes_tool` (hybrid keyword + vector search over the graph).
- **The IDE isn't running, or its index is stale/misconfigured** (see `common-search.md`'s
  own caveat about index drift) -- the graph doesn't depend on the IDE at all.
- **Cross-language edges** that no single-language LSP models.

## When NOT to bother

- Single-hop "where is X defined" / "what's its signature" -- `mcp__jetbrains__search_symbol`
  is just as good, needs no setup, and is compiler-informed rather than AST-heuristic.
- A trivial one-off question on a repo you won't revisit in this session.
- Text-anchored questions (string literals, comments, config values, log messages, TODOs) --
  still `ag`, exactly as `common-search.md` already says. The graph indexes structure, not
  arbitrary text.

## MANDATORY precondition: refresh the layers that do NOT auto-update

Only part of the graph maintains itself. The `PostToolUse` hook runs
`code-review-graph update --skip-flows`, and that flag means *"signatures + FTS only"*.
So three layers drift silently, and the tools that read them keep answering -- from stale
data, with no warning. Verified on the toolguard repo 2026-07-25: `embeddings_count` had
not moved since install, and a semantic search for functions written that same day
returned five unrelated older functions and none of the new code.

| layer | auto-updates? | tools that depend on it |
|---|---|---|
| nodes, edges (CALLS/IMPORTS/INHERITS/REFERENCES), signatures, FTS5 | **yes**, every Edit/Write/Bash | `query_graph_tool`, `traverse_graph_tool`, `get_impact_radius_tool`, `get_review_context_tool`, `get_minimal_context_tool`, `detect_changes_tool`, `refactor_tool`, `find_large_functions_tool`, `list_graph_stats_tool` |
| **embeddings** | **NO** | `semantic_search_nodes_tool` (its vector half; it silently degrades toward keyword-only) |
| **flows** | **NO** (`--skip-flows`) | `get_affected_flows_tool`, `list_flows_tool`, `get_flow_tool` |
| **communities** | **NO** (`--skip-flows`) | `get_architecture_overview_tool`, `list_communities_tool`, `get_community_tool`, `get_hub_nodes_tool`, `get_bridge_nodes_tool`, `get_surprising_connections_tool`, `generate_wiki_tool` / `get_wiki_page_tool` |

**Before using any tool in the bottom three rows, refresh first:**

```bash
uv run code-review-graph embed        # incremental; only new/changed nodes
uv run code-review-graph postprocess  # rebuilds flows + communities + FTS
```

Measured cost on a ~3000-node repo: **~3.6 s** for a no-op `embed` (almost all of it
sentence-transformers model load) and **~0.45 s** for `postprocess`. That is cheap enough
that you should just run it rather than reason about whether it is needed. Both are local,
offline, and write only to the gitignored `.code-review-graph/`.

Tools in the FIRST row need no refresh -- they traverse live structural data. That
distinction is the whole point of this table: do not pay 4 seconds to answer "who calls
this", and do not skip it before asking "what execution paths does this touch".

**Automation:** there is none built in. Confirmed against the CLI -- `embed` has no
scheduling options, `update` has no `--embed` flag, `watch` takes only `--repo`/`--data-dir`,
and the daemon's `~/.code-review-graph/watch.toml` exposes only `session_name`, `log_dir`,
`poll_interval`, `repos`. A project may wire `embed && postprocess` into its `SessionStart`
hook (toolguard does, backgrounded). **Where no such hook exists, the refresh is on you.**
Check the project's `.claude/settings.json` if unsure.

**Suspect staleness even with the hook** when: `semantic_search` stops surfacing recently
added functions, a concept query returns only older code, or you have just landed a batch
of new/renamed functions. Confirm via `list_graph_stats_tool` -- compare `embeddings_count`
against Function + Class + Test node counts; a large shortfall means new nodes are
unembedded.

## Report back on whether this tool is earning its keep

This tool is on trial. Each time you use it for something non-trivial, make a quick
judgement and tell Arnon in your reply -- briefly, not a formal report:

- Did it answer something `ag`/JetBrains MCP would have struggled with, or did it just
  restate what a grep would have found faster?
- Was the answer correct when you verified it? (Ranked/heuristic results are leads, not
  facts -- see edge confidence below.)
- Did stale data mislead you?

Say plainly when it added real value AND when it did not; a tool that only ever gets
positive reports is not being evaluated.

**Report observations, not verdicts.** A single use is a data point, not a statistic --
do not generalize "it didn't help here" into "it isn't useful", and do not let one good
result settle the question either. The purpose of the trial is to accumulate real evidence;
concluding early defeats it. Note especially whether a miss was the tool's fault or the
query's (a poorly-shaped question, or one asked after you already knew the answer, proves
little).

**Append every non-trivial use to `~/.claude/code-review-graph-evidence-log.md`** -- a
GLOBAL, cross-project log, so evidence accumulates across every repo the tool is installed
in rather than fragmenting into per-project memories. It carries the logging format and a
running count.

Arnon's bar for concluding anything: **~100 real-world uses across several of the tools.**
Until then, log observations and keep going; raise a reservation about continued use only
when a PATTERN emerges across many uses, never on a single disappointment. Check the running
count before you are tempted to declare a verdict.

## One caveat to always apply: edge confidence

Graph edges carry a confidence tier (EXTRACTED / INFERRED / AMBIGUOUS) -- resolution is
AST-level and heuristic, not compiler-backed, so dynamic dispatch, metaprogramming, and duck
typing can produce inferred or ambiguous edges. Treat an EXTRACTED edge as reliable; treat
INFERRED/AMBIGUOUS results as a lead to verify with a direct read, not as settled fact --
especially before stating something as certain to the user.
