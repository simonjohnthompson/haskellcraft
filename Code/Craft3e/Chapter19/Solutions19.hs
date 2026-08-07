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

import RegExp 
import ParseLib
import Data.Char (isLower)
import Test.QuickCheck
import QC
import QCfuns

--
-- Solution 19.1
--

interp :: RE -> RegExp

interp Eps         = epsilon
interp (Ch ch)     = char ch
interp (e1 :|: e2) = interp e1 ||| interp e2
interp (e1 :*: e2) = interp e1 <*> interp e2
interp (St e)      = star (interp e)
interp (Plus e)    = i <*> star i
                     where
                     i = interp e

--
-- Solution 19.2
--

-- First pretty printing, which shows the grammar used.
-- 'e' is the syntax for epsilon, here.

prettyRE :: RE -> String

prettyRE Eps         = "e"
prettyRE (Ch ch)     = [ch]
prettyRE (e1 :|: e2) = "("++ prettyRE e1 ++"|"++ prettyRE e2 ++ ")"
prettyRE (e1 :*: e2) = "("++ prettyRE e1 ++ prettyRE e2 ++ ")"
prettyRE (St e)      = "("++ prettyRE e ++ ")*"
prettyRE (Plus e)    = "("++ prettyRE e ++ ")+"

-- Little parsers

epsP, charP :: Parse Char RE

epsP = spot (=='e') `build` const Eps

charP = spot isLowerNoE `build` Ch

isLowerNoE ch = isLower ch && ch/='e'

altP :: Parse Char RE -> Parse Char RE -> Parse Char RE

altP p1 p2
  = (spot (=='(') >*>
     p1 >*>
     spot (=='|') >*>
     p2 >*>
     spot (==')'))
    `build`
    \ (_,(e1,(_,(e2,_)))) -> e1 :|: e2

seqP :: Parse Char RE -> Parse Char RE -> Parse Char RE

seqP p1 p2
  = (spot (=='(') >*>
     p1 >*>
     p2 >*>
     spot (==')'))
    `build`
    \ (_,(e1,(e2,_))) -> e1 :*: e2


starP :: Parse Char RE -> Parse Char RE

starP p
  = (spot (=='(') >*>
     p >*>
     spot (==')') >*>
     spot (=='*'))
    `build`
    \ (_,(e,(_,_))) -> St e

-- pulling them together

reP :: Parse Char RE

reP = epsP 
       `alt`
       charP
       `alt`
       altP reP reP
       `alt`
       seqP reP reP
       `alt`
       starP reP
        
-- top-level function.

parseRE :: String -> RE

parseRE st
  = e
    where
    [(e,"")] = reP st

-- Expected property: the two functions are inverses of each other, when applied to legal 
-- representations of strings.

-- To test in QuickCheck, note that it's difficult to generate legal strings directly,
-- instead best to generarte REs and turn them into legal strings.

--
-- Solution 19.3
--

palin :: RE 

palin = (middle :|: (a :*: (palin :*: a))) :|: (b :*: (palin :*: b))

middle = (Eps :|: (a :|: b))

--
-- Solution 19.4
--

-- Just follow the pattern of recursion used in the definition of reP above.
-- Works just like 19.3.

--
-- Solution 19.5
--

-- I believe that "recursive regular expressions" = "context free grammars" and
-- so this set of strings will therefore not be representable.

--
-- Solution 19.6
--

-- What does extension mean? Add a construct to RE and then extend its
-- interpretations into RegExp, enumeration, concrete syntax etc.

-- MatchN Int RE, interpreted by

matchN :: Int -> RegExp -> RegExp

matchN n re
  | n<=0        = epsilon
  | otherwise   = re <*> matchN (n-1) re

--- Ranges etc. are all pretty straightforward.

--
-- Solution 19.7
--

--- Actually not so difficult to implement ...

matchBoth :: RegExp -> RegExp -> RegExp

matchBoth re1 re2 st 
  = re1 st && re2 st

matchNot :: RegExp -> RegExp

matchNot re st
  = not (re st)

--
-- Solutions 19.8-10
--

-- See the module PositionedImages.hs

--
-- Solution 19.11
--

-- This was discussed in Solutions12,  question 12.19.

--
-- Solution 19.12
--

samplePretty :: IO ()

samplePretty
  = do exprs <- sample' (arbitrary :: Gen Expr)
       printLines (map ((++"\n").prettyE) exprs)

printLines :: [String] -> IO ()

printLines strs
  = if strs == [] 
       then return ()
       else do putStr (head strs)
               printLines (tail strs)

--
-- Solution 19.13
--

-- Generators standard.

-- Properties 
--   - should be able to round trip exp -> pretty -> exp
--   - not so obvious how to test the fact that the evaluator gives
--     the right result.
--   - one idea is to build pairs of expression and their values, which
--     are generated simultaneously ,,, of course, that is tantamount 
--     to defining a second evaluation function (albeit implicitly).

--
-- Solution 19.14
--

-- Five finger exercise ...
