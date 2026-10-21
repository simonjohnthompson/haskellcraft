/-
Exercises from Chapter 14's "Reasoning about algebraic types" section,
with their proofs.

`+++`, `myLength` and `length_append` are in Chapter9.lean; `comp` and
`∘'`, `myId`, `myMap`, `myFilter` and `map_append` are in
Chapter11.lean; `Tree`, `mapTree` and `collapse` are in Chapter14.lean.
The types that only the exercises use are defined here.
-/

import HaskellCraft.Chapter14

open Chapter9 Chapter11 Chapter14

namespace AdditionalChapter14

-- ---------------------------------------------------------------------
-- `weather` (book: Section "Algebraic type definitions revisited", and
-- the Chapter 4 exercise defining `Season` and `Temp`)
-- ---------------------------------------------------------------------

inductive Season where
  | spring | summer | autumn | winter
  deriving DecidableEq

inductive Temp where
  | cold | hot

open Season Temp

/-- In the UK. -/
def weather : Season → Temp
  | summer => hot
  | _      => cold

def makeHot : Bool → Temp
  | true  => hot
  | false => cold

def isSummer (s : Season) : Bool := s == summer

def newWeather : Season → Temp := makeHot ∘' isSummer

theorem weather_newWeather : weather = newWeather := by
  funext s
  cases s <;> rfl

-- ---------------------------------------------------------------------
-- `Shape` and `area`
-- ---------------------------------------------------------------------

/- TL;DR too messy to be of interest pedagogically.

The book's `Shape` uses `Float`. Lean's `Float` is machine floating
point with no algebraic laws, so no theorem about it can be proved.

Instead, `Shape` here is over any ordered field `R`: the real numbers
are one, the rationals `Rat` another. π is irrational, so it is not a
fixed value but a parameter `pi` of `area`, and the theorems assume only
`0 < pi`. They then hold for every positive `pi`, the real π included,
while `#eval` can still use a rational approximation.

`grind` is an automated tactic built into Lean, in the style of an SMT
solver: it assumes the goal is false and looks for a contradiction,
combining reasoning with equalities, instantiating lemmas, case splits,
and solvers for linear arithmetic and for commutative rings. The classes
that describe an ordered field, `Field`, `OrderedRing` and so on, are in
the `Lean.Grind` namespace (with the order classes in `Std`): they are
what lets `grind` do arithmetic over a type `R` it knows nothing else
about. Its arithmetic over ordered fields is linear only, so it treats
`r * r` as an unknown and can't see that it is never negative. -/

section Shapes

open Lean.Grind

inductive Shape (R : Type) where
  | circle    : R → Shape R
  | rectangle : R → R → Shape R

open Shape

variable {R : Type} [Field R] [LE R] [LT R]
  [Std.IsLinearOrder R] [Std.LawfulOrderLT R] [OrderedRing R]

def area (pi : R) : Shape R → R
  | circle r      => pi * r * r
  | rectangle h w => h * w

#eval area (314159 / 100000 : Rat) (circle 2)

/-- Not every area is non-negative: give a counterexample. -/
theorem area_not_nonneg (pi : R) : ¬ ∀ s : Shape R, 0 ≤ area pi s := by
  intro hyp
  have h := hyp (rectangle (-1) 1)
  simp only [area] at h
  grind

/-- A rectangle with non-negative sides has non-negative area. -/
theorem area_rectangle_nonneg (pi h w : R) (hh : 0 ≤ h) (hw : 0 ≤ w) :
  0 ≤ area pi (rectangle h w) := by
  simp only [area]
  exact OrderedRing.mul_nonneg hh hw

/-- Every circle has non-negative area. `grind` can't do this alone,
because `0 ≤ r * r` is not linear: prove that first, by cases on whether
`0 ≤ r`, using `OrderedRing.mul_nonneg`. -/
theorem area_circle_nonneg (pi r : R) (hpi : 0 < pi) :
  0 ≤ area pi (circle r) := by
  simp only [area]
  have rsq : 0 ≤ r * r := by
    by_cases hr : (0 ≤ r)
    · exact OrderedRing.mul_nonneg hr hr
    · have hneg : r < 0 := by grind
      have := OrderedRing.mul_pos_of_neg_of_neg hneg hneg
      grind
  have := OrderedRing.mul_nonneg (show 0 ≤ pi by grind) rsq
  grind



end Shapes

-- ---------------------------------------------------------------------
-- `NTree`: `size`, `depth` and `occurs`
-- ---------------------------------------------------------------------

/-- The book's trees of integers. Its constructor is `Node`, as for
`Tree`; inside this file only `NTree`'s is opened, so `node` means
`NTree.node` here. -/
inductive NTree where
  | nilT : NTree
  | node : Int → NTree → NTree → NTree

open NTree

def size : NTree → Nat
  | nilT         => 0
  | node _ t1 t2 => 1 + size t1 + size t2

def depth : NTree → Nat
  | nilT         => 0
  | node _ t1 t2 => 1 + max (depth t1) (depth t2)

/-- `size tr < 2 ^ depth tr`. The arithmetic in the `node` case is not
linear (it has `2 ^ ...`), so `omega` can't do it alone: it needs to be
told how `2 ^ depth t1` and `2 ^ depth t2` compare with
`2 ^ max (depth t1) (depth t2)`. `Nat.pow_le_pow_right` and
`Nat.pow_succ` are useful. -/
theorem size_lt_pow_depth (tr : NTree) : size tr < 2 ^ depth tr := by
  induction tr with
  | nilT => simp [size,depth]
  | node _n t1 t2 hyp1 hyp2 =>
    simp [size,depth,Nat.pow_add,Nat.pow_succ]
    have pow_max1 : ∀ n m, 2^n ≤ 2^(max n m) := by
      intro n m
      exact Nat.pow_le_pow_right (by decide) (Nat.le_max_left n m)
    have pow_max2 : ∀ n m, 2^m ≤ 2^(max n m) := by
      intro n m
      exact Nat.pow_le_pow_right (by decide) (Nat.le_max_right n m)
    have lemma1 : (1 + size t1 + size t2 < 1 + 2 ^ depth t1 + 2 ^ depth t2) := by omega
    have h1 := pow_max1 (depth t1) (depth t2)
    have h2 := pow_max2 (depth t1) (depth t2)
    omega

def occurs : NTree → Int → Nat
  | nilT, _ => 0
  | node n t1 t2, p =>
      if n == p then 1 + occurs t1 p + occurs t2 p
      else occurs t1 p + occurs t2 p

def collapseN : NTree → List Int
  | nilT         => []
  | node n t1 t2 => n :: (collapseN t1 +++ collapseN t2)

theorem filter_append (xs ys : List α) (p : (α -> Bool)) :
    myFilter p (xs +++ ys) = myFilter p xs +++ myFilter p ys := by
    induction xs with
      | nil => simp [myAppend,myFilter]
      | cons w ws hyp =>
        simp [myAppend,myFilter]
        by_cases test : p w
        · simp [test,hyp,myAppend]
        · simp [test,hyp]

/-- `occurs tr x = length (filter (==x) (collapse tr))`. You will need a
lemma relating `myFilter` and `+++`, like `map_append` for `myMap`. -/
theorem occurs_length_filter (tr : NTree) (x : Int) :
    occurs tr x = myLength (myFilter (fun y => y == x) (collapseN tr)) := by
      induction tr with
      | nilT =>
         simp [myLength, myFilter, collapseN, occurs]
      | node z t1 t2 hyp1 hyp2 =>
         simp [occurs,collapseN,myFilter]
         by_cases h : z=x
         · simp [h,myLength,filter_append,length_append,hyp1,hyp2]
           omega
         · simp [h,filter_append,length_append,hyp1,hyp2]





-- ---------------------------------------------------------------------
-- `twist` (book: exercises to Section "Polymorphic algebraic types")
-- ---------------------------------------------------------------------

inductive Either (α β : Type) where
  | left  : α → Either α β
  | right : β → Either α β

open Either

def twist : Either α β → Either β α
  | left x  => right x
  | right y => left y

theorem twist_twist :
    (twist ∘' twist : Either α β → Either α β) = myId := by
  funext x
  cases x <;> simp [comp,myId,twist]

-- ---------------------------------------------------------------------
-- `GTree` (book: exercises to Section "Polymorphic algebraic types")
-- ---------------------------------------------------------------------

/-- Trees with any number of subtrees at each node. -/
inductive GTree (α : Type) where
  | leaf  : α → GTree α
  | gnode : List (GTree α) → GTree α

open GTree

/- `GTree` is a *nested* inductive type: the recursion goes through
`List (GTree α)`. The simplest way to define functions on it is a
`mutual` block, with one function on trees and one on lists of trees
("forests"), each calling the other. Structural induction for `GTree`
then becomes two theorems proved together, in a `mutual` block, by
recursion: one for trees and one for forests. That is the answer to the
book's "explain the principle of structural induction for `GTree`". -/

mutual
def mapGTree (f : α → β) : GTree α → GTree β
  | leaf x   => leaf (f x)
  | gnode ts => gnode (mapForest f ts)

def mapForest (f : α → β) : List (GTree α) → List (GTree β)
  | []      => []
  | t :: ts => mapGTree f t :: mapForest f ts
end

mutual
/-- The equivalent of `collapse` for `GTree`. -/
def flatten : GTree α → List α
  | leaf x   => [x]
  | gnode ts => flattenForest ts

def flattenForest : List (GTree α) → List α
  | []      => []
  | t :: ts => flatten t +++ flattenForest ts
end

/- The equivalent of (map-collapse) for `GTree`. A theorem can be proved
by recursion, like a function: give the cases with `|` after the
statement (no `:= by`), and call the theorem on smaller arguments to
use it as an induction hypothesis. Each case can then be proved with
`by ...`. Lean checks that the recursion is well founded, so this is
structural induction. -/

mutual
theorem map_flatten (f : α → β) :
    (t : GTree α) → myMap f (flatten t) = flatten (mapGTree f t)
  | leaf x   =>
      by simp [myMap,flatten,mapGTree]
  | gnode ts =>
      by simp [flatten,
               map_flattenForest f ts,  -- induction
               mapGTree]


theorem map_flattenForest (f : α → β) :
    (ts : List (GTree α)) →
      myMap f (flattenForest ts) = flattenForest (mapForest f ts)
  | []      =>
      by simp [mapForest,flattenForest,myMap]
  | t :: ts =>
      by simp [flattenForest, map_append, mapForest,
               map_flattenForest f ts, -- induction
               map_flatten f t]        -- induction
end

end AdditionalChapter14
