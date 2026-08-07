module Paths_Craft3e (
    version,
    getBinDir, getLibDir, getDataDir, getLibexecDir,
    getDataFileName
  ) where

import Data.Version (Version(..))
import System.Environment (getEnv)

version :: Version
version = Version {versionBranch = [0,1,0,3], versionTags = []}

bindir, libdir, datadir, libexecdir :: FilePath

bindir     = "/Users/simonthompson/.cabal/bin"
libdir     = "/Users/simonthompson/.cabal/lib/Craft3e-0.1.0.3/ghc-6.12.3"
datadir    = "/Users/simonthompson/.cabal/share/Craft3e-0.1.0.3"
libexecdir = "/Users/simonthompson/.cabal/libexec"

getBinDir, getLibDir, getDataDir, getLibexecDir :: IO FilePath
getBinDir = catch (getEnv "Craft3e_bindir") (\_ -> return bindir)
getLibDir = catch (getEnv "Craft3e_libdir") (\_ -> return libdir)
getDataDir = catch (getEnv "Craft3e_datadir") (\_ -> return datadir)
getLibexecDir = catch (getEnv "Craft3e_libexecdir") (\_ -> return libexecdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
