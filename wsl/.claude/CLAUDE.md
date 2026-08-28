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
**I do all write operations myself** -- no commits, pushes, checkouts, merges, branches,
stashes, or resets, even when you think it's the obvious next step. Give me the command
line instead.

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
* Check a feature-coder task spec against CLAUDE.md conventions before sending it.
* Code review goes through the `/code-review` skill (below).
* Search: read `~/.claude/reference/search.md` before a non-trivial code search. Do **not**
  route search or structural questions to `mcp__jetbrains__*` -- the reachable IDE build
  exposes no analysis or language-aware tools, so it is neither a lane nor a fallback. Use it
  to open files and nothing else.

## Disclose code you wrote before you run it

**Applies to me and to every subagent and skill with a Bash tool.** Some projects add mechanics
on top (toolguard has an env-var marker scheme); this is the part that holds everywhere.

Every Bash command is one of two kinds. **A tool invocation**: running a program that already
existed -- `grep`, `ls`, `git diff`, a linter, a test runner, a committed project script. You
chose flags and paths; you did not write the logic. **No disclosure.** **Program delivery**: the
command *carries logic you just authored*. **Disclose.**

The question is always **"did I write the logic that is about to execute?"** -- not whether the
command is short, read-only, or already visible in the transcript. It comes out "yes" for:

1. A heredoc into an interpreter (`<<'PY'` into `python`/`node`/`sh`).
2. Inline code in an argument -- `python -c`, `node -e`, `perl -e`, `bash -c`, `jq -f`.
3. A path to a script you or a subagent wrote for this task -- `python scratchpad/probe.py`.
4. **Shell you composed rather than invoked** -- `sed -e`/`-i` programs, `awk`, `for`/`while`
   loops, `xargs` with an authored command. **This is the one that gets missed**, because shell
   does not look like a program. The interpreter is `sh`; the program is the command line.

Writing a script and then running it is a trigger by itself. The `Write` sitting in the
transcript makes the run feel already explained -- it isn't, because the log and the permission
prompt both get only a filename.

Format: Bash comments immediately before the command, so they travel with it into the prompt,
the transcript and the logs.

```bash
# INTENT: <what the code does, in plain language -- not a restatement of the code>
# TOUCHES: reads <paths>; writes <paths>   (say "writes nothing" when it writes nothing)
# INLINE BECAUSE: <why this isn't a file you could have been asked to run>
```

Use `NOT INLINE BECAUSE` for case 3, and put writes **outside the project directory in capitals**.
Judge each command on its own -- misses cluster in runs, because once one undisclosed command
goes out the next four inherit it.

**Disclosure is for after-the-fact analysis as much as for my approval**, so it is required even
when the command will be blocked by a rule, even when it fails, and even when nobody is watching.
A blocked command with a disclosure is a usable record; without one it is a bare path.

## Tool-capability reviews

`code-review-graph` is a moving target under active evaluation, and I care more about
precision than speed. Never restate a tool's capabilities from memory; measure them.

**Un-suspended and re-measured 2026-08-09.** The build moved 2026.1.3 -> 2026.2.1 RC: 9 tools
added (including `analyze_calls`, the gap that justified the suspension), 7 removed, 6 changed.
**Measured outcome: nothing changes for Python.** `analyze_calls` exists and resolves no Python
symbol in any FQN form -- module function, bare name, module-qualified, or class method -- while
`search_symbol` finds the same symbol fine. **Cause unresolved**: it is either a Python
call-hierarchy gap or, more likely per Arnon, the EAP/RC on WSL + Remote Development, where
other subsystems (diagram generation) also fail and reports go back a year. Re-test at the
final release, not on the normal cadence. pyright/LSP remains the semantic lane meanwhile.

The removals are the part that needs action: `replace_text_in_file`, `get_file_text_by_path`,
`find_files_by_glob`, `find_files_by_name_keyword` and both `search_in_files_by_*` are gone, and
they are enumerated **by name** in agent allowlists and in auto-memory. Details and the fix list
are in `~/.claude/reference/ide-mcp.md`.

The earlier suspension text said "the reachable build exposes no analysis tools" -- true when
written, false now, and that is exactly why the rule below says to measure rather than recall. If
the IDE setup changes again, the
method and the last measurements are in `~/.claude/reference/ide-mcp.md`; read it then, and
only then.

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

## Comments and doc comments: informative and SHORT

You are much too verbose here by default. Assume every comment you write is twice as long as
it should be.

* **Doc comments say what a thing is, what it takes, what it returns, and any non-obvious
  constraint.** That is usually 1-5 lines. Long rationale belongs in technical documentation;
  leave a reference to it, not the argument itself.
* **A ticket reference in a docstring is almost always wrong.** The default is none. A
  docstring says what a thing *is*; a ticket records a *change*, and change history is git's
  job. "Extracted from X under TOO-45 punch-list #03" is a commit message in the wrong file.
* **In an inline comment a ticket sometimes earns its place** -- when a reader would otherwise
  ask "why is this here at all" and the answer is a specific past incident. *"Ordered this way
  to avoid the race in TOO-88"* is worth its line. Even then: **one short sentence, the ticket
  as a pointer, no retelling.**
* **If what you want to say is not in the ticket, put it in the ticket -- not in the code.**
  The urge to explain something the ticket does not cover is a signal to go comment on the
  ticket. In code it drifts, it distracts, and it has a shelf life of weeks.
* Ask of any comment: will this still be worth reading in a year, to someone who never saw
  the ticket?
* **Do not explain what the code plainly says.** Explain why, only where why is not obvious.
* **Never document what static analysis already finds** -- callers, call graphs, "used by X",
  "the only importer is Y". The reader has an IDE; the editor has grep and an LSP. This text is
  long, goes stale silently, and is wrong often enough to mislead. It is the single largest
  source of useless prose.
* **Do not explain short, simple code at all.** A paragraph on a one-line private function is
  always wrong, however true it is.
* **Public and private are held to different standards.** A module's public surface tolerates
  more detail, about its *external contract and how it is used*, briefly -- not about how it
  works. Private functions get less: they are read in the narrow scope of their own module, by
  someone who can see the body.
* **When complexity genuinely needs explaining, put it in the body next to the complexity**,
  not in the docstring -- and first ask whether the answer is to simplify instead. A function
  needing heavy commentary to be followed is usually a function that should be split.
* **Assume a proficient reader.** They need to know which particulars to watch, not to be
  taught. The same point at a third of the length is easier to understand, not harder. Long is
  not thorough; long is unread.
* **Justify by the mistake, not by the code.** Simple code deserves a long note when the error
  it guards against is easy to make and costly -- and complex code deserves none if nobody
  would get it wrong. When length is genuinely warranted, say so up front
  (*"Intentionally two-directory-only:"*) so the reader knows to spend the attention. That is
  not a licence to prepend such a phrase as an excuse for length.
* **Where comments cluster is a refactoring signal.** A docstring that *numbers* what a function
  does should probably be that many functions. So should a long function whose branches each
  need their own comment block -- no enumeration required; those comments would read as the
  docstrings of the extracted branches. Look at where the commentary piles up, not just whether
  it is numbered.
* **Every statement in a comment is an ongoing tax.** It can drift, and it gets re-read and
  re-verified every time someone touches that code. It must justify a *recurring* cost, not
  the one-time cost of writing it. Volume is a cost even when every sentence is true.
* **Add on evidence, not on estimation.** Most comments are written from a guess about what a
  future reader might want; that guess is usually wrong and never falsifiable. Leave it out.
  It can be added later, when a real reader actually stumbles -- and then it aims at a real
  gap. Absence is cheap to fix; accumulated speculative prose is not.
* **When shortening a comment makes it inaccurate, do not reach first for a more careful short
  form.** Ask whether the statement earns its place at all -- a claim that resists compression
  is usually carrying more detail than it is worth, and deleting it outright is often the
  better answer. (Compression reliably introduces false universals: "only", "every", "never"
  appear where the original was hedged, because the short form wants a crisp rule and reality
  is not crisp. Measured across seven consecutive editing passes on one codebase.)

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

CLAUDE.md is context, not enforcement -- a "MUST" in prose has a demonstrated track record
of being silently dropped in this setup, including after being fixed once. So when a step
genuinely must happen at a fixed point (before a commit, after an edit, at session start),
say so and propose a **hook** instead of stronger wording. In long agent-facing runbooks,
prefer explicit checklists the agent ticks through over prose imperatives.

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
-->
