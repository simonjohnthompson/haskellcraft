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
Worth noting directly: **`Book/root.pdf` in the repo is dated March 2014**,
and there is no build script, Makefile, or CI job anywhere in this repo
that regenerates it — `Book/make-text` is a leftover list of manual `pandoc`
invocations from an earlier, abandoned conversion attempt, not a PDF build.
So, going into this report, "the ability to produce a PDF" from
`Book/*.tex` was a claim about what LaTeX in principle could still do with
this source, not a pipeline anyone had exercised recently. That gap has
since been closed directly, by actually running the build — see "The
LaTeX PDF build, tested directly" immediately below — and the short
version is that it works cleanly, with no drama. What's still genuinely
missing under every option is the small mechanical step of wiring an
actual build (a `Makefile`/CI job) into the repo, since none exists yet.

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
actually reaches the final PDF — but it's a latent, kernel-version-
dependent trap worth replacing with the standard
`\addcontentsline{toc}{chapter}{Appendices}`, which lets LaTeX generate
the correctly-sized call itself rather than hand-writing one that can go
stale again as the kernel evolves. Separately, `pdflatex` returned exit
code 1 even on the fully clean, warning-free final pass — worth resolving
before wiring this into CI (verify success by checking the log/output
file, not the exit code alone, until the cause is understood), but it
didn't correspond to any actual defect in the output itself.

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
- The PDF build itself is now directly confirmed, not assumed: a plain
  four-command `pdflatex`/`bibtex`/`makeindex`/`pdflatex`×2 sequence
  converges cleanly against this exact source (see above), with no missing
  packages and no index-specific complexity beyond the ordinary
  `makeindex` step.

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
- The PDF build isn't automated — no `Makefile`/CI job regenerates
  `root.pdf` today, so "keep the ability to produce a PDF" still means
  adding that automation, plus the one-line `appendix1.tex` fix found
  during testing (see above). Small, concrete, well-understood tasks now,
  rather than the open-ended re-verification this report originally
  flagged.
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
  now directly confirmed to work cleanly (see above), with no new PDF
  pipeline to build or trust.
- Removes the specific pain named in option (i): a rewrite would be against
  clean, standard LaTeX, not 1989-era macro soup. This is a one-off cost
  (cleaning 33k lines) rather than an ongoing one paid by every future edit.
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
  requirement.
- The cleanup pass is itself a large, one-shot migration over 33,000+
  lines that has to be checked for silent meaning changes — realistically
  via visual PDF diffing chapter-by-chapter against the now-confirmed
  baseline build — before it can be trusted as the new definitive source.
  That's real, non-trivial verification work, not a mechanical no-risk
  refactor.
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
| (i) LaTeX as-is | Confirmed high — direct build test, minor known bug | Poor — legacy macro layer | None natively; bespoke macros needed | Low — build now proven; just needs a Makefile/CI wired up |
| (ii) Cleaned-up LaTeX | Confirmed high — same proven build, cleaner source | Better, still LaTeX | None natively; bespoke macros needed | Medium — one large cleanup + verification pass |
| (iii) Markdown definitive | Unproven, now measured against a confirmed working alternative | Best — plain text, AI/diff-friendly | Well-precedented patterns available | Medium — new PDF path, but reuses proven MD output |
| (iv) Quarto/MyST | Unproven, same caveat as (iii) | Best, plus native citations/refs | First-class, built-in mechanism | Medium-high — new framework to adopt |
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

So the honest updated position is a genuinely closer call than the
original draft suggested, not a reversal of it:

- If preserving the original book's exact camera-ready layout, at minimum
  new risk, matters most: **option (ii)** is now clearly the stronger
  choice — its print pipeline is proven, and the cleanup itself can reuse
  `tex2md.py`'s existing macro-stripping logic rather than starting from
  scratch.
- If the authoring ergonomics of the rewrite itself, and first-class
  support for web-only features, matter most: **option (iii)/(iv)** is
  still the better fit — but should now be weighed with the understanding
  that it means deliberately setting aside a demonstrably working print
  pipeline to build a new one, not replacing a broken one.

Either way, two small, low-risk items are worth doing immediately,
independent of which option is ultimately chosen: fix the one-line
`appendix1.tex` `\contentsline` bug, and add a real `Makefile`/CI job that
runs the four-step build confirmed above, so `root.pdf` stops silently
drifting out of date the way it has since 2014.
