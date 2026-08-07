------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions4
--
------------------------------------------------------------------------------

module Solutions4 where

import Chapter4 hiding (maxThree,whiteBlack,whiteChess,blackWhite,blackChess)
import PicturesSVG
import Test.QuickCheck hiding (Result)
import Test.HUnit



--
-- Solution 4.1
--

maxThree :: Integer -> Integer -> Integer -> Integer

maxThree x y z
  = x `max` (y `max` z)

maxFour1, maxFour2, maxFour3 :: Integer -> Integer -> Integer -> Integer -> Integer

maxFour1 x y z w 
  | x>=y && x>=z && x>=w  = x
  | y>=x && y>=z && y>=w  = y
  | z>=x && z>=y && z>=w  = z
  | otherwise             = y

maxFour2 x y z w
  = x `max` (y `max` (z `max` w))

maxFour3 x y z w
  = (maxThree x y z) `max` w

--
-- Solution 4.2
--

-- Direct definition

between :: Integer -> Integer -> Integer -> Bool

between x y z
  = (x<=y && y <=z) || (x>=y && y>=z)

-- Using weakAscendingOrder

weakAscendingOrder :: Integer -> Integer -> Integer -> Bool

weakAscendingOrder x y z
  = (x<=y && y <=z)

between2 :: Integer -> Integer -> Integer -> Bool

between2 x y z 
  = weakAscendingOrder x y z || weakAscendingOrder z y x

--
-- Solution 4.3
--

-- Brute force solution

howManyEqual :: Integer -> Integer -> Integer -> Integer

howManyEqual x y z
  | x==y && y==z          = 3
  | x==y || y==z || z==x  = 2
  | otherwise             = 0

-- In another order ...

howManyEqual2 :: Integer -> Integer -> Integer -> Integer

howManyEqual2 x y z
  | x/=y && y/=z && z/=x  = 0
  | x==y && y==z          = 3
  | otherwise             = 2

--
-- Solution 4.4
-- 

howManyOfFourEqual :: Integer -> Integer -> Integer -> Integer -> Integer

-- Is this a well-posed problem .... what about
--   howManyOfFourEqual 3 3 4 4 
-- hmph ... it's certainly a corner case for testing!

howManyOfFourEqual a b c d 
  | a==b && b==c && c==d      = 4
  | (a==b && b==c) ||
    (a==b && b==d) ||
    (a==c && c==d) ||
    (b==c && c==d)            = 3
  | a==b || b==c || c==d ||
    a==c || b==d || a==d      = 2
  | otherwise                 = 0

-- A better question to ask is "how many different pairs are equal?"

howManyPairsEqual :: Integer -> Integer -> Integer -> Integer -> Integer

howManyPairsEqual a b c d  
  = eq a b + eq a c + eq a d +
    eq b c + eq b d + eq c d

eq :: Integer -> Integer -> Integer

eq a b = if a==b then 1 else 0 

--
-- Solution 4.5
--

fourPics5, fourPics6 :: Picture -> Picture

fourPics5 pic =
    left `beside` right
      where
        stack p  = p `above` invertColour p
        left     = stack pic
        right    = invertColour (stack (flipV pic))

fourPics6 pic =
    left `beside` right
      where
        stack p  = p `above` invertColour p
        left     = stack pic
        right    = invertColour (flipV (stack pic))

--
-- Solution 4.6
--

fourPics7, fourPics8, fourPics9 :: Picture -> Picture

fourPics7 pic =
    top `above` bottom
        where
          top = pic `beside` invertColour (flipV pic)
          bottom = invertColour pic `beside` flipV pic

fourPics8 pic =
    top `above` bottom
        where
          top = pic `beside` invertColour (flipV pic)
          bottom = invertColour top

fourPics9 pic =
    top `above` bottom
        where
          pair p =  pic `beside` invertColour (flipV p)
          top = pair pic
          bottom = pair (invertColour pic)

--
-- Solution 4.7
--

-- First definition just has an auxiliary function ...

fourPics10, fourPics11 :: Picture -> Picture

fourPics10 pic =
  stack pic `beside` stack (invertColour (flipV pic))
        where        
          stack p  = p `above` invertColour p

-- ... second uses none at all.

fourPics11 pic = 
  (pic `beside` invertColour (flipV pic))
     `above`
  (invertColour pic `beside` flipV pic)
    
--
-- Solution 4.8
--

possible :: Float -> Float -> Float -> Bool

possible a b c 
  = a>0 && b>0 && c>0 && a<b+c && b<a+c && c<a+b

--
-- Solution 4.9
--

maxThreeOccurs :: Int -> Int -> Int -> (Int,Int)

maxThreeOccurs a b c
  = (mx, occurs)
    where
        mx     = a `max` (b `max` c)
        occurs = occs a + occs b + occs c
        occs x = if x==mx then 1 else 0

--
-- Solution 4.11
--

data Result = Lose | Draw | Win
              deriving (Eq, Show)

--
-- Solution 4.12
--

outcome :: Move -> Move -> Result

outcome Rock Rock = Draw
outcome Rock Paper = Lose
outcome Rock Scissors = Win
outcome Paper Rock = Win
outcome Paper Paper = Draw
outcome Paper Scissors = Lose
outcome Scissors Rock = Lose
outcome Scissors Paper = Win
outcome Scissors Scissors = Draw

--
-- Solution 4.13
--

-- QuickCheck property about the "sanity" of the 
-- beat and lose functions.

prop_WinLose :: Move -> Bool

prop_WinLose x =
    beat x /= lose x &&
    beat x /= x &&
    lose x /= x

--
-- Solution 4.14
--

prop_beat x =
  outcome (beat x) x == Win

prop_lose x =
  outcome (lose x) x == Lose

--
-- Solution 4.15
--

data Season = Spring | Summer | Autumn | Winter
              deriving (Eq,Ord,Show)

data Temp = Cold | Hot
            deriving (Eq, Show, Ord)

temperature :: Season -> Temp

temperature Summer = Hot
temperature _      = Cold

--
-- Solution 4.16
--

data Month = January
           | February
           | March
           | April
           | May
           | June
           | July
           | August
           | September
           | October
           | November
           | December
           deriving (Show, Eq, Ord)

season :: Month -> Season

season mnt
  | (March<=mnt) && (mnt<=May)          = Spring
  | (June<=mnt) && (mnt<=August)        = Summer
  | (September<=mnt) && (mnt<=November) = Autumn
  | otherwise                           = Winter

-- Note: the parentheses are necessary in the 
-- guards in the example above.

--
-- Solution 4.17
--

-- Can work up from the lower end of the range ...

rangeProduct :: Integer -> Integer -> Integer

rangeProduct m n 
  | m>n       = 1
  | otherwise = m * rangeProduct (m+1) n

-- ... or down from the upper end. In either case terminate wheh
-- the lower is greater than the upper: the point is that either
-- approach makes the two limits closer.

ranPro :: Integer -> Integer -> Integer

ranPro m n 
  | m>n       = 1
  | otherwise = ranPro m (n-1) * n

--
-- Solution 4.18
--

factorial :: Integer -> Integer

factorial n = rangeProduct 1 n

--
-- Solution 4.19
--

-- Not recommended for real computation, but this is 
-- one way of defining multiplication and addition!

-- Note that they are undefined on negtive first arguments
-- could give them some value on negatives too ...

multNat :: Integer -> Integer -> Integer

multNat 0 n = 0
multNat m n 
  | m>0    = addNat n (multNat (m-1) n)

addNat 0 n = n
addNat m n
  | m>0    = (addNat (m-1) n)+1

--
-- Solution 4.20
--

-- The idea here is that the isr of n is either
--    isr (n-1)
--    isr (n-1) + 1
-- just have to test whether this latter, squared, is
-- <= n.

isr :: Integer -> Integer

isr 0 = 0
isr n
  | n>0 && next*next <= n   = next
  | n>0                     = prev
    where
       prev = isr (n-1)
       next = prev+1

-- An alternative solution here would embed an "if then else" , like this

isr' 0 = 0
isr' n
  | n>0 = if next*next <= n then next else prev
    where
       prev = isr' (n-1)
       next = prev+1
--
-- Solution 4.21
--

f 0 = 22
f 1 = 44
f 2 = 17
f _ = 0

maxf :: Integer -> Integer

maxf 0 = 0
maxf n
  | n>0 = if f n >= fmax then n else prev
    where
        prev = maxf (n-1)
        fmax = f prev

-- It's important that prev is calculated in a where
-- clause, as that means it's only calculated once in each
-- step: otherwise need to calculate it twice, once in the 
-- if, and once in the result, which makes
-- the computation exponential.

--
-- Solution 4.22
--

zero :: Integer -> Bool

zero 0 = (f 0 == 0)
zero n
  | n>0 = (f n == 0) || zero (n-1)

-- Note here that we'll only call zero (n-1) in the 
-- case that f n is not 0. If it's 0 then we know the
-- result is True.

--
-- Solution 4.23
--

-- RegionStep gives the number of new regions added at 
-- a particular step.

regionStep :: Integer -> Integer

regionStep 0 = 1
regionStep n = n

regions' :: Integer -> Integer

regions' n = sumFun regionStep n

-- Test the two regions functions, for positive numbers,
-- so check whether n is <= 0, or the property holds ...

prop_regions :: Integer -> Bool

prop_regions n 
  = (n <= 0) || (regions n == regions' n) 

--
-- Solution 4.24
--

-- With the fist three "cuts" get 2, 4, 8. with the fourth, we add
-- seven more (cutting all but one of the previous pieces). I *think*
-- it's then like the two dimensional case, add 8, 9, etc.

--
-- Solution 4.25
--

-- Imported 

blackWhite :: Integer -> Picture

blackWhite n
  | n<=1         = black
  | otherwise = black `beside` whiteBlack (n-1)

blackChess :: Integer -> Integer -> Picture

blackChess n m
  | n<=1         = blackWhite m
  | otherwise = blackWhite m `above` whiteChess (n-1) m

-- Solutions

whiteBlack :: Integer -> Picture
whiteBlack n
  | n<=1      = white
  | otherwise = white `beside` blackWhite (n-1)


whiteChess :: Integer -> Integer -> Picture
whiteChess n m
  | n<=1      = whiteBlack m
  | otherwise = whiteBlack m `above`  blackChess (n-1) m

--
-- Solution 4.26
--

column :: Picture -> Integer -> Picture

column pic n
  | n<=1      = pic
  | otherwise = pic `above` column pic (n-1)

--
-- Solution 4.27
--

-- build it from diagonal (n-1) by adding a column of white to the right
-- and a row beneath this with n-1 white squares and a black one.

diagonal :: Integer -> Picture

diagonal n 
  | n<=1      = black
  | otherwise = (diagonal (n-1) `beside` column white (n-1))
                  `above`
                (row white (n-1) `beside` black)  

-- using this auxiliary function ...

row :: Picture -> Integer -> Picture

row pic n
  | n<=1      = pic
  | otherwise = pic `beside` row pic (n-1)

--
-- Solution 4.28
--

-- The easiest way is to re-use diagonal ...

slash :: Integer -> Picture

slash n = flipH (diagonal n)

-- .. though it could be built up constructively just like diagonal.

--
-- Solution 4.29
--

-- With superimposition, we can just superimpose slash and diagonal.

-- Alternatively can build up from half-sized slashes and diagonals.

cross :: Integer -> Picture

cross n = (diagonal (n `div` 2) `beside` slash (n `div` 2))
            `above`
          (slash (n `div` 2) `beside` diagonal (n `div` 2))

-- though this solution is only correct for even n. For the odd case
-- need to think about how to put things together.

--
-- Solution 4.30
--

-- Solution is similar to earlier solution to diagonal, but need to 
-- switch between black and white in even/odd cases.

chessBoard :: Integer -> Picture

chessBoard n
  | n<=1      = black
  | isEven n  = (chessBoard (n-1) `beside` whiteBlackColumn (n-1))
                  `above`
                whiteBlack n
  | otherwise = (chessBoard (n-1) `beside` blackWhiteColumn (n-1))
                  `above`
                blackWhite n
    where
        isEven m = (m `rem` 2) == 0

whiteBlackColumn n 
  | n<=1      = white
  | otherwise = white `above` blackWhiteColumn (n-1)  

blackWhiteColumn n 
  | n<=1      = black
  | otherwise = black `above` whiteBlackColumn (n-1)  

--
-- Solution 4.31
--

-- using division

hcf :: Integer -> Integer -> Integer

hcf n m 
  | n<0 || m<0       = 0
  | n<m              = hcf m n
  | m==0             = n
  | otherwise        = hcf (n `rem` m) m

-- using subtraction 

hcf' :: Integer -> Integer -> Integer

hcf' n m 
  | n<0 || m<0       = 0
  | n<m              = hcf m n
  | m==0             = n
  | otherwise        = hcf' (n - m) m

--
-- Solution 4.32
--

power :: Integer -> Integer

power 0 = 1

power n
  | n `rem` 2 == 0 = pow*pow
  | otherwise      = pow*pow*2
    where
        pow = power (n `div` 2)

--
-- Solution 4.33
--

-- use this for 4.33
allEqual a b c = (a==b) && (b==c)

testAllEqual1 = TestCase (assertEqual "for: allEqual 6 4 1" False (allEqual 6 4 1))
testAllEqual2 = TestCase (assertEqual "for: allEqual 6 6 6" True (allEqual 6 6 6))
testAllEqual3 = TestCase (assertEqual "for: allEqual 2 6 6" False (allEqual 2 6 6))
testAllEqual4 = TestCase (assertEqual "for: allEqual 2 2 6" False (allEqual 2 2 6))

testsAllEqual = TestList [testAllEqual1, testAllEqual2, testAllEqual3, testAllEqual4]

--
-- Solution 4.34
--

-- use this for 4.34
-- allEqual m n p = ((m+n+p)==3*p)

--
-- Solution 4.35 and 4.36
--

-- incorrect solution!

allDifferent :: Integer -> Integer -> Integer -> Bool

-- this definition for 4.36
-- allDifferent a b c 
--   = (a/=b) && (b/=c)

testAllDifferent1 = TestCase (assertEqual "for: allDifferent 6 4 1" True (allDifferent 6 4 1))
testAllDifferent2 = TestCase (assertEqual "for: allDifferent 6 6 6" False (allDifferent 6 6 6))
testAllDifferent3 = TestCase (assertEqual "for: allDifferent 2 6 6" False (allDifferent 2 6 6))
testAllDifferent4 = TestCase (assertEqual "for: allDifferent 2 2 6" False (allDifferent 2 2 6))

testsAllDifferent = TestList [testAllDifferent1, testAllDifferent2, testAllDifferent3, testAllDifferent4]

-- and the moral of this is?

--
-- Solution 4.37
--

howManyAboveAverage :: Integer -> Integer -> Integer -> Integer

howManyAboveAverage a b c
  = above a + above b + above c
    where 
          above x = if fromInteger x > av then 1 else 0
          av = fromInteger (a+b+c) / 3

test_howManyAboveAverage1 = TestCase (assertEqual "for: howManyAboveAverage 6 4 1" 2 (howManyAboveAverage 6 4 1))
test_howManyAboveAverage2 = TestCase (assertEqual "for: howManyAboveAverage 6 6 6" 0 (howManyAboveAverage 6 6 6))
test_howManyAboveAverage3 = TestCase (assertEqual "for: howManyAboveAverage 2 6 6" 2 (howManyAboveAverage 2 6 6))
test_howManyAboveAverage4 = TestCase (assertEqual "for: howManyAboveAverage 2 2 6" 1 (howManyAboveAverage 2 2 6))

tests_howManyAboveAverage = TestList [test_howManyAboveAverage1, test_howManyAboveAverage2, 
                                      test_howManyAboveAverage3, test_howManyAboveAverage4]

--
-- Solution 4.38
--

-- Pretty striaghtforward

--
-- Solution 4.39
--

-- Nice point here: these test involve the way that two (or more) 
-- functions work together.

-- This definition for 4.39
allDifferent a b c 
  = (a/=b) && (b/=c) && (a/=c)

-- Can't have all equal and all different

prop_exclusive x y z 
  = not (allEqual x y z && allDifferent x y z)

twoEqual x y z 
  = (x==y && x/=z) ||
    (x==z && x/=y) ||
    (y==z && x/=z)

-- Either all equal, two equal or all different, with *exclusive* or.

prop_exhaustive x y z
  = allEqual x y z `exOr` twoEqual x y z `exOr` allDifferent x y z
    where 
          exOr = (/=)