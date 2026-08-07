------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions3
--
------------------------------------------------------------------------------

module Solutions3 where

import Prelude hiding ((||),(&&),min)
import Chapter3 hiding (toUpper, isDigit)
import Test.QuickCheck 
import Data.Char 


--
-- Solution 3.1
--

exOr1 :: Bool -> Bool -> Bool

exOr1 x y = (x && not y) || (not x && y)

-- A horrible solution here would be one which looks 
-- at the argument variables and compares them with 
-- True and False. Need to explain that can directly
-- return boolean values such as x, y.

exOr' ::  Bool -> Bool -> Bool

exOr' x y = ((x==True) && (y==False)) || ((x==False) && (y==True))

--
-- Solution 3.3
--

exOr2 :: Bool -> Bool -> Bool

exOr2 True True   = False
exOr2 True False  = True
exOr2 False True  = True
exOr2 False False = False

--
-- Solution 3.4
--

-- These solutions are nice in that they do "shortcut" evaluation, only
-- evaluating the second argument in the case that the first is False 
-- (respectively True). This only works in a language with lazy evaluation
-- as otherwise both arguments evaluated before the body of the defn.

(||), (&&) :: Bool -> Bool -> Bool

True  || x = True
False || x = x

True  && x = x
False && x = False

--
-- Solution 3.5
--

nAnd, nAnd1 :: Bool -> Bool -> Bool

nAnd x y = not (x && y)

nAnd1 False y = True
nAnd1 True  y = not y

-- 
-- Solution 3.7
-- 

-- Some solutions already in Chapter3

-- Check the two functions against each other ...

prop_nAnd1, prop_nAnd2, prop_nAnd3 :: Bool -> Bool -> Bool

prop_nAnd1 x y =
    nAnd x y == nAnd1 x y

-- Rather a silly property: it's the same result whatever values
-- of x and y. Still, it passes each time!

prop_nAnd2 x y = 
           (nAnd True True == False) &&
           (nAnd True False == True) &&
           (nAnd False True == True) &&
           (nAnd False False == True)

-- Testing against a different implementation:

prop_nAnd3 x y = 
           nAnd x y == ((not x) || (not y))
                                        

-- 
-- Solution 3.8
-- 

-- The three values are not all equal. NB that's not the same
-- as them all being different.

-- 
-- Solution 3.9
-- 

threeDifferent :: Integer -> Integer -> Integer -> Bool

threeDifferent x y z = (x/=y) && (y/=z) && (z/=x)

-- An obvious mistake is to write
-- threeDifferent x y z = (x/=y) && (y/=z)
-- which can be satisfied when x and z are equal.

-- 
-- Solution 3.10
-- 

fourEqual1, fourEqual2 :: Integer -> Integer -> Integer -> Integer -> Bool

fourEqual1 x y z w = (x==y) && (y==z) && (z==w)

fourEqual2 x y z w = threeEqual x y z && (z==w)

-- 
-- Solution 3.12
-- 

prop_fourEqual1 :: Integer -> Integer -> Integer -> Integer -> Bool

prop_fourEqual1 x y z w =
              fourEqual1 x y z w == fourEqual2 x y z w 

-- It's possible to use implication in writing properties, as in
-- but note here that the result type is "Property" not "Bool".
-- This is jumping ahead, but something it's good to be aware of.

prop_fourEqual2 :: Integer -> Integer -> Integer -> Integer -> Property

prop_fourEqual2 x y z w =
              (x/=y) ==> not (fourEqual2 x y z w) 

-- 
-- Solution 3.14
-- 

-- NB need to add hding of min to the import of Prelude at the top
-- of the solutions file.

min :: Integer -> Integer -> Integer

min x y = if x<y then x else y

minThree :: Integer -> Integer -> Integer -> Integer

minThree x y z = x `min` (y `min` z)

-- 
-- Solution 3.15
-- 

prop_min :: Integer -> Integer -> Bool

prop_min x y =
         ((min x y == x) || (min x y == y)) &&
         (min x y <= x) && (min x y <= y)

-- The property for minThree is defined in a similar
-- way, or can write a property relating the two, as in

prop_minThree :: Integer -> Integer -> Integer -> Bool

prop_minThree x y z =
              if x<=y then (minThree x y z == min x z)
                      else (minThree x y z == min y z)

-- 
-- Solution 3.16
-- 

-- Uses functions from Data.Char
-- Have to hide toUpper from Chapter3

convert :: Char -> Char

convert ch = if isLower ch 
                then toUpper ch 
                else ch

-- 
-- Solution 3.17
-- 

-- Uses functions from Data.Char
-- Have to hide isDigit from Chapter3

charToNum :: Char -> Int

charToNum ch = if isDigit ch
                  then fromEnum ch - fromEnum '0'
                  else 0


-- 
-- Solution 3.18
-- 

onThreeLines :: String -> String -> String -> String

onThreeLines st1 st2 st3 
  = st1 ++ "\n" ++ st2 ++ "\n" ++ st3 ++ "\n" 

-- 
-- Solution 3.19
-- 

romanDigit :: Char -> String

romanDigit ch = if isDigit ch
                   then roman (fromEnum ch)
                   else ""

roman :: Int -> String

roman 0 = ""
roman 1 = "I"
roman 2 = "II"
roman 3 = "III"
roman 4 = "IV"
roman 5 = "V"
roman 6 = "VI"
roman 7 = "VII"
roman 8 = "VIII"
roman 9 = "IX"

-- 
-- Solution 3.20
-- 

-- The average is entirely straighforward, except that we need to
-- convert the sum of integers to a Float before doing the division

averageThree :: Integer -> Integer -> Integer -> Float

averageThree x y z = fromInteger (x+y+z) / 3

-- but there's also an average that returns an Integer, which 
-- we can compare with other integers. This rounds the average down
-- because it's doing an integer division

avThree :: Integer -> Integer -> Integer -> Integer

avThree x y z = (x+y+z) `div` 3

-- Counting how many above average is a bit trickier

-- One nice way of doing this is to use if ... then ... else ...
-- calculating the sum of three of these:

howManyAboveAverage :: Integer -> Integer -> Integer -> Integer

howManyAboveAverage x y z =
 (if x > avThree x y z then 1 else 0) +
 (if y > avThree x y z then 1 else 0) +
 (if z > avThree x y z then 1 else 0)

-- Can also define a function like this ...

aboveAverage :: Integer -> Integer -> Integer -> Integer -> Integer

aboveAverage p x y z 
             = if p > avThree x y z then 1 else 0

-- ... and then use like this:

howManyAboveAverage1 x y z =
                     aboveAverage x x y z + 
                     aboveAverage y x y z + 
                     aboveAverage z x y z

-- What is tricky about these is that we've not yet seen where or let, so we
-- can't write the nicer

howManyAboveAverage2 x y z =
 (if x > aver then 1 else 0) +
 (if y > aver then 1 else 0) +
 (if z > aver then 1 else 0)
     where
        aver = avThree x y z 

--
-- Solution 3.21
--

-- Multiply the average by three, and you get the sum of the inputs ...

prop_averageThree :: Integer -> Integer -> Integer -> Bool

prop_averageThree x y z
  = 3.0 * averageThree x y z == fromInteger (x+y+z)
      
-- Doing the integer division by 3 is the same as doing floating-
-- point division and then taking the integer part, using floor.            

prop_avThree :: Integer -> Integer -> Integer -> Bool

prop_avThree x y z
  = floor (averageThree x y z) == avThree x y z 

--
-- Solution 3.22
--

-- Transcription of the specification.

numberNDroots :: Float -> Float -> Float -> Integer

numberNDroots a b c
  = if b*b > 4*a*c then 2
                   else if b*b == 4*a*c then 1 else 0

--
-- Solution 3.23
--

numberRoots :: Float -> Float -> Float -> Integer

numberRoots a b c
  = if a/=0 then numberNDroots a b c
            else if b/=0 then 1
                         else if c/=0 then 0 else 3

--
-- Solution 3.24
--

-- Note that the (...) are needed when you "or" together two tests.

smallerRoot, largerRoot :: Float -> Float -> Float -> Float

smallerRoot a b c = if (numberRoots a b c == 0) || (numberRoots a b c == 3)
                                   then 0
                                   else ((-b) - sqrt(b*b - 4*a*c))/(2*a)

largerRoot a b c = if (numberRoots a b c == 0) || (numberRoots a b c == 3)
                                   then 0
                                   else ((-b) + sqrt(b*b - 4*a*c))/2*a

--
-- Solution 3.25
--

-- First a function to calculate the value of the quadratic ...

calculate :: Float -> Float -> Float -> Float -> Float

calculate x a b c = a*x*x + b*x + c

-- ... and to substitue back the smaller root.

substSmaller :: Float -> Float -> Float -> Float

substSmaller a b c =
  calculate (smallerRoot a b c) a b c

-- Substitute the root back, and should get zero ...

prop_quadratic :: Float -> Float -> Float -> Bool

prop_quadratic a b c =
  substSmaller a b c == 0.0

-- ... but that only works if there's a proper root, so have a 
-- disjunctive property:

prop_quad :: Float -> Float -> Float -> Bool

prop_quad a b c =
  prop_quadratic a b c || ( (a/=0) && (b*b < 4*a*c) ) || (a==0)

-- This fails too: here's a counterexample:
--   substSmaller 0.5210301 9.0 1.6170254
-- calculates to 
--   -9.536743e-6
-- so it's almost 0.0 

-- Note that the approx value is a function of the size of the
-- a, b and c. Replacing 10^5 by 10^6 makes this easily falsifiable.
-- at 10^5 get most tests succeeding.

prop_quad_approx :: Float -> Float -> Float -> Bool

prop_quad_approx a b c =
  ( calculate (smallerRoot a b c) a b c < (abs a + abs b + abs c)/10^5 ) ||
  ( (a/=0) && (b*b < 4*a*c) ) || (a==0)
