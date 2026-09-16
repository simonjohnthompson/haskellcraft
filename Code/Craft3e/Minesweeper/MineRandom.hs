----------------------------------------------------------
--							--
--	MineRandom.hs					--
--							--
--	Simon Thompson					--
--							--
--	2002-2011					--
--							--
----------------------------------------------------------

-- Choosing a random starting configuration for 
-- a minesweeper game.

-- Making dynamic choices: get the seed on each invocation.
-- Have to refactor choices etc. to take the seed as a parameter.

module MineRandom ( randomGrid, randomGridDyn ) where
import System.Random
import System.IO.Unsafe ( unsafePerformIO )
import Data.Time.Clock.POSIX ( getPOSIXTime )
import Data.List ( insert , nub )

-- Generate a random combination of m elements from n 
-- i.e. choice of 0, 1, ..., n-1.
-- The algorithm used makes repeated random choices until m different
-- values are found.
-- Perfectly efficient for n=100, m=40; not for 1000,400.
-- Assumes that m<=n.
-- Postcondition: the result is in ascending order; no duplicates.
-- 16.6.02 seed is made a parameter

choices :: Int -> Int -> Int -> [Int]

choices seed n m
  = fst (choicesAux ([],rands))
    where
    
    choicesAux :: ([Int],[Int]) -> ([Int],[Int])
    choicesAux (cs,(r:rs))
      | length cs >= m 	= (cs,[])
      | otherwise	= choicesAux (nub (insert r cs) , rs)
      
    rands :: [Int]
    rands = randomRs (0::Int,n-1) (mkStdGen seed)
    
-- A random startup

-- A seed for the random numbers is given by system time in seconds.
-- A value is chosen once per session: the value persists through a
-- session.

sessionSeed :: Int

sessionSeed = round (unsafePerformIO getPOSIXTime)

-- A list of n choices from an m*p matrix
-- 	m = row length
--	p = column height
-- Assumes that the postcondition for choices holds.
-- 16.6.02 seed is made a parameter to the old randomGrid, now
-- renamed randomGridMake.

randomGridMake :: Int -> Int -> Int -> Int -> [[Bool]]

randomGridMake seed n m p 
  = pad
    where
    
    makeMatrix :: Int -> [Int] -> [[Bool]]

    makeMatrix i cs
      | cs==[]		= []
      | otherwise
        = convert first : makeMatrix (i+1) rest
	  where
	  (first,rest) = span ((==i).(flip div m)) cs
	  convert ns 
	     = map check [0 .. m-1]
	       where
	       check n = elem n [ x `mod` m | x<-ns ]

    rows = makeMatrix 0 (choices seed (m*p) n)
     
    pad = rows ++ replicate (p - length rows) (replicate m False)

-- Random grid with a per-session seed.

randomGrid :: Int -> Int -> Int -> [[Bool]]

randomGrid = randomGridMake sessionSeed 

-- Random grid with a per-invocation seed.

randomGridDyn :: Int -> Int -> Int -> Int -> [[Bool]]

randomGridDyn 
  = randomGridMake 
