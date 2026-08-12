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
per-chapter modules) once a reader has *some* way to run GHC/GHCi. This
report is about the layer underneath that: how they get GHC/GHCi in the
first place.

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
repository, built on the official `haskell:9.6` image (Option B) — the same
GHC line the code was verified against for
`Admin/CODE-COMPATIBILITY-REPORT.md`. It runs `cabal update && cabal build`
inside `Code/Craft3e` on first create, so the container is ready for
`cabal repl` as soon as it finishes. A reader:

- **GitHub Codespaces**: on the repo's GitHub page, "Code" → "Codespaces" →
  "Create codespace on main". Lands in a browser-based VS Code with GHC,
  cabal, and the `Craft3e` package already built. GitHub gives every
  personal account a free monthly quota of Codespaces hours.
- **Gitpod**: reads the same `devcontainer.json`; open via a
  `gitpod.io/#<repo-url>` link.
- **VS Code locally, no Haskell install at all**: with Docker and the "Dev
  Containers" extension, "Reopen in Container" on the cloned repo uses the
  same config.

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
extension would.) Still worth a first real run through an actual GitHub
Codespace before pointing readers at it, to confirm the browser-based VS
Code experience itself, but the underlying environment is confirmed
working.

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
| C. Codespaces / Gitpod | None | Yes, fully | Done — `.devcontainer/` added, smoke-tested via Docker |
| D. play.haskell.org / similar | None | No — single file, uncertain packages | None |
| E. GHC-in-browser (Wasm) | None | Not yet — no external packages | None today; future potential |
| F. IHaskell + Binder | None | Yes, but slow cold start | Larger: maintain notebook build |

**Recommend leading with Option A (GHCup)** in the book's own setup
instructions, exactly as today, since it's what the rest of this project's
tooling (and the companion compatibility report) already assumes and tests
against. **Mention Option B (Docker)** as a one-line alternative for readers
who'd rather not touch their system Haskell install at all. **Option C (a
Codespaces/Gitpod devcontainer) is now available and smoke-tested** in this
repository as the "try the real thing with nothing installed" path — it's
the only zero-install option that isn't crippled by missing packages or
single-file limits. Do **not** send readers to `tryhaskell.org`
(defunct); if a bare "try one line right now" link is wanted anywhere in
the front matter or on the website, `play.haskell.org` is the current
legitimate option, clearly scoped to short standalone snippets only.
