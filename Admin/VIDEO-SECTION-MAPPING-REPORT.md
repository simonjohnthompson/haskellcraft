# Exploring a section-level mapping of the lecture course (not adopted)

A finer-grained alternative to [VIDEO-CHAPTER-MAPPING-REPORT.md](VIDEO-CHAPTER-MAPPING-REPORT.md), prepared on request to see whether the same 91 videos (everything except Chapter 5's already-shipped 9) could be placed against the specific section — or, where confident, subsection — each one matches, rather than one block per chapter. **Not adopted**: Simon reviewed it and chose the chapter-level mapping instead. Kept here as a record of what was tried and why it didn't hold up, not as guidance for any future rollout.

The honest result is that precision drops sharply at this grain. The chapter-level mapping reached zero flagged rows after review; this one still has 26 of 91 (29%) marked as a guess worth a second look, concentrated in a few places:

- **Chapter 17's parsing case study** (6 videos — Language processing, Pretty printing, Evaluating expressions, Compilation and execution, Parsing, Taking things further) sits inside one long worked example (§Case study: parsing expressions) whose own subsection titles don't line up with these video titles at all — each video can be placed in the right *section* but not confidently in a subsection.
- **Two-part videos** (List Functions I/II, Regular expressions I/II, Infinite lists/Streams, Tournaments/Strategies) — which half covers which subsection is close to a coin flip from the title alone.
- A handful of individual videos (e.g. Chapter 1's early videos, "Proving properties of rotate" in Chapter 9) where two sections are equally plausible.

There's also a structural cost distinct from precision: placing `\webvideo` blocks at section granularity means a block lands *inside* most sections throughout every chapter file, rather than the single "Related videos online" block near the top that the Chapter 5 pilot shipped — more edit sites, and some sections interrupted mid-flow by a video box.

## Chapter 0 — Preface

- [Why learn functional programming?](https://youtu.be/dE4hB2TswIk) — front matter — no section to attach to
- [What is functional programming?](https://youtu.be/Gt6Jt95jRCg)
- [Four functional programming languages](https://youtu.be/qCzrH0yH9Q0)

## Chapter 1 — Introducing functional programming

**§ Expressions and evaluation**

- [Values, variables, equations and evaluation](https://youtu.be/ZjQSCmX5Fa0) **[check]** — could instead sit earlier, at §Definitions

**§ Function definitions**

- [A first exercise](https://youtu.be/1eO_8ERf-_s) **[check]** — no section is explicitly exercise-shaped; this is a guess

**§ Types**

- [Types](https://youtu.be/oWAg4785l0I) — exact match

**§ Two models of Pictures**

- [Pictures](https://youtu.be/RUyWgTcdNHs) **[check]** — could instead be the earlier §Pictures and functions

**No specific section**

- [Week 1 summary](https://youtu.be/m8H95JNvvvw) — end-of-chapter summary — no single section

## Chapter 2 — Getting started with Haskell programming

**§ Using Haskell in practice**

- [Getting started](https://youtu.be/c_CV5mEpNLc)

**§ Errors and error messages**

- [Interpreting ghci error messages](https://youtu.be/R8qEP-4D6jM) — exact match

## Chapter 3 — Basic types and definitions

**§ The Booleans: Bool**

- [Booleans](https://youtu.be/qUMYlt4SfIY)

**§ The Booleans: Bool — Defining Boolean functions**

- [Using Booleans](https://youtu.be/HwXGlkE5kiM) **[check]**

**§ The integers: Integer and Int**

- [Integers](https://youtu.be/QKHrI6iYpeI)

**§ Characters and strings**

- [Characters and Strings](https://youtu.be/kip5n-eZF1s) — exact match

**§ Floating-point numbers: Float**

- [Floats](https://youtu.be/rV4KwLOn9Og)

**§ Overloading**

- [Overloading](https://youtu.be/LZbuIuOA7AE) — exact match

**§ Syntax — Definitions and layout**

- [Layout](https://youtu.be/VO7qypEVNoU) **[check]** — could instead be §Recommended layout

**No specific section**

- [Week 2 summary](https://youtu.be/erpV8bzqJBQ) — end-of-chapter summary

## Chapter 4 — Designing and writing programs

**§ Where do I start? Designing a program in Haskell**

- [Where do I begin?](https://youtu.be/HiXQ-Rtcp4w) — exact match

**§ Solving a problem in steps: local definitions**

- [Local definitions](https://youtu.be/g2hy4F6xcwo)

**§ Solving a problem in steps: local definitions — Calculation with local definitions**

- [Using local definitions](https://youtu.be/wzK_ZF3Gl7k)

**§ Recursion**

- [Recursion](https://youtu.be/oN9JMtpSNmQ)

**§ Primitive recursion in practice**

- [Using primitive recursion](https://youtu.be/6uzFo543rbU) — exact match

**No specific section**

- [Week 3 summary](https://youtu.be/Pol5-QJfIIk) — end-of-chapter summary

## Chapter 5 — Data types, tuples and lists

*(already shipped at chapter level — not re-split here)*

## Chapter 6 — Programming with lists

**§ Haskell list functions in the Prelude**

- [List functions in Haskell](https://youtu.be/0YeEkR4fNO0) — exact match

**§ Generic functions: polymorphism**

- [Polymorphism](https://youtu.be/f8PNOJQwGEI) — exact match

**§ Generic functions: polymorphism — Polymorphism and overloading**

- [Polymorphism in practice](https://youtu.be/n2BUOUPB5IU)

**§ Finding your way around the Haskell libraries**

- [Types for finding functions](https://youtu.be/AmSpwZhXEnY)

**§ Haskell list functions in the Prelude — The importance of types**

- [List Functions I](https://youtu.be/VV2kITYmoY0) **[check]** — a guess at which half of the two-part video this is

**§ Haskell list functions in the Prelude — Further functions**

- [List functions II](https://youtu.be/OPQF4T7QySs) **[check]** — a guess at which half of the two-part video this is

**No specific section**

- [Week 5 summary](https://youtu.be/sanUo2LFJWM) — end-of-chapter summary

## Chapter 7 — Defining functions over lists

**§ Lists and list patterns**

- [Working with lists](https://youtu.be/up9mIAO1yRc) **[check]** — could instead be §Pattern matching revisited

**§ Pattern matching revisited**

- [How are lists built?](https://youtu.be/Vqai68WWw-I) **[check]** — could instead be §Lists and list patterns

**§ Primitive recursion over lists**

- [Defining functions over lists](https://youtu.be/cxsE83cOJVs) — matches the chapter's own title

**§ Finding primitive recursive definitions**

- [Standard functions over lists](https://youtu.be/vGqBbZJ_w6A) **[check]**

**§ General recursions over lists**

- [Other forms of recursion on lists](https://youtu.be/G_6hIDEJffc) — exact match

## Chapter 8 — Playing the game: I/O in Haskell

**§ Rock - Paper - Scissors: strategies**

- [Rock, Paper, Scissors](https://youtu.be/w74mCv0c_kU) — exact match

**§ Rock - Paper - Scissors: strategies — Strategies**

- [Tournaments](https://youtu.be/tw1kzG9Qb-g) **[check]** — no subsection names “tournaments” explicitly
- [Strategies](https://youtu.be/nNIJqIe9a0c) — exact subsection match

**§ Rock - Paper - Scissors: playing the game**

- [Playing the game using IO](https://youtu.be/JaKqewCUdmo) — exact match

**No specific section**

- [Week 6 summary](https://youtu.be/-CWOFtu3EJQ) — end-of-chapter summary

## Chapter 9 — Reasoning about programs

**§ Testing and proof**

- [Testing and proof](https://youtu.be/JX8xypBdj8I) — exact match

**§ Induction — A first example**

- [Proof by induction](https://youtu.be/Ov2Q4P3rMSE) **[check]**

**§ Further examples of proofs by induction**

- [Map and function composition proof](https://youtu.be/u1lBqTk_oOU)
- [Map and ++ proof](https://youtu.be/U6wfsPLE18g)

**§ Generalizing the proof goal**

- [Proving properties of rotate](https://youtu.be/77hw22QGWQY) **[check]** — could instead sit under §Further examples of proofs by induction

**No specific section**

- [Two exercises](https://youtu.be/wovScD1OwWY) **[check]** — general practice — no single section fits

**§ Definedness, termination and finiteness — Finiteness**

- [Finite, infinite and partial lists](https://youtu.be/hZ8mggMIIcQ)

## Chapter 10 — Generalization: patterns of computation

**§ Higher-order functions: functions as arguments**

- [Functions as data](https://youtu.be/cy-8wjlREE0)

**§ Folding and primitive recursion**

- [Fold functions](https://youtu.be/6D5atmysTxI) — exact match

## Chapter 11 — Higher-order functions

**§ Operators: function composition and application**

- [Operators over functions](https://youtu.be/HlMClQT7fSM) — exact match

**§ Expressions for functions: lambda abstractions**

- [Lambdas](https://youtu.be/dUsuSJUvoDA) — exact match

**§ Partial application**

- [Partial application and curried functions](https://youtu.be/_oS5fwzcQKE) **[check]** — title spans two sections — also covers §Under the hood: curried functions

## Chapter 12 — Developing higher-order programs

**§ Functions as data: recognising regular expressions**

- [Regular expressions I](https://youtu.be/vKWwv1b1UTU) — exact match
- [Regular expressions II](https://youtu.be/apHDTFTiZtI) **[check]** — same section as part I — a two-part video

**No specific section**

- [Week 8 summary](https://youtu.be/PrJghYuNc9c) — end-of-chapter summary

## Chapter 13 — Overloading, type classes and type checking

**§ Why overloading?**

- [Why overloading?](https://youtu.be/kRvAftsiiHg) — exact match

**§ Introducing classes**

- [Type classes](https://youtu.be/AgVZitfnFBk) — exact match

**§ A tour of the built-in Haskell classes**

- [Type class tour I](https://youtu.be/CJsTuA0p0CA) — exact match

**§ Signatures and instances**

- [Managing types](https://youtu.be/MICmFBuvx-0)

**§ Monomorphic type checking**

- [Monomorphic type checking](https://youtu.be/wFGzaFSFla0) — exact match

**§ Polymorphic type checking**

- [Polymorphic type checking](https://youtu.be/SHG7N6981u0) — exact match

**§ Polymorphic type checking — Unification**

- [Unification](https://youtu.be/MONHnc81q28) — exact subsection match

**§ Type checking and type inference: an overview — Overview**

- [Three type checking examples](https://youtu.be/josWP-e8k4k)

**§ Type checking and classes**

- [Type checking and type classes](https://youtu.be/pxA6b52UW8c) — exact match

**No specific section**

- [Week 9 summary](https://youtu.be/pFQpA3UKo3E) — end-of-chapter summary

## Chapter 14 — Algebraic types

**§ Recursive algebraic types — Trees of integers**

- [Recursive algebraic types](https://youtu.be/kcaEk3W64P8) — exact section match

**§ Recursive algebraic types — Rearranging expressions**

- [Functions on recursive types](https://youtu.be/49PGf2QczWg) **[check]**

**§ Polymorphic algebraic types**

- [Parametric types](https://youtu.be/e6NUkZzOYTE) — “parametric” = “polymorphic”

## Chapter 16 — Abstract data types

**§ Search trees — The abstract data type for search trees**

- [Search trees](https://youtu.be/gUqqXrYnZpc) — exact match

## Chapter 17 — Lazy programming

**§ Data-directed programming**

- [Language processing](https://youtu.be/sDqVAfdRB8o) **[check]** — introduces the parsing case study; exact subsection unclear

**§ Case study: parsing expressions**

- [Pretty printing](https://youtu.be/-INZ1i7hzzQ) **[check]** — case-study cluster — subsection unclear
- [Evaluating expressions](https://youtu.be/WhYpyIHjghA) **[check]** — case-study cluster — subsection unclear

**§ Case study: parsing expressions — The top-level parser**

- [Compilation and execution](https://youtu.be/SsWQXLl4F9c) **[check]**

**§ Case study: parsing expressions — Some basic parsers**

- [Parsing](https://youtu.be/5qvcafkuXlA) **[check]**

**§ Case study: parsing expressions — Conclusions**

- [Taking things further.](https://youtu.be/WtLojbr6HLQ) **[check]**

**No specific section**

- [Week 7 summary](https://youtu.be/ocDDDU8s8iM) — end-of-chapter summary
- [Week 10 summary](https://youtu.be/_I2itqlqz9k) — end-of-chapter summary

**§ Lazy evaluation**

- [Lazy evaluation](https://youtu.be/sqCETWi20Xs) — exact match

**§ Calculation rules and lazy evaluation**

- [Permutations](https://youtu.be/E_rbfw6Z1KM) **[check]** — a worked example; subsection unclear

**§ Why infinite lists?**

- [Infinite lists](https://youtu.be/9Xhw5i0laZY) — exact match
- [Streams](https://youtu.be/0XnM6t2I6YQ) **[check]** — same section as Infinite lists — a two-part video

**§ Case study: simulation**

- [Solving a maze](https://youtu.be/AJDi3Z06YqQ) — exact match

**§ Proof revisited**

- [Lazy evaluation and efficiency.](https://youtu.be/PpK5bG4DpXY) **[check]** — no subsection names “efficiency” explicitly

## Chapter 19 — Abstraction: functors, monads and folding

**§ Abstraction**

- [Abstraction](https://youtu.be/B1zHc5QtBNY) — exact match

**§ The Functor class**

- [Functor](https://youtu.be/s7vUod9_AM0) — exact match

**§ The Applicative class**

- [Applicative](https://youtu.be/pJf3q37uxbo) — exact match

**§ Monads: languages for functional programming — Monads, formally**

- [Monads](https://youtu.be/TB72Yn_mdKE)

**§ Example: monadic computation over trees**

- [Monads and computation](https://youtu.be/CU1iYIzP0uc) — exact match

**§ Folding over data: Foldable**

- [Foldable](https://youtu.be/J9-W6xJNG_E) — exact match

**No specific section**

- [Week 11 summary](https://youtu.be/IzTvAkWqzCM) — end-of-chapter summary

## Chapters with no matching video

Same five as the chapter-level report:

- Chapter 15 — Case study: Huffman codes
- Chapter 18 — I/O programming
- Chapter 20 — Domain-Specific Languages
- Chapter 21 — Time and space behaviour
- Chapter 22 — Conclusion

**[check]** = flagged as a guess worth a second look (26 of 91 rows).

