# Problem solving and further examples {#further}

<a id="ix-further-problem-solving"></a>

This appendix[^1] collects material that used to live on the companion website for this book: general advice on problem solving, a worked example of the design process applied to recognising palindromes, background on the Minesweeper implementations that accompany the `Craft3e` code, and a note on the regular-expressions and automata material referred to in Appendix [Project ideas](projects.md#projects).

### Problem solving {#ProbSolving .unnumbered}

At the University of Kent we have tried to incorporate more explicit advice about problem solving strategies into our programming teaching, based on Polya's classic *How to Solve It*. Two handouts developed for this are available online: [*How To Program It*](http://www.cs.kent.ac.uk/people/staff/sjt/Haskell_craft/HowToProgIt.html) (also as a [PDF](http://www.cs.kent.ac.uk/people/staff/sjt/Haskell_craft/howToProgIt.pdf)), which discusses general strategies for writing small-scale programs; and [*Programming It In Haskell*](http://www.cs.kent.ac.uk/people/staff/sjt/Haskell_craft/ProgInHaskell.html) (also as a [PDF](http://www.cs.kent.ac.uk/people/staff/sjt/Haskell_craft/progInHaskell.pdf)), which shows how these ideas are used in writing small- to medium-size Haskell programs. The approach is also described in the paper [*A problem solving approach in teaching functional programming*](http://www.cs.kent.ac.uk/people/staff/sjt/Haskell_craft/ProbSolvInHas.ps.gz), published in the proceedings of the First International Conference on Declarative Programming Languages in Education.

The next section works through a larger-scale example, recognising palindromes, applying this approach in detail.

### Recognising palindromes {#Palindromes .unnumbered}

This section is a worked example of the problem solving process, applied to writing a Haskell function which recognises palindromes -- strings which read the same backwards and forwards, such as *"Madam I'm Adam."*

#### Understanding the problem {#understanding-the-problem .unnumbered}

The first stage of the problem solving process is to work out exactly what the problem is. A palindrome is a string of text which reads the same backwards and forwards, if

- we disregard the punctuation (punctuation marks and spaces) in the string; and

- we disregard the case (upper or lower) of the letters in the string.

At this stage we can already say something about the Haskell function we are going to write. We will call it `palin`. What is its type? It takes the string we are checking as its argument, and the result of the test is a Boolean, so

``` haskell
palin :: String -> Bool
```

#### Starting the design {#starting-the-design .unnumbered}

Now that we know what we are aiming at, we can design a solution. A number of strategies help here, including looking for related problems, functions we already know which we might use, and trying to break the problem into parts we can solve separately. The palindrome problem breaks into two parts: disregard the punctuation and case, and then reverse the string and compare it with its original form.

We can solve these two separately. Suppose that the string `st` contains no punctuation and is already in lower case; then we just need the second part:

``` haskell
palin st = (reverse st == st)
```

which reverses the string `(reverse st)` and compares it with the original `(... == st)`. This leaves us needing to solve the problem of reversing a string:

``` haskell
reverse :: String -> String
```

To solve the whole problem, we need to do the same, but to a string which has had its punctuation and case disregarded:

``` haskell
palin st = (reverse st' == st')
           where
           st' = disregard st
```

where the function which disregards punctuation and case is

``` haskell
disregard :: String -> String
```

#### Carrying on {#carrying-on .unnumbered}

Our problem has now been broken down into two simpler problems: defining `reverse` and `disregard`.

To reverse a string, which is a list of characters (`[Char]`), we define the function from scratch (setting aside that it is already in the standard prelude). We can think this through in stages, left-hand side first:

``` haskell
reverse :: String -> String

reverse []     = ...
reverse (a:st) = ...
```

which are the two cases of an empty string, and a non-empty string whose first element is `a` and whose remainder (or tail) is `st`.

An empty string reversed is empty:

``` haskell
reverse []     = []
```

while in the general case we can be guided by an example. In this sort of definition we define `reverse (a:st)` using `reverse st`. Take the example `"door"`. Reversing the tail gives `"roo"`, and we get what we want by sticking `"d"` on the end. So,

``` haskell
reverse (a:st) = reverse st ++ [a]
```

where `++` joins together two strings and `[a]` is the string made up of the single character `a`.

The final problem is to define `disregard`, which as we saw above consists of two parts: removing punctuation, and changing capital letters to lower case. We can solve these separately, with

``` haskell
remove :: String -> String
change :: String -> String
```

We build `disregard` by applying these in turn: either `disregard st = remove (change st)` or `disregard st = change (remove st)`. Here is an example of reflecting on our design without having implemented either function: we choose the latter, since under this definition we only need to change those characters which remain in the string. This lets us write the definition more concisely still, as the composition

``` haskell
disregard = change . remove
```

first applying `remove`, and then applying `change` to the result.

#### The last steps {#the-last-steps .unnumbered}

It remains to define `remove` and `change`. The former follows the familiar recursion pattern over a list:

``` haskell
remove :: String -> String

remove []     = []
remove (a:st) = ...
```

In the `(a:st)` case there are two possibilities, depending on whether `a` is a punctuation character or not; if it is not, `a` goes into the result, and in both cases the remainder comes from removing punctuation from `st`:

``` haskell
remove (a:st)
  | notPunct a = a : remove st
  | otherwise  =     remove st
```

where we can decide whether we have punctuation with, for instance,

``` haskell
notPunct :: Char -> Bool
notPunct ch = isAlpha ch || isDigit ch
```

that is, that we have either a letter or a digit.

Finally, `change` affects each character in the list in turn:

``` haskell
change :: String -> String

change []     = []
change (a:st) = convert a : change st
```

where

``` haskell
convert :: Char -> Char
convert ch
  | isCap ch  = decode (code ch + offset)
  | otherwise = ch
    where
    offset = code 'a' - code 'A'

isCap :: Char -> Bool
isCap ch = 'A' <= ch && ch <= 'Z'
```

#### Conclusion {#conclusion .unnumbered}

This example shows how the problem solving approach applies in Haskell, and how it can help you get started on a problem which at first looks more complicated than it turns out to be. An [executable version of the program](http://www.cs.kent.ac.uk/people/staff/sjt/Haskell_craft/Palin.hs) is available online.

### Minesweeper {#MinesweeperApp .unnumbered}

<a id="ix-further-minesweeper"></a>

Minesweeper is a long-lived and popular computer game, with a great many implementations. The game is played on a rectangular board divided into a number of squares, beneath some of which lie mines. Clicking on a mine loses the game; otherwise the square is cleared and the number of mines on adjacent squares is shown -- and if the square has no adjacent mines, the whole mine-free region containing it is uncovered. The player wins once all the mines are marked and every other square is cleared.

A series of text-interface Haskell implementations of Minesweeper, originally written in 2002 and used as a case study for refactoring Haskell programs, are included with the `Craft3e` code in `Minesweeper/` (see [Working with multiple-module projects](2.md#multipleModuleProgs) for how to obtain and build the code for this book). The commands used in the textual versions are:

``` haskell
q            Quit
h            Help information
m7b          Mark position 7b
u7b          Unmark position 7b
r7b          Reveal position 7b
s7b          Show equations at 7b
a7b          Automatic turn at 7b
t7b          Transitive automatic from 7b
```

These commands should not be followed by a newline. The successive versions are:

- `Minesweeper.hs`: a simple interface -- input a row and column character to uncover a square; run `playGrid`.

- `Minesweeper2.hs`: implements `q`, `s`, `m`, `u`, `r`. To play, run `playGame m n` where `m` is the number of mines and `n` the size of the (square) board.

- `Minesweeper3.hs`: adds `a` and `t` to the commands above. Played the same way as `Minesweeper2`.

- `Minesweeper4.hs`: adds `h`. Played the same way as `Minesweeper2`.

- `Minesweeper5.hs`: a further refinement of `Minesweeper4`, played the same way.

- `MineRandom.hs`: generates a random starting grid, for use with the versions above.

An earlier, graphical interface to the same game, built using a now-defunct Haskell graphics library and tested only under Hugs on Windows, is also kept in the repository, in `Minesweeper/Graphical/` (`GraphicMine.hs` through `GraphicMine4.hs`), though it is not currently part of the buildable `Craft3e` package.

### Regular expressions and automata {#RegExpsApp .unnumbered}

<a id="ix-further-regular-expression-further-reading"></a>

Regular expressions are patterns used to describe the lexical parts of languages, such as numbers and identifiers, as discussed in [Domain-Specific Languages](19.md#dsls). Strings matching a regular expression can be detected by a non-deterministic finite automaton (NFA), which can in turn be transformed into a (more efficiently implementable) deterministic finite automaton (DFA), and from there into an optimal DFA.

A fuller account of this material, including the Haskell implementation, is given in the paper [*Regular expressions and automata using Haskell*](https://link.springer.com/chapter/10.1007/BFb0033853). It begins with the definition of regular expressions and how strings are matched against them, giving a first Haskell treatment; after describing an abstract data type of sets, it defines non-deterministic finite automata and their Haskell implementation, shows how to build an NFA corresponding to a regular expression, and how such a machine can be optimised -- first by making it deterministic, then by minimising the state space of the resulting DFA. It concludes with a discussion of regular definitions, and shows how recognisers for strings matching them can be built. The material illustrates many features of Haskell, including polymorphism (the states of an NFA can be represented by objects of any type), modularisation (the system is split across a number of modules), higher-order functions (used, for example, in finding the limits of iterative processes), and type classes, among other features. The [accompanying Haskell libraries](http://www.cs.kent.ac.uk/people/staff/sjt/craft2e/regExp.tar.gz) are also available.

[^1]: This appendix was drafted with assistance from Claude Code v2.1.236 (Claude Sonnet 5), Anthropic, 2026.
