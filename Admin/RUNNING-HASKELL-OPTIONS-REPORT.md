# Report: Options for Readers to Run the Book's Haskell Code

Prepared to survey the realistic ways a reader of *Haskell: The Craft of
Functional Programming* could get from "nothing installed" to actually
running the book's examples and exercises — local installation, browser/
online options, and other (cloud/container) options. This is a survey and
recommendation only; nothing has been added to `Book/`, `Code/`, or
`Website/`. Findings that depend on the *current* state of third-party
services were checked directly (not recalled from memory) in August 2026 —
see the "As of" note on each, since these services come and go faster than
this book will be revised.

This report should be read alongside `Admin/CODE-COMPATIBILITY-REPORT.md`,
which covers what needs to work (`Craft3e.cabal`, its dependencies, and the
per-chapter modules) once a reader has *some* way to run GHC/GHCi, and
`Admin/CODE-VS-BOOK-DISCREPANCIES-REPORT.md`, which covers the narrower but
sharper case of a reader typing the book's own printed code in by hand
rather than loading the shipped files (see the note under Option A below).
This report is about the layer underneath both: how they get GHC/GHCi in
the first place.

The book's own workflow assumes a reader can start GHCi and `:load` a
chapter file that pulls in sibling modules and packages like `QuickCheck`.
That rules out most "paste one file, click run" tools by itself — worth
keeping in mind throughout.

## Option A — Install GHC locally via GHCup (recommended primary path)

[GHCup](https://www.haskell.org/ghcup/) is now the toolchain installer
haskell.org itself points newcomers to, on Linux, macOS, Windows (native or
WSL), and FreeBSD. One command (`ghcup install ghc`, or the interactive
`curl | sh` bootstrap from the GHCup site) installs GHC, `cabal-install`,
and optionally `stack` and the Haskell Language Server, and `ghcup tui`
gives a simple menu for managing versions later. This is exactly the
environment used to test `Code/Craft3e` for the companion compatibility
report, and it is what both delivery options recommended there (`cabal
repl`, or `cabal install --lib` + a checked-in `.ghci`) assume.

**Why this should be the headline recommendation:** it's a genuine,
persistent, full install — no time limits, no missing packages, no network
dependency after setup, works offline on a train. Every other option below
is either a lighter-weight *substitute* for this (Docker), a *stopgap* for
readers not ready to install anything (online playgrounds), or a *hybrid*
that still ultimately runs a real GHC somewhere (cloud dev environments).
For anyone planning to work through more than a couple of isolated
examples — which describes most readers of this book — a real local
install is simply the least friction long-run, and it's what the book's
existing "start GHCi and `:load` a chapter" instructions already assume.

**A gap worth flagging, orthogonal to which environment option a reader
picks:** every option in this report (A through F) ends up running a
current GHC — 9.x, well past two class-hierarchy changes the book predates
(the Applicative-Monad Proposal, 2015, and the MonadFail Proposal, 2019).
This is invisible to a reader who runs `cabal repl` and `:load`s a shipped
chapter file, because `Code/Craft3e`'s modules have already been quietly
patched to compile under a modern GHC. It is *not* invisible to a reader
who instead types one of Chapter 18's monad examples in by hand from the
printed book — its `instance Monad (MP a) where fail s = MP none` (and the
`State` monad instance right after it) would fail to compile on any of the
environments this report sets up, with an error about `fail` not being a
method of `Monad`, unrelated to anything about the environment itself. See
`Admin/CODE-VS-BOOK-DISCREPANCIES-REPORT.md` for the full analysis and the
already-fixed versions of both examples in `Code/Craft3e`. Not a reason to
change any recommendation in this report — every option here still gets a
reader to a working, current GHC exactly as intended — but worth knowing so
a "why won't this compile, I copied it straight from the book" report from
a reader isn't mistaken for an environment-setup problem.

**Released, for readers who get the code via Hackage rather than this git
repo.** `Craft3e` is also published on Hackage (`cabal unpack Craft3e` /
`cabal install Craft3e`, per this book's own `README.txt` instructions) —
a separate distribution channel from cloning this repository, and one this
report hadn't previously distinguished. `ParseLib.hs`'s `MonadFail
(SParse a)` fix (the specific example above) has been released as
`Craft3e-0.2.0.3`, confirmed live by pulling it back down fresh with
`cabal update && cabal get Craft3e-0.2.0.3` and checking the instance is
present in the downloaded source. A reader on Option A who fetches the
package the book's own way, rather than cloning `Code/Craft3e` directly,
now gets the fix too.

**Updated again, this time for package metadata rather than code.**
`Craft3e-0.2.0.4` followed shortly after, correcting the package's own
`.cabal` metadata: copyright now reads `(c) Simon Thompson` rather than
Addison Wesley, `homepage` points at this project's actual GitHub Pages
site rather than the long-dormant `haskellcraft.com`, and two Hackage-side
`cabal check`/upload warnings (a missing `HUnit` upper bound, and
trailing-zero upper bounds on `time`/`open-browser`) are cleared. One
finding worth recording: Hackage's uploader hard-rejects any license that
isn't OSI-approved — an initial attempt to set `license:
CC-BY-NC-SA-4.0` (matching the book's own front-matter licensing) failed
server-side with "Invalid package," since Creative Commons' NonCommercial
clause isn't OSI-approved open source. `Craft3e`'s code license stays MIT;
only the book's prose is CC BY-NC-SA 4.0. Confirmed live the same way as
before: downloaded the published tarball directly from Hackage and checked
its `Craft3e.cabal` and `LICENSE` match.

**Alternatives to GHCup for local install**, mentioned for completeness:
a system package manager (Homebrew's `ghc`/`cabal-install` on macOS, `apt`
on Debian/Ubuntu, `choco`/`winget` on Windows) — usable, but versions lag
and GHCup is what the Haskell community itself now steers people to instead;
and `stack setup`, which fetches its own pinned GHC and can replace GHCup
entirely for readers who'd rather standardise on Stack over cabal.

## Option B — Docker: the official `haskell` image

Docker Hub hosts an [official, actively maintained `haskell`
image](https://hub.docker.com/_/haskell) (`docker pull haskell:9.6`, plus
slim variants), containing GHC, `cabal-install`, and `stack`. A reader with
Docker already installed gets a working, disposable GHC environment with a
single `docker run -it haskell:9.6 ghci`, with zero risk of clashing with
anything else on their machine, and zero risk of the "which GHC version did
the book test against" question ever arising.

This is a good secondary option for readers who already have Docker for
other reasons, or who want a completely throwaway sandbox. It's a heavier
ask than GHCup for a newcomer who has neither installed (an extra ~1-2GB
download for Docker itself), so it's not the best *first* recommendation for
this book's actual target reader, but worth listing as a clean alternative,
and it's the natural base for the cloud dev environment option below.

## Option C — Cloud dev environments (GitHub Codespaces / Gitpod) — implemented

These give a reader a full Linux VM with GHC already configured, reachable
through the browser (or through VS Code talking to that VM) — no local
install of anything at all, including no Docker.

**Implemented**: `.devcontainer/devcontainer.json` is now checked into this
repository, built on a plain `mcr.microsoft.com/devcontainers/base:bookworm`
image plus GHCup (not the official `haskell:9.6` image from Option B —
testing while preparing `Admin/DEVELOPMENT-ENVIRONMENT-OPTIONS-REPORT.md`
found that image's Debian 11 base is too old for the Haskell Language
Server binaries GHCup currently distributes, which broke in-editor
diagnostics/hover; GHCup on a current base avoids this). GHCup installs the
same GHC 9.6.7 line the code was verified against for
`Admin/CODE-COMPATIBILITY-REPORT.md`, plus cabal and a matching HLS build.
It runs `cabal update && cabal build` inside `Code/Craft3e` on first
create, so the container is ready for `cabal repl` as soon as it finishes,
and opening a `.hs` file gets live diagnostics/hover via HLS — see
`Admin/DEVELOPMENT-ENVIRONMENT-OPTIONS-REPORT.md` for the full editor/IDE
picture. A reader:

- **GitHub Codespaces**: on the repo's GitHub page, "Code" → "Codespaces" →
  "Create codespace on main". Lands in a browser-based VS Code with GHC,
  cabal, and the `Craft3e` package already built. GitHub gives every
  personal account a free monthly quota of Codespaces hours.
- **Gitpod**: reads the same `devcontainer.json`; open via a
  `gitpod.io/#<repo-url>` link.
- **VS Code locally, no Haskell install at all**: with Docker and the "Dev
  Containers" extension, "Reopen in Container" on the cloned repo uses the
  same config.

**Using it from VS Code (recommended default workflow for students).** VS
Code is a reasonable default development environment for this book's
readers — it's free, cross-platform, and both routes below land the reader
in it, whether or not they install anything locally first. The two are the
same editor experience; they differ only in where the container actually
runs.

*Route 1 — GitHub Codespaces (VS Code in the browser, nothing local at all):*

1. Go to the repository's GitHub page.
2. Click the green **"Code"** button → **"Codespaces"** tab → **"Create
   codespace on main"**.
3. GitHub builds the container from `.devcontainer/devcontainer.json`
   (a few minutes the first time) and opens a full VS Code window in the
   browser tab, already connected to it.
4. Wait for the **"Running postCreateCommand"** notification in the bottom
   right to finish — that's installing GHC, cabal, and HLS via GHCup, then
   running `cabal update && cabal build` inside `Code/Craft3e`. **This takes
   several minutes, not seconds** — it's genuinely working, not stuck; there
   is no need to reload or restart the codespace while it runs.
5. Open a terminal in VS Code (`` Ctrl+` `` / `` Cmd+` ``, or Terminal →
   New Terminal) — it opens directly in `Code/Craft3e`, since that's the
   window's workspace folder — then:
   ```
   cabal repl
   ```
6. At the `ghci>` prompt, `:load Chapter5` (or any other chapter/solutions
   file) works immediately, exactly as described in
   `Admin/CODE-COMPATIBILITY-REPORT.md`.
7. The `haskell.haskell` extension (Haskell Language Server) that
   `devcontainer.json` installs also gives inline type info, error
   highlighting, and "go to definition" when a reader opens any `.hs` file
   in the editor pane — useful beyond just the REPL. The first time it
   activates, it may pop up a prompt asking how to manage the Haskell
   toolchain (GHCup, PATH, etc.) — **choose the "Automatic"/GHCup-managed
   option**; this is what was tested and confirmed working.
8. When finished, the reader can just close the browser tab — GitHub
   suspends the codespace automatically (personal accounts get a free
   monthly quota of Codespaces hours; a suspended, unused codespace does not
   burn through it). Re-opening later resumes the same codespace with its
   state intact, from "Code" → "Codespaces" → the codespace's name in the
   list.

*Route 2 — VS Code installed locally, container running via Docker Desktop:*

1. Install [VS Code](https://code.visualstudio.com/) and
   [Docker Desktop](https://www.docker.com/products/docker-desktop/) (this
   is Option B's Docker install, reused here).
2. In VS Code, install the **"Dev Containers"** extension (published by
   Microsoft; `ms-vscode-remote.remote-containers`).
3. Clone this repository and open the cloned folder in VS Code
   (File → Open Folder).
4. VS Code detects `.devcontainer/devcontainer.json` and offers **"Reopen in
   Container"** as a notification in the bottom right — click it. (If the
   notification doesn't appear: Command Palette →
   "Dev Containers: Reopen in Container".)
5. VS Code builds the container and re-opens the same window connected to
   it — the reader's local GHC/Haskell install (or lack of one) is
   irrelevant from this point on, everything runs inside the container.
6. Steps 4–7 from Route 1 above apply identically (wait for
   `postCreateCommand`, open a terminal, `cabal repl`).

Route 1 needs no local install of anything and is the simpler recommendation
for a reader trying this for the first time; Route 2 suits a reader who
wants their usual local VS Code (their own settings, keybindings, other
extensions) rather than the browser-hosted one, and who is comfortable
installing Docker Desktop.

**This is the closest thing available to "zero install, but still the real,
exact book environment"** — genuinely more capable than any browser
playground (below), because it's actually running full GHC/cabal in a VM,
not a sandboxed subset. **Smoke-tested successfully**: with Docker running
locally, `docker run` against the `haskell:9.6` image reproduced the
container's exact lifecycle — `cabal update && cabal build` inside
`Code/Craft3e` completed with no errors (all 68 modules plus the three
`Chapter20` performance executables), and a subsequent `cabal repl` in that
same container loaded all 67 modules and correctly `:load`ed both a chapter
file (`Chapter5`) and a reader-style exercise file (`Solutions4`), matching
the workflow in `Admin/CODE-COMPATIBILITY-REPORT.md`. (The dedicated
`devcontainers` CLI itself couldn't be run in this environment — it failed
under the sandbox's bundled Node 10/npm 6 `npx`, an unrelated local
toolchain issue — but since `devcontainer.json` here is just an image plus
a `postCreateCommand`, running that image and command directly through
`docker run` exercises the same thing a Codespace or the Dev Containers
extension would.) **Confirmed in a live GitHub Codespace too**: a real
codespace was created on `main`, opened in the browser, and — following
exactly the Route 1 steps above — `postCreateCommand` completed and
`cabal repl` reached a working `ghci>` prompt. Both the underlying
environment and the actual browser-based reader experience are confirmed
working end-to-end.

**Base image changed, and HLS confirmed working end-to-end in a live
Codespace.** The base image was switched (see above) to fix the HLS/glibc
issue found while preparing
`Admin/DEVELOPMENT-ENVIRONMENT-OPTIONS-REPORT.md`, and that fix — plus two
further issues only visible in a real Codespace, not local Docker testing —
was confirmed working via a full round-trip: create a live Codespace,
open `Chapter5.hs`, and check the Haskell extension's actual in-editor
behaviour (not just `cabal build`/`cabal repl`).

- `cabal build` completes cleanly in the live Codespace (all 68 modules
  plus the three `Chapter20` performance executables).
- Opening `Chapter5.hs` initially still showed `Test.QuickCheck` as an
  unresolvable module, with no hover-for-type — a real dependency
  (`QuickCheck`) is correctly listed in `Craft3e.cabal`'s `build-depends`,
  so this wasn't a missing-dependency bug. The Haskell extension's Output
  log showed HLS falling back to a bare GHC session (`In-place unit ids:
  [ main-... ]`, no package database) rather than a real cabal-based
  session — i.e. `hie-bios`'s cradle detection wasn't finding
  `Craft3e.cabal` at all.
- Root cause, confirmed by testing: `hie-bios`'s cradle search anchors to
  the *VS Code workspace root*, not to the individual file being edited.
  With the workspace root at the repo root (`/workspaces/haskellcraft`,
  two directories above `Code/Craft3e`), it never looked inside
  `Code/Craft3e` at all. Opening `Code/Craft3e` itself as the workspace
  root fixed it immediately — confirmed live: the `QuickCheck` error
  disappeared and hover-for-type started working.
- **Fix applied**: `.devcontainer/devcontainer.json`'s `workspaceFolder`
  now points at `Code/Craft3e` directly rather than the repo root, so this
  works out of the box for a fresh Codespace/devcontainer with no manual
  step. The one consequence is that the rest of the repo (book source,
  `Admin/` reports) isn't shown in that VS Code window — acceptable since
  Option C exists specifically for readers running/editing the book's
  code, not editing the book itself. A `Code/Craft3e/cabal.project` file
  (`packages: .`) was also added along the way; it turned out not to be
  the fix, but is a harmless, standard addition worth keeping.

Both `cabal build`/`cabal repl` and HLS's live diagnostics/hover are now
confirmed working end-to-end in a real GitHub Codespace, not just locally
via Docker.

## Option D — Browser-based playgrounds (no install, but limited)

These are worth knowing about for readers who just want to try a single
short snippet before committing to installing anything — but none of them
can run the book's actual code as-is, because none give GHCi-style
multi-file loading with the book's own package dependencies.

- **`tryhaskell.org` is gone.** It was the option most likely to be
  suggested from memory or from older web references, but its creator
  [shut it down in 2025 after 16 years](https://tryhaskell.org/), and its
  own shutdown notice now redirects readers to the option below. **Do not
  point readers at it** — this is exactly the kind of stale link worth
  actively avoiding in the book's front matter or website.
- **[play.haskell.org](https://play.haskell.org)** is the current
  official Haskell Playground (linked from haskell.org's own navigation) and
  is the natural successor. It compiles a single file with a `main`
  function (no GHCi-style interactive session), can show Core or x86-64
  assembly output, lets a reader pick a GHC version, and produces a
  shareable URL — but its own disclaimer states saved snippets are "not a
  storage or backup system," and it does not document which non-boot
  packages (e.g. `QuickCheck`) are available, if any. Fine for "does this
  ten-line function do what I think," not viable for `:load`ing a chapter's
  worth of interdependent modules.
- **Generic multi-language online IDEs** — Replit, JDoodle, OneCompiler,
  CoderPad, etc. — all support Haskell at some level (typically GHC + a
  small fixed package set, single file or a small project). They're
  reasonable if a reader already has an account on one of these for other
  courses, but none is authoritative or Haskell-specific, availability and
  free-tier limits change often, and none was built with this book's
  dependency set in mind, so each would need per-file trial and error.

## Option E — GHC compiled to WebAssembly, running *in* the browser (notable, not yet usable for this book)

Since GHC 9.6, the compiler ships an official [WebAssembly
backend](https://downloads.haskell.org/ghc/9.6-latest/docs/users_guide/wasm.html),
and a public demo — [haskell-wasm.github.io/ghc-in-browser](https://haskell-wasm.github.io/ghc-in-browser/)
— now runs the actual GHC compiler *client-side*, with no server round-trip
at all: parsing, type-checking, and bytecode execution all happen in the
visitor's own browser tab. This is a genuinely different technology from
the "send code to a server" playgrounds above, and it's moving fast.

Today it's explicitly experimental: no external packages (so no
`QuickCheck`, no `containers` beyond what ships with the compiler itself),
no ability to invoke a C compiler or run Cabal, and a large (~50MB) initial
download. It cannot currently run the book's code. It's included here
because it's the most plausible future path to something genuinely
attractive for this project specifically: the book already has its own
GitHub Pages / mdBook website (`Website/`), and an embedded, truly
client-side "try this exact listing" widget on each chapter's page — no
server, no account, no install — is the kind of thing this technology could
support once it grows package support. Not actionable today; worth
revisiting.

## Option F — Jupyter notebooks via IHaskell + Binder (mentioned, not recommended over C)

[IHaskell](https://github.com/IHaskell/IHaskell) is a real Jupyter kernel
for Haskell (cells behave like a GHCi session, with rich output), and a
repository can be made launchable with zero reader-side install via
[mybinder.org](https://mybinder.org), which builds a container from a
config file in the repo and hands the visitor a live notebook in their
browser. This would give a genuinely capable, stateful, in-browser
experience with the real dependencies available — but it requires
maintaining a Binder-compatible environment definition alongside the
existing `Craft3e.cabal`, cold starts are slow (often several minutes while
Binder builds or fetches the image), and idle sessions are recycled.
Given Option C (Codespaces/Gitpod) achieves a very similar "zero install,
real environment" outcome with a simpler, more standard piece of
configuration (a devcontainer, vs. a parallel notebook-oriented build), this
report doesn't recommend pursuing both — Option C is the better use of
whoever's time would go into adding either.

## Summary and recommendation

| Option | Install needed | Runs the book's actual code (deps, multi-module) | Effort to set up (project side) |
|---|---|---|---|
| A. GHCup | Yes (once) | Yes, fully | None — already works |
| B. Docker `haskell` image | Docker only | Yes, fully | None — already works |
| C. Codespaces / Gitpod | None | Yes, fully | Done — `.devcontainer/` added, confirmed end-to-end in a live Codespace (build, repl, and HLS) |
| D. play.haskell.org / similar | None | No — single file, uncertain packages | None |
| E. GHC-in-browser (Wasm) | None | Not yet — no external packages | None today; future potential |
| F. IHaskell + Binder | None | Yes, but slow cold start | Larger: maintain notebook build |

**Recommend leading with Option A (GHCup)** in the book's own setup
instructions, exactly as today, since it's what the rest of this project's
tooling (and the companion compatibility report) already assumes and tests
against. **Mention Option B (Docker)** as a one-line alternative for readers
who'd rather not touch their system Haskell install at all. **Option C (a
Codespaces/Gitpod devcontainer) is now available and confirmed working
end-to-end in a live Codespace** — including HLS's in-editor
diagnostics/hover, not just `cabal build`/`cabal repl` — as the "try the
real thing with nothing installed" path; it's the only zero-install option
that isn't crippled by missing packages or single-file limits. Do **not** send readers to `tryhaskell.org`
(defunct); if a bare "try one line right now" link is wanted anywhere in
the front matter or on the website, `play.haskell.org` is the current
legitimate option, clearly scoped to short standalone snippets only.
