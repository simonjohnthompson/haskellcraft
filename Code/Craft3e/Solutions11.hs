------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions11
--
------------------------------------------------------------------------------

module Solutions11 where

import Prelude hiding (flip,curry,uncurry)
import Chapter11 hiding (flip,iter')
import Test.QuickCheck
import QCfuns

--
-- Solution 11.1
-- 

-- produceBill = makeBill >.> formatBill

--
-- Solution 11.2
-- 

-- All are the function f
-- Types:
--      Bool -> Bool
--      Int -> Int
--      (Int -> Bool) -> (Int -> Bool)

-- Final case f :: (a -> a) -> some type

--
-- Solution 11.3
-- 

composeList :: [a -> a] -> a -> a

composeList = foldr (.) id

-- A more explicit definition

compList :: [a -> a] -> a -> a

compList [] x     = x  

compList (f:fs) x = f (compList fs x)

-- composeList [] is the identity function

--
-- Solution 11.4
-- 

--      *Solutions11> :type ($)
--      ($) :: (a -> b) -> a -> b

--
-- Solution 11.5
-- 

-- [3,12]

--
-- Solution 11.6
-- 

-- Three expressions
--       f
--       f applied to id (so has to have right type)
--       ($)

--       (Int -> Bool) -> (Int -> Bool)
--       doesn't type check
--       ((a -> b) -> a -> b) -> (a -> b) -> a -> b

-- final result as for 11.2

--
-- Solution 11.7
-- 

nonWhitespace :: Char -> Bool

nonWhitespace
  = \ch -> not (elem ch " \t\n") 

--
-- Solution 11.8
-- 

-- Not using recursion ...

total :: (Integer -> Integer) -> (Integer -> Integer)

total f = \n -> sum (map f [0..n])

--
-- Solution 11.9
-- 

-- \y x -> f x y

--
-- Solution 11.10
-- 

flip :: (a -> b -> c) -> (b -> a -> c)

flip f = \y x -> f x y

--
-- Solution 11.11
-- 

comp2' :: (a -> b) -> (b -> b -> c) -> (a -> a -> c)

comp2' f g x y = g (f x) (f y)

total' :: (Integer -> Integer) -> (Integer -> Integer)

total' f n = sum (map f [0..n])

--
-- Solution 11.12
-- 

-- map (+1) . filter (=>0)

prop_map_filter :: [Integer] -> Bool

prop_map_filter xs
  = (map (+1) . filter (>=0)) xs == (filter (>0). map (+1)) xs

--
-- Solution 11.13
-- 

mapFuns' :: [a -> b] -> a -> [b]

mapFuns' fs x = map ($ x) fs

--
-- Solution 11.14
-- 

-- Can get their types using :type in ghci

-- effects are as the ordinary versions, except that they take two arguments
-- in a pair

--
-- Solution 11.15
-- 

-- The best way to see what these functions do is to find out their
-- types using :type in ghci. Once you know the type, their behaviour is
-- predictable.

-- also look at uncurry curry

--
-- Solution 11.16
-- 

-- Could try this ...

prop_curries :: ([Integer],[Integer]) -> Bool

prop_curries ps
  = unzip (uncurry zip ps) == ps

-- but it's falsified if the two lists of different length, so need
-- to include ... || length (fst ps) /= length (snd ps)

--
-- Solution 11.17
-- 

curry3 :: ((a,b,c) -> d) -> (a -> b -> c -> d)

curry3 g x y z = g (x,y,z)

uncurry3 :: (a -> b -> c -> d) -> ((a,b,c) -> d) 

uncurry3 f (x,y,z) = f x y z

-- Can *almost* do it with repreated (un)curry

-- *Solutions11> :type (curry.curry)
-- (curry.curry) :: (((a, b), b1) -> c) -> a -> b -> b1 -> c
-- *Solutions11> :type (uncurry.uncurry)
-- (uncurry.uncurry) :: (a -> b1 -> b -> c) -> ((a, b1), b) -> c

-- but we need to convert to and from ((x,y),z) and (x,y,z)

convTo :: ((a,b),c) -> (a,b,c)

convTo ((x,y),z) = (x,y,z) 

convFrom :: (a,b,c) -> ((a,b),c)

convFrom (x,y,z) = ((x,y),z) 

-- and convert functions with these arguments by pre-composing with conversion functions:

curry3' = (curry.curry) . (.convTo)

uncurry3' = (.convFrom) . (uncurry.uncurry)

-- It's really helpful to have type checking in ghci to check out your attempts.

--
-- Solution 11.18
-- 

-- need to turn the function [a] -> d to (a,[a]) -> d as can then use curry;
-- to do that need to compose uncurry (:) with that function:

curryList :: ([a] -> d) -> (a -> [a] -> d)

curryList = curry . (. uncurry (:))

-- uncurry gives us a function ((a,[a]) -> d) and we can convert that
-- to (a -> [a] -> d) by composing with a function that takes head and
-- tail of the input list (it's an inverse to uncurry (:) in fact)

uncurryList :: (a -> [a] -> d) -> ([a] -> d)  

uncurryList = (. (\xs -> (head xs, tail xs))) . uncurry

-- I hve used "point free" definitions here (p 251): it may be clearer to start 
-- with more constructive definitions using more arguments for the function
-- and its arguments, as in definitions of curry and uncurry.

--
-- Solution 11.19,20
-- 

-- Straightforward

-- iter succ n is the same as (+n)

--
-- Solution 11.21
-- 

iter' :: Integer -> (a -> a) -> a -> a

iter' n f = foldr (.) id [f | x<-[1..n]]

--
-- Solution 11.22
-- 

-- 11.13 does this already. 

--
-- Solution 11.23
-- 

-- The numerical analysis underlying these solutions is minimal.
-- Caveat emptor.

slope :: (Float -> Float) -> (Float -> Float)

slope f r = (f (r+delta) - f r) /delta
            where
            delta = 10**(-6) * r 

--
-- Solution 11.24
-- 

integrate :: (Float -> Float) -> (Float -> Float -> Float)

integrate f lower upper
  = delta * sum (map f [lower, lower+delta .. upper])
    where
    delta = 10**(-3)*(lower+upper)

--
-- Solutions 11.26-35
-- 

-- You can use QuickCheck to check properties involving functions if
-- you include the module QCfuns. Details on p502 of the book. Need to 
-- include the types so that polymorphic types don't default to ().
-- Another treatment given on p259.

-- Some examples ...

prop_id f x = (f.id) x == (f::Int-> Bool) x

prop_concat f xs
  = concat (map (map f) xs) == map (f::Int-> Int) (concat xs)

--
-- Solutions 11.26-36
-- 

-- This is only correct if p and q are defined for all elements of the original
-- list. The correct property is 
--       filter p (filter q xs) == filter (q &&& p) xs
-- so that q is applied before p. Think of
--    q = const False
--    p = const undef
-- where undef = undef


