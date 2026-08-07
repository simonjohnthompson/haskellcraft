------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  SolutionsRelation
--
------------------------------------------------------------------------------

module SolutionsRelation where

import Relation
import Set
import Data.List

--
-- Solutions 16.45,46
--

-- Standard calculations.

--
-- Solution 16.47
--

graph1 = makeSet [ (1,2), (1,3), (3,2), (3,4), (4,2), (2,4) ]

-- Would like to write something like this, but it fails to give an
-- answer if there is no route from x to y.

distance' :: Ord a => Relation a -> a -> a -> Int

distance' graph x y 
  | x==y       = 0
  | otherwise  = 1 + minimum [ distance' graph z y | z<- flatten (image graph x) ]

-- Instead need to work with the model of breadthFirst:

circles :: Ord a => Relation a -> a -> [[a]]

circles rel val 
  = iter step start
    where
    start = [val]
    step xs = xs ++ nub (concat (map (findDescs rel xs) xs))

iter step start
  | start==next         = [start]
  | otherwise           = start : iter step next
                          where
                          next = step start

distance graph x y 
  | elem y accessible = firstOcc y circs
  | otherwise         = 0
    where
    firstOcc y circs = if elem y (head circs)
                          then 0
                          else 1 + firstOcc y (tail circs)
    circs = circles graph x
    accessible = last circs                     

--
-- Solution 16.48
--

-- Need a new model, so that Relation a won't work. Need something like
--   Edge a b = Set (a,b,a)
-- with consequent need to define new library functions over this representation.

-- Alternatively could stick with Relation a as a model, but additionally have 
-- something giving the weights. This could be a function
--   weight :: (a,a) -> Weight
-- or a list of edge, weight pairs. This latter is pretty ugly, though, as it
-- duplicates much of the representation in Set (a.a).

-- Need to modify the algorithm to keep on looking for shorter paths from a to b
-- even one ath has been found. Can only stop the search for shorter paths when 
-- no new nodes visited in an iteration. Therefore model on the solution for 
-- depthSearch.

--
-- Solution 16.49
--

type BinaryRel a b = [(a,b)] -- could hide in abstyoe Set (a,b)

-- Some functions carry over, e,g. finding image. Others don't, because with different
-- domain and range types it's not as easy to iterate things. Do get relational 
-- composition, like this

relCompos :: Eq b => BinaryRel a b -> BinaryRel b c -> BinaryRel a c

relCompos rel1 rel2
  = [ (x,z) | (x,y) <- rel1, (y',z)<-rel2, y==y' ]

--
-- Solution 16.50
--

-- Search functions produce lists of elements.
-- If y is accessible from x, and z from y, then z accessible from x.
-- triangle inequality:
--     distance x z <= distance x y + distance y z
-- (for cases where they are all >0, ie all paths x->y, y->z exist.)

-- breadth first: if y before z in list below x then distance from
-- x to y is <= distance from x to z

-- depth first: what characterises this? Not clear.

 
