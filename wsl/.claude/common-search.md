# Efficiently Searching in Code

## Quick decision rule

Before searching, ask: **am I looking for a symbol or for text?**

| Question | Use |
|----------|-----|
| Where is `Foo` / `bar()` defined? | `mcp__jetbrains__search_symbol` |
| Who calls it / what does it call? (call graph) | `mcp__jetbrains__analyze_calls` |
| What is its signature? | `mcp__jetbrains__get_symbol_info` |
| A string literal, template fragment, comment, log message, config value | `ag` |
| Anything in gitignored / generated / just-created files the IDE has not indexed | `ag` |
| Logical combinations (`--and`/`--not`) over text | `ag` piped into `grep -v` |
| The IDE is not running / no MCP available | `ag`, falling back to the recipes below |

Semantic queries via the MCP are precise, return structured metadata (so a follow-up
`Read` is usually unneeded), and are immune to the blind spots of text-based recipes.
Use them by default for anything symbol-shaped.

## Why this matters

The default search tools like `grep` can use a lot of context, as Claude has to sift
through a lot of output, often reading whole files to narrow down the search.

This system has an installation of `ag` (Silver Searcher), which is a fork of `ack`,
which is also on this system. You may find further documentation by running `ag --help`, or read the
[ack docs](https://beyondgrep.com/documentation/) for the full option reference.
Note that while `ag` is much faster than `ack`, it does not have every command line option
that `ack` has. Notably, it does not support `--and`, `--or`, and `--not`.

`ack` allows narrowing down searches by file type, `--and`, `--or`, `--not`. When
combined with the knowledge that the project has consistent formatting (with `ruff`), you
can very efficiently search for material with very little impact on the context buffer.

For example, suppose you want to know where `target_fn()` is defined:

```bash
ag --python 'def target_fn\(' src/
```

For something more complex, finding all probable call sites knowing that wildcard imports
are not used:

```bash
ag -l --python 'from myproject.some.module import(?=[\s\S]{0,1000} target_fn)' src/ \
  | xargs ag --python '\btarget_fn\('
```

**Use `\btarget_fn\(` not ` target_fn\(`** -- the word boundary catches both
` target_fn(` and `module.target_fn(`, whereas a leading literal space silently misses
attribute-style calls. For this kind of search prefer `mcp__jetbrains__analyze_calls`
when available -- it is semantic, so it also catches aliased imports and same-named-symbol
false positives that text patterns cannot reason about.

To exclude lines matching a pattern, pipe to `grep -v`:

```bash
ag -l --python 'from myproject.some.module import(?=[\s\S]{0,1000} target_fn)' src/ \
  | xargs ag --python '\btarget_fn\(' \
  | grep -v 'SomeClass.CONSTANT'
```

(`ack` has a native `--not` flag if you prefer that style.)

Whenever reasonable, use these techniques to save space in the context buffer.

# Searching using JetBrains MCP tools

When running in a JetBrains IDE, use the included MCP tools (`mcp__jetbrains__*`), which
expose the IDE's semantic index. The most useful tools:

* `search_symbol` (`mcp__jetbrains__search_symbol`) -- locate a class/function/method/
  variable definition by name; returns location and signature information.
* `analyze_calls` (`mcp__jetbrains__analyze_calls`) -- analyze the call graph for a
  symbol: who calls it and what it calls. Focuses on function calls; does not enumerate
  all reference kinds such as imports or attribute access.
* `get_symbol_info` (`mcp__jetbrains__get_symbol_info`) -- get detailed information about
  a symbol at a known file location.

## Canonical workflow for "who calls Foo?"

1. `search_symbol(name="Foo", ...)` -- returns one or more matches with file location.
2. `analyze_calls(...)` -- given the symbol location, returns its call graph.

Notes:

* Add filters to `search_symbol` when you know the kind or language -- disambiguates fast.
* `search_symbol` may return multiple matches (overloads, same name across modules). Pick
  the right one before proceeding.

## When to prefer which

* **Symbol-anchored questions** -- "where is it defined", "who calls it", "what's its
  signature" -- prefer the JetBrains MCP tools. They are precise, give richer per-result
  metadata, and avoid the structural blind spots of text-based recipes.
* **Text-anchored questions** -- string literals, comments, TODOs, HTML/template
  fragments, configuration values, log messages, regex patterns, files outside the IDE's
  index -- prefer `ag` / `ack`.
* **Mixed** -- start with the MCP for the symbol, then use `ag` to scan for related
  non-code traces.

## Structural blind spots in text-based recipes

Be aware of what text patterns can miss compared to semantic tools like
`mcp__jetbrains__analyze_calls`:

* A pattern like ` get_fn\(` with a leading space won't match `module.get_fn(...)`
  attribute-style access.
* Pre-filtering by `from ... import` misses files that use `import some.module` followed
  by attribute access.
* Aliased imports (`from ... import get_fn as gf`) are invisible to text patterns keyed
  on the original name.
* A second unrelated symbol of the same name elsewhere will produce false positives.
* The import line itself is typically excluded by these recipes.

# Structural graph search (code-review-graph, when installed)

Some projects have `code-review-graph` installed -- a per-project MCP tool, not universal.
Check for `mcp__code-review-graph__*` tools in your available tool list, or a
`.code-review-graph/` directory at the project root, before assuming it's there.

When present: read `~/.claude/code-review-graph-search.md` before relying on it -- it covers
the staleness preconditions (**mandatory** -- several layers do not auto-update) and the
edge-confidence caveat.

When absent: the two lanes above are unaffected, proceed as today.

## Reach for it by default on these questions

The failure mode to avoid is habit: falling back on `ag` for multi-hop structural questions
because it is familiar, burning several grep+read+reason rounds on something that is one
call. When a question matches this table, use the graph **first**:

| Question shape | Tool |
|---|---|
| "What breaks if I change this?" / blast radius before a refactor | `get_impact_radius_tool` |
| "Who calls the callers of X", transitive dependency chains | `traverse_graph_tool`, or `query_graph_tool` with `pattern="callers_of"` |
| "What execution paths touch this?" | `get_affected_flows_tool` |
| "What tests cover this function?" | `query_graph_tool` `pattern="callers_of"` filtered to `is_test:true` |
| Reviewing a change set -- risk-scored, token-efficient | `detect_changes_tool`, then `get_review_context_tool` |
| "Is there already a helper that does X?" (BEFORE writing a new one) | `semantic_search_nodes_tool` |
| Orienting in an unfamiliar area of the codebase | `get_architecture_overview_tool` |
| Planning a rename, or hunting dead code | `refactor_tool` |

The duplicate-helper row earns its place: a private predicate was once written that exactly
duplicated an existing public function, and the "inventory existing helpers first"
instruction only got added *after* the fact. A semantic search is what makes that
instruction actionable rather than aspirational. Note it returns a ranked guess -- when the
top hit is an adjacent sibling in the right file rather than the function itself, treat that
as the lead it is and read.

**Keep using `ag`/AST scripts when the answer must be exhaustive and verifiable** -- "all N
call sites", "every import of this symbol", "does this file still reference `re.`". The
graph returns ranked results, which is the wrong shape for a question where missing one
entry IS the failure. On small-to-medium repos the fused relevance scores are also nearly
flat, so ranking carries little signal.

## Evaluate it each time, and say so

`code-review-graph` is on trial. Whenever you use it for something non-trivial, add a
one-line verdict to your reply: did it beat the alternative lane, was it right when you
checked it, did stale data mislead you. Report misses as readily as wins -- a tool that only
ever gets good reviews is not being evaluated -- and raise reservations about continued use
as soon as they form rather than accumulating them silently.

## Caveats when using the MCP

* The IDE must be running and the project indexed. Fresh checkouts or just-edited files
  may lag for a moment. If the IDE is not running and/or the Jetbrains MCP is not available, you can fall back on the other tools.
* `analyze_calls` focuses on function calls; for broader reference tracking (imports,
  subclass declarations), inspect the file context manually or fall back to `ag`.
* Occasionally a `filePath` in a result comes back as a bare/short path missing the
  project prefix. Canonicalize against the `filePath` you passed in if you need stable
  absolute paths.
* Sometimes the IDE index may include files that are not in the project source --
  especially Python or JavaScript package files from `.venv`. If you find that MCP tools
  return results outside the project source directories, it is probably misconfigured.
  **How to detect**: a result is suspect if it (1) falls outside the project root
  directory entirely, or (2) sits under any `.venv*` directory. Both conditions indicate
  the index is pulling in files that should be excluded -- not a tool bug, but a
  configuration drift to surface. Let me know if this happens -- it can occur after a
  Python upgrade or an IDE project configuration change. Fall back to command-line tools
  for searches outside the project source directories.
