------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions9
--
------------------------------------------------------------------------------

module Solutions9 where

import Chapter9 hiding (length,sum,(++))
import Test.QuickCheck
import Prelude hiding (reverse)
import qualified Prelude


--
-- Solution 9.1
-- 

-- First evaluation gives True; second fails to terminate

--
-- Solution 9.2
-- 

mult :: Integer -> Integer -> Integer

mult 0 y = 0
mult x y = x*y

--
-- Solutions 9.3-9.9
-- 

-- These are straightforward proofs by induciton over lists. The only choice that needs
-- to be made is in the case where there is more than one variable over which to use
-- induction: in that case choose the variable over which the recursion is done in the 
-- definition (in the case of ++ the variable to the left of the operator).

--
-- Solution 9.10
-- 

-- Here do an induction over n, with subsidiary cases for the list variable.

--
-- Solution 9.11
-- 

-- Enitrely straightforward. Just trasliterate with == replacing = and 
-- giving the lists [Integer] type, as explained on p207, so, for example, 9.7
-- gives

prop_sum_reverse :: [Integer] -> Bool

prop_sum_reverse xs 
  = sum (reverse xs) == sum xs


prop_length_reverse :: [Integer] -> Bool

prop_length_reverse xs 
  = length (reverse xs) == length xs

-- and 9.10 gives

prop_take_drop :: Int -> [Integer] -> Bool

prop_take_drop n xs 
  = take n xs ++ drop n xs == xs

--
-- Solution 9.12
-- 

-- Same advice as above (9.3-9.9) on the choice of variable for induction.

--
-- Solution 9.13
-- 

-- Need to choose an appropriate generalisation of the property 
--      fac2 n = facAux n 1
-- as 1 is too special a case. Replace 1 with m on the RHS: what
-- has to happen on the LHS?
--      fac2 n * m = facAux n m

prop_genfac :: Integer -> Integer -> Bool
prop_genfac n m
  = n<0 || fac2 n * m == facAux n m

-- need the n<0 || ... so that property only addresses non-negative n, as when
-- n is negative the facAux function loops forever

--
-- Solution 9.14
-- 

prop_two_reverse :: [Integer] -> Bool

prop_two_reverse xs 
  = reverse xs == Prelude.reverse xs

--
-- Solution 9.15
-- 

-- Combines insights from the last two questions.



