/-
Logic in Lean: proofs in propositional and predicate logic.

This is the logic that all the other files use without saying so. Each
section starts with worked examples, fully proved, and goes on to
exercises stated with `sorry` in place of a proof, to be filled in.

A proposition `p : Prop` is a statement, and a proof of `p` is a value
of type `p`. So proving is like programming: to prove `p → q` is to
write a function that turns a proof of `p` into a proof of `q`. The
tactics build these values step by step, working backwards from the
goal:
- `intro h`: to prove `p → q`, assume `h : p` and prove `q`;
- `exact h`: the goal is exactly `h`;
- `apply f`: to prove `q` with `f : p → q`, it is enough to prove `p`.

The variables `p q r : Prop` stand for any propositions.
-/

namespace Logic

variable (p q r : Prop)

-- ---------------------------------------------------------------------
-- Implication
-- ---------------------------------------------------------------------

/-- `p → p`: assume `p`, and that is the proof. -/
theorem imp_self : p → p := by
  intro hp
  exact hp

/-- The same proof, written as a function: the identity function. This
is the sense in which proofs are programs. -/
theorem imp_self' : p → p := fun hp => hp

/-- Implication is transitive: `apply` works backwards from the goal. -/
theorem imp_trans : (p → q) → (q → r) → (p → r) := by
  intro hpq hqr hp
  apply hqr
  apply hpq
  exact hp

/-- Exercise. -/
theorem imp_const : p → (q → p) := by
  sorry

/-- Exercise: the order of the hypotheses doesn't matter. -/
theorem imp_swap : (p → q → r) → (q → p → r) := by
  sorry
-- ---------------------------------------------------------------------
-- Conjunction: `∧` (typed `\and`)
-- ---------------------------------------------------------------------

/-- To prove `p ∧ q`, prove both: `constructor` gives two goals. To use
`h : p ∧ q`, take it apart: `h.1 : p` and `h.2 : q`, or
`obtain ⟨hp, hq⟩ := h`. -/
theorem and_swap : p ∧ q → q ∧ p := by
  intro h
  obtain ⟨hp, hq⟩ := h
  constructor
  · exact hq
  · exact hp

/-- The same proof as a term: `⟨_, _⟩` builds a proof of an `∧`. -/
theorem and_swap' : p ∧ q → q ∧ p := fun ⟨hp, hq⟩ => ⟨hq, hp⟩

/-- Exercise. -/
theorem and_assoc : (p ∧ q) ∧ r → p ∧ (q ∧ r) := by
  sorry

/-- Exercise: this is `curry` from Chapter 11, as a theorem. -/
theorem and_imp_curry : (p ∧ q → r) → (p → q → r) := by
  sorry

/-- Exercise: and `uncurry`. -/
theorem and_imp_uncurry : (p → q → r) → (p ∧ q → r) := by
  sorry

-- ---------------------------------------------------------------------
-- Disjunction: `∨` (typed `\or`)
-- ---------------------------------------------------------------------

/-- To prove `p ∨ q`, choose a side: `left` or `right`. To use
`h : p ∨ q`, split into two cases with `cases h`, one for each side:
proof by cases. -/
theorem or_swap : p ∨ q → q ∨ p := by
  intro h
  cases h with
  | inl hp => right; exact hp
  | inr hq => left; exact hq

/-- Exercise. -/
theorem or_imp : (p → r) → (q → r) → (p ∨ q → r) := by
  sorry

/-- Exercise: `∧` distributes over `∨`. -/
theorem and_or_distrib : p ∧ (q ∨ r) → (p ∧ q) ∨ (p ∧ r) := by
  sorry

-- ---------------------------------------------------------------------
-- Negation: `¬` (typed `\not`), `False` and `True`
-- ---------------------------------------------------------------------

/- `¬p` means `p → False`: assuming `p` leads to a contradiction. So a
proof of `¬p` starts with `intro`. `False` has no proofs, and from a
proof of `False` anything follows: `exfalso` changes any goal to
`False`, and `absurd hp hnp` proves anything from `hp : p` and
`hnp : ¬p`. -/

/-- Modus tollens. -/
theorem modus_tollens : (p → q) → ¬q → ¬p := by
  intro hpq hnq hp
  exact hnq (hpq hp)

/-- Exercise: double negation introduction. -/
theorem not_not_intro : p → ¬¬p := by
  sorry

/-- Exercise: one of de Morgan's laws, in one direction. -/
theorem not_or_of_not_and_not : ¬p ∧ ¬q → ¬(p ∨ q) := by
  sorry

/-- Exercise: and the other direction. -/
theorem not_and_not_of_not_or : ¬(p ∨ q) → ¬p ∧ ¬q := by
  sorry

/-- Exercise: anything follows from a contradiction. -/
theorem contradiction_anything : p ∧ ¬p → q := by
  sorry

-- ---------------------------------------------------------------------
-- If and only if: `↔` (typed `\iff`)
-- ---------------------------------------------------------------------

/-- To prove `p ↔ q`, prove both directions: `constructor` again. To
use `h : p ↔ q`, `h.mp : p → q` and `h.mpr : q → p`. `rw [h]` also
works, replacing `p` by `q`. -/
theorem and_comm_iff : p ∧ q ↔ q ∧ p := by
  constructor
  · exact and_swap p q
  · exact and_swap q p

/-- Exercise: use the two `or_swap`s. -/
theorem or_comm_iff : p ∨ q ↔ q ∨ p := by
  sorry

/-- Exercise: de Morgan, both directions; use the theorems above. -/
theorem not_or_iff : ¬(p ∨ q) ↔ ¬p ∧ ¬q := by
  sorry

-- ---------------------------------------------------------------------
-- Classical logic
-- ---------------------------------------------------------------------

/- Everything so far is constructive: a proof of `p ∨ q` says which of
`p` and `q` holds. Some laws need more: the law of the excluded middle,
`p ∨ ¬p` for every `p`, which Lean provides as `Classical.em p`, and
`by_cases h : p`, which uses it to split into the cases `h : p` and
`h : ¬p`. These laws hold in classical logic, but can't be proved
constructively. -/

/-- Double negation elimination needs the excluded middle. -/
theorem not_not_elim : ¬¬p → p := by
  intro hnnp
  by_cases hp : p
  · exact hp
  · exact absurd hp hnnp

/-- Exercise: the other de Morgan law, in the direction that needs the
excluded middle. Hint: `by_cases` on `p`. -/
theorem not_and_imp : ¬(p ∧ q) → ¬p ∨ ¬q := by
  sorry

/-- Exercise: an implication in terms of `∨`. -/
theorem imp_iff_not_or : (p → q) ↔ ¬p ∨ q := by
  sorry

-- ---------------------------------------------------------------------
-- Predicate logic: `∀` (typed `\all`) and `∃` (typed `\ex`)
-- ---------------------------------------------------------------------

/- `P Q : α → Prop` are predicates on a type `α`. A proof of
`∀ x, P x` is a function from each `x` to a proof of `P x`, so it is
proved by `intro x`, and used by applying it to a value. A proof of
`∃ x, P x` is a pair of a value and a proof that it has the property:
it is built with `⟨a, h⟩`, or `exists a`, and taken apart with
`obtain ⟨x, hx⟩ := h`. -/

variable {α : Type} (P Q : α → Prop)

/-- `∀` distributes over `∧`. -/
theorem forall_and : (∀ x, P x ∧ Q x) → (∀ x, P x) ∧ (∀ x, Q x) := by
  intro h
  constructor
  · intro x
    exact (h x).1
  · intro x
    exact (h x).2

/-- A witness: 4 is bigger than 3. `decide` checks `4 > 3`. -/
theorem exists_gt_three : ∃ n : Nat, n > 3 := by
  exact ⟨4, by decide⟩

/-- Taking an `∃` apart. -/
theorem exists_or_left : (∃ x, P x) → ∃ x, P x ∨ Q x := by
  intro h
  obtain ⟨x, hx⟩ := h
  exact ⟨x, Or.inl hx⟩

/-- Exercise: the converse of `forall_and`. -/
theorem and_forall : (∀ x, P x) ∧ (∀ x, Q x) → ∀ x, P x ∧ Q x := by
  sorry

/-- Exercise: there is no number less than 0. -/
theorem not_exists_lt_zero : ¬∃ n : Nat, n < 0 := by
  sorry

/-- Exercise: every number has a bigger one. -/
theorem exists_bigger : ∀ n : Nat, ∃ m, m > n := by
  sorry

/-- Exercise: de Morgan for quantifiers, constructive direction. -/
theorem not_exists_forall : ¬(∃ x, P x) → ∀ x, ¬P x := by
  sorry

/-- Exercise: and back again. -/
theorem forall_not_exists : (∀ x, ¬P x) → ¬∃ x, P x := by
  sorry

/-- Exercise: the order of quantifiers. One way round is true. -/
theorem exists_forall_swap (R : α → α → Prop) :
    (∃ x, ∀ y, R x y) → ∀ y, ∃ x, R x y := by
  sorry

/- The other way round, `(∀ y, ∃ x, R x y) → ∃ x, ∀ y, R x y`, is false:
every number has a bigger one, but there's no number bigger than every
number. -/

/-- Exercise: so prove that it fails, with `R` as `>` on `Nat`. Hint:
`exists_bigger` gives the hypothesis; then take the `∃` apart, and use
the `∀` at the number you get. -/
theorem not_forall_exists_swap :
    ¬((∀ y : Nat, ∃ x, x > y) → ∃ x : Nat, ∀ y, x > y) := by
  sorry

end Logic
