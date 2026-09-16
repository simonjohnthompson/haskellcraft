----------------------------------------------------------
--							--
--	Minesweeper.hs					--
--							--
--	Simon Thompson					--
--							--
--      2002-2011                                       --
--                                                      --
----------------------------------------------------------

{-# LANGUAGE FlexibleInstances #-}

-- NB: Requires pragma above for instance declaration of
-- non-atomic type: 
--	instance AddThree [Int] where ...

-- The board is represented by a list of lists. It is a
-- global assumption that this is rectangular, that is all
-- component lists have the same length.
-- It is also assumed that grids are nonempty.

module Minesweeper where
import MineRandom ( randomGrid )
import Data.List ( (\\) )


type Config = [[Bool]]

type Count  = [[Int]]

class AddThree a where
  add3 :: a -> a -> a -> a
  zero :: a
  addOffset :: [a] -> [a]
  addOffset = zipOffset3 add3 zero
  
instance AddThree Int where
  add3 n m p = n+m+p
  zero       = 0

instance AddThree [Int] where
  add3 = zipWith3 add3
  zero = repeat zero

-- Combine elementwise (i.e. zipWith3) the three lists:
--
--	 z,a0,a1,a2,...
--	a0,a1,a2,...,an
--      a1,a2,...,an,z
--
-- using the ternary function f
-- Example: f is addition of three numbers, z is zero.

zipOffset3 :: (a -> a -> a -> a) -> a -> [a] -> [a]

zipOffset3 f z xs = zipWith3 f (z:xs) xs (tail xs ++ [z])

-- From the grid of occupation (Boolean) calculate the
-- number of occupied adjacent squares.
-- Note that the stone in the square itself is also
-- counted.

countConfig :: [[Bool]] -> [[Int]]

countConfig = addOffset . map addOffset . makeNumeric

-- A variant of countConfig which doesn't count the stone in
-- the square itself.

countConfigLess :: [[Bool]] -> [[Int]]

countConfigLess bs 
  = zipWith (zipWith (-)) (countConfig bs) (makeNumeric bs)

-- Boolean matrix to numeric matrix; True to 1, 
-- False to 0.

makeNumeric :: [[Bool]] -> [[Int]]

makeNumeric = map (map (\b -> if b then 1 else 0))

-- A 3*3 Boolean test matrix.

test1 = [[True, False, True],[True,True,True],[False,True,True]]

-- Printing the grid

showGrid :: [[Int]] -> String

showGrid nss = "   " ++ take (length (head nss)) ['a' .. 'z'] ++ "\n" ++
             concat (zipWith f [0 .. length nss - 1] nss)
	     where
	     f n ns = pad 3 (show n) ++ concat (map show ns) ++ "\n"

pad :: Int -> String -> String

pad n st
  | len <= n		= st ++ replicate (n - len) ' ' 
  | otherwise		= take n st
    where
    len = length st

showTest1 :: IO ()

showTest1 = putStr $ showGrid $ countConfig test1

showGrid3 :: IO ()

showGrid3 = putStr $ showGrid $ map (map (\b -> if b then 1 else 0)) test3


showTest3 :: IO ()

showTest3 = putStr $ showGrid $ countConfig test3

tester3 :: IO ()

tester3 = showGrid3 >> showTest3


test3 = randomGrid 20 10 10


-- Strength of the product functor on the left

appLeft :: (a -> b) -> (a,c) -> (b,c)

appLeft f (x,y) = (f x , y)

-- Update list xs at index n to have value f (xs!!n)
-- Handles out of range indices
	     
update :: Int -> (a -> a) -> [a] -> [a]

update n f xs = front ++ rear
		where
		(front,rest) = splitAt n xs
		rear = case rest of
			[]	-> []
			(h:t)	-> f h:t
			
-- Update an array to have value x at position (n,m)			
 
updateArray :: Int -> Int -> a -> [[a]] -> [[a]]

updateArray n m x xss = update n (update m (const x)) xss

-- Show play
-- Assumes that the two arrays are of the same shape
-- The second array gives the adjacency count of the cell,
-- whilst the first indicates whether or not it is uncovered.


showPlay :: [[Bool]] -> [[Int]] -> String

showPlay ess nss = "   " ++ take (length (head nss)) ['a' .. 'z'] ++ "\n" ++
             concat (zipWith3 f [0 .. length nss - 1] ess nss)
	     where
	     f n es ns = pad 3 (show n) ++ concat (zipWith showCell es ns) ++ "\n"

-- How to show the value in a particular cell.

showCell :: Bool -> Int -> String

showCell b n = if not b then "X"
                        else if n==0 then " "
			             else show n


showTest2 :: IO ()

showTest2 = putStr $ showPlay showing (countConfig test1)

showing = [[True, False, False],[True, False, True],[True,True,True]]




playGame :: IO ()

playGame = 
   playGameGrid showing

   where

   grid      = randomGrid 20 10 10
   count     = countConfig grid			
   countLess = countConfigLess grid	-- Added 26.4.02 (superfluous)
   showing   = map (map (const False)) grid

   playGameGrid :: [[Bool]] -> IO ()

   playGameGrid showing =
     do { putStr (showPlay showing count) ;
          rowCh <- getChar ;
	  let { row = fromEnum rowCh - fromEnum '0' } ;
	  colCh <- getChar ;
	  let { col = fromEnum colCh - fromEnum 'a' } ;
	  putStr "\n" ;
	  if grid!!row!!col then do { putStr "LOST!" ; return () }
	  else
	    playGameGrid (uncoverNbhrs count [(row,col)] (row,col) showing)
	}
     
-- Transitively uncover all the neighbours of all the points in a list.
-- Repeatedly applies uncoverNbhrs

uncoverNbhrsList :: [[Int]] -> [(Int,Int)] -> [(Int,Int)] -> 
                    [[Bool]] -> [[Bool]]

uncoverNbhrsList count avoid
  = foldr (.) id . map (uncoverNbhrs count avoid)

-- Transitively uncover all the neighbours of a point.
-- First uncover the immediate neighbours, then call recursively on
-- all the neighbours with zero adjacency count.
   
uncoverNbhrs :: [[Int]] -> [(Int,Int)] -> (Int,Int) -> 
                [[Bool]] -> [[Bool]]

uncoverNbhrs count avoid (p,q)
  = uncoverNbhrsList count (avoid++nbhrs count (p,q)) 
                           (nullNbhrs count (p,q) \\ avoid) 
    .
    ( foldr (.) id $ 
      map ((flip.uncurry) updateArray True) (nbhrs count (p,q)) )

-- What are the neighbours of a point?

nbhrs :: [[Int]] -> (Int,Int) -> [(Int,Int)]

nbhrs count (p,q)
  = filter inGrid [ (p-1,q-1), (p-1,q), (p-1,q+1),
                    (p,q-1),   (p,q),   (p,q+1),
		    (p+1,q-1), (p+1,q), (p+1,q+1) ]
    where
    inGrid (s,t) = 0<=s && s <= rows &&
                   0<=t && t <= cols
    rows = length count - 1
    cols = length (head count) -1

-- What are the null nbhrs?

nullNbhrs :: [[Int]] -> (Int,Int) -> [(Int,Int)]

nullNbhrs count (p,q)
  = filter zeroVal (nbhrs count (p,q))
    where
    zeroVal (s,t) = count!!s!!t==0
    
