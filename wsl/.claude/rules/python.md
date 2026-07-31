---
paths:
  - "**/*.py"
---

# Python conventions

Run `uv run python`, never bare `python`. Format with `uv run ruff format .` and lint with
`uv run ruff check .` after generating or editing.

## Prohibited without my explicit approval

- **async/await.** These are low-concurrency apps; async buys nothing and costs
  readability. If you think you cannot avoid it, stop and ask -- I will find a way.
- **threading.** Sequential code is easier to reason about.
- **Local imports** (inside a function). Only for a documented, approved circular-import
  escape, or a genuinely expensive import. Fixing the import structure is preferred.

When you do violate one of these, note it in the current task memory under "Recent
Anti-Pattern Violations" and in your auto-memory, so it surfaces next launch.

## Style

- Doc comments on every function and class.
- Plainest form that works. No `TYPE_CHECKING` guard without a real circular import, no
  `__slots__` without a memory justification, no `object.__setattr__` outside a genuine
  recursion guard, no accumulator loop where a comprehension reads better. Reach for a
  sharper construct only when you can name the concrete reason.
- No unused imports when you finish. `autoflake` removes them without spending AI budget.

## Deprecating a function

Decorate the old one `@deprecated('use func_b instead')` (from `warnings`) and add
`# FIXME func_a was deprecated, refactor all uses to func_b` so I can find the callers.

<!--
Maintainer notes (stripped before entering context).

This file is path-scoped, so it only loads when a .py file is touched -- the one place in
this setup where relocation genuinely saves context rather than just reorganizing.

Removed as redundant with current models:
  - The "before marking a task complete, scan modified files for `async def` / `threading` /
    function-level imports / bash file ops" ritual checklist. The rules above are the
    content; the self-scan ceremony was scaffolding for weaker models.
  - The Python dot-notation -> file-path conversion table.
  - "No Bash for file operations" -- now in the harness system prompt.
  - The note that pre-commit hooks "may be configured" to catch some of these. Either they
    are configured, in which case they need no mention here, or they are not, in which case
    this is the enforcement gap worth closing for real.
Added: the Pythonic-plainness guidance, promoted from featherhill's project architecture
file and auto-memory feedback_pythonic_style, since it is a language preference, not a
project fact.
53 -> 38 lines.
-->
