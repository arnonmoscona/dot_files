---
name: obsidian
description: Search, read, create, and edit notes in the user's Obsidian vault. Use when asked to look up, write, or update Obsidian notes or memories — especially in claude-global-memory.
argument-hint: [search <query> | read <note-name-or-path> | create <path> <content> | append <path> <content> | list [folder]]
allowed-tools:
  - Bash(\obsidian *)
---

# /obsidian — Obsidian Vault Access

Interact with the user's Obsidian vault via the CLI. Arguments: `$ARGUMENTS`

## Key facts

- Command: `\obsidian` (backslash bypasses the GUI shell alias)
- Obsidian must be running; the first command auto-launches it if needed
- Vault root: `/home/arnon/obsidian-vault/`
- All paths in commands are **relative to the vault root**
- Global memories (for Claude across projects): `claude-global-memory/claude-global-memories/`
- Other vaults in the vault root: `empire-memories/`, `project-flowers-for-claude/`

## Commands reference

### Search
```bash
\obsidian search query='<text>'
\obsidian search query='<text>' path='<subfolder>'   # limit to folder
\obsidian search:context query='<text>'              # include matching lines
```

### Read
```bash
\obsidian read file='<note name>'                    # match by name (fuzzy, like wikilinks)
\obsidian read path='<folder/note.md>'               # exact relative path
```

### Create / overwrite
```bash
\obsidian create path='<folder/note.md>' content='<text>'
# Use \n for newlines in content. Overwrites if file exists.
```

### Append (extend existing note)
```bash
\obsidian append path='<folder/note.md>' content='<text>'
\obsidian append file='<note name>' content='<text>' inline   # no leading newline
```

### Delete
```bash
\obsidian delete path='<folder/note.md>'
```

### List vaults
```bash
\obsidian vaults verbose
```

## Dispatch on arguments

Parse `$ARGUMENTS`:

- `search <query>` → run `\obsidian search query='<query>'`; if user specifies a folder, add `path='<folder>'`
- `read <name-or-path>` → if arg contains `/`, use `path=`; otherwise use `file=`
- `create <path> <content>` → `\obsidian create path='<path>' content='<content>'`
- `append <path> <content>` → `\obsidian append path='<path>' content='<content>'`
- `list [folder]` → `\obsidian search query='path:<folder or vault root>'` to enumerate files
- No args or unrecognized → show vault structure: run `\obsidian search query='path:claude-global-memory'` and display results

## Common patterns

**Search global memories:**
```bash
\obsidian search query='<topic>' path='claude-global-memory'
```

**Read a global memory note:**
```bash
\obsidian read path='claude-global-memory/claude-global-memories/conversation with claude.ai on claude code notes.md'
```

**Write a new global memory:**
```bash
\obsidian create path='claude-global-memory/claude-global-memories/my-topic.md' content='# Title\nContent here.'
```

**Extend an existing note:**
```bash
\obsidian append path='claude-global-memory/claude-global-memories/my-topic.md' content='\n## New Section\nMore content.'
```
