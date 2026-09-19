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
2. **Figures and tables containing an embedded `\label`/`\index`** — 2.7.3
   emits plain Markdown image syntax (which `tex2md.py`'s
   `_sized_thumbnail()` post-processing, around line 2658, then wraps in
   the site's click-to-zoom `checkbox-label`/`img-wrapper` HTML) and clean
   GFM pipe-tables. 3.11 instead emits a raw `<figure><embed
   src="..."/><div id="...">...</div>...</figure>` HTML block and, for the
   same reason, a raw `<table>` instead of a pipe table. `tex2md.py`'s
   post-processing pattern-matches 2.7.3's plain-Markdown shape and simply
   doesn't fire against 3.11's HTML shape. **Not harmless**: regenerating
   any affected chapter under 3.11 silently drops the zoom-on-click
   behaviour from every such figure and replaces a clean pipe table with
   unstyled raw HTML.

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
2. **Medium-term decision** (still open — needs your call): either (a)
   treat the pin above as the final answer, accepting that
   `/usr/local/bin/pandoc` (2.7.3, 2019) is a required, if unmanaged and
   ageing, dependency of this repo — or (b) update `tex2md.py`'s
   figure/table post-processing to also recognise Pandoc 3.11's HTML
   output shape, then do one deliberate full-corpus regeneration off the
   Homebrew binary, checking rendered output before committing. Given
   `brew` has already moved on to 3.11, and a 2019-era x86_64 binary won't
   be around forever, (b) is the more durable fix, but is real work, not a
   drive-by change.
3. ~~**While doing that regeneration pass**, also pick up the eight stale
   `19→20`/`20→21` cross-references above...~~ **Done** (commit `3eab103`,
   ahead of the medium-term decision in (2) — these were cheap enough to
   fix immediately using the newly-pinned binary rather than waiting).
4. ~~**Low-priority hygiene**: delete the dead `~/.cabal/bin/pandoc` (2010,
   32-bit, can't execute)...~~ **Done**: removed from this machine
   (`~/.cabal/bin/pandoc`, outside the repo, so no commit applies).
   `which -a pandoc` now lists only `/opt/homebrew/bin/pandoc` (3.11) and
   `/usr/local/bin/pandoc` (2.7.3, the one `tex2md.py` pins to).
