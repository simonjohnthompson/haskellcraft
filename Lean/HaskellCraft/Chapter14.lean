/-
Chapter 14 ("Algebraic types"), section "Reasoning about algebraic
types", re-done in Lean.

As in the earlier files, the types and functions are redefined from
scratch: `Tree`, `Maybe` and `Expr` are the book's own types, not Lean's
`Option` and so on. `+++` comes from Chapter9.lean, and `myMap` and
`map_append` from Chapter11.lean.

The worked proofs from the text are given in full. The section's
exercises are in AdditionalChapter14.lean.

What carries over from lists, and what is new:
- Lean derives a structural induction principle from every `inductive`
  declaration, so `induction tr` gives exactly the book's cases: one per
  constructor, with an induction hypothesis for each recursive argument.
  For `Tree` that is a `nil` case and a `node` case with two hypotheses.
- For a non-recursive type like `Maybe`, induction is just proof by
  cases, and `cases x` is all that's needed.
- `assoc` is not defined by primitive recursion, so Lean needs to be told
  why it terminates (`termination_by`). In return, Lean generates an
  induction principle that follows `assoc`'s own recursion, `assoc.induct`.
  That replaces the book's induction on the number of left-nested `Add`s.
-/

import HaskellCraft.Chapter11

open Chapter9 Chapter11

namespace Chapter14

-- ---------------------------------------------------------------------
-- Trees (book: "Trees")
-- ---------------------------------------------------------------------

inductive Tree (α : Type) where
  | nil  : Tree α
  | node : α → Tree α → Tree α → Tree α

open Tree

def mapTree (f : α → β) : Tree α → Tree β
  | nil          => nil                                         -- (mapTree.1)
  | node x t1 t2 => node (f x) (mapTree f t1) (mapTree f t2)    -- (mapTree.2)

def collapse : Tree α → List α
  | nil          => []                                          -- (collapse.1)
  | node x t1 t2 => collapse t1 +++ [x] +++ collapse t2         -- (collapse.2)

/-- (map-collapse): `map f (collapse tr) = collapse (mapTree f tr)`.
The `node` case has two induction hypotheses, `hyp1` and `hyp2`, one for
each subtree, and uses (map++) from Chapter 11, as the book does. -/
theorem map_collapse (f : α → β) (tr : Tree α) :
    myMap f (collapse tr) = collapse (mapTree f tr) := by
  induction tr with
  | nil => simp [collapse, mapTree, myMap]
  | node x tr1 tr2 hyp1 hyp2 =>
      simp [collapse, mapTree, map_append, myMap, myAppend, hyp1, hyp2]

-- ---------------------------------------------------------------------
-- The `Maybe` type (book: "The Maybe type")
-- ---------------------------------------------------------------------

inductive Maybe (α : Type) where
  | nothing : Maybe α
  | just    : α → Maybe α

open Maybe

def maybe (n : β) (f : α → β) : Maybe α → β
  | nothing => n
  | just x  => f x

def myAbs (x : Int) : Int := if x ≥ 0 then x else -x

/-- `maybe 2 abs x ≥ 0`: proof by cases, with no induction hypothesis,
since `Maybe` is not recursive. The `just` case needs `abs y ≥ 0`, which
the book takes as known; here `split` and `omega` prove it. -/
theorem maybe_abs (x : Maybe Int) : maybe 2 myAbs x ≥ 0 := by
  cases x with
  | nothing => simp [maybe]
  | just y =>
      simp only [maybe, myAbs]
      split <;> omega

-- ---------------------------------------------------------------------
-- Expressions and `assoc` (book: "Other forms of proof")
-- ---------------------------------------------------------------------

inductive Expr where
  | lit : Int → Expr
  | add : Expr → Expr → Expr
  | sub : Expr → Expr → Expr

open Expr

def eval : Expr → Int
  | lit n     => n
  | add e1 e2 => eval e1 + eval e2
  | sub e1 e2 => eval e1 - eval e2

/-- The number of constructors in an expression. -/
def size : Expr → Nat
  | lit _     => 1
  | add e1 e2 => 1 + size e1 + size e2
  | sub e1 e2 => 1 + size e1 + size e2

/-- The number of `Add`s left-nested at the top of an expression. -/
def leftAdds : Expr → Nat
  | add e1 _ => 1 + leftAdds e1
  | _        => 0

/-- The patterns overlap, as in the book: Lean, like Haskell, tries them
in order, so the second only applies when `e1` is not itself an `add`.

The first equation is not primitive recursive, so Lean needs a reason
why `assoc` terminates. The book's argument is that rearranging keeps
the total number of `Add`s the same but reduces those left-nested at
the top. Here: each recursive call either makes the expression smaller,
or keeps its size and reduces `leftAdds`. `termination_by` gives that
pair, compared lexicographically, and `decreasing_by` checks each call. -/
def assoc : Expr → Expr
  | add (add e1 e2) e3 => assoc (add e1 (add e2 e3))   -- (assoc.1)
  | add e1 e2          => add (assoc e1) (assoc e2)    -- (assoc.2)
  | sub e1 e2          => sub (assoc e1) (assoc e2)    -- (assoc.3)
  | lit n              => lit n                        -- (assoc.4)
termination_by e => (size e, leftAdds e)
decreasing_by all_goals simp [size, leftAdds]; omega

/-- (eval-assoc): `eval (assoc ex) = eval ex`.

`induction ex using assoc.induct` inducts along `assoc`'s own recursion,
giving one case per equation, each with a hypothesis for every recursive
call that equation makes:
- `case1` (assoc.1): the hypothesis is for `add e1 (add e2 e3)`, and the
  rest is associativity of `+`. This is the book's induction step on the
  number of left-nested `Add`s.
- `case2` (assoc.2): `h` records that `e1` is not an `add`, so (assoc.2)
  is the equation that applies. This is the book's "no `Add`s at the top
  level of `e1`" case.
- `case3` (assoc.3) and `case4` (assoc.4), the `Sub` and `Lit` cases. -/
theorem eval_assoc (ex : Expr) : eval (assoc ex) = eval ex := by
  induction ex using assoc.induct with
  | case1 e1 e2 e3 hyp =>
      rw [assoc, hyp]
      simp [eval]
      omega
  | case2 e1 e2 h hyp1 hyp2 =>
      rw [assoc]
      · simp [eval, hyp1, hyp2]
      · exact h
  | case3 e1 e2 hyp1 hyp2 => simp [assoc, eval, hyp1, hyp2]
  | case4 n => simp [assoc]

end Chapter14
