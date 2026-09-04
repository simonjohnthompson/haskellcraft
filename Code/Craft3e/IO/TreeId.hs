--------------------------------------------------------------------------
--                                                                      --
--   Tree and the identity monad.                                   --
--                                                                      --
--  (c) Addison-Wesley, 1996-2010.                  --
--                                                                      --
--------------------------------------------------------------------------

module TreeId where

import Prelude
import Control.Monad (liftM, ap)

--------------------------------------------------------------------------
--       Type of trees                          --
--------------------------------------------------------------------------

data Tree t = Nil | Node t (Tree t) (Tree t) 
              deriving (Eq, Show)

--------------------------------------------------------------------------
--       A direct computation of the sum of a tree.         --
--------------------------------------------------------------------------

sTree :: Tree Int -> Int

sTree Nil = 0

sTree (Node n t1 t2) = n + sTree t1 + sTree t2

--------------------------------------------------------------------------
--       A monadic computation of the sum of a tree.            --
--------------------------------------------------------------------------

sumTree :: Tree Int -> Id Int

sumTree Nil = return 0

sumTree (Node n t1 t2)
  = do num <- return n
       s1  <- sumTree t1
       s2  <- sumTree t2
       return (num + s1 + s2)

--------------------------------------------------------------------------
--   The monad in question -- the identity monad            --
--------------------------------------------------------------------------

data Id t = Id t 
            deriving (Eq, Ord, Show, Read)

instance Monad Id where
  return         = Id
  (>>=) (Id x) f = f x

instance Applicative Id where
  pure = return
  (<*>) = ap

instance Functor Id where
  fmap = liftM

extract :: Id t -> t
extract (Id x) = x

