------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions20
--
------------------------------------------------------------------------------

module Solutions20 where

import Data.List

{-

-- 
-- Solution 20.1
--

f is O(n^2): choose d=8, m=10, and check that f n <= 8* n^2 for n>=10

n^2 is O(f): d=n=1 will do the trick.

-- 
-- Solution 20.2
--

Can write a funcition in Haskell to complete this table. 

Completing the table gives some indication of how these functions grow.

-- 
-- Solution 20.3
--

f1: choose d=1032, m= 35
f1: choose d=1032, m=35 and then d=m=1

-- 
-- Solution 20.4
--

Not completely straightforward: can use the power series expansion to prove this. Here's
a reference:

  http://www.math.5u.com/The%20function%20ex%20grows%20faster%20than%20any%20power%20of%20x.htm

-- 
-- Solution 20.5
--

log_a x = log_a b * log_b x

so they all grow at the same rate.

-- 
-- Solution 20.6
--

Show that 2^n is O(fib n)

-- 
-- Solution 20.7
--

Just need to get the constants in the definition to balance.

-- 
-- Solution 20.8
--

Just adjust d to get the first result.

For sum and difference choose sum the constants chosen.

Won't preserve Theta, as may cancel out the leading terms, e,g. if
f and g are equal, then f-g is constant zero. 

-- 
-- Solution 20.9
--

Multiply d's and take the max of the m's.

-- 
-- Solution 20.10
--

These are standard induction proofs, in any mathematical text.

-- 
-- Solution 20.11
--

Quadratic, as xs++ys is proportional to the length of xs.
so in the recursive calls get 

 1 + 2 + 3 + ... + (n-1)
which is approx n^2/2.

In the second case, it's linear.

-- 
-- Solution 20.12
--

The first is linear in m.

The second is logarithmic, as at each stage the second argument is halved.

-- 
-- Solution 20.13
--

Exponential< as the call to fib (n+1) generates two calls to fib (n-1), one
directly, and the other via fib n.

-- 
-- Solution 20.14
--

Top level call: one list
Second layer: lists have half the length, two merges of length n/2: total is n
...
log n layers, so in total have n*(log n).

-- 
-- Solution 20.15
--

lists:
- memSet: need to search on average half the length, so O(n)
- subSet: it's memSet times the number in the subset: so quadratic.
- inter: linear in each member of the LHS set: for each linear in size of the RHS, 
  so quadratic.
- makeSet: trivial
- mapSet: linear, just run along the list.

ordered lists:
- memSet: same as lists
- subSet: linear traversal through the two lists, so linear
- inter: as for subset
- makeSet: the complexity of sorting O(n(log n))
- mapSet: linear traversal but need to sort the result, so as for makeSet

-- 
-- Solution 20.16
--

search trees: average makes the assumption that trees are balanced, and so
can expect that the average depth of the trees is log n, if the tree has n nodes.

- memSet: need to, on average, descend half way down a branch, so logarithmic
- subSet: need to iterate memSet n times, so n(log n)
- inter: similarly to subSet
- makeSet: requires the search tree to be built: on average insertion requires 
  log n steps
- mapSet: it's the tree construction which dominates here, as for ordered lists above.

-- 
-- Solution 20.17
--

- memSet: linear, same as lists
- subSet: as for lists
- inter: as for lists
- makeSet: the complexity of sorting O(n(log n)), as could sort with duplicate removal.
- mapSet: linear traversal but need to remove duplicates from the result, so as for makeSet

-- 
-- Solution 20.18
--

Lazy evaluation might be expected to imply that this takes constant space:
just generate enough of the list to get the next summand, but in fact will be 
linear, creating expression 0+1+2...+n before evaluating it. So, linear.

-- 
-- Solution 20.19
--

getting and dropping are linear, assuming that spaces occur regularly; if not, then
might be able to infer a smaller bound.

-}

-- 
-- Solution 20.20
--

-- Standard translations.

-- Assume that digits in *ascending* order of significance

diglistToNum1 :: String -> Int

diglistToNum1 = foldr (\ ch x -> (fromEnum ch - zero) +10*x) 0
                where
                zero = fromEnum '0'
       
-- Assumes that digits in *descending* order

diglistToNum2 :: String -> Int

diglistToNum2 = foldl' (\ x ch -> (fromEnum ch - zero) +10*x) 0
                where
                zero = fromEnum '0'
       
-- The latter will be more efficient.

-- 
-- Solution 20.21
--

-- Similar translation of sorting. However, it's less clear which is
-- more efficient as this depends on the *context* in which it is called.
-- For instance, can call head.sort to get the least element of a list, 
-- and in this case the foldr example will only calculate the head, whereas
-- the foldl' version will calculate the whole list, irrespective of how it 
-- is used.

-- 
-- Solution 20.22
--

-- Can see the relationship in digListToNum1 and digListToNum2

-- diglistToNum1 xs = foldr fun 0 xs
-- diglistToNum2 xs = foldl' (flip fun) 0 (reverse xs)

-- 
-- Solution 20.23
--

-- get equality: don't need to worry about flip and reverse 
-- when a==b and these properties hold.

-- 
-- Solution 20.24-6
--

-- Find the first matching pair in the lists, and iterate.
-- Question of what is meant by "first": we're searching through
-- pairs of indices I and j: should we fix (e.g.) i and then run 
-- through all j, or go by order of (i+j), pushing a "fringe"
-- through the space? 

-- Let's go for that.

dropPairs :: [a] -> [a] -> [([a],[a])]

dropPairs xs ys 
  = [ (drop i xs, drop (t-i) ys) | t <-[0..lenT-1], i<-[0..lenX] ]
    where
    lenX = length xs
    lenY = length ys
    lenT = lenX + lenY

fstMatch :: Eq a => [a] -> [a] -> Maybe ([a],[a]) 

fstMatch xs ys 
  = if res==[] 
       then Nothing
       else Just (head res)
    where
    res = [ ((x:xs),(y:ys)) | ((x:xs),(y:ys)) <- dropPairs xs ys, x==y ]

matches xs ys 
  | isNothing        = []
  | otherwise        = head zs : matches (tail zs) (tail ws)
    where
    res = fstMatch xs ys
    isNothing = (res==Nothing)
    Just (zs,ws) = res


-- 
-- Solution 20.25
--

-- The idea here is to bring together values which collectively can
-- be used to define the "next" value.

-- In, the case of fib, value at (n+1) needs values at n and (n-1), so
-- the best thing is to pair these up: from here it's easy to calculate
-- fib (n+1) (and fib n).

-- What are the similar data for mLen? value at (x:xs,y:ys) uses the values 
-- at (xs,ys), (x:xs,ys), (xs,y:ys) and so could return these four values:

--                        mLen (x:xs) (y:ys)   mLen xs (y:ys)
--                        mLen (x:xs)    ys    mLen xs    ys

-- and calculate subsequent values from these.

-- 
-- Solution 20.26
--

-- Straightforward application of these techniques: nice to memoise 
-- into a two-diminsional table.

-- 
-- Solution 20.27
--

-- Beef up the mLen algorithm to handle lines, and format the output in 
-- a particular way.