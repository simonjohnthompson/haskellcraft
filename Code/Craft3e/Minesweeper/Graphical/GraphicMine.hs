----------------------------------------------------------
--							--
--	GraphicMine.hs				--
--							--
--	Simon Thompson, June 2002			--
--							--
----------------------------------------------------------

module GraphicMine where
import MineRandom ( randomGrid )
import List ( (\\), zipWith4, nub )
import Minesweeper5 
import GraphicsUtils hiding (Point)
import qualified GraphicsUtils (Point)

type PointG = GraphicsUtils.Point

test2 :: IO ()

test2 = 
  runGraphics $
  	do
		w <- openWindow "test1" (600,600)
		w1 <- openWindow "test2" (100,100)
		drawInWindow w (button Red "Quit" (0,0) (100,50))
		drawInWindow w $
		    overGraphics [ 
		       overGraphics [ mine Red "" x (y+2)
		                      | y <-[0..9] ] 
				 | x<-[0..9] ]
		loopUntilQuit w
		closeWindow w
	where
	loopUntilQuit w 
	  = do
	  	(x,y) <- getLBP w
		(if (0<=x && x<=100 && 0<=y && y<=50) 
		  then return ()
		  else loopUntilQuit w)

mine :: Color -> String -> Int -> Int -> Graphic

mine color str s t 
  = button color str (25*s,25*t) (25*(s+1),25*(t+1))

button :: Color -> String -> PointG -> PointG -> Graphic

button color st p0@(x0,y0) p1@(x1,y1) 
  = withTextAlignment (Center,Baseline) $
    overGraphic (text center st) (rectangle color p0 p1)
    where
    center = ((x0+x1) `div` 2, (y0+y1) `div` 2)

rectangle :: Color -> PointG -> PointG -> Graphic

rectangle color p0@(x0,y0) p1@(x1,y1)
  = mkBrush (just (lookup color colorList)) 
            (\brush -> withBrush brush $ 
    		polygon [ (x0,y0), (x0,y1), (x1,y1), (x1,y0), (x0,y0) ])

just :: Maybe a -> a

just (Just x) = x
just Nothing  = error "just"

-- Show play
-- Assumes that the two arrays are of the same shape
-- The second array gives the adjacency count of the cell,
-- whilst the first indicates whether or not it is uncovered.


showPlayG :: [[Bool]] -> [[Bool]] -> [[Int]] -> Graphic

showPlayG ess mss nss 
           = overGraphics (zipWith4 f [0 .. length ess - 1] ess mss nss)
	     where
	     f n es ms ns 
	       = overGraphics (zipWith4 (showCellG n) [0 .. length es - 1] es ms ns)

-- How to show the value in a particular cell.

showCellG :: Int -> Int -> Bool -> Bool -> Int -> Graphic

showCellG n m showing marked count 
	= if marked 
	     then mine Red "" n m
	  else if not showing 
	     then mine Blue "" n m
          else if count==0 
	     then mine Green "" n m
             else mine Green (show count) n m



-- Play the game; pass in the number of mines
-- and the (square) board size as initial arguments.

playGameG :: Int -> Int -> IO ()

playGameG mines size = 
   runGraphics $
    do
	w <- openWindow "Minesweeper" (400,400) 
        playGameGridG grid count showing marked w
	closeWindow w

   where

   grid      = randomGrid mines size size
   count     = countConfig grid			
   showing   = map (map (const False)) grid
   marked    = map (map (const False)) grid
 

playGameGridG :: [[Bool]] -> [[Int]] -> [[Bool]] -> [[Bool]] -> Window -> IO ()

playGameGridG grid count showing marked w =
     do { clearWindow w ;
          drawInWindow w $ showPlayG showing marked count ;
          (choice,point) <- getInputG w ;
	  case choice of
	    'q' -> do { getRBP w ; return () }
	    -- 'h' -> do { putStr helpInfo ; playGameGrid grid count showing marked }
	    'h' -> playGameGridG grid count showing marked w
	    'm' -> if marked!!!point
	    	   then playGameGridG grid count showing (updateArray point False marked) w
	           else playGameGridG grid count showing (updateArray point True marked) w
	    'r' -> if grid!!!point 
	             then (do { getRBP w ; closeWindow w})
	             else
	                (playGameGridG grid count 
			              (uncoverClosure count point showing)
	                              marked w)
{-	    's' -> let {eqs = getInfo count showing marked point;
	                normEqs = fixSplit eqs }
		   in do { putStr $ showEquations eqs ; 
	                   putStr "---------\n" ;
	                   putStr $ showEquations normEqs ;
	                   playGameGrid grid count showing marked }
	    'a' -> let {eqs = fixSplit (getInfo count showing marked point);
	                (newShow,newMark) = playAutoOne grid count
						showing marked point}
		   in do {
	                putStr $ showEquations eqs ;
			playGameGrid grid count newShow newMark }
	    't' -> playAuto grid count showing marked [point]
	    _   -> playGameGrid grid count showing marked 
	    -}
	}
	where size = length grid



-- A uniform procedure for getting input, which gives
-- a choice and a cell. 
-- In the case that cell information is not required, i.e.
-- 'help' or 'quit' a dummy point is returned.
-- Parameterised by the size of the grid, so that the Point
-- returned is quaranteed to be in the grid ... primitive
-- error correction.

getInputG :: Window -> IO (Char,Point)

getInputG w =
  do {    ev <- getWindowEvent w;
          case ev of
	    Button (x,y) isL True
	       -> if 0<=x && x<=250 && 0<=y && y<=250
	          then if isL then return ('r',(x `div` 25,y `div` 25)) 
		              else return ('m',(x `div` 25,y `div` 25))
		  else if (250<=y && y<=300)
		       then (if (0<=x && x<=50)
		       		then return ('q',(0,0))
		             else if (50<=x && x<=100)
			        then return ('h',(0,0))
			     else if (100<=x && x<=150)
			        then do { (x,y) <- getLBP w;
				          return ('a',(x `div` 25,y `div` 25))} 
			     else if (150<=x && x<=200)
			        then do { (x,y) <- getLBP w;
				          return ('s',(x `div` 25,y `div` 25))} 
			     else if (200<=x && x<=250)
			        then do { (x,y) <- getLBP w;
				          return ('t',(x `div` 25,y `div` 25))} 
				else getInputG w)
			else getInputG w
            _ -> getInputG w
      }

{-

helpInfo :: String

helpInfo
  = "\n\n q\tQuit\n\
    \ h\tHelp information\n\
    \ m7b\tMark position 7b\n\
    \ u7b\tUnmark position 7b\n\
    \ r7b\tReveal position 7b\n\
    \ s7b\tShow equations at 7b\n\
    \ a7b\tAutomatic turn at 7b\n\
    \ t7b\tTransitive automatic from 7b\n\n"
	
-- Play one step automatically

playAutoOne :: [[Bool]] -> [[Int]] -> [[Bool]] -> [[Bool]] -> 
               Point -> ([[Bool]],[[Bool]])

playAutoOne grid count showing marked point
 = let eqs = fixSplit (getInfo count showing marked point)
   in (updateShowByEqs eqs count showing,
       updateMarkByEqs eqs marked)

-- Play the game automatically from the information at point (n,m)
-- Halts when no further progress made, and calls playGame.

playAuto :: [[Bool]] -> [[Int]] -> [[Bool]] -> [[Bool]] -> [Point] -> IO ()

playAuto grid count showing marked []
  = playGameGrid grid count showing marked
playAuto grid count showing marked (point:rest)
 = let eqs = fixSplit (getInfo count showing marked point)
       (newShow,newMark) = playAutoOne grid count showing marked point
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

closure :: [[Int]] -> Point -> [Point]

closure count point = doClosure count point []

-- doClosure, doClosureList use a variant of the algorithm 
-- on pp333-4 of craft2e.

doClosure :: [[Int]] -> Point -> [Point] -> [Point]

doClosure count point avoid
  | count!!!point /= 0	= [point]
  | otherwise	
    = point : doClosureList count nbs (point:avoid)
      where
      nbs = nbhrs count point

doClosureList :: [[Int]] -> [Point] -> [Point] -> [Point]

doClosureList count [] avoid = []

doClosureList count (point: points) avoid
  = next ++ doClosureList count points (avoid ++ next)
    where
    next = if elem point avoid
           then [point]
	   else doClosure count point avoid

-- Uncover all the points in the closure

uncoverClosure :: [[Int]] -> Point -> [[Bool]] -> [[Bool]]

uncoverClosure count point 
  = foldr (.) id $ 
    map (flip updateArray True) (closure count point)

-- What are the neighbours of a point?

nbhrs :: [[Int]] -> Point -> [Point]

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

(!!!) :: [[a]] -> Point -> a

xss!!!(p,q) = xss!!p!!q

-- Showing the information about a given cell,
-- in the context of certain known information:
--	count showing marked
-- Produces an equation corresponding to each neighbour
-- which has its value showing.
-- Count zero for showing zeroes and 1 for marked cells
-- i.e. assumes that markings are correct.

-- Refactored as getInfoCell below ....

getInfo :: [[Int]] -> [[Bool]] -> [[Bool]] -> Point -> Equations

getInfo count showing marked point
  = map (getInfoCell count showing marked)
        [ nb | nb <- nbhrs count point , showing!!!nb ]

showInfo :: [[Int]] -> [[Bool]] -> [[Bool]] -> Point -> String

showInfo count showing marked point 
  = showEquations (getInfo count showing marked point)
			  
type Equations = [Equation]
type Equation  = (Int, [Point])

-- Initial program for the information extracts it and immediately
-- shows it. Subsequently refactored to produce a data structure
-- containing the information, and a corresponding show function over
-- the data structure.

-- Call this separate producer and consumer ... allows whatever is
-- produced to be used in more than one way.
-- Can envisage the converse too: merging producer and consumer,
-- particularly if there's only one use of the producer in the program.

getInfoCell :: [[Int]] -> [[Bool]] -> [[Bool]] -> Point -> Equation 

getInfoCell count showing marked point
  = ( (count!!!point - marks) , 
      [ nb | nb <- nbrs, not (showing!!!nb), not (marked!!!nb) ]
    )
    where 
    nbrs              = nbhrs count point
    marks             = sum [ 1 | nb<-nbrs , marked!!!nb ]

-- Showing the information in a cell
    
showInfoCell :: [[Int]] -> [[Bool]] -> [[Bool]] -> Point -> String 

showInfoCell count showing marked point
  = showEquation (getInfoCell count showing marked point)

showEquations :: Equations -> String

showEquations = ("\n"++) . concat . (map showEquation)

showEquation :: Equation -> String

showEquation (lhs, rhs) 
  = show lhs ++ " = " ++ showPoints rhs ++ "\n"

showRow :: Int -> String
showRow           = show

showCol :: Int -> String
showCol t         = [ chr (t + ord 'a') ]

showPoint :: Point -> String
showPoint (p,q)   = showRow p ++ showCol q

showPoints :: [Point] -> String
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

makePos,makeNeg :: [Equation] -> [Point]

makeNeg = nub . concat . map snd . filter deterNeg
makePos = nub . concat . map snd . filter deterPos

-- Update a marking array according to the information 
-- in a set of equations.

updateMarkByEqs :: [Equation] -> [[Bool]] -> [[Bool]]

updateMarkByEqs eqs marked
  = updatePos marked
    where
    updatePos = foldr (.) id $ map updateP (makePos eqs)
    updateP pt = updateArray pt True 

-- Update a showing array according to the info
-- in a set of equations. In the first version it
-- failed to uncover the closure of the uncovered points.
-- To do this, it has to be passed the grid count as well
-- as the show matrix.

updateShowByEqs :: [Equation] -> [[Int]] -> [[Bool]] -> [[Bool]]

updateShowByEqs eqs count showing
  = updateNeg showing
    where
    updateNeg = foldr (.) id $ map updateN (makeNeg eqs)
    updateN   = uncoverClosure count


-}    

