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

## Open issue: is the 2.7.3 pin durable long-term?

`tex2md.py` (`Website/convert/tex2md.py`) resolves an explicit
`/usr/local/bin/pandoc` itself (commit `5a63daa`), falling back to bare
`pandoc` on `$PATH` if that's absent, and warns loudly on stderr if the
resolved binary isn't 2.7.x. **Decided: stay pinned to 2.7.3** rather
than move to a newer Pandoc — see the archived report's "Why (a), not
(b)" for the reasoning (recognising Pandoc 3.x's HTML output shape
properly, and reversing its syntax highlighting back to plain code
blocks, would have been real multi-session engineering; the one part of
that scope that mattered in practice — the `\beware` figure wrapper —
got a cheaper, narrower fix instead, and is now resolved).

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
