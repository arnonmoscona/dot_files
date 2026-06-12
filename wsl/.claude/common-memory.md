# Context and Memory Management

## Task memory system

For context management, use the basic-memory MCP server for persistent context storage.
The project name and ticket prefix for the current project are specified in the project
CLAUDE.md. When told to take notes or remember something, use the basic-memory tools to
create or update notes. Organize notes into appropriate folders (e.g., a folder named
after the ticket number) and use descriptive titles. Tag notes with relevant keywords for
easy retrieval.

The basic-memory tools available include:

- `mcp__basic-memory__write_note`: Create or update notes
- `mcp__basic-memory__read_note`: Read existing notes
- `mcp__basic-memory__search`: Full-text search across all content
- `mcp__basic-memory__search_notes`: Structured tag/metadata search
- `mcp__basic-memory__build_context`: Build context from memory:// URIs
- `mcp__basic-memory__recent_activity`: Get recent activity
- `mcp__basic-memory__sync_status`: Check sync status and ensure database is up to date

Always specify the correct project name (see project CLAUDE.md). When creating memories
in the context of a specific ticket, add the ticket ID as a tag on the document.

**Best practices for basic-memory usage:**

- **At launch**: Run `sync_status` to ensure the database is fully indexed and up to date.
- **For finding memories**: Use `search_notes` instead of reading files and scanning
  directories manually -- saves tokens.
- **Search patterns that work**:
    - Single tags: `"task-memory"` or `"TOO-72"`
    - Multi-tag with AND: `"task-memory AND TOO-72"` -- returns items matching ALL tags
    - Multi-tag with OR: `"task-memory OR TOO-72"` -- returns items matching ANY tag
- **Search patterns that don't work**:
    - Space-separated: `"task-memory TOO-72"` -- returns empty
    - Comma-separated: `"task-memory, TOO-72"` -- returns empty
    - Plus signs: `"+task-memory +TOO-72"` -- returns empty
    - Quoted pairs: `"task-memory" "TOO-72"` -- returns empty
- **Best approach for precise results**: Use `AND` operator for multi-tag searches.
- Keep focused on work at hand by letting basic-memory handle memory retrieval efficiently.

## Current task context

Whenever we work on a task there will always be a specific task memory for that task.

- The task memory includes my instructions and specifications.
- It includes references such as ticket numbers, screenshots, mockups, and other material.
- It includes a dedicated section where you keep notes about the task.

There is a special memory called `Current Task Context.md`. This memory contains a link
to the current task we are working on.

- When you launch, read this memory and then read the linked task to make sure that you
  start with a clear understanding of what we are doing and where we are.
- When I say something like "we're now working on some task name", where "some task name"
  refers to a specific memory, verify with me that we are switching to that task after
  identifying the task memory. After I confirm, update the link in the current task
  context memory. The same applies if I say "switch to some task name" or "switch context
  to some task name".
    - If you cannot clearly identify which memory I am referring to, ask me whether this
      is a new task, whether I want to specify more exactly which task I mean, or whether
      you should ignore the instruction. If I respond that it is a new task, create the
      new task memory.
    - Once an existing task memory has been identified and switched to, read that memory,
      analyze it, and ask clarifying questions using the AskUserQuestion tool.
    - Regardless of whether this is a new or existing task memory, open the memory file
      in the IDE for me to view and edit.
- Keep a section of notes for yourself in the task memory file, separate from the content
  I provide, titled something like "Clarifications from discussion". Add notes you generate
  independently or that I instruct you to take. For instance, if I say "take a note of
  this" or "remember that x, y, z", add this to your notes section in the current task
  memory.
- If I say something like "in the future remember that x, y, z", I am likely referring to
  long-term project memory rather than task-specific memory. In such cases, ask me. If I
  confirm it is long-term memory, take the note in CLAUDE.md or in a memory that you
  reference in CLAUDE.md. Otherwise the note goes into the task-specific memory.

## Long-term memory management

- By default, always use CLAUDE.md as your main long-term memory.
- For each task we work on, maintain a separate task summary memory in the folder
  "task summaries". The purpose is to help you remember what the task is about without
  overloading your context with all the details.
- When I refer to past activity (e.g. "recall when we were working on some task"), you
  can read the summary to recall what it was about without fully digesting all the details.
  This uses less space in your context.
- When such a reference is ambiguous (matches more than one summary), present the list of
  matching candidates for me to select from, with one option being "all of these". If I
  choose "all of these", read all of them.
- Whenever you create new task summary memories, make sure they include the properties
  `title`, `type`, `permalink`, and at least one tag: `task-summary`. If the ticket number
  is apparent, also include a tag with the ticket number. Refer to the properties in
  "Current Task Context.md" for an example. Also make sure to interact with the
  basic-memory MCP to maintain its database properly.
- When asked to find a memory, do not try to scan all memories -- that uses too many
  tokens. Instead use basic-memory tools: `search_notes` (for structured search),
  `recent_activity` (very useful for narrowing scope), `list_directory` (useful for
  focusing on the current ticket), and `fetch`. Prefer basic-memory MCP capabilities over
  your own text matching. Use your own capabilities on smaller sets of documents after
  narrowing down with the MCP tools.

## Clarifications

1. **Task memory naming and organization**: Most tasks are related to a ticket number.
   When a ticket exists, use folder organization and naming like
   `<TICKET-ID>/<TICKET-ID> <description>.md`. When creating a new task memory without a
   provided ticket number, ask whether there is a ticket. If no ticket exists, ask where
   to place the memory to avoid cluttering the main memory folder.

2. **Task memory tagging**: All task memory files must include the "task-memory" tag in
   their frontmatter, along with the ticket number tag and other relevant tags. If you
   create a task memory or if Arnon creates one without this tag, add it or remind him to
   add it. This ensures proper searchability in basic-memory's database.

3. **Task summary creation timing**: Create task summaries once you understand what the
   task is about, even with minor open questions remaining. You may ask if it is time to
   create one. Always ensure a summary exists at task completion. Update summaries during
   work as appropriate.

4. **Task summary brevity**: Keep task summaries compact (under 150 words). The purpose
   is to enable quick recall without consuming excessive context tokens. Include only
   essential information: what the task is, current status, key patterns/decisions, and
   reference to full details. Verbose summaries defeat the purpose.

5. **Launch procedure**: At launch, read `Current Task Context.md` from the project's
   basic-memory (if it exists), and the linked task memory to understand current work and
   status.
