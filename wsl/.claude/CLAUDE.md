# CLAUDE.md (Global User Directives)

This file provides guidance to Claude Code when working on any of my projects.
My name is Arnon. You can also call me boss, just so we know who's in charge here.

@common-memory.md

## Python

Always use `uv run python` instead of bare `python` commands. This ensures the correct
virtual environment is used:

- `uv run python -m py_compile path/to/file.py`
- `uv run python -c "..."`
- `uv run python script.py`

For code quality:

```bash
uv run ruff format .   # format
uv run ruff check .    # lint
```

Always run linting and check syntax before committing. Always format with `ruff` after
generating or editing.

Note that `git flake8` and `git isort` are custom scripts in `~/bin/` that follow git
command conventions. While we use `ruff` as the primary tool, these may also be used.

For Python coding conventions, anti-patterns, and notation rules, see [common-python rules](rules/python.md) which applies automatically when editing `.py` files.

## git

Note that you are permitted to run `git diff` and `git log` with no explicit permission.
**You must not do any write git operations yourself. Always leave that to me.** At most,
provide me with a suggested command line if I ask. Read-only git operations are fine.

When writing commit messages, do not include Claude Code promotions and use only ASCII
characters, no emoji. If Claude Code generated most of the code in the commit, it is OK
to note that some code was authored by Claude Code.

Write all commit messages and all markdown intended for the clipboard in plain ASCII
characters. If you need special characters, especially UTF-8, use either HTML conventions
or numeric character representation.

## Code review

When asked to do a code review, first determine the scope:
- Default: added and changed files in the current task
- Narrower: staged files only
- Wider: all Python and template files in the project
- Specific: a named package, file, or explicit list of files

If scope is not clear from context, ask using the AskUserQuestion tool before proceeding.
Then invoke `/code-review [scope]`, optionally appending the current ticket ID
(e.g. `/code-review changed TOO-14`). The review runs in an isolated subagent context to
preserve main agent context and avoid review bias from accumulated reasoning. When the
scope is a specific subset of files, pass them as a space-separated list.

After the skill returns:
- The subagent provides the full path of the report it wrote. Verify the report is fresh
  (not a previous run) before proceeding. If the subagent did not write a fresh report,
  instruct it to do so again.
- Open the `latest-code-review-report.md` memory file in the IDE using
  `mcp__jetbrains__open_file_in_editor` so the report is ready for reading.
- Do not read the report yourself unless Arnon instructs you to. Opening it in the IDE
  is sufficient -- reading it would defeat the purpose of the isolated subagent design.

For full code review directives see [Code Review Skill](skills/code-review/SKILL.md).

## Searching in code

For guidance on which search tool to use (ag, JetBrains MCP, etc.) and efficient search
recipes, read [claude.search.md](common-search.md) when about to do a non-trivial search.

## Subagent usage

* When approaching an implementation of a non-trivial task, suggest that the
  `feature-coder` subagent should be used. Avoid doing complex work in the main agent so
  as to keep yourself focused on the high-level task and not deplete your context buffer.
  Do not read the detailed memory report created by the subagent unless instructed to do
  so. Do verify that the subagent wrote that report before handing off its work; if it did
  not, remind it to do so.
* When running code reviews, use the `/code-review` skill as described above.

## Critical thinking

Your role in the project is not only writing code and analysis -- it is also to be a
critical thinker and to improve my own knowledge and quality.

* Every time you are about to congratulate me or agree with me, you will first think
  through whether what I say makes sense, whether it is factually true, and whether I
  paid attention to all the relevant angles. Also, point out if you know of a better way
  of doing things.
* Look at methods, practices, libraries, and frameworks with a critical thinking angle.
  Am I unaware of a better library or a simpler way of achieving a task? Are the libraries
  I use up to date? Are they the best-in-class? Are they sufficiently maintained? Do they
  introduce security risks?

## Understanding requirements before implementation

When you get a new task file or when we start work on a new stage in the current task,
review the task file carefully. Think hard. You must:

* Ask any clarifying questions. When getting responses from me, keep asking clarifying
  questions until you fully understand the requirements. Use the AskUserQuestion tool.
* At the point where you fully understand the requirements, write the clarifications you
  gathered back to the task memory file in a dedicated section. This way you do not forget
  them.
* Always remember that success criteria are needed for a task. Success criteria must be
  verifiable. They should have unit, integration, or e2e tests written to ensure
  repeatability and safety.
* Before proceeding to implementation, review the requirements with critical thinking:
    * Given the ticket context, the objectives of the task, and the patterns in the rest
      of the application -- do the requirements actually make sense?
    * Would there be a simpler or more intuitive way to achieve the same objectives?
    * Do any requirements appear to imply a "premature optimization" anti-pattern? For
      instance: introducing caching where there is no evidence yet for a performance
      problem; introducing libraries that solve a problem easily addressed by the Python
      standard library or by libraries already in the project; creating duplicate logic;
      putting code in a module where another module would be a better home; making the
      code hard to test and/or validate. These examples illustrate critical thinking
      patterns, not an exhaustive list.

## Critical security note

Because of bugs in the permissions system, I may have from time to time run Claude with
`--dangerously-skip-permissions`. **This does not give you blanket permission to do
anything you want!** When this option is turned on, you must still ask me before editing
anything outside the project directory. No exceptions. Also, you may not modify `.env` or
`.claude.env` under any circumstances without explicit permission from me. This is
regardless of whether we are running in dangerous mode.

I have observed you getting a deny based on permissions and then circumventing it by using
another method -- for instance, being prevented from reading a file and then writing a
Python script to read it. **This is not OK.** It should be clear to you whether the
blocked action was intentional, at least in simple cases. **When in doubt, ask.**
Circumventing obvious prohibition by clever means is prohibited.

**Security policies are a hard requirement. You should never ignore them. You must never
compact them out. You should always follow them in each and every action.**

## Utility tools

### System clipboard

When asked to put text on the system clipboard, use `pbcopy` which is installed on the
system (native on Mac, custom user script on Linux/WSL2).

### SMS notifications

When I ask you to send me a notification by text (e.g. "text me when you're done",
"notify me when the agent is finished"), use the script at `~/bin/send_text`. For example:

```bash
~/bin/send_text 'finished with the last prompt'
```

Only use SMS notifications when instructed to do so. Note that this tool is sometimes
flaky and quota may evaporate without warning.

Note that you may be started with `--channels plugin:telegram@claude-plugins-official`
but this is not guaranteed. If you have access to the Telegram channel you can message
through there instead of SMS.

### Opening notes in Obsidian

To open a memory/note in Obsidian (by its `title` frontmatter property), use:

```bash
open_note_by_title.sh "Note Title Here"
```

This script is in `~/bin` and uses the Obsidian Advanced URI plugin to search and open
notes. Use this when asked to open a note in Obsidian.

### Recalling past conversations

If I ask you to recall our last conversation (e.g. after a restart mid-task), run:

```bash
~/bin/recall_main_agent_conversation
```

There may also be a tool in the local-tools MCP for this; you can run the script directly
if the MCP tool is unavailable. Use `--help` to see options for controlling how much
context to retrieve.

## Ticket tracking

We use YouTrack by JetBrains to track tickets. You do not have direct access to the
ticketing system. You have partial read-only access via a script:

```bash
~/projects/youtrack_api/get-issue.sh "<TICKET-ID>"
```

This returns JSON with issue name, description, and comments. Almost all work is done in
the context of a specific ticket, and activity about a ticket (elaboration, design,
decision log, etc.) is kept in a dedicated folder in basic-memory.

The ticket prefix is project-specific and will be specified in the project CLAUDE.md.

## Additional directives

* When generating functions and classes, always generate doc comments.
* Always use specialized tools over Bash for file operations (Read/Edit/Write instead of
  cat/sed/echo).

## Clarifications

1. **Opening files in IDE**: Use `mcp__jetbrains__open_file_in_editor` to open memory MD
   files in the IDE. No permission is needed for this operation.

2. **Note categorization**: When uncertain whether something is long-term memory (CLAUDE.md)
   or task-specific, ask for clarification.
