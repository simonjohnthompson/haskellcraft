# Pandoc version drift in the website conversion pipeline

**Status: RESOLVED (20 Sep 2026).** Archived here for historical
reference. The entire `Website/chapters/*.md` corpus now regenerates
byte-for-byte identical to the pinned Pandoc 2.7.3 binary — verified
corpus-wide, zero remaining diffs. See "Full resolution" at the end for
what was actually fixed and when. The only item that outlived this
report is the long-term durability of the 2.7.3 pin itself, which moved
to `Admin/PANDOC-VERSION-DRIFT-REPORT.md` as the one live, open item.

Prepared in response to a request to check whether other chapters have
drifted out of sync with what `Website/convert/tex2md.py` would currently
produce from the same LaTeX source — the same class of problem behind two
bugs fixed earlier (commits `722717b`, `a08d62c`), where `Book/0.tex` and
`Book/2.tex` needed a `\label{}` moved out of the gap before a list's first
`\item`. **No files were modified to produce this report**, beyond the
temporary output of test regenerations under `/tmp`, which never touched
the repository.

## Headline finding: two pandoc binaries, and the wrong one is now winning

`tex2md.py` shells out to a bare `pandoc` (`Website/convert/tex2md.py:2428`)
with no version pin anywhere in the repo — no `requirements.txt`, no CI
step, no comment naming a required version. Which binary that resolves to
depends entirely on `$PATH` at the time someone runs it. On this machine
there are three:

| Path | Version | Notes |
|---|---|---|
| `~/.cabal/bin/pandoc` | — | 32-bit Mach-O from **12 Apr 2010**; can't execute on modern macOS at all. First on `$PATH`, but the OS silently skips it (confirmed: plain `pandoc` on this `$PATH` reliably reaches one of the two below). Dead weight, not currently causing harm, worth deleting for hygiene. |
| `/usr/local/bin/pandoc` | **2.7.3** | x86_64 binary dated **12 Jun 2019** (likely the official pandoc `.pkg` installer from years ago). |
| `/opt/homebrew/bin/pandoc` | **3.11** | Installed via Homebrew "on request"; the Cellar directory and the `/opt/homebrew/bin` symlink are both dated **16 Sep 2026, 16:13** — i.e. this was installed five business days ago. |

`$PATH` on this machine lists `/opt/homebrew/bin` *before* `/usr/local/bin`.
Before 16 Sep 2026, Homebrew's slot was empty, so `pandoc` resolved to
`/usr/local/bin/pandoc` (2.7.3). Since 16 Sep 2026, it resolves to the
newly-installed Homebrew pandoc 3.11 instead — a silent, unannounced
four-major-version jump for any `tex2md.py` invocation, with nothing in the
project flagging that the tool it depends on changed under it.

**Confirmed empirically, not just inferred from dates:** regenerating
chapters with `PATH=/usr/local/bin:$PATH` (forcing 2.7.3) reproduces the
currently-committed `Website/chapters/*.md` exactly, or near-exactly:

- `2.md`, `4.md`, `5.md`, `9.md`, `15.md`, `opsTable.md`, `glossary.md`,
  `otherHs.md` — **byte-for-byte identical**.
- `6.md`, `7.md`, `10.md`, `11.md`, `12.md`, `16.md`, `17.md` — identical
  except for a handful of stale chapter-number cross-references, a
  *separate*, already-existing issue (see below), unrelated to pandoc.

This is conclusive: **`tex2md.py` was built and, until five days ago, run
against Pandoc 2.7.3.** Every chapter regenerated since 16 Sep 2026 (the
Preface work, and the two label-position fixes made today) picked up
Pandoc 3.11 instead, without anyone choosing to change tooling versions.

## What Pandoc 3.11 does differently, and why it matters

Two behaviour changes between 2.7.3 and 3.11 are visible in this project's
output:

1. **Heading style** — 2.7.3's markdown writer emits Setext-style headings
   (`===`/`---` underlines) for levels 1–2; 3.11 emits ATX (`#`/`##`)
   throughout. Cosmetically different, functionally identical — mdBook's
   CommonMark renderer accepts both. **Harmless.**
2. **Figures whose content isn't a bare image, and any figure using a
   float-placement argument** — 2.7.3 emits plain Markdown image syntax
   (which `tex2md.py`'s `_sized_thumbnail()` post-processing, around line
   2658, then wraps in the site's click-to-zoom `checkbox-label`/
   `img-wrapper` HTML) and clean GFM pipe-tables. 3.11 instead emits a raw
   `<figure><embed src="..."/><div id="...">...</div>...</figure>` HTML
   block and, for the same reason, a raw `<table>` instead of a pipe
   table. `tex2md.py`'s post-processing pattern-matches 2.7.3's
   plain-Markdown shape and simply doesn't fire against 3.11's HTML shape.
   **Not harmless**: regenerating any affected chapter under 3.11 silently
   drops the zoom-on-click behaviour from every such figure and replaces a
   clean pipe table with unstyled raw HTML.

   **Correction (20 Sep 2026):** this was originally attributed to an
   embedded `\label`/`\index` inside the figure/table. Empirical testing
   with minimal `.tex` fragments through both binaries (varying one thing
   at a time) shows that's wrong — `\label`/`\index` make no difference to
   the output in any case tested. The real triggers, independent of
   label/index, are:
   - A `\begin{figure}[t]` (or `[b]`/`[h]`/etc.) **placement argument**,
     when the figure's content is a bare image — 3.11 records the
     argument as a `data-latex-placement` attribute it can't express in
     plain Markdown image syntax alongside the id, so it falls back to
     raw HTML. A bare `\begin{figure}` with no placement argument stays
     as plain Markdown under 3.11 even when labelled.
   - A `\begin{tabular}` **nested inside** `\begin{figure}` — always
     raw `<table>` under 3.11, with or without a label or placement
     argument.
   - A `\begin{quote}` **nested inside** `\begin{figure}` (i.e. every
     `\beware` box, which is wrapped in a figure purely for float
     placement) — always raw HTML under 3.11, with or without a label or
     placement argument. This is what turns fenced ` ```haskell ` blocks
     inside `\beware` boxes into raw syntax-highlighted HTML spans.

   Practical upshot: stripping the `[t]`/`[b]`/etc. placement argument
   from `\begin{figure}[...]` in preprocessing (it's meaningless outside a
   real LaTeX float) would fix the plain-image case under 3.11, cheaply
   and with no cross-referencing risk. It would not touch the table or
   `\beware` cases, which stay exactly the multi-session engineering
   problem described in "Why (a), not (b)" below. Removing `\label`/
   `\index` from figures/tables — a mitigation this correction was
   prompted by considering — would fix none of the three triggers above
   and would break `\ref{}` cross-referencing throughout the book, so it
   was not pursued.

   **Update (20 Sep 2026): the `\beware` case is now fixed, cheaply.**
   `\beware{title}{content}` is wrapped in `\begin{figure}[...]` by hand
   at 37 of its 66 call sites (the other 29 already call `\beware` bare
   and convert cleanly) purely to get the printed book's float placement
   — the wrapper carries no meaning for the website conversion at all.
   `tex2md.py`'s `preprocess()` now has a new `unwrap_bare_beware_figures`
   step, run just before the existing `\beware` substitution, that
   strips exactly that wrapper (only when `\beware`, plus any leading
   `\index`/`\hypertarget` calls, is its sole content — anything else
   inside a figure is left alone) before Pandoc ever sees it. Verified:
   byte-identical regeneration of the whole corpus under the pinned 2.7.3
   binary (no regression), and zero raw-HTML `\beware` boxes left under
   3.11 across every previously-affected chapter.

## Chapters affected

Counting only real content/behaviour differences (the Setext/ATX heading
noise is excluded as harmless):

| Chapter | Figures that would lose click-to-zoom under 3.11 | Tables affected |
|---|---|---|
| `6.md` | 5 of 11 | yes |
| `16.md` | 4 of 5 | — |
| `11.md` | 3 of 11 | yes |
| `17.md` | 4 of 6 | yes |
| `3.md` | 1 of 6 | yes |
| `15.md` | 1 of 8 | — |
| `9.md` | 1 of 1 | — |
| `2.md` | 1 of 6 | yes |

Thirteen chapters in total show *some* diff against a fresh 3.11
regeneration (the eight above, plus `5.md`, `4.md`, `7.md`, `12.md`,
`10.md`, `opsTable.md`, `glossary.md`, `otherHs.md`, whose differences are
heading-style only and need no attention).

**This table undersold the problem.** It counted only chapters where a
*fresh 3.11 regeneration* would introduce new damage; it didn't check
whether any already-committed chapter's `.md` had *already* been built
with 3.11 before the pin landed. It had: see "Full resolution" below —
nine chapters, not the eight above, turned out to already be carrying
live 3.11-flavoured raw HTML on the site.

## A second, unrelated drift found along the way

While diffing against the 2.7.3 baseline, eight chapters turned up a small
number of stale cross-reference links, all following the same pattern —
`19.md#dsls`/`19.md#qcGens` should now read `20.md#dsls`/`20.md#qcGens`,
and `20.md#behaviour` should now read `21.md#behaviour`:

`6.md`, `7.md`, `10.md`, `11.md`, `12.md`, `16.md`, `17.md`, `errors.md`

This traces to the chapter-19 reorganisation earlier in the project
history (`68cda9b` "Move Foldable section to end of Ch 19, fix >=> index
entry" and its neighbours) — the `.tex` source's own `\ref{}`/`\label{}`
targets are correct (they resolve dynamically), but these particular `.md`
files simply haven't been regenerated since that renumbering landed, so
they still carry the old chapter numbers baked into their link targets and
link text. **Done** (commit `3eab103`): fixed using the newly-pinned
2.7.3 binary.

## A third, unrelated bug found along the way

While implementing the `\beware`-wrapper fix above, one of `11.tex`'s
`\beware` calls turned out to already be broken, independent of pandoc
version or the figure wrapper. `Book/11.tex`'s "QuickCheck and
higher-order functions" box was written as:

```
\beware{QuickCheck and higher-order functions}
{\label{QChofs}We...
```

— a newline between `\beware`'s two argument groups. `tex2md.py`'s
`strip_two_arg_macro` (and `unwrap_bare_beware_figures`, which shares the
same brace-matching logic) requires the second `{` to immediately follow
the first `}`; when it doesn't, the whole call is left unconverted.
Concretely: pandoc still treated `\beware{title}` as an unknown macro
whose single following brace group it swallows and discards (the same
"unknown macro swallows its argument" failure mode noted elsewhere in
this file), so the *title* ("QuickCheck and higher-order functions")
was silently dropped from the live site, while the second, syntactically
separate `{...}` group happened to still render as plain, unindented
paragraph text below it rather than as a proper blockquote — not "the
whole box missing" as first thought here, but visibly wrong regardless:
no bold title, no indentation, no visual distinction from surrounding
prose.

**Done**: closed up the newline in `Book/11.tex` directly (the simpler,
lower-blast-radius fix — `strip_two_arg_macro` is shared by several other
macro substitutions, so leaving it strict and fixing the one malformed
call site avoids loosening a check the other call sites may be relying
on). Regenerated `Website/chapters/11.md` under the pinned 2.7.3 binary;
the box now renders as a proper blockquote with its title, both code
samples, and the `QChofs` anchor intact. A second instance of the exact
same typo was later found and fixed the same way in `Book/8.tex`'s "More
information about Rock - Paper - Scissors" box — see "Full resolution".

## Recommendations

1. ~~**Immediate, zero-cost fix**: when regenerating any chapter by hand,
   run `tex2md.py` with `/usr/local/bin` ahead of `/opt/homebrew/bin` on
   `$PATH`...~~ **Done** (commit `5a63daa`): `tex2md.py` now resolves an
   explicit `/usr/local/bin/pandoc` itself (falling back to bare `pandoc`
   on `$PATH` if that's absent) rather than trusting `$PATH` order, and
   warns loudly on stderr if the resolved binary isn't 2.7.x. No more
   `$PATH` gymnastics needed at the call site; verified it reproduces
   `Website/chapters/6.md` byte-for-byte unchanged. This is the "pin to
   2.7.3" half of option (a) below — the eight stale cross-references this
   report found were also fixed (commit `3eab103`) using this same pinned
   binary.
2. ~~**Medium-term decision**: either (a) treat the pin above as the final
   answer... or (b) update `tex2md.py`'s figure/table post-processing to
   also recognise Pandoc 3.11's HTML output shape, then do one deliberate
   full-corpus regeneration off the Homebrew binary.~~ **Decided: (a), stay
   pinned to 2.7.3.** See "Why (a), not (b)" below for the reasoning. (The
   2.7.3 pin's own long-term durability is the one part of this
   recommendation that outlived this report — see
   `Admin/PANDOC-VERSION-DRIFT-REPORT.md`.)

### Why (a), not (b)

Investigating (b) turned up more scope than this report first estimated.
Pandoc 3.11 doesn't just re-render figures/tables containing a
`\begin{tabular}` as raw HTML — it does that for **any**
`\begin{figure}...\end{figure}` whose content isn't a bare image,
including this book's `\beware{...}` aside boxes (rendered as
blockquotes via a bare `\begin{figure}` wrapper), which are neither an
image nor a table (see the correction under "What Pandoc 3.11 does
differently" above — `\label`/`\index` were never the actual trigger).
Under 3.11, a `\beware` box's *entire contents* — including any Haskell
code sample inside it — comes out as Pandoc's own syntax-highlighted raw
HTML (`<pre class="sourceCode haskell"><span class="fu">...</span>`)
instead of a plain ` ```haskell ` fenced block. Across the flagged
chapters, roughly half of the affected `<figure>` blocks are this kind,
not images or tables. Making (b) work properly in general — recognising
3.11's HTML output shape for *every* case and reversing its syntax
highlighting back to plain code blocks — would have been real,
multi-session engineering. In the end this report's own investigation
found a cheaper, narrower fix for the `\beware` case specifically
(unwrapping the figure before Pandoc ever sees it, rather than teaching
`tex2md.py` to parse 3.11's HTML afterwards) — see "Full resolution".
The plain-image-with-placement-argument and genuine table-in-figure
cases were never hit in practice (see below), so no further work went
into them.

3. ~~**While doing that regeneration pass**, also pick up the eight stale
   `19→20`/`20→21` cross-references above...~~ **Done** (commit `3eab103`,
   ahead of the medium-term decision in (2) — these were cheap enough to
   fix immediately using the newly-pinned binary rather than waiting).
4. ~~**Low-priority hygiene**: delete the dead `~/.cabal/bin/pandoc` (2010,
   32-bit, can't execute)...~~ **Done**: removed from this machine
   (`~/.cabal/bin/pandoc`, outside the repo, so no commit applies).
   `which -a pandoc` now lists only `/opt/homebrew/bin/pandoc` (3.11) and
   `/usr/local/bin/pandoc` (2.7.3, the one `tex2md.py` pins to).

## Full resolution (20 Sep 2026)

Regenerating chapter 8 to check for a second instance of the `\beware`
newline typo (found in Ch11 above) turned up something much bigger than
the two chapters this report had scoped: **nine committed chapters — not
the eight in "Chapters affected" above — already contained live,
un-postprocessed Pandoc 3.x raw HTML**, built at some point before the
2.7.3 pin landed (commit `5a63daa`) and never re-verified since. This
directly contradicted this report's own "nothing is broken on the live
site right now" conclusion for `1.md`, `3.md`, `8.md`, `13.md`, `14.md`,
`19.md`, `20.md`, `21.md` and `22.md` specifically: real figures, tables
and `\beware` boxes were rendering as unstyled raw HTML on the live site,
not just as a dormant risk waiting for the next regeneration.

Fixed in full, across three commits (`116486f`, `17eae4e`, and the
`\beware`-unwrap fix above):

- **`unwrap_bare_beware_figures`** (this report's main finding) — fixed
  every affected `\beware` box across all nine chapters.
- **A second `\beware` newline typo**, identical in shape to Ch11's
  ("More information about Rock - Paper - Scissors" in `Book/8.tex`) —
  fixed the same way, closing up the newline in the source.
- **A wholly separate bug, found only because Ch13 was in the affected
  set**: `Book/13.tex`'s Wikimedia image-attribution footnote is split
  across `\caption{...\protect\footnotemark}` and a later
  `\footnotetext{...}`, because `\caption` is a moving argument and a
  plain `\footnote{}` directly inside it breaks the real LaTeX build
  (commit `5159fdf`). Confirmed by direct test: Pandoc 2.7.3 *and* 3.11
  both silently drop this split idiom entirely, losing a CC BY-SA
  attribution outright rather than mis-rendering it — unrelated to
  everything else in this report, and used exactly once in the whole
  book. Fixed with a new `merge_footnotemark_footnotetext` preprocessing
  step that folds the pair back into a single `\footnote{...}` before
  Pandoc ever sees it, without touching the real `.tex` source (which
  needs the split for the print build).

Every fix was verified the same way: full-corpus regeneration under the
pinned 2.7.3 binary, diffed word-for-word (a multiset comparison, not
just a line diff) against the previously-committed text, with every
apparent discrepancy manually traced to its source rather than assumed
benign. This caught the footnote bug in the first place, and separately
ruled out several false alarms from the comparison tooling itself (e.g.
HTML-tag-stripping inserting spurious whitespace that split `1.80s` into
`1.80` + `s`).

The remaining five chapters that had shown *some* diff against a 2.7.3
regeneration (`0.md`, `18.md`, `appendix1.md`, `further.md`,
`projects.md`) were checked too: word-identical, every diff line traced
to heading style, list/description-marker spacing, or `C#`/`C\#`
escaping — cosmetic only, no live-site bug. Regenerated anyway for
corpus-wide consistency (commit `ab76507`).

**End state, verified 20 Sep 2026: a fresh regeneration of every chapter
under the pinned 2.7.3 binary produces zero diffs against the committed
corpus.** The whole site now genuinely reflects the pinned binary, not a
mix of 2.7.3 and stale 3.11 output.
