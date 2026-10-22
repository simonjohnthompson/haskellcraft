/-
Expr.hs in Lean: arithmetical expressions with variables, a printer and
parser, evaluation in an environment, a compiler to a stack machine,
and simplification. The theorems about the compiler and `simplify` are
stated with `sorry` in place of a proof, to be filled in.

Most of the definitions carry over directly. The differences:
- `run` is partial in Haskell: it has no equation for a stack that runs
  out, or for an empty stack at the end. Here it returns an `Option Int`,
  with `none` for those cases.
- `parse` is partial too: it returns an `Option`, with `none` where the
  Haskell would fail. Its second recursive call is not on a part of its
  argument, so, as for `simplify` below, Lean needs to know a fact about
  `parse` while it is being defined: here, that what it leaves of the
  string is no longer than the string.
- `simplify` terminates, but not because its recursion is structural:
  it calls itself again on the simplified expression. That terminates
  because simplifying either leaves an expression unchanged or makes it
  smaller, and Lean needs that fact while `simplify` is being defined.
  So `simp'` returns the simplified expression together with that fact,
  and `simplify` takes the expression part.
- Haskell's `Int` has a fixed size; Lean's `Int` is unbounded.

`Expr` and `eval` are also names in Chapter14.lean; the namespace keeps
them apart.
-/

namespace Expressions

inductive Expr where
  | num : Int → Expr
  | var : Char → Expr
  | add : Expr → Expr → Expr
  | mul : Expr → Expr → Expr
  deriving DecidableEq, Repr

open Expr

def expr1 : Expr := add (var 'a') (mul (num 2) (var 'b'))

def expr2 : Expr :=
  add (mul (num 1) (var 'b'))
      (mul (add (mul (num 2) (var 'b')) (mul (num 1) (var 'b'))) (num 0))

-- ---------------------------------------------------------------------
-- Printing
-- ---------------------------------------------------------------------

/-- `add (var 'a') (mul (num 2) (var 'b'))` prints as `"(a+(2*b))"`. -/
def print : Expr → String
  | num n     => toString n
  | var v     => v.toString
  | add e1 e2 => "(" ++ print e1 ++ "+" ++ print e2 ++ ")"
  | mul e1 e2 => "(" ++ print e1 ++ "*" ++ print e2 ++ ")"

#eval print expr1

-- ---------------------------------------------------------------------
-- Parsing
-- ---------------------------------------------------------------------

def is_digit (ch : Char) : Bool := '0' ≤ ch && ch ≤ '9'

/-- The longest initial segment whose elements satisfy `p`, and the
rest of the list. -/
def get_while (p : α → Bool) : List α → List α × List α
  | y :: ys =>
      if p y then
        let (zs, rest) := get_while p ys
        (y :: zs, rest)
      else
        ([], y :: ys)
  | [] => ([], [])

def get_digits : List Char → List Char × List Char := get_while is_digit

/-- An integer: a sequence of digits, with an optional `-` at the start. -/
def get_int : List Char → List Char × List Char
  | [] => ([], [])
  | y :: ys =>
      if y == '-' then
        let (n, rest) := get_digits ys
        (y :: n, rest)
      else
        get_digits (y :: ys)

/-- A list of digits, with an optional `-`, as an `Int`. -/
def list_to_int (chars : List Char) : Int :=
  match chars with
  | '-' :: rest => -1 * worker rest.reverse
  | xs          => worker xs.reverse
where
  worker : List Char → Int
    | []      => 0
    | d :: ds => (d.toNat - '0'.toNat : Int) + 10 * worker ds

/-- `get_while` never makes the list longer. -/
theorem get_while_length (p : α → Bool) (xs : List α) :
    (get_while p xs).2.length ≤ xs.length := by
  induction xs with
  | nil => simp [get_while]
  | cons y ys ih => by_cases h : p y <;> simp [get_while, h] <;> omega

/-- ... and so neither does `get_int`. -/
theorem get_int_length (xs : List Char) : (get_int xs).2.length ≤ xs.length := by
  cases xs with
  | nil => simp [get_int]
  | cons y ys =>
      by_cases h : y = '-'
      · have := get_while_length is_digit ys
        simp [get_int, h, get_digits]; omega
      · simpa [get_int, h, get_digits] using get_while_length is_digit (y :: ys)

/-- `parse`, returning the result together with the fact that what is
left of the string is no longer than the string itself. Lean needs that
fact to see that the second recursive call, on `rest2`, is on a shorter
string: `rest2` is what the first call left, minus the operator.

What is left can be the whole string: on a character that is not a
letter, a digit or `-`, an empty number is read, as in the Haskell, so
`parse "+"` gives `num 0` with `"+"` left. -/
def parse' (s : List Char) : Option {p : Expr × List Char // p.2.length ≤ s.length} :=
  match s with
  | '(' :: rest =>
      match parse' rest with
      | none => none
      | some ⟨(e1, rest1), h1⟩ =>
          have h1' : rest1.length ≤ rest.length := h1
          match rest1, h1' with
          | op :: rest2, h1 =>
              have : rest2.length < ('(' :: rest).length := by simp at h1 ⊢; omega
              match parse' rest2 with
              | none => none
              | some ⟨(e2, rest3), h3⟩ =>
                  have h3' : rest3.length ≤ rest2.length := h3
                  match op, rest3, h3' with
                  | '+', ')' :: rest4, h3 => some ⟨(add e1 e2, rest4), by simp at *; omega⟩
                  | '*', ')' :: rest4, h3 => some ⟨(mul e1 e2, rest4), by simp at *; omega⟩
                  | _, _, _ => none
          | [], _ => none
  | ch :: rest =>
      if 'a' ≤ ch && ch ≤ 'z' then
        some ⟨(var ch, rest), by simp⟩
      else
        some ⟨(num (list_to_int (get_int (ch :: rest)).1), (get_int (ch :: rest)).2),
              get_int_length _⟩
  | [] => none
termination_by s.length

/-- A fully bracketed expression at the start of the string, and the
rest of the string; `none` where the Haskell `parse` would fail. -/
def parse (s : List Char) : Option (Expr × List Char) := (parse' s).map (·.1)

#eval parse "(-55*e)+1111)".toList

/-- All the variables in an expression are lower case. -/
def lowerVars : Expr → Bool
  | num _     => true
  | var v     => 'a' ≤ v && v ≤ 'z'
  | add e1 e2 => lowerVars e1 && lowerVars e2
  | mul e1 e2 => lowerVars e1 && lowerVars e2

/-- What can follow an expression without changing how it is parsed:
nothing, or a character that is not a digit. -/
def okNext : List Char → Bool
  | []     => true
  | c :: _ => !is_digit c

/-- Parsing what has been printed gives back the expression, with the
rest of the string left over.

Both conditions are needed. An upper-case variable prints as itself, as
in `print (var 'A') = "A"`, but `parse` reads it as the number 0: try
`#eval parse (print (var 'A')).toList`. And if a number is followed by
a digit, the two are read together: `num 1` followed by `"2"` is read as
`num 12`.

Hints:
- Induction on `e`, generalizing `rest`. In the `add` and `mul` cases,
  use the induction hypotheses with the `rest` that follows each
  subexpression: `'+' :: ...` (or `'*'`) after `e1`, and `')' :: rest`
  after `e2`.
- `parse` is `parse'` without the proof, so it helps first to show that
  `parse s = some (e, r)` exactly when `parse' s` returns `(e, r)`
  together with some proof.
- `parse'` returns a proof that depends on its argument, so rewriting
  that argument inside `parse' s = ...` fails with "motive is not type
  correct". Instead, rewrite `(print e).toList ++ rest` into a list
  starting with `'('` while the goal is still about `parse`, and only
  then unfold, with `rw [parse, parse'.eq_def]`.
- `String.toList_append` turns `(s ++ t).toList` into
  `s.toList ++ t.toList`.
- The `num` case is the hardest, and needs some lemmas of its own.
  `toString n` for `n : Int` is `n.repr`: the digits of `n.natAbs`, with
  `"-"` in front if `n` is negative. From the library:
  `Nat.toList_repr` says that `n.repr.toList = Nat.toDigits 10 n`;
  `Nat.isDigit_of_mem_toDigits` says that these are all digits; and
  `Nat.toDigits_eq_ite` splits off the last digit, for an induction on
  `n` with `Nat.strongRecOn` that shows `list_to_int` gives back `n`. -/
theorem parse_print_gen (e : Expr) (hv : lowerVars e) (rest : List Char)
    (hr : okNext rest) :
    parse ((print e).toList ++ rest) = some (e, rest) := by
  sorry

/-- Parsing a printed expression gives it back. -/
theorem parse_print (e : Expr) (hv : lowerVars e) :
    parse (print e).toList = some (e, []) := by
  sorry

-- ---------------------------------------------------------------------
-- Evaluation
-- ---------------------------------------------------------------------

abbrev Env := List (Char × Int)

def env1 : Env := [('a', 12), ('b', -11)]

def lookup (v : Char) : Env → Int
  | []            => 0
  | (x, n) :: ps  => if x == v then n else lookup v ps

def eval (env : Env) : Expr → Int
  | num n     => n
  | var v     => lookup v env
  | add e1 e2 => eval env e1 + eval env e2
  | mul e1 e2 => eval env e1 * eval env e2

#eval eval env1 expr1

-- ---------------------------------------------------------------------
-- Compiler and virtual machine
-- ---------------------------------------------------------------------

/-- `push n` pushes `n`; `fetch v` pushes the value of `v`; `add2` and
`mul2` pop the top two elements, and push their sum or product. -/
inductive Instr where
  | push  : Int → Instr
  | fetch : Char → Instr
  | add2  : Instr
  | mul2  : Instr

open Instr

abbrev Program := List Instr

abbrev Stack := List Int

def compile : Expr → Program
  | num n     => [push n]
  | var v     => [fetch v]
  | add e1 e2 => compile e2 ++ compile e1 ++ [add2]
  | mul e1 e2 => compile e2 ++ compile e1 ++ [mul2]

/-- Execute the instructions, and when they run out, return the top of
the stack: `none` if the stack runs out first. -/
def run : Program → Env → Stack → Option Int
  | push n :: cont,  env, stack             => run cont env (n :: stack)
  | fetch v :: cont, env, stack             => run cont env (lookup v env :: stack)
  | add2 :: cont,    env, n1 :: n2 :: rest  => run cont env ((n1 + n2) :: rest)
  | mul2 :: cont,    env, n1 :: n2 :: rest  => run cont env ((n1 * n2) :: rest)
  | [],              _,   n :: _            => some n
  | _,               _,   _                 => none

/-- Compile then run: this should be the same as `eval`. -/
def execute (env : Env) (e : Expr) : Option Int :=
  run (compile e) env []

#eval execute env1 expr1

/-- Running the code for `e`, then `cont`, is running `cont` with the
value of `e` pushed on the stack. This is the general form of
`execute_eval` below, needed because `run` takes the rest of the program
and the stack as arguments; compare `shunt` in Chapter9.lean. Hint:
induction on `e`, generalizing `cont` and `stack`; `List.append_assoc`
is useful. -/
theorem run_compile (env : Env) (e : Expr) (cont : Program) (stack : Stack) :
    run (compile e ++ cont) env stack = run cont env (eval env e :: stack) := by
  sorry

/-- Compiler correctness. -/
theorem execute_eval (env : Env) (e : Expr) :
    execute env e = some (eval env e) := by
  sorry

-- ---------------------------------------------------------------------
-- Simplification
-- ---------------------------------------------------------------------

def size : Expr → Nat
  | num _     => 1
  | var _     => 1
  | add e1 e2 => 1 + size e1 + size e2
  | mul e1 e2 => 1 + size e1 + size e2

/-- `e'` is `e` unchanged, or is smaller than `e`. -/
def NoBigger (e' e : Expr) : Prop := e' = e ∨ size e' < size e

theorem smaller_of_changed {s1 e1 s2 e2 : Expr}
    (h1 : NoBigger s1 e1) (h2 : NoBigger s2 e2) (h : ¬(s1 = e1 ∧ s2 = e2)) :
    size s1 + size s2 < size e1 + size e2 := by
  unfold NoBigger at h1 h2
  rcases h1 with h1 | h1 <;> rcases h2 with h2 | h2 <;> simp_all <;> omega

theorem noBigger_trans {a b c : Expr} (h1 : NoBigger a b) (h2 : size b < size c) :
    NoBigger a c := by
  unfold NoBigger at *
  right
  rcases h1 with h1 | h1
  · subst h1; exact h2
  · omega

/-- `simplify`, returning the simplified expression together with the
fact that it is no bigger. The equations are the Haskell ones, in the
same order; the proofs in `⟨_, _⟩` and the `have hlt` are what Lean
needs to see that the recursion terminates. -/
def simp' (e : Expr) : {e' : Expr // NoBigger e' e} :=
  match e with
  | add e1 (num 0)      => let r := simp' e1; ⟨r.1, noBigger_trans r.2 (by simp [size] <;> omega)⟩
  | add (num 0) e2      => let r := simp' e2; ⟨r.1, noBigger_trans r.2 (by simp [size] <;> omega)⟩
  | add (num n) (num m) => ⟨num (n + m), Or.inr (by simp [size])⟩
  | mul e1 (num 1)      => let r := simp' e1; ⟨r.1, noBigger_trans r.2 (by simp [size] <;> omega)⟩
  | mul (num 1) e2      => let r := simp' e2; ⟨r.1, noBigger_trans r.2 (by simp [size] <;> omega)⟩
  | mul _ (num 0)       => ⟨num 0, Or.inr (by simp [size] <;> omega)⟩
  | mul (num 0) _       => ⟨num 0, Or.inr (by simp [size] <;> omega)⟩
  | add e1 e2 =>
      let s1 := simp' e1
      let s2 := simp' e2
      if h : ¬(s1.1 = e1 ∧ s2.1 = e2) then
        have hlt : size (add s1.1 s2.1) < size (add e1 e2) := by
          have := smaller_of_changed s1.2 s2.2 h
          simp [size]; omega
        let r := simp' (add s1.1 s2.1)
        ⟨r.1, noBigger_trans r.2 hlt⟩
      else
        ⟨add s1.1 s2.1, Or.inl (by simp_all)⟩
  | mul e1 e2 =>
      let s1 := simp' e1
      let s2 := simp' e2
      if h : ¬(s1.1 = e1 ∧ s2.1 = e2) then
        have hlt : size (mul s1.1 s2.1) < size (mul e1 e2) := by
          have := smaller_of_changed s1.2 s2.2 h
          simp [size]; omega
        let r := simp' (mul s1.1 s2.1)
        ⟨r.1, noBigger_trans r.2 hlt⟩
      else
        ⟨mul s1.1 s2.1, Or.inl (by simp_all)⟩
  | e => ⟨e, Or.inl rfl⟩
termination_by size e
decreasing_by all_goals first | assumption | (simp [size] <;> omega)

def simplify (e : Expr) : Expr := (simp' e).1

#eval simplify expr2

/-- Simplifying doesn't change the value. Hint: prove it for `simp'`,
by `fun_induction simp' e`, which inducts along the recursion of
`simp'`, giving one case for each equation. The `let`s in `simp'` show
up as local definitions, `r✝ : ... := simp' e1`; `simp +zetaDelta`
unfolds them. -/
theorem simplify_eval (env : Env) (e : Expr) :
    eval env (simplify e) = eval env e := by
  sorry

end Expressions
