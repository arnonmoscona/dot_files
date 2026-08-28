---
paths:
  - "toolguard/parser/**"
  - "**/*.peg"
  - "toolguard/parser/command_extractor.py"
---

# Changing the bash grammar: two phases, in this order

All bash parsing lives in `toolguard/parser/bash_parser.peg`. `canopy` generates the base
parser from it. **Never hand-roll parsing in Python** -- not regex, not a tokenizer, not tree
walking that recovers structure the grammar should have produced.

This procedure exists because the instruction alone has repeatedly failed: grammar changes get
implemented as convoluted Python even when the prompt explicitly says to use the PEG grammar
and canopy. Treat the phase gate as the mechanism, not the reminder.

- [ ] **Phase 1 -- grammar only.** Use the `feature-coder` subagent. It edits *only* the
      `.peg` file and validates by running `canopy` on it. **No Python file changes at all,**
      including the generated parser if that would obscure the diff. Stop and hand back for
      review.
- [ ] **Review the PEG diff** before authorizing phase 2.
- [ ] **Phase 2 -- Python side.** Re-invoke `feature-coder` to complete the change.
- [ ] **Review again.** Two specific failure modes to look for:
      - New logic that still belongs in the grammar, smuggled into Python.
      - Overly complex tree-walking. If the processing code is hard to read, the fix is
        usually to enrich the intermediate representation first, which makes the consuming
        code simple.

## Why the grammar is deliberately incomplete

It is not a full bash grammar and should not become one. It covers the compound-command
patterns Claude Code actually emits, because that is what has to be split into leaf commands
for per-part rule matching. Resist scope creep toward general bash coverage.

The generated parser depends only on the standard library, so this adds no runtime dependency
-- `canopy` is a dev-machine tool only. Keep it that way.

<!--
Maintainer notes (stripped before entering context).

Extracted from toolguard/CLAUDE.md (the "Claude bad tendencies" section) and path-scoped, so
it loads when parser or grammar files are touched instead of in every session.

Reframed from prose narration of Claude's tendencies into a checklist the agent ticks through
-- which is what Arnon's own global directive on long runbooks asks for, and what the official
guidance says to do with multi-step procedures. The content is unchanged; only the shape and
the trigger are different.

A PreToolUse hook rejecting Python edits under toolguard/parser/ while a phase-1 marker file
is present would make the gate actually enforced rather than merely written down. Worth
considering if it regresses again.
-->
