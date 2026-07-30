Run a comprehensive review of toolguard's own documentation (README.md, AGENTS.md, llms.txt,
everything under docs/, technical-notes.md, and the skills' SKILL.md/passes files). This
codifies the method used for the doc audits recorded in
tmp/too15-doc-audit-findings.md and tmp/too15-doc-audience-audit.md -- read those first if
they still exist, both for the method and to avoid re-flagging something already discussed
and deliberately deferred/ignored there.

Scope: unless the user names a git ref/tag to diff against (an "since we last did a big pass"
style request), review the CURRENT state of the docs, not a diff -- this command is meant to
be run periodically (e.g. before a push), not just once after a large ticket.

Do THREE passes. Do not skip any of them; they catch different things.

## Pass 1 -- fact-accuracy audit

For every doc, find every claim that names a specific config key, CLI flag/subcommand, file
path, default value, or behavior, and VERIFY it against the actual source code -- grep/read
the real implementation, don't just check that two docs agree with each other (two docs can
agree and both be wrong; this has happened before in this project). Specifically hunt for:

- A config key or CLI flag documented that doesn't actually exist in code (a fabricated or
  since-removed capability).
- A config key or CLI flag that exists in code but isn't documented anywhere.
- A "complete"/"full reference" section (e.g. configuration.md's Configuration reference)
  that is stale relative to the actual schema.
- Stale invocation forms -- `uv run python -m toolguard.scripts.X` or similar dev-only forms
  shown as the default where an installed console script now exists (this exact bug has
  recurred multiple times across different files; grep for `uv run python -m
  toolguard.scripts.migrate_permissions` and similar patterns specifically).
- A setting documented in one place with a nested/qualified form (e.g. inside a `[section]`)
  when the code treats it as a different location (top-level vs nested), or vice versa.
- Claims about a safety/protection mechanism ("can never be deleted", "always enforced") that
  don't hold in every case the doc's own context implies -- verify the mechanism's actual
  scope, don't take the doc's own confidence at face value.
- **Tooling that is not toolguard and not stock Linux/macOS.** Toolguard's documentation may
  only assume a normal Linux or macOS environment plus toolguard itself. Any recommendation to
  use an editor integration, an indexing service, a knowledge-graph or MCP server, or another
  optional tool is leakage from someone's personal setup and must be removed -- a reader cannot
  act on it, and it tends to be stale too (a real instance recommended a graph query that this
  project's own CLAUDE.md documents as returning false results here). Naming an MCP tool as an
  *example of a governed tool* is expected and fine; recommending one as *tooling to use* is not.
- **Any exhaustive listing, verified mechanically rather than read.** A doc that enumerates
  something -- modules, config sections, CLI flags, environment variables, governed tools --
  is claiming completeness, and completeness decays silently as code is added. Reading such a
  listing tells you nothing; only a diff against reality does. Generate the real set and
  compare:

  ```bash
  ls toolguard/ toolguard/*/          # vs architecture.md's package structure
  grep -oE '"[a-z_]+"' toolguard/config_validation.py   # vs configuration.md's sections
  grep -n 'add_argument' toolguard/**/*.py              # vs documented CLI flags
  ```

  A real instance: architecture.md's package structure listed 17 modules when there were 25,
  and omitted the entire `tools/` subpackage (~30 modules, the whole operator tooling surface)
  and `testing/`. An agent orienting itself there would conclude `resolve.py` and every audit
  and maintenance command did not exist. Invisible to reading; obvious to `ls`.

Verify claims independently -- read the actual source (`toolguard/`, `toolguard/tools/`,
`toolguard/scripts/`), not just other docs.

**Where a claim depends on Claude Code's own behavior rather than toolguard's code, say so
explicitly instead of asserting it, and do NOT try to settle it from toolguard's logs.** The
logs record the verdict toolguard *returned*, never what Claude Code then *did* with it. A
logged `Status: ASK` followed by the command executing is exactly what an approved prompt
looks like -- it is indistinguishable from a bypass, so it cannot establish either. Reasoning
of that shape produced a wrong, safety-relevant claim ("an ASK does not block in auto mode",
false) that reached three artifacts before being caught. If a doc you are cross-linking to
already states the opposite, read it: in that case `auto-mode.md` already said an unanswered
ask hangs an unattended run, which is only true if the ASK blocks.

## Pass 2 -- audience and structure audit

Read every doc in full against three audiences:

- **Impatient humans**: will read a couple of README paragraphs and maybe the quickstart, if
  short and clearly signposted. Nothing else, ever.
- **Agents**: the primary readership of most of this documentation (AGENTS.md, llms.txt,
  agent-guides.md, docs/agent-map.md, install.md, uninstall.md are explicitly agent-facing).
- **Diligent humans**: will read a whole doc, or hunt down one specific section, and need
  navigation to work either way.

Check specifically:

- Is the impatient-human path clearly and prominently signposted from README (not buried)?
- Do the docs billed as "usually enough on its own" for agents (agent-guides.md, AGENTS.md)
  actually cover the capabilities that exist, or silently omit whole areas (a silent gap
  reads as "not needed," which is worse than an explicit "see X for this")?
- Do large files (roughly 400+ lines, or 15+ headings) have adequate internal navigation --
  a table of contents, or at minimum well-anchored, jump-to-friendly headers?
- Does every file state its audience/purpose in its opening paragraph? (Every doc in this
  project is expected to, following technical-notes.md's fix for this.)

## Pass 3 -- agent-map.md and cross-reference link freshness

A dedicated pass, not a bullet inside Pass 2 -- `docs/agent-map.md` is the single biggest
drift risk in the whole documentation set (it summarizes every other doc's headings plus a
curated Q&A list, and nothing else keeps it in sync automatically), and stale internal links
are a mechanical, easy-to-miss bug class distinct from the judgment-heavy work of Pass 1/2.

1. **Regenerate `docs/agent-map.md`'s master table of contents.** Walk every doc's
   `##`/`###` headers (skip anything inside code fences), compute GitHub's anchor-slug
   algorithm, and disambiguate duplicate slugs the way GitHub does (`-1`, `-2`, ...). Diff the
   result against what the file currently has. Any file added, removed, renamed, or re-headed
   since the map was last updated will show up here as a diff.
2. **Spot-check the "Questions and pointers" section.** For each entry, confirm the linked
   anchor still exists in the target file -- headings get renamed or reordered without anyone
   remembering to update every pointer to them. This section has no regeneration path, so it
   is the most likely piece to silently drift.
3. **Sweep for broken or stale internal links project-wide.** Do NOT hand-compute slugs --
   run the committed checker, which is the whole point of it existing:

   ```bash
   uv run python tools/check_doc_links.py
   ```

   It walks README.md, AGENTS.md, llms.txt, technical-notes.md, CLAUDE.md, `docs/` and
   `skills/`, and exits non-zero on any unresolved anchor. **Two traps have now produced real
   breakage twice, and both are baked into the checker -- do not "simplify" them back out:**

   - GitHub **keeps underscores** in anchors. An anchor regex of `[a-z0-9-]+` cannot even match
     `#why-no_match_fallback...`, so it skips exactly the links most likely to be wrong. This
     caused a false clean bill of health on 2026-07-23 and again in the first pass on
     2026-07-29.
   - GitHub **does not collapse runs of hyphens**. Punctuation between words leaves consecutive
     hyphens: `"Phase 0 -- Preflight"` -> `#phase-0----preflight` (four). Note that softening
     `--` to `-` does NOT fix this -- the spaces around it still become hyphens
     (`#phase-0---preflight`). Only a heading with no separator punctuation slugs cleanly
     (`"Phase 0: Preflight"` -> `#phase-0-preflight`). Prefer that form for NEW headings;
     do not mass-rename existing ones, since every inbound link would have to move with them.
4. **Confirm `llms.txt` and README's documentation table list every doc under `docs/`.** A new
   doc file added without updating either is the same class of gap as the missing
   `auto-mode.md` entry found and fixed in an earlier pass -- check for it explicitly rather
   than assuming it can't recur. **`AGENTS.md` is deliberately NOT in this list**: it is a
   router (install.md / agent-guides.md / skills.md / llms.txt / agent-map.md), and
   enumerating docs there was rejected as reintroducing the duplication drift that
   `tmp/too15-doc-audience-audit.md` Findings 5-6 removed. Do not "fix" it.

## Output

Write findings to a new markdown file in tmp/ (name it for this run, e.g.
tmp/doc-review-<date>.md), each with a distinct number, verified evidence (not just
assertion), and enough context to discuss without re-deriving it. Follow the exact format of
the two prior audit files in tmp/ if they're still present. Open the file in the IDE. Do NOT
make any changes to the documentation itself in this pass -- this command only produces
findings for discussion, exactly like the two prior audits. Wait for explicit per-finding
direction (fix / defer / ignore) before editing anything, and keep the findings file updated
with the outcome of each as you go, the same way the two prior audits recorded resolutions
inline.
