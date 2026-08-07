------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions10
--
------------------------------------------------------------------------------

module Solutions10 where

import Chapter10 hiding (map,filter,and,foldr,foldr1,zipWith)
import Test.QuickCheck
import Prelude hiding (length,last,init)
import Pictures hiding (invertColour,superimpose)

--
-- Solution 10.2
-- 

length xs
  = sum (map f xs)
    where
    f x = 1::Int

--
-- Solution 10.3
-- 

addUp ns = map addOne (filter greaterZero ns)

addOne n = n+1
greaterZero n = n>0

--
-- Solution 10.4
-- 

-- map f (map g xs) applies g to all elements and then f to all results; same as
-- applying (f.g) to all elements, ie map (f.g) xs

--
-- Solution 10.5
-- 

-- filter p (filter q xs) : first pick out all the elements with property q, then
-- those with property p. Same as filter pAndq xs, where

--       pAndq x = q x && p x

-- Why this way round? && evaluates its left argument first, so does the q test 
-- first, and only does the p test if q is true: if q is false p could be undefined
-- and that's not detected: would be different if p and q in the other order.

--
-- Solution 10.6
-- 

squareAll :: [Integer] -> [Integer]

squareAll ns = map square ns

square :: Integer -> Integer

square n = n*n

sumSquares :: [Integer] -> Integer

sumSquares ns = sum (squareAll ns)

allG0 :: [Integer] -> Bool

allG0 ns = and (map greaterZero ns)

--
-- Solution 10.7
-- 

-- minimum of values f 0, .. , f n

miniFun :: (Integer -> Integer) -> Integer -> Integer

miniFun f n = minimum (map f [0..n])

-- are f 0, .. , f n all equal?

allEq :: (Integer -> Integer) -> Integer -> Bool

allEq f n = and (map eqf [0..n])
            where
            eqf m = (f 0 == f m)

-- are f 0, .. , f n all greater than zero?

allValsG0 :: (Integer -> Integer) -> Integer -> Bool

allValsG0 f n = and (map greaterZero (map f [0..n]))

-- are f 0, .. , f n in ascending order

ascOrder :: (Integer -> Integer) -> Integer -> Bool

ascOrder f n = and (map ord (zip (map f [0..(n-1)]) (map f [1..n])))
               where
               ord (x,y) = x<=y

--
-- Solution 10.8
-- 

twice :: (Integer -> Integer) -> Integer -> Integer

twice f x = f (f x)

-- most general type is
--      (a -> a) -> a -> a

--
-- Solution 10.9
-- 

iter :: Integer -> (Integer -> Integer) -> Integer -> Integer

iter 0 f x = x
iter n f x 
  | n>0    = f (iter (n-1) f x)

-- most general type is
--      Integer -> (a -> a) -> a -> a

--
-- Solution 10.10
-- 

exp :: Integer -> Integer

exp n = iter n double 1
        where
        double m = 2*m

--
-- Solution 10.11
-- 

-- All elements in the result have the property p:

prop_filter1 :: (Integer -> Bool) -> [Integer] -> Bool

prop_filter1 p xs 
  = and (map p (filter p xs))

-- The result should be a sub-list of the original: the
-- function subList is from Solutions7, but here redefined
-- with a more general type:

prop_filter2 :: (Integer -> Bool) -> [Integer] -> Bool

prop_filter2 p xs 
  = subList (filter p xs) xs

subList :: Eq a => [a] -> [a] -> Bool

subList [] xs     = True
subList (x:xs) [] = False
subList (x:xs) (y:ys)
  = (x==y && subList xs ys) ||
    subList (x:xs) ys

--
-- Solution 10.12
-- 

-- Expect that mapping f then g, and g then f will give back the input list.

--
-- Solution 10.13
-- 

sumSquares' :: Integer -> Integer

sumSquares' n = foldr (+) 0 (map square [0..n])

--
-- Solution 10.14
-- 

sumSquaresPos :: [Integer] -> Integer

sumSquaresPos ns = foldr (+) 0 (map square (filter greaterZero ns))

--
-- Solution 10.15
-- 

unZip :: [(a,b)] -> ([a],[b])

unZip ps = foldr addEls ([],[]) ps
           where
           addEls (x,y) (xs,ys) = (x:xs,y:ys)

-- last and init are problematic: if we can use xs as well as x and f xs in describing
-- f (x:xs) then it's straightforward. A general way of doing this is to have the
-- value at each point be a function, or we can return xs together with f xs. We can also 
-- use ad hoc tricks as in last

last :: [a] -> a

last xs = head (foldr cons1 [] xs)
          where
          cons1 a [] = [a]
          cons1 a ys = ys

-- here we return xs with f xs, so that we can use it in defining the value of the 
-- function at x:xs.

init :: [a] -> [a]

init xs = fst (initAux xs)

initAux :: [a] -> ([a],[a])

initAux xs = foldr addEl ([],[]) xs
             where
             addEl x (ys,[]) = ([],[x])
             addEl x (ys,zs) = (x:ys, x:zs)

--
-- Solution 10.16
-- 

prop_mystery :: [Integer] -> Bool

prop_mystery xs
  = foldr (++) [] (map sing xs) == xs
    where 
    sing x = [x]

--
-- Solution 10.17
-- 

formatList :: (a -> String) -> [a] -> String

formatList fmt st = foldr (++) [] (map fmt st)

-- formatLines lines = formatList formatLine lines

--
-- Solution 10.18
-- 

filterFirst :: (a -> Bool) -> [a] -> [a]

filterFirst p [] = []
filterFirst p (x:xs)
  | not (p x)   = xs
  | otherwise   = x: filterFirst p xs

--
-- Solution 10.19
-- 

-- The most straightforward definition is ...

filterLast :: (a -> Bool) -> [a] -> [a]

filterLast p xs = reverse (filterFirst p (reverse xs))

-- ... can also do by a recursion which checks whether anything in the
-- tail hasn't got property p.

--
-- Solution 10.20
-- 

switchMap :: (a -> b) -> (a -> b) -> [a] -> [b]
switchMap f g [] = []
switchMap f g (x:xs) = f x : switchMap g f xs

-- switching the arguments in the recursive call is the nestest way of doing this:
-- could also have a boolean flag, or two functions defined by mutual recursion, as 
-- in the next question.

--
-- Solution 10.21
-- 

split, split' :: [a] -> ([a],[a])

split []     = ([],[])
split (x:xs) = (x:ys,zs)
                where
                (ys,zs) = split' xs

split' []     = ([],[])
split' (x:xs) = (ys,x:zs)
                 where
                 (ys,zs) = split xs  

merge :: ([a],[a]) -> [a]

merge ((x:xs),ys) = x : merge (ys,xs)
merge ([],    ys) = ys

--
-- Solution 10.22
-- 

prop_merge_split :: [Integer] -> Bool

prop_merge_split xs
  = merge (split xs) == xs

-- doesn't work in the other order, unless the lists are of the same length.

--
-- Solution 10.23
-- 

-- here's the case for addition over numbers, need to ensure that the property itself
-- is only checked for non-empty ns and ms

prop_plus_assoc :: [Integer] -> [Integer] -> Bool

prop_plus_assoc ns ms
  = ns==[] || ms==[] || foldr1 (+) (ns ++ ms) == (foldr1 (+) ns) + (foldr1 (+) ms) 

-- Need s to be a "zero" for the operation: for (+) then 0 is the element.

--
-- Solution 10.24
-- 

dropUntil :: (a -> Bool) -> [a] -> [a]
dropUntil p []    = [] 
dropUntil p (x:xs) 
  | p x         = x:xs
  | otherwise   = dropUntil p xs

-- Test using this, applied to suitable predicates such as (>0) etc.

prop_drop_get :: (Integer -> Bool) -> [Integer] -> Bool

prop_drop_get p xs
  = xs == getUntil p xs ++ dropUntil p xs

--
-- Solution 10.25
-- 

-- Use the predicate nonWhiteSpace

-- Use the negation of the property

--
-- Solution 10.26
-- 

-- predicates are eol and its negation

eol ch = ch=='\n'

--
-- Solution 10.27-28
-- 

--      getLine :: Int -> [[a]] -> [[a]]
-- test becomes p :: Int -> a -> Bool and so
--      getLine' :: (Int -> a -> Bool) -> Int -> [a] -> [a]
-- because no need to know that the elements of the list are
-- themselves lists

--
-- Solution 10.29
-- 

invertColour :: Picture -> Picture

invertColour pic = map (map invert) pic

--
-- Solution 10.30
-- 

superimpose :: Picture -> Picture -> Picture

superimpose pic1 pic2
  = zipWith (zipWith super) pic1 pic2
    where
    super '#' _ = '#'
    super _   x = x

-- This solution cuts down to the smaller line / picture in each aplication of
-- zipWith. To avoid this need to pad the pictures to start with, or use the 
-- alternative definition (with a more limited type, as indicated):

zipWith' :: (a -> a -> a) -> [a] -> [a] -> [a]

zipWith' f (x:xs) (y:ys) = f x y : zipWith' f xs ys
zipWith' f xs []         = xs
zipWith' f [] ys         = ys

--
-- Solution 10.31
-- 

rotate90 :: Picture -> Picture

rotate90 pic 
  = map extract [length pic -1, length pic -2 .. 0]
    where 
    extract i = map (!!i) pic

--
-- Solutions 10.32-27
-- 

-- All straightforward exercises. List comprehensions are good when you're just running 
-- through a list, but map, filter etc are more general. On the other hand multiple-
-- generator list comprehensions in Chapter 17 show how multiple generators and filters
-- togther give a powerful notation.

-- All is mad simpler when we look at partial application in the next chapter, so worth
-- perhaps postpoining these exercises until then. In fact I have cheated a bit here in
-- using expressions like (!!i) in 10.31 above; mea cupla.








