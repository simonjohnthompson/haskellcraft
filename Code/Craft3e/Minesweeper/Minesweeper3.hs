----------------------------------------------------------
--							--
--	Minesweeper3.hs					--
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

-- Modifies Minesweeper2.hs, by ... (to be completed)

-- The board is represented by a list of lists. It is a
-- global assumption that this is rectangular, that is all
-- component lists have the same length.
-- It is also assumed that counts are nonempty.

module Minesweeper3 where
import MineRandom ( randomGrid )
import Data.List ( (\\), zipWith4, nub )


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


showPlay :: [[Bool]] -> [[Bool]] -> [[Int]] -> String

showPlay ess mss nss 
           = "   " ++ take (length (head nss)) ['a' .. 'z'] ++ "\n" ++
             concat (zipWith4 f [0 .. length nss - 1] ess mss nss)
	     where
	     f n es ms ns 
	       = pad 3 (show n) ++ concat (zipWith3 showCell es ms ns) ++ "\n"

-- How to show the value in a particular cell.

showCell :: Bool -> Bool -> Int -> String

showCell showing marked n 
	= if marked then "X"
	     else if not showing then "."
                 else if n==0 then " "
		     else show n


-- Play the game; pass in the number of mines
-- and the (square) board size as initial arguments.

playGame :: Int -> Int -> IO ()

playGame mines size = 
   playGameGrid grid count showing marked

   where

   grid      = randomGrid mines size size
   count     = countConfig grid			
   showing   = map (map (const False)) grid
   marked    = map (map (const False)) grid
   
playGameGrid :: [[Bool]] -> [[Int]] -> [[Bool]] -> [[Bool]] -> IO ()

playGameGrid grid count showing marked =
     do { putStr (showPlay showing marked count) ;
          choice <- getChar ;
	  if choice=='q' 				-- quit
	  then 
	   do { putStr "\nquit" ; return () }
	  else if not (elem choice "smurat")		-- ignore illegal
	  then						-- choice
	   do { putStr "\n" ; playGameGrid grid count showing marked }
	  else 
	   do {
           rowCh <- getChar ;				-- get row
	   let { row = fitRange size (fromEnum rowCh - fromEnum '0') } ; 
	   colCh <- getChar ;				-- and column
	   let { col = fitRange size (fromEnum colCh - fromEnum 'a') } ;
	   putStr "\n" ;
	   case choice of
	    'm' -> playGameGrid grid count showing (updateArray row col True marked)
	    'u' -> playGameGrid grid count showing (updateArray row col False marked)
	    'r' -> if grid!!!(row,col) 
	             then (do { putStr "LOST!" ; return () })
	             else
	                (playGameGrid grid count 
			              (uncoverClosure count (row,col) showing)
	                              marked)
	    's' -> do { putStr $ showInfo count showing marked row col ; 
	                putStr "---------\n" ;
	                putStr $ showEquations $ fixSplit $
			         getInfo count showing marked row col ;
	                playGameGrid grid count showing marked }
	    'a' -> let {eqs = fixSplit (getInfo count showing marked row col);
	                (newShow,newMark) = playAutoOne grid count
						showing marked row col}
		   in do {
	                putStr $ showEquations eqs ;
			playGameGrid grid count newShow newMark }
	    't' -> playAuto grid count showing marked [(row,col)]
	       }
	}
	where size = length grid
	
-- Play one step automatically

playAutoOne :: [[Bool]] -> [[Int]] -> [[Bool]] -> [[Bool]] -> 
               Int -> Int -> ([[Bool]],[[Bool]])

playAutoOne grid count showing marked row col
 = let eqs = fixSplit (getInfo count showing marked row col)
   in (updateShowByEqs eqs count showing,
       updateMarkByEqs eqs marked)

-- Play the game automatically from the information at point (n,m)
-- Halts when no further progress made, and calls playGame.

playAuto :: [[Bool]] -> [[Int]] -> [[Bool]] -> [[Bool]] -> [(Int,Int)] -> IO ()

playAuto grid count showing marked []
  = playGameGrid grid count showing marked
playAuto grid count showing marked ((row,col):rest)
 = let eqs = fixSplit (getInfo count showing marked row col)
       (newShow,newMark) = playAutoOne grid count showing marked row col
       newPts = makeNeg eqs ++ makePos eqs
   in if (showing,marked)==(newShow,newMark) 
   then playAuto grid count showing marked rest
   else 
   do { putStr $ showEquations eqs ;
        putStr (showPlay showing marked count) ;
	playAuto grid count newShow newMark (nub(newPts++rest)) }


-- Finding the closure of a point / set of points.
-- The worker functions: doClosure, doClosureList, carry around a 
-- list of points already visited.

closure :: [[Int]] -> (Int,Int) -> [(Int,Int)]

closure count point = doClosure count point []

-- doClosure, doClosureList use a variant of the algorithm 
-- on pp333-4 of craft2e.

doClosure :: [[Int]] -> (Int,Int) -> [(Int,Int)] -> [(Int,Int)]

doClosure count point avoid
  | count!!!point /= 0	= [point]
  | otherwise	
    = point : doClosureList count nbs (point:avoid)
      where
      nbs = nbhrs count point

doClosureList :: [[Int]] -> [(Int,Int)] -> [(Int,Int)] -> [(Int,Int)]

doClosureList count [] avoid = []

doClosureList count (point: points) avoid
  = next ++ doClosureList count points (avoid ++ next)
    where
    next = if elem point avoid
           then [point]
	   else doClosure count point avoid

-- Uncover all the points in the closure

uncoverClosure :: [[Int]] -> (Int,Int) -> [[Bool]] -> [[Bool]]

uncoverClosure count point 
  = foldr (.) id $ 
    map ((flip.uncurry) updateArray True) (closure count point)

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

-- Push an integer value into the range 
--	0 .. r-1

fitRange :: Int -> Int -> Int

fitRange r val
  | 0<=val && val<r	= val
  | val<0		= 0
  | val>=r 		= r-1

-- Array lookup operation

(!!!) :: [[a]] -> (Int,Int) -> a

xss!!!(p,q) = xss!!p!!q

-- Showing the information about a given cell,
-- in the context of certain known information:
--	count showing marked
-- Produces an equation corresponding to each neighbour
-- which has its value showing.
-- Count zero for showing zeroes and 1 for marked cells
-- i.e. assumes that markings are correct.

-- Refactored as getInfoCell below ....

getInfo :: [[Int]] -> [[Bool]] -> [[Bool]] -> Int -> Int -> Equations

getInfo count showing marked row col
  = map (uncurry (getInfoCell count showing marked))
        [ point | point <- nbhrs count (row,col) , showing!!!point ]

showInfo :: [[Int]] -> [[Bool]] -> [[Bool]] -> Int -> Int -> String

showInfo count showing marked row col 
  = showEquations (getInfo count showing marked row col)
			  
type Equations = [Equation]
type Equation  = (Int, [(Int,Int)])

-- Initial program for the information extracts it and immediately
-- shows it. Subsequently refactored to produce a data structure
-- containing the information, and a corresponding show function over
-- the data structure.

-- Call this separate producer and consumer ... allows whatever is
-- produced to be used in more than one way.
-- Can envisage the converse too: merging producer and consumer,
-- particularly if there's only one use of the producer in the program.

getInfoCell :: [[Int]] -> [[Bool]] -> [[Bool]] -> Int -> Int -> Equation 

getInfoCell count showing marked s t 
  = ( (count!!!(s,t) - marks) , 
      [ point | point <- nbrs, not (showing!!!point), 
    			       not (marked!!!point) ]
    )
    where 
    nbrs              = nbhrs count (s,t)
    marks             = sum [ 1 | point<-nbrs , marked!!!point ]

-- Showing the information in a cell
    
showInfoCell :: [[Int]] -> [[Bool]] -> [[Bool]] -> Int -> Int -> String 

showInfoCell count showing marked s t 
  = showEquation (getInfoCell count showing marked s t)

showEquations = concat . (map showEquation)

showEquation :: Equation -> String

showEquation (lhs, rhs) 
  = show lhs ++ " = " ++ showPoints rhs ++ "\n"

showRow :: Int -> String
showRow           = show

showCol :: Int -> String
showCol t         = [ toEnum (t + fromEnum 'a') ]

showPoint :: (Int,Int) -> String
showPoint (p,q)   = showRow p ++ showCol q

showPoints :: [(Int,Int)] -> String
showPoints []     = "none"
showPoints [p]    = showPoint p
showPoints (p:ps) = showPoint p ++ " + " ++ showPoints ps

-- Reducing a list of equations to a normal form

-- Is one list a sublist of the other?
-- It is assumed that the elements appear in the same order, 
-- without repetitions.

subList :: Eq a => [a] -> [a] -> Bool

subList [] _     = True
subList (_:_) [] = False
subList (x:xs) (y:ys)
  | x==y	= subList xs ys
  | otherwise	= subList (x:xs) ys

-- The difference of two lists;
-- only applied when the first is a subList of the second.

listDiff :: Eq a => [a] -> [a] -> [a]

listDiff [] ys	= ys
listDiff (_:_) [] = error "listDiff applied to non-subList"
listDiff (x:xs) (y:ys) 
  | x==y	= listDiff xs ys
  | otherwise	= y : listDiff (x:xs) ys

-- Only splits when the first rhs is a sublist of the second
-- and a proper sublist at that.

splitEq :: Equation -> Equation -> Equation

splitEq e1@(l1,r1) e2@(l2,r2)
  | e1==e2		= e2
  | subList r1 r2	= (l2-l1 , listDiff r1 r2)
  | otherwise		= e2


-- Split a set (list) of equations

splitEqs :: [Equation] -> [Equation]

splitEqs eqs
  = foldr (.) id (map map (map splitEq eqs)) eqs

-- Generic fixpt operator

fixpt :: Eq a => (a -> a) -> a -> a

fixpt f x
  = g x
    where
    g y
  	| y==next	= y
  	| otherwise	= g next
    	  where
	  next = f y

fixSplit :: [Equation] -> [Equation]

fixSplit = fixpt (nub.splitEqs)

-- Added in Minesweeper3 ...

-- Is an equation determinate?
-- Could be determinate in setting all values to
-- zero (deterNeg) or to one (deterPos)

determined :: Equation -> Bool

determined eq
  = deterPos eq || deterNeg eq
  
deterPos,deterNeg :: Equation -> Bool

deterPos (n,pts)
  = n>0 && n==length pts

deterNeg (n,pts) 
  = n==0 && length pts > 0

-- Find all the points to be made negative or positive
-- from a set of Equations.

makePos,makeNeg :: [Equation] -> [(Int,Int)]

makeNeg = nub . concat . map snd . filter deterNeg
makePos = nub . concat . map snd . filter deterPos

-- Update a marking array according to the information 
-- in a set of equations.

updateMarkByEqs :: [Equation] -> [[Bool]] -> [[Bool]]

updateMarkByEqs eqs marked
  = updatePos marked
    where
    updatePos = foldr (.) id $ map updateP (makePos eqs)
    updateP (n,m) = updateArray n m True 

-- Update a showing array according to the info
-- in a set of equations. In thie first version it
-- failed to uncover the closure of the uncovered points.
-- To do this, it has to be passed the grid count as well
-- as the show matrix.

updateShowByEqs :: [Equation] -> [[Int]] -> [[Bool]] -> [[Bool]]

updateShowByEqs eqs count showing
  = updateNeg showing
    where
    updateNeg = foldr (.) id $ map updateN (makeNeg eqs)
    updateN (n,m) = uncoverClosure count (n,m)


    
