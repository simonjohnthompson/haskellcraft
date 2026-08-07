------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions15
--
------------------------------------------------------------------------------

module Solutions15 where

import Types

--
-- Solution 15.1
--

-- It is always possible to limit what is imported from a particular
-- module through import controls, but that doesn't prevent a client of 
-- the imported module importing anything from the client, if no export
-- controls are in place.

-- On the other hand, export controls are needed for re-export of imported
-- definitions, which are not re-exported by default.

-- Export controls have an annoying limitation: it's not possible to hide
-- particular bindings explicitly on export, rather have to have a whole export
-- list which excludes the binding(s) in question, but which has to include
-- everything else.

--
-- Solution 15.2
--

-- It's the right default: can always re-export, but if everything re-exported a
-- automatically it's harder to look at a module and see where the definitions it 
-- uses come from. As it stands, a definition will be in one of the modules included,
-- or explicitly re-exported from one of those.

-- Also auto re-export would possibly pollute the name space with bindings we don't
-- want to be aware of.

--
-- Solution 15.3
--

-- More brevity. Why not? Could have to check consistency: what if we say "no Dog"
-- but something imported from Dog is explicitly exported?

--
-- Solution 15.4
--

-- LRLRRRRRLRR

--
-- Solution 15.5
--

-- babbat

-- would expect that the shortest is with b coded by a single letter; using the
-- tree in 15.4 get the coding LRLLLRLRR: 9 chars rather than 10.

--
-- Solutions 15.6-7
--

-- Just walk through the definitions

--
-- Solution 15.8
--

mergeSort :: Ord a => [a] -> [a]

mergeSort [] = []

mergeSort [x] = [x]

mergeSort xs 
  = mergeOrd (mergeSort left) (mergeSort right) 
    where
    (left,right) = splitAt (length xs `div` 2) xs

mergeOrd :: Ord a => [a] -> [a] -> [a]

mergeOrd [] ys = ys
mergeOrd xs [] = xs
mergeOrd (x:xs) (y:ys)
  | x<y        = x : mergeOrd xs (y:ys)
  | x==y       = x:y: mergeOrd xs ys
  | otherwise  = y : mergeOrd (x:xs) ys

--
-- Solution 15.9
--

-- change the line
--          | x==y       = x:y: mergeOrd xs ys
-- to
--          | x==y       = x: mergeOrd xs ys

--
-- Solution 15.10
--

-- assuming that x `f` y iff x<=y.

mergeSort' :: (a -> a -> Bool) -> [a] -> [a]

mergeSort' _ [] = []

mergeSort' _ [x] = [x]

mergeSort' f xs 
  = mergeOrd' f (mergeSort' f left) (mergeSort' f right) 
    where
    (left,right) = splitAt (length xs `div` 2) xs

mergeOrd' ::  (a -> a -> Bool) -> [a] -> [a] -> [a]

mergeOrd' _ [] ys = ys
mergeOrd' _ xs [] = xs
mergeOrd' f (x:xs) (y:ys)
  | x `f` y        = x : mergeOrd' f xs (y:ys)
  | otherwise      = y : mergeOrd' f (x:xs) ys

--
-- Solution 15.11
--

-- already in MakeTree.hs

--
-- Solution 15.12
--

-- Stadard calculation.

--
-- Solution 15.13
--

-- showTable is a standard layout problem.

showTree :: Tree -> String

showTreeInd :: Int -> Tree -> String

showTree = showTreeInd 0

showTreeInd n (Leaf ch int) = replicate n ' ' ++ show ch ++ ": " ++ show int ++"\n"
showTreeInd n (Node m t1 t2) = showTreeInd (n+4) t1 ++
                               replicate n ' ' ++ show n ++
                               showTreeInd (n+4) t2

--
-- Solution 15.14
--

-- Basic property to expect is that (decode.code) is the identity function, or
--       decode (code string) = string
-- But need the string to come from the elements in the code tree. Alternatively
-- can just left the coding function drop anything unrecodgnised, and then compare
-- the results of decode.code with the string with the unrecognised characters 
-- removed. This means don't have to write a special generator, but means that most
-- of the tests are effectively on the empty list.

--
-- Solution 15.15
--

sorted :: [Int] -> Bool

sorted [] = True
sorted [x] = True
sorted (x:y:zs) = x<=y && sorted (y:zs)

--
-- Solution 15.16
--

-- Pretty open-ended. Note discussion for 15.14 above. Often different ways of
-- solving the same problem.

--
-- Solution 15.17
--

-- an example is given in 15.14.

--
-- Solution 15.18
--

-- It's possible to write a property / test of whether a sequence of L's and R's is
-- a valid code. For the abt tress above, would have LL as a valid code sequence but
-- not LR, as this should be LRL or LRR. Any sequence is a valid initial segment, so 
-- can be extended to a valid code. Once that's done, then should expect that
-- code.decode is also the identity (on that subset).










