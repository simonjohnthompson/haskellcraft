# Lean step-by-step

## The logical model of Lean

Goal-directed proof: (sub-)goals with hypotheses. By default working backwards, but also possible to work forwards. Could give a simple example from propositional logic, but maybe that would confuse. If included, keep it to two lines in the same notation as the later proofs: `intro` to move a hypothesis into the context, then `exact` to close the goal with it.

Using `sorry` to mark what is not (yet) done.

A `sorry` spreads further than its warnings show. Lean warns only about a declaration that contains `sorry` itself, not about one that uses a theorem proved with `sorry`. So, in Expr.lean, `execute_eval` is accepted without a warning once it is proved from `run_compile`, even while `run_compile` is still `sorry`. `#print axioms execute_eval` shows what a theorem really rests on: `sorryAx` in the list means that there is a `sorry` somewhere underneath. (`propext` and the others that may appear are standard axioms of Lean's logic.)

In the Haskell examples, typically establishing (potentially conditional) equations on the basis of other (conditional) equations.

Theorems as functions, taken lightly:
- a theorem `∀ x, P x` can be applied to an argument, like a function, to give `P a`: `have := hyp ws`.
- this is also why a theorem can be proved by recursion, calling itself on smaller arguments, as in the `mutual` theorems for `GTree` in Chapter 14.

Proving that something does not hold: `¬ ∀ ...` is proved by `intro`, then giving a counterexample and deriving a contradiction. This pattern recurs: `area_not_nonneg` (Chapter 14), `reverse_append_fails` (Chapter 17) and `rev_rev_fails` (Chapter 17 additional).

## Using Lean in practice

Installation etc. and default view in VS Code.

`lake`: Lean's build tool and package manager, the counterpart of `cabal` or `stack` for Haskell. Installing Lean with `elan` (the counterpart of `ghcup`) installs `lake` too, and the version of Lean a project uses is fetched automatically the first time `lake` runs in it. The commands needed here, all run in the project folder (`Lean`):
- `lake build` builds and checks the whole project;
- `lake env lean File.lean` checks one file, and prints the output of its `#eval`s; `lake env` runs a command in the project's environment, so that its `import`s are found;
- `lake new` creates a new project, for anyone starting their own.

The project's files:
- `lakefile.toml` describes the project, and `lean-toolchain` pins the Lean version;
- the root file `HaskellCraft.lean` imports the others, so that `lake build` checks them all, while the editor checks only the open file;
- module names follow file paths: `HaskellCraft/Chapter9.lean` is `import HaskellCraft.Chapter9`.

Reading the infoview: this *is* the step-by-step view, so it comes before the proofs.
- the goal, after `⊢`, and the hypotheses above it;
- moving the cursor through a proof to see the state after each step;
- `case` tags (`case nil`, `case pos`), which name the goals;
- inaccessible names marked `✝`, which Lean gave to variables you didn't name, and how to name them;
- reading the common errors, especially "unsolved goals", which shows the goal still to be proved.

Finding out about things:
- `#check` for the type of a name or expression, `#print` for a definition, `#eval` to run a function;
- where to type `#eval`: there is no separate prompt, as there is with GHCi. `#eval` goes in a `.lean` file, on a line of its own at the top level (not inside a proof), after the definitions it uses. The result appears in the infoview when the cursor is on the line, and on hovering over it, and it is re-run whenever the file changes. To experiment without adding lines to the project's files, use a scratch file in the project folder that imports the file you want, e.g. `import HaskellCraft.Expr` then `open Expressions`, and leave it out of `HaskellCraft.lean` so that `lake build` ignores it. `lake env lean Scratch.lean` prints the results at the command line;
- `simp?` to see which lemmas `simp` used, and `exact?` to search for a lemma that closes the goal;
- naming conventions for library lemmas, such as `Nat.pow_le_pow_right` or `Nat.pow_add`, which make it possible to guess names.
- the library is worth looking in before proving something yourself: the parsing proof in Expr.lean uses lemmas about decimal digits such as `Nat.toList_repr` and `Nat.toDigits_eq_ite`.
- names change between versions of Lean. A deprecation warning, such as "`Nat.toDigits_eq_if` has been deprecated: Use `Nat.toDigits_eq_ite` instead", gives the new name; pinning the version in `lean-toolchain` keeps a project stable.

## Lean vs. Haskell

Totality and laziness. Give motivation.

Look at the proof chapters in haskellcraft: you can see that I had to be clear there about the scope of the results. These carry over straightforwardly to Lean. For the results in Chapters 9–14, which are about finite, defined values, all Lean needs is totality. Totality has two parts:
- functions must be defined on their whole domain: every case is covered;
- every recursion must terminate (see `termination_by` below).

Lean does have `partial def` for functions it can't show terminate, but nothing can be proved about them.

What about laziness? It has two consequences.

First, function applications are evaluated in a different order: start evaluating the body, and only evaluate the arguments when computation requires it (and then only to the extent that allows computation to continue). Lean, like most languages, is strict: arguments are evaluated first.

Evaluation order matters less than it might, because of a property that is not a given for every language: values are independent of evaluation order (confluence, or Church–Rosser). If two orders of evaluation both give a value, it is the same value.
- In Lean every function is pure and total, so every order gives the same result. This is what makes equational reasoning sound: `rw` can replace equals by equals anywhere in a term, without asking when that subterm would be evaluated.
- In Haskell, which is pure but not total, evaluation order can change *whether* there is a value, but not *which* value. Lazy evaluation terminates whenever any order does (the standardization theorem); strict evaluation can loop where lazy evaluation succeeds, as with `const 17 undef`.
- Caveats in Haskell: `unsafePerformIO` makes evaluation order observable; and `seq` distinguishes `undefined` from `\x -> undefined x`, so eta-equivalence, and with it extensionality as stated in Chapter 11, holds only for defined functions. Lean's escape hatches (`unsafe`, `IO`, `implemented_by`) only affect compiled code run by `#eval`, never what can be proved.

Second, laziness removes the dichotomy evaluated/unevaluated, and this has the consequence that the types contain extra values: data structures can be partial or infinite, as well as undefined. Lean's `inductive` types contain only finite, fully defined values, so these require a different treatment in Lean: in Chapter 17, `PList` for finite and partial lists. (Infinite lists are a stream type, in Streams.lean, not covered here.)

Numbers:
- `Nat` and `Int` are different types; subtraction on `Nat` stops at 0, so `3 - 5 = 0`;
- patterns on `Nat` use `n + 1` where Haskell definitions often use `n - 1` in the body;
- `Float` is machine floating point, with no algebraic laws, so nothing can be proved about it (hence the change to `Shape` in Chapter 14 additional).

Strings: in Haskell `String` is `[Char]`, but in Lean `String` is a type of its own. `s.toList` turns it into a `List Char`, and `String.toList_append` says that `(s ++ t).toList = s.toList ++ t.toList`. In Expr.lean, `print` produces a `String` and `parse` takes a `List Char`, so the round-trip theorem is about `(print e).toList`.

Design decisions in the Lean files:
- functions are redefined from scratch (`myMap`, `+++`, ...) rather than using Lean's own, so that the proofs use the book's defining equations, not library lemmas that already prove the results;
- the project doesn't use Mathlib, Lean's large mathematical library. It keeps the project small and self-contained; Mathlib would add many more lemmas and stronger automation, at the cost of a large dependency.

## Syntax in Lean

Use of Greek and mathematical symbols. Input by means of shortcuts `\a` or `\alpha` etc. 

Insert or link to a reference table. 

## Definitions in Lean

This gives information about how to transliterate definitions from Haskell into Lean.

Could give a table of correspondences in syntax.

Particular points to note for value definitions. Give examples where necessary.
 - Definitions use `:=` rather than `=` which is the logical equality, and `==` which is Boolean equality.
 - `:=` is omitted in definitions by pattern matching over inductive types
 - In such definitions parameters are separated by commas (which would not be the case in Haskell).
 - Only the arguments after the colon are pattern-matched: in `def myMap (f : α → β) : List α → List β`, `f` is a fixed parameter, and the cases match on the list.
 - And case values follow `=>`.
 - Local definitions allowed too.
 - Types have to be declared. There is polymorphism and type classes. See examples.
 - Type parameters can be implicit.
 - DIY infix allowed, with a precedence and associativity, as in `infixr:65 " +++ " => myAppend`. Precedence matters, and can differ from Haskell's: in Lean `::` (precedence 67) binds more tightly than our `+++` (65), so `w :: xs +++ ys` means `(w :: xs) +++ ys`; in Haskell `:` and `++` are both `infixr 5`, so `w : xs ++ ys` means `w : (xs ++ ys)`. The two terms have the same value, but they are different terms, and a proof has to deal with the one actually written (see `filter_append` in AdditionalChapter14). `set_option pp.parens true` makes Lean print all the brackets.

Termination
- `termination_by` in the case of non-structural recursion, with `decreasing_by` to prove that each recursive call decreases the measure.
- Three levels, depending on where the arguments of the recursive calls come from:
  1. Structural recursion: each call is on a piece of the input, got by pattern matching on it (`xs` in `x :: xs`). This is a check on the program text, not on sizes, and Lean accepts it with no proof. Most of the functions in Chapters 9–14.
  2. Well-founded recursion with a measure: a call's argument is not a piece of the input, but is built from pieces of it, with constructors or with functions already defined. In `assoc` (Chapter 14), `assoc (add e1 (add e2 e3))` is built from `e1`, `e2` and `e3`, so the measure `(size, leftAdds)` of the new argument can be computed from the definitions of `size` and `leftAdds` alone, and `decreasing_by` needs nothing about `assoc` itself. (`assoc` does use the results of recursive calls, in `add (assoc e1) (assoc e2)`, but only in its answer, never as the argument of another call.)
  3. Nested recursion: a call's argument depends on the *result* of an earlier recursive call, as in `simplify (Add s1 s2)` with `s1 = simplify e1`, or `parse rest2` with `rest2` from the result of `parse rest` (Expr.lean). Showing that the argument is smaller needs a fact about what the function returns: that `simplify` never makes an expression bigger, that `parse` never returns a longer string. Lean can't use a theorem about a function while defining it, so the fact goes into the definition: `simp'` and `parse'` return their result together with a proof of it. The classic example is McCarthy's 91 function, `f n = if n > 100 then n - 10 else f (f (n + 11))`.
- Quicksort is an example of level 2: `filter (< x) xs` is no longer than `xs`, but it is not a piece of it. Showing that it is shorter than `x :: xs` needs a lemma about `filter`, but that is fine, because `filter` is already defined; it is facts about the function being defined that force level 3.
- Alternatives to level 3 that make the recursion structural: fuel (an extra `Nat` argument that goes down by one each call; every theorem then needs a proof that there was enough fuel), or a different algorithm (for parsing, a shift-reduce parser that reads one character at a time).

Subtypes: `{x : α // P x}` is the type of values `x` together with a proof of `P x`. A value of it is built with `⟨value, proof⟩`, and the value is taken out with `.1` (or `.val`). This is how `simp'` and `parse'` in Expr.lean carry the fact that their termination depends on: `parse'` returns `{p : Expr × List Char // p.2.length ≤ s.length}`, and `parse` takes the `.1` part.

Type definitions.
 - `inductive`
 - the role of `open` here
 
Structuring
- need to say something about `namespace`s
- `open` in general
- projects and modules: see `lake` in "Using Lean in practice"

## Propositions, Booleans and equality

`Prop` and `Bool`: more than `=` versus `==`.
- `=` gives a proposition, which may not be decidable; `==` gives a Boolean, computed by the type's `BEq` instance.
- an `if` on a `Bool` is turned into an `if` on a `Prop`: `if b then ...` means `if b = true then ...`.
- decidability: an `if` on a proposition needs it to be decidable; `deriving DecidableEq` gives this for a new type.
- `simp` turns `(a == b) = true` into `a = b` (the lemma `beq_iff_eq`), so after `simp` tests appear as `=`. This needs `LawfulBEq`, which says that `==` agrees with `=` (Chapter 9 additional).

`decide` has two roles, which are closely related.
- The tactic `decide` proves a proposition by computing it. This works when the proposition is decidable (there is a `Decidable` instance: an algorithm that answers true or false) and has no variables: Lean runs the algorithm, and an answer of `true` is a proof. In the parsing proof in Expr.lean it settles facts about constants: `1 < 10` and `10 ≤ 10`, the conditions for base 10 in library lemmas such as `Nat.toDigits_eq_ite`, and `'-' ≠ '('`, which compares character codes.
- The function `decide : (p : Prop) → [Decidable p] → Bool` turns a decidable proposition into a `Bool`. It appears in goals such as `if (decide ('a' ≤ c) && decide (c ≤ 'z')) = true then ...`: writing `'a' ≤ ch && ch ≤ 'z'` combines two propositions with the Boolean `&&`, so Lean inserts `decide` to turn each into a `Bool`, then `= true` to turn the result back into a proposition for the `if`. This is the `Prop`/`Bool` boundary in the opposite direction from the coercion of a `Bool` to `b = true`.
- Limits of the tactic: it can't deal with variables. `'-' ≠ '('` can be decided, but `c ≠ '('` for an arbitrary digit `c` can't, as there is nothing to compute, so it needs a proof (`digit_not_letter` in Expr.lean). It also needs the algorithm to exist: it fails on `Temp`, which has no `DecidableEq`. And sometimes the computation gets stuck when Lean runs it while checking the proof; `decide +kernel` does the computation in Lean's kernel instead, as was needed for `Rat`.

Equality:
- `rfl` proves `a = a`, and also `a = b` when `a` and `b` compute to the same thing (definitional equality), as in `weather_newWeather`.
- different constructors of an inductive type are never equal, and a constructor is injective: from `cons x xs = cons y ys` follow `x = y` and `xs = ys`. `simp` knows both facts (from lemmas such as `List.cons.injEq`, and a built-in rule for different constructors), which is how it finishes counterexample proofs. The tactic `injection` and the principle `noConfusion` are the explicit versions.

## First steps

Introduce each tactic where it first appears; later lists only mention new uses. A table of all the tactics, with where each first appears, could go at the end.

Chapter 9
- `by`
- `induction ... with`  
- the induction hypothesis
- `simp` 
- `simp only`
- `simp [f]` uses `f`'s defining equations, which Lean names `f.eq_1`, `f.eq_2`, ...: these are the book's labels, (sum.1), (sum.2) and so on. This is the main link between the book's proofs and the Lean ones.
- `omega`
- sequencing of steps

Chapter 9 additional
- `induction ... generalizing ... with`
- `cases`
- `<;>`
- `constructor` (used on `\and` goal)
- `simp_all`
- `intro`

Chapter 11
- `funext`
- `exact`

Chapter 11 additional
- application of theorems to specialise them, with explicit arguments, as in `foldr_append (· + ·) 0 ...`
- `.symm`, to use an equation the other way round
- `have`
- `simp ... at h`, to simplify a hypothesis rather than the goal; needed when the induction hypothesis is stated with `∘'`
- `by_cases h : p` splits the goal on whether the proposition `p` holds, with `h : p` in one case and `h : ¬p` in the other. Not to be confused with `cases`, which creates goals by splitting on a value of an inductive type (or on a hypothesis such as `A ∨ B`), or with `case tag =>`, which picks one existing goal by its tag, such as `case pos` after `by_cases`.

Chapter 14
- induction over `inductive`
- multiple induction hypotheses
- `split`
- `rw`
- `rw` with an equation from overlapping patterns leaves a side goal: the condition under which that equation applies (`eval_assoc`, `case2`)
- `induction ... using assoc.induct`: functional induction, following the recursion of `assoc` rather than the structure of the type; the main new idea in `eval_assoc`
- dot notation: three different things to separate.
  - `·` as a bullet, focusing on one goal.
  - `·` as the gap in an anonymous function, as in `(x + ·)`, which is `fun y => x + y`, Haskell's section `(x +)`.
  - `.` for field notation, as in `(index xs n).map f`, which is `Option.map f (index xs n)`.
  - The first two are the same character, typed `\.`.

Chapter 14 additional
- `rfl`
- `grind`, briefly: what it does, and that its arithmetic is linear only
- `¬ ∀ ...` proved by a counterexample (see "The logical model")
- `mutual` induction and the explicit recursive call of theorems.

Chapter 17
- induction with three cases: the extra base case `undef`
- `Option` for undefined results, with `<$>` (`fmap`) and `>>=`
- `congr`

Chapter 17 additional
- `induction ... generalizing` and `cases n` on `Nat`, to use the hypothesis at a smaller index (`map_index`)
- `cases ys with` inside an induction case, splitting on a second list (`zipWith_index`)
- two `by_cases` combined with `<;>`, giving four cases (`filter_filter`)
-  ignoring the streams stuff for the moment

Expr (Expr.hs in Lean)
- `fun_induction f e`: induction following the recursion of `f`, like `induction ... using assoc.induct` in Chapter 14. There is one case for each equation of `f`, named `case1`, `case2`, ... in the order of the equations, not after constructors.
- naming in `| caseN ... =>`: the names bind in order, first the variables of that equation, then its local definitions (`let`s), then the induction hypotheses. In `simplify_eval`, `| case1 e1 r ih =>` names `e1`, then `r := simp' e1`, then the hypothesis. Giving too few names leaves the later ones unnamed (shown with `✝`), and giving one name for each of the first two makes the second one the `let`, not the hypothesis, which is an easy mistake to make. The infoview shows which is which.
- `simp +zetaDelta` unfolds local definitions such as `r := simp' e1`, which `simp` otherwise leaves alone; `exact` unfolds them anyway when it checks that two things are the same.
- a wildcard alternative, `| _ => sorry`, as the last case of `induction ... with`, `cases ... with` or `fun_induction ... with`, covers every case not yet given. It is the way to work through the cases one at a time: add each case above it. A lone `sorry` after the alternatives doesn't work, because there are no goals left there; Lean reports the missing cases instead.
- unfolding a function defined by well-founded recursion, such as `parse'`: `simp [parse']` doesn't unfold it one step, but `rw [parse'.eq_def]` does. The `match` or `if` in its definition then appears in the goal, and `split` divides the goal into one case for each branch.
- "motive is not type correct": when the type of a term depends on a value, rewriting that value fails with this error. `parse'` returns a proof about its argument `s`, so `rw` can't change `s` inside `parse' s = ...`. The fix is to rewrite first, while the goal is still about `parse`, and only then unfold to `parse'`. The message doesn't explain itself, so it is worth knowing.
- logic tactics, for `∧`, `∃` and `↔`:
  - `obtain ⟨_, h⟩ := e` takes apart a fact `e` that is an `∃` or an `∧`;
  - `rintro rfl` introduces an equation `x = a` and replaces `x` by `a` everywhere, as in proving `c ≠ '('` from what is known about `c`;
  - `refine ⟨?_, ?_, ?_⟩` splits a goal `A ∧ B ∧ C` into three goals;
  - `h.mp` and `h.mpr` use one direction of `h : A ↔ B`, as with `parse_eq_some`.
- strong induction: `induction n using Nat.strongRecOn` gives a hypothesis for every smaller number, not just `n - 1`. It is needed in `worker_toDigits`, where the hypothesis is used at `n / 10`.
- `show`, to restate the goal in a form that is equal by definition, as in the negative case of `parse_num`.
- `rename_i`, to name the variables that `split` and other tactics introduce unnamed (shown with `✝`).

## Finding and structuring proofs

Test before proving. Before stating the round-trip theorem in Expr.lean, it was run with `#eval` on every integer from −2000 to 2000, every lower-case variable, and some larger expressions. That is how the condition on variables was found: `var 'A'` prints as `"A"`, which parses as the number 0. This is the book's advice from Chapter 9, to QuickCheck a property before trying to prove it, carried over to Lean. There are also property-testing libraries for Lean, such as Plausible.

Generalizing the statement. Some theorems can't be proved by induction as they stand, but can be once generalized: `shunt` in Chapter 9, and in Expr.lean `run_compile` for compiler correctness and `parse_print_gen` for the round trip. Generalizing can bring new hypotheses with it: `parse_print_gen` adds an arbitrary `rest` after the expression, and then needs `okNext rest`, that `rest` doesn't start with a digit, since otherwise `num 1` followed by `"2"` would be read as `num 12`. Each induction hypothesis is then used with a particular `rest`: the text that follows that subexpression.

Lemmas. A long proof is easier as a series of lemmas, each simple: the round trip takes about a dozen, for digits, for numbers, and for `parse` in terms of `parse'`, before the main induction.

## Automation

What each automatic tactic does, and doesn't do:
- `simp`: rewriting with equations and simp lemmas;
- `omega`: linear arithmetic over `Nat` and `Int`;
- `decide`: decidable propositions, by computation;
- `grind`: combines these and more, but its failures are harder to read.

The tension with the book: automation makes proofs short, but hides the steps that the book shows. The alternative is to write proofs step by step, with `rw` or `calc`, so that they follow the book's chains of equations; see `Admin/LEAN-PROOF-VISUALIZATION-REPORT.md`.
