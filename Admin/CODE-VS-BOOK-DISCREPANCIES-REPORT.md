# Discrepancies between the current `Craft3e` cabal package and the code as described in the book

Prepared in response to a request to document where the code that actually
ships in the `Craft3e` cabal package (`Code/Craft3e`, currently version
0.2.0.2) now differs from the code as printed and explained in `Book/*.tex`.
The book's monad chapter was written for the language as it stood around
2011; three changes to the `Monad`/`Applicative` class hierarchy since then
— none of which the book anticipates or mentions — are the entire cause of
every discrepancy found. **No files were modified to produce this report.**

Test environment: GHC 9.6.7 / cabal-install 3.12.1.0, against the
repository's own `Code/Craft3e` (not a copy — read-only `cabal build`
commands only).

## Headline finding

The book teaches a `Monad` class with `fail` as one of its four methods, and
shows several worked examples (`MP`, the calculator's parsing monad; `State`,
the imperative-store monad) that define `Monad` instances with nothing else
— no `Applicative`, no `Functor`, no separate failure class. That was an
accurate description of Haskell in 2011. It is not an accurate description
of Haskell today: **the word "Applicative" does not appear anywhere in
`Book/*.tex`**, yet every one of the book's hand-written `Monad` instances
would fail to compile under GHC 9.6.7 without one. The shipped cabal package
has already been silently patched to cope with this — the book's prose has
not been.

Two separate language changes are responsible:

1. **The Applicative-Monad Proposal (AMP)**, GHC 7.10 / `base-4.8`, 2015:
   `Applicative` became a superclass of `Monad`. Every `instance Monad T`
   now requires a preceding `instance Functor T` and `instance Applicative T`.
2. **The MonadFail Proposal (MFP)**, fully enforced from GHC 8.8 /
   `base-4.13`, 2019: `fail` was removed from `Monad` entirely and now lives
   in its own class, `MonadFail`. Writing `fail s = ...` inside an
   `instance Monad T where` block is now a **compile error** ("`fail` is not
   a (visible) method of class `Monad`"), regardless of whether `fail` is
   ever called.

Confirmed directly against the installed GHC:

```
class Applicative m => Monad m where
  (>>=) :: m a -> (a -> m b) -> m b
  (>>) :: m a -> m b -> m b
  return :: a -> m a

class Monad m => MonadFail m where
  fail :: String -> m a          -- no default; contrast with pre-2019 base,
                                  -- where every Monad got `fail s = error s`
                                  -- automatically, whether declared or not
```

The book's own printed definition (`Book/18.tex:652-668`, Chapter 18,
"Programming with monads", section "Monads, formally") is:

```
class Monad m where
  (>>=)  :: m a -> (a -> m b) -> m b
  return :: a -> m a
  (>>)   :: m a -> m b -> m b
  fail   :: String -> m a
```
with default declarations `m >> k = m >>= \_ -> k` and `fail s = error s`.

This is a real behavioural change, not just a cosmetic one: pre-2019, *any*
type with a `Monad` instance automatically got a working (if crude) `fail`
via the default; a refutable pattern in a `do`-block over that type failed
at *run time* with `error`. Post-2019, a type with no explicit `MonadFail`
instance has *no* `fail` at all — the same code is now a *compile-time*
type error. The book's claim (`Book/18.tex:685-686`) that "the value `fail
s` corresponds to a computation which fails, giving the error message `s`"
is still true of types that define `MonadFail`, but is no longer a property
every monad has for free.

## Where this actually bites: three worked examples, three different fates

`cabal build --ghc-options=-Wnoncanonical-monad-instances` against the
unmodified package pinpoints exactly three files where the book's
`Monad`-without-`Applicative` style survives in the shipped code (as a
warning, because each one has already been patched to add the missing
instances) — and they line up exactly with the book's three worked
examples in Chapter 18. There are no other occurrences anywhere in the
cabal package.

| Book example | Book location | Shipped file | What the shipped file has that the book doesn't |
|---|---|---|---|
| The parsing monad, type `MP` | `Book/18.tex:757-767` | `ParseLib.hs:124-140` (as `SParse`) | `instance Applicative`/`instance Functor` added; `fail` moved into a separate `instance MonadFail` (fixed — see below) |
| The parsing monad, same type, second copy | *(same book text — the calculator section reuses it)* | `Calculator/CalcParseLib.hs:126-141` (also `SParse`) | `instance Applicative`/`instance Functor` added; `fail` **kept**, moved into a separate `instance MonadFail` |
| The state monad, type `State` | `Book/18.tex:1094-1129` | `Chapter18.hs:210-233` | `instance Applicative`/`instance Functor` added; no `fail` was ever defined here, so no `MonadFail` question arises |

The `MP`/`SParse` row was, until this report prompted a one-line fix, the
interesting one: **the same monad, presented once in the book, exists as two
separately-maintained copies in the shipped package, and they had diverged
in how they were patched.**

### `ParseLib.hs` (top-level, exposed as `ParseLib`) — `fail` gap now closed

`ParseLib.hs` originally had `instance Applicative`/`instance Functor` added
for `SParse` but no `MonadFail (SParse a)` instance — the book's `fail s =
MP none` (`Book/18.tex:764`) had been silently dropped rather than moved.
Since this report was first written, that gap has been closed to bring this
copy in line with `Calculator/CalcParseLib.hs`:

```haskell
-- ParseLib.hs:124-140
instance Monad (SParse a) where
  return x = SParse (succeed x)
  (SParse pr) >>= f
    = SParse (\st -> concat [ sparse (f a) rest | (a,rest) <- pr st ])

instance MonadFail (SParse a) where
  fail s   = SParse none

instance Applicative (SParse a) where
  pure = return
  (<*>) = ap

instance Functor (SParse a) where
  fmap = liftM
```

Confirmed via `cabal build lib:Craft3e`: no new errors or warnings beyond
the pre-existing, harmless `-Wnoncanonical-monad-instances` notes already
present on both copies (see the class-hierarchy discussion above for why
those warnings are expected and benign).

**Released.** This fix has since shipped to Hackage as `Craft3e-0.2.0.3` —
the version bump was made specifically because `ParseLib.hs` is the one
copy of this fix that actually reaches `cabal sdist` (`Solutions18.hs`
doesn't, and `Chapter19/parselib.hs`'s identical copy rides along as inert,
uncompiled source either way; see `Admin/CODE-COMPATIBILITY-REPORT.md`'s
"Released" note for the full detail). Confirmed live by running
`cabal update && cabal get Craft3e-0.2.0.3` fresh and checking the
downloaded `ParseLib.hs` for the `instance MonadFail (SParse a)` above. A
reader who fetches the package the book's own documented way
(`cabal unpack Craft3e`) now gets this fix, independent of whether or when
`Book/18.tex`'s prose itself is ever updated to match.

A related footnote to the licensing discussion elsewhere in this project:
a follow-up release, `Craft3e-0.2.0.4`, attempted to align the package's
`license:` field with the book's own front-matter CC BY-NC-SA 4.0
licensing, and was rejected outright by Hackage's uploader — Creative
Commons' NonCommercial clause isn't an OSI-approved open source license,
which Hackage requires. `Craft3e`'s code license stays MIT; the book's
prose licensing is unaffected and unrelated. See
`Admin/CODE-COMPATIBILITY-REPORT.md`'s "Released" note for the full
detail.

### `Calculator/CalcParseLib.hs` — `fail` preserved via `MonadFail`

```haskell
-- Calculator/CalcParseLib.hs:126-141
instance Monad (SParse a) where
  return x = SParse (succeed x)
  (SParse pr) >>= f
    = SParse (\st -> concat [ sparse (f x) rest | (x,rest) <- pr st ])

instance MonadFail (SParse a) where
  fail s   = SParse none

instance Applicative (SParse a) where
  pure = return
  (<*>) = ap

instance Functor (SParse a) where
  fmap = liftM
```

This is the patched form (`craft3e patches/0003-fix-Move-fail-from-Monad-
into-MonadFail-in-CalcParse.patch`, already applied in the version of
`Code/Craft3e` in this repository) and is the version that actually
preserves the book's stated semantics for `fail`. It is also, character for
character, the closer of the two to what the book describes — only the
`instance MonadFail` wrapper is new. This was the pattern `ParseLib.hs` was
brought in line with, above; the two copies now match.

### `Chapter18.hs` — `State` monad, `Applicative`/`Functor` added, nothing else changes

```haskell
-- Chapter18.hs:217-233
instance Monad (State a) where
  return x = State (\tab -> (tab,x))
  (State st) >>= f
    = State (\tab -> let
                     (newTab,y)    = st tab
                     (State trans) = f y
                     in
                     trans newTab)

instance Applicative (State a) where
  pure = return
  (<*>) = ap

instance Functor (State a) where
  fmap = liftM
```

The book's version (`Book/18.tex:1108-1129`) is exactly the `instance Monad`
block above, verbatim, with no `Applicative`/`Functor` block at all — and no
`fail` either, so the MonadFail split doesn't apply here. This is the
cleanest of the three cases: purely an *addition* the book doesn't show, not
a behaviour change.

## Sweep: no further gaps of this kind in the exposed modules

After fixing `ParseLib.hs`'s dropped `fail` (and its duplicate,
`Chapter19/parselib.hs`), the rest of `Craft3e.cabal`'s `exposed-modules`
were swept for the same class of issue, two ways: an exhaustive `grep` for
`instance Monad`/`Applicative`/`Functor`/`MonadFail` across all of
`Code/Craft3e`, and a full `cabal build lib:Craft3e --ghc-options="-Wall
-Wcompat"` (478 warnings, triaged by category).

The three instances catalogued above — `ParseLib.hs`'s `SParse`,
`Calculator/CalcParseLib.hs`'s `SParse`, `Chapter18.hs`'s `State` — are the
**entire set** of custom `Monad` instances anywhere in the package's
exposed modules; there is no fourth one. A parallel check for the
analogous `Semigroup`-became-a-superclass-of-`Monoid` split (`base-4.11`,
GHC 8.4, 2018) and for `Alternative`/`MonadPlus` found zero instances of
either anywhere in the tree, so neither split can produce a gap here at
all. The `-Wall` sweep's remaining ~470 warnings are pedagogical-code noise
(`-Wmissing-signatures`, `-Wunused-matches`, `-Wname-shadowing`,
`-Wtype-defaults`, `-Wincomplete-patterns`/`-Wincomplete-uni-patterns` on
ordinary `let`/`where` bindings, three `-Wcompat-unqualified-imports`, one
`-Worphans` on a QuickCheck `Show (a -> b)` instance in `QCfuns.hs`) or
forward-looking compat notices — none of them mark a place where behaviour
was silently dropped the way `fail` was. **This closes out the sweep: the
`MonadFail` fix already applied is the only instance of this discrepancy in
the shipped package, and nothing else needs the same treatment.**

## A secondary, related discrepancy: how a reader is told to run the performance examples — fixed 2026-09-04

`Book/20.tex:1033-1038` told the reader to compile the Chapter 20
performance examples directly with `ghc`, producing `a.out`, which was then
renamed by hand to `perfI.out`, `perfIA.out`, `perfIS.out`. The shipped
package instead defines these as three cabal `executable` stanzas
(`performanceI`, `performanceIA`, `performanceIS` in `Craft3e.cabal`), built
via `cabal build` and installed under cabal's own naming. This wasn't a code
bug — the executables *do* build (once `craft3e patches/0002-...patch`'s
`build-depends: base, Craft3e` was added to each stanza; without it `cabal
build` fails with "Could not load module 'Prelude'") — but it meant a reader
following the book's literal instructions ("run `ghc`, look for `a.out`")
wouldn't find what the book described, because the packaging built on top of
the book's code took over that workflow rather than mirroring it.

Fixing this properly surfaced a second, previously-undocumented bug in the
same area: even a reader who correctly used `cabal build`/`cabal run`
instead of `ghc` would then hit `performanceI: Most RTS options are
disabled. Link with -rtsopts to enable them.` the moment they tried the
book's own `+RTS -K100000000 -sstderr -RTS` example — confirmed directly by
building and running the unmodified executables — because none of the three
`executable` stanzas in `Craft3e.cabal` set `-rtsopts`. Without it, the
`+RTS`/`-RTS` flags the book explicitly teaches (`sstderr`, `-K<size>`) are
silently rejected at runtime by any cabal-built binary, regardless of how a
reader got there.

**Fixed**: `Craft3e.cabal`'s three `performanceI`/`performanceIA`/
`performanceIS` stanzas now each carry `ghc-options: -rtsopts`, confirmed
directly (`+RTS -K100000000 -sstderr -RTS` now runs and produces the same
shape of report the book's Figures \ref{perfIreport}/\ref{perfISreport}
show). `Book/20.tex`'s prose was rewritten to describe the actual
`cabal build performanceI performanceIA performanceIS` / `cabal run
performanceI -- +RTS ...` workflow, replacing the `ghc Main.hs` → `a.out` →
rename instructions and the `./perfI.out`/`./perfIS.out` invocations
throughout the section (including the later `\texttt{perfIA.out}`/
`\texttt{perfIS.out}` prose references). Confirmed via `make check` (clean,
same 644-page count) and regenerating `Website/chapters/20.md` via
`tex2md.py` (clean `mdbook build`, no warnings).

## What is *not* a discrepancy

For completeness, since the sibling `Admin/CODE-COMPATIBILITY-REPORT.md`
covers overlapping ground from a different angle (whole-package
buildability rather than book-text fidelity), it's worth being precise about
scope:

- `Craft3e.cabal`'s version bumps (`cabal-version: >= 1.10`, `base >=
  4.9.0.0`, etc.) have no counterpart in the book at all — the book never
  reproduces or discusses the `.cabal` file's contents, so there is nothing
  for these to be "inconsistent" with.
- The other GHC-evolution fixes catalogued in `CODE-COMPATIBILITY-REPORT.md`
  (the `Word` naming clash, the `RegExp` `<*>` clash, `IO/TreeId.hs`'s
  missing `Applicative Id`, `import IO` → `import System.IO`, the `n+k`
  pattern in `SolutionsParsing.hs`) all live in files that are **exercise
  solutions or scratch material**, not in `Craft3e.cabal`'s
  `exposed-modules` and not reproduced anywhere in `Book/*.tex`'s prose.
  They're real compile failures a curious reader could hit by loading those
  files, but they are not discrepancies between the book's *text* and the
  package, because the book never shows that code in the first place.
- `IO/TreeState.hs` is a near-duplicate, unpatched draft of the `Chapter18.hs`
  `State` monad example (same `Applicative`/`Functor` gap, plus an unrelated
  indentation bug) — but it too sits outside `hs-source-dirs` and outside
  `exposed-modules`, so it's an artifact of the source tree, not something a
  reader following the book/package would ever load.

## Recommendation

If the book text is revised for a new edition, the one substantive update
needed to keep Chapter 18 accurate is: introduce `Applicative` (and
`Functor`) as a documented prerequisite of `Monad`, show the `Applicative`
instance alongside each `instance Monad` example rather than omitting it,
and split `fail` out into a short note on `MonadFail` (ideally right where
the book currently claims every monad gets `fail` "for free" via a default
— that claim needs qualifying, not just supplementing). All three worked
examples in the chapter (`MP`/`SParse`, `State`) already have a working,
tested, AMP/MFP-compliant version sitting in the shipped code
(`Calculator/CalcParseLib.hs` and, as of this report, `ParseLib.hs` are both
the version that preserves the book's stated semantics for `fail`, rather
than quietly dropping them — those two copies of the same book example now
match each other, so there is a single, consistent pattern to copy into a
revised Chapter 18 rather than two diverging ones).
