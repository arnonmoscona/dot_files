---
paths:
  - "**/*.py"
---

# Python Coding Conventions

## Anti-patterns to avoid

Before finalizing code, review for these prohibited patterns:

- **No async/await** unless explicitly approved by the user
- **No threading** unless explicitly approved by the user
- **No local imports** (imports inside functions) unless a circular dependency is
  documented and approved
- **No Bash for file operations** -- use Read/Edit/Write tools instead of cat/sed/echo

Before marking a task complete, scan modified files for:
- `async def` or `await` keywords
- `threading` or `Thread` usage
- Import statements inside function bodies
- Bash commands used for file content operations (`cat`, `sed`, `echo` reading/writing
  files instead of the Read/Edit/Write tools)

When an anti-pattern violation occurs, add it to a "Recent Anti-Pattern Violations"
section in the current task memory for review at next launch. You may also add it to your auto-memory.

Note: pre-commit hooks may be configured to catch some of these automatically (local
imports, async/await patterns, destructive git operations).

## Code references and Python module notation

When you see Python dot notation for class or module references:

- `package_x.module_y.ClassName` -- class `ClassName` in file `package_x/module_y.py`
- `package_x.module_y.get_user` -- function `get_user` in file `package_x/module_y.py`

Conversion rules:
- Dots (`.`) in module paths become forward slashes (`/`) in file paths
- Add `.py` extension
- The last component after the final dot is the class, function, or constant name

## Doc comments

When generating functions and classes, always generate doc comments.

## Deprecation pattern

When replacing an existing function with a new one and intending to deprecate the old one:
- Use `@warnings.deprecated` decorator on the old function, naming the replacement
- Add a `# FIXME` comment to the old function to track remaining callers
- Example: `@deprecated('use func_b instead')` and
  `# FIXME func_a was deprecated, refactor all uses to func_b`
