# Searching code efficiently

Read this before a non-trivial code search. Not loaded at launch.

## Pick a lane

| Question | Lane |
|---|---|
| Transitive callers, blast radius, affected flows, which tests cover a function | `code-review-graph` if installed (below) |
| Conceptual -- "is there already a helper that does this?" | `semantic_search_nodes_tool`, else `ag` |
| Where is `Foo` defined? Who calls it? | `ag` -- see the blind spots below |
| String literal, comment, log message, template fragment, config value | `ag` |
| Gitignored, generated, or just-created files | `ag` |
| Must be exhaustive and verifiable ("all N call sites", "every import of X") | `ag` |

There is currently **no working semantic/PSI lane** on this machine -- see the note at the
bottom. So every symbol question that `code-review-graph` cannot answer falls to text search,
and its blind spots are load-bearing rather than a footnote.

Say which lane you used when you report a caller set. They are not equivalent, and an `ag`
count is not a call hierarchy.

## `ag` and `ack`

Both are installed (verified 2026-07-31: `/usr/bin/ag`, `/usr/bin/ack`). `ag` (Silver
Searcher) is much faster and is the default choice. It lacks `--and`, `--or`, `--not` -- pipe
to `grep -v` to exclude, or reach for `ack` when you want those flags natively.

Type filters plus consistent `ruff` formatting make targeted searches cheap:

```bash
ag --python 'def target_fn\(' src/
```

Use `\btarget_fn\(` and not ` target_fn\(` -- the word boundary catches `module.target_fn(`
too, whereas a leading literal space silently misses attribute-style calls.

**Text patterns have structural blind spots.** They miss attribute-style access, `import
some.module` followed by dotted use, and aliased imports (`from x import fn as f`); they
produce false positives on same-named symbols elsewhere; and they usually exclude the import
line itself. When completeness matters and no semantic tool can answer, say what the pattern
could have missed rather than presenting the count as definitive.

## Structural graph (`code-review-graph`)

Per-project, not universal. Confirm `mcp__code-review-graph__*` tools exist or a
`.code-review-graph/` directory is at the project root, then read
`~/.claude/reference/code-review-graph.md` -- it has the mandatory staleness preconditions
and the edge-confidence caveat, both of which change what you can trust.

Reach for it first on multi-hop structural questions: impact radius before a refactor,
transitive callers, affected execution paths, which tests cover a function, orienting in
unfamiliar code, planning a rename or hunting dead code. The failure mode to avoid is habit
-- burning several grep+read+reason rounds on something that is one call.

Keep using `ag` when the answer must be exhaustive: the graph returns *ranked* results, and
on small-to-medium repos the fused scores are nearly flat, so ranking carries little signal.
A question where missing one entry is the failure is the wrong shape for it.

## Why there is no IDE lane here

The JetBrains MCP server is registered and works, but the build reachable from this machine
(a Remote Development backend) exposes **none of the analysis or language-aware tools** --
no call hierarchy, no find-usages, no type hierarchy, no symbol resolution worth the call.
What remains is file open/read/write and plain text search, which `ag` and the normal file
tools already do.

So: **do not route search or structural questions to `mcp__jetbrains__*`.** It is not a
fallback for `code-review-graph`; it is not a second opinion; it is not an oracle for
resolving disagreements. Use it for opening files in the IDE and nothing in this document.

If that changes -- a plugin update, a non-remote backend, tools appearing in the registry --
`~/.claude/reference/ide-mcp.md` holds the dated measurements and the method for re-measuring.
Read it only when actually re-evaluating the IDE's surface, not during ordinary searching.

<!--
Maintainer notes (stripped before entering context).

Was ~/.claude/common-search.md, 184 lines -> 66.

REVISED 2026-07-31 on Arnon's instruction: drop the JetBrains MCP lane entirely. He checked the
IDE's exposed tool configuration and analyze_calls is not merely unshipped -- essentially every
language-specific and analysis tool is absent, which he attributes to the WSL/Remote-Development
setup. There is no fix he can identify now. Guidance naming those tools is "wasteful noise", and
worse, it advertised a head-to-head comparison lane against code-review-graph that cannot happen.

That supersedes the 2026-07-29 correction, which had restored analyze_calls to the table as "real
but not callable in this build". Both facts still hold; the conclusion changed from "document the
skew and fall back" to "remove the lane".

Consequence worth remembering: code-review-graph has NO viable fallback for structural questions.
That raises the stakes on its evaluation rather than lowering them, and it is why the trial
continues. Arnon has mentioned possibly evaluating graphify later; not now.

ack: the previous draft said ag is installed "as is ack", and Arnon's review note said ack was
"not there". Checked directly -- both are installed. Now stated with the date and the paths.

Removed as redundant with current models: the "why this matters / grep uses a lot of context"
motivation section, the two elaborate multi-line lookahead+xargs pipelines (a brittle idiom
current models don't need coaching into and shouldn't be nudged toward), the duplicated
blind-spot list, and the "on trial, report a verdict each use" paragraph -- that belongs in one
place, the code-review-graph reference, not in two files.
-->
