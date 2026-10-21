/-
Additional material for Chapter 9 ("Reasoning about programs").

Shows how to import another module in the project, and to use unqualified names (open).

To note:
- Named theorem for associativity of '||' so it can be used in simp.
- Used type class for (Boolean) equality BEq
- To use rules from that type class need to include [LawfulBEq α] in the theorem statement
- Early attempts to prove theorems using (==) problematic because of operator binding: needed to add extra parentheses to solve. This manifested by producing a propositional equality rather than Boolean.
- Nice notation for Nats, which is available for patterm matching when writing definitions, but not when building inductive proofs.
- Multiplication on Nat is defined: rules are in the Nat module e.g. Nat.mul_assoc
-/

import HaskellCraft.Chapter9

open Chapter9

namespace AdditionalChapter9

-- More examples

-- Associativity of || is needed as a lemma

theorem orAssoc (x y z : Bool) :
  (x || (y || z)) = ((x ||y) || z) := by
  cases x with
    | false => simp
    | true => simp

-- Type class for equality used here

def myElem [BEq α] : α -> List α -> Bool
  | _x, []      => false
  |  x, y :: ys => x == y || myElem x ys

-- To use properties of ==, need to include the LawfulBEq interface

theorem sing_myelem [BEq α] [LawfulBEq α] (n : α)  :
  (myElem n (n :: nil)) = true := by
  simp [myElem]

-- Polymorphic myElem distributes over +++ with ||

theorem elem_append [BEq α ] (xs ys : List α)  (x : α):
  (myElem x (xs +++ ys)) = ((myElem x xs) || (myElem x ys)) := by
  induction xs with
  | nil => simp [myElem, myAppend]
  | cons z zs hyp => simp [myElem, myAppend, orAssoc, hyp]

-- Num

def fac : Nat -> Nat
  | 0 => 1
  | n+1 => (n+1)*(fac n)

def fac_acc : Nat -> Nat -> Nat
  | 0, k    => k
  | n+1, k  => fac_acc n (k*(n+1))

theorem two_facs n k :
  fac_acc n k = k*(fac n) := by
  induction n generalizing k with
    | zero =>
      simp [fac,fac_acc]
    | succ n hyp =>
      simp [fac,fac_acc,hyp,Nat.mul_assoc]

/-
Looking at zip and unzip in detail

To note:
-  sequencing is by ; or newline, but c1 ; c2 only applies c2 to the first goal left after c1. To apply to all of them use c1 <;> c2.
- cases ys with … used in similary notation to induction with …
- obtain ⟨hp, hq⟩ := h to get two named hypotheses
- Loogle
- have := hyp ws
- := notation is implicit in pattern matching definitions, but it's there all the same.
-/


def zip {α β} : List α × List β -> List (α × β)
  | ((x::xs), (y::ys))  => (x,y) :: zip (xs,ys)
  | (_xs, _ys)       => []

def pcons {α β} : (α × β) -> List α × List β -> List α × List β
  | p, ps => (p.fst :: ps.fst, p.snd :: ps.snd)

def unzip {α β} : List (α × β) -> (List α) × (List β)
  | [] => ([],[])
  | z::zs => pcons z (unzip zs)

theorem zip_unzip {α β} (ps : List (α × β)) :
  zip (unzip ps) = ps := by
  induction ps with
    | nil => simp [zip,unzip]
    | cons z zs hyp => simp [zip,unzip,hyp,pcons]

theorem unzip_zip {α β} (xs : List α) (ys : List β) :
  (h: xs.length = ys.length) → unzip (zip (xs,ys)) = (xs, ys) := by
  induction xs generalizing ys with
    | nil => cases ys <;> simp_all [zip,unzip]
    | cons z zs hyp =>
      cases ys with
      | nil => simp
      | cons w ws => simp_all [zip,unzip,pcons]

theorem unzip_length {α β} (ps : List (α × β)) :
    ((unzip ps).fst).length = ps.length ∧
    ((unzip ps).snd).length = ps.length := by
    constructor <;>
    induction ps with
      | nil => simp [unzip]
      | cons z zs hyp => simp [unzip,hyp,pcons]

theorem zip_length {α β} (xs : List α) (ys : List β) :
    (zip (xs,ys)).length = min (xs.length) (ys.length) := by
      induction xs generalizing ys with
        | nil => simp [zip]
        | cons w ws hyp =>
          cases ys with
          | nil => simp [zip]
          | cons v vs => simp [zip,hyp]

theorem unzip_zip_inverse {α β} (xs : List α) (ys : List β) :
  unzip (zip (xs,ys)) = (xs, ys) → (xs.length = ys.length) := by
  induction xs generalizing ys with
    | nil => cases ys <;> simp_all [zip,unzip]
    | cons z zs hyp =>
      cases ys with
      | nil => simp_all [zip,unzip]
      | cons w ws =>
          have := hyp ws
          simp_all [zip,unzip,pcons,Prod.ext_iff]

end AdditionalChapter9
