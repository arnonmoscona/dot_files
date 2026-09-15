---
name: diagramming
description: >
  How to produce a diagram that is actually clear -- notation choice, layout engine
  selection, tuning levers, and the quality criteria to judge the result against. Use
  this whenever you are about to draw a diagram of any kind: an architecture picture,
  a dependency or call graph, a state machine, a sequence or flow, a component
  breakdown, a layer stack, an ER diagram. Use it even when the request sounds trivial
  ("just sketch the modules", "show me how these connect", "add a diagram to the docs")
  and even when no notation is named, because the notation and engine choice is the
  decision that determines whether the result is readable. Also use it when an existing
  diagram is being revised, when someone says a diagram is cluttered or hard to follow,
  or when deciding whether a picture is worth drawing at all.
---

# Diagramming

The point of a diagram is that someone understands the structure faster by looking than
by reading. A cluttered diagram fails that test and is worse than the prose it replaced,
so treat layout quality as part of the deliverable, not decoration.

## Mermaid is the default

Start with Mermaid unless there is a reason not to. It renders inline in Markdown almost
everywhere Arnon reads: JetBrains preview, Obsidian, GitHub, and Claude artifacts. No
toolchain, no build step, no binary committed next to the source. Diagrams that live in
documentation should stay legible when the documentation moves, and Mermaid does that.

It also covers far more than flowcharts -- sequence, state, ER, class, gantt, C4, mindmap,
timeline, journey. For most of those, layout is not the hard part and Mermaid is simply
the right answer.

## When to reach past Mermaid

The measured boundary is **dense layered graphs**: roughly 25+ nodes with grouping, where
edges cross package boundaries. Mermaid's `dagre` layout spreads these very wide with
large empty regions and full-height edges; `elk` makes them very tall with long orthogonal
bundles. Neither is a tuning failure -- the layout engines simply give up on this shape.

At that point Graphviz `dot` produces a dramatically more compact and readable drawing.
That is a specific, narrow exception, not a general preference.

Signals you have crossed the line: the render is several times taller or wider than it is
in the other dimension; large regions are empty; edges run the full height or width; boxes
overlap; labels are obscured.

## Check what is installed, then render, then LOOK

This is the step that matters most, and it is the one most easily skipped.

**You can see images.** Rendering a diagram to PNG and reading the file makes you a
sighted judge of your own output. Guessing at a renderer's behaviour by reading its source
is guessing; looking is measuring.

```bash
for t in dot neato fdp sfdp twopi circo plantuml mmdc rsvg-convert; do
  printf '%-14s ' "$t"; command -v "$t" >/dev/null 2>&1 && echo yes || echo -
done
```

If a renderer is available, the loop is: generate → render to PNG → read the image →
judge against the criteria below → adjust. If none is available, say so plainly, get the
diagram's *content* right, and hand over the source and generator rather than iterating
on a layout you cannot see.

The failure this prevents is real and expensive: several rounds of layout changes judged
only by reading generated source, producing no improvement, while a renderer sat installed
and unchecked the whole time.

## What makes a layout clean

Arnon's criteria. They conflict with each other and cannot all be maximised at once, but
they are what a reader's eye is actually reacting to, and rating a candidate against them
predicts human judgement well:

1. **Closely related entities are drawn close together.**
2. **Arrows are short.**
3. **Arrows have few bends.**
4. **Arrow crossings are minimised.**
5. **Arrows and lines do not cross over boxes.**
6. **Boxes do not overlap.**
7. **The whole diagram is reasonably compact.**

When comparing candidates, name which criteria each one wins and loses on rather than
declaring one "better" -- the trade is usually between compactness and crossings, or
between short arrows and clean routing, and the user may weigh those differently than you
do.

## Which engine for which job

| engine | good for |
|---|---|
| Mermaid `dagre` | the default; everything that is not a dense layered graph |
| Mermaid `elk` | rarely better; tends to go very tall on dense graphs |
| Graphviz `dot` | **layered DAGs.** The strongest option for dependency, call and layer graphs |
| Graphviz `neato` | hub and component structure -- what `dot` buries. Best of the force family |
| Graphviz `twopi` | radial; unusable untuned, legible tuned, rarely a winner |
| Graphviz `fdp` | force-directed with cluster support; no layer ordering |
| Graphviz `sfdp` | may fail outright on clustered graphs |
| PlantUML | good local structure; tends to sweep long curves across the canvas |

**The force and radial engines are not just worse `dot`.** They answer a different
question. On a flat graph with no sub-packages, `neato` and `twopi` make disconnected
sub-systems and hub modules obvious at a glance, which a layered drawing hides. If the
insight you want is "what are the natural components here", they are the right tool even
though `dot` is clearer.

**Why they fail on layered graphs**: a low-level module imported by everything gets pulled
apart toward its many consumers. That is exactly where an explicit cluster beats emergent
proximity.

## Tuning levers, in order of how much they moved the needle

Structure first, cosmetics last. Two levers did nearly all the work in practice:

1. **Grouping.** Put related nodes in a box. Collecting scattered flat nodes into one
   group removes the long edges that were dragging the layout apart.
2. **Rank direction.** `rankdir=TB` puts entry points at the top and leaves at the bottom
   -- both reading order and the orientation a layer stack is usually pictured in. `BT`
   inverts the stack, which fights the reader's mental model.

Then the smaller ones:

3. `splines=ortho` removes curved sweeps; `polyline` and `spline` are the alternatives.
   Orthogonal is usually cleaner but is more likely to cut through a box, so check.
4. `concentrate=true` merges parallel edges -- it can warn about degenerate ranks and
   makes the drawing show fewer edges than the graph has. Prefer `false` unless it buys
   something visible.
5. `nodesep` / `ranksep` for density, `overlap=prism|false` for the force engines.
6. `root=<node>` is **twopi's biggest lever**, bigger than any spacing attribute.

For Mermaid, the equivalent structural levers are subgraphs, and invisible links (`~~~`)
between them to pin rank order without drawing anything.

## Reduce before you draw

A transitive reduction -- dropping every edge implied by a longer path -- often halves the
edge count and turns an unreadable tangle into a structure. It is honest as long as you say
the drawing is reduced, since reachability is unchanged.

Check for cycles first: a transitive reduction is only meaningful on a DAG, and finding a
cycle is itself worth reporting.

## Recipe: Graphviz with rounded orthogonal edges

Graphviz has no rounded-ortho mode. Round the corners afterwards by reducing each edge path
to its polyline and replacing interior corners with quadratic arcs. In the toolguard repo
that is `tools/round_svg_corners.py`; elsewhere it is a short script worth rewriting.

```bash
dot -Tsvg graph.dot -o /tmp/sharp.svg
python round_svg_corners.py /tmp/sharp.svg graph.svg --radius 8
rsvg-convert -f png -o graph.png graph.svg
```

Keep the `.dot` source next to the rendered output and record the regenerate command, so
the picture stays reproducible rather than becoming a binary nobody can update.

## Colour carries information or it carries nothing

If the diagram has groups, colour by group. If it is flat, colour by a structural role you
can compute -- entry point, intermediate, leaf, isolated -- so the colour tells the reader
something a box would otherwise have to. Decorative colour is noise.

## When comparing candidates, show the work

If you have rendered several variants, say which won and *why*, in terms of the criteria.
Keep the losing renders somewhere the user can open them; a ranking they cannot check is
an assertion. Name what you did not evaluate rather than implying full coverage.
