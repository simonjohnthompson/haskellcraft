Project ideas {#projects}
=============

<a id="ix-projects-project-ideas"></a>

In this appendix we give some ideas for extended Haskell projects, building on what we have covered here. Most of the projects can be implemented using what you have learned in this text, but many would gain from using libraries on the Hackage site. The projects are also discussed in more detail in the online supplement to the text, which appears at <http://www.haskellcraft.com/>.

### Games and puzzles {#games-and-puzzles .unnumbered}

Different games and puzzles give a whole lot of different challenges to the programmer. A game like noughts and crosses (tic-tac-toe) has an easy strategy which means that the first player can always avoid losing, whereas there is no machine implementation of Go that can compete with the best human players. Interacting with a game can be done textually -- as people used to play chess by post -- or through interactive graphics. Haskell has bindings to two fully-featured graphics/GUI libraries: `gtk` and `wx`, and these, as well as browser-based systems, can be used for implementations of various levels of sophistication.

We don't describe any of the games in any detail here: there are abundant web-based resources including, of course, wikipedia, which cover the history and rules of the games as well as their many variants.

#### Sudoku {#sudoku .unnumbered}

A first puzzle here is to *devise Sudoko problems*, which can then be printed and solved by hand. How do you find problems which fit the various levels of difficulty?

A second problem is to *solve a given problem*, as appears in many newspapers and online. As well as thinking of the algorithm which finds a solution efficiently, you'll need to think about how to input the problem and how to present the results. Finally, you could check whether the solution you find is unique: if not, can you enumerate or count the number of solutions? Conversely, are any seemingly consistent problems in fact unsolvable?

A third problem is to *provide assistance* to a human solver: can you give hints how they might make the next move when their solution has got to a certain point. Again you'll need to think about just how the interaction will take place. This could be part of an online solution assistant, or stand alone.

#### Minesweeper {#minesweeper .unnumbered}

The minesweeper program requires the player to uncover mines in a minefield without setting any of them off, when the player is given the count of mines on squares adjacent to each uncovered square. Many games are available online to provide examples.

One problem is to re-implement one of these *interactive games*: it could use \"text graphics\", specifying the square to uncover by giving its coordinates, or could work interactively in a graphics system or browser.

Alternatively, you could implement an algorithm to *play the game automatically*: given a particular configuration, which is the optimal move to make next? How much information do you need to know to make this decision? Can you solve the problem in a deterministic way, or will your solution be probabilistic?

#### Noughts and crosses (tic-tac-toe) {#noughts-and-crosses-tic-tac-toe .unnumbered}

When we looked at Rock-Paper-Scissors we saw that we could represent a *strategy* for a player as a function from their opponent's playing history to the player's next move. Try implementing noughts and crosses where two strategies play against each other: in doing this you will need to think about how to represent these strategies in a compact way, and also about how you might combine simple strategies together using *strategy combinators*.

A second problem is to implement an *interactive* version of the game in which a human player plays against a strategy. You will need to think about just how to present the interaction to the player, and in particular whether to us a textual, graphical or web browser-based representation of the game.

### Web graphics {#web-graphics .unnumbered}

The web is moving towards a new standard, HTML5, which will directly render Scalable Vector Graphics (SVG) ([SVG 2010](bibliography.md#SVG)) in web browsers. We have used SVG as a way of rendering our pictures, but in doing this we have barely scratched the surface of what is possible. The `gtk` package renders SVG using the Cairo system, but the aim of the projects discussed here is to use standard web technology to do the 'heavy lifting' of rendering.

#### Representing SVG {#representing-svg .unnumbered}

In this project you should devise a representation for a subset of SVG within Haskell. You might like to look at what has been done in `gtk`, and also at the different ways that XML is represented in HaXml and other Haskell libraries.

#### Rendering SVG {#rendering-svg .unnumbered}

SVG can be rendered in place using a modern browser -- in the case of Internet Explorer from version 9 upwards. Suppose that you want to generate SVG in a program, and have that data rendered in a browser: one mechanism for this is to run a local web-server in which the page is created, and then served to a client on the local machine. Using the HTTP and Web libraries for Haskell, build this local web server.

#### Web forms: calculator in a browser {#web-forms-calculator-in-a-browser .unnumbered}

Using the *web forms* standard in HTML5, you can build richer interactions, particularly using a local web server running in Haskell. In particular, you should be able to build a browser-embedded version of the calculator program, using Haskell to calculate the value of the input expression, and performing the interaction using a web form.

Alternatively, it is possible to build interactivity using JavaScript, either "raw" or through the `jQuery` library.

### Logic {#logic .unnumbered}

Logic is a branch of mathematics closely linked to computer science ([Huth and Ryan 2004](bibliography.md#HuthAndRyan)), and implementing various logical procedures is a great way to understand precisely how logic works.

#### Truth tables {#truth-tables .unnumbered}

The first exercise is to *implement truth tables* for formulas of propositional logic. We can use these to decide whether a formula is a tautology (true in *all* interpretations) or satisfiable (true in *at least one* interpretation). The output could just be this classification, or it could be the full truth table, showing the value of the formula under each interpretation.

#### SAT solving {#sat-solving .unnumbered}

The practicalities of deciding whether or not a formula is satisfiable, the *SAT solving* problem, is an area where huge efforts are made to find efficient algorithms to solve the problem. How can these algorithms be implemented in Haskell?

#### Tableaux {#tableaux .unnumbered}

Semantic tableaux give a decision procedure not just for propositional logic, but also for temporal and other modal logics. A tableau method is a *constructive* mechanism, which will find all the interpretations satisfying a particular formula. This project is to implement a *tableau procedure* for propositional logic; can also look at tableaux for the temporal logics in ([Huth and Ryan 2004](bibliography.md#HuthAndRyan)).

#### Proof {#proof .unnumbered}

Rather than using an automated mechanism to decide whether or not a formula is a tautology, it is possible to *prove* a formula in a formal system: this project is to implement an interactive proof system for propositional logic. You will need to decide how the interactions are to be modelled in the system, and how feedback can be provided to the user about their proof choices, as well as how advice can be given to them on request.

### Voting systems {#voting-systems .unnumbered}

Depending on where you live, you will decide the form of your government in different ways. The simplest mechanism is perhaps *first past the post*, where the person gaining the single largest number of votes is elected, but other systems include ways of getting a more *proportional* outcome than this.

How is it possible to explain these various mechanisms to a naı̈ve voter? The aim of this exercise is to illustrate the effects of different systems, based on a simulated vote.

#### Voting data {#voting-data .unnumbered}

It should be possible to get *actual voting data* from particular elections, and to use (processed?) variants of those data in different voting scenarios. Alternatively you should generate random data according to a scenario specified by a user. This could be done from scratch, or alternatively you could use the data generation facilities of QuickCheck to build a sample.

#### Visualisation {#visualisation .unnumbered}

'A picture is worth a thousand words', and in a situation it makes sense to provide *visualisations* of the various results. You could use the SVG facilities developed in an earlier suggestion, or investigate the capabilities of the graphical libraries provided within Hackage.

#### Tactical voting {#tactical-voting .unnumbered}

What is the best way to get the result that you want? On the basis of historical data and the particular system, analyse the options for a voter who wants a particular outcome to happen. For instance, what is the best option for your second vote in an AV system?

### Finite-state machines {#finite-state-machines .unnumbered}

One of the fundamental abstractions in computer science is the *finite-state machine* (FSM) ([Aho et al. 2006](bibliography.md#dragon2ed)). We saw earlier that we can write recognisers for regular expressions, but more efficient implementations are given by deriving NFAs from regular expressions, and then (minimal) DFAs from those NFAs.

#### Conversion chain {#conversion-chain .unnumbered}

As an exercise, implement the chain of conversions from regular expressions to NFAs, DFAs and finally optimal DFAs; there are also algorithms which convert directly from a regular expression to a DFA.

#### Inferring machines {#inferring-machines .unnumbered}

There is a well-developed literature on deriving machines, regular expressions or grammars from sets of traces which are accepted (or rejected) by a particular machine. Investigate these further by implementing them.

#### Visualisation {#visualisation-1 .unnumbered}

Develop mechanisms which provide a *visualisation* of the operation of an FSM. and of the algorithms discussed earlier.

### Domain-specific languages {#domain-specific-languages .unnumbered}

<a id="ix-projects-dsl-project-ideas"></a>

One theme of this book has been domain-specific languages, and as a part of some of these projects you could build a domain-specific language. Examples include

-   A language for describing games has been defined by Conway ([Conway 2002](bibliography.md#conwayGames); [Berlekamp et al. 2001](bibliography.md#winningWays)): look at how you can build a DSL for these games; you could also look at a language for describing strategies to play these games.

-   A language for describing different voting systems: your simulations and visualisations could then work with an arbitrary voting system, as described in the language.

-   We saw in the body of the text that it is possible to write a simple DSL for patterns, namely regular expressions. Look at ways that this can be extended to make it more expressible, and also at the possibility of defining a DSL to describe different kinds of finite state machines.

These are just a few ideas of the kind of DSL that you could build: a general project is to use Haskell for building DSLs in a domain of your choice.
