# Pandoc version drift in the website conversion pipeline

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
   3.11 across every previously-affected chapter. This does **not**
   touch the plain-image-with-placement-argument case or the
   table-in-figure case above — those are unaffected and still the
   reason the 2.7.3 pin remains the right call for now.

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
heading-style only and need no attention). Every other chapter (`0`, `1`,
`8`, `13`, `14`, `18`–`22`, `appendix1`, `errors`, `projects`, `further`)
either has no figures/tables sensitive to this, or — in the case of `0.md`
and `2.md` — was already fixed today.

**Nothing is broken on the live site right now.** `deploy-book.yml` only
runs `mdbook build` against the already-committed `.md` files; it never
invokes `tex2md.py` or pandoc. This is a dormant risk that only bites the
next time someone regenerates one of the 8 chapters above from an unchanged
`$PATH` — which is exactly what nearly happened with `2.md` earlier today,
before the mismatch was caught and a minimal hand-patch was used instead of
a full regeneration.

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
link text. This is a live, if minor, broken-link bug on the site today
(unlike the pandoc-version issue, which is dormant) — worth its own fix,
but it is a different root cause from everything else in this report and
is called out here only because the same regeneration pass would resolve
both at once.

## A third, unrelated bug found along the way

While implementing the `\beware`-wrapper fix above, one of `11.tex`'s
`\beware` calls turned out to already be broken, independent of pandoc
version or the figure wrapper. `Book/11.tex`'s "QuickCheck and
higher-order functions" box is written as:

```
\beware{QuickCheck and higher-order functions}
{\label{QChofs}We...
```

— a newline between `\beware`'s two argument groups. `tex2md.py`'s
`strip_two_arg_macro` (and `unwrap_bare_beware_figures`, which shares the
same brace-matching logic) requires the second `{` to immediately follow
the first `}`; when it doesn't, the whole `\beware` call is left
unconverted rather than becoming a blockquote. Confirmed: the phrase
"QuickCheck and higher-order functions" does not appear anywhere in the
live `Website/chapters/11.md` — this box's entire title and content are
silently missing from the site today, unrelated to the pandoc-version
issue and not fixed by anything in this report. Worth its own fix (either
relax the two-arg matching to allow whitespace/newlines between groups,
or just close up the newline in `11.tex` itself), but out of scope here.

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
   pinned to 2.7.3.** See "Why (a), not (b)" and "Is the 2.7.3 pin durable
   long-term?" below for the reasoning.

### Why (a), not (b)

Investigating (b) turned up more scope than this report first estimated.
Pandoc 3.11 doesn't just re-render figures/tables containing a
`\begin{tabular}` as raw HTML — it does that for **any**
`\begin{figure}...\end{figure}` whose content isn't a bare image,
including this book's `\beware{...}` aside boxes (rendered as
blockquotes via a bare `\begin{figure}` wrapper), which are neither an
image nor a table (see the correction under "What Pandoc 3.11 does
differently" above — `\label`/`\index` were never the actual trigger).
Under
3.11, a `\beware` box's *entire contents* — including any Haskell code
sample inside it — comes out as Pandoc's own syntax-highlighted raw HTML
(`<pre class="sourceCode haskell"><span class="fu">...</span>`) instead of
a plain ` ```haskell ` fenced block. Across the 8 flagged chapters, roughly
half of the affected `<figure>` blocks are this kind, not images or
tables. Making (b) work properly means reversing Pandoc's HTML
syntax-highlighter output back into plain code blocks wherever it
happens to sit inside an aside box, on top of the already-scoped
figure/table work — real, multi-session engineering, not the point release
this report originally sized it as. Given (a) carries no live-site risk
(see below), that work isn't worth it right now.

### Is the 2.7.3 pin durable long-term?

Nothing forces an upgrade: `deploy-book.yml` (the CI that builds and
publishes the live site) only runs `mdbook build` against the
already-committed `Website/chapters/*.md` files — it never invokes
`tex2md.py` or Pandoc. Pandoc only runs when someone manually regenerates
a chapter from `.tex` on a dev machine, so there's no security-patch
cadence or CI mandate pushing an upgrade, and the pin can sit unchanged
indefinitely with zero live-site risk. Missing Pandoc 3.x features is a
hypothetical concern, not a known one — every chapter in the corpus
regenerates byte-identical (or near-identical, modulo the already-fixed
cross-refs) under 2.7.3, so there's no evidence today that 2.7.3 is
mishandling anything the book actually needs.

The real, if bounded, cost is durability of one unmanaged binary on one
machine:

- `/usr/local/bin/pandoc` is a 2019 x86_64 build, not tracked by any
  package manager this repo knows about. **Checked (19 Sep 2026): the
  exact release is still available** — Pandoc's GitHub release
  [2.7.3](https://github.com/jgm/pandoc/releases/tag/2.7.3) still hosts
  the original `pandoc-2.7.3-macOS.pkg` (matching the installed binary
  exactly), and the source is still on Hackage (`cabal get pandoc-2.7.3`
  works today). So if this binary is ever lost, it can be re-fetched
  as-is — no re-porting needed, just re-running the original 2019
  installer.
- It depends on Rosetta 2 continuing to run x86_64 binaries on Apple
  Silicon. Apple has kept extending Rosetta 2's support for years with no
  announced end date, but hasn't committed to "forever" — a real, if
  long-tail, risk.
- **Checked whether a native-arm64 rebuild is a viable fallback if Rosetta
  support ever erodes: not a quick one, but not obviously hopeless
  either.** Building pandoc 2.7.3's own source (from Hackage) against a
  period-correct 2019 dependency graph, using a genuinely native arm64
  GHC (worth noting: the `ghcup`-installed GHC already on this machine
  turned out to itself be an x86_64 binary running under Rosetta, despite
  this being an Apple Silicon Mac — swapped in Homebrew's native arm64
  GHC 9.14.1 instead), got substantial progress: it compiled cleanly past
  one real bug (`HsYAML-0.1.2.0`, a transitive, LaTeX-irrelevant
  dependency used only for YAML frontmatter, missing an import that a
  newer `mtl` no longer papers over — a one-line fix), then hit a second,
  deeper one in `blaze-builder-0.4.1.0` (part of the HTML-writer path):
  GHC's own representation of 32-bit words at the primitive-op level
  changed sometime in the last six years (`Word32#` is now a distinct
  type from `Word#`), breaking a hand-written bit-shift helper — real
  bit-rot in a six-year-old dependency, not a version-bounds annoyance,
  and fixing it means editing low-level primop calls rather than
  relaxing a constraint. Stopped there rather than continuing to chase
  further such issues (`hslua`'s C/Lua FFI bindings, not yet reached, are
  a likely next one) — **decided not worth pursuing further right now**,
  since nothing today requires it. The upshot: a native-arm64 pandoc 2.7.3
  is plausible with enough forward-porting effort, but it's a real
  project for if/when Rosetta 2 support actually erodes, not a five-minute
  fallback to have ready today.
3. ~~**While doing that regeneration pass**, also pick up the eight stale
   `19→20`/`20→21` cross-references above...~~ **Done** (commit `3eab103`,
   ahead of the medium-term decision in (2) — these were cheap enough to
   fix immediately using the newly-pinned binary rather than waiting).
4. ~~**Low-priority hygiene**: delete the dead `~/.cabal/bin/pandoc` (2010,
   32-bit, can't execute)...~~ **Done**: removed from this machine
   (`~/.cabal/bin/pandoc`, outside the repo, so no commit applies).
   `which -a pandoc` now lists only `/opt/homebrew/bin/pandoc` (3.11) and
   `/usr/local/bin/pandoc` (2.7.3, the one `tex2md.py` pins to).
