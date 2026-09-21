# Review of the Preface and Conclusion for currency and gaps

Prepared in response to a request to check `Book/0.tex` (Preface) and
`Book/22.tex` (Conclusion) for anything factually incorrect about the
Haskell ecosystem, anything obviously missing, and to draft a "What is new
in this (online) edition?" section for the Preface. **No files were
modified to produce this report.**

`git log --oneline -- Book/22.tex` shows only a chapter-renumbering commit
— the Conclusion has had no substantive edit since the 2011 third edition.
`Book/0.tex` has already had several targeted updates (GHCup, the
online-edition credit note, retiring `haskellcraft.com`), but the body
text reviewed below has not.

Facts below that could be checked against a live source were checked via
web search on 2026-09-18 and are cited; everything else is drawn from
reading the `.tex` files and the project's own git history.

## Preface (`Book/0.tex`)

### Factual/currency issues

- **Line 125** — *"The standard for Haskell is under yearly review, but it
  is likely that the parts of the language discussed here will be stable
  in future versions of the standard."* This is now wrong: no successor to
  the Haskell 2010 Report has ever shipped — it is 16 years old. This is
  just starting to change: the Haskell Foundation has recently stood up a
  working group to produce a Revised Haskell 2010 Report
  ([blog.haskell.org](https://blog.haskell.org/revised-haskell-2010-report/),
  [Discourse thread](https://discourse.haskell.org/t/a-revised-haskell-2010-language-report-the-haskell-programming-languages-blog/14508)).
  Suggest rewriting to say Haskell 2010 has in practice remained the
  stable base for 16 years, that GHC has instead evolved via language
  extensions (bundled since 2021 into "language editions" `GHC2021` /
  `GHC2024` — [GHC user's guide](https://downloads.haskell.org/ghc/latest/docs/users_guide/exts/control.html)),
  and that a Haskell Foundation working group has now begun work on a
  revised Report.
- **Line 54** — The Erlang example ("Facebook chat and other services from
  Amazon and Yahoo!") is dated; Facebook's chat backend moved off Erlang
  years ago. A more current, well-known example would be WhatsApp (still
  substantially Erlang), or mentioning Elixir (built on the Erlang VM) as
  its modern face.
- **Line 54** — F# is described as "a standard part of their Visual Studio
  suite" — true but narrower than reality; Chapter 22 (line 149) already
  correctly notes it is "now open source and cross-platform as part of
  .NET." Worth making the Preface consistent with that.

### Obvious gaps

- **The Haskell Foundation** (est. 2020) is not mentioned anywhere in the
  book at all — not the Preface, not the Conclusion, not the modernized
  Chapter 6 library section. It is the single biggest organizational
  development in the ecosystem since 2011: it funds core tooling/library
  maintenance, runs the (recently revived) yearly community survey
  ([State of Haskell 2025](https://discourse.haskell.org/t/state-of-haskell-2025-results/13755)),
  and now the language-report effort above. Probably best placed in
  Chapter 22's "Haskell on the web" section rather than the Preface.
- ~~The "why learn Haskell" bullet list (lines 39-55) still leads with
  Xmonad and Cryptol. Both remain true but are quiet, 2010-era examples.
  A more resonant 2026 example: Cardano's Plutus smart-contract platform
  is built on Haskell at real production scale
  ([Cardano docs](https://docs.cardano.org/developer-resources/smart-contracts/plutus)),
  alongside a number of fintech users (Standard Chartered, Mercury, and
  others). Optional polish, not a correctness fix.~~ **Done** — kept
  Xmonad/Cryptol and appended a sentence to the same bullet in
  `Book/0.tex` naming Standard Chartered (multi-million-line Haskell
  dialect powering its Markets division), Mercury (Haskell-backed
  fintech processing hundreds of billions/year), and Plutus, each
  re-verified via web search before adding. Live in both the PDF and
  website.

### Draft "What is new in this online edition?" section

Based on the actual git history (mdBook web edition, GHCup/HLS adoption,
dev containers, CC BY-NC-SA 4.0 licensing, `MonadFail`/`Foldable` code
fixes, retiring `haskellcraft.com`), a draft in the voice of the existing
"What has changed..." sections, to be inserted right after "Outline"
(before line 310), keeping the reverse-chronological order (online
edition → 3rd edition → 2nd edition):

```latex
\section*{What is new in this online edition?}

This is a revision of the 2011 third edition, not a fourth edition in
its own right: the core text, examples and case studies are unchanged
in substance. What has changed:
\begin{itemize}
\item
The book is now freely available online under a Creative Commons
licence (CC BY-NC-SA 4.0), alongside the PDF, as a web edition built
with mdBook.
\item
The recommended toolchain has moved on: \emph{GHCup} is now the
single recommended installer for GHC, Cabal and the Haskell Language
Server (HLS), and VS Code with HLS is the recommended editor setup.
Readers who want to try the book's code without installing anything
can use the accompanying dev container (GitHub Codespaces or Gitpod).
\item
The code accompanying the book has been brought into line with
current GHC and \texttt{base}: for example the \texttt{MonadFail}
class, split out of \texttt{Monad} since \texttt{base-4.13}, and the
\texttt{Foldable} class, are now covered directly, and every example
compiles cleanly under a current GHC.
\item
Guidance on finding libraries and getting help has been refreshed:
Hackage, Stackage snapshots, Haddock and Hoogle for libraries; the
Haskell Discourse, Haskell Cafe and Stack Overflow for questions.
\item
Dead links to \texttt{haskellcraft.com} have been retired, with that
material folded into the book and its GitHub repository,
\url{https://github.com/simonjohnthompson/haskellcraft}.
\end{itemize}
As noted above, this revision was itself carried out with the
assistance of an LLM (Claude Code, using Claude Sonnet 5) --- itself
a small illustration of how much the wider software landscape has
changed since 2011.
```

Trim/extend the bullet list to taste — it is meant as a starting draft,
not a final version.

## Conclusion (`Book/22.tex`)

This chapter has had zero substantive edits since 2011 (only a chapter
renumber in the git history), so it is the most dated part of the book.
In priority order:

### 1. The "future of Haskell" subsection (lines 106-116) makes a claim that is now false

*"Haskell is now undergoing regular language standard updates."* It
wasn't, for 16 years — until literally now (see the Haskell Foundation
Report working group above). Worth rewriting to tell the real, more
interesting story: Haskell 2010 stayed stable far longer than anyone
expected; GHC evolved instead through extensions, now curated into
`GHC2021` / `GHC2024` "language editions"; and a Report revision effort
has just begun.

### 2. The "next few years" prediction (line 205) is itself now 15 years stale

It is framed as a retrospective on the *second* edition's 1998-9
predictions, so a natural, in-keeping move is to add a short coda scoring
the *third* edition's 2011 predictions and naming a couple of new ones for
today's reader:

- Multicore/parallelism: broadly vindicated — GHC's `async`, STM and
  sparks story matured a lot, though the "thousands of cores" framing
  reads oddly now that the industry is a lot more excited about
  GPUs/accelerators.
- Type-system prediction: also vindicated, concretely — `LinearTypes`
  landed in GHC 9.0+, directly continuing that thread.
- Worth naming since 2011: real production use at genuine scale
  (Cardano/Plutus for smart contracts; fintech deployments at Standard
  Chartered and others); the rise of effect systems (`effectful`,
  `polysemy`) as an alternative to monad-transformer stacks; the Haskell
  Foundation itself as new community infrastructure.

### 3. Recommended further reading (lines 96-101) is showing its age

*Real World Haskell* is from 2008 — pre-Stack, pre-Stackage, code examples
look dated. Suggest keeping it (its FFI coverage is still called out as
valuable) but flagging its age, and adding one or two more current picks:
*Haskell Programming from First Principles* (Allen & Moronuki) is the most
commonly recommended thorough self-study text today, and *Effective
Haskell* (Rebecca Skinner, Pragmatic Bookshelf, 2022) is a well-regarded,
tooling-current practical follow-on
([confirmed current/in-print](https://www.pragprog.com/titles/rshaskell/effective-haskell/)).

### 4. "Haskell on the web" (lines 126-140) is missing the Haskell Foundation

As above, this is probably its natural home in the book. Otherwise this
section is in better shape than expected: the community list (Discourse,
IRC, mailing lists, Reddit, Stack Overflow) already matches the wording
used in the recently-modernized Chapter 6 (`6.tex:505`), and Haskell
Weekly was confirmed still actively publishing (issue 541, 2026-09-10 —
[haskellweekly.news](https://haskellweekly.news/)), so that link does not
need touching. Worth a note for later: this list and Chapter 6's now live
in two places and could drift out of sync again — a cross-reference
instead of a duplicate list might be worth considering next time either
is touched.

### 5. "Other functional programming languages" (lines 141-165) is missing anything that has emerged/grown since 2011

PureScript and Elm (both directly Haskell-influenced, and PureScript in
particular pairs naturally with the book's own SVG/browser Picture DSL
material), Rust (shares a lot of Haskell's type-system DNA — ADTs, pattern
matching, `Result`/`Option`), or Clojure alongside the existing
Lisp/Scheme paragraph. None of these are corrections, just candidates for
a "where these ideas show up today" addition.

## Suggested priority if asked to act on this

1. ~~Fix the two factual errors (Preface "yearly review" line, Conclusion
   "regular language standard updates" line) — these are the only things
   that are actually *wrong* rather than merely dated.~~ **Done** —
   rewrote `Book/0.tex:125` and `Book/22.tex:113-116`, both now
   describing Haskell 2010's real 16-year stability, GHC's evolution via
   `GHC2021`/`GHC2024` language editions, and the Haskell Foundation
   working group's new Report-revision effort. Also fixed the dated
   Erlang/F# examples in the same Preface paragraph (`Book/0.tex:54`)
   while there. Live in both the PDF and website.
2. ~~Add the Haskell Foundation mention.~~ **Done** — added as a fourth
   paragraph to the Preface's "Haskell and GHCi" section (`Book/0.tex`),
   ending with the "revised Haskell 2010 Report" sentence moved down
   from the end of the second paragraph. Live in both the PDF and
   website. (This placed it in the Preface rather than Chapter 22's
   "Haskell on the web" section as originally suggested — Simon's call.)
3. ~~Draft and insert the "What is new in this online edition?"
   section.~~ **Done** — inserted into `Book/0.tex` (before "What has
   changed from the second edition?"), merged with a second bullet list
   drafted independently in the same session, dropping the "released on
   Hackage" bullet as no longer new. Live in both the PDF and website.
4. Everything else (reading list refresh, other-languages additions, the
   2011-predictions coda) is optional polish.
