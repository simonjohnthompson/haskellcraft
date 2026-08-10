Haskell practicalities {#OtherHS}
======================

<a id="ix-otherHs-haskell-implementations"></a>

<a id="ix-otherHs-haskell-platform"></a>

It's not difficult to get going using Haskell, and most of the relevant information is easily accessible from the `haskell.org` page. This appendix points you in the right direction.

### Implementations {#implementations .unnumbered}

Implementations of Haskell have been built at various sites around the world. This text uses GHCi, an interactive front-end to the Glasgow Haskell Compiler (GHC). GHCi provides much of the functionality of the Hugs interpreter, which was developed in a joint effort by staff at the Universities of Nottingham in the UK and Yale in the USA. The first compilers for Haskell were developed at the University of Glasgow, UK, and Chalmers Technical University, Göteborg, Sweden. More recent developments have taken place elsewhere, including at York and Utrecht. An up-to-date list of implementations and their status can be found at

```haskell
http://www.haskell.org/haskellwiki/Implementations
```

In this book we have used the **Haskell Platform** as our foundation. This is documented at

```haskell
http://hackage.haskell.org/platform/
```

from where it can also be downloaded. Installation instructions for Windows, Mac OS X and Linux are listed on the relevant downloads page.

### Getting the Craft3e code {#getting-the-craft3e-code .unnumbered}

The modules for this text are available as a package on Hackage: full details on how to download are available at the homepage for the book:

```haskell
www.haskellcraft.com
```

### Using GHCi {#using-ghci .unnumbered}

<a id="ix-otherHs-ghci-documentation"></a>

An overview of the main commands of GHCi can be found in [Principal GHCi commands](2.md#commands), and full details of other aspects of GHCi are in the online documentation for GHC.

### Editors for Haskell {#editors-for-haskell .unnumbered}

<a id="ix-otherHs-editors-for-haskell"></a>

While there is no preferred editor for Haskell, emacs is probably the best loved and most used. To tune emacs to work with Haskell, it's good to use the Haskell mode, which is documented extensively at

```haskell
http://www.haskell.org/haskellwiki/Haskell_mode_for_Emacs
```

Not everyone gets on with emacs, and vim is an alternative for many, with its mode available from

```haskell
http://projects.haskell.org/haskellmode-vim/
```

Other editors include Yi, a text editor written in Haskell and extensible in Haskell.

```haskell
http://www.haskell.org/haskellwiki/Yi
```

and an overview of all those available is at

```haskell
http://www.haskell.org/haskellwiki/Editors
```
