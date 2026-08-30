------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions18
--
------------------------------------------------------------------------------

module Solutions18 where

import Chapter18 hiding (sumInts,lookup)
import Prelude hiding (lookup,repeat,sequence)
import System.IO 
import Control.Monad.Identity hiding (sequence)
import Chapter8 (getInt)
import Data.Time
import System.Locale
import System.IO.Unsafe (unsafePerformIO)
import Control.Monad (liftM, ap)
import SolutionsSet

--
-- Solution 18.1
--

-- The version here will give rise o whole lot of nested calls, one for 
-- each non-zero integer, and so the implementation will have to store all
-- those and then unwind them (storage on the stack).

-- By contrast, the first solution presented is "tail recursive", so that 
-- we only have one active call at a time - effectively the active call
-- jumps to sumInts (m+n) as its last action: it never needs to return a 
-- result.

--
-- Solution 18.2
--

fmap :: (a -> b) -> IO a -> IO b

fmap f m
  = do x <- m
       return (f x)

--
-- Solution 18.3
--

repeat :: IO Bool -> IO () -> IO ()

repeat test m
  = do res <- test
       if res 
          then return ()
          else do m
                  repeat test m

--
-- Solution 18.4
--

whileG :: (a -> IO Bool) -> (a -> IO a) -> (a -> IO a)

whileG cond op x
  = do test <- cond x
       if test
          then do op x
                  whileG cond op x
          else return x

--
-- Solution 18.5
--

findAvg :: IO Integer

findAvg 
  = do n <- getInt
       s <- sumInts n 0
       return (s `div` n)

sumInts :: Integer -> Integer -> IO Integer

sumInts n s 
  = if n>0 
       then do m <- getInt
               sumInts (n-1) (s+m)
       else return s     

--
-- Solution 18.6
--

-- Should first loook at Section 18.2.

--
-- Solution 18.7
--

accumulate :: [IO a] -> IO [a]

accumulate [] = return []

accumulate (a:as)
  = do x<-a     
       xs<- accumulate as
       return (x:xs)

sequence :: [IO a] -> IO ()

sequence [] = return ()

sequence (a:as)
  = do a
       sequence as
       return ()

--
-- Solution 18.8
--

sumIntsFile :: FilePath -> IO Integer

sumIntsFile path
  = do contents <- readFile path
       let nums = (map read (lines contents)) :: [Integer]
       let nonZero = takeWhile (/=0) nums
       return (sum nonZero)

--
-- Solution 18.9
--

sumIntsInteract :: String -> String

sumIntsInteract input
  = show (sum (takeWhile (/=0) (map read (lines input)))) ++ "\n"      

--
-- Solution 18.10
--

-- Follows the pattern of 18.9.

--
-- Solution 18.11
--

-- Will have to take values from the strategies within a do block.
-- and handle them within that same block.

--
-- Solution 18.12
--

-- Add two lines to the do block of mainCalc before and after calcSteps.

--
-- Solution 18.13: see 17.17
--

--
-- Solution 18.14: see 17.16
--

--
-- Solution 18.15
--

-- Need to modify the body of calcStep so as to read multiple lines
-- Do this by writing function to read lines until the line not ended 
-- by the continuation character, and return the concatenation of the lines 
-- with continuation removed:

getLines :: IO String

getLines 
  = do line <- getLine
       if last line /= '\\'
          then return line
          else do lines <- getLines
                  return (init line ++ lines)
 
--
-- Solution 18.16: see 17.18
--

--
-- Solution 18.17
--

-- Ok, here's the solution to 18.15 ...

getLines' :: IO String

getLines'
  = getLine >>= \ line ->
    if last line /= '\\'
       then return line
       else getLines' >>= \ lines ->
            return (init line ++ lines)

--
-- Solution 18.18
--

-- Doesn't quite work as mapSet needs an instance of
-- Ord b for b the range type.

--instance Monad Set where
--  return a = sing a
--  x >>= f  = setUnion (mapSet f x)

-- Similar issues for binary trees too.

-- For the error type need to  

--
-- Solution 18.19
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
-- Solution 18.20
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
-- Solution 18.21
--

-- Similar to 18.20

--
-- Solution 18.22
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
-- Solution 18.23
--

mapLists f m = [ f x | x<-m ]

joinLists m  = [ y | x<-m, y<-x ] 

--
-- Solution 18.24
--

-- gives more clarity in the definition than hiding the 
-- construction of the result in the funciotn passed to build

--
-- Solution 18.25
--

-- fmapPair f (x,y) = (f x, f y) etc.

--
-- Solution 18.26
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
-- Solution 18.27
--

lookup :: Eq a => a -> Table a -> Int

lookup x tab = look x tab 0

look :: Eq a => a -> Table a -> Int -> Int

look x [] n = (n+1)
look x (y:ys) n
  | x==y        = n
  | otherwise   = look x ys (n+1)

--
-- Solution 18.28
--

-- just modify the operation of numberNode to return a 
-- random value rather than a lookup in a table.


--
-- Solution 18.29
--

-- Exceptions: can use the maybe monad: would need to change the
-- definition of eval to handle this.

-- Can use the State monad to collect information about the number of 
-- steps in a calculation.