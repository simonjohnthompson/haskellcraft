------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions17
--
------------------------------------------------------------------------------

module Solutions17 where

import Chapter17 hiding (primes,sieve)
import Data.List ((\\))
import ParseLib
import Solutions10 (subList)

--
-- Solution 17.1
--

-- Standard calcuation.

--
-- Solution 17.2
--

subLists :: [a] -> [[a]]

subLists [] = [[]]

subLists (x:xs)
  = subxs ++ [ (x:ys) | ys<-subxs ]
    where
    subxs = subLists xs

-- Quite different solution for subSequences ...

subSequences :: [a] -> [[a]]

subSequences xs = [ take n (drop m xs) | m<-[0..length xs -1], n<-[0..length xs -m]]

--
-- Solution 17.3
--

-- Standard calculation.

--
-- Solution 17.4
--

scalarProduct' xs ys = sum (zipWith (*) xs ys)

--
-- Solution 17.5
--

-- It's a matter of translating the recursive formulation of determinant
-- calculation into Haskell notation. Need to do some list manipulation to
-- extract sub-matrices etc.

--
-- Solution 17.6
--

-- [ e | v<-[], ....] 
--      ---> []
-- [ e | v<-(x:xs), q1, q2, ... ] 
--      ---> [e | q1[x/v], q2[x/v], ... ] ++ [ e | v<-xs, q1, q2, ... ]

-- where write e[x/v] for "e wth x substituted for v"

--
-- Solution 17.7
--

-- Can replace ... (x:xs)<-lExp ... by
--     ... ws<-lExp, ws/=[], x<-[head ws], xs<-[tail ws] ...

--
-- Solution 17.8
--

-- I have avoided defining auxiliry functions by using lambda expressions.

ans1    = map (\m -> m*m) [1..10]
ans2    = map (\m -> m*m) (filter (\m -> m*m<50) [1..10])
ans3    = concat (map (\x -> map (\y -> x+y) (filter (\y -> x>y) [2..4])) [1..4])
ans4 xs = concat (map (\x -> map (\p -> x:p) (perms (xs\\[x]))) xs )

--
-- Solution 17.9
--

-- Calculation. The calculation shows how the definition is unsuitable.

--
-- Solutions 17.10-22
--

-- See SolutionsParsing.hs

--
-- Solution 17.23
--

factorial :: [Integer]

factorial = 1 : zipWith (*) factorial [2..]

fibonacci :: [Integer]

fibonacci = 1 : 1 : zipWith (+) fibonacci (tail fibonacci)

--
-- Solution 17.24
--

factors :: Integer -> [Integer]

factors n = [ m | m<-[1..n], n `rem` m == 0]

primes :: [Integer]

primes = sieve [2..]

sieve (x:xs) = x : sieve [ y | y<-xs, y `rem` x /= 0 ]

primeFactors ::  Integer -> [Integer]

primeFactors n = factors n `ascendingIntersection` primes

ascendingIntersection :: [Integer] -> [Integer] -> [Integer]

ascendingIntersection xs [] = []

ascendingIntersection [] ys = []

ascendingIntersection (x:xs) (y:ys) 
  | x<y               = ascendingIntersection xs (y:ys) 
  | y<x               = ascendingIntersection (x:xs) ys
  | otherwise         = x : ascendingIntersection xs ys 

hamming1 :: [Integer]

hamming1 = [ n | n<-[2..], subList (primeFactors n) [2,3,5] ]

--
-- Solution 17.25
--

runningSums :: [Integer] -> [Integer]

runningSums xs
  = 0 : zipWith (+) xs (runningSums xs) 

--
-- Solution 17.26
--

infiniteProduct :: [a] -> [b] -> [(a,b)]

infiniteProduct (x:xs) zs
  = interleave (map (\b -> (x,b)) zs)
               (infiniteProduct xs zs)

-- interleave two infinite lists

interleave :: [a] -> [a] -> [a]

interleave (x:xs) ys
  = x : interleave ys xs

--
-- Solution 17.27
--

powers2 :: [Integer]

powers2 = 1 : zipWith (*) powers2 twos

twos = 2 : twos

--
-- Solution 17.28
--

-- It depends. If you know that there are infinitely many of them, then
-- just filter them out ...

runningPosSums :: [Integer] -> [Integer]

runningPosSums = runningSums . filter (>0)

--
-- Solution 17.29
--

merge :: Ord a => [a] -> [a] -> [a]

-- assumes that the lists sorted in (strict) ascending order

merge (x:xs) (y:ys)
  | x<y      = x : merge xs (y:ys)
  | x==y     = x : merge xs ys -- removes duplicates
  | x>y      = y : merge (x:xs) ys

--
-- Solution 17.30
--

-- Fibs see 17.23

hamming2 :: [Integer]

hamming2 = 1 : ((map (*2) hamming2
                `merge`
                map (*3) hamming2)
                `merge`
                map (*5) hamming2)

--
-- Solution 17.31
--

-- both sides are undef

--
-- Solution 17.32
--

-- The induction step isn't valid.

--
-- Solution 17.33
--

-- Induction over n

--
-- Solution 17.34
--

-- [0..] is infinite, and map preserves the structure of a list.

-- facs is more complex, but the point is that it is "productive" in that each 
-- step produces one more element of the list

--
-- Solution 17.35
--

-- Induction over n

--
-- Solution 17.36
--

-- Induction over the list argument.

