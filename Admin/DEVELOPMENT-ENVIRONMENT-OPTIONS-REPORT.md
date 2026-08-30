# Report: Development Environment Options for Readers/Students

Prepared to survey what readers of *Haskell: The Craft of Functional
Programming* could actually write and edit code *in* — editors, IDEs, and
the extensions/tooling that give a more guided experience than a bare
terminal — once they have some way to run GHC/GHCi at all. Findings that
depend on the current behaviour of specific tools/extensions were checked
directly in August 2026, not recalled from memory.

This report sits alongside two companion reports and assumes their
findings:

- `Admin/CODE-COMPATIBILITY-REPORT.md` — what needs to work in
  `Code/Craft3e` itself, and how its module dependencies are delivered.
- `Admin/RUNNING-HASKELL-OPTIONS-REPORT.md` — how a reader gets GHC/cabal
  running in the first place (local GHCup install, Docker, Codespaces/
  Gitpod, browser playgrounds).
- `Admin/CODE-VS-BOOK-DISCREPANCIES-REPORT.md` — specific places the book's
  printed code no longer matches what actually compiles under a modern GHC
  (see the note under Option 1 below for what this looks like through HLS
  specifically).

This report is one layer up: given GHC is available somehow, what should a
reader actually type code *into*, and what live help (error highlighting,
type-on-hover, jump-to-definition) can realistically be switched on.

## The two layers: the compiler, and the editor tooling that talks to it

It's worth being explicit about a distinction that caused some confusion
while preparing this report, because it explains several of the caveats
below.

**GHC and cabal** — covered by the companion reports — are the compiler and
build tool. They compile and run the book's code. The book's code is not
tied to any particular GHC version; GHC 9.6.7 was simply the version used
for testing in `Admin/CODE-COMPATIBILITY-REPORT.md`, and nothing in the
code depends on anything specific to that exact release.

**The Haskell Language Server (HLS)** is a different thing: it's what an
editor talks to for *live* diagnostics, hover-for-type, go-to-definition,
and similar IDE features. HLS isn't a simple text scanner — it's built by
linking directly against GHC's own internal compiler library, and that
internal API changes with every GHC release. As a result, a single HLS
*release* actually bundles several binaries inside it, one compiled against
each supported GHC version, plus a small wrapper program that detects a
project's GHC version and launches the matching binary. In the normal case
this is invisible — a reader never thinks about it — but it means editor
tooling has its own, separate set of moving parts and failure modes beyond
"does the code compile," which is why this is a report of its own rather
than a section of the companion reports.

Every option below is still fully usable with **zero** editor tooling and
just `cabal repl`/`ghci` in a terminal — HLS only adds convenience on top,
never a requirement.

## Option 1 — VS Code + the official Haskell extension (recommended default)

The [`Haskell`](https://marketplace.visualstudio.com/items?itemName=haskell.haskell)
extension (publisher `haskell.haskell`, maintained by the Haskell
Foundation/community) is the standard choice, and is a reasonable default
development environment to point students at: VS Code itself is free,
actively developed, cross-platform, and — as covered in the companion
report's Option C — is also exactly what GitHub Codespaces and the Dev
Containers workflow present to a reader, so the same extension and the same
experience apply whether GHC is installed locally or a reader is working in
the zero-install devcontainer.

**What it gives, once HLS is running for a project:**

- Inline red/yellow squiggles for type errors and warnings, matching what
  `cabal build`/`ghci` would report, but live as you type.
- Hover-for-type: hovering any identifier shows its inferred/declared type.
- Go to definition / find references, including across the book's sibling
  modules (`Chapter5`, `Solutions5`, etc.).
- Code actions — for example, inserting a missing import, or filling in a
  typed hole — offered as quick fixes.
- Document outline (jump to a specific function/definition in a long
  chapter file).
- Optional formatting via Ormolu/Fourmolu if a reader configures one.

Plain syntax highlighting and bracket matching work immediately with no
setup at all, independent of any of the above.

**How the extension obtains HLS:** its default setting,
`haskell.manageHLS: "GHCup"`, means that on first opening a `.hs` file it
looks for the `ghcup` tool. If `ghcup` isn't present at all, it offers to
install the whole toolchain (GHCup, GHC, cabal, and HLS) interactively —
this is a real, guided, in-editor alternative to a reader manually running
the GHCup bootstrap script from the companion report's Option A, and is
worth mentioning to readers as a possible *first* step rather than a
terminal command. If `ghcup` is present (as after a normal GHCup install)
but the specific GHC-version-matched HLS build isn't yet installed, the
extension fetches it via `ghcup install hls` automatically the first time
it's needed. An alternative setting, `haskell.manageHLS: "PATH"`, instead
uses whatever `haskell-language-server-wrapper` a reader already has on
`PATH` — relevant if they're managing the toolchain themselves rather than
letting the extension do it.

**A related caveat, this one about the book's own text rather than the
tooling:** the "Inline red/yellow squiggles... matching what `cabal
build`/`ghci` would report, but live as you type" bullet above cuts both
ways. It's exactly how a reader would first encounter the gap documented in
`Admin/CODE-VS-BOOK-DISCREPANCIES-REPORT.md`: typing Chapter 18's printed
`instance Monad (MP a) where fail s = MP none` into a new file would show a
live squiggle under `fail` (`'fail' is not a (visible) method of class
'Monad'`) the moment HLS finishes checking it, before the reader ever runs
`cabal build`. That's not an HLS bug or a devcontainer misconfiguration — it's
HLS correctly reporting that the book's printed code, transcribed exactly,
no longer compiles under the Applicative-Monad Proposal (2015) and
MonadFail Proposal (2019), both of which postdate the book. The already-
working fix lives in `Code/Craft3e` (`ParseLib.hs`, `Calculator/
CalcParseLib.hs`); worth knowing so a "the extension is broken, it's
underlining code straight from the book" report isn't chased as an editor
problem.

**Released.** `ParseLib.hs`'s fix has since shipped as `Craft3e-0.2.0.3` on
Hackage (see `Admin/RUNNING-HASKELL-OPTIONS-REPORT.md`), confirmed by
re-downloading the package fresh via `cabal update && cabal get
Craft3e-0.2.0.3`. This doesn't change anything about the caveat above — a
reader typing the book's `MP`/`State` examples in by hand still hits the
same live HLS squiggle regardless of which package version they have
installed, since the gap is in the *book's printed text*, not in whichever
`Craft3e` a reader's project happens to depend on.

**Caveat, confirmed during testing for this report:** the version-tie
described above means that if the GHC version visible to the extension has
no matching prebuilt HLS binary — which normally only happens right after a
very new GHC release, or, as found while preparing this report, because of
an unusually old base OS whose system libraries are too old for the
prebuilt HLS binary (see "Devcontainer status" below) — the extension shows
an install/start-up error rather than silently degrading. This affects
*only* the live-editing features; a reader can always fall back to
`cabal repl` in a terminal, which is entirely unaffected and was separately
confirmed working (companion report).

## Option 2 — Neovim or Vim, with an LSP client

For readers already comfortable in a terminal-based editor: Neovim's
built-in LSP client (`nvim-lspconfig`, or newer Neovim's native `vim.lsp`
config) can be pointed at `haskell-language-server-wrapper` directly, once
GHCup has installed it (Option A of the companion report). Plugins such as
`haskell-tools.nvim` bundle sensible defaults (diagnostics, hover, code
actions) specifically for Haskell projects. Vim (not Neovim) needs a
general-purpose LSP plugin such as `vim-lsp` or `coc.nvim`, configured
similarly. This is a capable, lightweight option, but the setup itself
(installing and wiring a plugin manager, an LSP client, and a Haskell
plugin) is more involved than VS Code's single-extension install, so it's
best suited to readers who already use Neovim/Vim as their everyday editor
rather than a first recommendation for newcomers.

## Option 3 — Emacs, with haskell-mode and lsp-haskell

Similarly capable for readers already using Emacs: `haskell-mode` provides
Haskell-aware editing (indentation, REPL integration via `inferior-haskell`
processes), and `lsp-mode` + `lsp-haskell` wire up HLS for live diagnostics
and the usual IDE features. As with Neovim, this is a good option for
existing Emacs users, not a first recommendation for someone starting from
nothing.

## Option 4 — Terminal-only, no editor tooling at all

Always available, and worth stating explicitly as a legitimate option
rather than a fallback of last resort: any text editor (even one with no
Haskell awareness at all) plus `cabal repl`/`ghci` in a terminal, relying
on GHCi's own error messages — which are generally clear and precise about
line/column and the nature of the error — instead of live in-editor
diagnostics. This is closest to the book's own original assumed workflow
("start GHCi, `:load` a file"), has zero additional setup beyond whichever
option from the companion report a reader chose for GHC itself, and sidesteps
every HLS/GHC-version-matching concern above entirely, since it never
invokes HLS. The cost is a slower edit/error feedback loop (save, then
`:reload`, rather than live squiggles) and no go-to-definition/hover.

## Devcontainer status (Option C of the companion report), as tested

This section reflects hands-on testing of `.devcontainer/devcontainer.json`
specifically for HLS/editor support, distinct from the `cabal build`/
`cabal repl` testing already reported as successful in the companion
report. Both issues found below have since been fixed in the checked-in
config and reconfirmed in a live GitHub Codespace.

**Issue 1 — glibc too old for prebuilt HLS binaries (fixed).** The
devcontainer was originally based directly on the official
[`haskell:9.6`](https://hub.docker.com/_/haskell) Docker image, which
provides GHC and cabal but not the `ghcup` tool itself — so opening a `.hs`
file produced the extension's "Project requires GHCup but it isn't
installed" message, the issue that prompted this report. Installing `ghcup`
alongside the image's existing GHC/cabal is straightforward, but testing
then found a second, more fundamental problem: the prebuilt HLS binaries
`ghcup` currently distributes require a newer glibc (Debian 12/13-era) than
the `haskell:9.6` image's Debian 11 base provides, on both `aarch64` and
`x86_64` — an OS/packaging mismatch, not an architecture-specific one.
**Fix**: `.devcontainer/devcontainer.json` now uses
`mcr.microsoft.com/devcontainers/base:bookworm` (a current, actively
maintained Debian 12 base) and installs the whole toolchain (GHC 9.6.7
pinned, cabal, and HLS) via GHCup directly, mirroring the companion
report's Option A almost exactly, just automated inside the container.

**Issue 2 — HLS cradle detection anchored to the wrong workspace root
(fixed).** With Issue 1 fixed and the devcontainer's workspace folder set
to the repository root, opening `Chapter5.hs` still showed
`Test.QuickCheck` as an unresolvable module and gave no hover-for-type —
despite `QuickCheck` being correctly listed in `Craft3e.cabal`'s
`build-depends`. The Haskell extension's Output log showed HLS falling
back to a bare GHC session with no package database at all (`In-place unit
ids: [ main-... ]`), meaning `hie-bios` (the library HLS uses to work out
how to load a file) never found `Craft3e.cabal` in the first place. Adding
a `cabal.project` file did not fix it. The actual cause: `hie-bios`'s
automatic cradle search anchors to the *VS Code workspace root*, not to
the individual file being edited — and the workspace root was the
repository root, two directories above `Code/Craft3e` where the actual
cabal package lives, so the search never looked there at all. Confirmed by
opening `Code/Craft3e` itself as the workspace root in the same running
container: the `QuickCheck` error disappeared and hover-for-type started
working immediately. **Fix**: `.devcontainer/devcontainer.json`'s
`workspaceFolder` now points directly at `Code/Craft3e` rather than the
repository root — the one consequence being that the rest of the repo
(book source, `Admin/` reports) isn't shown in that VS Code window, judged
acceptable since this devcontainer exists for readers running/editing the
book's code, not editing the book itself.

Both fixes are now live in `.devcontainer/devcontainer.json`, and a full
round-trip — create a live Codespace, open `Chapter5.hs`, confirm no
GHCup/module errors and working hover-for-type — was used to confirm the
final config, not just `cabal build`/`cabal repl` (which were already
confirmed working end-to-end, including in a live Codespace, before this
editor-tooling testing began).

## Summary and recommendation

| Option | Setup effort | Live diagnostics/hover/goto-def | Best suited to |
|---|---|---|---|
| 1. VS Code + Haskell extension | Low — one extension install, rest can be guided by the extension itself | Yes, once HLS is running | Newcomers; the default recommendation |
| 2. Neovim/Vim + LSP client | Medium — plugin manager + LSP client + Haskell plugin | Yes | Readers already living in Neovim/Vim |
| 3. Emacs + haskell-mode/lsp-haskell | Medium | Yes | Readers already living in Emacs |
| 4. Terminal only (any editor + ghci) | None beyond GHC itself | No | Anyone wanting the simplest, most robust path; matches the book's original workflow |

**Recommend VS Code with the `haskell.haskell` extension as the default
suggestion for students**, for the reasons above (free, cross-platform, low
setup effort, and it's the same tool whether a reader chose a local GHCup
install or the zero-install Codespaces/devcontainer path from the companion
report). **Mention Option 4 (terminal-only) explicitly** alongside it, both
as the simplest possible starting point and as the reliable fallback if a
reader hits any HLS setup friction — the book's exercises and examples
remain fully usable without any editor tooling at all. Options 2 and 3
are worth a one-line mention for readers who already have a strong existing
editor preference, but shouldn't be the lead recommendation for newcomers.
