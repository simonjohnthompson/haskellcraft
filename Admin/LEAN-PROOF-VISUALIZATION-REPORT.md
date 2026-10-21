# Visualizing equational proofs in Lean

Prepared in response to a request to investigate how Lean proofs about equations could be shown
the way the book shows them: as chains of steps, each justified by an equation label such as
`(sum.2)` or `(hyp)`, inside an explicit `(base)`/`(ind)` induction structure. The report surveys
existing software, then plans a tool that tracks the Lean proof state step by step and renders it
in the book's style. A small prototype of the extraction stage was built and run against the
Chapter 9 Lean file to check that the plan is feasible. Nothing in the `Lean/` project has been
changed; the prototype lives outside the repository.

## Summary

- **No existing tool does this.** Several tools show Lean proof states, but each shows them as
  goal lists (Lean's infoview, Verso, Alectryon), as trees (Paperproof), or as controlled natural
  language (Verbose Lean). None produces the book's "left-hand side, then right-hand side, each a
  chain of `= ... by (label)` lines" layout.
- **Lean records everything such a tool needs.** As it checks a file, Lean builds *info trees*
  recording the goal before and after every tactic. For `rw [a, b, c]` this includes the goal
  after *each* rewrite rule, so a single `rw` line yields the whole chain of intermediate
  expressions. The prototype extracts exactly this.
- **Two routes, best used together.**
  1. *Write the proofs in book style*, using Lean's `calc` notation. This needs no new
     software, and the result already reads almost line for line like the book (an example
     below compiles against the existing Chapter 9 file).
  2. *Build a renderer* that reads the info trees and prints book-style LaTeX or Markdown from
     ordinary tactic proofs. The plan below breaks this into five stages; the first is already
     prototyped.

## What the book shows

The worked proof of `sum (doubleAll xs) = 2 * sum xs` in Chapter 9 is typical. After setting up
the induction, with goals labelled `(base)` and `(ind)` and the hypothesis `(hyp)`, each side of
the equation is simplified separately:

```
sum (doubleAll (x:xs))
  = sum (2*x : doubleAll xs)        by (doubleAll.2)
  = 2*x + sum (doubleAll xs)        by (sum.2)
  = 2*x + 2 * sum xs                by (hyp)

2 * sum (x:xs)
  = 2 * (x + sum xs)                by (sum.2)
  = 2*x + 2 * sum xs                by arith.
```

The two chains meet at the same expression, which finishes the case. Three features matter for
any Lean visualization:

1. **Each step rewrites one side**, not the whole equation.
2. **Each step is justified by a label**: a defining equation such as `(sum.2)`, the induction
   hypothesis `(hyp)`, or an appeal to arithmetic.
3. **The induction structure frames the chains**: base case and induction step, with the
   hypothesis stated for the step.

## How Lean's proofs differ

The Lean files prove the same theorem like this:

```lean
theorem sum_doubleAll (xs : List Int) :
    mySum (doubleAll xs) = 2 * mySum xs := by
  induction xs with
  | nil => simp [mySum, doubleAll]
  | cons x xs hyp =>
      simp only [mySum, doubleAll]
      omega
```

The induction structure (feature 3) is there: `nil` and `cons` are the book's `(base)` and
`(ind)`, and `hyp` is named in the source. The individual steps are not. `simp` makes all the
rewrites at once, and `omega` does the arithmetic, so there is nothing step-by-step for a reader
to see.

The steps become visible if the proof uses `rw`, which rewrites with one equation at a time:

```lean
  | cons x xs hyp =>
      rw [doubleAll.eq_2, mySum.eq_2, hyp, mySum.eq_2]
      omega
```

Here `doubleAll.eq_2` is Lean's automatically generated name for the second defining equation of
`doubleAll`, the book's `(doubleAll.2)`. Even so, `rw` differs from the book in two ways:

- **`rw` works on the whole equation.** It rewrites the goal `lhs = rhs`, so a step can change
  either side, or both.
- **`rw` rewrites every occurrence.** In the base case, `rw [mySum.eq_1]` rewrites `mySum []` on
  *both* sides at once, turning `mySum [] = 2 * mySum []` into `0 = 2 * 0`. The book shows these
  as two separate steps, one in each chain.

A renderer can undo both of these, as described in stage 2 of the plan.

## What Lean records

Lean's editor support shows the proof state (the hypotheses and the goal) at the cursor, in the
VS Code *infoview*. This is interactive, and shows one state at a time. But the same information
is stored for the whole file. While elaborating, Lean builds an **info tree** for each command;
every tactic node carries the goals before it ran and the goals after. These trees are what the
infoview queries, and they are available to any Lean program.

### Prototype

A short Lean program (about 60 lines) was written that elaborates a file, walks its info trees,
and prints each tactic with the goal it leaves. Run on the `rw` version of the proof above, the
relevant part of its output for the `cons` case is:

| Rule applied     | Goal afterwards                                        |
|------------------|--------------------------------------------------------|
| (start)          | `mySum (doubleAll (x :: xs)) = 2 * mySum (x :: xs)`    |
| `doubleAll.eq_2` | `mySum (2 * x :: doubleAll xs) = 2 * mySum (x :: xs)`  |
| `mySum.eq_2`     | `2 * x + mySum (doubleAll xs) = 2 * mySum (x :: xs)`   |
| `hyp`            | `2 * x + 2 * mySum xs = 2 * mySum (x :: xs)`           |
| `mySum.eq_2`     | `2 * x + 2 * mySum xs = 2 * (x + mySum xs)`            |
| `omega`          | (no goals)                                             |

This is the book's proof, with both chains interleaved. The first three rules change only the
left-hand side, and give the book's left-hand chain; the fourth changes only the right-hand side;
`omega` is the book's "by arith.". The prototype got one goal per *rule*, not just one per `rw`
line, because Lean records a separate info node for each rule in the list.

For `simp`, the info tree only has the goals before and after. But Lean has a trace option,
`set_option trace.Meta.Tactic.simp.rewrite true`, that lists every rewrite `simp` makes, with the
lemma used and the subterm before and after:

```
unfold doubleAll, doubleAll (x :: xs) ==> 2 * x :: doubleAll xs
mySum.eq_2:  mySum (2 * x :: doubleAll xs) ==> 2 * x + mySum (doubleAll xs)
hyp:         mySum (doubleAll xs) ==> 2 * mySum xs
unfold mySum, mySum (x :: xs) ==> x + mySum xs
```

So `simp` proofs can be rendered step by step too, by replaying these rewrites.

## Existing software

None of these produces the book's layout, but several are useful building blocks, and some are
worth knowing about as alternatives.

### For Lean

- **The infoview** (part of the Lean VS Code extension). Shows the state at the cursor; moving
  through a proof line by line shows each step. It is the best tool for *doing* the proofs, but
  it isn't a document a reader can scan. It can be extended with custom panels using
  [ProofWidgets](https://reservoir.lean-lang.org/@leanprover-community/proofwidgets), which
  matters for stage 5 below.
- **`calc` blocks** (built into Lean). Lean's own notation for chains of equations, each step
  with its own proof. This is the closest thing Lean has to the book's notation, and it is the
  basis of route 1 below. Mathlib adds a
  [calc widget](https://florisvandoorn.com/LeanCourse24/docs/Mathlib/Tactic/Widget/Calc.html)
  that helps write new steps by selecting subterms of the goal.
- **[Verso](https://verso.lean-lang.org/)**, the Lean FRO's documentation tool, which is used to
  write Lean's own reference manual. Its pages are written as Lean files, and it renders Lean
  code into HTML with hovers and the intermediate proof states. It is the most actively
  developed way to publish Lean proofs on the web, and is a candidate front end for the
  website. It shows proof states as goal lists, not as equational chains.
- **Alectryon with LeanInk.** Alectryon renders proof scripts with the proof state after each
  step interleaved, and was built for Coq; LeanInk connected it to Lean 4. The
  [LeanInk repository](https://reservoir.lean-lang.org/@leanprover/leanInk/versions) was
  archived in 2024 and only supports a very old Lean, so this is not a practical route now;
  Verso has taken over its role.
- **[Paperproof](https://reservoir.lean-lang.org/@Paper-Proof/examples).** A VS Code extension
  that draws a Lean proof as a tree of hypotheses and goals, close to a natural-deduction tree. It
  shows the *logical* structure of a proof well, but an equational chain would appear as a
  sequence of single goals, not as a chain of expressions.
- **[Verbose Lean](https://reservoir.lean-lang.org/@PatrickMassot/verbose)** (Patrick Massot,
  [ITP 2024](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2024.27)). Tactics
  in a controlled natural language, designed to teach students to move between Lean and paper
  proofs. It changes how proofs are *written*, rather than displaying existing ones. Massot also
  mentions a related project, LeanInformal, that turns Lean proofs into readable English
  documents.
- **Machine interfaces**: the [Lean REPL](https://reservoir.lean-lang.org/@leanprover-community/REPL),
  [LeanDojo](https://leandojo.readthedocs.io/en/latest/user-guide.html) and
  [LeanInteract](https://github.com/augustepoiroux/LeanInteract). These give programs JSON access
  to tactic states, mainly for machine learning work. They are an alternative to the prototype's
  direct use of info trees, at the cost of an extra dependency.

### In other systems

- **Agda** has an equational reasoning notation in its standard library,
  `begin e₁ ≡⟨ reason ⟩ e₂ ≡⟨ reason ⟩ ...`, closed by an end-of-proof box, which is close to the book's style and is checked
  by Agda directly.
- **Liquid Haskell** supports proofs written as Haskell functions that are chains of equations
  with justifications. Vazou and others, in
  ["Theorem proving for all"](https://arxiv.org/abs/1806.03541) (Haskell Symposium 2018), recast
  the equational proofs from Hutton's textbook this way and found that they "look essentially the
  same". This is the nearest existing match to the book's style, and is in Haskell itself. It
  would be a different project from the Lean work, though.

## Route 1: write the proofs in book style with `calc`

Lean's `calc` can express the book's two chains directly. This version of the proof compiles
against the existing `Chapter9.lean`:

```lean
theorem sum_doubleAll_book (xs : List Int) :
    mySum (doubleAll xs) = 2 * mySum xs := by
  induction xs with
  | nil =>
    have lhs : mySum (doubleAll []) = 0 :=
      calc mySum (doubleAll [])
          = mySum [] := by rw [doubleAll.eq_1]   -- (doubleAll.1)
        _ = 0        := by rw [mySum.eq_1]       -- (sum.1)
    have rhs : 2 * mySum [] = 0 :=
      calc 2 * mySum []
          = 2 * 0 := by rw [mySum.eq_1]          -- (sum.1)
        _ = 0     := by omega                    -- *
    rw [lhs, rhs]
  | cons x xs hyp =>
    have lhs : mySum (doubleAll (x :: xs)) = 2 * x + 2 * mySum xs :=
      calc mySum (doubleAll (x :: xs))
          = mySum (2 * x :: doubleAll xs) := by rw [doubleAll.eq_2]  -- (doubleAll.2)
        _ = 2 * x + mySum (doubleAll xs)  := by rw [mySum.eq_2]      -- (sum.2)
        _ = 2 * x + 2 * mySum xs          := by rw [hyp]             -- (hyp)
    have rhs : 2 * mySum (x :: xs) = 2 * x + 2 * mySum xs :=
      calc 2 * mySum (x :: xs)
          = 2 * (x + mySum xs)   := by rw [mySum.eq_2]               -- (sum.2)
        _ = 2 * x + 2 * mySum xs := by omega                         -- arith.
    rw [lhs, rhs]
```

Set beside the book's chains, this is the same proof in the same order, with the labels as
comments. Lean checks every intermediate expression, so the chain on the page is guaranteed to be
correct.

**Advantages:** no new software; the proofs themselves become the visualization; it works today,
in the infoview and in any tool that shows Lean source (including Verso).

**Disadvantages:** the proofs are several times longer than the `simp` versions, and every
intermediate expression has to be typed out. That is good for the worked examples in the text,
where the point *is* the steps, but tedious for the exercises. The step justifications (`by rw
[mySum.eq_2]`) also repeat what the label comment says.

**Suggestion:** use `calc` for the worked examples from the book, perhaps as a second version
alongside each existing `simp` proof, so that the files show both the book's proof and the
concise Lean one.

## Route 2: a renderer from ordinary tactic proofs

The aim is a command, say `lake exe bookproof HaskellCraft/Chapter9.lean sum_doubleAll`, that
prints the proof in the book's layout as LaTeX (in the book's `alltt` style, with `\hfill by
(label)`) or as Markdown for the website. It would take five stages.

### Stage 1: extract the steps (prototyped)

Elaborate the file with info trees enabled, and walk the tree for the chosen theorem. For each
tactic node record:

- the tactic and, for `rw`, the individual rule;
- the goal before and after, pretty-printed;
- the case it belongs to, from the `induction ... with` alternatives (`nil`, `cons x xs hyp`),
  with the induction hypotheses from the local context.

Output this as JSON, so that the later stages need not be written in Lean. The prototype does
everything here except the JSON and the restriction to one theorem; it also needs to drop the
structural nodes (`by`, separators, the whole `rw [...]`) that appear in the tree alongside the
rule-level nodes.

### Stage 2: turn goal changes into one-sided steps

For each rewrite, compare the goal `lhs = rhs` before and after:

- if only `lhs` changed, it is a step in the left-hand chain;
- if only `rhs` changed, it is a step in the right-hand chain;
- if both changed (the base-case `mySum.eq_1` above), it is split into two steps, one per chain,
  each justified by the same rule.

Then print the left-hand chain, the right-hand chain, and the point where they meet. When a step
is closed by `rfl` or `omega`, the remaining difference between the two sides is shown as a final
"by arith." step, as the book does.

For `simp`, replay the rewrite trace (above) against the goal to recover the same sequence of
goals, then proceed as for `rw`. An alternative is to have the tool re-run the proof with each
`simp only [...]` replaced by a `rw` of the lemmas in the order the trace used them, and extract
from that.

For a `calc` proof, the steps are already one-sided; the tool just reads them off.

### Stage 3: labels

Map Lean's names to the book's labels: `mySum.eq_2` becomes `(sum.2)`, `hyp` becomes `(hyp)`,
`omega` becomes "arith.". The Lean files already have the book's labels as comments on each
equation (`| x :: xs => x + mySum xs   -- (sum.2)`), so the tool could read them from there. A
more robust choice is a small attribute, for example `@[book_label "sum"] def mySum`, which the
tool can look up in the environment.

Theorem labels work the same way: `map_append` is the book's `(map++)`, and the book's names for
results could be given by an attribute or taken from the existing doc comments.

### Stage 4: Haskell-like printing

Lean prints `x :: xs`, `myAppend`/`+++` and `mySum`; the book has `x:xs`, `++` and `sum`. Lean's
pretty-printer can be customized (with *delaborators* and `notation`), so a "book" printing mode
could print the Lean terms in Haskell syntax, with the `my` prefixes dropped. This is cosmetic but
important for a reader comparing the output with the text.

### Stage 5: output

- **LaTeX** in the book's own `alltt` format, so generated proofs could be included in the book
  or compared with it automatically. A check that the book's chains match the generated ones would
  catch errors in the text.
- **Markdown/HTML** for the website, possibly via Verso, which would add hovers with the full
  proof state.
- **Live view in the editor**: a ProofWidgets panel in the infoview that shows the book-style
  version of the proof being edited, updated as it changes. This is the most useful form for
  students working through the Lean exercises, and reuses stages 1–4 unchanged.

### Effort and risks

Stages 1–3 are a few days' work, given the prototype; stage 4 is a day or two for the types used
so far; stage 5 depends on the output chosen, with LaTeX and Markdown the quickest and the
infoview panel the most work.

The main risks:

- **Lean's internal APIs change.** Info trees are internal, and details changed even between
  recent versions (the prototype had to use `String.Pos.Raw`). The tool would need updating with
  each Lean upgrade; pinning the toolchain, as the project already does, contains this.
- **Not every proof is equational.** Proofs that use `cases`, `by_cases`, `funext` or `split`
  have structure beyond chains of equations. The renderer should show these as headings (one
  per case, as for induction), and fall back to the plain goal list for anything it doesn't
  recognise.
- **Rewriting under binders and large `simp` sets.** `simp` with many lemmas can produce long or
  unhelpful chains. For the book's proofs, which use a handful of defining equations each, this
  is unlikely to matter.

## Recommendation

1. Rewrite the Chapter 9 worked examples in the two-chain `calc` style (route 1), alongside the
   existing proofs. This gives book-style proofs straight away, and serves as the test data for
   route 2.
2. Turn the prototype into stages 1–3 of the renderer, with plain-text and Markdown output, and
   check its output for the Chapter 9 and Chapter 11 `rw` and `simp` proofs against the book.
3. Decide on the final output (LaTeX, website, or infoview panel) once that is working; Verso is
   the natural choice if the proofs are to appear interactively on the website.
