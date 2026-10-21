/-
Exercises from Chapter 11's "Verification and general functions"
section, with their proofs.

The definitions they use (`comp` and `∘'`, `myId`, `iter`, `myFoldr`,
...) are in Chapter11.lean, and `+++`, `mySum`, `append_assoc` and
`append_nil` are in Chapter9.lean. The section's other exercise, (map++),
is proved in Chapter11.lean as `map_append`, because the worked proof of
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
  funext x
  simp [comp]

theorem id_comp (f : α → β) : myId ∘' f = f := by
  funext x
  simp [comp,myId]

def myFlip (f : α → β → γ) : β → α → γ :=
  fun x y => f y x

/-- The book's hint: prove this first ... -/
theorem flip_flip (f : α → β → γ) : myFlip (myFlip f) = f := by
  funext x y
  simp [myFlip]

/-- ... then this, using `flip_flip`. -/
theorem flip_comp_flip :
    (myFlip ∘' myFlip : (α → β → γ) → (α → β → γ)) = myId := by
  funext x
  simp [comp,flip_flip,myId]

def myCurry (g : α × β → γ) : α → β → γ :=
  fun x y => g (x, y)

def myUncurry (f : α → β → γ) : α × β → γ
  | (x, y) => f x y

/-- `curry` and `uncurry` are inverses: one direction ... -/
theorem curry_uncurry :
    (myCurry ∘' myUncurry : (α → β → γ) → (α → β → γ)) = myId := by
   funext f x y
   simp [myCurry,myUncurry,comp,myId]

/-- ... and the other. -/
theorem uncurry_curry :
    (myUncurry ∘' myCurry : (α × β → γ) → (α × β → γ)) = myId := by
    funext f x
    simp [myCurry,myUncurry,comp,myId]

/-- By induction on `n`. -/
theorem iter_id (n : Nat) : iter n (myId : α → α) = myId := by
  funext x
  induction n with
  | zero => simp [iter,myId]
  | succ n hyp => simp [iter,myId,comp,hyp]

def myAbs (x : Int) : Int := if x ≥ 0 then x else -x

def mySignum (x : Int) : Int :=
  if x > 0 then 1 else if x = 0 then 0 else -1

/-- `abs` is non-negative. -/
theorem abs_pos (x:Int) : 0 <= myAbs x  := by
  simp [myAbs]
  by_cases h : (0 <= x) <;> omega

/-- `abs` is idempotent. -/
theorem abs_idempotent : myAbs ∘' myAbs = myAbs := by
  funext x
  simp [myAbs,comp]
  by_cases h : (0 <= x) <;> omega

/-- `signum` is idempotent. -/
theorem signum_idempotent : mySignum ∘' mySignum = mySignum := by
  funext x
  simp [mySignum,comp]
  by_cases h : (0 <= x) <;> omega


-- ---------------------------------------------------------------------
-- `foldr` and `++` (book: "Libraries of theorems")
-- ---------------------------------------------------------------------

/-- The general form of (foldr.3), for any `f : α → β → β`, with no side
conditions: folding over `xs ++ ys` is folding over `ys`, then using the
result as the starting value for folding over `xs`. -/
theorem foldr_append_gen (f : α → β → β) (st : β) (xs ys : List α) :
    myFoldr f st (xs +++ ys) = myFoldr f (myFoldr f st ys) xs := by
  induction xs with
  | nil => simp [myFoldr, myAppend]
  | cons x xs hyp => simp [myFoldr, myAppend, hyp]

/-- (foldr.3): if `f` is associative and `st` is an identity for `f`,
then `foldr f st (xs ++ ys) = f (foldr f st xs) (foldr f st ys)`. The
book's two side conditions become hypotheses of the theorem.
In fact idr : ∀ x, f x st = x not necessary for the proof, so removed.
Proved from `foldr_append_gen`: the side conditions are what let the
starting value `z` be moved out to the right, in `shift`. -/
theorem foldr_append (f : α → α → α) (st : α)
    (assoc : ∀ x y z, f x (f y z) = f (f x y) z)
    (idl : ∀ x, f st x = x)
    (xs ys : List α) :
    myFoldr f st (xs +++ ys) = f (myFoldr f st xs) (myFoldr f st ys) := by
  have shift : ∀ z, myFoldr f z xs = f (myFoldr f st xs) z := by
    intro z
    induction xs with
    | nil => simp [myFoldr, idl]
    | cons x xs hyp => simp [myFoldr, hyp, assoc]
  rw [foldr_append_gen, shift]

/-- (sum.3), as a special case of (foldr.3). Hint: first prove that
`mySum xs = myFoldr (· + ·) 0 xs`.
Note the explicit application of foldr_append to the particular proofs for Int.add
and the need to take the symmetric version of the equation to match the hypothesis.-/
theorem sum_append (xs ys : List Int) :
    mySum (xs +++ ys) = mySum xs + mySum ys := by
    have lemma : ∀ zs : List Int, mySum zs = myFoldr (· + ·) 0 zs := by
      intro zs
      induction zs with
      | nil => simp [myFoldr,mySum]
      | cons n ns hyp => simp [myFoldr,mySum,hyp]
    simp [lemma,foldr_append (· + ·) 0 (fun x y z => (Int.add_assoc x y z).symm) Int.zero_add]


def myConcat (xss : List (List α)) : List α := myFoldr (· +++ ·) [] xss

/-- `concat (xs ++ ys) = concat xs ++ concat ys`, as a special case of
(foldr.3). The Chapter 9 lemma `append_assoc`  gives one
of its side conditions. -/
theorem concat_append (xss yss : List (List α)) :
    myConcat (xss +++ yss) = myConcat xss +++ myConcat yss := by
      have nil_append : ∀ zs : List α, [] +++ zs = zs := by simp [myAppend]
      simp [myConcat, foldr_append (· +++ ·) [] (fun x y z => (append_assoc x y z)) nil_append]

end AdditionalChapter11
