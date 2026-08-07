------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions13
--
------------------------------------------------------------------------------

{-# OPTIONS_GHC -XFlexibleInstances #-}

module Solutions13 where

import Chapter13
import Chapter4 (Move(..))


--
-- Solution 13.1
--

-- x /= y = not (x == y)

--
-- Solution 13.2
--

numEqual :: Eq a => [a] -> a -> Integer

numEqual [] _ = 0
numEqual (x:xs) y
  | x==y        = 1 + numEqual xs y
  | otherwise   = numEqual xs y

member' :: Eq a => [a] -> a -> Bool

member' xs x = (numEqual xs x > 0)

--
-- Solution 13.3
--

oneLookupFirst :: Eq a => [(a,b)] -> a -> b

oneLookupFirst [] _ = error "oneLookupFirst fails"

oneLookupFirst ((x,y):ps) z
  | x==z         = y
  | otherwise    = oneLookupFirst ps z

-- raises error if no element found

-- oneLookupSecond: just change the roles of first and second elements 
-- in the list.

--
-- Solution 13.4
--

instance Info Move where
  examples = [Rock, Paper, Scissors]
  size     = \s -> 0

instance (Info a, Info b, Info c) => Info (a,b,c) where
  examples = [ (a,b,c) | a<-examples, b<-examples, c<-examples ]
  size (a,b,c) = size a + size b + size c + 1

--
-- Solution 13.5
--

instance Info (Int -> Bool) where
  examples = map makeFun examples

makeFun :: [Int] -> (Int -> Bool)

makeFun xs = \x -> elem x xs

-- for Int->Int need to make choices for function
-- values: can use examples again, or randomly generate values

--
-- Solution 13.6
--

instance Info Float where
  examples = [ fromIntegral a / fromIntegral b | 
               a<-examples::[Int], b<-examples::[Int], b/=0 ]

--
-- Solution 13.7
--

compare :: (Info a, Info b) => a -> b -> Bool

compare x y = size x <= size y

--
-- Solution 13.8
--

-- We can't hide default definitions or instances, so
-- we redefine here.

max' x y = if x>y then x else y
min' x y = if x<y then x else y

compare' x y 
  | x>y         = GT
  | x<y         = LT
  | otherwise   = EQ

--
-- Solution 13.9
--

-- instance (Ord a, Ord b) => Ord (a,b) where
--  (x1,y1)<(x2,y2) = (x1<x2) || (x1==x2 && y1<y2)

-- similarly for lists.

--
-- Solution 13.10
--

-- False < True

-- (False,False) < (False,True) < (True,False) < (True,True)

--
-- Solution 13.11
--

pad :: String -> String

pad st = replicate (9 - length st) ' ' ++ st

-- showing a unary function ...

showBoolFun :: (Bool -> Bool) -> String

showBoolFun f
  = pad "x" ++ pad "f x" ++ "\n" ++
    concat [ pad (show x) ++ pad (show (f x)) ++ "\n" | x<-[False,True] ]

-- showing a unary function ... to an arbitrary type   

showBoolFunGen :: (a -> String) -> (Bool -> a) -> String

showBoolFunGen s f
  = pad "x" ++ pad "f x" ++ "\n" ++
    concat [ pad (show x) ++ pad (s (f x)) ++ "\n" | x<-[False,True] ]

-- showing a binary function ...

showBool2Fun :: (Bool -> Bool -> Bool) -> String

showBool2Fun f
  = pad "x" ++ pad "y" ++ pad "f x y" ++ "\n" ++
    concat [ pad (show x) ++ pad (show y) ++ pad (show (f x y)) ++ "\n" | 
             x<-[False,True], y<-[False,True] ]

--
-- Solution 13.12
--

instance Show (Bool -> Bool) where
  show = showBoolFun

--
-- Solution 13.13
--

-- Let's use the Info class for a set of examples ... we just 
-- rewrite showBoolFun so that it takes the inputs from the
-- list of examples ...

show1Fun :: (Show a, Show b, Info a) => (a -> b) -> String

show1Fun f
  = pad "x" ++ pad "f x" ++ "\n" ++
    concat [ pad (show x) ++ pad (show (f x)) ++ "\n" | x<-examples ]

--
-- Solution 13.14
--

-- nxt and prv cycle through the possibilities in opposite order, and
-- are inverses

class Eq a => Cycle a where
  nxt :: a -> a
  prv :: a -> a
    

instance Cycle Move where

  nxt Rock = Paper
  nxt Paper = Scissors
  nxt Scissors = Rock

  prv Rock = Scissors
  prv Paper = Rock
  prv Scissors = Paper

-- Other examples: seasons, 24 hour clock, Int (loops around) etc.

--
-- Solution 13.15
--

data Roman = Roman Int

-- works up to 48 ... need to treat "L" and "C" in a way analagous to "V" and "X".

instance Show Roman where
  show (Roman n) 
    | n<=0              = "non Roman numeral"
    | 1<=n && n<=3      = replicate n 'I'
    | otherwise         = prefixTen ++ replicate tens 'X' ++ 
                          prefixFive ++ replicate fives 'V' ++ postfixUnits
      where
      units = n `rem` 5
      fives = ((n+1) `div` 5) `rem` 2
      tens  = (n+1) `div` 10
      prefixTen  = if n `rem` 10 == 9 then "I" else ""
      prefixFive = if n `rem` 10 == 4 then "I" else ""
      postfixUnits = if units == 4 then "" else replicate units 'I'

-- Idea for addition: turn "I" as in "IX" to "J", then normalise the concatenated strings. 
-- Any "J" and "I" will cancel each other out, and if have 4 I's in normalised result, turn to 
-- an I prefix.

--
-- Solution 13.16
--

-- The Read class will need to be the opposite of Show. To convert use the same track as above.
-- converting things out of order into a negative equivalent before adding up values.

-- Adding this "idealised" element makes the calculation much simpler.

--
-- Solution 13.17
--

-- Type into ghci.

--
-- Solution 13.18
--

-- Yes, to (Int -> Bool)
-- No, as in any unification would have all fields the same.

--
-- Solution 13.19
--

-- a goes to Bool
-- b goes to Bool
-- c goes to [Bool]

--
-- Solution 13.20
--

-- Yes (giving a b)
-- Yes (giving a b)
-- No, can't unify Int with Bool

--
-- Solution 13.21
--

-- Yes (giving an Int)
-- Yes (giving an Int)
-- No, can't unify Int with Bool

--
-- Solution 13.22
--

-- type is a->b

-- [a] -> a -> a

--
-- Solution 13.24
--

-- type them into ghci ...

--
-- Solution 13.25
--

-- This can be found in the literature e.g. 
--      http://en.wikipedia.org/wiki/Unification_(computer_science)

--
-- Solution 13.26
--

-- Type them as four separate clauses (merge1 etc) and get the
-- :type from ghci

--
-- Solution 13.27
--

pSort :: Ord a => [a] -> [a]

pSort [] = []
pSort (x:xs) = pSort [ y | y<-xs, y<=x] ++ [x] ++ pSort [ y | y<-xs, y>x]

--
-- Solution 13.28
--

-- Again, use :type in ghci.





