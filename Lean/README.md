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
- `HaskellCraft/Chapter11.lean` -- the "Verification and general
  functions" section of Chapter 11: extensionality via `funext`
  (`f . id = f`, `iter 2 f = twice f`), `map`/composition, filter
  promotion, and `map`/`reverse` with the `Picture` corollary, all
  complete, together with the exercise (map++), which `map`/`reverse`
  uses.
- `HaskellCraft/AdditionalChapter11.lean` -- the rest of that section's
  exercises (composition, `flip`, `curry`/`uncurry`, `iter`,
  idempotence, and `foldr`/`++`), stated with `sorry` as their proofs.

## Building

Requires [elan](https://github.com/leanprover/elan) (`brew install elan-init`,
or see the official install instructions); `lean-toolchain` pins the
Lean version, so the first `lake build` will fetch it automatically.

```sh
cd Lean
lake build
```
