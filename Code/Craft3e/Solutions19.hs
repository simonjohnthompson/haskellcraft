------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
--
--  Solutions19
--
------------------------------------------------------------------------------

module Solutions19 where

import Chapter19 hiding (lookup)
import Prelude hiding (lookup)
import Control.Monad (liftM, ap)

--
-- Solution 19.4
--

-- Ok, here's the solution to the getLines exercise from the previous
-- chapter, but using >>= instead of the do notation ...

getLines' :: IO String

getLines'
  = getLine >>= \ line ->
    if last line /= '\\'
       then return line
       else getLines' >>= \ lines ->
            return (init line ++ lines)

--
-- Solution 19.5
--

-- Doesn't quite work as mapSet needs an instance of
-- Ord b for b the range type.

--instance Monad Set where
--  return a = sing a
--  x >>= f  = setUnion (mapSet f x)

-- Similar issues for binary trees too.

-- For the error type need to

--
-- Solution 19.6
--

-- Id is obviouos if look at the Kleisli form.
-- Lists: f>@>g is concat . map g . f

{-
compos f g = concat . map g . f

compos (\x -> [x]) g
  = concat . \x -> [g x]
  = \x -> g x
  = g

compos f (\x -> [x])
  = concat . \x -> [x] . g
  = \x -> x . g
  = g

-- associativity is similar.

-}
--
-- Solution 19.7
--

{-
fmap (f.g) m
  = do x <- m
       return (f(g x))

fmap f (fmap g m)
  = do y <- fmap g m       -- by definition of fmap f
       return (f y)
  = do x <- m              -- by definition of fmap g
       y <- return (g x)
       return (f y)
  = do x <- m              -- by M1 in do notation
       return (f (g x))
-}

--
-- Solution 19.8
--

-- Similar to 19.7

--
-- Solution 19.9
--

-- Idea: just keep at most one element in the list.

newtype Mlist a = Mlist {mlist::[a]}

instance Monad Mlist where
  return x  = Mlist [x]
  m >>= f   = if nil (mlist m)
                       then Mlist []
                       else Mlist (take 1 (mlist (f (head (mlist m)))))

instance Applicative Mlist where
  pure = return
  (<*>) = ap

instance Functor Mlist where
  fmap = liftM

nil :: [a] -> Bool
nil [] = True
nil _  = False

--
-- Solution 19.10
--

mapLists f m = [ f x | x<-m ]

joinLists m  = [ y | x<-m, y<-x ]

--
-- Solution 19.11
--

-- gives more clarity in the definition than hiding the
-- construction of the result in the funciotn passed to build

--
-- Solution 19.12
--

-- fmapPair f (x,y) = (f x, f y) etc.

--
-- Solution 19.13
--

-- top-level function. Start with an empty table.

nTree :: Eq a => Tree a -> Tree Integer

nTree tree = fst (nAux tree [])

-- auxiliary function that does the work

nAux :: Eq a => Tree a -> Table a -> (Tree Integer,Table a)

nAux Nil tab = (Nil,tab)

nAux (Node x t1 t2) tab
  = (Node n i1 i2,tab3)
    where
    (tab1, n) = nNode x tab
    (i1,tab2) = nAux t1 tab1
    (i2,tab3) = nAux t2 tab2

egTree :: Tree String

egTree = (Node "Moon" (Node "Ahmet" Nil Nil) (Node "Dweezil" (Node "Ahmet" Nil Nil) (Node "Moon" Nil Nil)))

--
-- Solution 19.14
--

lookup :: Eq a => a -> Table a -> Int

lookup x tab = look x tab 0

look :: Eq a => a -> Table a -> Int -> Int

look x [] n = (n+1)
look x (y:ys) n
  | x==y        = n
  | otherwise   = look x ys (n+1)

--
-- Solution 19.15
--

-- just modify the operation of numberNode to return a
-- random value rather than a lookup in a table.


--
-- Solution 19.16
--

-- Exceptions: can use the maybe monad: would need to change the
-- definition of eval to handle this.

-- Can use the State monad to collect information about the number of
-- steps in a calculation.
