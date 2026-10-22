/-
Infinite lists, from Chapter 17's "Proof revisited" section, with the
two factorial lists. The part of the section on finite and partial
lists is in Chapter17.lean, and the exercises on infinite lists are in
AdditionalStreams.lean.

Combining the two, as the book does in treating an infinite list as the
limit of its partial approximations, is not covered.
-/

import HaskellCraft.Chapter11

open Chapter11

namespace Streams

-- ---------------------------------------------------------------------
-- Infinite lists (book: "Infinite lists")
-- ---------------------------------------------------------------------

/- Infinite lists are streams: `Strm α`, with a head and a tail, but no
`[]` and no `undef`. Neither Lean nor Mathlib has coinductive types, so
`Strm` is built from a function on `Nat`. That function is private to
this file: everything after the next few definitions, and everything in
AdditionalStreams.lean, uses only the stream interface:

- `head`, `tail` and `cons`, with `head (cons x s) = x` and
  `tail (cons x s) = s`;
- corecursion, `corec`, which defines a stream by unfolding it from a
  seed, as `unfoldr` does for Haskell lists;
- coinduction, `eq_of_bisim`: two streams are equal if they are
  bisimilar, that is if their heads are equal and their tails are
  bisimilar. `Bisim` is a `coinductive` predicate, and Lean generates
  its proof principle, `Bisim.coinduct`.

Coinduction plays the part of the book's principle that two lists are
equal if all their approximants are. -/

/-- Infinite lists. -/
structure Strm (α : Type) where
  private mk ::
  private get : Nat → α

namespace Strm

def head (s : Strm α) : α := s.get 0

def tail (s : Strm α) : Strm α := ⟨fun n => s.get (n + 1)⟩

def cons (x : α) (s : Strm α) : Strm α :=
  ⟨fun n => match n with
    | 0     => x
    | n + 1 => s.get n⟩

@[simp] theorem head_cons (x : α) (s : Strm α) : (cons x s).head = x := rfl

@[simp] theorem tail_cons (x : α) (s : Strm α) : (cons x s).tail = s := rfl

/-- Every stream is a `cons`. -/
theorem cons_head_tail (s : Strm α) : cons s.head s.tail = s := by
  rcases s with ⟨g⟩
  simp only [cons, head, tail]
  congr
  funext n
  cases n <;> rfl

/-- Corecursion: `step` gives the head, and the seed for the tail. -/
def corec (step : σ → α × σ) (seed : σ) : Strm α :=
  ⟨fun n => (step (go n seed)).1⟩
where
  go : Nat → σ → σ
    | 0,     s => s
    | n + 1, s => go n (step s).2

@[simp] theorem head_corec (step : σ → α × σ) (seed : σ) :
    (corec step seed).head = (step seed).1 := rfl

@[simp] theorem tail_corec (step : σ → α × σ) (seed : σ) :
    (corec step seed).tail = corec step (step seed).2 := rfl

coinductive Bisim : Strm α → Strm α → Prop where
  | step : s.head = t.head → Bisim s.tail t.tail → Bisim s t

/-- Coinduction: bisimilar streams are equal. -/
theorem eq_of_bisim {s t : Strm α} (h : Bisim s t) : s = t := by
  rcases s with ⟨f⟩
  rcases t with ⟨g⟩
  congr
  funext n
  induction n generalizing f g with
  | zero => cases h with | step hh _ => exact hh
  | succ n ih => cases h with | step _ ht => exact ih _ _ ht

/- From here on, only the interface above is used. -/

/-- `xs!!n`. -/
def nth : Strm α → Nat → α
  | s, 0     => s.head
  | s, n + 1 => nth s.tail n

/-- The book's "infinite list equality": infinite lists are equal if
their elements are equal at every index. With streams this is a
theorem, proved by coinduction. -/
theorem eq_of_nth {s t : Strm α} (h : ∀ n, nth s n = nth t n) : s = t := by
  apply eq_of_bisim
  apply Bisim.coinduct (fun s t => ∀ n, nth s n = nth t n)
  · intro s t h
    exact ⟨h 0, fun n => h (n + 1)⟩
  · exact h

def map (f : α → β) (s : Strm α) : Strm β :=
  corec (fun s => (f s.head, s.tail)) s

def zipWith (g : α → β → γ) (s : Strm α) (t : Strm β) : Strm γ :=
  corec (fun (p : Strm α × Strm β) => (g p.1.head p.2.head, (p.1.tail, p.2.tail)))
    (s, t)

/-- `[n ..]`. -/
def upFrom (n : Nat) : Strm Nat := corec (fun k => (k, k + 1)) n

@[simp] theorem head_map (f : α → β) (s : Strm α) :
    (map f s).head = f s.head := rfl

@[simp] theorem tail_map (f : α → β) (s : Strm α) :
    (map f s).tail = map f s.tail := by
  simp [map]

@[simp] theorem head_zipWith (g : α → β → γ) (s : Strm α) (t : Strm β) :
    (zipWith g s t).head = g s.head t.head := rfl

@[simp] theorem tail_zipWith (g : α → β → γ) (s : Strm α) (t : Strm β) :
    (zipWith g s t).tail = zipWith g s.tail t.tail := by
  simp [zipWith]

@[simp] theorem head_upFrom (n : Nat) : (upFrom n).head = n := rfl

@[simp] theorem tail_upFrom (n : Nat) : (upFrom n).tail = upFrom (n + 1) := by
  simp [upFrom]

/-- (map.!!), which the book assumes. -/
theorem nth_map (f : α → β) (s : Strm α) (n : Nat) :
    nth (map f s) n = f (nth s n) := by
  induction n generalizing s with
  | zero => simp [nth]
  | succ n hyp => simp [nth, hyp]

/-- (zipWith.!!), which the book also assumes. -/
theorem nth_zipWith (g : α → β → γ) (s : Strm α) (t : Strm β) (n : Nat) :
    nth (zipWith g s t) n = g (nth s n) (nth t n) := by
  induction n generalizing s t with
  | zero => simp [nth]
  | succ n hyp => simp [nth, hyp]

/-- `[m ..]!!n = m+n`. -/
theorem nth_upFrom (m n : Nat) : nth (upFrom m) n = m + n := by
  induction n generalizing m with
  | zero => simp [nth]
  | succ n hyp => simp [nth, hyp]; omega

end Strm

-- ---------------------------------------------------------------------
-- Two factorial lists (book: "Example: Two factorial lists")
-- ---------------------------------------------------------------------

open Strm

def fac : Nat → Nat
  | 0     => 1                            -- (fac.1)
  | n + 1 => (n + 1) * fac n              -- (fac.2)

def facMap : Strm Nat := Strm.map fac (upFrom 0)   -- (facMap.1)

/- The book defines `facs = 1 : zipWith (*) [1 ..] facs`. Lean won't
accept a definition that refers to itself like this, so `facs` is
defined by corecursion, and the book's equation (facs.1) is proved as a
theorem, `facs_eq`. -/

/-- `a, k*a, (k+1)*k*a, ...`: the seed is the next multiplier and the
current value. -/
def facsFrom (k a : Nat) : Strm Nat :=
  corec (fun (p : Nat × Nat) => (p.2, (p.1 + 1, p.1 * p.2))) (k, a)

@[simp] theorem head_facsFrom (k a : Nat) : (facsFrom k a).head = a := rfl

@[simp] theorem tail_facsFrom (k a : Nat) :
    (facsFrom k a).tail = facsFrom (k + 1) (k * a) := by
  simp [facsFrom]

def facs : Strm Nat := facsFrom 1 1

/-- (facs.1), by coinduction. Its tail is `facsFrom 2 1`, and the
relation relates each later tail of `facs`, `facsFrom (k+1) (k*a)`, to
the matching tail of `zipWith (*) [1 ..] facs`. -/
theorem facs_eq : facs = cons 1 (Strm.zipWith (· * ·) (upFrom 1) facs) := by
  have h : facs.tail = Strm.zipWith (· * ·) (upFrom 1) facs := by
    apply eq_of_bisim
    apply Bisim.coinduct
      (fun s t => ∃ k a, s = facsFrom (k + 1) (k * a) ∧
                         t = Strm.zipWith (· * ·) (upFrom k) (facsFrom k a))
    · rintro s t ⟨k, a, rfl, rfl⟩
      exact ⟨by simp, k + 1, k * a, by simp, by simp⟩
    · exact ⟨1, 1, by simp [facs], rfl⟩
  conv => lhs; rw [← cons_head_tail facs]
  rw [h]
  rfl

/-- `facMap!!n = fac n`, the first steps of each case of the book's
proof below: by (facMap.1), (map.!!) and the definition of `[0 ..]`. -/
theorem nth_facMap (n : Nat) : nth facMap n = fac n := by
  simp [facMap, nth_map, nth_upFrom]

/-- (facMap.!!), with the book's proof: induction on `n`, using
(zipWith.!!) and (facs.1) for the right-hand side. -/
theorem facMap_nth (n : Nat) : nth facMap n = nth facs n := by
  induction n with
  | zero => rw [nth_facMap]; rfl
  | succ n hyp =>
      rw [nth_facMap] at hyp ⊢
      rw [facs_eq]
      simp only [nth, tail_cons]
      rw [nth_zipWith, nth_upFrom, ← hyp, fac, Nat.add_comm 1 n]

/-- So the two lists are equal, by infinite list equality. -/
theorem facMap_eq_facs : facMap = facs := eq_of_nth facMap_nth

/-- The same result, proved directly by coinduction: each tail of
`facMap`, `map fac [k ..]`, is related to the matching tail of `facs`. -/
theorem facMap_eq_facs' : facMap = facs := by
  apply eq_of_bisim
  apply Bisim.coinduct
    (fun s t => ∃ k, s = Strm.map fac (upFrom k) ∧ t = facsFrom (k + 1) (fac k))
  · rintro s t ⟨k, rfl, rfl⟩
    exact ⟨by simp, k + 1, by simp, by simp [fac]⟩
  · exact ⟨0, rfl, rfl⟩

end Streams
