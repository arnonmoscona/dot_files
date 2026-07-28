---
name: reduce-complexity
description: Reduce cyclomatic and cognitive complexity in Python code. Break down complex functions, simplify control flow, and track complexity trends over time.
status: stable
---

# Code Complexity Reduction

Reduce code complexity to improve maintainability and understandability.

Effective use of context windows.

## Objectives

1. Measure cyclomatic and cognitive complexity
2. Identify overly complex functions and modules
3. Identify overly long files (no code files >500 lines, unless unavoidable)
4. Apply refactoring patterns to reduce complexity
5. Track complexity improvements over time
6. Enforce complexity thresholds in CI/CD

## Required Tools

You need at least one command line tool on the system to measure complexity. **If none of these tools are available, then this skill would not work well and the user should be alerted to this***

- **pyscn**: The preferred tol. It measures several complexity measures as well as identifies other code issues like duplicate code segments, dead code, and other issues. 
- **complexipy** Rust based cognitive complexity analyzer
- **radon**: Cyclomatic complexity & maintainability index
- **lizard**: Cognitive complexity (better for readability)
- **xenon**: CI/CD threshold enforcement
- **wily**: Track trends across git history

### Optional: code-review-graph MCP

If the project has `code-review-graph` installed (its tools are named
`mcp__code-review-graph__*`; a `.code-review-graph/` directory at the project root is also
a signal), it complements the complexity measurers above: they tell you WHICH function is
too complex, the graph tells you what will BREAK if you restructure it. Use it for:

- `find_large_functions_tool` -- corroborate the complexity tool's hit list.
- `get_impact_radius_tool` -- blast radius BEFORE extracting or splitting a function. This
  is the single highest-value one here: a "safe" extraction is only safe if you know every
  caller.
- `query_graph_tool` with pattern `callers_of` -- enumerate callers, and find a function's
  tests by filtering results to `is_test:true`. (In some repos the dedicated `tests_for`
  heuristic misses class-based `unittest.TestCase` methods -- check the project's own
  CLAUDE.md for caveats before trusting it.)
- `get_affected_flows_tool` -- which execution paths run through the function you are about
  to restructure, so you know what to re-test.
- `get_hub_nodes_tool` / `get_bridge_nodes_tool` -- a complex function that is also a hub or
  bridge is the riskiest to touch and deserves the most test coverage first.
- `refactor_tool` -- plan renames and find dead code (dead code is complexity you can delete
  outright, which always beats restructuring it).

**Staleness precondition.** Embeddings, flows and communities do NOT auto-update in every
setup (a common PostToolUse hook passes `--skip-flows`). Before relying on
`semantic_search_nodes_tool`, `get_affected_flows_tool` or `get_architecture_overview_tool`,
refresh:

```bash
uv run code-review-graph embed && uv run code-review-graph postprocess
```

The structural queries (callers, impact radius, large functions) read live structure and do
not need this.

**Verify before you cut.** Treat graph output as a lead, not proof -- confirm a caller list
against the IDE or `ag` before deleting or resignaturing anything. A missed caller in a
"behaviour-preserving" refactor is exactly the failure this skill must not produce.

## Discovery Phase

### Measure Complexity

```bash
# Key commands
pyscn analyze .              # Produces a comprehensive code quality analysis and writes it in the .pyscn/reports directory. To focus on specific issues or control the output format run `pyscn --help`. Full documentation at https://ludo-technologies.github.io/pyscn/ 
# Less preferred tools:
radon cc . -n C              # Functions with complexity ≥11
lizard -C 15 .               # Cognitive complexity warnings
radon mi . -n B              # Maintainability index <65
wily build .                 # Initialize tracking (one-time)
wily diff HEAD~10            # Compare trends
scc --by-file --ci           # Optional: code statistics (called 'sccount' on openSUSE)
```

### Thresholds

The following thesholds are just general guidance. If using pyscn, it produces its own high/medium/low score for each individual suggestion while providing the numerical score for those checks that produce one.

For the other tools (if pyscn is not installed but any of the others are):

- **Cyclomatic**: Refactor at ≥C (11+)
- **Cognitive**: Refactor at >15
- **Maintainability**: Refactor at <65
- **Lines per code file**: Split if significantly >500, unless unavoidable

### Manual Pattern Detection

When the results from pyscn are mostly clean with respect to complexity (no high, very few medium suggestions) - it may be beneficial to also do the following:

Use Explore agent to find these complexity-increasing patterns:

**Magic numbers and strings**:
- Numeric literals (except 0, 1, -1) scattered in code
- String literals used as keys, thresholds, or configuration
- Search: `grep -rE '\b[0-9]{2,}\b' --include='*.py'` for multi-digit numbers
- Look for: fee calculations, timeout values, buffer sizes, regex patterns

**Repetitive field operations**:
- Multiple similar if-statements checking/setting object fields
- Pattern: `if obj.field: obj.field = func(obj.field)`
- Search: Functions with 5+ lines doing similar operations on different fields
- Candidates: configuration loading, validation, serialization, field clearing

**Repeated complex type definitions**:
- Same complex type annotation used in multiple places
- Example pattern: `Literal["a", "b", "c"] | None` repeated across functions/classes
- Search: `grep -r 'Literal\[' --include='*.py'` then look for duplicates
- Also: Complex union types, nested generics used multiple times
- Candidates: Function parameters, return types, class attributes, cast() calls

**Long if/elif chains**:
- 5+ conditional branches doing similar operations
- Can often be replaced with lookup tables (dicts) or structural pattern matching (`match` statement) or polymorphism

**Deeply nested code**:
- 4+ levels of indentation
- Multiple nested loops or conditionals

## Refactoring Patterns

### Prerequisites

**VERY important**: Do not attempt to refactor functions that do not have good code coverage in fast unit tests. Ideally the individual function that is a candidate for refactoring should have its own uniot tests. You may consider creating additional unit tests before the refactoring attempt so that you can iterate safely and have high confidence in the correctness of the result. 

**You must start out with the full test suite 100% green** Any failing tests before refactoring starts present a large risk of incorrect results.

It is highly recommended that before you start refactoring attempts that the git tree is clean and there is no staged material for commits, except perhaps new usnit tests that were created in preparation for refactoring.

### Extract Function

Break complex functions into focused sub-functions:

```python
# BEFORE - 20+ lines, complexity: 15
def process_order(order: dict) -> bool:
    # Validation, payment, confirmation logic all mixed

# AFTER - Each function <5 lines, complexity: <5
def process_order(order: dict) -> bool:
    return is_valid_order(order) and process_payment(order) and complete_order(order)
```

This approach can really help with deeply nested loops. For example, given the function:

```python
def process_matrix(matrix):
    """Processes a 3D matrix. Original code used 3 nested loops."""
    for z, layer in enumerate(matrix):
        for y, row in enumerate(layer):
            for x, value in enumerate(row):
                # High cognitive complexity: deeply nested logic
                if value > 0 and value % 2 == 0:
                    if (x + y + z) % 3 == 0:
                        matrix[z][y][x] = value * 2
```

You could refactor the code by breaking it into 3 functions like so:

```python
def should_transform(x, y, z, value):
    """Encapsulates the filtering logic."""
    is_positive_even = value > 0 and value % 2 == 0
    coordinate_multi_of_three = (x + y + z) % 3 == 0
    return is_positive_even and coordinate_multi_of_three

def process_cell(matrix, x, y, z):
    """Handles operations for a single cell."""
    value = matrix[z][y][x]
    if should_transform(x, y, z, value):
        matrix[z][y][x] = value * 2

def process_matrix(matrix):
    """Main loop with reduced cognitive complexity."""
    for z, layer in enumerate(matrix):
        for y, row in enumerate(layer):
            for x in range(len(row)):
                process_cell(matrix, x, y, z)
```

### Convert for and while loops into comprehensions

Python comprehensions are 

- Terser
- More idiomatic
- Easier to understand when not deeply nested (avoid more than one nesting level, meaning no more than one inner comprenension)
- Can be either concrete collections or lazy generators (very useful for early temination of iteration once a condition is satisfied)

### Replace custom python code with builtin functions

Often you will find that authors, and especially coding agents, write pleanty of python code that does thinng that could be directly replaced by existing python standard library functions or combinations of them. 

Find opportunities to replace such wasteful and potentially incorrect or non-performant code fragments by using builtin capabilities of the Python standard library. Exampoles include, but are not limited to:

`map()`, `filter()`,`zip()`,`enumerate()`,`sorted()`,`any()`,`sum()`,`min()`,`max()`, the `collections` module, the `itertools` module, the `functools` module

Often project include additional popular libraries that can also contain already implemented and tested functions that can replace hand-rolled code fragments. You can check the `pyproject.toml` file for such existing dependencies, and then explore the possibility of leveraging those libraries (the built-in standard library is generally preferred, but these packages can have advanced functionality not provided by the standard library).

Examples: `fastcore`, `more-itertools`, `pydantic`, `funcy`, `toolz` `pydash`

### Guard Clauses

Replace nested conditions with early returns:

```python
# BEFORE - Deep nesting
if user:
    if user.get("active"):
        if user.get("verified"):
            return True
return False

# AFTER - Guard clauses
if not user or not user.get("active") or not user.get("verified"):
    return False
return True
```

### Lookup Tables

Replace if/elif chains with dictionaries:

```python
# BEFORE - Nested conditionals (complexity: 7)
if customer == "gold" and total > 1000: return 0.20
elif customer == "gold": return 0.15
# ... more branches

# AFTER - Lookup table (complexity: 2)
RATES = {("gold", "high"): 0.20, ("gold", "low"): 0.15, ...}
return RATES.get((customer, tier), 0.0)
```

### Extract Magic Numbers and Strings

Extract scattered literals to configuration classes:

```python
# BEFORE - Magic numbers throughout code
if amount < 100: base_fee = 2.50
elif amount < 1000: base_fee = 5.00
if account_type == "premium": return base_fee * 0.5

# AFTER - Configuration class
class FeeConfig:
    TIER_SMALL = 100
    FEE_SMALL = 2.50
    PREMIUM_DISCOUNT = 0.5

if amount < FeeConfig.TIER_SMALL:
    base_fee = FeeConfig.FEE_SMALL
```

**Benefits**: Single source of truth, easy to change, self-documenting, can load from environment

### Replace Repetitive Field Operations

Replace repetitive if-statements with loops over field names:

```python
# BEFORE - 15 similar if-statements (complexity: 9)
if config.email.smtp_host:
    config.email.smtp_host = substitute_secret(config.email.smtp_host, secrets)
if config.email.smtp_user:
    config.email.smtp_user = substitute_secret(config.email.smtp_user, secrets)
# ... 13 more similar lines

# AFTER - Loop over field list (complexity: 3)
email_fields = ["smtp_host", "smtp_user", "smtp_password", "smtp_from"]
for field in email_fields:
    if value := getattr(config.email, field, None):
        setattr(config.email, field, substitute_secret(value, secrets))
```

**Pattern**: Use getattr/setattr loops for: validation, field clearing, transformation, serialization

### Extract Repeated Complex Type Definitions

Replace repeated complex type annotations with TypeAlias:

```python
# BEFORE - Type repeated 8 times across files
cache_mode: Literal["use", "only", "refresh"] | None
# ... used in 8 different functions, classes

# AFTER - Define once, use everywhere
CacheMode = Literal["use", "only", "refresh"]
CacheModeOptional = CacheMode | None

cache_mode: CacheModeOptional
```

**Placement**:
- Module-level: types used within one module
- `types.py`: project-wide types
- `__init__.py`: package-wide exports

**Benefits**: DRY, semantic names, easier to change, reduced typos

## Verification Checklist

- [ ] All tests pass after refactoring
- [ ] Code coverage maintained or improved
- [ ] Pyscn analysis report of refactored code either substantially improved the score of refactored code or no longer flags it at all 
- [ ] All original behavior is preserved
- [ ] Code follows project conventions and standards

If pyscn is unavailable, consider (for available tools):

- [ ] `radon cc . -n C` reports no functions with complexity ≥C (11+)
- [ ] `lizard -C 15 .` reports no cognitive complexity warnings
- [ ] `radon mi . -n B` reports no modules with maintainability index <65
- [ ] No code files >500 lines (unless unavoidable)
- [ ] `wily build .` initialized for tracking


### Beyond mere refactoring: leverage present specialized libraries and packages

This is more of a corner-case. The `pyproject.toml` file may reveal existing dependencies on specialized packages that may solve complex problems in a packaged, tested ways. Examples include:

- `networkx`, `praph-tool`, `rustworkx` for graph algorithms
- the builtin `statistic` module, `statsmodels` (plus stats capabilities in `numpy`, `scipy`)
- table and data-frame processing: `numpy`, `pandas`, `scipy`, `polars`, `duckdb`, `pyarrow`, even in-memory `sqlite` databases
- general ML: `scikit-learn`
- Various NLP packages: `spacy`, `nltk`, `pytorch-nlp`, `gensim` transformers
- template processing, like `jinja2`
- time and date functions: in addition to the rich builtin functionality in `datetime`, `time`, `calendar` etc. you may find existing dependencies on packages like `arrow`, `pendulum`, `dateutil`, `pytz`
- state machines: `transitions`, `pysm`, `statesman` -- those can sometimes replace convoluted if-then-else situations where simple lookups etc. don't quite achive an elegant result

While these are "edge cases" you may find that an agent wrote complicated code that is much better handled by one of the packages present in the dependencies. In some cases the complex code is older than the introduction of the additional dependencies and was never refactored to leverage the new capability.

In cases like this you may need to investigate further than the narrow refactoring of flagged code. The problem may not be the flagged code itself, but rather the parts that the flagged code is serving. The question to ask is "what is the larger problem we're trying to solve here?" If that problem is a good match for the capabilities of an existing dependency but is not taking advantage of them, or does so poorly - then the solution may lie in a larger refactoring of not only the flagged function but a whole section, or module, or even package. 

This type of finding is very valuable, but is a large expansion of the scope than the ask of "improve the complexity of this function". In such cases you may attempt a focused improvement and highlight the larger refactoring opportunity to the user, or you may punt on the refactoring if your judgement is that it is really better to do the larger refactoring, and tell the user of your opinion. If the user instists on the point refactoring then comply. But don't leave the user in the dark about a "golden refactroing or rewrite opportunity.

In some cases you will find that none of these dependencies are actually in the project, but a quick investigation (for instance via context7) may show that there is a lot of potential of replacing some complex nexus of code with an existing library (especially if it is already on the lists above) may be a good direction for the user to consider.

## More on extracting helper methods

### Instructions

1. **Analyze the current method** to identify sources of cognitive complexity:
   - Nested conditional statements
   - Multiple if-else or switch chains
   - Repeated code blocks
   - Multiple loops with conditions
   - Complex boolean expressions

2. **Identify extraction opportunities**:
   - Validation logic that can be extracted into a separate method
   - Type-specific or case-specific processing that repeats
   - Complex transformations or calculations
   - Common patterns that appear multiple times

3. **Extract focused helper methods**:
   - Each helper should have a single, clear responsibility
   - Extract validation into separate `Validate*` methods
   - Extract type-specific logic into handler methods
   - Create utility methods for common operations
   - Use appropriate access levels (static, private, async)

4. **Simplify the main method**:
   - Reduce nesting depth
   - Replace massive if-else chains with smaller orchestrated calls
   - Use switch statements where appropriate for cleaner dispatch
   - Ensure the main method reads as a high-level flow

5. **Preserve functionality**:
   - Maintain the same input/output behavior
   - Keep all validation and error handling
   - Preserve exception types and error messages
   - Ensure all parameters are properly passed to helpers

6. **Best practices**:
   - Make helper methods static when they don't need instance state
   - Use null checks and guard clauses early
   - Avoid creating unnecessary local variables
   - Consider using tuples for multiple return values
   - Group related helper methods together

### Implementation Approach

- Extract helper methods before refactoring the main flow
- Test incrementally to ensure no regressions
- Use meaningful names that describe the extracted responsibility
- Keep extracted methods close to where they're used
- Consider making repeated code patterns into generic methods

### Result

The refactored method should:
- Have cognitive complexity reduced to the target threshold of `${input:complexityThreshold}` or below
- Be more readable and maintainable
- Have clear separation of concerns
- Be easier to test and debug
- Retain all original functionality
