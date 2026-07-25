# code-review-graph for code review (read only when the tool is confirmed present)

This is about analytical rigor, not token efficiency -- see `code-review-graph-search.md`
for the efficiency framing when the task is general searching. In a review, the value of
this tool is that it gives you graph-derived structural FACTS (who calls what, what's
tested, how code clusters, how central a piece of code is, what coupling is unusual) instead
of asking you to infer those things from reading files linearly. A purely-LLM read of a diff
can miss a caller three hops away, misjudge how central the changed code is, or simply not
notice an unusual dependency -- the graph doesn't, because it was built from the actual
parsed edges, not from an attention-limited read-through.

For the full tool/command reference, use the tool's own `get_docs_section_tool` rather than
assuming details here -- this file covers *which* capability matters for *which* review
situation, and why, not the full API.

## Tier 1 -- use on essentially every review when available

1. **`get_minimal_context_tool(task=...)` first, always.** Establishes structural
   orientation -- risk area, community, relevant flows -- before you read anything. Treat
   this as the entry point to a review, not an optional shortcut.
2. **`detect_changes_tool`.** Maps the diff onto affected functions, flows, communities, and
   test gaps, with risk scores computed from real graph structure. Use this to decide WHAT
   to read and in what order, before reading anything -- it is a structural fact about the
   change's actual footprint, not a guess.
3. **`get_impact_radius_tool` / `get_affected_flows_tool`.** Blast radius beyond the literal
   diff: every caller, dependent, and execution path that could be affected. This is an
   analytical-completeness aid, not an efficiency one -- it is specifically where a change
   silently breaks something the diff itself never shows, and where a linear read is most
   likely to miss something.
4. **`query_graph_tool(pattern="tests_for"/"callers_of")`.** Verifies test coverage exists
   for changed code via parsed edges, not by inspecting filenames or guessing from imports --
   a structural fact about whether a change is safety-netted, not an inference.
5. **Edge-confidence discipline applies doubly here.** Don't let an INFERRED/AMBIGUOUS edge
   stand in for actually reading code before a Critical/Major finding -- verify with a direct
   read first. The graph's analytical value depends on knowing how much to trust each claim
   it makes.

## Tier 2 -- situational, reach for on substantial or cross-cutting changes

6. **`list_communities_tool` / `get_community_tool`.** Leiden clustering reveals the code's
   *actual* cohesion boundaries -- not directory structure, but which pieces genuinely belong
   together based on real coupling. A change that crosses multiple communities is
   analytically riskier than one confined to a single community, independent of how many
   files it touches -- it's crossing a real structural boundary, not just a file-count
   threshold. Use this to decide review order (community by community) on a large or
   cross-cutting change.
7. **`get_architecture_overview_tool`.** Orientation for a large or first-time-in-this-area
   review -- places the changed code in the bigger structural picture before you judge it in
   isolation, which matters for catching design-level (not just line-level) problems.
8. **`get_hub_nodes_tool` / `get_bridge_nodes_tool`.** Centrality/chokepoint detection via
   betweenness centrality -- an OBJECTIVE, graph-derived measure of structural importance and
   coupling, not a subjective "this looks important" guess. A change touching a hub
   (high-connectivity node) or bridge (chokepoint between communities) objectively carries
   more coupling risk than its diff size suggests. Treat this as a signal to raise scrutiny,
   not as a finding by itself.
9. **`get_surprising_connections_tool`.** Flags statistically unexpected coupling relative to
   the graph's own community/language/degree structure (cross-community, cross-language,
   peripheral-to-hub edges). This is exactly the class of hidden coupling that's hard for an
   LLM to notice by reading code linearly, and disproportionately where bugs and bad
   abstractions hide -- worth a specific look when a change touches a surprising edge.
10. **`get_suggested_questions_tool`.** Auto-generated review questions derived from the same
    structural signals (bridges/hubs/surprises) -- a semantically-grounded supplementary
    checklist, not a replacement for the review's own checklist.

## Tier 3 -- available, lower priority for a single review pass

11. **`get_knowledge_gaps_tool`.** Isolated nodes, untested hotspots, thin communities --
    useful context on the surrounding code's structural health, not usually review-blocking
    by itself.
12. **`semantic_search_nodes_tool`.** Most useful here for a duplication/reimplementation
    check ("does something like this already exist elsewhere in the codebase") -- otherwise
    primarily a search-lane tool, see `code-review-graph-search.md`.
13. **Graph diff** (compare snapshots over time). Better suited to tracking architectural
    drift across a series of reviews/releases than a single review pass.

## What this does NOT replace

The graph tells you WHAT is affected, WHERE tests are, HOW code clusters, and WHICH
connections are structurally unusual. It does not tell you whether the code is correct,
secure, or well-designed -- that judgment is still yours, applied to the specific files and
functions the graph pointed you toward.
