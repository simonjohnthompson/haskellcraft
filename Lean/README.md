# Lean formalizations of the book's proofs

Lean 4 formalizations of the "proof"/"reasoning" results in
*Haskell: the Craft of Functional Programming*, following the tiered
plan in [`Admin/LEAN-FORMALIZATION-OPTIONS-REPORT.md`](../Admin/LEAN-FORMALIZATION-OPTIONS-REPORT.md).

Each book chapter gets its own file under `HaskellCraft/`, redefining
just enough of the relevant Haskell functions from scratch (rather than
reusing Lean/Mathlib's own `List.sum`, `++`, etc.) so that the proofs
track the book's defining equations and `(base)`/`(ind)`/`(hyp)`
structure step for step.

- `HaskellCraft/Chapter9.lean` -- the worked list-induction proofs from
  Chapter 9 (`sum`/`doubleAll`, `length`/`++`, `reverse`/`++`, and the
  `shunt`/`rev` "generalizing the proof goal" example).
- `HaskellCraft/AdditionalChapter9.lean` -- further Chapter 9 proofs:
  associativity of `||`, `elem` and `++` (using `BEq`/`LawfulBEq`),
  arithmetic on `Nat`, and `zip`/`unzip`.
- `HaskellCraft/Chapter11.lean` -- the "Verification and general
  functions" section of Chapter 11: extensionality via `funext`
  (`f . id = f`, `iter 2 f = twice f`), `map`/composition, filter
  promotion, and `map`/`reverse` with the `Picture` corollary, all
  complete, together with the exercise (map++), which `map`/`reverse`
  uses.
- `HaskellCraft/AdditionalChapter11.lean` -- the rest of that section's
  exercises, all proved: composition, `flip`, `curry`/`uncurry`, `iter`,
  idempotence, and `foldr`/`++`, including a general form of (foldr.3)
  for any `f : α → β → β`, from which the book's version follows.
- `HaskellCraft/Chapter14.lean` -- the "Reasoning about algebraic types"
  section of Chapter 14: (map-collapse) for trees, proof by cases for
  `Maybe`, and (eval-assoc), where `assoc` needs a termination proof and
  the induction follows its recursion (`assoc.induct`).
- `HaskellCraft/AdditionalChapter14.lean` -- that section's exercises,
  all proved: `weather`, non-negative areas of shapes (over any ordered
  field, with π as a parameter, in place of the book's `Float`), `size`,
  `depth` and `occurs` for trees of integers, `twist`, and
  (map-collapse) for general trees by mutual induction.
- `HaskellCraft/Chapter17.lean` -- the finite and partial lists
  (fp-lists) of Chapter 17's "Proof revisited": a list type with an
  `undef` constructor, whose induction principle has the book's two
  base cases; (sum-double) and `map f . map g = map (f . g)` for all
  fp-lists, and the counterexample showing (reverse++) does not hold for
  them.
- `HaskellCraft/AdditionalChapter17.lean` -- that section's fp-list
  exercises, all proved: associativity of `++`, `rev` via `shunt`,
  indexing with `map` and `zipWith`, and the equations between
  functions for `filter`, `map` and `concat`.
- `HaskellCraft/Streams.lean` -- the infinite lists of the same section,
  as a stream type used only through `head`, `tail`, corecursion and
  coinduction (bisimulation). The two factorial lists are proved equal
  both by the book's induction on indices and by coinduction.
- `HaskellCraft/AdditionalStreams.lean` -- the section's infinite-list
  exercises, on indexing and on equations proved by coinduction, stated
  with `sorry`. Only the stream interface is visible here.

## Building

Requires [elan](https://github.com/leanprover/elan) (`brew install elan-init`,
or see the official install instructions); `lean-toolchain` pins the
Lean version, so the first `lake build` will fetch it automatically.

```sh
cd Lean
lake build
```
