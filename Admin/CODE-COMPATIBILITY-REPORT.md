# Code Compatibility Report: `Code/Craft3e` against current GHC/GHCi

Prepared in response to the request to (1) identify what needs to change in
`Code/Craft3e` for it to load cleanly under a current GHCi, and (2) recommend
how module dependencies should be delivered to readers. **No files in `Book/`
or `Code/` were modified to produce this report.** All testing was done
against a scratch copy of `Code/Craft3e`.

Test environment: GHC 9.6.7 / cabal-install 3.12.1.0 (GHCup), macOS, with
network access to Hackage. GHCi version differences between 9.x releases are
very unlikely to change any of the findings below — the issues found are
either long-settled language/library changes (10+ years old) or pre-existing
source bugs.

## Companion reports

This report has since become the base layer for several others in `Admin/`,
each building on it rather than duplicating it:

- `Admin/RUNNING-HASKELL-OPTIONS-REPORT.md` — how a reader gets GHC/GHCi
  running in the first place (GHCup, Docker, Codespaces/Gitpod, browser
  playgrounds), one layer underneath the module/dependency questions this
  report answers.
- `Admin/DEVELOPMENT-ENVIRONMENT-OPTIONS-REPORT.md` — one layer above both:
  what a reader edits code *in* (VS Code + HLS, Neovim/Emacs, terminal-only),
  once GHC is available.
- `Admin/CODE-VS-BOOK-DISCREPANCIES-REPORT.md` — a narrower, related
  question this report's compile-only methodology didn't originally cover;
  see "Update" immediately below.
- `Admin/SOURCE-FORMAT-OPTIONS-REPORT.md` — a different axis entirely (what
  format the book's own prose/typesetting should live in for a future
  rewrite), which folds in the discrepancies report's finding as a
  concrete argument for keeping code listings mechanically tied to
  `Code/Craft3e` rather than hand-transcribed.

## Update

Since this report was first written, `ParseLib.hs` and its stray duplicate
`Chapter19/parselib.hs` (see "Files that look orphaned" below) were both
given an explicit `instance MonadFail (SParse a)`, matching the fix already
present in `Calculator/CalcParseLib.hs`. This wasn't a compile error — both
files already built cleanly under the "Headline finding" below — but a
*semantic* gap this report's compile-only methodology didn't catch: the
book's `fail s = MP none` (its worked parsing-monad example, Chapter 18)
had been silently dropped from `SParse`'s API rather than moved to
`MonadFail`, the same way the Applicative-Monad Proposal and MonadFail
Proposal required for `Calculator/CalcParseLib.hs`'s copy of the same type.
See `Admin/CODE-VS-BOOK-DISCREPANCIES-REPORT.md` for the full analysis and
`Code/Craft3e/ParseLib.hs`/`Code/Craft3e/Chapter19/parselib.hs`'s current
`instance MonadFail (SParse a) where fail s = SParse none` for the fix.

A follow-up sweep of the exercise-solution and orphaned files for the same
class of gap (missing `Applicative`/`Functor` alongside a custom `Monad`
instance) turned up one more, previously undocumented here: `Solutions18.hs`
defines `instance Monad Mlist` (Solution 18.22, an exercise solution, not a
scratch/orphan file) with no `Applicative`/`Functor` instance at all — a
genuine, live compile error (`No instance for (Applicative Mlist)`,
confirmed directly with `ghc -fno-code`), missed by this report's original
methodology because loading `Solutions18.hs` via `cabal repl` hits the
already-documented `SolutionsSet.hs` indentation bug first (see 1a below),
masking the separate error underneath it. Now fixed, the same way as every
other instance of this gap in the package: `instance Applicative Mlist`
(`pure = return; (<*>) = ap`) and `instance Functor Mlist` (`fmap = liftM`)
added alongside the existing `instance Monad Mlist`, plus a
`Control.Monad (liftM, ap)` import; confirmed compiling cleanly with the
same benign `-Wnoncanonical-monad-instances` warnings every other fixed
instance in this package produces. `IO/TreeId.hs`'s `Id` and
`IO/TreeState.hs`'s `State` have the identical gap (see 1b and "Files that
look orphaned" below) but were deliberately left as-is, consistent with
this report's existing recommendation to exclude those two files from
delivery rather than patch them — neither is an exercise solution, and
`IO/` isn't even in `hs-source-dirs`. No other file among the exercise
solutions or orphans (`Foo.hs`, `Test.hs`, `UsePictures.hs`,
`Chapter19/PositionedImages.hs`) defines a custom `Monad` instance at all;
this is the complete set.

**Sweep complete.** A final pass specifically over `Chapter19/` and
`Simulation/` (the two directories not otherwise itemised by name above)
found nothing further: `Chapter19/parselib.hs`'s `SParse` (already fixed,
above) is the only custom `Monad` instance in either directory, and every
other `Monad`-related mention there is an ordinary import of standard
library machinery (`Control.Monad`, `Control.Monad.State` in
`Chapter19/PositionedImages.hs`; `liftM`/`liftM2` in `Chapter19/QC.hs`), not
a hand-rolled instance. Combined with the exposed-modules check (Headline
finding), the exercise-solutions/orphans check immediately above, and this
final pass, **every `.hs` file under `Code/Craft3e` has now been checked
for the Applicative-Monad-Proposal/MonadFail-Proposal gap**, and the full
list of instances affected is: `ParseLib.hs`, `Calculator/CalcParseLib.hs`,
`Chapter19/parselib.hs`, and `Chapter18.hs` (all fixed and shipped),
`Solutions18.hs` (fixed and shipped, this report), and `IO/TreeId.hs` /
`IO/TreeState.hs` (left as-is, excluded-from-delivery orphans). Nothing else
in the tree has this gap.

**Released.** The `ParseLib.hs` fix — the one instance of this gap that
actually reaches Hackage's `cabal sdist` (confirmed directly: neither
`Solutions18.hs` nor `Chapter19/parselib.hs`'s copy affects what
`cabal unpack`/`cabal install Craft3e` ever delivered, since only
`exposed-modules`/`extra-source-files` get packed, and `Solutions18.hs`
isn't either) — has shipped as `Craft3e-0.2.0.3` on Hackage. Confirmed live
by running `cabal update && cabal get Craft3e-0.2.0.3` fresh and checking
the downloaded `ParseLib.hs` for the `instance MonadFail (SParse a)`. A
reader who fetches the package the book's own documented way
(`cabal unpack Craft3e`) rather than cloning this repository now gets the
fix too. See `Admin/RUNNING-HASKELL-OPTIONS-REPORT.md` for the reader-facing
write-up of this.

A follow-up release, `Craft3e-0.2.0.4`, updated the package's own metadata
(`copyright`, `homepage`, `synopsis`) and cleared the `HUnit`
missing-upper-bound warning plus a `time`/`open-browser`
trailing-zero-upper-bound warning Hackage's uploader flags but local
`cabal check` in this environment doesn't. One finding worth recording
here: an initial attempt to set `license: CC-BY-NC-SA-4.0` (matching the
book's own front-matter licensing) was rejected server-side by Hackage's
uploader ("Invalid package") — Hackage requires an OSI-approved license,
and Creative Commons' NonCommercial clause isn't OSI-approved.
`Craft3e`'s code license stays MIT; only the book's prose is CC BY-NC-SA
4.0. Confirmed live by downloading the published `0.2.0.4` tarball
directly and checking its `Craft3e.cabal`/`LICENSE`.

Every other finding below is unaffected and still accurate.

## Update 2 (2026-09-04)

The five remaining Part 1 fixes below — `SolutionsSet.hs`, `Solutions7.hs`,
`Solutions12.hs`, `Chapter19/Solutions19.hs`, `SolutionsParsing.hs` — have
now been applied directly to `Code/Craft3e` and confirmed loading cleanly
via `cabal repl`. The tables below are left as originally written (they
still correctly describe the underlying issues) but each fixed row is
annotated **— fixed**.

Fixing `Solutions12.hs`'s `Word` ambiguity surfaced two further,
previously-undocumented errors underneath it — the same
error-masks-another-error pattern this report already noted for
`Solutions18.hs`/`SolutionsSet.hs` above:

- **A pre-existing bug, not a GHC-evolution issue**: three uses of `<*>`
  (in `plus`, `digString`, `fraction`) were actually meant to be Chapter
  12's own regex-sequencing operator `<++>` — `<*>` isn't defined anywhere
  reachable from this file at all, on any GHC version. Fixed by replacing
  all three with `<++>`.
- **A genuine, previously-unrecorded GHC-evolution issue**: `majority`'s
  intentionally-unfinished `major = undef` stub (`undef = undef`, a
  self-referential placeholder) becomes `Couldn't match ... arising from a
  use of 'null'` / ambiguous `Foldable` instance under current GHC, because
  `null` was generalised from `[a] -> Bool` to `Foldable t => t a -> Bool`
  by the Foldable/Traversable-in-Prelude proposal (`base-4.8`, 2014) — the
  same release as the Applicative-Monad Proposal. Pre-2014, `null`'s
  list-only type alone pinned `major`'s type down; today nothing does.
  Fixed by annotating the stub: `major = undef :: [Chapter8.Move]` (needing
  a new `import qualified Chapter8 (Move)`, since the unqualified import
  already hides `Move` to avoid a clash with `Chapter4`'s own `Move`, used
  for RPS).

Confirmed via `cabal build` (whole package, zero errors) and `cabal repl`
+ `:load` for each of the five files individually. See
`Code/Craft3e/Solutions12.hs`, `Solutions7.hs`, `SolutionsSet.hs`,
`SolutionsParsing.hs`, `Chapter19/Solutions19.hs` for the current fixed
source.

## Headline finding

**The book's main chapter code is already clean.** All 20 chapters' primary
listings — the ~68 modules cabal already knows how to build (see
`Craft3e.cabal`'s `exposed-modules`, which lines up with `README.txt`'s
chapter table) — compile with **zero errors** under GHC 9.6.7 via
`cabal build`, using the project's *existing, unmodified* dependency bounds
(`QuickCheck >= 2.1 && < 3`, `mtl >= 1.1 && < 2.3`, `old-locale == 1.0.*`,
`open-browser >= 0.1.0.0 && < 0.5.0.0`, etc.). cabal's solver resolves all of
these against current Hackage (QuickCheck-2.16.0.0, HUnit-1.6.2.0,
mtl-2.2.2, old-locale-1.0.0.7, open-browser-0.4.0.0, time-1.12.2). There are
a handful of harmless `-Wnoncanonical-monad-instances` warnings (old-style
`instance Monad` definitions that predate the `Applicative`-first idiom) but
no errors.

The problems are concentrated in a smaller, well-defined set of files: the
**per-chapter exercise-solution files** (`SolutionsN.hs`), which are not
part of the cabal package's `exposed-modules` and so were never build-tested
before, plus a handful of files that look like leftover personal/scratch
material rather than book content (see "Files that look orphaned" below).

## Methodology

- Copied `Code/Craft3e` to a scratch directory (not `Code/`).
- Ran `cabal build all` against the unmodified `Craft3e.cabal` — this
  compiles every module listed in `exposed-modules`.
- For every `.hs` file that exists under `Code/Craft3e` but is *not* in
  `exposed-modules` (all `SolutionsN.hs` files, `Chapter15/Solutions15.hs`,
  `Chapter16/Solutions16.hs`, `Chapter19/Solutions19.hs`,
  `Chapter19/PositionedImages.hs`, `Foo.hs`, `UsePictures.hs`, the four files
  under `IO/`, and the duplicate `Chapter19/parselib.hs`), ran `cabal repl`
  against the library (which loads all 67 "official" modules interpreted)
  and then `:load`ed the extra file, mirroring what a reader who has the
  package built would experience typing `:load SolutionsN` inside GHCi.
- Cross-checked `Book/*.tex` for the files with errors, to see whether they
  are actually pulled into the book text. Only `Chapter2.tex` does this
  mechanically (`\input{FirstScript.hs}`); everything else is prose-authored
  code listings, so "does this file compile" and "is this file's *text*
  correctly transcribed into the book" are independent questions — this
  report only addresses the former.

## Part 1: Code modifications needed

### 1a. Genuine pre-existing bugs (would have failed on *any* GHC version)

These are plain indentation/layout mistakes, unrelated to library or
language changes. They would never have compiled, on any Haskell compiler,
in the form currently in the repository.

| File | Problem | Minimal fix |
|---|---|---|
| `SolutionsSet.hs:114-116` — **fixed** | In `makeSet`'s `where`-clause, the guards of `remDups (x:y:xs)` are indented *less* than the clause head, prematurely closing the layout block: `\| x < y = ...` sits at column 9, `remDups (x:y:xs)` at column 11. | Re-indent the two guard lines to at least column 11, e.g. align them under `remDups (x:y:xs)`. |
| `IO/TreeState.hs:29-33` | In the `let` inside `(State st) >>= f`, the second binding `(State trans) = f y` is indented *less* than the first (`(newTab,y) = st tab`), so the `let` block closes early. | Indent `(State trans) = f y` to the same column as `(newTab,y) = st tab`. |
| `IO/DoTest.hs:26-28` | In `putNtimes`'s `else do putStrLn str`, the next `do`-statement `putNtimes (n-1) str` is indented *less* than `putStrLn str` (which sets the block's column), so only one statement remains in the block and the parser then rejects the leftover text. | Indent `putNtimes (n-1) str` to the same column as `putStrLn str`. |

### 1b. Real GHC/library evolution since 2011

These are the actual "the language moved on" issues — every one has a
one-line or few-line fix, no rewrite required.

| File | Problem | Root cause | Minimal fix |
|---|---|---|---|
| `Solutions7.hs:435` (cascades to `Solutions8.hs`, which imports it) — **fixed** | `Ambiguous occurrence 'Word'` | `Chapter7.hs` defines its own pedagogical `type Word = String`; `Word` was later added to the standard `Prelude` (as the unsigned machine-word numeric type) after this book's `Word` type was written. `Solutions7.hs` imports `Chapter7` and `Prelude` unqualified without hiding either's `Word`. | Add `Word` to the existing `Prelude hiding (...)` list at the top of `Solutions7.hs` (or hide it from the `Chapter7` import instead). |
| `Solutions12.hs` — **fixed** (see "Update 2" above for two further masked bugs found while fixing this one) | Same `Ambiguous occurrence 'Word'`, this time between `Index.hs`'s `type Word = String` and `Prelude.Word` | Same cause as above; `Solutions12.hs`'s own `import Prelude hiding (succ,lines)` doesn't hide `Word`. | Add `Word` to that hiding list. |
| `Chapter19/Solutions19.hs` — **fixed** | `Ambiguous occurrence '<*>'` | `Chapter19/RegExp.hs` defines its own regex-sequencing operator `(<*>)`. `<*>` was later made a `Prelude`-exported method of `Applicative` (the Applicative-Monad Proposal, GHC 7.10/2015). `Solutions19.hs` imports `RegExp` and (implicitly) all of `Prelude` without hiding either's `<*>`. | Add `import Prelude hiding ((<*>))`, or `import RegExp hiding ((<*>))`, to `Solutions19.hs`. |
| `IO/TreeId.hs` | `No instance for (Applicative Id)` | Same Applicative-Monad Proposal: since GHC 7.10, every `Monad` instance requires a corresponding `Applicative` instance; `instance Monad Id` here has none. | Add `instance Functor Id where fmap f (Id x) = Id (f x)` and `instance Applicative Id where pure = Id; Id f <*> Id x = Id (f x)` above the existing `instance Monad Id`. |
| `Solutions18.hs` (Solution 18.22) — **fixed** | `No instance for (Applicative Mlist)` | Same Applicative-Monad Proposal; `instance Monad Mlist` here had none. | Added `instance Applicative Mlist where pure = return; (<*>) = ap` and `instance Functor Mlist where fmap = liftM`, plus `import Control.Monad (liftM, ap)`. |
| `IO/MonadIO.hs:10` | `Could not find module 'IO'` | `import IO` refers to the pre-Haskell-2010 monolithic `IO` compatibility module, removed from `base` long ago. | Change to `import System.IO`. |
| `SolutionsParsing.hs:120` — **fixed** | `Parse error in pattern: n + 1` | `nTimes (n+1) p = ...` uses an "n+k pattern", a Haskell 98 feature dropped from the language in the Haskell 2010 report (GHC keeps it only behind the now-off-by-default `NPlusKPatterns` extension, still available in GHC 9.6.7). | Either add `{-# LANGUAGE NPlusKPatterns #-}` at the top of the file, or (preferable for an introductory text, since the extension is obscure and non-standard today) rewrite as a guard: `nTimes n p \| n > 0 = (p >*> nTimes (n-1) p) \`build\` (uncurry (:))` with a base case `nTimes 0 p = succeed []` already present. |
| `Chapter19/PositionedImages.hs:12` | `Could not load module 'Data.Map' — hidden package 'containers'` | `containers` is a GHC boot library but is *not* automatically exposed the way `base` is; it must be a declared dependency. | Add `containers` to `build-depends` in `Craft3e.cabal` if this file is kept (see "orphaned" note below — recommend dropping it instead). |

Two more files (`IO/DoTest.hs`, `IO/MonadIO.hs`, `IO/TreeId.hs`,
`IO/TreeState.hs`) also have **no `module Foo where` header at all**, so GHC
defaults each to `module Main`. This is harmless for loading any *one* of
them alone, but means they can never be loaded together in one GHCi session
(all four collide as `Main`) and is inconsistent with every other file in
the package. If kept, each should get an explicit header matching its
filename (`module DoTest where`, `module MonadIO where`, etc).

### Files that look orphaned (recommend excluding from what's delivered to readers, rather than fixing)

None of these are referenced anywhere in `Book/*.tex`, and none are in
`Craft3e.cabal`'s `exposed-modules` — they sit in directories the `.cabal`
file's own `hs-source-dirs` don't reach at all (`IO/`) or are simply omitted
from the module list despite being co-located with files that are (`Foo.hs`,
`Chapter19/parselib.hs`).

- **`IO/DoTest.hs`, `IO/MonadIO.hs`, `IO/TreeId.hs`, `IO/TreeState.hs`** —
  the `IO/` directory isn't even on the cabal package's `hs-source-dirs`.
  `TreeId.hs`/`TreeState.hs` look like earlier drafts of ideas that ended up
  properly written (with correct `Applicative` instances) inside
  `Chapter18.hs`. Nothing in the book text points a reader at this folder.
- **`Foo.hs`, `Test.hs`** — no header comment, no chapter/exercise
  attribution (compare to every real solutions file, which opens with a
  `-- Solutions to Exercises N.N` banner); read as the author's own
  scratch/experimentation files.
- **`Chapter19/parselib.hs`** — byte-for-byte identical to the top-level
  `ParseLib.hs` (confirmed via `diff`, still true after both files' shared
  `MonadFail` fix, see "Update" above), both declaring `module ParseLib`. A
  stray duplicate; this is *why* it's excluded from `exposed-modules` (cabal
  would reject two same-named modules in one package).

If the intent is a minimal, coherent reader-facing package, these five files
could simply be dropped from what's shipped. If they should be kept for
completeness, `PositionedImages.hs`'s one-line `containers` fix and the
`IO/` files' fixes above are all that's needed.

### Files confirmed clean, no action needed

All of `Chapter1.hs`–`Chapter20.hs` (including the `Chapter15`, `Chapter16`,
`Chapter19`, `Chapter20`, `Calculator` and `Simulation` sub-modules),
`ParseLib.hs`, `ParsingBasics.hs`, `Pictures.hs`, `PicturesSVG.hs`, `Set.hs`,
`Relation.hs`, `Index.hs`, `RPS.hs`, `UseMonads.hs`, `FirstScript.hs`,
`UsePictures.hs`, and, as of the fixes under "Update" and "Update 2" above,
all 17 of the top-level `SolutionsN.hs` files (`Solutions2,3,4,5,6,7,9,10,
11,12,13,14_1,14_2,17,18,20`, `SolutionsSet`, `SolutionsParsing`), plus
`Chapter15/Solutions15.hs`, `Chapter16/Solutions16.hs`, and
`Chapter19/Solutions19.hs`, now load without error.

## Part 2: Delivering module dependencies to readers

The book's own workflow ("start GHCi, `:load ChapterN`") silently assumes
every sibling module and every third-party package (`QuickCheck`, `HUnit`,
`time`, `mtl`, `old-locale`, `open-browser`) is already visible to GHCi. On
a stock, freshly-installed GHC (e.g. via GHCup, which is now the standard
install path), **none of that is true out of the box**: a bare `ghci
Chapter5.hs` fails immediately on `import Test.QuickCheck` (package not
installed), and even GHC's own boot libraries like `containers` are hidden
by default unless something explicitly exposes them. Two options were
tested and both work; they suit different audiences.

### Option A — keep the existing Cabal package, readers use `cabal repl` (recommended)

`Craft3e.cabal` already works, unmodified, against current GHC/cabal (see
Headline finding above). A reader needs only:

```
cabal build          # once, downloads + builds all dependencies
cabal repl            # drops into GHCi with all 20 chapters' modules
                       # already loaded and every dependency in scope
```

Inside that REPL, `:load Solutions5` or `:load Chapter19/Solutions19` works
directly (verified above), because `cabal repl`'s GHCi session already has
every `hs-source-dirs` entry on its search path and every declared package
visible.

**Pros:** zero new files to author or maintain; matches how any other
modern Haskell project is built, which is a transferable skill; cabal's
dependency solver — not the reader — deals with version resolution.
**Cons:** `cabal repl`/`cabal build` are extra vocabulary beyond "just start
ghci", relevant for a book aimed at newcomers; first run downloads and
compiles ~10 dependency packages, which takes a few minutes and needs
network access.

**Addendum: readers adding their own files under Option A.** This was
tested directly (scratch copy, not `Code/`): after the automatic 67-module
load, `cabal repl`'s `:load` is not restricted to the paths listed in
`Craft3e.cabal`'s `hs-source-dirs` — it happily loads a brand-new file the
reader creates anywhere under `Code/Craft3e` (tested both at the top level
and inside a freshly-created subdirectory), and that file can freely
`import` any existing chapter module or any of the package's declared
dependencies (confirmed with `import Chapter5 (minAndMax)` alongside
`import Test.QuickCheck`, with `quickCheck` run successfully against a
property in the new file). The only side effect is a harmless
`-Wmissing-home-modules` warning when the new file imports a chapter module
that isn't itself in `exposed-modules`. Workflow for a reader:

1. `cd Code/Craft3e && cabal repl` — as above.
2. In an editor, create e.g. `Code/Craft3e/MyExercise.hs` starting with
   `module MyExercise where`, with whatever `import`s are needed.
3. In the REPL: `:load MyExercise`.
4. After further edits, `:reload` — no `.cabal` changes or REPL restart
   needed.

### Option B — a shared package environment + a checked-in `.ghci`, readers use bare `ghci`

This reproduces the book's original "just run `ghci Chapter5.hs`" workflow
exactly. It was verified end-to-end: a **one-time** setup step

```
cabal install --lib QuickCheck HUnit time old-locale mtl containers open-browser
```

registers those packages into a GHC *package environment* file that plain
`ghci` (no cabal project, no `.cabal` file involved) picks up automatically
from then on. Combined with a small `.ghci` file checked into
`Code/Craft3e/` —

```
:set -i.:Calculator:Chapter15:Chapter16:Chapter19:Simulation:Chapter20
```

— a reader can `cd` into `Code/Craft3e` and run plain `ghci`, then
`:load Chapter5` or `:load Solutions4` directly; both were confirmed to load
cleanly this way in testing.

**Pros:** closest match to the book's existing instructions and to what a
beginner expects ("just open ghci and load a file"); no cabal/project
vocabulary needed after the one-time install. **Cons:** the one-time
`cabal install --lib ...` step is still unavoidable (bare GHCi cannot
resolve dependencies itself); a global/user package environment is somewhat
more "invisible" magic than a project file, and could in principle collide
with packages/versions a reader has installed for unrelated purposes.

### Recommendation

Offer both, but lead with **Option A** as the documented/primary path
(it's what the existing `Craft3e.cabal` already sets up, needs no new
files, and teaches a directly transferable skill), and mention **Option B**
as a "just want `ghci` like the book says" fallback for readers who find
`cabal repl` off-putting. Either way, the existing `Craft3e.cabal`'s
dependency bounds do not need loosening or updating — they already resolve
correctly against current package versions.
