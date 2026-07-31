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

## Tool-capability reviews

`code-review-graph` is a moving target under active evaluation, and I care more about
precision than speed. Never restate a tool's capabilities from memory; measure them.

The IDE MCP review is **suspended** as of 2026-07-31 -- the reachable build exposes no
analysis tools, there is no fix in hand, and re-measuring a known-empty surface on a cadence
is not worth the tokens. Don't remind me about it. If I say the IDE setup has changed, the
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

## Wrapping up a ticket

When it looks like I'm ready to push, remind me about: coverage, documentation updates,
a version bump in `pyproject.toml`, release notes, and `pyscn analyze` on the main package
(read the report, then discuss fix/defer/ignore). Project CLAUDE.md files add their own
items.

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
