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

import Chapter18 hiding (sumInts)
import Prelude hiding (repeat,sequence)
import System.IO
import Chapter8 (getInt)

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
