/-
Exercises from Chapter 17's "Proof revisited" section, with their
proofs: the ones about fp-lists. The ones about infinite lists are in
Streams.lean.

`PList`, `app`, `rev`, `pmap` and `single` are in Chapter17.lean, and
`∘'` is in Chapter11.lean. The functions that only these exercises use
are defined here, each with its `undef` equation. Every proof is by
induction with the two base cases `nil` and `undef`.
-/

import HaskellCraft.Chapter17

open Chapter11 Chapter17 PList

namespace AdditionalChapter17

-- ---------------------------------------------------------------------
-- `++` is associative over all lists
-- ---------------------------------------------------------------------

/-- (assoc++.u), the new base case. -/
theorem app_assoc_undef (ys zs : PList α) :
    app undef (app ys zs) = app (app undef ys) zs := by
  simp [app]

/-- (assoc++) for all fp-lists. -/
theorem app_assoc (xs ys zs : PList α) :
    app xs (app ys zs) = app (app xs ys) zs := by
  induction xs with
  | nil => simp [app]
  | undef => simp [app_assoc_undef]
  | cons x xs hyp =>
    simp [app,hyp]


-- ---------------------------------------------------------------------
-- `rev` via `shunt` (book: Chapter 9, "Generalizing the proof goal")
-- ---------------------------------------------------------------------

def shunt : PList α → PList α → PList α
  | nil,       ys => ys
  | undef,     _  => undef
  | cons x xs, ys => shunt xs (cons x ys)

def rev' (xs : PList α) : PList α := shunt xs nil

/-- (rev-rev.1). -/
theorem rev_rev_undef : rev' (rev' (undef : PList α)) = undef := by
  simp [rev',shunt]

/- The book asks why (rev-rev.1) and Chapter 9's (rev-rev.2), for finite
lists, don't give `rev (rev xs) = xs` for all fp-lists. One way to
answer is to find an fp-list for which it fails. -/

theorem rev_rev_fails : ¬ ∀ xs : PList Nat, rev' (rev' xs) = xs := by
  intro hyp
  have cex := hyp (cons 1 undef)
  simp [rev',shunt] at cex

-- ---------------------------------------------------------------------
-- Indexing, `map` and `zipWith`
-- ---------------------------------------------------------------------

/-- `xs!!n`. Indexing past the end is an error, and indexing into
`undef` is undefined; both are `none`. -/
def index : PList α → Nat → Option α
  | nil,       _     => none
  | undef,     _     => none
  | cons x _,  0     => some x
  | cons _ xs, n + 1 => index xs n

/-- (map.!!) for all fp-lists. The book asks for `f` to be strict; here
the elements are always defined, so any `f` will do. Hint: the induction
hypothesis is needed at `n - 1`, so make `n` arbitrary in it with
`induction xs generalizing n`, then split on `n` with `cases n`. -/
theorem map_index (f : α → β) (xs : PList α) (n : Nat) :
    index (pmap f xs) n = f <$> index xs n := by
   induction xs generalizing n with
    | undef => simp [index,pmap]
    | nil => simp [index,pmap]
    | cons x xs hyp =>
       cases n with
       | zero => simp [index,pmap]
       | succ n => simp [index,pmap,hyp n]

/-- `zipWith`. Pattern matching on the first list, then on the second,
so `undef` in either place, once reached, gives `undef`. -/
def zipW (g : α → β → γ) : PList α → PList β → PList γ
  | undef,     _         => undef
  | cons _ _,  undef     => undef
  | cons x xs, cons y ys => cons (g x y) (zipW g xs ys)
  | _,         _         => nil

/-- (zipWith.!!) for all fp-lists: the result is defined only when both
`xs!!n` and `ys!!n` are. Hint: as for `map_index`, but generalize `ys`
too, and in the `cons` case split on `ys` as well as `n`. -/
theorem zipWith_index (g : α → β → γ) (xs : PList α) (ys : PList β)
    (n : Nat) :
    index (zipW g xs ys) n =
      (index xs n >>= fun x => g x <$> index ys n) := by
  induction xs generalizing ys n with
  | undef => simp [zipW, index]
  | nil   => cases ys <;> simp [zipW, index]
  | cons x xs hyp =>
    cases ys with
    | undef     => cases n <;> simp [zipW, index]
    | nil       => cases n <;> simp [zipW, index]
    | cons y ys => cases n <;> simp [zipW, index, hyp]

-- ---------------------------------------------------------------------
-- Equations between functions
-- ---------------------------------------------------------------------

def pfilter (p : α → Bool) : PList α → PList α
  | nil       => nil
  | undef     => undef
  | cons x xs => if p x then cons x (pfilter p xs) else pfilter p xs

/-- The book's `&&&`. -/
def andP (q p : α → Bool) : α → Bool := fun x => q x && p x

infixl:35 " &&& " => andP

/-- Filter promotion, for all fp-lists. -/
theorem filter_map (p : β → Bool) (f : α → β) :
    pfilter p ∘' pmap f = pmap f ∘' pfilter (p ∘' f) := by
  funext xs
  induction xs with
  | undef => simp [pmap,pfilter,comp]
  | nil   => simp [pmap,pfilter,comp]
  | cons x xs hyp =>
    simp [comp] at hyp
    simp [pmap,pfilter,comp]
    by_cases test : p (f x)
    · simp [test,pmap,hyp]
    · simp [test,hyp]

theorem filter_filter (p q : α → Bool) :
    pfilter p ∘' pfilter q = pfilter (q &&& p) := by
  funext xs
  induction xs with
  | undef => simp [pfilter, comp]
  | nil   => simp [pfilter, comp]
  | cons x xs hyp =>
    simp [comp] at hyp
    by_cases hq : q x <;> by_cases hp : p x <;>
      simp [pfilter, comp, andP, hq, hp, hyp]

def pconcat : PList (PList α) → PList α
  | nil         => nil
  | undef       => undef
  | cons xs xss => app xs (pconcat xss)

/-- (map++) for fp-lists, needed for `concat_map`. -/
theorem map_app (f : α → β) (xs ys : PList α) :
    pmap f (app xs ys) = app (pmap f xs) (pmap f ys) := by
  induction xs with
  | undef => simp [pmap, app]
  | nil => simp [pmap, app]
  | cons w ws hyp => simp [pmap, app,hyp]

theorem concat_map (f : α → β) :
    pconcat ∘' pmap (pmap f) = pmap f ∘' pconcat := by
   funext xs
   induction xs with
  | undef => simp [pmap, pconcat,comp]
  | nil => simp [pmap, pconcat,comp]
  | cons ws wss hyp =>
    simp [comp] at hyp
    simp [comp,pmap,pconcat,hyp,map_app]
end AdditionalChapter17
