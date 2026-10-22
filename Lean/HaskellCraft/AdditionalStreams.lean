/-
Exercises on infinite lists from Chapter 17's "Proof revisited" section,
stated with `sorry` in place of a proof, to be filled in.

`Strm` and its functions are in Streams.lean, and `∘'` is in
Chapter11.lean. The representation of `Strm` is private to Streams.lean,
so only its interface can be used here: `head`, `tail`, `cons`, the
`@[simp]` equations for them, `nth`, `eq_of_bisim` and `Bisim.coinduct`.
-/

import HaskellCraft.Streams

open Chapter11 Streams

namespace AdditionalStreams

open Strm (nth upFrom eq_of_bisim Bisim cons_head_tail)

/-- `(map f [m ..])!!n = f (m+n)`. Streams.lean already has `nth_map`
and `nth_upFrom`, which make this one line; prove it without them, by
induction. The book's hint: choose the right variable for the induction,
and make the other one arbitrary in the hypothesis with `generalizing`. -/
theorem nth_map_upFrom (f : Nat → α) (m n : Nat) :
    nth (Strm.map f (upFrom m)) n = f (m + n) := by
  sorry

/- The book also asks you to prove that `facMap` and `facs` are infinite,
meaning that `take n xs ≠ take (n+1) xs` for every `n`. That exercise
has no counterpart here: a `Strm` has no `[]`, so every stream is
infinite, by its type. The two below replace it. -/

/-- The natural numbers, as the process-based definition
`nats = 0 : map (+1) nats` would give them. Prove this the way
Chapter17.lean proves `facs_eq`: show that the tails are equal by
coinduction, with the relation "`upFrom (k+1)` and `map (+1) [k ..]`,
for some `k`". -/
theorem nats_eq : upFrom 0 = Strm.cons 0 (Strm.map (· + 1) (upFrom 0)) := by
  sorry

/-- (map.3) for infinite lists, so `map f . map g = map (f . g)` holds
for streams too. By coinduction: relate `map f (map g u)` and
`map (f . g) u`, for any stream `u`. -/
theorem map_comp_strm (f : β → γ) (g : α → β) (s : Strm α) :
    Strm.map f (Strm.map g s) = Strm.map (f ∘' g) s := by
  sorry

end AdditionalStreams
