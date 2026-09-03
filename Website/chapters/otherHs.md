Haskell practicalities {#OtherHS}
======================

<a id="ix-otherHs-haskell-implementations"></a>

<a id="ix-otherHs-haskell-platform"></a>

[Getting started with Haskell programming](2.md#getStart) covered the recommended way to get going with Haskell: installing GHC, `cabal` and the Haskell Language Server using GHCup, and then obtaining the code for this book from either Hackage or GitHub. This appendix covers the alternatives: other ways to install Haskell locally, and -- often more useful for a reader who just wants to try something out first -- several ways of running Haskell *without* installing anything at all.

### Installing Haskell locally {#installing-haskell-locally .unnumbered}

<a id="ix-otherHs-ghcup"></a>

GHCup, <https://www.haskell.org/ghcup/>, described in [Getting started with Haskell programming](2.md#getStart), is the toolchain installer that `haskell.org` itself recommends, and remains the best starting point on Linux, macOS and Windows (native or under WSL). A system package manager -- Homebrew's `ghc` and `cabal-install` on macOS, `apt` on Debian/Ubuntu, Chocolatey on Windows -- can also install a Haskell toolchain, but the versions provided are often out of date, so GHCup remains the better default. Readers who prefer the Stack build tool to Cabal can instead run `stack setup`<a id="ix-otherHs-stack"></a>, which fetches and manages its own GHC.

Readers who would rather not install anything directly onto their own machine, but who already have Docker<a id="ix-otherHs-docker"></a> installed for other reasons, can use the official Haskell Docker image instead:

```haskell
docker run -it haskell:9.6 ghci
```

This gives a disposable GHC, `cabal` and Stack installation inside a container, with no risk of it clashing with anything else already on the machine.

### Running Haskell with nothing installed {#running-haskell-with-nothing-installed .unnumbered}

<a id="ix-otherHs-codespaces"></a>

<a id="ix-otherHs-gitpod"></a>

For a reader who wants to try the book's actual code -- including its multi-module structure and dependencies such as `QuickCheck` -- without installing anything, the best option is a cloud development environment. This book's GitHub repository includes a *dev container* configuration which builds a ready-to-use GHC, `cabal` and HLS environment with the code for the book already built. It can be used in a few ways:

-   **GitHub Codespaces**: on the repository's GitHub page, <https://github.com/simonjohnthompson/haskellcraft>, click **Code**, then the **Codespaces** tab, then **Create codespace on main**. This opens a full, browser-based copy of VS Code, already connected to a virtual machine with Haskell installed; GitHub gives every personal account a free monthly quota of Codespaces hours.

-   **Gitpod** reads the same configuration file, and can be used by visiting <https://gitpod.io/#https://github.com/simonjohnthompson/haskellcraft>.

-   With Docker and VS Code's **Dev Containers** extension installed locally, opening a clone of the repository and choosing **Reopen in Container** uses the same configuration, without needing either service above.

In each case, once the container has finished building -- the first time takes a few minutes, so watch for the "Running postCreateCommand" notification to complete -- opening a terminal and typing `cabal repl` gives a working `ghci` prompt with all of the book's code and dependencies available, exactly as described in [Working with multiple-module projects](2.md#multipleModuleProgs); opening a `.hs` file gives the usual IDE features through HLS.

For trying out a single short expression or function, rather than the book's code as a whole, an online **playground**<a id="ix-otherHs-playground"></a> may be quicker still. The current, officially maintained one is <https://play.haskell.org>; it compiles a single file containing a `main` function and produces a shareable link, but does not support GHCi-style interaction or the book's package dependencies. (An older, once widely-recommended site, `tryhaskell.org`, closed in 2025 after sixteen years of service; if you see it mentioned elsewhere, use `play.haskell.org` instead.) A number of general-purpose online IDEs -- Replit, JDoodle, OneCompiler and others -- also support Haskell to varying degrees, and may be convenient if you already use one of these for other purposes, though none is Haskell-specific.

Two further approaches are worth knowing about, though neither is yet a good fit for this book. Since version 9.6, GHC has had an experimental WebAssembly backend, and a public demonstration, <https://haskell-wasm.github.io/ghc-in-browser/>, runs GHC itself inside the browser tab with no server involved at all; today, though, it supports no external packages and so cannot build the book's code. Jupyter notebooks can also be used for Haskell via the **IHaskell**<a id="ix-otherHs-ihaskell"></a> kernel, and a repository can be made launchable with no installation using <https://mybinder.org>; this gives a capable, genuine environment, but with a much slower start-up than the dev container described above, so it isn't needed here.

### Getting the `Craft3e` code {#getting-the-craft3e-code .unnumbered}

<a id="ix-otherHs-downloading-support-materials"></a>

[Working with multiple-module projects](2.md#multipleModuleProgs) describes in detail how to obtain and build the code for this book, either from Hackage using `cabal unpack Craft3e`, or by cloning the book's GitHub repository, <https://github.com/simonjohnthompson/haskellcraft>.

### Using GHCi {#using-ghci .unnumbered}

<a id="ix-otherHs-ghci-documentation"></a>

An overview of the main commands of GHCi can be found in [Principal GHCi commands](2.md#commands), and full details of other aspects of GHCi are in the online documentation for GHC.

### Editors and IDEs for Haskell {#editors-and-ides-for-haskell .unnumbered}

<a id="ix-otherHs-editors-for-haskell"></a>

As discussed in [Getting started with Haskell programming](2.md#getStart), Visual Studio Code together with the Haskell Language Server (HLS) is a good default choice: it is free, cross-platform, and provides type checking, refactoring and other IDE features once the `haskell.haskell` extension is installed. Several other editors have long-standing Haskell support, and remain popular with readers who prefer a terminal-based workflow: emacs, via its Haskell mode, <https://github.com/haskell/haskell-mode>; and vim, via <https://github.com/neovimhaskell/haskell-vim>. An overview of editor support more generally can be found at

```haskell
https://wiki.haskell.org/Editors
```
