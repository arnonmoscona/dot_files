---
paths:
  - "**/*.py"
  - "**/*.js"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.sh"
  - "**/*.toml"
---

# Comments and doc comments: informative and SHORT

Loaded automatically when you touch a source file. The one-line rule lives in `CLAUDE.md`; this file is the detail.

You are much too verbose here by default. **Assume every comment you write is twice as long as it should be.**

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

