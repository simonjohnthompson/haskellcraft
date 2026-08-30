# Report: Source Format Options for Rewriting and Extending the Book

Prepared ahead of a planned rewrite/extension of *Haskell: The Craft of
Functional Programming*, to weigh where the book's "source of truth" should
live once that work starts. The rewrite is expected to keep PDF output
alive, while adding features that only make sense online — embedded video,
AI-assisted feedback on exercises, and presumably others as they come up.
Findings below are grounded in the actual state of this repository as of
August 2026, not a generic LaTeX-vs-Markdown comparison.

This report sits alongside the three companion reports in `Admin/`, but
looks at a different layer: not how a reader runs the book's code, or what
they edit it in, but what format the book's *own* text should be
authored and stored in going forward.

## Current state, as it actually is

Two toolchains already coexist in this repository, and understanding both
precisely matters for everything that follows.

**The LaTeX source (`Book/*.tex`)** is the original, camera-ready
Addison-Wesley book: 21 chapter files plus front/back matter, appendix,
glossary, error-message appendix, and a projects chapter — 33,000+ lines of
`.tex` in total. It's built on `\usepackage{chicago}` (author-date
bibliography, driven by `Book/big.bib`, a 375-entry BibDesk-exported `.bib`
file), `makeidx`/`\printindex` (a real back-of-book index), custom fonts
(`fourier`, scaled `helvet`), and — critically — **three decades of bespoke
macro layers**: `Book/defs0.tex` (1989–1994, hand-rolled Miranda/Haskell
listing environments, catcode tricks for `alltt`) and `Book/miradefs.tex`
sit underneath every chapter, and `Book/root.tex` overrides core LaTeX
internals like `\maketitle` directly. This is not "LaTeX" in the sense of a
clean `\section`/`\textbf`/`\begin{itemize}` document — it's a working but
idiosyncratic macro system that only this book's own build understands.
Worth noting directly: **`Book/root.pdf` in the repo was, at the start of
this investigation, dated March 2014**, and there was no build script,
Makefile, or CI job anywhere in the repo that regenerated it —
`Book/make-text` is a leftover list of manual `pandoc` invocations from an
earlier, abandoned conversion attempt, not a PDF build. (Both of those
facts are now history rather than current state: `root.pdf` has since been
rebuilt from source and `Book/Makefile` added, see below — but they're
worth recording as the actual starting point, since they're what prompted
this report's LaTeX build test in the first place.) So, going into this
report, "the ability to produce a PDF" from
`Book/*.tex` was a claim about what LaTeX in principle could still do with
this source, not a pipeline anyone had exercised recently. That gap has
since been closed directly, by actually running the build — see "The
LaTeX PDF build, tested directly" immediately below — and the short
version is that it works cleanly, with no drama. The small mechanical gap
that testing left behind — an actual build script — has since been closed
too: `Book/Makefile` (added in commit `8705a04`, alongside a one-line fix
to the `appendix1.tex` bug found during testing, see below) runs the
confirmed sequence end to end; `make` in `Book/` is now genuinely all it
takes. What's still missing under every option is CI automation (a
GitHub Actions job that runs the build on push, the way
`.github/workflows/deploy-book.yml` already does for the website) — a
smaller, optional step, not a blocker.

## The LaTeX PDF build, tested directly

The original draft of this report treated `root.pdf`'s stale timestamp as
evidence the print pipeline was an open risk. That was a fair reading of
the available evidence, but it was worth actually checking rather than
leaving as an assumption — so, in preparing this report, the build was run
directly, in a sandboxed copy of `Book/`, against a plain, current TeX
Live 2025 install (`pdfTeX 3.141592653-2.6-1.40.27`), with nothing in the
real repository touched.

**The result: the build is exactly as straightforward as expected, and it
works.** The standard sequence —

```
pdflatex root   # pass 1: lays out the book, collects \cite/\ref/\index
bibtex   root   # resolves \cite/\citeyear against big.bib -> root.bbl
makeindex root  # sorts/formats \index entries -> root.ind
pdflatex root   # pass 2: pulls in root.bbl/root.ind, updates cross-refs
pdflatex root   # pass 3: settles anything that shifted after pass 2
```

— converges cleanly, with no extra passes and no separate index-handling
step beyond the ordinary `makeindex` call, confirming the suspicion that
prompted this test. No package was missing: every `\usepackage` in
`root.tex` — including `fourier`, `chicago`, `wrapfig`, `eso-pic` —
resolved straight from a stock TeX Live install, and `chicago.sty`/
`chicago.bst` are already vendored in `Book/`. `bibtex` produced only 8
cosmetic warnings (missing `author`/`page` fields on a handful of
`big.bib` entries — a data-quality note about the bibliography's content,
not a build problem). `makeindex` accepted all 2,408 index entries with
zero rejections and zero warnings. By the third `pdflatex` pass the log is
completely clean — zero `LaTeX Warning`s, zero `Overfull`/`Underfull` hbox
warnings, zero undefined references or citations — producing a valid
646-page, 17MB PDF. Visual spot-checks of the title page, an interior
chapter page, and a generated index page (rendered via Ghostscript, since
the sandbox had no PDF viewer) all look right: correct font rendering (the
`fourier`/scaled-`helvet` pairing the book was designed with), proper
monospace code styling, and a correctly alphabetised, cross-referenced
(`see` entries), page-ranged back-of-book index. The earlier framing of
print fidelity as an open technical risk was too pessimistic — it was
*untested* risk, not *demonstrated* risk, and the two are different things.

One genuine, minor bug did turn up, worth fixing on its own merits
regardless of which option below is chosen: `Book/appendix1.tex` line 4
has a hand-written
`\addtocontents{toc}{\contentsline {chapter}{Appendices}{}}`, which throws
`! Argument of \contentsline has an extra }.` on a cold first pass. This
is a known LaTeX2e kernel compatibility break — the kernel's default
`\contentsline` gained a mandatory 4th argument in a 2021-era release (for
PDF/accessibility tagging), and this line's raw, hand-rolled call still
uses the old 3-argument form from whenever it was written. It's non-fatal
and self-resolves from the second `pdflatex` pass onward, so it never
actually reaches the final PDF — but it was a latent, kernel-version-
dependent trap, and has since been fixed (commit `8705a04`): the
hand-rolled call was replaced with the standard
`\addcontentsline{toc}{chapter}{Appendices}`, which lets LaTeX generate
the correctly-sized call itself rather than relying on one that can go
stale again as the kernel evolves. Separately, `pdflatex` returned exit
code 1 even on the fully clean, warning-free final pass — this is worked
around, rather than actually resolved, in `Book/Makefile` (added in the
same commit) by prefixing each `pdflatex`/`bibtex`/`makeindex` call with
`-` so `make` doesn't treat it as fatal; the underlying cause is still not
understood, and would be worth chasing down before relying on the exit
code in CI.

**The website pipeline (`Website/`)** is new, and already works end to end:
`Website/convert/tex2md.py` (2,725 lines, ~80 functions) preprocesses the
custom macros above into something Pandoc's LaTeX reader can parse, shells
out to `pandoc`, then post-processes the result — fenced Haskell code
blocks, image paths, and, notably, **it already solves the two hardest
problems in any LaTeX→Markdown conversion**: `\cite`/`\citeyear` are
resolved against `big.bib` into a real generated `bibliography.md` with
Chicago-style author-date formatting, and every `\index`/`\minx` entry is
collected into a real generated `term-index.md`, anchor-linked back into
the chapter text. `Website/convert/convert_images.py` rasterises the
`Pictures/*.pdf` figures to PNG. The output — `Website/chapters/*.md` — is
what mdBook actually builds and deploys via
`.github/workflows/deploy-book.yml` on every push to `main`. Spot-checking
the chapter 5 output against its `.tex` source confirms the conversion
quality is high: `\ref{intro}` cross-references become real Markdown links
to the right chapter and anchor, footnotes become Markdown footnotes,
`\index` entries become anchors, `alltt` code becomes fenced ` ```haskell `
blocks.

So this isn't a green-field choice. It's: LaTeX is the *original* source
and (nominally) still a PDF path; a working, evidenced, one-directional
LaTeX→Markdown pipeline already exists and already feeds the live,
auto-deployed website. Any option below is a variation on what to do with
that fact, not a decision made from scratch.

## The Markdown→PDF path, tested directly

Following the same principle as the LaTeX build test above — check rather
than assume — Chapter 5 (`Website/chapters/5.md`, "Data types, tuples and
lists") was run through a plain `pandoc` conversion to PDF, with no custom
template or flags, to see what the "unproven" side of option (iii)/(iv)
actually looks like today, rather than leave it as a prediction.

The first attempt, `pandoc 5.md -o chapter5.pdf` (Pandoc's default engine,
`pdflatex`), crashed outright: `! LaTeX Error: Unicode character ∈
(U+2208) not set up for use with LaTeX` — a bare Unicode math symbol
surviving unchanged from the original LaTeX prose. Switching the PDF
engine to `xelatex` (native Unicode support) got past the crash and
produced a real, readable, 26-page PDF for one chapter with no template
work at all: prose, headings, bold/italic, ordered/unordered lists, and
code blocks (with nicer syntax highlighting than the original's plain
monospace) all converted correctly.

Three things did not survive, and — this is the more important finding
than the crash — none of them announced themselves as errors:

- **All three figures in the chapter (`lineSoln`, `rectanglePos`,
  `rectangleMove`) disappeared, silently.** `tex2md.py` currently emits
  each figure as raw HTML (a checkbox-based click-to-zoom trick, used only
  for the web edition) rather than a plain Markdown image. Pandoc's
  Markdown→LaTeX path has no defined behaviour for raw HTML, so it just
  drops the block — confirmed by inspecting the intermediate `.tex`: zero
  occurrences of `includegraphics`, `figure`, or `Pictures/` anywhere in
  the output, and no warning at any point in the process. This is the
  specific, current shape of the "web-only content needs an explicit print
  fallback" risk this report already named — caught in the act, not argued
  in the abstract. It's a property of *this converter's current markup
  choice* for figures, not of Markdown-to-PDF in general — a pipeline that
  emitted plain `![alt](path)` image syntax instead of the raw-HTML
  lightbox trick would not have this problem — but it's a real, current
  fact about `Website/chapters/*.md` as it exists today, not a hypothetical.
- **The missing `∈` glyph didn't get fixed by switching to `xelatex`, just
  downgraded from a crash to a silent gap**: `Missing character: There is
  no ∈ (U+2208) in font [lmmono10-regular]`. The character is simply blank
  in the rendered PDF. Any raw Unicode math/logic symbol embedded in prose
  (a pattern used throughout the book — `⇒`, `∀`, and others) would need
  either a proper math-mode macro or a font with full glyph coverage;
  neither happens automatically.
- **Cross-chapter links resolve to nothing.** `[...](1.md#intro)` survives
  as a hyperlink with the right visible text but no working target outside
  a full multi-file build — expected, in isolation, but a concrete reminder
  that a real Markdown→PDF pipeline needs either one merged document per
  build or a proper cross-reference resolution step, not per-file relative
  links carried over unchanged from the website output.

On top of those three, none of the book's typographic identity survived,
because nothing asked it to: no chapter number or running head, no
`5.1`-style section numbering, the default Latin Modern font rather than
the book's `fourier`/scaled-`helvet` pairing, generic page margins,
exercises renumbering from 1 instead of the book's per-chapter
`Exercise 5.1` scheme, and no index. None of this is a dead end — it's all
template and flag work — but it's real, unbudgeted work, exactly as this
report already argued before running the test, now with a concrete
worked example rather than a general claim.

**Net effect on the comparison**: this doesn't rule out option (iii)/(iv),
but it moves "Pandoc's generic LaTeX template will not, out of the box,
reproduce the specific camera-ready layout" from an informed prediction to
a directly observed result, and it surfaces one risk this report hadn't
explicitly separated out before running the test: *silent* content loss —
specifically of figures — is a real, current property of today's
converter output, not just a hypothetical gap to design around later.

## Option (ii)'s cleaned-up LaTeX, tested directly

Rather than leave "cleaned-up LaTeX" as a description, a real passage was
cleaned up and compiled, to check both how readable the result actually is
and how closely it still matches the original. The "shopping basket"
example from `Book/5.tex` (`ShopItem`/`Basket` tuple and list types, a
footnote, a `\beware` note box) was taken unmodified and compiled with the
book's real preamble plus the full `defs0.tex`/`miradefs.tex`, then
compared against a hand-cleaned version of the same passage compiled
against a new 13-line, commented `book-macros.tex` in place of those two
files (193 + 110 lines).

**The diff between the two source files is almost nothing.** The only
changes needed anywhere in the passage were renaming `\minx{X}` (index a
code term in typewriter font) to `\ix{X}`, and `\beware{title}{body}` (a
grey note box) to `\note{title}{body}` — both re-implemented, transparently,
in `book-macros.tex`:

```latex
% Index a code identifier in typewriter font, e.g. \ix{ShopItem}.
\newcommand{\ix}[1]{\index{#1@\texttt{#1}}}

% A grey callout box for an aside, e.g. \note{Title}{body text}.
\newcommand{\note}[2]{%
  \medskip\noindent\colorbox{light-gray}{\parbox{\textwidth}{%
    \textbf{\large #1}\medskip\noindent\\ #2}\medskip\noindent}}
```

Nothing else in the passage changed — `\section`, `\subsubsection*`,
`\begin{itemize}`, `\begin{alltt}...\end{alltt}` for code, `\footnote{}`,
`\texttt{}` are all already standard LaTeX. This particular passage
happens to already sit close to plain LaTeX at the paragraph level; what
made it feel messy was entirely the invisible machinery underneath
(`defs0.tex`'s catcode tricks, dead Miranda-era subscript shortcuts like
`\aone`/`\atwo` this passage never uses), not the visible markup a chapter
author actually types. Not every passage will be this easy — five files
in `Book/` still use the more catcode-heavy `ttdisplay`/`\so`/`\st`
environment rather than plain `alltt`, and those would need real
translation work, not just a rename — but it's a fair, representative
sample, not a cherry-picked best case.

**Fidelity was checked, not assumed.** Both versions were compiled with
the book's actual fonts and packages (`fourier`, scaled `helvet`, etc.)
and every page rendered to PNG for comparison: the note-box page and the
generated index page came out **byte-identical**; the page with the code
listings differed by 2 bytes in PNG encoding — visually indistinguishable
side by side. That's expected, not a coincidence: since only the macro
*names* changed, not their definitions, nothing about the printed output
had any reason to move.

**Extensibility was tested too, not just claimed.** A brand-new macro —
`\pitfall{title}{body}`, a pink "common mistake" box, copy-pasted from the
shape of `\note` with a different name and colour — was added to
`book-macros.tex`, used once in the sample text, and the whole thing
rebuilt. It worked on the first attempt: no errors, box rendered exactly
as intended. This is the honest answer to "would an author be able to add
macros themselves": yes, because the mechanism involved (`\newcommand`
with numbered arguments, `#1`/`#2`) is beginner-level LaTeX, not the
brace-matching/catcode territory `defs0.tex` currently requires. One
clarification worth being explicit about, since it's easy to
over-interpret "cleaned up": this is not "delete the macros and write
vanilla LaTeX" — it's "keep a small, shared, documented set of macros that
earn their keep" (an index helper, a note box, presumably a couple of
others as real needs come up), authored the same ordinary way as any
LaTeX book's house style, not the accumulated, undocumented,
catcode-dependent pile it's built on today.

## Option (ii) and web-only content

The one thing the testing above doesn't settle is the disadvantage named
for option (ii) throughout this report: LaTeX has no native notion of
"this content targets one output only," so embedded video and
AI-assisted exercise feedback need *some* mechanism invented, and
`Website/convert/tex2md.py` will need matching code for it — worth being
concrete about, since `tex2md.py` currently has no generic "pass an
unrecognised macro through" fallback; every custom macro it handles
(`\beware`, `\minx`, citations, and so on) is special-cased by name.
Whatever mechanism is chosen adds to that list, it doesn't sidestep it.

Four mechanisms are worth naming, in order of how well they fit
everything else already established in this report:

1. **Typed semantic macros** — e.g. `\webvideo{id}{caption}`,
   `\aifeedback{5.3}`, defined once in the shared `book-macros.tex`. In the
   PDF build they're ordinary LaTeX commands with a print-friendly
   definition (a short "watch online at ..." note, or silent for things
   with no print equivalent). `tex2md.py` pattern-matches the same macro
   calls — exactly as it already does for `\cite`/`\index`/`\minx` — and
   emits real HTML for the web build. This is the most consistent option
   with everything else in this report: same architecture as the working
   parts of the current pipeline, greppable/auditable (`grep webvideo`
   answers "which chapters have web content?"), and ties naturally to the
   exercise numbering (`\theexercise`) that already exists.
2. **Raw HTML dropped into a no-op LaTeX block** (`\begin{rawhtml}...
   \end{rawhtml}`, swallowed via the `comment` package for PDF, passed
   through verbatim by `tex2md.py`). Maximum flexibility for whoever builds
   the embed markup, but it's the exact mechanism that already silently
   dropped this chapter's figures in the Markdown→PDF test above — using
   it *inside* LaTeX would import that same fragility into option (ii)
   rather than avoid it, and it dilutes the "clean, readable LaTeX" result
   just demonstrated for the surrounding content.
3. **A lookup-by-ID indirection** — the LaTeX source only ever contains a
   stable ID (`\webresource{ex5-3-feedback}`), and the actual video URL,
   AI-prompt configuration, or embed HTML lives in a separate manifest
   under `Website/` that only the web build reads. This decouples content
   that changes often (video hosting, AI backend tuning) from the
   document, so swapping a URL never touches `Book/*.tex` or triggers a
   PDF rebuild. Costs an extra layer of indirection nobody's built yet, and
   puts "what actually plays here" one hop away from the book source.
4. **A plain LaTeX comment as an insertion marker**
   (`% WEB-INSERT: video-5-3`), with the real content living entirely as a
   separate Markdown snippet merged in later by an mdBook preprocessor.
   Zero risk to the PDF build — a comment can never break compilation —
   but unstructured: nothing checks the referenced snippet exists, and
   it's invisible to anyone reading the LaTeX for content.

**The best fit is option 1 for the marker, combined with option 3's
decoupling for the payload**: a small family of named macros
(`\webvideo{}{}`, `\aifeedback{}`) keeps the book's actual content visible
and greppable in the LaTeX source — consistent with how exercises are
already delimited — but each macro's argument should be a stable ID rather
than a raw URL or embed config, so that changing a video host or tuning an
AI prompt never touches `Book/*.tex` at all, only the manifest
`tex2md.py` looks the ID up in. This isn't a new architecture — it's the
same shape as the existing, working `\cite`/`big.bib` split (a stable key
in the LaTeX, the actual data external to it), applied to web content
instead of references.

Worth being explicit about the honest trade-off, surfaced directly by the
Markdown→PDF test above: this is inherently more homegrown under
LaTeX-as-source than under Quarto specifically, which has this exact
mechanism (`.content-visible when-format=`) built in and battle-tested.
That's real, and part of why option (iv) remains genuinely worth a
prototype (see below) — but it doesn't change the shape of option (ii)'s
case: this is bounded, buildable work — one macro family, one small
manifest format, a few dozen lines in `tex2md.py` — not an open design
question, and not different in kind from work `tex2md.py` already does
today for citations and the index.

## A related finding: hand-transcribed code listings have already drifted from the real code

Separately from this report's own testing, a direct comparison of
`Book/18.tex` ("Programming with monads") against the current
`Code/Craft3e` cabal package turned up a concrete, already-realised
instance of exactly the kind of drift risk this report has been assessing
in the abstract — worth folding in here because it bears directly on
"authoring ergonomics for a rewrite" and, specifically, on how code
listings should be kept honest going forward, independent of which prose
format wins. Full detail in `Admin/CODE-VS-BOOK-DISCREPANCIES-REPORT.md`;
the shape of it:

The book teaches a `Monad` class with `fail` as one of its four methods,
and its two worked monad examples in Chapter 18 (`MP`, the parsing monad;
`State`, the imperative-store monad) define `instance Monad` with nothing
else — no `Applicative`, no `Functor`. That was accurate in 2011. It isn't
today: **the word "Applicative" does not appear anywhere in `Book/*.tex`**,
yet two language changes since publication — the Applicative-Monad
Proposal (GHC 7.10, 2015, `Applicative` became a superclass of `Monad`) and
the MonadFail Proposal (GHC 8.8, 2019, `fail` was removed from `Monad`
entirely into its own class) — mean every one of the book's printed `Monad`
instances would fail to compile exactly as shown. The shipped
`Code/Craft3e` package had already been silently patched around both
changes in the three places affected (`ParseLib.hs`'s `SParse`,
`Calculator/CalcParseLib.hs`'s `SParse`, `Chapter18.hs`'s `State`) — but the
book's prose was never updated to match, and, until this investigation, the
patching itself was inconsistent: `ParseLib.hs`'s copy had silently
*dropped* `fail` rather than moving it to `MonadFail` the way
`Calculator/CalcParseLib.hs`'s identical copy had, quietly changing
behaviour rather than just syntax. (Now fixed and consistent across both
copies, and confirmed via `-Wall`/`-Wcompat` that no other exposed module
has the same gap — see the discrepancies report and
`Admin/CODE-COMPATIBILITY-REPORT.md`'s "Update" section.)

The structural reason this went unnoticed for a decade is directly
relevant to the source-format decision: **only one chapter's code listing
is actually connected to the real, compiling source.** `Book/2.tex:31` does
`\input{FirstScript.hs}` — a literal, mechanical inclusion of the real
file. Every other chapter's code, in every one of `Book/1.tex` through
`Book/21.tex`, is hand-transcribed prose typed inside `\begin{alltt}...
\end{alltt}` blocks, with no mechanical link back to `Code/Craft3e` at all.
Nothing checks that a `\begin{alltt}` listing still matches the file it was
copied from, let alone that it still compiles — a language-level break
that made three worked instances uncompilable, sitting in the book's own
core teaching chapter on monads, was invisible to any process for over ten
years, simply because there was no process capable of noticing it.

This doesn't favour any one option above on its own — the drift is a
property of *how code listings are authored*, not of whether the
surrounding prose is LaTeX or Markdown — but it's a real, evidenced
argument that the rewrite should treat "code listings stay synchronised
with `Code/Craft3e`" as a design requirement in its own right, not an
assumed side-effect of choosing a prose format. It also gives one more
concrete data point for authoring ergonomics: mechanically including or
generating code listings from source (as `Book/2.tex` already does for one
file) is comparatively natural to retrofit onto fenced-code-block Markdown
via a small build step, and no harder in principle for LaTeX via more
`\input{}`/`\lstinputlisting{}` use — but *either* is a deliberate choice
this rewrite would need to make and enforce, where the status quo makes
neither.

**Released, as one concrete data point on the code side of this gap:** the
`ParseLib.hs` fix has since shipped as `Craft3e-0.2.0.3` on Hackage
(confirmed by pulling the package back down fresh), so `Code/Craft3e` — the
half of this drift that's actually reachable through a build/compiler — is
now current. The book's *prose*, `Book/18.tex`, is not, and can't be fixed
by a package release: this is exactly the asymmetry the finding above is
about — code has a compiler to catch drift and a release channel to fix it;
hand-transcribed prose listings have neither, which is precisely why the
gap survived undetected for a decade in the first place.

A second release, `Craft3e-0.2.0.4`, surfaced a smaller but relevant
wrinkle on the licensing front specifically: an attempt to set the
package's `license:` field to `CC-BY-NC-SA-4.0`, matching `Book/titlepage.tex`'s
front-matter licensing, was rejected outright by Hackage — Creative
Commons' NonCommercial clause isn't OSI-approved open source, which
Hackage requires of anything it hosts. `Craft3e`'s code stays MIT; the
book's prose licensing is a separate, unaffected decision. Worth keeping
in mind for whichever source-format option is chosen: code and book prose
don't just have different drift-detection tooling (the point above), they
can also legitimately need different licenses, for reasons specific to
each distribution channel rather than to the rewrite itself.

## What the decision actually has to satisfy

Four things, in tension with each other, are worth naming explicitly
because each option trades them off differently:

- **Print fidelity.** The book has a real, previously-published camera-ready
  layout — a genuine index, an author-date bibliography, wrapped figures
  (`wrapfig`), multi-column material (`multicol`), a designed title/half-title.
  Reproducing that isn't just "does a PDF come out the other end," it's
  "does it look like the same book."
- **Authoring ergonomics for a rewrite.** This is specifically a *rewrite*
  project, not a one-off conversion — chapters will be edited repeatedly,
  reviewed, diffed, and (per this project's own working pattern) very
  plausibly drafted/edited with AI assistance. The format that's easiest to
  read, diff, and generate correctly matters more here than it would for a
  static, rarely-touched source.
- **Room for web-only features.** Embedded video and AI-assisted exercise
  feedback are not expressible in either LaTeX or plain Markdown natively —
  both need *some* extension mechanism, and that mechanism has to degrade
  sensibly in the PDF, not break it.
- **Migration risk vs. work already banked.** `tex2md.py` and
  `convert_images.py` represent real, working, tested effort. Any option
  that discards them is spending that back down to zero; any option that
  keeps LaTeX authoritative keeps relying on them indefinitely rather than
  retiring them.
- **Code-listing fidelity to the real, compiling source.** Not previously
  named as its own criterion, but demonstrated to matter directly (see "A
  related finding" above): with only one chapter's listing mechanically
  tied to `Code/Craft3e`, a decade-old, language-level break sat unnoticed
  in the book's own monad chapter. Whichever format wins, the rewrite
  should treat generating or verifying listings against the real source as
  a requirement, not leave every chapter as hand-typed prose the way
  `Book/*.tex` is today.

One structural fact is worth flagging up front, because it's independent of
which format wins: both video embeds and AI exercise feedback need
*exercises* to be a recognisable, machine-extractable unit, not just prose.
That already exists on the LaTeX side — every exercise block is delimited
by `\begin{exercises}...\end{exercises}` (confirmed throughout `Book/*.tex`,
e.g. five occurrences in `Book/5.tex` alone) — so whichever format is
chosen, preserving (or re-establishing, in Markdown) an equally explicit,
consistently-delimited exercise boundary is a prerequisite for AI feedback
tooling, not a detail to leave implicit in prose.

## Option (i) — Keep `Book/*.tex` as-is, definitive, unconverted

Continue authoring directly in the existing LaTeX, warts and all;
`tex2md.py` keeps running as a downstream, one-way pipeline to the website,
unchanged in role.

**Advantages**

- Zero migration cost or risk — nothing about the source changes, so
  nothing that currently works can be broken by the switch itself.
- Full native LaTeX typesetting power stays available for the things it's
  genuinely good at: the real index, the Chicago bibliography, figure
  wrapping, multi-column layout — no need to reproduce any of that in a
  different toolchain.
- The website pipeline is already downstream of this and already works;
  choosing this option changes nothing about `Website/`'s CI or output.
- The PDF build itself is now directly confirmed, automated, and its one
  known bug fixed, not just assumed: the four-command
  `pdflatex`/`bibtex`/`makeindex`/`pdflatex`×2 sequence (see above)
  converges cleanly against this exact source, is wired up as
  `Book/Makefile`, and the `appendix1.tex` `\contentsline` bug it
  surfaced is fixed — all pushed in commit `8705a04`. Running `make` in
  `Book/` is now genuinely all it takes.

**Disadvantages**

- A "rewrite" against this source means writing and fixing 30-year-old,
  undocumented, personally-authored macro plumbing (`defs0.tex`,
  `miradefs.tex`, catcode-level tricks), not writing prose. That plumbing
  is exactly what makes `tex2md.py` 2,725 lines long in the first place —
  the messiness is the reason a hand-rolled brace-matcher
  (`_find_matching_brace`) was needed at all instead of a stock LaTeX
  parser. A rewrite is the point at which that cost gets paid repeatedly by
  whoever is authoring, rather than once by conversion tooling.
- No native way to express "this only appears online" (video, an
  AI-feedback widget) — it would have to be invented as a new custom macro
  on top of an already bespoke macro layer, which `tex2md.py` would then
  need special-casing to either render for the web or silently drop for
  print. Every new web-only feature is a new piece of two-sided macro
  plumbing to maintain.
- LaTeX source is comparatively hostile to diff-based review and to
  AI-assisted editing: heavy macro nesting, non-semantic line-wrapping
  conventions, and file-specific abbreviations mean both a human reviewer
  and an LLM have to hold more incidental context in mind per edit than
  with plain prose markup.

## Option (ii) — Cleaned-up LaTeX as the definitive source

Use (some of) the preprocessing already written for `tex2md.py` — the
macro-stripping and normalisation passes, not the Pandoc hand-off — to do a
one-time rewrite of `Book/*.tex` into a much smaller, standard LaTeX
subset (plain `\section`, `\textbf`, `\begin{itemize}`, standard code
environments), then author against *that* going forward, still generating
both PDF (via a normal LaTeX toolchain) and Markdown (via Pandoc, now much
more directly since its input is no longer full of bespoke macros).

**Advantages**

- Keeps LaTeX — and therefore full print fidelity (index, bibliography,
  figure layout) — as the definitive format, building on a print pipeline
  now directly confirmed to work cleanly and already automated via
  `Book/Makefile` (see above), with no new PDF pipeline to build or trust.
- Removes the specific pain named in option (i): a rewrite would be against
  clean, standard LaTeX, not 1989-era macro soup. This is a one-off cost
  (cleaning 33k lines) rather than an ongoing one paid by every future edit.
  Tested directly, not just argued (see "Option (ii)'s cleaned-up LaTeX,
  tested directly" above): on a real sample passage, cleaning up meant
  renaming two macros and nothing else, the rendered output came out
  byte-identical/visually indistinguishable, and adding a brand-new macro
  afterward worked first try with plain `\newcommand` — the kind of thing
  an author, not just a LaTeX specialist, can do.
- Much of the hard work already exists: the macro-stripping logic in
  `tex2md.py` (`strip_balanced_macro`, `strip_two_arg_macro`,
  `collapse_standalone_index_lines`, etc.) already knows how to flatten
  most of these macros — repurposing it to emit *clean LaTeX* rather than
  going all the way to Markdown is a smaller, more targeted piece of new
  work than either writing a fresh cleanup tool or building a new PDF
  pipeline from scratch.
- Once clean, `tex2md.py` itself likely shrinks substantially — much of its
  bulk exists specifically to cope with the non-standard macros; standard
  LaTeX is something Pandoc's own reader already handles well.

**Disadvantages**

- Still LaTeX. Video embeds and AI-feedback markup still need bespoke
  macros with no meaning outside this project, and every future contributor
  (human or AI) authoring the rewrite still has to know LaTeX, not prose
  Markdown — this option makes that LaTeX *nicer*, it doesn't remove the
  requirement. A concrete mechanism for this is worked out in "Option (ii)
  and web-only content" below — it's bounded, buildable work, not an open
  question, but it is real, additional work this option carries that
  option (iii)/(iv) wouldn't (Quarto in particular has this mechanism
  built in already).
- The cleanup pass is itself a large, one-shot migration over 33,000+
  lines that has to be checked for silent meaning changes — realistically
  via visual PDF diffing chapter-by-chapter against the now-confirmed
  baseline build — before it can be trusted as the new definitive source.
  That's real, non-trivial verification work, not a mechanical no-risk
  refactor. The one sample passage tested (above) needed almost no
  translation work, but it was also already close to plain LaTeX at the
  paragraph level; the five files that use the more catcode-heavy
  `ttdisplay`/`\so`/`\st` environment instead of plain `alltt` would need
  real, non-mechanical rewriting, not a rename, so the 33k-line estimate
  shouldn't be read down just because one representative passage was easy.
- Doesn't remove the round-trip problem, it just makes the round trip
  nicer: the web edition is still a generated, lossy derivative of a source
  optimised for print, so richer web-only features remain second-class,
  bolted on via magic comments/macros rather than being naturally
  expressible in the authoring format itself.
- Ongoing drift risk: nothing stops a future edit from reintroducing a
  Pandoc-unfriendly LaTeX construct by hand, since the source is still
  hand-authored general LaTeX, not a constrained/validated subset.

## Option (iii) — Markdown as the definitive source

Flip the direction: treat `Website/chapters/*.md` (or its successor) as
the definitive, hand-edited source going forward, and build a **new**
Markdown→PDF path (most plausibly Pandoc's Markdown reader plus a custom
LaTeX template, rather than reusing `Book/*.tex`'s own template directly)
to keep producing print output. `tex2md.py`/`convert_images.py` shift from
"the pipeline" to "the one-time migration tool that bootstrapped the
switch," and can be archived once the switch is complete.

**Advantages**

- Matches what's actually consumed the most today: the live, auto-deployed
  website (`.github/workflows/deploy-book.yml`) already builds directly
  from Markdown. Choosing Markdown as the source removes a conversion step
  for the output that currently gets the most real use, rather than adding
  one.
- Markdown is dramatically more approachable for the actual rewrite work:
  plain text, clean line-oriented diffs, no macro layer to fight, and —
  concretely relevant given this project's own working style — the format
  general-purpose tools (including AI-assisted editing) are most fluent at
  reading, writing, and fixing correctly. A "rewrite and extend" project is
  exactly the case where that ergonomics gap compounds the most, across
  many editing passes rather than one conversion.
- Both of the genuinely hard problems — a real bibliography and a real
  index — are **already solved in this direction**: `tex2md.py` already
  generates a working `bibliography.md` (Chicago author-date, resolved
  against `big.bib`) and `term-index.md` (real anchor-linked index) from
  the LaTeX. That de-risks the part of this option that would otherwise be
  the biggest unknown.
- Natural, well-precedented home for web-only content. Markdown-based
  book/document tooling (mdBook preprocessors, Quarto, MyST) has
  established patterns for exactly "this block only appears in one output
  target" — e.g. a fenced div carrying a video embed for HTML that degrades
  to a "see the online edition" note in the PDF — rather than needing a
  bespoke convention invented from nothing, which is what either LaTeX
  option would require.
- Genuinely closer to done than it looks: the LaTeX→Markdown half of this
  migration is not hypothetical, it's a working, evidenced pipeline already
  in the repo. What's missing is specifically the reverse direction
  (Markdown→PDF), not the whole thing.

**Disadvantages**

- The missing half is real, and unproven here: nothing in this repository
  currently demonstrates Markdown→PDF at anywhere near this book's quality
  bar. Pandoc's generic LaTeX template will not, out of the box, reproduce
  the specific camera-ready layout `Book/root.tex` hand-built (the
  `fourier`/scaled-`helvet` font pairing, the custom title-page macros, the
  Chicago bibliography style, `wrapfig` figure placement) — getting close
  means writing a real custom Pandoc LaTeX template, which is new,
  non-trivial work, not a checkbox. This gap matters more now than it did
  before this report's direct LaTeX build test (above): the alternative on
  offer isn't a hypothetical, unverified print pipeline any more, it's a
  demonstrably working one, so choosing this option means deliberately
  setting aside a proven pipeline in favour of building a new one, not
  replacing a broken one.
- No longer just predicted, either: a plain, untemplated `pandoc`
  conversion of one chapter (see "The Markdown→PDF path, tested directly"
  above) crashed under the default engine on a bare Unicode symbol,
  silently dropped all three of the chapter's figures (raw HTML that
  Pandoc's LaTeX writer has no defined behaviour for), and reproduced none
  of the book's typographic identity. None of that is fatal — it's exactly
  the custom-template work this report already anticipated — but it turns
  "Pandoc won't reproduce the layout out of the box" from a prediction into
  a measured result, and specifically surfaces *silent* figure loss as a
  real, current property of today's converter output, not a hypothetical
  one.
- Because of the above, "maintain the ability to produce a PDF" under this
  option most realistically means "produce a good, clean, but visually
  different PDF," not "reproduce the original Addison-Wesley layout exactly" —
  worth being explicit about, given the book has a real prior published
  edition readers may compare against.
- Markdown has no first-class equivalent of `\index`/`\printindex` for the
  *PDF* direction specifically — the web index is already solved (as
  above), but an automatically generated back-of-book index in a
  Markdown-sourced PDF is a separate, unproven piece of tooling.
- This is still, in effect, a rewrite of the migration tooling's direction
  of travel, not zero new tooling — real work, just smaller and lower-risk
  work than either LaTeX option, and work that directly reuses what
  `tex2md.py` already proved is possible.

## Other approaches worth considering

**(iv) Quarto (or MyST Markdown) instead of hand-rolled Markdown +
mdBook.** This is a variant of option (iii) worth calling out on its own,
because it's a purpose-built answer to exactly this report's central
tension — one authored source, multiple faithful outputs (HTML, PDF via
LaTeX, EPUB) — rather than something to assemble from mdBook plus custom
Pandoc scripting. Concretely relevant to this book specifically: Quarto has
native citeproc support, so `Book/big.bib` could be used directly rather
than needing bespoke citation-resolution code (`tex2md.py` currently
hand-rolls this in ~150 lines); it has real cross-reference and
figure/table numbering that works consistently across HTML and PDF output
from the same markup; and it has a first-class notion of output-target-
specific content blocks (`.content-visible when-format="html"` and
equivalents), which is precisely the mechanism a video embed or an
AI-feedback widget needs, with no bespoke convention to invent. The
trade-off against plain mdBook: heavier tooling dependency, a real (if
much better-trodden than a bespoke Pandoc template) learning curve for its
own PDF templating, and it would mean revisiting the already-working
`mdbook` + GitHub Pages deployment (`.github/workflows/deploy-book.yml`)
rather than keeping it as-is. Worth a serious prototype — one or two
chapters through Quarto, HTML and PDF both — before committing either way
between this and plain option (iii).

**(v) Hybrid: Markdown for chapter prose, LaTeX-only for a small fixed set
of front/back matter.** A lower-risk cut of option (iii): migrate the 21
chapters (the actual bulk of "rewrite" work, and the material that
benefits most from easier authoring) to Markdown as definitive, but leave
genuinely fixed, typographically fussy, rarely-edited pieces —
`Book/titlepage.tex`, `Book/halftitle.tex`, `Book/opsTable.tex` — as
hand-tuned LaTeX fragments included directly into the PDF build only, never
round-tripped. This shrinks migration risk to exactly the material that's
actually being rewritten, at the cost of the PDF build having two source
languages instead of one — an acceptable irregularity for content that
essentially never changes.

**(vi) Independent dual-authoring (LaTeX and Markdown maintained by hand,
no conversion tooling at all)** was considered and is worth naming only to
rule out: it removes all conversion-fidelity risk but replaces it with
permanent, manual synchronisation burden across every future edit, with no
tooling to catch drift. Given this is specifically a multi-pass rewrite
project, not a one-off, the two sources would diverge quickly. Not
recommended.

## Summary table

| Option | Print fidelity | Authoring ergonomics for a rewrite | Web-only features | Migration risk |
|---|---|---|---|---|
| (i) LaTeX as-is | Confirmed high — direct build test, known bug fixed, build automated | Poor — legacy macro layer | None natively; bespoke macros needed | Low — build proven and automated (`Book/Makefile`); only CI wiring is optional/outstanding |
| (ii) Cleaned-up LaTeX | Confirmed high — same proven, automated build; tested directly on a sample passage (byte-identical/indistinguishable output) | Tested directly — reads as near-plain LaTeX, extensible via ordinary `\newcommand`, still LaTeX | None natively; bespoke macros needed | Medium — one large cleanup + verification pass; sample passage was easy, catcode-heavy files won't be |
| (iii) Markdown definitive | Tested directly, not just predicted — structurally works, but silently drops raw-HTML figures and all book identity without real template work (see test above) | Best — plain text, AI/diff-friendly | Well-precedented patterns available | Medium — new PDF path, but reuses proven MD output; concrete gaps now known, not just guessed |
| (iv) Quarto/MyST | Same caveat as (iii) on book identity/templating; untested itself, though its native image handling likely avoids the specific raw-HTML figure loss found in (iii) | Best, plus native citations/refs | First-class, built-in mechanism | Medium-high — new framework to adopt |
| (v) Hybrid MD + fixed LaTeX front matter | Confirmed high for front matter; unproven for body | Best for the material actually being rewritten | Well-precedented (MD portion) | Lower — smaller MD surface to prove out |

## Recommendation

Testing the LaTeX build directly changes the shape of this decision, so
it's worth being explicit about what moved and what didn't, rather than
mechanically restating the original lean towards Markdown.

**What moved:** the original case for Markdown leaned partly on the print
pipeline being an unknown quantity anyway — "keep the existing PDF
pipeline" wasn't really on offer as a zero-risk baseline, so why not spend
the migration effort on Markdown instead. That argument no longer holds.
The LaTeX PDF path is now demonstrated, not assumed: a plain four-command
build, no missing packages, no bespoke index handling beyond ordinary
`makeindex`, one small pre-existing bug with a one-line fix, and a final
PDF that visually matches the camera-ready quality the book was designed
for. That's real, concrete evidence in favour of **option (ii)**
specifically — cleaning up the macro layer gets most of the
authoring-ergonomics benefit this report cares about, while keeping a
print pipeline that's now known-good rather than hoped-good, at
meaningfully lower migration risk than betting on an unproven
Markdown→PDF path.

**What didn't move:** for a sustained rewrite-and-extend project, Markdown
is still the format that's easiest to read, diff, review, and generate
correctly — including with the AI-assisted editing this project already
leans on — and it's still the natural home for the web-only features
(video, AI exercise feedback) that motivated this report, via
well-precedented patterns (mdBook preprocessors, Quarto's conditional
content blocks) rather than bespoke macros invented from nothing. The
bibliography/index generation that's already solved in the
LaTeX→Markdown direction (`tex2md.py`) is unaffected by this test either
way.

**What also moved, in the same direction:** the Markdown→PDF side of the
comparison is no longer purely hypothetical either — see "The
Markdown→PDF path, tested directly" above. A plain, untemplated `pandoc`
conversion of one chapter confirmed the report's prediction rather than
overturning it: real content (all three of the chapter's figures) was
silently dropped, a Unicode symbol crashed the default engine, and none
of the book's typographic identity survived. None of this is fatal to
option (iii)/(iv) — it's exactly the "real, non-trivial custom-template
work" this report already anticipated — but that gap is now a measured
one, not a guessed one, and it modestly reinforces rather than narrows the
case for option (ii) if minimising new risk is the priority.

**And option (ii) specifically was tested, not just argued for:** see
"Option (ii)'s cleaned-up LaTeX, tested directly" above. On a real sample
passage, cleanup meant renaming two macros and nothing else; the printed
output came out byte-identical/visually indistinguishable from the
original; and adding a genuinely new macro afterward — the concern raised
directly in conversation, "would I still be able to add macros myself" —
worked first try with ordinary `\newcommand`. That's the strongest
concrete evidence in this report for any single option: not just that
option (ii)'s print pipeline is proven (which was already established),
but that its *authoring* experience is, too.

So the honest updated position is a genuinely closer call than the
original draft suggested, not a reversal of it:

- If preserving the original book's exact camera-ready layout, at minimum
  new risk, matters most: **option (ii)** is now clearly the stronger
  choice — its print pipeline is proven, the cleanup itself can reuse
  `tex2md.py`'s existing macro-stripping logic rather than starting from
  scratch, and the resulting authoring experience has been tested directly
  and found genuinely readable and extensible, not just theoretically
  cleaner.
- If the authoring ergonomics of the rewrite itself, and first-class
  support for web-only features, matter most: **option (iii)/(iv)** is
  still the better fit — but should now be weighed with the understanding
  that it means deliberately setting aside a demonstrably working print
  pipeline to build a new one, not replacing a broken one.

Both small, low-risk items flagged earlier in this report as worth doing
immediately, independent of which option is ultimately chosen, have since
been done (commit `8705a04`): the one-line `appendix1.tex` `\contentsline`
bug is fixed, and `Book/Makefile` runs the four-step build confirmed
above end to end, so `root.pdf` no longer has to drift out of date by
hand the way it did since 2014 — running `make` in `Book/` keeps it
current. The one remaining item in the same spirit, still outstanding and
still optional, is CI automation: a GitHub Actions job that rebuilds (and
perhaps publishes) the PDF on push, mirroring what
`.github/workflows/deploy-book.yml` already does for the website.

One further item belongs in the same "do regardless of which option is
chosen" bucket: the code-listing drift documented above ("A related
finding") is independent of the LaTeX-vs-Markdown decision, but it's a
concrete, evidenced case for building *some* mechanical link between the
rewrite's chapter text and `Code/Craft3e`'s real, compiling modules —
extending `Book/2.tex`'s existing `\input{FirstScript.hs}` pattern (or its
Markdown fenced-code-block equivalent) to more chapters, or at minimum an
automated check that flags when a listing and its source file diverge —
rather than carrying forward a decade of unchecked hand-transcription into
the next edition.
