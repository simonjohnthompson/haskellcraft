/-
Chapter 11 ("Higher-order functions"), section "Verification and general
functions", re-done in Lean.

As in Chapter9.lean, the functions involved are redefined from scratch
(composition, `id`, `map`, `filter`, `foldr`, ...) rather than reusing
Lean's `∘`, `List.map` and so on, so that the proofs use exactly the
defining equations the book cites. `+++`, `myReverse`, `mySum` and the
Chapter 9 lemmas about them are reused from Chapter9.lean.

The worked proofs from the text are given in full. The section's
exercises are stated, with `sorry` in place of a proof, to be filled in.

Two things are new compared with Chapter 9:
- Equality between functions: the book's principle of extensionality is
  Lean's `funext`, so the tactic `funext x` turns a goal `f = g` into
  `f x = g x` for an arbitrary `x`.
- The book proves its list results "for all finite lists", and defers
  the general functional equations (e.g. `map (f . g) = map f . map g`)
  to Chapter 17. Every Lean `List` is finite, so here the functional
  equations follow at once from the list results, by `funext`.
-/

import HaskellCraft.Chapter9

open Chapter9

namespace Chapter11

-- ---------------------------------------------------------------------
-- Composition, `id`, `twice` and `iter`
-- ---------------------------------------------------------------------

def myId (x : α) : α := x

def comp (f : β → γ) (g : α → β) : α → γ :=
  fun x => f (g x)                         -- (comp.1)

infixr:90 " ∘' " => comp

def twice (f : α → α) : α → α := f ∘' f    -- (twice.1)

/-- The book's `iter` is over `Integer`, with guards `n > 0` and
`otherwise`. Over `Nat` those two cases are exactly the patterns `n + 1`
and `0`. -/
def iter : Nat → (α → α) → (α → α)
  | 0,     _ => myId                       -- (iter.2)
  | n + 1, f => f ∘' iter n f              -- (iter.1)

-- ---------------------------------------------------------------------
-- Function-level verification (book: "Function-level verification")
-- ---------------------------------------------------------------------

/-- (compId): `f . id = f`, the book's first use of extensionality.
`funext x` reduces it to `(f . id) x = f x`, which is the book's own
two-step calculation. -/
theorem comp_id (f : α → β) : f ∘' myId = f := by
  funext x
  simp [comp, myId]

/-- `iter 2 f = twice f`, unfolding `iter` twice and then using (compId),
step for step as in the book. -/
theorem iter_two (f : α → α) : iter 2 f = twice f := by
  simp [iter, twice, comp_id]

-- Exercises

/-- Composition is associative. -/
theorem comp_assoc (f : γ → δ) (g : β → γ) (h : α → β) :
    f ∘' (g ∘' h) = (f ∘' g) ∘' h := by
  sorry

theorem id_comp (f : α → β) : myId ∘' f = f := by
  sorry

def myFlip (f : α → β → γ) : β → α → γ :=
  fun x y => f y x

/-- The book's hint: prove this first ... -/
theorem flip_flip (f : α → β → γ) : myFlip (myFlip f) = f := by
  sorry

/-- ... then this, using `flip_flip`. -/
theorem flip_comp_flip :
    (myFlip ∘' myFlip : (α → β → γ) → (α → β → γ)) = myId := by
  sorry

def myCurry (g : α × β → γ) : α → β → γ :=
  fun x y => g (x, y)

def myUncurry (f : α → β → γ) : α × β → γ
  | (x, y) => f x y

/-- `curry` and `uncurry` are inverses: one direction ... -/
theorem curry_uncurry :
    (myCurry ∘' myUncurry : (α → β → γ) → (α → β → γ)) = myId := by
  sorry

/-- ... and the other. -/
theorem uncurry_curry :
    (myUncurry ∘' myCurry : (α × β → γ) → (α × β → γ)) = myId := by
  sorry

/-- By induction on `n`. -/
theorem iter_id (n : Nat) : iter n (myId : α → α) = myId := by
  sorry

def myAbs (x : Int) : Int := if x ≥ 0 then x else -x

def mySignum (x : Int) : Int :=
  if x > 0 then 1 else if x = 0 then 0 else -1

/-- `abs` is idempotent. -/
theorem abs_idempotent : myAbs ∘' myAbs = myAbs := by
  sorry

/-- `signum` is idempotent. -/
theorem signum_idempotent : mySignum ∘' mySignum = mySignum := by
  sorry

-- ---------------------------------------------------------------------
-- `map`, `filter` and `foldr`
-- ---------------------------------------------------------------------

def myMap (f : α → β) : List α → List β
  | []      => []                          -- (map.1)
  | x :: xs => f x :: myMap f xs           -- (map.2)

def myFilter (p : α → Bool) : List α → List α
  | []      => []                          -- (filter.1)
  | x :: xs =>
      if p x then x :: myFilter p xs       -- (filter.2)
      else myFilter p xs                   -- (filter.3)

def myFoldr (f : α → β → β) (st : β) : List α → β
  | []      => st                          -- (foldr.1)
  | x :: xs => f x (myFoldr f st xs)       -- (foldr.2)

-- ---------------------------------------------------------------------
-- `map` and composition (book: "map and composition")
-- ---------------------------------------------------------------------

/-- (map.3): `map (f . g) xs = (map f . map g) xs`. The induction
hypothesis `hyp` is exactly what the book's (ind) step needs. -/
theorem map_comp (f : β → γ) (g : α → β) (xs : List α) :
    myMap (f ∘' g) xs = (myMap f ∘' myMap g) xs := by
  induction xs with
  | nil => simp [myMap, comp]
  | cons x xs hyp =>
      simp only [comp] at hyp
      simp [myMap, comp, hyp]

/-- The functional equation `map (f . g) = map f . map g`, which the book
defers to Chapter 17; here it is (map.3) plus extensionality. -/
theorem map_comp_fun (f : β → γ) (g : α → β) :
    myMap (f ∘' g) = myMap f ∘' myMap g := by
  funext xs
  exact map_comp f g xs

-- ---------------------------------------------------------------------
-- `map` and `filter` (book: "map and filter", filter promotion)
-- ---------------------------------------------------------------------

/-- (filter/map): `(filter p . map f) xs = (map f . filter (p . f)) xs`.
The induction step splits into the two cases the book considers, on
whether `p (f x)` is `true` or `false`: `cases h : p (f x)` does the
split and records which case we're in as `h`. -/
theorem filter_map (p : β → Bool) (f : α → β) (xs : List α) :
    (myFilter p ∘' myMap f) xs = (myMap f ∘' myFilter (p ∘' f)) xs := by
  induction xs with
  | nil => simp [myMap, myFilter, comp]
  | cons x xs hyp =>
      simp only [comp] at hyp
      cases h : p (f x) with
      | true  => simp [myMap, myFilter, comp, h, hyp]
      | false => simp [myMap, myFilter, comp, h, hyp]

-- ---------------------------------------------------------------------
-- `map`, `reverse` and the `Picture` case study
-- ---------------------------------------------------------------------

/-- (map++): left as an exercise in the book, and used in `map_reverse`
below. -/
theorem map_append (f : α → β) (ys zs : List α) :
    myMap f (ys +++ zs) = myMap f ys +++ myMap f zs := by
  sorry

/-- (map/reverse): `map f (reverse xs) = reverse (map f xs)`, using
(map++) in the induction step. Lean only warns about a `sorry` used
directly, so this compiles silently even before `map_append` is proved;
`#print axioms map_reverse` shows whether it still depends on `sorryAx`. -/
theorem map_reverse (f : α → β) (xs : List α) :
    myMap f (myReverse xs) = myReverse (myMap f xs) := by
  induction xs with
  | nil => simp [myMap, myReverse]
  | cons x xs hyp => simp [myMap, myReverse, map_append, hyp]

def flipH : List (List α) → List (List α) := myReverse

def flipV : List (List α) → List (List α) := myMap myReverse

/-- `flipV (flipH xs) = flipH (flipV xs)`: (map/reverse) with `f`
replaced by `reverse`. -/
theorem flipV_flipH (xs : List (List α)) :
    flipV (flipH xs) = flipH (flipV xs) := by
  simp [flipV, flipH, map_reverse]

/-- The functional equation `flipV . flipH = flipH . flipV`, again by
extensionality. -/
theorem flipV_comp_flipH :
    (flipV ∘' flipH : List (List α) → List (List α)) = flipH ∘' flipV := by
  funext xs
  exact flipV_flipH xs

-- ---------------------------------------------------------------------
-- Exercises: `foldr` and `++` (book: "Libraries of theorems")
-- ---------------------------------------------------------------------

/-- (foldr.3): if `f` is associative and `st` is an identity for `f`,
then `foldr f st (xs ++ ys) = f (foldr f st xs) (foldr f st ys)`. The
book's two side conditions become hypotheses of the theorem. -/
theorem foldr_append (f : α → α → α) (st : α)
    (assoc : ∀ x y z, f x (f y z) = f (f x y) z)
    (idl : ∀ x, f st x = x) (idr : ∀ x, f x st = x)
    (xs ys : List α) :
    myFoldr f st (xs +++ ys) = f (myFoldr f st xs) (myFoldr f st ys) := by
  sorry

/-- (sum.3), as a special case of (foldr.3). Hint: first prove that
`mySum xs = myFoldr (· + ·) 0 xs`. -/
theorem sum_append (xs ys : List Int) :
    mySum (xs +++ ys) = mySum xs + mySum ys := by
  sorry

def myConcat (xss : List (List α)) : List α := myFoldr (· +++ ·) [] xss

/-- `concat (xs ++ ys) = concat xs ++ concat ys`, as a special case of
(foldr.3). The Chapter 9 lemmas `append_assoc` and `append_nil` give two
of its side conditions. -/
theorem concat_append (xss yss : List (List α)) :
    myConcat (xss +++ yss) = myConcat xss +++ myConcat yss := by
  sorry

end Chapter11
