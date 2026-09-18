-----------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Simon Thompson, 1996-2011.
--
--  Chapter 18
--
-----------------------------------------------------------------------


module Chapter18 where

import Prelude hiding (lookup)
import System.IO
import Chapter8 (getInt)
import Data.Time
import System.Locale hiding (defaultTimeLocale)
import System.IO.Unsafe (unsafePerformIO)

-- I/O programming
-- ^^^^^^^^^^^^^^^


-- The basics of input/output
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^

-- Reading input is done by getLine and getChar: see Prelude for details.

--  getLine :: IO String
--  getChar :: IO Char

-- Text strings are written using
--
--  putStr :: String -> IO ()
--  putStrLn :: String -> IO ()

-- A hello, world program

helloWorld :: IO ()
helloWorld = putStr "Hello, World!"

-- Simple examples

readWrite :: IO ()

readWrite =
    do
      getLine
      putStrLn "one line read"

readEcho :: IO ()

readEcho =
    do
      line <-getLine
      putStrLn ("line read: " ++ line)


-- Adding a sequence of integers from the input

sumInts :: Integer -> IO Integer

sumInts s
  = do n <- getInt
       if n==0
          then return s
          else sumInts (s+n)

-- Adding a list of integers, using an accumulator

sumAcc :: Integer -> [Integer] -> Integer

sumAcc s [] = s
sumAcc s (n:ns)
  = if n==0
       then s
       else sumAcc (s+n) ns


-- Addiing a sequence of integers, courteously.

sumInteract :: IO ()
sumInteract
  = do putStrLn "Enter integers one per line"
       putStrLn "These will be summed until zero is entered"
       sum <- sumInts 0
       putStr "The sum is "
       print sum


-- Further I/O
-- ^^^^^^^^^^^

-- Interaction at the terminal

copyInteract :: IO ()

copyInteract =
    do
      hSetBuffering stdin LineBuffering
      copyEOF
      hSetBuffering stdin NoBuffering

copyEOF :: IO ()

copyEOF =
    do
      eof <- isEOF
      if eof
        then return ()
        else do line <- getLine
                putStrLn line
                copyEOF

-- Input and output as lazy lists

-- Reverse all the lines in the input.

listIOprog :: String -> String

listIOprog = unlines . map reverse . lines


-- Generating random numbers

randomInt :: Integer -> IO Integer
randomInt n =
    do
      time <- getCurrentTime
      return ( (`rem` n) $ read $ take 6 $ formatTime defaultTimeLocale "%q" time)

randInt :: Integer -> Integer
randInt = unsafePerformIO . randomInt


-- The calculator
-- ^^^^^^^^^^^^^^

-- This is available separately in the Calculator directory.
