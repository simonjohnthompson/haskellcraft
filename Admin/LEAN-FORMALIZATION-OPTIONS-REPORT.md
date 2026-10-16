# Options for formalizing the book's proofs in Lean

Prepared in response to a request to investigate how the book's treatment of reasoning about
Haskell programs -- Chapter 9, "Reasoning about programs", and the "Proof revisited" section of
Chapter 17, "Lazy programming" -- could be formalized in Lean, bearing in mind that Haskell types
contain `undefined` and infinite values that Lean's own types do not. No files have been changed
to produce this report; it records the investigation and the options it surfaced, for review
before any formalization work is started.

## What the book already does

The book is already more careful about this than a first glance suggests, which matters for
scoping the Lean work.

**Chapter 9** introduces the issue directly, in "Definedness, termination and finiteness"
(`Book/9.tex`): evaluating a Haskell expression can fail to terminate, giving the **undefined**
value, and lazy evaluation means the list types also contain **partial** lists (e.g. `2:3:undef`)
and **infinite** lists. The chapter's response is a standing convention, stated explicitly: proofs
in Chapters 9-16 are proofs about **defined, finite values**, and that restriction "does not cause
problems in practice, since the defined cases will be exactly those which interest us the vast
majority of the time." Every induction in those chapters is ordinary structural/mathematical
induction over finite lists and natural numbers, with no domain theory needed to state or follow
it.

**Chapter 17's "Proof revisited"** is where the book picks the restriction back up and partly lifts
it, for lists specifically:

- **fp-list induction**: to prove `P(xs)` for all finite-or-partial lists, prove `P([])` **and**
  `P(undef)` (two base cases, not one), then the usual inductive step `P(x:xs)` assuming `P(xs)`.
  A worked example shows `reverse (xs ++ ys) = reverse ys ++ reverse xs` holds for finite lists but
  **fails** once `undef` is allowed, with a concrete counterexample -- the book is explicit that
  lifting a finite-list result to fp-lists is a real proof obligation, not a formality.
- **Infinite-list equality via approximants**: two lists are equal if all their finite
  approximants agree, i.e. `take n xs = take n ys` for every `n` -- the classical "take lemma".
  A full worked proof (`facMap!!n = facs!!n` for two different definitions of the infinite list of
  factorials) is carried out by ordinary mathematical induction on `n`, using this principle.
- The section cites Paulson's *Logic and Computation* (Cambridge LCF) and the book's own author's
  1999 survey chapter "Proof" (in *Research Directions in Parallel Functional Programming*) as
  further reading -- i.e. the book already points at the domain-theoretic literature this question
  is really asking about, it just doesn't name it as such for an undergraduate audience.

So the book's own structure already separates "ordinary, needs nothing special" (Ch 9-16) from
"genuinely needs domain-theoretic care" (Ch 17's fp-lists and infinite lists) -- and that split maps
almost directly onto where Lean's native types are adequate versus where they are not.

## The core translation issue

Lean's built-in types don't have the feature that makes this hard in Haskell. A Lean `Nat` is
always a genuine natural number; a Lean `List α` is always finite and, once its elements are
total, fully defined. Neither has anything playing the role of Haskell's `undef :: a`, and there is
no infinite `List α` -- `List` is an ordinary (strictly positive) inductive type, not a lazy,
possibly-infinite structure.

The consequence cuts both ways:

- **For Chapters 9-16's results, this is good news, not a problem.** A theorem like
  `sum (doubleAll xs) = 2 * sum xs` stated in Lean over `xs : List Int` is automatically a theorem
  about *defined, finite* lists, because that's the only kind of `List Int` Lean has. That is
  exactly the scope the book already restricts itself to for these results. No restatement is
  needed beyond saying so once, up front: translating "for all defined, finite `xs`" into "for all
  `xs : List Int`" is not a weakening, it's making the book's own stated restriction precise rather
  than informal.
- **For Chapter 17's fp-lists and infinite lists, this is the real gap.** `list1 = 2:3:undef` and
  the infinite `facs = 1 : zipWith (*) [1 ..] facs` have no Lean `List α` counterpart at all. A
  type that can actually represent "possibly partial, possibly infinite" is needed before any of
  that section's results can even be *stated* in Lean, let alone proved.

## Lean mechanisms for the Chapter 17 material

Investigated in decreasing order of fit for this specific job.

### `Mathlib.Data.Seq.WSeq` and `Mathlib.Data.Seq.Computation` -- the strongest match

- `Computation α` is Mathlib's coinductive type of "unbounded computations": internally a
  `Stream' (Option α)` that, once it produces `some a`, stays `some a` forever. `Computation.empty`
  (never produces a value) is a direct analogue of the book's `undef`. Equality between
  computations is established via `eq_of_bisim`/`IsBisimulation`.
- `WSeq α` is defined as `Seq (Option α)` -- a "weak sequence". Mathlib's own documentation
  describes this type as the right model for **"Haskell style lazy lists"**: a `none` entry
  represents an unresolved or still-computing position, playing structurally the same role as the
  book's device of writing a partial list's unknown tail as `undef`.
- Equality on `WSeq` is `Equiv` (notation `~ʷ`), defined via `LiftRel (· = ·)`, itself a
  **coinductively defined** relation: two weak sequences are equivalent iff both are empty, or
  their heads agree and their tails are (coinductively) equivalent. That is a formal,
  machine-checked version of the book's own principle that "two lists are equal if all their
  approximants are equal" -- not an analogy chosen for this report, the same idea, stated
  coinductively instead of via an explicit `take n` quantification.
- `WSeq.take s n` gives finite approximants directly, the same role as the book's `take n xs`.
  `IsFinite` and `Productive` are typeclasses distinguishing "finitely many elements", "infinitely
  many but every position eventually resolves" and (by their absence) genuinely partial sequences
  -- matching the book's finite/fp-list/infinite three-way split.
- This is mainline, actively maintained Mathlib, not a fringe or experimental package -- the only
  option below with that property.

### `Mathlib.Order.OmegaCompletePartialOrder` + `Mathlib.Control.LawfulFix`

General $\omega$-complete-partial-order theory: suprema of increasing chains, Scott-continuous
functions, and a `LawfulFix` least-fixed-point operator satisfying `fix f = f (fix f)` for
continuous `f`. Mathlib's own docs describe this machinery as being "useful for the formalization
of the semantics of programming languages" and for defining "the meaning of recursive procedures"
-- it is the Lean analogue of HOLCF's domain-theoretic core (see below). Its role here is
different from `WSeq`'s: it would justify *why* a recursive definition like
`facs = 1 : zipWith (*) [1 ..] facs` denotes a well-defined value at all (as a least fixed point),
rather than describing the structure or equality of the resulting values. Complementary to `WSeq`,
not a substitute for it, and not needed for most individual proofs -- useful for one short "why
this definition is legitimate" aside, not for everyday use.

### `Part α` (`Mathlib.Data.Part`)

A single value's partiality: a proposition `Dom` (does it have a value?) together with a getter
`Dom → α`. This is the right primitive for "this one computation might not terminate" -- closer to
`undef` at a single type than to the book's broader claim that *every* type has an `undef`. Useful
as a building block (and it is, internally, part of how `Computation`/`WSeq` are built), but it
does not by itself give every type a bottom element the way HOLCF's lifted/pointed types do.

### The standalone `domain-theory` Lean package

A new, independent Lean library ([reservoir.lean-lang.org/@zilberstein/domain-theory]) following
Abramsky and Jung's classical domain theory textbook more closely than Mathlib's pragmatic
`OmegaCompletePartialOrder` shortcut does -- notably, it doesn't require suprema of *arbitrary*
sets (only directed ones) or a bottom element, both of which Mathlib's `CompletePartialOrder`
does require. That is a theoretically cleaner fit for genuine domain theory, but the package is at
v0.1.0, first released August 2026, with limited adoption so far. Worth a watching brief, not a
dependency to build teaching material on today.

## Prior art worth citing directly

- **HOLCF (Isabelle)**, and specifically Brian Huffman's 2012 thesis *"HOLCF '11: A Definitional
  Domain Theory for Verifying Functional Programs"*, is the actual precedent for this exact
  problem: full domain theory (fixpoint reasoning, recursive domain equations) plus coinductive
  reasoning about lazy datatypes, built specifically to verify functional (Haskell-like) programs
  in a theorem prover. It is also the direct intellectual descendant of Paulson's *Logic and
  Computation*, already cited in Chapter 17. Worth one sentence in any formalized material noting
  that this problem has a fully rigorous solution already, just not in Lean -- it calibrates how
  much machinery a *maximally* faithful treatment needs, against which the `WSeq`-based approach
  above is a deliberate, lighter-weight simplification.
- **hs-to-coq** (Breitner et al., *"Ready, Set, Verify! Applying hs-to-coq to real-world Haskell
  code"*) takes the opposite philosophy: rather than modelling partiality rigorously, it translates
  a largely-total fragment of real Haskell source to Coq directly, and treats genuine partiality
  (`error`, non-structural recursion) as an axiomatized, explicitly out-of-scope edge, verified
  only where surrounding invariants rule it out in practice. This is a much closer match to how
  Chapters 9-16 of the book already work than a from-scratch domain-theory project would be, and is
  the realistic model for "how much of the book's *existing* proof content needs zero special
  machinery" (see Tier 1 below).

## Recommendation: a tiered approach

1. **Tier 1 -- Chapters 9-16, as ordinary total Lean theorems.** Translate a representative sample
   of these proofs (structural induction over `List`/`Nat`, the equational-reasoning style proofs,
   the generalization examples) directly, stated over Lean's native `List α`/`Nat`. This needs no
   special library, follows the book's existing restriction to defined, finite values exactly, and
   gives the most direct evidence for whether this formalization project is worth continuing before
   any of the harder Chapter 17 material is attempted. Lowest cost, immediate payoff.
2. **Tier 2 -- a pilot from Chapter 17's "Proof revisited".** The `facMap!!n = facs!!n` proof is a
   strong single candidate: self-contained, already a complete worked proof in the book, and a
   direct fit for `WSeq`/`Computation`'s `Equiv`/bisimulation machinery and `take`. Formalizing it
   would be a genuine, checkable demonstration that the book's informal take-lemma argument
   corresponds to an actual Lean coinductive bisimulation proof -- interesting in its own right, and
   arguably a natural extension of the "Proof in functional programming" survey already cited in
   that chapter. The `reverse++` counterexample (showing a finite-list result that provably fails
   to lift to fp-lists) would make a good second pilot, since a *failure* proof exercises
   `WSeq`/fp-list induction slightly differently than an equality proof does.
3. **Tier 3 -- optional.** A short note using `OmegaCompletePartialOrder`/`LawfulFix` to justify
   that `facs`'s self-referential definition denotes a well-defined value in the first place --
   worth having once Tier 2 exists, not before.
4. **Explicitly not recommended right now**: a full, automatic, hs-to-coq-style translation of
   actual book `.tex`/Haskell source into Lean, and building anything on the standalone
   `domain-theory` package. Both are real projects in their own right, disproportionate to what a
   textbook formalization needs, and (for the package) resting on something too new to be a stable
   foundation yet.

## Open questions before starting

1. **Deliverable**: is this formalization work meant to produce a standalone research/demonstration
   artifact (e.g. a `Lean/` directory with a handful of worked proofs and a short write-up), or is
   it meant to eventually become book content itself (an appendix, or references alongside the
   existing exercises)? The two have different bars for polish and exposition.
2. **Scope of the pilot**: Tier 2 above proposes `facMap!!n = facs!!n` (and optionally `reverse++`)
   as the first genuinely domain-theoretic proof to attempt. Confirm that's the right starting
   point, or substitute a different Chapter 17 result if another one matters more.
3. **Lean/Mathlib version pinning**: Mathlib moves quickly and the `WSeq`/`Computation` API seen
   during this investigation is current as of this report's date; any actual Lean project should
   pin a specific Mathlib commit/release rather than tracking latest, the same way `Worker/package.json`
   pins `wrangler` rather than floating it.

## Recommendation

Proceed with Tier 1 first, as a low-cost way to confirm the overall approach is worth continuing,
then Tier 2 as the project's actual interesting content -- a small number of fully worked Chapter 17
proofs using `Mathlib.Data.Seq.WSeq`, which turns out to be a closer structural match to this
book's own fp-list/approximant apparatus than any other option investigated, without requiring the
much heavier, less mature alternatives (a from-scratch domain theory development, or a full
HOLCF-style system) that a maximally rigorous treatment would otherwise call for.
