---
paths:
  - "test/unit/**"
---

# Test config isolation

Applies to everything under `test/unit/`. Companion to `.claude/rules/testing.md`, which
carries the suite-wide conventions (unittest, BDD docstrings, coverage).

## Why config isolation is mandatory here

This repo dogfoods toolguard on itself, so real config genuinely exists on any dev machine:
`~/.claude/toolguard_hook.toml`, `~/.config/toolguard/rules/`, and `~/.toolguard/rules/`.
`toolguard/config.py`'s discovery reads real filesystem state from exactly three controllable
anchors -- the home directory, `toolguard.config.find_project_root()`, and the
`XDG_CONFIG_HOME` / `CLAUDE_SETTINGS_PATH` environment variables. Both candidate rules
directories derive from home, so patching it isolates both -- except that a set
`XDG_CONFIG_HOME` relocates the first one.

Since ticket 44 those reads go through `toolguard.ambient` -- `ambient.home()`, `ambient.cwd()`,
`ambient.env_var()` -- rather than `pathlib`/`os` directly. Patching `pathlib.Path.home` still
works, because an accessor with no facts bound falls through to the live call, and that is what
`ConfigIsolationMixin` does. Patching `toolguard.ambient.home` is the alternative, and it is one
target instead of one per reading module. `~` expansion answers from that same door
(`path_utils.expanduser`), which matters because `pathlib`'s own `expanduser` reads `$HOME` and then
the passwd entry: under the mixin, which clears `os.environ`, a `~` path used to expand to the
developer's REAL home despite a patched `Path.home`.

One caveat: `toolguard.hook.main()` binds home, cwd and the environment once for the invocation
around its resolve/decide block (`--eval` returns above the binding and binds nothing), so a
`pathlib.Path.home` or `os.environ` patch installed after `main()` has started is not consulted --
install it before the call.

A test that doesn't redirect all three anchors it touches can silently depend on, or be broken
by, whatever config happens to exist on the machine running the suite. That has already caused
real failures (`test_takeover_mode.py`, 2026-07-23). Background: basic-memory notes "TOO-30
pre-push follow-up: suite-wide test isolation cleanup" and "TOO-30 Test Isolation Cleanup -
Implementation Report".

**A fourth, separate anchor: `toolguard.env_config`'s own log-directory resolution.**
`toolguard/env_config.py` has its OWN `find_project_root()` -- a different function from
`toolguard.config`'s, resolving from `ambient.cwd()`, which with nothing bound is the real
process cwd that nothing above patches, and reading the `TOOLGUARD_PROJECT_ROOT` /
`TOOLGUARD_LOG_DIR` env vars. `toolguard.hook.main()` calls
`get_env_config()` unconditionally, before `load_configuration()` even runs, to resolve
`TOOLGUARD_LOG_DIR` (default `<project_root>/logs`) for the config-discovery diagnostic log. A
test that drives `main()` without isolating this resolves the REAL repo's `logs/` directory --
since the test process's cwd genuinely is the repo root -- and writes real entries into it. This
bit `TestHardDenyThroughMain` in `test_hard_deny.py` for real (TOO-19, 2026-07-31) even though it
DID use `ConfigIsolationMixin`, because the mixin's original scope covered only the first three
anchors; it also bit `test_hook.py` and `test_hook_eval.py`, which mock `load_configuration()`
directly and so never reach `toolguard.config`'s discovery at all, but still reach
`get_env_config()`. `isolate_config_environment()` now ALSO isolates this anchor (see the
checklist below) -- treat it as a fourth anchor alongside the original three, not a separate
concern.

## Writing or editing a test here

- [ ] **Does it reach `toolguard.config`'s discovery path** -- `load_configuration()`,
      `_discover_levels()`, `find_project_root()`, `discover_config_files()`, or anything
      calling those transitively (`migrate()`, `load_file_path_patterns()`)? If no -- e.g. it
      builds a `Configuration` from hand-constructed `ConfigLayer`/`Provenance` objects with
      zero file I/O -- no isolation needed. Stop.
- [ ] Mix in `ConfigIsolationMixin` from `test.unit._config_isolation`:
      `class TestFoo(ConfigIsolationMixin, unittest.TestCase):`
- [ ] Call `home, project = self.isolate_config_environment(...)` first thing in the test, or
      once in `setUp` if the whole class needs the same shape. Pass `xdg_config_home=` /
      `extra_env=` if the test controls those. This also isolates `TOOLGUARD_LOG_DIR` (into
      `self.isolated_log_dir`) as of TOO-19 -- no separate step needed.
- [ ] **Never** hand-roll `tempfile.TemporaryDirectory()` +
      `patch("toolguard.config.find_project_root", ...)` + `patch.object(Path, "home", ...)`.
      That ad hoc, inconsistent pattern is exactly what the mixin replaced.
- [ ] **Only exception**: a layout the mixin's fixed `tmp/home` + `tmp/project` siblings can't
      represent -- a marker positioned *above* home, or a genuinely nested project. Check
      `isolate_config_environment(project_under_home=...)` first; it already covers the nested
      case. If you truly must hand-roll, **add a one-line comment saying why** -- a silent
      exception is indistinguishable from a missed retrofit. See `test_hierarchical.py` for the
      one existing commented precedent.
- [ ] **Does it drive `toolguard.hook.main()` end-to-end but mock `load_configuration()`
      directly** (so it never reaches `toolguard.config`'s discovery, but DOES reach
      `get_env_config()` -- the fourth anchor above)? If the whole module does this and doesn't
      otherwise need `ConfigIsolationMixin`, use the lighter module-level
      `isolate_log_dir_for_module()` from `test.unit._config_isolation` in `setUpModule()` /
      `tearDownModule()` instead of retrofitting every test method -- see test_hook.py and
      test_hook_eval.py for the pattern.

## Before pushing, if `toolguard/config.py` or any test here changed

- [ ] Diff `toolguard/config.py` and whatever it delegates discovery to against the last push.
      A new environment variable, a new fixed real-filesystem path, or a new function reading
      `ambient.home()` (config.py no longer calls `Path.home()` itself) or walking the
      filesystem independently of `find_project_root` means
      `isolate_config_environment()` in `test/unit/_config_isolation.py` needs a new parameter
      or patched anchor.
- [ ] Grep this directory for `Path.home()`, `patch.object(Path, "home"`,
      `patch("toolguard.config.find_project_root"`, `patch("toolguard.config.Path.home"`,
      `patch("toolguard.ambient.` (covers `home`/`cwd`/`env`/`env_var` in one token), and
      `XDG_CONFIG_HOME`, outside `_config_isolation.py`, `test_ambient.py` (ambient's own
      tests, where patching those accessors is the subject) and the commented exceptions. For
      the four `Path.home` / `find_project_root` tokens, a new uncommented hit is a missed
      retrofit or a new ad hoc pattern to fold into the mixin. `patch("toolguard.ambient.`
      needs the judgement below; a `XDG_CONFIG_HOME` hit is context for reading the others,
      not a finding by itself.
- [ ] Judge a `patch("toolguard.ambient.` hit differently. Redirecting or breaking one accessor
      is the supported way to stage a machine the mixin cannot build -- a home that raises, a
      crash log written somewhere else -- and the paragraph above endorses it. It is a missed
      retrofit only where it stands in for `isolate_config_environment()`. A stated reason is
      what separates the two, so require the same "why" as a hand-rolled exception -- beside
      the patch, or in the enclosing `setUp`/`setUpModule` docstring where the whole module
      shares one fixture -- and read it before concluding anything.
- [ ] Run the suite against an empty `$HOME`:

      ```bash
      TMPH=$(mktemp -d); TMPX=$(mktemp -d)
      HOME="$TMPH" XDG_CONFIG_HOME="$TMPX" uv run python -m unittest discover -s test -t .
      rm -rf "$TMPH" "$TMPX"
      ```

      **Never validate this by making a throwaway change to your real
      `~/.claude/toolguard_hook.toml` and reverting it.** Mutating live permission config to
      test anything is the anti-pattern that produced the TOO-19 incident: toolguard governs
      the agent, these files are usually untracked, and a missed revert is unrecoverable. The
      env-var form needs no revert and is strictly stronger -- it found three latent failures
      on its first run (`TestRulesDirectoryDiscovery`, 2026-07-28) that compared against a
      `Path.home()` evaluated outside a `clear=True` env patch and passed only because `$HOME`
      happened to equal the machine's pwd entry. The live-config form never varied `$HOME`, so
      it could not have found them.

- [ ] For "what would this config decide?", use `toolguard.testing.sandbox`, never a real
      config file:

      ```bash
      uv run python -m toolguard.testing.sandbox --config <file> --command "<command>"
      ```

## Structural guard against a silent regression (TOO-19)

A checklist here did not prevent the log-dir leak the first time -- three tests missed it
independently, one of them despite already using `ConfigIsolationMixin`. On top of the checklist,
`test/unit/_real_log_dir_guard.py` (installed from `test/unit/__init__.py`, before any test
module is imported) wraps toolguard's log-writing entry points so that any call whose `log_dir`
resolves to the REAL repo `logs/` directory is suppressed (never actually written) and recorded.
`test_zz_real_log_dir_guard.py` asserts the record is empty; `test/unit/__init__.py` also
registers an `atexit` hook that re-checks the same record after the whole process's test run and
force-exits nonzero if anything leaked, so the guard does not depend on discovery/test order. If
you add a new toolguard function that writes into the log directory, add it to the wrapped set in
`_real_log_dir_guard.py`'s `install()`.

<!--
Maintainer notes (stripped before entering context).

100 -> 72 lines. The smallest cut of any file here, on purpose: almost all of it is
non-derivable local knowledge about a facility that exists in this repo, plus two
incident-derived prohibitions. That is precisely the category a trim should keep.

What I did cut: the investigation archaeology in "Why this file exists" (which anchor was
added for which ticket, why Path.home patching sufficed for TOO-19, the "no new anchor was
needed" reasoning). The conclusion is what governs behavior; the derivation lives in the
basic-memory notes now cited.

Kept verbatim in force: the do-not-mutate-live-config prohibition and its rationale. It is a
data-loss rule earned by an actual incident, and the reasoning is what makes it stick rather
than get argued around.

RELOCATED 2026-07-31 on Arnon's decision. This was toolguard/test/unit/CLAUDE.md. The reason:
nested CLAUDE.md files in subdirectories are NOT re-injected after /compact -- only the project
root one is -- so on a long session that compacted mid-task this guidance could silently drop
out of context while tests were still being edited. That is a bad property for a file whose
whole purpose is preventing one specific, expensive, already-committed-once mistake.

As a path-scoped rule the trigger is the same (touch a file under test/unit/) but it lives
alongside .claude/rules/testing.md, which already fires on the same files, so all test guidance
is now in one directory.

APPLY NOTE: the old toolguard/test/unit/CLAUDE.md must be DELETED, not left in place. Two files
saying the same thing is the drift risk this whole review is about.
-->
