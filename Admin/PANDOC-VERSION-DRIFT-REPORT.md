# Pandoc version drift — status: resolved, pin moved to 3.11

**The pin has moved.** As of 21 Sep 2026, `tex2md.py` resolves
Homebrew-managed `/opt/homebrew/bin/pandoc` (Pandoc 3.11), not the old
unmanaged 2019 `/usr/local/bin/pandoc` (2.7.3) binary. `Website/chapters/
*.md` has been regenerated and committed under the new pin, and the live
site reflects it. This is the end state of an investigation that ran
across three sessions -- what follows is a record of why the move took
this long and how it was verified, kept for the next person (human or
Claude) who wonders whether it's safe to trust.

The original pandoc-version-drift investigation (two pandoc binaries on
`$PATH`, what 3.11 did differently and why, nine chapters found
carrying live un-postprocessed 3.x HTML and fixed, two `\beware`
newline typos, a dropped Wikimedia attribution footnote, five more
chapters normalised for consistency) is archived in full at
`Admin/Archive/PANDOC-VERSION-DRIFT-REPORT.md`. That investigation
concluded the pin needed to stay at 2.7.3 for the time being; a
follow-up thread revisited that conclusion, found the real blocker was
bigger than originally scoped, fixed it in full, verified it with a
real page-by-page rendered-HTML diff (not just markdown-source
comparison), and moved the pin. Ten distinct causes of the
raw-HTML-fallback problem were found and fixed first (below), followed
by ten more found only by that rendered-HTML diff (`## The
rendered-HTML diff` below) -- some pre-existing and unrelated to any
Pandoc version, some 3.11-specific.

## Why we couldn't just move to the latest Pandoc for so long (now fixed)

`tex2md.py` (`Website/convert/tex2md.py`) used to resolve an explicit
`/usr/local/bin/pandoc` (commit `5a63daa`), falling back to bare
`pandoc` on `$PATH` if that's absent, and warned loudly on stderr if the
resolved binary wasn't 2.7.x. This wasn't inertia — a real regression
blocked moving to Pandoc 3.x (checked directly against 3.11). Ten
distinct causes of it were found and fixed first -- see below.

The root cause (see the archived report for the full derivation):
Pandoc 3.x's Markdown writer can only degrade a LaTeX `\begin{figure}`
to plain Markdown when its content is a **bare image with absolutely
nothing else wrapping or accompanying it**. An earlier session fixed
the `\beware` aside-box case; a follow-up session investigating "why
can't we just upgrade" found the problem was substantially larger than
that — practically every captioned image figure in the book carried at
least one of several distinct triggers for the same fallback, plus two
entirely separate causes (a genuine table in a figure; a stray
hypertarget landing inside a table cell) that shared the same symptom
but needed their own fixes. All are now understood and fixed.

**Fixed, in `Website/convert/tex2md.py`:**

1. **A figure's own primary `\label` was always converted to
   `\hypertarget{X}{}` instead of being kept as a real `\label`** — only
   a heading's primary label was. `_label_replacement`'s `kind ==
   "heading"` check is now `kind in ("heading", "figure")`;
   `find_primary_heading_labels` already treated a `\caption`'s first
   following label as primary the same way as a heading's, so this was
   a one-line widening of what it's allowed to apply to. This was the
   single biggest fix — it's what made every other figure fix below
   actually show up in the output, since Pandoc keeping a real `\label`
   on the image (`{#X width="..."}`) is what makes the image bare
   enough to degrade at all.
   - Two follow-on fixes this required, both in `postprocess()`:
     Pandoc 2.7.3 (confirmed already fixed in 3.11) renders a kept
     figure label as *both* the `{#X ...}` attribute *and* a redundant
     `[]{label="X"}` span inside the caption text, which broke the
     alt-text regex that drives the click-to-zoom `<figure>` wrapper —
     stripped before that regex runs (but only when it's genuinely
     redundant — see item 5 below for the one other place this span
     shows up, where it's the *only* copy of the id and deleting it
     would have been a real regression). The id itself needed carrying
     from the image's attributes onto the `<figure>` tag (`_id_attr`),
     replacing the separate `<a id="X">` anchor the old `\hypertarget`
     path used to emit — including de-duplicating it correctly for
     Chapters 16/19's side-by-side images sharing one label, and a
     fallback anchor for the one case (Chapter 13's footnote-in-caption
     image) that still doesn't flow through that conversion at all, for
     an unrelated, pre-existing reason.
2. **`[t]`/`[b]`/etc. placement arguments and `\begin{center}` wrappers**
   around a figure's image — `strip_figure_placement_args` and
   `unwrap_center_around_image`, both confirmed no-ops under 2.7.3.
   `unwrap_center_around_image` also unwraps a `\begin{center}` whose
   content is the image *plus* its `\caption`/`\label` (Chapter 20's
   "Positioned images" figure puts both inside the `\begin{center}`
   rather than after it) — confirmed by fragment test to be exactly as
   safe as the bare-image case.
3. **A trailing `\hypertarget` left inside a figure** — almost always a
   first-occurrence `\index{}` entry (Chapter 11's
   `\label{plmb}\index{plumbing}`, right before `\end{figure}`) — is, on
   its own, enough non-image content to trigger the fallback.
   `hoist_hypertargets_out_of_figures` moves a *trailing* run of
   `\hypertarget`s (immediately before `\end{figure}`, nothing else) out
   to just after it; deliberately narrow, since a hypertarget can also
   sit deep inside a figure's own content (Chapter 2's GHCi-commands
   table plants one next to almost every row) where hoisting it out
   would detach it from what it's meant to mark — confirmed a real
   regression by a full-corpus diff when this fix first tried to sweep
   up every hypertarget in a figure rather than just the trailing run.
   Must run after `unwrap_bare_beware_figures`, for the same reason: a
   `\beware`-wrapping `\begin{figure}` (before that unwraps it) can
   contain several unrelated, correctly-placed hypertargets of its own.
4. **Two vestigial, genuinely empty `\begin{alltt}\end{alltt}` blocks**
   flanking Chapter 16's "two-list queue" image (the book's only
   instance) — each became a real but content-free code block, and was
   itself enough non-image content to trip the fallback. Dropped
   entirely before the real alltt-to-minted conversion runs.
5. **Three genuine tables wrapped in `\begin{figure}` purely for print
   float placement** (`2.md`, `3.md`, `6.md`, one each) — a different
   mechanism from 1-4: Pandoc's reader only recognizes `\caption{...}`
   inside a `\begin{figure}` for the single-bare-image case, so for
   these three the caption was *already* silently vanishing (rescued
   until now via a sentinel workaround, `mark_non_image_captions`), and
   separately Pandoc 3.x can't degrade a non-image Figure block to
   plain Markdown at all. `convert_table_figures_to_table_env` swaps
   `\begin{figure}` for `\begin{table}` around these three specific
   blocks (detected by "contains a `\begin{tabular}`/`\begin{tabular*}`,
   no `\includegraphics`") -- confirmed by fragment test that Pandoc's
   reader recognizes the caption correctly inside `\begin{table}` with
   no sentinel needed, and both 2.7.3 and 3.11 render it as a genuine
   plain-Markdown table with a `: Caption {#id}` line under it, no raw
   HTML in either version. That caption-line syntax isn't plain
   CommonMark either, though, so `postprocess()` converts it to this
   pipeline's usual `<figcaption>` (the `.content figcaption` CSS rule
   applies to any figcaption regardless of a `<figure>` parent — and a
   `<figure>` can't wrap the table itself, since CommonMark never
   re-parses markdown inside a raw HTML block, which would corrupt the
   table). Incidental bonus: Chapter 6's table caption had a `` ` ``
   backtick that was rendering as a literal, unstyled character on the
   *already-live* site (the old sentinel path never did the
   backtick-to-`<code>` conversion `postprocess()` does everywhere
   else) — now fixed too.
6. **A `\hypertarget` landing as the leading content of a table cell**
   — a third, unrelated mechanism, found only after fixing #5 exposed
   it (it was hiding behind the *other* table-in-figure problem in the
   same chapter). Chapter 3's special-characters table places an
   `\index{}` right after a row's `\\[3pt]` separator; positionally that
   puts it at the very start of the *next* row's first cell, and
   confirmed by fragment test: a hypertarget as a cell's first content
   makes pandoc treat it as its own block-level Div rather than an
   inline Span, regardless of what follows or whether whitespace
   separates them. Since `tex2md.py` invokes pandoc with grid/multiline/
   simple tables all disabled (pipe tables only, for consistent
   styling), and a pipe table can't represent a cell with block content
   at all, pandoc had nowhere to fall back to but raw HTML for the
   entire table — **under both 2.7.3 and 3.11 equally**, so this was
   never a version-drift issue and was already live-site-broken today
   (confirmed: the currently-committed `3.md` already has this exact
   raw, unstyled `<table>` for this content). `move_hypertargets_off_table_row_starts`
   moves a row-leading hypertarget run to right after the next real
   content in that cell instead of before it (stopping only at an
   actual `&` or `\\`, not any single backslash, since cell content
   routinely has its own backslash commands like `\verb+\+`); a
   hypertarget in the table's last row, with no following row to swap
   with, is hoisted past `\end{tabular}` instead, the same shape as
   item 3 above. This fix is a genuine improvement to *today's* live
   site, independent of the whole Pandoc-3.x question.
7. **Figures wrapping a bare Haskell code listing that isn't a
   `\beware` box** — 26 instances across 9 chapters (`1`, `2`, `6`,
   `14`, `15`, `16`, `17`, `20`, `21`), e.g. Chapter 20's "Simple data
   types" figure, Chapter 1's ASCII-art `Picture` example. Same
   "`\begin{figure}` added by hand purely for print float placement"
   pattern as `\beware` (item covered by `unwrap_bare_beware_figures`)
   and the genuine-table case (item 5) — `unwrap_bare_code_listing_
   figures` strips just the wrapper tokens. This was wrongly believed
   already fixed in an earlier version of this file ("no longer shows
   up in the fallback scan... worth a quick recheck") — that recheck
   never actually happened before the file said it was resolved. It
   wasn't; the fingerprint check used at the time only looked for
   `<embed `/`<table>`/`<blockquote>` at line-start and missed this
   shape entirely (`<figure>` then `<div class="sourceCode">`).
8. **A hypertarget landing immediately before `\caption{`, not just
   before `\end{figure}`** — Chapter 2's GHCiPreludeModules figure has
   `\index{GHCi!modules in}` between the image and its caption.
   `hoist_hypertargets_out_of_figures` (item 3) widened to also hoist
   this shape, past the caption and label instead of before them.
9. **N side-by-side images sharing one caption** — Chapter 16's 3- and
   4-image search-tree diagrams, Chapter 19's before/after pair (the
   book's only 3 instances). Turned out to need more than unwrapping
   their `\begin{center}` (item 2): confirmed by direct fragment test
   that even a bare, wrapper-free multi-image figure still fails under
   3.11 — Pandoc's writer only has a plain-Markdown representation for
   a Figure block holding *one* image, full stop. `split_multi_image_
   figures` splits one N-image `\begin{figure}` into N single-image
   ones sharing the same caption/label; `postprocess()` already has a
   pair-merge pass built for exactly this shape (it's what recombines
   the *unsplit* 2.7.3-native version of the same thing today), which
   recombines them back into one `<figure>`.
10. **`_table_caption_to_figcaption` (item 5) couldn't tell a table
    caption from a `\begin{description}` list body under 3.11.** It
    disambiguated by counting spaces after `:` (one for a table
    caption, three for a definition body) — true for Pandoc 2.7.3's
    writer, false for 3.11's, which uses one space for *both*.
    Regenerating under 3.11 as-is corrupted every definition-list item
    into a stray `<figcaption>`, confirmed directly (Chapter 6's
    Haskell-resources reading list). Fixed with a disambiguation that
    doesn't depend on either version's whitespace convention: a table
    caption is always the line right after the table's own last
    pipe-delimited row (blank lines allowed in between); a definition
    list's body never is. Affects the 4 chapters using
    `\begin{description}`: `0`, `6`, `8`, `20`.

All ten fixes verified corpus-wide: under the pinned 2.7.3, exactly the
same 15 chapters change as before any of this started (`1`, `2`, `3`,
`6`, `9`, `11`, `13`, `14`, `15`, `16`, `17`, `19`, `20`, `21`, `22`),
every anchor id preserved (checked by extracting and diffing every
`id="..."` in old vs. new output), no duplicate ids, no leaked
`[]{label=...}`/table-caption artifacts, and every word-multiset diff
either zero or traced to an understood, desirable change (Chapter 3's
raw-HTML table becoming a real pipe table; Chapter 6's backtick fix).
This part is solid, committed, and live: `Website/chapters/*.md` was
regenerated and pushed the same day, and the live-site bugs it fixed
along the way (Chapter 3's special-characters table, Chapter 6's
caption backtick) are confirmed fixed on the deployed site. Under real
Pandoc 3.11: **zero chapters left with the raw-HTML-fallback problem,
corpus-wide** — down from 13 chapters at the start of this
investigation, confirmed with a comprehensive scan (not just the
`<embed `/`<table>`/`<blockquote>` fingerprint that missed item 7, but
also any bare `<figure>` not matching this pipeline's own
`<label class="checkbox-label">` convention, any `<div class=
"sourceCode">`, and any stray `<figcaption>` not accounted for by a
known-legitimate case).

**Known-incomplete verification along the way (corrected twice in one
day, before the diff below caught the rest):** two separate "this is
fixed" claims made the same day were wrong. The first ("zero chapters
remaining") was based only on the narrow `<embed `/`<table>`/
`<blockquote>` fingerprint and missed item 7. The second was catching
real distinct causes (items 8, 9) as side effects of fixing item 7, not
from deliberately looking for them — the corpus kept having one more
thing than the last check found. What actually worked: after each fix,
rerunning the *broadest* plausible fingerprint scan (not just the one
the current fix targets) across the *whole* corpus, every time — and,
in the end, the rendered-HTML diff below, which is what actually
settled it.

## The rendered-HTML diff

The raw-HTML-fallback problem above was the entire subject of this
investigation across three sessions, but every verification up to this
point compared Markdown *source* (word-multiset + id-set diffs)
between 2.7.3 and 3.11 — right for catching content loss and broken
anchors, but blind to purely cosmetic-*looking* differences that might
actually render differently once mdBook builds the final page. The
real test: build the site both ways (`mdbook build` against the
2.7.3-regenerated chapters, and again against a fresh 3.11
regeneration) and diff the *rendered* `book/` output page by page, not
just the markdown that feeds them.

That diff found real issues neither the markdown-source diffs nor the
fallback fingerprint had caught — ten more distinct causes, fixed in
two more commits the same day:

**Already-live bugs, independent of any Pandoc version** (fixed
regardless of the migration question — these were broken on the site
before this thread even started):

- `\looseness=N` (a print-layout paragraph-tightness hint, no braces)
  leaking as literal `.=-1`/`.=1` text — pandoc drops `\looseness` but
  not the `=N` half. 4 uses, Chapters 4/16/17.
- `\hbox{X}` silently dropping its whole argument, the same failure
  `\mbox` already had a fix for — Chapter 13 was missing "and
  `a -> [a]`." from a sentence entirely.
- Bare `\tt` and `{\tt ...}` (plain LaTeX's older typewriter-font
  switch, distinct from `\mi`/`\ttfamily`) never being recognized at
  all — a whole table in Chapter 12 and headings in Chapters 4/7 were
  rendering unstyled where they should be code.
- `\mi` immediately followed by a digit (`\mi456.23`, no space) not
  matching the old regex's `\b` (a digit is a regex "word" character,
  so `\b` doesn't end the command name there the way a real LaTeX
  control word does) — a number was silently vanishing from the
  glossary.
- A `\ttfamily`/`\tt`/`\mi` scope with nothing in it before the next
  cell boundary (a deliberately empty table cell) producing literal
  stray backticks, since an empty ` `` ` isn't a real CommonMark code
  span — opsTable.
- `` ``` {.haskell} `` not being normalized to `` ```haskell `` when
  quoted inside a `\beware` blockquote or indented under a list item —
  syntax highlighting was silently broken for 102 code blocks across
  17 chapters.

**Pandoc-3.11-specific bugs** (needed fixing before the pin could
safely move):

- A footnote nested inside an image's caption gets its definition
  duplicated by Pandoc 3.11's writer when the figure degrades to a
  plain image — Chapter 13's Wikimedia attribution footnote.
- `\verb` loses track of its own delimiter specifically inside a table
  cell (confirmed with both `+` and `|` delimiters, confirmed clean in
  ordinary prose) — converted to `\texttt{}` instead (escaping a
  literal backslash to `\textbackslash{}` first: `\texttt{\}` parses
  differently from `\verb+\+` in real LaTeX, caught by a full-corpus
  id-diff before it shipped).
- The `::: <environment>` fence-stripping (for `\begin{center}` and
  similar) didn't handle a blockquote-quoted, indented, or *nested*
  fence (Chapter 2's ASCII art is a `\begin{minipage}` inside a
  `\begin{center}`) — broke Chapters 2 and 11's rendering into garbled
  definition lists.
- Pandoc 3.11 tags a `\url`-derived autolink with a stray `{.uri}`
  attribute that leaks as visible text — Chapter 19's footnote.

Verified corpus-wide: every fix a confirmed no-op under the pinned
2.7.3 except real, understood content restorations (id-checked and
word-content-checked throughout). Under real Pandoc 3.11: the
raw-HTML-fallback count still zero, and the rendered-HTML diff across
every page came down to only cosmetic, understood differences —
harmless code-span splitting (confirmed harmless: this theme's inline
`<code>` has no padding/background, so a code span split into several
adjacent `<code>` elements is visually identical to one), an invisible
figcaption-anchor position difference, escaped vs. unescaped `#`/`_`
characters (both render as the literal character either way), a
soft-hyphen typography difference, and a couple of pre-existing,
unrelated, equally-broken-in-*both*-versions warts (see "Known
remaining issues, unrelated to Pandoc" below) — plus a genuine
corpus-wide *regeneration*, since Pandoc's own default Markdown-writer
style differs between major versions (ATX `#` headings instead of
Setext `===` underlines, a space in `` ``` haskell ``, tighter list
markers) even where nothing else changed.

**Pin moved 21 Sep 2026.** `_PINNED_PANDOC` now resolves
`/opt/homebrew/bin/pandoc`; `Website/chapters/*.md` was regenerated
under it and committed in the same change. None of this was urgent —
it cost nothing to leave the pin in place while unresolved — but the
concrete blocker is gone, and the day's work (twenty distinct fixes
between the fallback problem and the rendered-HTML diff) is a real,
substantial improvement to the live site independent of the version
question, several of which were already paying off before the pin
moved. One more, unrelated to any of this: Simon spotted a literal
stray backslash after the Preface's sign-off ("December 2010\") on the
live site the same day, fixed separately (a trailing hard-line-break
marker with nothing left to break to, right before the enclosing group
closes -- see the git history for the full fix).

## Two more, fixed the same day (unrelated to Pandoc, found by the rendered-HTML diff)

- **Chapter 1's `[[typesIntro]]`** (garbled bracket text near "Types")
  was an orphaned secondary `\label`: `\section{Types}\index{type}
  \label{typesIntro}` has `\index{type}` (this book's first
  occurrence, so already a `\hypertarget` by this point) glued
  directly onto `\label{typesIntro}` with *no* whitespace between them
  at all. An existing fix already moved a hypertarget from before a
  label to after it (Pandoc only attaches `\label` to its enclosing
  heading when the label immediately follows with nothing in between),
  but its regex required a literal newline between the two
  (`\s*\n\s*`) — safe for every other case in the book, but this one
  has zero whitespace of any kind, so it never matched. Widened to
  `\s*` (newline optional, not required).
- **Chapter 21's `\[...\]`-wrapped `\begin{tabular}`** (an exercise
  question aligning three lines, not real math at all) rendered as
  garbled literal text ("tabularll associative: & ..." instead of a
  table) — Pandoc's math-mode reader parses the whole
  `\begin{tabular}{ll}...\end{tabular}` as literal math source instead
  of a table, since it's wrapped in `\[...\]`. Confirmed by fragment
  test that stripping just the `\[`/`\]` delimiters (LaTeX doesn't
  require them around a `tabular` used this way) lets Pandoc's
  ordinary table reader handle it correctly instead — a clean Markdown
  table. The book's only instance of this shape.

Both verified corpus-wide (only these two chapters changed, plus a
harmless anchor-order swap as an incidental side effect of the first
fix in Chapter 17 — same ids, same words, just two adjacent empty
anchors trading places) and confirmed to work under both the old 2.7.3
binary and the current 3.11 pin.

## Known remaining issue, unrelated to Pandoc

- **Glossary**: `\texttt{--}` (Haskell's line-comment marker) renders
  as an en-dash character (–) instead of two literal hyphens under
  2.7.3 (fixed under 3.11, now the default) — possibly not even a bug:
  real LaTeX's own `--`-to-en-dash ligature applies inside `\texttt`
  too, so this might just be faithfully reproducing what the *printed*
  book itself shows; not verified against the actual PDF.

## Is the 3.11 pin durable long-term?

Much simpler story than the old one below: `/opt/homebrew/bin/pandoc`
is a Homebrew-managed symlink into `/opt/homebrew/Cellar/pandoc/3.11/`,
a genuinely native arm64 build kept current by the same package
manager as everything else on this machine — not a one-off,
hand-installed, x86_64-under-Rosetta binary nobody else can reproduce.
If it's ever lost, `brew install pandoc` gets it back (a *current*
version, not necessarily 3.11 exactly — re-verify with the same
discipline as this whole investigation, full-corpus regeneration plus
a rendered-HTML diff, before trusting whatever that installs without
checking `_check_pandoc_version`'s warning first). `brew upgrade`
moving it past 3.11 silently is the one real risk worth naming; `brew
pin pandoc` would prevent that if it matters enough to guard against,
though nothing here currently requires it — same as before, nothing
forces an upgrade (`deploy-book.yml` never invokes Pandoc at all, only
`mdbook build` against the already-committed `Website/chapters/*.md`).

**Nothing to action here now.**

<details>
<summary>Archived: why the old 2.7.3 pin's durability was a real
concern (no longer applicable, kept for history)</summary>

The real, if bounded, cost was durability of one unmanaged binary on
one machine:

- `/usr/local/bin/pandoc` was a 2019 x86_64 build, not tracked by any
  package manager this repo knew about. **Checked (19 Sep 2026): the
  exact release was still available** — Pandoc's GitHub release
  [2.7.3](https://github.com/jgm/pandoc/releases/tag/2.7.3) still
  hosted the original `pandoc-2.7.3-macOS.pkg` (matching the installed
  binary exactly), and the source was still on Hackage (`cabal get
  pandoc-2.7.3` worked). So if that binary was ever lost, it could have
  been re-fetched as-is — no re-porting needed, just re-running the
  original 2019 installer.
- It depended on Rosetta 2 continuing to run x86_64 binaries on Apple
  Silicon. Apple kept extending Rosetta 2's support for years with no
  announced end date, but hadn't committed to "forever" — a real, if
  long-tail, risk.
- **Checked whether a native-arm64 rebuild would have been a viable
  fallback if Rosetta support ever eroded: not a quick one, but not
  obviously hopeless either.** Building pandoc 2.7.3's own source (from
  Hackage) against a period-correct 2019 dependency graph, using a
  genuinely native arm64 GHC (worth noting: the `ghcup`-installed GHC
  already on this machine turned out to itself be an x86_64 binary
  running under Rosetta, despite this being an Apple Silicon Mac —
  swapped in Homebrew's native arm64 GHC 9.14.1 instead), got
  substantial progress: it compiled cleanly past one real bug
  (`HsYAML-0.1.2.0`, a transitive, LaTeX-irrelevant dependency used
  only for YAML frontmatter, missing an import that a newer `mtl` no
  longer papers over — a one-line fix), then hit a second, deeper one
  in `blaze-builder-0.4.1.0` (part of the HTML-writer path): GHC's own
  representation of 32-bit words at the primitive-op level changed
  sometime in the last six years (`Word32#` is now a distinct type from
  `Word#`), breaking a hand-written bit-shift helper — real bit-rot in
  a six-year-old dependency, not a version-bounds annoyance, and
  fixing it would have meant editing low-level primop calls rather than
  relaxing a constraint. Stopped there rather than continuing to chase
  further such issues (`hslua`'s C/Lua FFI bindings, not yet reached,
  were a likely next one) — decided not worth pursuing further at the
  time, since nothing then required it.

This entire section is moot now that the pin is a Homebrew-managed
native arm64 binary, but is kept here in case the pin is ever reverted
or a similarly unmanaged binary is pinned again in the future.

</details>
