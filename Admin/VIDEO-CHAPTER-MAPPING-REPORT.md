# Mapping the YouTube lecture course to book chapters

Prepared to drive the `\webvideo`/`\begin{webvideos}` rollout (`Book/webdefs.tex`, piloted on Chapter 5 in commit `aa5d27e`) across the rest of the book: which of the [*Introduction to functional programming*](https://www.youtube.com/playlist?list=PLqu19-ygE4ocMda7XgriK0BHL8vmlyKPU) playlist's 100 videos belongs in which chapter's "Related videos online" block. This is the **confirmed, adopted mapping** — one video list per chapter, reviewed chapter-by-chapter in conversation until every row was either an exact/near-exact match to the chapter's own title or section headings, or explicitly confirmed by Simon against a genuine toss-up. No row in this report is an unreviewed guess.

The playlist groups its 100 videos into 11 "weeks" plus 6 trailing, unlabelled videos. Week boundaries were a useful starting prior but not authoritative — several weeks span two or three chapters, and a handful of videos moved against their week's grouping where their title was a clear match for a different chapter's section (e.g. "Testing and proof", filed under the same week as Chapter 6's videos in the playlist, moved to Chapter 9, whose own section is titled exactly that). A finer section/subsection-level attempt at this mapping was also prepared and is kept as a companion report, [VIDEO-SECTION-MAPPING-REPORT.md](VIDEO-SECTION-MAPPING-REPORT.md) — it was not adopted: precision drops sharply at that grain (just over a quarter of rows would need a second look, against zero here), and placing a block mid-section throughout each chapter is more disruptive to the chapter's own flow than the one `Related videos online` block per chapter that was actually built for Chapter 5.

**Chapter 5** ("Data types, tuples and lists") is already live — its 9 videos (all from the playlist's Week 4) were piloted and shipped before this wider review; listed below for completeness.

## Chapter 0 — Preface

- [Why learn functional programming?](https://youtu.be/dE4hB2TswIk) — moved here per feedback — general motivation, not chapter-specific
- [What is functional programming?](https://youtu.be/Gt6Jt95jRCg) — moved here per feedback
- [Four functional programming languages](https://youtu.be/qCzrH0yH9Q0) — moved here per feedback

## Chapter 1 — Introducing functional programming

- [Values, variables, equations and evaluation](https://youtu.be/ZjQSCmX5Fa0) — matches §Expressions and evaluation / §Calculation and evaluation
- [A first exercise](https://youtu.be/1eO_8ERf-_s) — confirmed
- [Types](https://youtu.be/oWAg4785l0I) — exact match: §Types
- [Pictures](https://youtu.be/RUyWgTcdNHs) — moved here per feedback — matches §Pictures and functions / §Two models of Pictures
- [Week 1 summary](https://youtu.be/m8H95JNvvvw) — moved here per feedback

## Chapter 2 — Getting started with Haskell programming

- [Getting started](https://youtu.be/c_CV5mEpNLc) — matches the chapter's own title
- [Interpreting ghci error messages](https://youtu.be/R8qEP-4D6jM) — moved here per feedback — matches §Errors and error messages

## Chapter 3 — Basic types and definitions

- [Booleans](https://youtu.be/qUMYlt4SfIY)
- [Using Booleans](https://youtu.be/HwXGlkE5kiM)
- [Integers](https://youtu.be/QKHrI6iYpeI)
- [Characters and Strings](https://youtu.be/kip5n-eZF1s)
- [Floats](https://youtu.be/rV4KwLOn9Og)
- [Overloading](https://youtu.be/LZbuIuOA7AE)
- [Layout](https://youtu.be/VO7qypEVNoU) — matches §Syntax
- [Week 2 summary](https://youtu.be/erpV8bzqJBQ)

## Chapter 4 — Designing and writing programs

- [Where do I begin?](https://youtu.be/HiXQ-Rtcp4w) — matches §Where do I start?
- [Local definitions](https://youtu.be/g2hy4F6xcwo)
- [Using local definitions](https://youtu.be/wzK_ZF3Gl7k)
- [Recursion](https://youtu.be/oN9JMtpSNmQ)
- [Using primitive recursion](https://youtu.be/6uzFo543rbU) — matches §Primitive recursion in practice
- [Week 3 summary](https://youtu.be/Pol5-QJfIIk)

## Chapter 5 — Data types, tuples and lists

*(already live — commit `aa5d27e`)*

- [Compound types](https://youtu.be/bsXSlDP-VHc)
- [Tuple types](https://youtu.be/seXEFQn2vnc)
- [Fibonacci numbers](https://youtu.be/5o-hvSp2cPM)
- [Enumerated data types](https://youtu.be/AWAN5Y3_JcE)
- [Data types and constructors](https://youtu.be/JOmPAOrMyEU)
- [Data types in general](https://youtu.be/XrtOkNcAsms)
- [Introducing lists](https://youtu.be/SUvrl3FWH-M)
- [List comprehensions](https://youtu.be/sVNRYyrCb6s)
- [Week 4 summary](https://youtu.be/gTUxHHg4rw0)

## Chapter 6 — Programming with lists

- [List functions in Haskell](https://youtu.be/0YeEkR4fNO0) — matches §Haskell list functions in the Prelude
- [Polymorphism](https://youtu.be/f8PNOJQwGEI) — matches §Generic functions: polymorphism
- [Polymorphism in practice](https://youtu.be/n2BUOUPB5IU)
- [Types for finding functions](https://youtu.be/AmSpwZhXEnY) — matches §Finding your way around the Haskell libraries
- [List Functions I](https://youtu.be/VV2kITYmoY0)
- [List functions II](https://youtu.be/OPQF4T7QySs)
- [Week 5 summary](https://youtu.be/sanUo2LFJWM)

## Chapter 7 — Defining functions over lists

- [Working with lists](https://youtu.be/up9mIAO1yRc)
- [How are lists built?](https://youtu.be/Vqai68WWw-I)
- [Defining functions over lists](https://youtu.be/cxsE83cOJVs) — matches the chapter's own title
- [Standard functions over lists](https://youtu.be/vGqBbZJ_w6A) — matches §Primitive recursion over lists
- [Other forms of recursion on lists](https://youtu.be/G_6hIDEJffc) — matches §General recursions over lists

## Chapter 8 — Playing the game: I/O in Haskell

- [Rock, Paper, Scissors](https://youtu.be/w74mCv0c_kU) — matches §Rock-Paper-Scissors: strategies
- [Tournaments](https://youtu.be/tw1kzG9Qb-g)
- [Strategies](https://youtu.be/nNIJqIe9a0c)
- [Playing the game using IO](https://youtu.be/JaKqewCUdmo) — matches §Rock-Paper-Scissors: playing the game
- [Week 6 summary](https://youtu.be/-CWOFtu3EJQ)

## Chapter 9 — Reasoning about programs

- [Testing and proof](https://youtu.be/JX8xypBdj8I) — confirmed — exact match: §Testing and proof
- [Proof by induction](https://youtu.be/Ov2Q4P3rMSE) — matches §Induction
- [Map and function composition proof](https://youtu.be/u1lBqTk_oOU) — matches §Further examples of proofs by induction
- [Proving properties of rotate](https://youtu.be/77hw22QGWQY)
- [Map and ++ proof](https://youtu.be/U6wfsPLE18g)
- [Two exercises](https://youtu.be/wovScD1OwWY)
- [Finite, infinite and partial lists](https://youtu.be/hZ8mggMIIcQ) — matches §Definedness, termination and finiteness

## Chapter 10 — Generalization: patterns of computation

- [Functions as data](https://youtu.be/cy-8wjlREE0) — confirmed
- [Fold functions](https://youtu.be/6D5atmysTxI) — matches §Folding and primitive recursion

## Chapter 11 — Higher-order functions

- [Operators over functions](https://youtu.be/HlMClQT7fSM) — matches §Operators: function composition and application
- [Lambdas](https://youtu.be/dUsuSJUvoDA) — matches §Expressions for functions: lambda abstractions
- [Partial application and curried functions](https://youtu.be/_oS5fwzcQKE)

## Chapter 12 — Developing higher-order programs

- [Regular expressions I](https://youtu.be/vKWwv1b1UTU) — matches §Functions as data: recognising regular expressions
- [Regular expressions II](https://youtu.be/apHDTFTiZtI)
- [Week 8 summary](https://youtu.be/PrJghYuNc9c) — confirmed

## Chapter 13 — Overloading, type classes and type checking

- [Why overloading?](https://youtu.be/kRvAftsiiHg) — exact match
- [Type classes](https://youtu.be/AgVZitfnFBk) — matches §Introducing classes
- [Type class tour I](https://youtu.be/CJsTuA0p0CA) — matches §A tour of the built-in Haskell classes
- [Managing types](https://youtu.be/MICmFBuvx-0) — matches §Signatures and instances
- [Monomorphic type checking](https://youtu.be/wFGzaFSFla0) — exact match
- [Polymorphic type checking](https://youtu.be/SHG7N6981u0) — exact match
- [Unification](https://youtu.be/MONHnc81q28) — part of §Polymorphic type checking
- [Three type checking examples](https://youtu.be/josWP-e8k4k)
- [Type checking and type classes](https://youtu.be/pxA6b52UW8c) — matches §Type checking and classes
- [Week 9 summary](https://youtu.be/pFQpA3UKo3E)

## Chapter 14 — Algebraic types

- [Recursive algebraic types](https://youtu.be/kcaEk3W64P8) — exact match
- [Functions on recursive types](https://youtu.be/49PGf2QczWg)
- [Parametric types](https://youtu.be/e6NUkZzOYTE) — matches §Polymorphic algebraic types

## Chapter 16 — Abstract data types

- [Search trees](https://youtu.be/gUqqXrYnZpc) — moved here per feedback — exact match: §Search trees

## Chapter 17 — Lazy programming

- [Language processing](https://youtu.be/sDqVAfdRB8o) — part of §Case study: parsing expressions
- [Pretty printing](https://youtu.be/-INZ1i7hzzQ)
- [Evaluating expressions](https://youtu.be/WhYpyIHjghA)
- [Compilation and execution](https://youtu.be/SsWQXLl4F9c)
- [Parsing](https://youtu.be/5qvcafkuXlA)
- [Taking things further.](https://youtu.be/WtLojbr6HLQ)
- [Week 7 summary](https://youtu.be/ocDDDU8s8iM)
- [Lazy evaluation](https://youtu.be/sqCETWi20Xs) — exact match, from Week 10
- [Permutations](https://youtu.be/E_rbfw6Z1KM) — confirmed
- [Infinite lists](https://youtu.be/9Xhw5i0laZY) — matches §Why infinite lists?
- [Streams](https://youtu.be/0XnM6t2I6YQ)
- [Solving a maze](https://youtu.be/AJDi3Z06YqQ) — confirmed
- [Lazy evaluation and efficiency.](https://youtu.be/PpK5bG4DpXY) — matches §Proof revisited
- [Week 10 summary](https://youtu.be/_I2itqlqz9k)

## Chapter 19 — Abstraction: functors, monads and folding

- [Abstraction](https://youtu.be/B1zHc5QtBNY) — exact match
- [Functor](https://youtu.be/s7vUod9_AM0) — matches §The Functor class
- [Applicative](https://youtu.be/pJf3q37uxbo) — matches §The Applicative class
- [Monads](https://youtu.be/TB72Yn_mdKE) — matches §Monads: languages for functional programming
- [Monads and computation](https://youtu.be/CU1iYIzP0uc) — matches §Example: monadic computation over trees
- [Foldable](https://youtu.be/J9-W6xJNG_E) — matches §Folding over data: Foldable
- [Week 11 summary](https://youtu.be/IzTvAkWqzCM)

## Chapters with no matching video

No video in the playlist matches these chapters' content. All are deeper case-study or advanced material an introductory course plausibly skips:

- Chapter 15 — Case study: Huffman codes
- Chapter 18 — I/O programming
- Chapter 20 — Domain-Specific Languages
- Chapter 21 — Time and space behaviour
- Chapter 22 — Conclusion

