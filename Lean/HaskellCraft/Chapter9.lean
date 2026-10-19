/-
Chapter 9 ("Reasoning about programs") worked proofs, re-done in Lean.

Everything here is redefined from scratch (mySum, doubleAll, myLength, ...)
rather than reusing Lean/Mathlib's `List.sum`, `++`, `List.reverse`, etc.,
so that the proofs below mirror the book's own (base)/(ind)/(hyp) structure
step for step, using exactly the defining equations the book cites -- not
whatever lemma library already proves the result.
-/

namespace Chapter9

-- ---------------------------------------------------------------------
-- `sum` and `doubleAll` (book p.9, "A first example")
-- ---------------------------------------------------------------------

def mySum : List Int → Int
  | []      => 0                     -- (sum.1)
  | x :: xs => x + mySum xs          -- (sum.2)

def doubleAll : List Int → List Int
  | []      => []                    -- (doubleAll.1)
  | z :: zs => 2 * z :: doubleAll zs -- (doubleAll.2)

/-- `sum (doubleAll xs) = 2 * sum xs`. `simp` unfolds the defining
equations in both the base case and the induction step, exactly the
(base)/(ind) split the book makes; `omega` then closes the pure linear
arithmetic left over (the step the book does "by arith." by hand), using
the induction hypothesis `hyp` straight out of the local context. -/
theorem sum_doubleAll (xs : List Int) :
    mySum (doubleAll xs) = 2 * mySum xs := by
  induction xs with
  | nil => simp [mySum, doubleAll]
  | cons x xs hyp =>
      simp only [mySum, doubleAll]
      omega

-- ---------------------------------------------------------------------
-- `length` and `++` (book p.9, "Further examples", example 1)
-- ---------------------------------------------------------------------

def myLength : List α → Nat
  | []      => 0                 -- (length.1)
  | _ :: zs => 1 + myLength zs   -- (length.2)

def myAppend : List α → List α → List α
  | [],      zs => zs                  -- (++.1)
  | w :: ws, zs => w :: myAppend ws zs -- (++.2)

infixr:65 " +++ " => myAppend

/-- `length (xs ++ ys) = length xs + length ys`, induction over `xs` (the
variable `++` recurses on), `ys` left arbitrary -- just as the book
argues for choosing the induction variable. -/
theorem length_append (xs ys : List α) :
    myLength (xs +++ ys) = myLength xs + myLength ys := by
  induction xs with
  | nil => simp [myLength, myAppend]
  | cons x xs hyp =>
      simp only [myLength, myAppend]
      omega

-- ---------------------------------------------------------------------
-- `reverse` and `++` (book p.9, "Further examples", example 2)
-- The book proves this using two auxiliary lemmas, (++.3) and (++.4),
-- and leaves both as exercises. We prove them first, by induction.
-- ---------------------------------------------------------------------

def myReverse : List α → List α
  | []      => []                   -- (reverse.1)
  | z :: zs => myReverse zs +++ [z] -- (reverse.2)

/-- (++.3): `xs ++ [] = xs`, for all finite `xs`. -/
theorem append_nil (xs : List α) : xs +++ ([] : List α) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs hyp => simp [myAppend, hyp]

/-- (++.4): `++` is associative, for all finite `xs`, `ys`, `zs`. -/
theorem append_assoc (xs ys zs : List α) :
    xs +++ (ys +++ zs) = (xs +++ ys) +++ zs := by
  induction xs with
  | nil => rfl
  | cons x xs hyp => simp [myAppend, hyp]

/-- `reverse (xs ++ ys) = reverse ys ++ reverse xs`, using (++.3) in the
base case and (++.4) in the induction step, exactly as the book does. -/
theorem reverse_append (xs ys : List α) :
    myReverse (xs +++ ys) = myReverse ys +++ myReverse xs := by
  induction xs with
  | nil => simp [myAppend, myReverse, append_nil]
  | cons x xs hyp => simp [myAppend, myReverse, hyp, ← append_assoc]

-- ---------------------------------------------------------------------
-- `shunt` and `rev` (book p.9, "Generalizing the proof goal")
-- The point of this example is that `rev (rev xs) = xs` can't be proved
-- directly by induction, because `rev` isn't itself defined by recursion.
-- The book generalizes to a statement about `shunt` quantified over an
-- extra list `zs`, strengthening the induction hypothesis. In Lean this
-- generalization is exactly what `induction xs generalizing zs` does:
-- it makes `zs` arbitrary again in the induction hypothesis itself, so
-- `hyp` below is really `∀ zs, shunt (shunt xs zs) [] = shunt zs xs`
-- (the book's `∀zs (...)` statement of `(hyp)`), usable at any `zs`.
-- ---------------------------------------------------------------------

def shunt : List α → List α → List α
  | [],      ys => ys                 -- (shunt.1)
  | x :: xs, ys => shunt xs (x :: ys) -- (shunt.2)

def rev (xs : List α) : List α := shunt xs []  -- (rev.1)

theorem shunt_shunt_nil (xs zs : List α) :
    shunt (shunt xs zs) [] = shunt zs xs := by
  induction xs generalizing zs with
  | nil => simp [shunt]
  | cons x xs hyp => simp [shunt, hyp]

/-- `rev (rev xs) = xs`, the result the direct induction attempt couldn't
reach -- now immediate from the generalized lemma at `zs := []`. -/
theorem rev_rev (xs : List α) : rev (rev xs) = xs := by
  simp [rev, shunt_shunt_nil, shunt]

end Chapter9
