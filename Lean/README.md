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

## Building

Requires [elan](https://github.com/leanprover/elan) (`brew install elan-init`,
or see the official install instructions); `lean-toolchain` pins the
Lean version, so the first `lake build` will fetch it automatically.

```sh
cd Lean
lake build
```
