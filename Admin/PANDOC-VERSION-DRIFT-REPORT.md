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

This file tracks only what's still open.

## Why we can't just move to the latest Pandoc

`tex2md.py` (`Website/convert/tex2md.py`) resolves an explicit
`/usr/local/bin/pandoc` itself (commit `5a63daa`), falling back to bare
`pandoc` on `$PATH` if that's absent, and warns loudly on stderr if the
resolved binary isn't 2.7.x. This isn't inertia — a real regression
blocks moving to Pandoc 3.x (checked directly against 3.11) today.

The root cause (see the archived report for the full derivation):
Pandoc 3.x's Markdown writer can only degrade a LaTeX `\begin{figure}`
to plain Markdown when its content is a **bare image with no float
placement argument**. Anything else — a placement argument like `[t]`
on an otherwise-bare image, a genuine table (`\begin{tabular}`) inside
the figure, or any other content (code listing, blockquote) — makes it
fall back to raw, un-styled HTML instead, and for anything containing
Haskell source, to Pandoc's own syntax-highlighted HTML in place of a
plain ` ```haskell ` fenced block. This session fixed the one instance
of that we'd actually hit in practice — the book's `\beware` aside boxes
— by unwrapping their figure wrapper in preprocessing before Pandoc ever
sees it (cheap, and now resolved: `rawblockquote` count is 0 corpus-wide
under a fresh 3.11 regeneration, checked 20 Sep 2026). But re-checking
the whole corpus against 3.11 after that fix shows real, unaddressed
exposure remains:

- **Bare-image figures using a `[t]`/`[b]`/etc. placement argument** —
  15 chapters would lose click-to-zoom on at least one figure under 3.11
  (`1`, `2`, `3`, `6`, `9`, `11`, `13`, `14`, `15`, `16`, `17`, `19`,
  `20`, `21`, `22`). This one's cheap to fix the same way the `\beware`
  case was (strip the placement argument in preprocessing — it's
  meaningless outside a real LaTeX float) but hasn't been done, since
  nothing forces the issue while the pin holds.
- **Genuine tables nested inside a `\begin{figure}`** — `2.md`, `3.md`
  and `6.md` have at least one each. Stripping a placement argument
  doesn't help here; fixing it under 3.x means either restructuring the
  `.tex` source to pull the table out of its figure (losing the caption/
  float for the *printed* book) or teaching `tex2md.py` to convert
  Pandoc's raw `<table>` HTML back into a clean pipe table.
- **Figures wrapping a direct Haskell code listing that isn't a
  `\beware` box** (e.g. Chapter 20's "Simple data types" figure) — the
  same syntax-highlighted-raw-HTML problem `\beware` boxes had, but the
  `unwrap_bare_beware_figures` fix only recognises the `\beware` shape
  specifically. Not yet scoped in detail; likely fixable the same way
  (unwrap before Pandoc sees it) but not counted or verified.

None of this is urgent — see below, it costs nothing to leave the pin in
place — but it's the concrete reason "just upgrade Pandoc" isn't a
five-minute change: three distinct content shapes would all need their
own fix (two of them still undone) before a 3.x regeneration of the
whole corpus would be safe.

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
