/-
Chapter 17 ("Lazy programming"), section "Proof revisited", re-done in
Lean: the part on finite and partial lists (fp-lists). The part on
infinite lists, with the two factorial lists, is in Streams.lean.

Lean's `List α` has only finite, fully defined lists, so the fp-lists
need a type of their own. `PList α` adds a third constructor, `undef`,
for a list whose remainder is undefined, so that the book's
`2:3:undef` is `cons 2 (cons 3 undef)`. Lean then derives the book's
induction principle for fp-lists by itself: `induction xs` gives two
base cases, `nil` and `undef`, and the usual `cons` step.

The functions are the book's, with one more equation each, saying what
happens on `undef`. A function that pattern matches on a list gives an
undefined result on `undef`, so each `undef` equation is the book's
(f.u): `doubleAll undef = undef` and so on.

Two simplifications, both noted where they matter:
- The book also has undefined *elements*, as in `undef:[2,3]`. Here the
  elements of a `PList` are always defined. Undefined *results* are
  still needed, for `sum undef :: Integer`: an `Int` that may be
  undefined is an `Option Int`, with `none` for undefined.
- `PList` is a new type, so `+++`, `myMap` and the rest are redefined
  for it, as `app`, `pmap` and so on. `∘'` is still Chapter 11's.

The section's exercises are in AdditionalChapter17.lean.
-/

import HaskellCraft.Chapter11

open Chapter11

namespace Chapter17

/-- Finite and partial lists. -/
inductive PList (α : Type) where
  | nil   : PList α
  | undef : PList α
  | cons  : α → PList α → PList α

open PList

/-- `[x]`. -/
def single (x : α) : PList α := cons x nil

-- ---------------------------------------------------------------------
-- `sum` and `doubleAll` (book: "List induction revisited")
-- ---------------------------------------------------------------------

/-- `sum`, with a possibly undefined result: `none` is the undefined
integer. Addition is strict, so if the sum of the tail is undefined,
so is the whole sum. -/
def psum : PList Int → Option Int
  | nil       => some 0                   -- (sum.1)
  | undef     => none                     -- (sum.u)
  | cons x xs => (x + ·) <$> psum xs      -- (sum.2)

def doubleAll : PList Int → PList Int
  | nil       => nil                      -- (doubleAll.1)
  | undef     => undef                    -- (doubleAll.u)
  | cons z zs => cons (2 * z) (doubleAll zs) -- (doubleAll.2)

/-- (sum-double) for all fp-lists. `2 * sum xs` is
`(2 * ·) <$> psum xs`, since multiplication is strict too. `<$>` is
Haskell's `fmap` on `Maybe`, Lean's `Option.map`.

The `undef` case is the book's (sum-double.u): both sides are undefined,
by (sum.u) and (doubleAll.u). The `cons` case is Chapter 9's induction
step, under `<$>`. -/
theorem sum_doubleAll (xs : PList Int) :
    psum (doubleAll xs) = (2 * ·) <$> psum xs := by
  induction xs with
  | nil => simp [psum, doubleAll]
  | undef => simp [psum, doubleAll]
  | cons x xs hyp =>
      simp only [psum, doubleAll, hyp, Functor.map_map]
      congr 1
      funext y
      omega

-- ---------------------------------------------------------------------
-- `++` and `reverse` (book: "List induction revisited")
-- ---------------------------------------------------------------------

/-- `++`. It pattern matches on its first argument, so
`undef ++ ys = undef`, whatever `ys` is. -/
def app : PList α → PList α → PList α
  | nil,       ys => ys                   -- (++.1)
  | undef,     _  => undef                -- (++.u)
  | cons x xs, ys => cons x (app xs ys)   -- (++.2)

def rev : PList α → PList α
  | nil       => nil                      -- (reverse.1)
  | undef     => undef                    -- (reverse.u)
  | cons x xs => app (rev xs) (single x)  -- (reverse.2)

/-- The book's calculation of the left-hand side of (reverse++.u), with
`ys = [2,3]`. -/
example : rev (app undef (cons 2 (cons 3 nil))) = undef := by
  simp [app, rev]

/-- ... and of the right-hand side, which is the partial list
`[3,2] ++ undef`, that is `3:2:undef`. -/
example : app (rev (cons 2 (cons 3 nil))) (rev undef) =
    cons 3 (cons 2 undef) := by
  simp [app, rev, single]

/-- (reverse++) does not hold for all fp-lists: the two calculations
above give different results. `simp` finishes, because `undef` and
`cons 3 ...` are different constructors. -/
theorem reverse_append_fails :
    ¬ ∀ xs ys : PList Int, rev (app xs ys) = app (rev ys) (rev xs) := by
  intro h
  have := h undef (cons 2 (cons 3 nil))
  simp [app, rev, single] at this

-- ---------------------------------------------------------------------
-- `map` (book: "Proofs for infinite lists")
-- ---------------------------------------------------------------------

def pmap (f : α → β) : PList α → PList β
  | nil       => nil                      -- (map.1)
  | undef     => undef                    -- (map.u)
  | cons x xs => cons (f x) (pmap f xs)   -- (map.2)

/-- (map.3) for all fp-lists: the proof of Chapter 11's `map_comp`, with
an `undef` base case that holds by (map.u). -/
theorem map_comp (f : β → γ) (g : α → β) (xs : PList α) :
    (pmap f ∘' pmap g) xs = pmap (f ∘' g) xs := by
  induction xs with
  | nil => simp [pmap, comp]
  | undef => simp [pmap, comp]
  | cons x xs hyp =>
      simp only [comp] at hyp
      simp [pmap, comp, hyp]

/-- `map f . map g = map (f . g)`, by extensionality. The book goes on to
infer this for infinite lists too, from their approximations; with
`PList` it is a result about fp-lists only. -/
theorem map_comp_fun (f : β → γ) (g : α → β) :
    pmap f ∘' pmap g = pmap (f ∘' g) := by
  funext xs
  exact map_comp f g xs
end Chapter17
