---
paths:
  - "test/**/*.py"
  - "tools/coverage_stdlib.py"
---

# Testing conventions

Standard-library `unittest`. **pytest is not installed** -- don't write pytest-style bare
`assert`s or fixtures.

```bash
uv run python -m unittest discover -s test -t .
```

## Every test function carries a Given/When/Then docstring

State the scenario and the expected outcome, so the intent is readable without
reverse-engineering the assertions:

```python
def test_more_specific_allow_overrides_parent_deny(self):
    """
    Given a parent level that denies a command and a project level that allows it
    When the command is evaluated under more-specific-wins resolution
    Then the project's allow wins and the command is permitted
    """
```

**Keep the description and the code in sync in the same edit.** When you change what a test
does or expects, update its Given/When/Then. A stale BDD comment is worse than none -- it is
part of the test, not decoration.

## Coverage

No external coverage tools; we use the stdlib `trace` module via a committed runner:

```bash
uv run python tools/coverage_stdlib.py
```

It prints a per-module summary and writes annotated `cover/*.cover` files where any line
prefixed with `>>>>>>` never executed. Find gaps with:

```bash
grep -rn '>>>>>>' cover/ | grep toolguard
```

`cover/` is a gitignored build artifact.

<!--
Maintainer notes (stripped before entering context).

Extracted from toolguard/CLAUDE.md and path-scoped to test/**.

Removed the inlined 15-line source of tools/coverage_stdlib.py -- the file is committed, so
reproducing it here was duplication that could drift from the real runner. Also dropped the
explanation of what ignoredirs does and the "trace is line-only and slower than coverage.py"
caveat: neither changes what to run, and the first is derivable from reading the runner.

Kept the BDD requirement verbatim in substance, including the keep-it-in-sync clause. It is a
genuine local convention that differs from tool defaults, which is exactly what survives a
trim.
-->
