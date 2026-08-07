{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module PackageInfo_Craft3e (
    name,
    version,
    synopsis,
    copyright,
    homepage,
  ) where

import Data.Version (Version(..))
import Prelude

name :: String
name = "Craft3e"
version :: Version
version = Version [0,2,0,2] []

synopsis :: String
synopsis = "Code for Haskell: the Craft of Functional Programming, 3rd ed."
copyright :: String
copyright = "(c) Addison Wesley"
homepage :: String
homepage = "http://www.haskellcraft.com/"
