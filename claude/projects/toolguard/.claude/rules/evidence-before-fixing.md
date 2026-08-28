# Measure a ticket's real exposure before fixing it

**Applies to**: every ticket in the TOO-45 fix queue, **including ones Arnon has already approved.**

Arnon, 2026-08-20: *"even for the tickets that I approved to fix - before fixing any of them - spend a bit of time looking at the toolguard logs... to measure the evidence of how relevant a ticket actually is... Just like the sudo case that you misjudged, I may also have been too eager to approve things that are not a real exposure."*

## Why this exists

**toolguard works.** Very few defects have ever surfaced in the field; essentially all of them were found by analysis. The strongest single datum: ticket 78 fixed a genuine deny-rule bypass, and a replay of **26,530 real commands across pre- and post-fix trees produced 0 decision changes, 0 matched-rule changes, 0 digest differences.** A real bug, correctly fixed, that had never once fired.

The `sudo` case is the cautionary one in the other direction: a ticket filed as a security bypass, approved for fixing, and then found on inspection to be **faithful behaviour** whose evading command cannot even execute. Approval is not evidence.

## The corpora

| corpus | files | character |
|---|---|---|
| `~/projects/flowers/featherhill/logs/` | **140** | **a real user project — the valuable one**, since it is not toolguard developing itself |
| `/home/arnon/projects/toolguard/logs/` | 68 | dogfood; heavily biased toward toolguard's own development commands |
| `~/projects/instagram-downloader/logs/` | 7 | small third sample |
| `test/verdict_corpus/` | — | curated cases, not field evidence — do not count it as exposure |

**Weight featherhill above toolguard's own logs.** A defect that only ever appears in toolguard's dogfood may be an artifact of this repo's unusual rule set.

## The procedure, per ticket, BEFORE any implementation

1. **Count actual occurrences** of the triggering shape in the combined corpora. Report the number even when it is zero — especially when it is zero.
2. **If zero, estimate likelihood rather than stopping.** Would a user plausibly write it? Does it need deliberate spelling, or does it arise by accident?
3. **Assess the risk if it did fire** — what is the worst outcome, and would anyone notice? A false negative on a deny rule is **silent forever**; a false positive on an allow rule surfaces as a spurious prompt somebody can report.
4. **Apply the reachability filter.** toolguard governs Claude, not an adversary. Claude does not prepend `env` to dodge a deny rule or spell a path `~arnon` to slip past `/home/arnon`. A defect needing deliberate evasion is a threat model this project does not have.

## What to do with a defer candidate — DO NOT act unilaterally

**Move it to the bottom of the queue AND flag it for Arnon to re-decide.** Do not skip it, do not quietly drop it, and do not treat his earlier approval as settling the question — the whole point is that the approval may have been given without this evidence.

Record the measurement in the ticket file itself, so the re-decision is made against numbers rather than against the ticket's original framing.

## The one thing this filter must NOT be used to wave away

**Absence of field evidence is weak evidence when the failure mode is silent by construction.** Nobody reports "my deny rule did not fire" — they never learn it did not. This campaign's single most repeated finding is *a mechanism that fails open and says nothing*. For that class, a zero count measures the observability of the bug, not its absence.

So: **zero occurrences plus accidental reachability plus silent failure** is still a fix. Zero occurrences plus deliberate-evasion-only is a defer.

---

## A related rule for INSTRUMENTS: name the declaration, or label it a heuristic

Established 2026-08-20 from Arnon's observation that *"some findings in architectural fitness are unambiguous and actionable"* — which is true, and the reason is specific.

**A check is unambiguous exactly when it measures conformance to intent a human declared, rather than inferring whether the intent is any good.**

| check | what it compares against | strength |
|---|---|---|
| `--layers` completeness | the layer map in `.pyscn.toml` — every module must have an entry | **strong**: binary, total, no threshold. It never judges whether `foundation` is the right home, only that a home was declared |
| `--layers` edges | the declared legal imports | **strong**, same reason |
| `--ambient` owner entries | `PATH_AMBIENT_OWNERS` | **strong for what is listed** |
| `--ambient` *enumeration* | a human judgement about which `pathlib` members count as ambient | **WEAK — and this is where three live defects escaped.** `expanduser`, `resolve` and `absolute` each got through by not being on the list yet. The check was rigorous about what it had been told and blind to what nobody had declared |
| `--mocks` | a heuristic for inertness | signal only |
| cognitive complexity | a threshold | signal only — sends you to look, which is its whole value |

**So, before proposing any new check: name the declaration it checks against.** If there is no declaration — if the tool has to supply the judgement itself — it is a heuristic, and it must be labelled one rather than reported as a verdict.

**The consequence for architecture documentation is the strongest argument for writing it down.** Declaring a decision in an explicit, machine-readable form is what converts a mushy architectural question into a checkable one. The tool does not get smarter; the intent gets declared. Ticket 85 is exactly this shape: consolidating the contract makes *"does this module touch the external contract?"* an import edge, so `--contract` can check conformance — strong. Whereas *"is our contract still current?"* stays uncheckable by any static means, because no declaration here can capture what Claude Code changed upstream.

---

## Rule shapes and command shapes are different kinds of evidence

Added 2026-08-20, refining "weight featherhill above toolguard's own logs." That instruction is right for **rule** shapes and too blunt for **command** shapes.

- **A rule shape is project configuration.** `~/projects/**`, `uv run pytest :*`, a `[regex]` git rule — somebody wrote these for one project. toolguard's own rule set is unusual (it governs its own development), so **rule-shape counts from toolguard's logs are dogfood-biased and featherhill is the honest sample.** Tickets 18, 21, 17, 83, 84 are all rule-shape tickets and must be read that way.
- **A command shape is agent behaviour.** `$(...)`, backticks, a leading `env`, a redirect — these are what *Claude* emits, and Claude behaves broadly the same across projects. So a command-shape count from either corpus carries information about the agent, not just about the project.

**But the correction has a limit, measured on the spot.** Command substitution appears in **2.1%** of toolguard's commands and **0.1%** of featherhill's — a 20x gap. So command shapes are *also* project-dependent, because the work differs: toolguard development is shell-heavy in a way flower-shop development is not.

**How to apply:** for a rule-shape ticket, read featherhill and treat toolguard's count as near-worthless. For a command-shape ticket, read both and treat the **gap between them** as the estimate of how much is task-specific. Never quote a combined total as though it were one population — that is what made ticket 36 look like a 657-occurrence problem when 652 of those are this repo's own mandated disclosure comments.

---

## A corpus replay MUST compare `matched_rule`, not just the decision

Found 2026-08-20. The replay compares `allow`/`deny`/`ask` per command. **It cannot see a rule going from not-matching to matching when the fallback already permits** — and this repo sets `no_match_fallback = "allow_with_no_warnings"` (`.claude/toolguard_hook.toml:4`, TEMPORARY pending TOO-28), so an unmatched command was already a silent `allow`.

**Measured**: `Bash(\obsidian search:context *)` matched nothing at HEAD and matches now; ticket 18's replay reported "zero flips across 53,112 decisions" and read it as safety. It was neither safety nor inertness — it was a null over an unobservable transition.

**So: compare `matched_rule` alongside `decision` in every replay**, and before believing any null result, plant a change you know should appear and confirm the instrument shows it. Full analysis: `toolguard-memories/TOO-45/reports/replay-instrument-blind-spot.md`.

**BETTER METHOD (Arnon, 2026-08-20)**: re-score the corpus **as if `no_match_fallback` were `ask`**, regardless of what this repo sets. A command matching no rule then scores `ask`, so a rule that starts matching shows a real `ask -> allow` flip. That makes the instrument sensitive instead of requiring a second field to be eyeballed, and it models the default configuration. Provenance already distinguishes a fallback from a real match — the log writes `[fallback allow -- no rule matched]`.

**Measured scope of the blind spot**: featherhill **0 fallbacks in 3,675 decisions (0%)**; toolguard **9,848 of 51,918 (19%)**; instagram 0. So featherhill-based evidence was never masked, and this is a third independent reason to weight featherhill over dogfood.

## The dogfood corpus records THIS investigation, so it inflates its own evidence

**Measured on ticket 19, 2026-08-21.** Counting the corpora for the ticket's remaining bypass shapes gave 11 hits for P2, 9 for P3 and 10 for P4 in `toolguard/logs` — against a punch-list note that had skipped P4 on "measured zero exposure". Printing the matching lines resolved the contradiction: **nearly every hit was this campaign's own diagnostic probe**, plus the text of `follow-up-queue.md` being echoed into a log. Genuine field occurrences outside the investigation: approximately zero, in both directions.

The mechanism is structural, not a mistake. toolguard governs this repo's own agent, so **every probe run while investigating a defect is logged as a command exhibiting that defect's shape.** The more carefully a defect is investigated, the more "evidence" of it the dogfood corpus accumulates. featherhill is unaffected — nobody investigates toolguard there — which is a further reason it is the corpus that counts.

So, whenever a shape count in `toolguard/logs` is small (say under ~50):

- [ ] **Print the matching lines. Never report the count alone.** The count is uninterpretable at this scale.
- [ ] Discard hits that are probes, test fixtures, or ticket/report prose quoted into a log.
- [ ] Report the surviving count and the discarded count separately.
- [ ] If featherhill is zero and toolguard's hits are all probes, the honest finding is **zero**, not the raw number.

This cuts both ways and the second direction is the dangerous one: it inflates evidence *for* fixing something that never occurs in the field, which is precisely the over-eagerness this rule exists to prevent.

**It also means an earlier "measured zero" can disagree with a later "measured ten" with neither being wrong** — they were taken before and after the investigation that manufactured the hits. Date every exposure measurement, and prefer the earliest one taken before work began.

### CORRECTION, same day — featherhill is NOT immune, and that claim was the dangerous half

The section above says *"featherhill is unaffected — nobody investigates toolguard there."* **Measured false within two hours of writing it.**

`~/projects/flowers/featherhill/logs/toolguard-2026-05-11.md` contains a run of `find` probes — `find . -maxdepth 1 -name 'CLAUDE.md' -type f -exec echo {} \;` three times over, and `find . -maxdepth 1 -name 'nonexistent-CLAUDE.md' -delete`. The `nonexistent-` prefix and the `-exec echo` payload are unmistakable: somebody was testing toolguard's `find` handling **with featherhill as the working directory**. Of 9 apparently-genuine `find -exec`/`-delete` commands in that corpus, **8 are probes and 1 is real work.**

**The mechanism is that toolguard governs the agent, not the project.** Any directory that agent is standing in when it investigates toolguard receives the probe traffic. featherhill's protection was never structural — it was only that fewer investigations have happened there.

**This is the more dangerous error of the two**, because featherhill is the corpus this rule tells you to weight above all others. An inflated count there does not get discounted; it gets believed.

So the print-the-lines checklist above applies to **every** corpus, not only to dogfood. Additional tells for probe traffic, all observed in that one file:

- a deliberately harmless payload where a real command would do work — `-exec echo`, `--version`, `true`
- a target named to guarantee no effect — `nonexistent-*`, `/tmp/x`, `foo-xyz`
- the same command repeated 3+ times with one token varied, which is a matrix, not work
- a cluster of related shapes inside a few minutes on one date
- **the date matching a toolguard investigation** — check `git log` for that day before trusting a spike

**And the corollary that actually protects you: a corpus is evidence about a DATE RANGE, not about a project.** When a count concentrates on one or two days, that is the signal to look at what was being investigated then — not a signal that the shape is common.

---

## An isolation instrument must be validated IN THE SAME INVOCATION FORM as the measurement

**Measured 2026-08-21, on ticket 19, and it nearly shipped a security regression.**

A review reported that the fix dropped the ASK floor for `python $(true; true) <<EOF` and called it a regression. To check, I copied the package to a scratch directory, swapped in `git show HEAD:...multiline.py`, and ran the same fixtures against both trees. **They agreed exactly, so I concluded the reviewer was wrong, and told the implementer not to fix it.**

They agreed because **both runs imported the working tree.** The comparison script lived in the scratchpad, so Python put *the script's* directory on `sys.path` — not the HEAD copy. The HEAD tree was never loaded.

**I had "validated" the isolation** — planted a marker in the HEAD copy and confirmed it was visible. But that check ran via `python -c`, where `sys.path[0]` is the **cwd**, while the measurement ran a **script file**, where `sys.path[0]` is the **script's directory**. The validation proved isolation for an invocation that never happened.

Redone with `PYTHONPATH` pinned: HEAD `ask`, working tree `allow`, on every shape. **The reviewer was right and my null was an artifact.**

### The rule

**Emit provenance from inside the measurement itself, in the same process that produces the numbers.** Not from a separate command, not from a prior check.

```python
import toolguard.parser.multiline as m
print("MODULE:", m.__file__)          # printed by the run that produces the data
print("MARKER:", getattr(m, "MARKER_CHECK", "absent"))
```

A separate validation step tests a different execution, and the ways two Python invocations differ in `sys.path` are numerous and silent: `-c` vs script vs `-m`, cwd, `PYTHONPATH`, an installed distribution shadowing a source tree, a stale `__pycache__`.

### Why this is the same failure this project keeps finding

This campaign's signature defect is **a mechanism that fails open and says nothing**. My instrument did exactly that: when isolation failed, it did not error — it produced a clean, plausible, *symmetric* result. A null that looks like proof.

**And note which way the error cut.** It let me dismiss a correct finding about a real floor loss, on my own authority, against an expert reviewer who had done the work properly. **Prefer the reviewer's finding when your refutation rests on a null**, and re-examine the instrument first — the asymmetry is that a false positive costs a wasted round, while a false negative ships the bug.
