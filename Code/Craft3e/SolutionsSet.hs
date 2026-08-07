-------------------------------------------------------------------------
-- 
--         SolutionsSet.hs  
--
--         ADT of sets, implemented as ordered lists without repetitions.   
--  
--         (c) Addison-Welsey, 1996-2011.                   
--        
---------------------------------------------------------------------------

module SolutionsSet ( Set ,
  empty              , -- Set a
  sing               , -- a -> Set a
  memSet             , -- Ord a => Set a -> a -> Bool
  union,inter,diff   , -- Ord a => Set a -> Set a -> Set a
  eqSet              , -- Eq a  => Set a -> Set a -> Bool
  subSet             , -- Ord a => Set a -> Set a -> Bool
  makeSet            , -- Ord a => [a] -> Set a
  mapSet             , -- Ord b => (a -> b) -> Set a -> Set b
  filterSet          , -- (a -> Bool) -> Set a -> Set a
  foldSet            , -- (a -> b -> b) -> b -> Set a -> b
  showSet            , -- (a -> String) -> Set a -> String
  card               , -- Set a -> Int
  setUnion,setInter    -- Ord a => Set (Set a) -> Set a

  ) where

import Data.List hiding ( union )
--  
-- Instance declarations for Eq and Ord                 

instance Eq a => Eq (Set a) where
  (==) = eqSet

instance Ord a => Ord (Set a) where
  (<=) = leqSet

-- The implementation.                      
--              
newtype Set a = Set [a]

empty :: Set a
empty  = Set []

sing :: a -> Set a
sing x = Set [x]

memSet :: Ord a => Set a -> a -> Bool
memSet (Set []) y    = False
memSet (Set (x:xs)) y 
  | x<y     = memSet (Set xs) y
  | x==y    = True
  | otherwise   = False

union :: Ord a => Set a -> Set a -> Set a
union (Set xs) (Set ys) = Set (uni xs ys)

uni :: Ord a => [a] -> [a] -> [a]
uni [] ys        = ys
uni xs []        = xs
uni (x:xs) (y:ys) 
  | x<y     = x : uni xs (y:ys)
  | x==y    = x : uni xs ys
  | otherwise   = y : uni (x:xs) ys

inter :: Ord a => Set a -> Set a -> Set a
inter (Set xs) (Set ys) = Set (int xs ys)

int :: Ord a => [a] -> [a] -> [a]
int [] ys = []
int xs [] = []
int (x:xs) (y:ys) 
  | x<y     = int xs (y:ys)
  | x==y    = x : int xs ys
  | otherwise   = int (x:xs) ys

--
-- Solution 16.36
--

diff :: Ord a => Set a -> Set a -> Set a
diff (Set xs) (Set ys) = Set (dif xs ys)

dif :: Ord a => [a] -> [a] -> [a]
dif [] ys = []
dif xs [] = xs
dif (x:xs) (y:ys)  
  | x<y     = x : dif xs (y:ys)
  | x==y    = dif xs ys
  | otherwise   = dif (x:xs) ys

subSet :: Ord a => Set a -> Set a -> Bool
subSet (Set xs) (Set ys) = subS xs ys

subS :: Ord a => [a] -> [a] -> Bool
subS [] ys = True
subS xs [] = False
subS (x:xs) (y:ys) 
  | x<y     = False
  | x==y    = subS xs ys
  | x>y     = subS (x:xs) ys

eqSet :: Eq a => Set a -> Set a -> Bool
eqSet (Set xs) (Set ys) = (xs == ys)

leqSet :: Ord a => Set a -> Set a -> Bool
leqSet (Set xs) (Set ys) = (xs <= ys)

--          
makeSet :: Ord a => [a] -> Set a
makeSet = Set . remDups . sort
          where
          remDups []     = []
          remDups [x]    = [x]
          remDups (x:y:xs) 
        | x < y     = x : remDups (y:xs)
            | otherwise = remDups (y:xs)

mapSet :: Ord b => (a -> b) -> Set a -> Set b
mapSet f (Set xs) = makeSet (map f xs)

filterSet :: (a -> Bool) -> Set a -> Set a
filterSet p (Set xs) = Set (filter p xs)

foldSet :: (a -> b -> b) -> b -> Set a -> b
foldSet f x (Set xs)  = (foldr f x xs)

showSet :: (a->String) -> Set a -> String
showSet f (Set xs) = concat (map ((++"\n") . f) xs)

card :: Set a -> Int
card (Set xs)     = length xs

--  
-- Solution 16.37
--

-- can define using diff, or can define recursively (exercise)

symmDiff :: Ord a => Set a -> Set a -> Set a

symmDiff x y = diff x y `union` diff y x

--  
-- Solution 16.38
--

-- could define this using foldSet if it was given a more general type
--     (a -> b -> b) -> b -> Set a -> b

powerSet :: Ord a => Set a -> Set (Set a)

powerSet = foldSet extraElem (sing empty)

-- given a set of sets (sets) and an element x, returns a new set of sets
-- built by taking the union of the original with a new set created
-- by adding the element to each of the sets in the set of sets.

extraElem :: Ord a => a -> Set (Set a) -> Set (Set a)

extraElem x sets
  = sets `union` mapSet (union (sing x)) sets

-- 
-- Solution 16.39
--

setUnion :: Ord a => Set (Set a) -> Set a

setUnion = foldSet union empty

-- setInter similarly, but need a value for the intersection of an empty 
-- set of sets, which is the "universe" of sets. Alternatively, just 
-- define for non-empty sets:

setInter :: Ord a => Set (Set a) -> Set a

setInter (Set (x:xs)) = foldSet inter x (Set xs)

--  
-- Solution 16.40
--

-- No. Need to do something more symbolic to e.g. represent ranges, but
-- in general there's no way of doing this.

--  
-- Solution 16.41
--

-- Can do everything with unordered lists that can do with ordered ones.
-- Will need Eq a in the context of some functions, e.g. mapSet, so that
-- duplicates can be eliminated.

-- Functions fine as far as knowing about single elements, also OK with filter
-- set but difficult for map and fold; also for show. In all cases can sort out
-- by maintaining an "upper bound" on the elements, or a list to which the elements
-- belong.

--  
-- Solution 16.42
--

-- Pretty straightforward: all the operations you need are defined.

--  
-- Solution 16.43
--

-- Ordered lists are simpler to implement, but substantially slower for e.g. 
-- lookup of membership than search trees. See Chapter 20 for further discussion of
-- this.

--  
-- Solution 16.44
--

-- This implementation should satisfy rules like this

prop_sets1 :: Ord a => Set a -> Set a -> Set a -> Bool

prop_sets1 x y z 
  = eqSet (x `union` (y `inter` z)) ((x `union` y) `inter` (x `union` z))

-- these really are the traditional "laws" of finite set theory.






