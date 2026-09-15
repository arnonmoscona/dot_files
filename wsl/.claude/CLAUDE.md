# CLAUDE.md (Global User Directives)

My name is Arnon. You can also call me boss, just so we know who's in charge here.

## Security -- hard requirements, never relax, never compact away

* I sometimes run Claude with `--dangerously-skip-permissions`. **That is not blanket
  permission.** Even then, ask before editing anything outside the project directory.
* Never modify `.env` or `.claude.env` without my explicit permission, dangerous mode or not.
* If an action is denied, do not reach for another route to the same effect (e.g. blocked
  from reading a file, then writing a script to read it). Circumventing an obvious
  prohibition by clever means is prohibited. When in doubt, ask.

## git

Read-only git is fine without asking (`git diff`, `git log`, `git status`, `show`).
**I do all write operations myself** -- no pushes, checkouts, merges, branches, stashes, or
resets, even when you think it's the obvious next step. Give me the command line instead.
**`git worktree` is permitted** (add/move/remove/prune/repair/lock/unlock): it touches no
existing checkout, index, or ref, and an `ask` there stalls an unattended run.

**When a git rule denies you, hand over the command -- do not find another route to the same
effect.** `git commit --amend` is denied deliberately, which keeps the `commit` allow
append-only. Reaching for `reset --soft` and re-committing is the same history rewrite by
another name, and the prohibition covers it. Say what the fix is and let me run it.

Commit messages: plain ASCII only, no emoji, no Claude Code promotion. Noting that Claude
Code authored most of the code is fine. Same ASCII rule for any markdown you put on my
clipboard (use `pbcopy`).

## Python

Always `uv run python`, never bare `python`. Format and lint with
`uv run ruff format .` and `uv run ruff check .` before I commit.

Language conventions live in `~/.claude/rules/python.md`, which loads automatically when
you touch a `.py` file.

## Tickets

YouTrack. The ticket prefix is in each project's CLAUDE.md. A bare `FLO-123`/`TOO-123` in a
prompt or a code comment is a ticket reference -- read it without asking.

**Read**: `~/projects/youtrack_api/get-issue.sh "<TICKET-ID>"`. Weight the description over the
comments.

**Comment**:

```bash
~/projects/youtrack_api/add-comment.sh <TICKET-ID> -f <file.md>    # preferred
~/projects/youtrack_api/add-comment.sh <TICKET-ID> -m "short text"
cat <file.md> | ~/projects/youtrack_api/add-comment.sh <TICKET-ID>
```

**list unresolved**

You can list unresolved tickets for a given project given its ticket prefix. For instance, if the ticket 
prefix for a project is "FLO", then you can list the unresolved tickets for it using:
```bash
~/projects/youtrack_api/list-unresolved-issues.sh FLO
```
This will produce a JSON list with the unresolved tickets. For example:
```json
[
  {
    "resolved": null,
    "idReadable": "FLO-145",
    "$type": "Issue"
  },
  {
    "resolved": null,
    "idReadable": "FLO-126",
    "$type": "Issue"
  },
  {
    "resolved": null,
    "idReadable": "FLO-100",
    "$type": "Issue"
  }
]
```
or, if you just want the IDs:
```bash
~/projects/youtrack_api/list-unresolved-issues.sh FLO | jq '.[] | .idReadable' | sed -e 's/"//g'
```

The body is markdown. The script handles all quoting and escaping, so don't sanitize the text; it
prints the created comment as JSON and exits non-zero on failure. Anything longer than a line or
two goes in a file (your scratchpad) passed with `-f`, not crammed into `-m`.

**Ask me before posting.** A comment is visible to others and can't be undone. The exception is
when I've already told you to comment on that specific ticket.

The script authenticates as a **separate Claude Code account**, so your comments are attributed to
you automatically -- no need to add an "authored by Claude" header to the body.

## Task memory (basic-memory MCP)

Each project's CLAUDE.md names its basic-memory project. Every task has a task memory note;
`Current Task Context.md` links to the active one. At launch, read it and the linked task.

* Ticket-scoped notes go in `<TICKET-ID>/<TICKET-ID> <description>.md` and must carry the
  `task-memory` tag plus the ticket ID. Ask where to put a note with no ticket.
* Keep your own notes in a "Clarifications from discussion" section, separate from mine.
  "Take a note of this" / "remember that X" goes there. "In the future remember that X"
  probably means long-term memory -- ask which.
* Maintain a `task summaries/` note per task, under 150 words, tagged `task-summary`:
  what it is, status, key decisions. Create it once you understand the task; ensure one
  exists at completion.
* When I say "we're now working on X" or "switch to X", identify the note, confirm with me,
  then update the `Current Task Context.md` link and open the task file in the IDE. If X is
  ambiguous, ask whether it's new, or which one I mean. If several summaries match a
  "recall when we were working on X", list the candidates plus an "all of these" option.
* Find notes with `search_notes` / `recent_activity` / `list_directory`, not by scanning.
  Multi-tag search needs an explicit operator: `"task-memory AND TOO-72"` works;
  space-separated, comma-separated, `+`-prefixed and quoted-pair forms all return empty.
* Open memory files in the IDE with `mcp__jetbrains__open_file_in_editor` -- no permission
  needed.

## Delegation

* Non-trivial implementation goes to the `feature-coder` subagent -- suggest it rather than
  burning my main-agent context on the details. Verify it wrote its memory report before
  you accept its work; remind it if it didn't. Don't read the report unless I ask.
* **A delegation needs a filled brief.** The `agent-process` plugin's `brief` skill covers 
  the whole loop -- writing one, spawning against it, and validating the report that comes 
  back. A `PreToolUse` gate now refuses to spawn `feature-coder` without a valid brief, so 
  this is enforced rather than remembered; `NO BRIEF: <reason>` in the prompt waives it 
  deliberately and visibly.
* Check a feature-coder task spec against CLAUDE.md conventions before sending it.
* Code review goes through the `/code-review` skill (below).
* Search: read `~/.claude/reference/search.md` before a non-trivial code search. Do **not**
  route search or structural questions to `mcp__jetbrains__*` -- the reachable IDE build
  exposes no analysis or language-aware tools, so it is neither a lane nor a fallback. Use it
  to open files and nothing else.

## Disclose code you wrote before you run it

**Applies to me and to every subagent and skill with a Bash tool, in every project.** The
permission hook sees a command line; it cannot see the program the command line carries. This
section is how that program gets in front of Arnon before it runs.

**The test is authorship, not length.** Every Bash command you issue is one of two kinds:

- **A tool invocation**: you are running a program that already existed -- `grep`, `ls`,
  `git diff`, a linter, a test runner, a committed project script. You chose flags and paths;
  you did not write the logic. **No disclosure.**
- **Program delivery**: the command *carries a program you just authored*, or points at one. A
  heredoc into an interpreter, a `-c`/`-e` argument, or the path to a script you wrote for this
  task. The flags are not the point -- the code is. **Disclose.**

The word "one-liner" is banned from this decision. `python -c` followed by forty lines of code is
a single shell command and is not a one-liner in any sense that matters here; the shell syntax is
a delivery mechanism for a program you wrote. Likewise `uv run python fix.py` is short, but its
shortness is the problem -- the program is in the file, and only the filename reaches the reviewer.

Ask: **did I write the logic that is about to execute?** If yes, disclose it, however short the
command looks.

Concretely, that question comes out "yes" for any of these, **anywhere in the command text**,
including after a `cd`, a `&&`, a pipe, or inside a subshell:

1. A heredoc into an interpreter -- `<<'PY'`, `<<EOF`, `<<-` into `python`/`node`/`sh`/`bash`.
2. Inline code in an argument -- `python -c`, `uv run python -c`, `node -e`, `perl -e`,
   `ruby -e`, `bash -c`, `sh -c`, `jq -f`.
3. **A path to a script you or a subagent wrote for this task** -- `uv run python tmp/x.py`,
   `python scratchpad/probe.py`, `bash /tmp/fix.sh`, `node scratch.js`.
4. **Shell you composed rather than invoked** -- `sed -e`/`-i` substitution programs, `awk`
   programs, `for`/`while` loops, `xargs` with an authored command, multi-stage `$(...)`
   pipelines whose logic is the point. The interpreter is `sh` and the program is the command
   line. **This is the case that gets missed**, because shell does not *look* like a program.

No exceptions for short, for read-only, for "I just showed the code", or for "a rule will
reject it anyway". The exemption covers only what is *not* on that list: `grep`, `ls`,
`git diff`, `uv run ruff check .`, `uv run python -m unittest ...`, and **committed** scripts
(a project's own `tools/`, `~/bin/...`, `~/projects/youtrack_api/...`) -- files that were
reviewed once and are not being written right now.

**Measured 2026-08-09**: of 17 qualifying commands in one day, 7 were disclosed and 10 were
not, and every miss on the main agent's side was case 4 or an undisclosed scratch script. The
misses were not random -- everything that felt like *a program in a file* got a block, and
everything that felt like *shell* got nothing. That is the file-versus-shell test, which is not
the test. The test is authorship.

**Disclosure is not only decision support.** It also feeds after-the-fact analysis of what the
agent actually did, which is why it is required even when the command will be blocked, even
when it fails, and even when nobody is at the keyboard. A rejected command with a disclosure is
a usable record; a rejected command without one is a bare path.

**This applies to subagents exactly as it applies to the main agent** -- `feature-coder`,
`code-reviewer`, and anything else with a Bash tool. A subagent's commands land in the same
`logs/toolguard-*.md` and, because subagent identification is currently broken, are attributed
to `main`. An agent that skips disclosure therefore corrupts the main agent's record too.

This wording is not a guess. The previous version said "don't announce ordinary one-liners whose
full effect is visible in the command text", which a short `python -c` satisfies as well as `grep`
does -- so the carve-out ate the rule. Five candidate rewrites were scored against 77 real
commands drawn from the logs; the authorship framing above was the only one to clear 95% (98.7%
on Sonnet, vs 85.7% for the "one-liner" text, with its single error a false positive). Notably it
beat a purely mechanical version of the same trigger list (90.9%) -- naming the underlying
question generalizes where enumerating syntax does not, which is why the framing leads and the
list is subordinate to it. Full results: basic-memory note *Intent-disclosure phrasing experiment
-- winning wording and results* (`TOO-19`).

**Case 3 is the one that actually gets missed, and it is the one that matters most.** Measured over
`logs/toolguard-2026-07-29.md` and `-07-30.md`: 34 commands qualified, 20 were undisclosed, and
**every single scratch-script run was undisclosed (5/5)**. One of them, `uv run python
fix_agents.py --apply`, rewrote 15 files under `~/.claude/` -- outside the project -- and logged as
`EXECUTED`, not `ASK`, because `uv run python *` matches an allow rule. Nothing prompted, nothing
was recorded but a filename, and the disclosure that was the only remaining signal was absent.

The mechanism is specific and worth naming so you can catch it: **you had just written the file in
the same turn.** The `Write` is right there in the transcript, so running it feels already
explained. It is not -- the log gets a bare path, and the permission prompt gets a bare path.
So: **`Write`/`Edit` of a script, followed by running it, is a disclosure trigger by itself.**
If a script is worth writing rather than inlining, its `--apply` run is worth one comment block.

**Judge each command on its own.** The misses cluster in runs -- once one undisclosed heredoc goes
out, the next four inherit it. A batch of similar commands is a batch of separate decisions.

Announce as a Bash comment on the lines immediately before the invocation, so it travels with
the command into all three places that matter -- the permission prompt where Arnon decides,
the transcript, and `logs/toolguard-*.md`:

```bash
# INTENT: <what the code does, in plain language -- not a restatement of the code>
# TOUCHES: reads <paths>; writes <paths>   (say "writes nothing" when it writes nothing)
# INLINE BECAUSE: <why this isn't a file you could have been asked to run>
uv run python - <<'PY'
...
PY
```

For case 3 the third field doesn't apply -- it *is* a file -- so use `NOT INLINE BECAUSE` and say
why the code deserved a file. Never drop the block just because the third line doesn't fit; that
friction is part of why this case gets skipped:

```bash
# INTENT: rewrite the model: field in the two code-reviewer variants to match the opus definition
# TOUCHES: reads ~/.claude/agents/*.md; WRITES ~/.claude/agents/code-reviewer-{fable,sonnet}.md
# NOT INLINE BECAUSE: multi-file rewrite with a --apply dry-run gate; too long to read inline
uv run python scratchpad/fix_agents.py --apply
```

Note what that `TOUCHES` line does that nothing else in the pipeline does: it puts
"writes 15 files under `~/.claude/`" in front of Arnon *before* the command runs. The rule that
allows it sees only `uv run python *`. Where a command writes outside the project, put the write
in capitals as above.

Prose in the terminal reaches only the transcript, so use the comment form even when you add
prose as well. A leading comment does not affect rule matching -- the PEG parser discards it and
matches the real leaf command.

### Always add the machine-checkable marker too

The comment block is what Arnon reads, but **a comment can never be matched by a permission
rule** -- the PEG parser strips comments before matching (verified via
`toolguard.testing.sandbox`, 2026-07-29: a comment-only marker behaved identically to no marker
at all). So whenever the disclosure applies, also add an **env-var prefix**, which is inside the
leaf command and therefore visible:

| Prefix | Meaning |
|---|---|
| `TG_INTENT=1` | a disclosure block precedes this command |
| `TG_ATTEST_READONLY=1` | same, **plus** every leaf here is read-only (implies `TG_INTENT`) |

```bash
# INTENT: count call sites of resolve_project_root across the package
# TOUCHES: reads toolguard/**/*.py; writes nothing
# INLINE BECAUSE: needs import-alias resolution, not a grep
TG_ATTEST_READONLY=1 uv run python tmp/count_calls.py
```

**User-level toolguard rules read these markers.** Three consequences follow from how matching
works, and they are the difference between the marker working and not:

* **The marker must be the first thing in the leaf it attests.** Matching is per extracted leaf,
  so `cd x && TG_ATTEST_READONLY=1 grep foo` attests nothing -- `cd` is the first leaf. A bare
  `export TG_ATTEST_READONLY=1` on its own line attests nothing either: the exported variable
  never appears in the later leaves' *text*, which is what rules match.
* **A pipeline needs every leaf permitted, not just the first.** The marker prefixes one leaf;
  the rest stand on their own rules.
* **Foreign code takes a floor that no attestation lifts.** A heredoc, `-c`/`-e` inline code, and
  interpreters such as `awk` are classified undecidable, and that decision overrides allow rules
  -- attesting the leaf does not change it. What it answers to is the project's
  `undecidable_fallback`: `ask` by default, so the command prompts; a project that sets `allow`
  lets it through. Either way the shape is authored code, so **disclose it** and do not reach for
  `awk` where `grep`, `sed -n` or `cut` would do.

**A rule also nudges when a command carries authored logic and no marker.** It allows the command
and injects a line saying the disclosure was missing, so an omission is visible rather than
silent. It catches a scratch-script path, composed `sed`/`awk`/`xargs`, and a loop body -- a loop
itself is invisible to any rule, since matching happens per extracted leaf, but its body almost
always references the loop variable.

Detection is partial by design, so **the log is still the audit**. `disclosure_compliance.py` in
the claude_tooling repo measures the rate over these logs; treat every qualifying command as one
you will be measured on.

Use `TG_ATTEST_READONLY=1` only when *every* leaf is read-only. Do **not** attest a compound
containing a write, redirect, delete, or install -- not even an incidental one. If part of the
work writes, split it: attest the read-only part, let the writing part take a normal decision.
This is an attestation you make on your own authority, and a false one is worse than none,
because the rules trust it.

So attestation buys silence for scratch-script runs and ordinary leaf commands, not for foreign
code (the undecidable floor above). Mark foreign code anyway: it costs nothing and it records
the claim.

This is not a request for permission and doesn't replace one. Arnon reads these when deciding
where to keep or remove friction, so specific beats short. If the honest answer to "why
inline" is "no good reason", write it to a file and run that instead.

## Tool-capability reviews

**Never restate a tool's capabilities from memory; measure them.** Every capability claim is a
claim with a date on it, and this file is the wrong place to keep one -- the measurements that
used to live here went stale in 19 days without anyone noticing. Current state, method, and the
review cadence: `~/.claude/reference/ide-mcp.md`. Read it when the IDE setup changes, and then.

## Code review

Determine scope first -- default is added/changed files in the current task; narrower is
staged only; wider is all Python and templates; or a named package/file/list. Ask with
AskUserQuestion if it isn't clear. Then invoke `/code-review <scope>`, appending the ticket
ID (e.g. `/code-review changed TOO-14`).

Afterwards: verify the subagent reported a **fresh** report path (not a previous run), open
`latest-code-review-report.md` with `mcp__jetbrains__open_file_in_editor`, and **do not read
it yourself** unless I say so -- reading it defeats the isolated-context design.

## Critical thinking

Being a critical thinker is part of your job here, not a garnish on it.

* Before you agree with me or congratulate me, check whether I'm actually right, whether
  it's factually true, and whether I've missed an angle. Say so when I haven't.
* Question the libraries and frameworks I choose: is there a better one, a simpler path, a
  standard-library answer? Is it maintained? Does it carry security risk?
* On a new task or stage: read the task file, then pressure-test the requirements before
  writing code. Do they make sense given the ticket and the rest of the app? Is there a
  simpler way? Any premature optimization -- caching with no measured problem, a dependency
  for something stdlib does, duplicated logic, code in the wrong module, a design that's
  hard to test? Say so before implementing, not after.
* Success criteria must be verifiable and backed by unit, integration, or e2e tests.
* Write the clarifications I give you back into the task memory so they survive.
* **My own assertions are not an oracle.** Verify them like any other claim -- especially
  anything I state from memory, relay second-hand, or asserted more than a few weeks ago. A
  claim can be true when made and false when you read it.

## Punch lists and unattended work

**Convert any non-trivial sequence into a punch list, enumerated inline.** A cross-reference is
for detail, never for membership -- "then the items in <file>" loses them. Spell out every item
where the list lives, and check them off against what was actually delivered.

**In an unattended stretch, run an anti-stall cron. A punch list does not replace it** -- they
catch different failures: the list catches work declared done that was not, the cron catches a
turn that ended without anything pending.

## Comments and doc comments: informative and SHORT

You are much too verbose here by default. **Assume every comment you write is twice as long as it should be.** Explain why, only where why is not obvious; never explain what the code plainly says; never document what static analysis already finds.

The full guidance -- doc comments, ticket references, public vs private, where comments cluster as a refactoring signal -- is in `~/.claude/rules/comments.md`. Read it before writing or reviewing comments.

## Literal strings with semantic meaning belong in constants

**A string literal used in a conditional, a comparison, or a dispatch is a constant.** Name it
at the appropriate scope -- module, class, or a shared vocabulary module -- and use the name.

`if unit.kind == "inline_code":` is brittle: nothing catches a typo, nothing finds the other
sites, and renaming means grepping prose. The offenders that matter most are the ones repeated
across modules and tests -- decisions like `"deny"`/`"ask"`, kinds, statuses, format names.

Applies to values with meaning in the program's logic. A one-off message, a log line, or a
format string is not a constant; a value the code *branches on* is.

## Prose is output, not a data structure

**Never build a prose string and then parse it back within the same runtime.** Carry
structured data and render prose at the edge, where it leaves the program. The only
legitimate consumption of prose by code is combining it with more prose.

If you find yourself writing a regex against a message your own program produced, the
structure you needed was discarded upstream. **Restore it there** -- do not improve the
regex.

This is not a style preference. In `TOO-45` the permission hook rendered a decision to a
human-readable reason string, threw the structured result away, and later re-derived the
sub-command breakdown by regex over that prose. Measured cost: **813 of 975 compound-allow
decisions (83%) were under-logged, and 1,943 sub-commands reached the audit trail with no
record at all.** The parser was correct on the shapes it was written for; the data it needed
had simply stopped existing. Nothing failed, nothing warned, and the audit log looked
complete. Carrying the structured result through to the writer took the loss to zero.

Two corollaries worth applying without being asked:

* A function that returns prose *and* whose caller needs a fact from that prose should
  return both -- the fact as data, the prose for display.
* Accumulate structured results, then choose or consolidate at the end. Do not overwrite or
  flatten as you go; you cannot recover what you discarded, and the place that discovers it
  needs the detail is usually not the place that threw it away.

## Wrapping up a ticket

When it looks like I'm ready to push, remind me about: coverage, documentation updates,
a version bump in `pyproject.toml`, release notes, and `pyscn analyze` on the main package
(read the report, then discuss fix/defer/ignore). Project CLAUDE.md files add their own
items.

## Markdown you author

**Never hard-wrap a paragraph.** One paragraph is one line, however long; blank line between
blocks. Use a single newline only when a `<br>` is what you want -- CommonMark lets a renderer
emit soft breaks as `<br>`, and Obsidian and YouTrack both do, so wrapped prose breaks at every
wrap column. My editors all soft-wrap, so don't optimize the raw width.

Applies to anything I read rendered: tickets, notes, docs, clipboard. Code blocks, list items,
tables and frontmatter are unaffected.

## Utilities

* Obsidian: `open_note_by_title.sh "Note Title"` (uses the Advanced URI plugin).
* Recall a conversation after a restart: `~/bin/recall_main_agent_conversation` (`--help`
  for context options).
* Clipboard: `pbcopy`.
* `git flake8` and `git isort` are my own scripts in `~/bin/`; `ruff` is the primary tool.

## Encoding rules as guidance vs. enforcing them

**Every directive in this file is binding. A MUST is a MUST**, and nothing below softens that.
This section is about how *I* should encode a new rule, not about how much weight you give an
existing one.

The problem it addresses is mine, not yours to invoke: rules delivered only as prose have been
dropped here often enough to measure -- the disclosure rule missed on **10 of 17** qualifying
commands in one day, `RED:` markers stale at **9 of 9**, the grammar rule ignored *even when
the instruction was explicit*, the TDD refactor step absent from **all three** implementation
reports. That is evidence about **delivery**, and it is never a reason to treat a written
instruction as optional. If you notice yourself reasoning "this is only prose", the reasoning
is wrong -- and it is worth telling me, because it means the rule needs a better mechanism.

**So when a rule is being written, prefer the strongest available mechanism -- first that
fits:**

1. **Something the harness executes** -- a hook, a permission rule, a validator, a lint. It
   cannot be forgotten because nothing depends on remembering.
2. **A slot in an artifact template** that makes an omission visible -- a required report
   section, a punch-list row. It turns a silent skip into a claim somebody can dispute.
3. **A skill or rule file loaded on demand** for guidance tied to one activity.
4. **Prose here** -- best for values and judgement, which no mechanism can encode.

**When something keeps being missed, propose a stronger mechanism, not stronger wording.** More
emphasis has been tried and did not help; a lower tier is the fix. Propose it to me rather than
working around the rule in the meantime.

<!--
Maintainer notes (stripped before this file enters context, so they cost no tokens).

Rewritten for Opus 5 / Sonnet 5. Removed as redundant with current model+harness behavior:
  - Python dot-notation -> file-path conversion rules (trivially known).
  - "Always use specialized tools over Bash for file operations" (now in the harness
    system prompt; also still in rules/python.md where it is an enforceable lint).
  - "Always generate doc comments" as a standalone bullet -> folded into rules/python.md.
  - The @common-memory.md indirection: per the docs, @imports load in full at launch and
    save no context, so the surviving ~35 lines were folded in directly.
Removed as actively harmful:
  - "Keep asking clarifying questions until you fully understand" -- conflicted with the
    harness's ambiguity guidance and with auto-memory feedback_avoid_overasking_small_phases.
    Replaced by "pressure-test the requirements" under Critical thinking.
219 lines + 127 imported -> 118 lines, none imported.

TOO-73 (2026-08-28). Governing principle: prefer a mechanism the harness executes, then an
artifact slot, then an on-demand skill, then prose -- prose only for values, never for steps.
So this pass is mostly moves and deletions.
  MOVED OUT
  - Tool-capability reviews (25 lines) -> reference/ide-mcp.md, which already held all of it.
    The copy here had gone stale in 19 days: it called the IDE build an RC after it shipped GA,
    and called a cause unresolved after three hypotheses had been killed. Dated measurement
    does not belong in a file that loads every session. One line kept: measure, never recall.
  - Comments and doc comments (61 lines) -> rules/comments.md, which auto-loads on source
    files via its own `paths:` frontmatter. A rule file beats the skill originally proposed:
    the harness loads it, where a skill needs the agent to judge relevance first.
  ADDED (all values, not steps)
  - "My own assertions are not an oracle" under Critical thinking.
  - A Punch lists and unattended work section: enumerate membership inline, and an anti-stall
    cron is not replaced by a punch list.
  REWRITTEN
  - Encoding rules as guidance: was a warning, is now a four-tier decision procedure with the
    four measured droppings behind it. "Propose a lower tier, not stronger prose."
  - git: names worktree as permitted (the rules allowed it while the prose forbade it), and
    says to hand over a denied command rather than route around it.
  - Disclose code you wrote: the markers are READ by user-level toolguard rules as of
    2026-08-28. Documents the three things that decide whether the marker works -- it must lead
    its leaf, a pipeline needs every leaf permitted, and foreign code takes an undecidable
    floor no attestation lifts.
Baseline for the rule this pass deployed: 10.9% disclosure compliance over 238 trigger-carrying
commands (tools/disclosure_compliance.py). Control flow is 160 of those and is structurally
invisible to a permission rule, so the report -- not the rule -- covers two thirds of the gap.
Context-bearing lines (excluding this stripped block): 318 -> 306. Only -12, against a plan that
predicted ~112 out. The moves removed 78; the approved additions put back 66. Worth knowing
before the next pass: the gain here came from deleting dated measurement and activity-specific
detail, and was mostly spent on documenting a mechanism that had no user-level description at
all. The remaining bulk is Tickets, Task memory and the disclosure mechanics -- all procedure,
all candidates for tier 2 or 3, none touched in this pass.
-->
