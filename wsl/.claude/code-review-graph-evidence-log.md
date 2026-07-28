# code-review-graph: cross-project evidence log

A running record of real-world uses of `code-review-graph`, kept **globally** (not per
project) so evidence accumulates across every repo where the tool is installed.

## Why this exists

The tool is on trial. Arnon's standard (2026-07-25): *"it would be too early to draw any
concrete conclusions before we have at least something like 100 real-world uses across
several of the tools it provides"*, and *"one instance is information but it is not a
statistic."*

So: **log observations, do not draw conclusions.** Do not generalize from a single
disappointing result, and do not let a single good one settle the question either. A
reservation about continued use is worth raising only when a PATTERN shows up across many
uses. If you find yourself wanting to declare a verdict, check the count first.

## The real question: does it beat the IDE, not does it beat grep

Sharpened by Arnon 2026-07-27, and it materially raises the bar:

> *"some of its functionality overlaps with tools provided by the IDE... From experience we
> know that the IDE keeps its indexes up to date automatically and with very low latency and
> that things like identifying usages (such as callers, but also all symbol usages) are very
> reliable."*

The JetBrains MCP is the **incumbent to beat**, not `ag`. It is compiler/PSI-informed rather
than AST-heuristic, auto-indexes with low latency, and is reliable on exactly the primitives
the graph also offers. So "the graph answered my question" is NOT evidence of value — the
IDE probably would have too, faster and more accurately.

**Working hypothesis to test (falsify it either way):** the graph's unique value is in the
AGGREGATE/ANALYTICAL layer the IDE has no equivalent for --

- `get_impact_radius_tool`, `get_affected_flows_tool` (blast radius, execution paths)
- `detect_changes_tool` (risk-scored change review)
- `get_architecture_overview_tool`, communities, `get_bridge_nodes_tool`
- cross-session persistence, and working with **no IDE running at all**

...while for the PRIMITIVES (callers, usages, definitions, signatures) the IDE should win on
both accuracy and latency. If that hypothesis holds, the conclusion is "use it for the
analytical layer only", not "drop it" or "use it for everything".

**Deliberate paired calls.** To get real head-to-head data, run BOTH tools when both can
answer, even though that is more MCP calls than the task needs. Arnon explicitly accepted
that cost for the duration of the trial. Record which won.

A concrete precision concern already open: `query_graph_tool(callers_of)` once reported
"Found 7 result(s)" while listing 5, and an independent grep found 6. Whether that is
minimal-mode truncation or a real edge gap is UNRESOLVED — re-check it on the next
opportunity, and compare against `mcp__jetbrains__analyze_calls` on the same symbol.

## How to log

Append one bullet per non-trivial use. Keep it short. Record:

- **which tool**, and the question you were actually trying to answer;
- **the alternative you compared against** -- JetBrains MCP where it could have answered
  (state which tool), otherwise `ag`/reading, otherwise "none available (no IDE running)";
- **verdict**: beat / tied / lost against that alternative -- and on WHAT axis (correctness,
  completeness, latency, tokens, effort);
- **was it correct** when you verified it independently;
- **if it missed** -- TOOL's fault or QUERY's? A badly-shaped question, or one asked after
  you already knew the answer, proves little about the tool.

Also log uses that went WELL. A log full of only complaints is as useless as one full of
only praise, and both mean the trial was not run honestly.

Roughly tally as you go so the sample size stays visible.

**Code reviews are the highest-value sampling opportunity** -- they ask exactly the
multi-hop structural questions the tool claims to be good at. The `/code-review` skill
(step 1b) now requires an evaluation note per review. Refresh embeddings/flows/communities
BEFORE reviewing, or the sample is contaminated by staleness rather than measuring the tool.

---

## Running count

Split by layer, because the hypothesis above predicts they behave differently.
`vs IDE` counts only uses where the JetBrains MCP could also have answered.

**Primitives** (IDE has an equivalent — `search_symbol`, `analyze_calls`, `get_symbol_info`):

| tool | uses | beat | tie | lost | vs IDE (w/l/untested) |
|---|---|---|---|---|---|
| `semantic_search_nodes_tool` | 3 | 0 | 1 | 2 | 0/0/3 |
| `query_graph_tool` | 1 | 0 | 1 | 0 | 0/0/1 |

**Analytical** (no IDE equivalent — this is where value is expected):

| tool | uses | beat | tie | lost | vs IDE |
|---|---|---|---|---|---|
| `get_impact_radius_tool` | 2 | 1 | 0 | 1 | n/a |
| `list_graph_stats_tool` | 1 | 1 | 0 | 0 | n/a |

| **total** | **7** | **2** | **2** | **3** | **0/0/4 untested vs IDE** |
|---|---|---|---|---|---|

**Sample is far too small to conclude anything** (Arnon's bar: ~100 uses across several
tools). Note the glaring gap: **every primitive-layer use so far was logged WITHOUT an IDE
comparison**, which is exactly the data the trial most needs. Fix that from here on.

---

## EXIT CHECKLIST -- run this when the trial concludes

**The trial added temporary scaffolding in several places. It does not remove itself.**
Whichever way the verdict goes, tick every box -- do not leave the evaluation overhead
(paired MCP calls, per-review evaluation notes) running forever after the question is
settled, and do not leave dangling references to a tool that was removed.

Decide first: **ACCEPT** (keep the tool, narrow the guidance to where it actually won) or
**REJECT** (remove it and every reference).

If **ACCEPT**:

- [ ] `~/.claude/code-review-graph-search.md` -- delete the "Report back on whether this
      tool is earning its keep" section; keep the staleness precondition table (that is
      permanent operational fact, not trial scaffolding).
- [ ] `~/.claude/common-search.md` -- delete the "Evaluate it each time, and say so"
      section. **Rewrite the "Reach for it by default" table to list ONLY the tools that
      demonstrably beat the IDE / `ag`** -- drop the rest. That narrowing is the whole
      payoff of running the trial.
- [ ] `~/.claude/skills/code-review/SKILL.md` step 1b -- delete the head-to-head and
      evaluation-note requirements; keep the refresh step ONLY if a kept tool needs it.
- [ ] Project CLAUDE.md files -- drop "on trial" language; state the settled usage rule.
- [ ] `project_crg_staleness_and_usage_policy` memory -- rewrite as settled policy.
- [ ] This file -- keep as the archived evidence that justified the decision. Mark it
      CLOSED at the top with the date, the verdict, and the final tally.

If **REJECT**:

- [ ] `~/.claude/skills/code-review/SKILL.md` -- remove steps 1a AND 1b entirely.
- [ ] `~/.claude/common-search.md` -- remove the whole "Structural graph search" section.
- [ ] Delete `~/.claude/code-review-graph-search.md` and
      `~/.claude/code-review-graph-review.md`.
- [ ] Project CLAUDE.md files -- remove the code-review-graph sections (in `toolguard`'s
      case: the MCP Tools section, project-specific caveats, and periodic-maintenance
      block).
- [ ] Remove the MCP server registration (`.mcp.json`) and the `SessionStart` /
      `PostToolUse` hooks that run `code-review-graph` (in `toolguard`:
      `.claude/settings.json`, both hooks).
- [ ] `uv tool uninstall` / remove the package; delete the gitignored
      `.code-review-graph/` directories.
- [ ] `project_crg_staleness_and_usage_policy` memory -- delete it.
- [ ] This file -- keep as the archived rationale, marked CLOSED/REJECTED with the tally.

Either way:

- [ ] Grep `~/.claude/` and every project for `code-review-graph` and `crg` to catch
      stragglers; a half-removed tool is worse than either outcome.
- [ ] Tell Arnon what was changed, and confirm the dot_files repo diff is what he expects
      (these files are version-controlled via the `~/.claude` symlink).

## Log

### 2026-07-25 -- toolguard, TOO-19 Phase 0a

- **`semantic_search_nodes_tool`** -- "find `normalize_entry` / `RuleEntry`", written the
  same day. **Lost.** Returned five unrelated older functions and none of the new code.
  **Tool's fault via drift, not ranking**: embeddings had not been recomputed since install
  (see the staleness section in `code-review-graph-search.md`). After `embed`, the same
  class of query did surface the new code. Root cause fixed via a SessionStart hook.
- **`list_graph_stats_tool`** -- "is the graph current?" **Beat the alternative.** The most
  valuable output of the day came from inspecting the tool rather than querying it:
  `embeddings_count` had not moved since install, which is what exposed the drift above.
  Nothing else would have surfaced that.
- **`semantic_search_nodes_tool`** -- "is there already a predicate that checks whether a
  string is a `Tool(...)` wrapper?", asked retrospectively after a subagent shipped
  `_is_wrapper_shaped` duplicating the existing `is_tool_wrapper`. **Lost, partially.** Did
  not return `is_tool_wrapper` in the top 6; returned `wrap_tool_pattern`, its adjacent
  sibling in the same file -- a lead a developer would follow. **Weak evidence**: query was
  constructed after already knowing the answer. Also note relevance scores on this repo are
  near-flat (~0.016, an RRF fusion artifact), so ranking carries little signal at this size.
- **`semantic_search_nodes_tool`** -- same concept query re-run after `embed`. **Tie.**
  Surfaced the day's new tests and `reassemble_permissions_section`. Better, but still not a
  precise hit on the target function.
- **`get_impact_radius_tool`** -- "what depends on `config_validation.py`?" before editing
  it. **Lost.** Returned "480 nodes impacted, 90 files, risk: high", with test-infrastructure
  files as the key entities. Technically true but not actionable -- it mostly restated that
  `config.py` is a hub, which was already known. **Query's fault as much as the tool's**: the
  real question was the much narrower "who calls `validate_permissions`", and impact-radius
  is the wrong granularity for that. Lesson: match the tool to the question's scope.
- **`query_graph_tool`** (`callers_of` `validate_permissions`) -- the narrower re-ask.
  **Tie.** Clean and fast, and classified results by `kind: Test` for free, which `ag` does
  not. But `ag` would have answered in one call too. **Precision caveat worth watching**: in
  `minimal` mode it reported "Found 7 result(s)" while listing 5, and a subsequent grep by
  the implementing subagent found **6** test callers, not 5. Unresolved whether that is
  truncation in minimal mode or a real edge gap -- **re-check this on a future use before
  trusting counts from this tool as exhaustive.**

### 2026-07-26 -- toolguard, TOO-19 Phase 0b write-path tracing

- **`get_impact_radius_tool`** (`rule_sort.py`, `depth=1`, `minimal`) -- "what does the
  write path touch before I widen its payload type?" **Beat the alternative.** Named
  `migrate_permissions.py`, `generate_permissions_section`, `write_json_config`,
  `write_toml_config`, and surfaced `annotate.py` (a Phase 0b consumer I had not yet
  considered) in ONE call. Reconstructing that with `ag` took several greps afterwards to
  confirm, and it was correct on all five. **vs IDE: n/a** -- no JetBrains equivalent for
  blast radius, which is the point.
  **Caveat worth remembering:** `detail_level="standard"` at `depth=2` returned **348,000
  characters** and blew the tool-result limit outright. `depth=1` + `minimal` was
  immediately useful. Default to minimal/shallow and widen only if needed.

**Session note (not a tool verdict):** the work that dominated this session -- exhaustive
enumeration (all 18 `hard_deny()` call sites, all 69 import sites, whether any dataclass
annotation referenced `Configuration`) -- is a poor fit for ranked graph results, and `ag` +
purpose-written AST scripts were the right lane. That is evidence about *question shape*,
not about tool quality. The fair test is still pending: TOO-19 increments 8/9 widen a
payload across `toolguard_permissions` -> `config_divergence` -> `migrate_permissions` ->
`rule_sort` -> `rule_apply`, which is a genuine multi-hop tracing question where `grep` is
weak.
