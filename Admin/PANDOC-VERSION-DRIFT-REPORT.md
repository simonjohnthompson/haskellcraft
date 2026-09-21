# Pandoc version drift — status and open issue

**The pandoc-version-drift investigation itself is fully resolved.**
Every chapter in `Website/chapters/*.md` regenerates byte-for-byte
identical to the pinned Pandoc 2.7.3 binary — verified corpus-wide, zero
remaining diffs, as of 20 Sep 2026. The full investigation (two pandoc
binaries on `$PATH`, what 3.11 does differently and why, nine chapters
found carrying live un-postprocessed 3.x HTML and fixed, two `\beware`
newline typos, a dropped Wikimedia attribution footnote, five more
chapters normalised for consistency) is archived in full at
`Admin/Archive/PANDOC-VERSION-DRIFT-REPORT.md`.

This file tracks only what's still open. As of 21 Sep 2026, the
raw-HTML-fallback issue described below is **fully fixed**: a
corpus-wide regeneration against the real Pandoc 3.11 binary shows
**zero** chapters left with un-postprocessed raw HTML, down from 13 at
the start of this investigation. The fixes are correct and verified but
still uncommitted — see below.

## Why we couldn't just move to the latest Pandoc (now fixed)

`tex2md.py` (`Website/convert/tex2md.py`) resolves an explicit
`/usr/local/bin/pandoc` itself (commit `5a63daa`), falling back to bare
`pandoc` on `$PATH` if that's absent, and warns loudly on stderr if the
resolved binary isn't 2.7.x. This wasn't inertia — a real regression
blocked moving to Pandoc 3.x (checked directly against 3.11), now
resolved by the fixes below (still uncommitted, so the pin itself
hasn't moved yet — see "Is the 2.7.3 pin durable long-term?" below for
why that's fine either way).

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

**Fixed (uncommitted, in `Website/convert/tex2md.py`):**

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

All six fixes verified corpus-wide: under the pinned 2.7.3, exactly the
same 15 chapters change as before any of this started (`1`, `2`, `3`,
`6`, `9`, `11`, `13`, `14`, `15`, `16`, `17`, `19`, `20`, `21`, `22`),
every anchor id preserved (checked by extracting and diffing every
`id="..."` in old vs. new output), no duplicate ids, no leaked
`[]{label=...}`/table-caption artifacts, and every word-multiset diff
either zero or traced to an understood, desirable change (Chapter 3's
raw-HTML table becoming a real pipe table; Chapter 6's backtick fix).
Under the real Pandoc 3.11 binary: **zero chapters left with
un-postprocessed raw HTML**, corpus-wide, down from 13 at the start.

Left uncommitted for now, simply because this is mid-session work
rather than any remaining doubt about correctness.

None of this was urgent to begin with — see below, it cost nothing to
leave the pin in place while unresolved — but the concrete blocker that
made "just upgrade Pandoc" more than a five-minute change is now gone.
Whether to actually move the pin to a current Pandoc release is a
separate decision (worth a fresh, deliberate corpus-wide regeneration
and review before flipping it, not assumed from this fix alone) — not
yet made.

## Is the 2.7.3 pin durable long-term?

Nothing forces an upgrade: `deploy-book.yml` (the CI that builds and
publishes the live site) only runs `mdbook build` against the
already-committed `Website/chapters/*.md` files — it never invokes
`tex2md.py` or Pandoc. Pandoc only runs when someone manually regenerates
a chapter from `.tex` on a dev machine, so there's no security-patch
cadence or CI mandate pushing an upgrade, and the pin can sit unchanged
indefinitely with zero live-site risk. Missing Pandoc 3.x features is a
hypothetical concern, not a known one — every chapter in the corpus now
regenerates byte-identical under 2.7.3, so there's no evidence today that
2.7.3 is mishandling anything the book actually needs.

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

**Nothing to action here now.** Revisit only if Apple signals an actual
end date for Rosetta 2, or if `/usr/local/bin/pandoc` is ever lost and
needs re-fetching.
