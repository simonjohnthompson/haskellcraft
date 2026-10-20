/-
Exercises from Chapter 11's "Verification and general functions"
section, stated with `sorry` in place of a proof, to be filled in.

The definitions they use (`comp` and `∘'`, `myId`, `iter`, `myFoldr`,
...) are in Chapter11.lean, and `+++`, `mySum`, `append_assoc` and
`append_nil` are in Chapter9.lean. The one remaining exercise, (map++),
is in Chapter11.lean as `map_append`, because the worked proof of
(map/reverse) there uses it.
-/

import HaskellCraft.Chapter11

open Chapter9 Chapter11

namespace AdditionalChapter11

-- ---------------------------------------------------------------------
-- Function-level verification
-- ---------------------------------------------------------------------

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
-- `foldr` and `++` (book: "Libraries of theorems")
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

end AdditionalChapter11
