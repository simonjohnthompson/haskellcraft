----------------------------------------------------------
--							--
--	GraphicMine3.hs					--
--							--
--	Simon Thompson, June 2002			--
--							--
----------------------------------------------------------

-- Extends GraphicMine by:
--	putting in buttons for other menu options.

-- Extends GraphicMine2 by
--	completing options for
--		quit
--		help
--		new game, generated randomly
--		automatic play
--		showing equations

module GraphicMine3 where
import MineRandom ( randomGrid, randomGridDyn )
import IOExts ( unsafePerformIO )
import Time ( getClockTime , ClockTime(..) )
import List ( (\\), zipWith5, zipWith4, nub )
import Minesweeper5 ( playAutoOne, Point, countConfig, (!!!),
	 	      updateArray, uncoverClosure, getInfo, fixSplit,
		      makePos, makeNeg )
import GraphicsUtils hiding (Point)
import qualified GraphicsUtils (Point)

game = playGameG 20 10

type PointG = GraphicsUtils.Point

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

-- Show play graphically
-- Arguments are
--	old show values
--	current show values
--	current marking
--	adjacency count
-- Only shows cells where a change has taken place.


showPlayG :: [[Bool]] -> [[Bool]] -> [[Bool]] -> [[Int]] -> Graphic

showPlayG oss ess mss nss 
           = overGraphic 
	         (overGraphics (zipWith5 f [0 .. length ess - 1] oss ess mss nss))
		 buttonBar
	     where
	     f n os es ms ns 
	       = overGraphics [ g | Just g <- (zipWith5 (showCellG n) [0 .. length es - 1] os es ms ns) ]
	     buttonBar
	       = overGraphics [ button Cyan "q" (0,300) (50, 250) ,
	                        button Cyan "h" (50,300) (100, 250) ,
	                        button Cyan "n" (100,300) (150, 250) ,
	                        button Cyan "s" (150,300) (200, 250) ,
	                        button Cyan "t" (200,300) (250, 250) ]

-- How to show the value in a particular cell.
-- See the previous question for a gloss on the 
-- purpose of the various arguments.
-- A Graphic is only produced if the value in the cell
-- has changed; hence the Maybe type.

showCellG :: Int -> Int -> Bool -> Bool -> Bool -> Int -> Maybe Graphic

showCellG n m o showing marked count 
	= if o==showing then Nothing 
	  else Just (if marked 
		     then mine Red "" n m
		  else if not showing 
		     then mine Blue "" n m
	          else if count==0 
		     then mine Green "" n m
	             else mine Green (show count) n m)



-- Show play
-- Assumes that the two arrays are of the same shape
-- The second array gives the adjacency count of the cell,
-- whilst the first indicates whether or not it is uncovered.


showPlayG' :: [[Bool]] -> [[Bool]] -> [[Int]] -> Graphic

showPlayG' ess mss nss 
           = overGraphics (zipWith4 f [0 .. length ess - 1] ess mss nss)
	     where
	     f n es ms ns 
	       = overGraphics (zipWith4 (showCellG' n) [0 .. length es - 1] es ms ns)

-- How to show the value in a particular cell.

showCellG' :: Int -> Int -> Bool -> Bool -> Int -> Graphic

showCellG' n m showing marked count 
	= if marked 
	     then mine Red "" n m
	  else if not showing 
	     then mine Blue "" n m
          else if count==0 
	     then mine Green "" n m
             else mine Green (show count) n m



-- Play the game dynamically; pass in the number of mines
-- and the (square) board size as initial arguments.
-- Have to pass in the seed at each call as first argument.

playGameGDyn :: Int -> Int -> Int -> IO ()

playGameGDyn seed mines size = 
   runGraphics $
    do
	w <- openWindow "Minesweeper" (250,300) 
	drawInWindow w $ showPlayG' showing marked count
        playGameGridG grid count showing showing marked w
	closeWindow w

   where

   grid      = randomGridDyn seed mines size size
   count     = countConfig grid			
   showing   = map (map (const False)) grid
   marked    = map (map (const False)) grid

playGameG :: Int -> Int -> IO ()

playGameG mines size = 
   runGraphics $
    do
	w <- openWindow "Minesweeper" (250,300) 
	drawInWindow w $ showPlayG' showing marked count
        playGameGridG grid count showing showing marked w
	closeWindow w

   where

   grid      = randomGrid mines size size
   count     = countConfig grid			
   showing   = map (map (const False)) grid
   marked    = map (map (const False)) grid

playGameGridG :: [[Bool]] -> [[Int]] -> [[Bool]] -> [[Bool]] -> [[Bool]] -> Window -> IO ()

-- Arguments: 	layout of mines
--		adjacency count
--		is a square uncovered?	old
--		is a square uncovered?	current
--		is a square marked?
--		window

playGameGridG grid count old showing marked w =
     do { -- clearWindow w ;
          drawInWindow w $ showPlayG old showing marked count ;
          (choice,point) <- getInputG w ;
	  case choice of
	    'q' -> do { return () }
	    'h' -> do { w1 <- openWindowEx "Minesweeper Help" 
	                                   (Just (500,200)) 
					   (250,150)
					   DoubleBuffered
					   (Just 3000);
                        setGraphic w1 $ helpInfoG ;
			getWindowTick w1 ;
	                closeWindow w1 ;
	                playGameGridG grid count old showing marked w }
	    'm' -> if marked!!!point
	    	   then playGameGridG grid count 
		                      (updateArray point True showing)
		                      (updateArray point False showing) 
				      (updateArray point False marked) w
	           else playGameGridG grid count showing 
		                      (updateArray point True showing) 
				      (updateArray point True marked) w
	    'r' -> if grid!!!point 
	             then (let {none = showNone ;
		                all = showAll ;
				reveal = zipWith (zipWith (||)) marked grid }
		           in do { drawInWindow w $ showPlayG none all reveal count ;
		                   playGameGridG grid count none all reveal w })
	             else
	                (playGameGridG grid count showing
			              (uncoverClosure count point showing)
	                              marked w)
{-	    's' -> let {eqs = getInfo count showing marked point;
	                normEqs = fixSplit eqs }
		   in do { putStr $ showEquations eqs ; 
	                   putStr "---------\n" ;
	                   putStr $ showEquations normEqs ;
	                   playGameGrid grid count showing marked }
-}
            'n' -> let {grid'      = randomGridDyn (fromIntegral (case (unsafePerformIO getClockTime) of (TOD s m) -> s)) 
	    					   20 10 10 ;
	    		count'     = countConfig grid' ;			
   			showing'   = map (map (const False)) grid' ;
   			marked'    = map (map (const False)) grid' }
		   in do {drawInWindow w $ showPlayG' showing' marked' count' ;
        		  playGameGridG grid' count' showing' showing' marked' w}
{-	   
            'n' -> do {closeWindow w ;
        	       playGameGDyn mines size} -}
	    't' -> playAutoG grid count old showing marked [point] w
	    _   -> playGameGridG grid count old showing marked w 
	}
	where size     = length grid
	      mines    = length (concat (map (map (\b -> if b then 1 else 0)) grid))
	      showNone = replicate size (replicate size False)
	      showAll  = replicate size (replicate size True)



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
			        then return ('n',(0,0)) 
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



helpInfoG :: Graphic

helpInfoG
  = overGraphics [
    	text (0,10)   " q   Quit",
	text (0,40)   " h   Help Information",
	text (0,70)   " n   New Game",
	text (0,100)  " s   Show Information (select point)",
	text (0,130)  " t    Play automatically (select point)" 
	]

-- Play the game automatically from the information at point (n,m)
-- Halts when no further progress made, and calls playGameG.
-- No need to modify playAutoOne for the graphical interface.

playAutoG :: [[Bool]] -> [[Int]] -> [[Bool]] -> [[Bool]] -> [[Bool]] -> [Point] -> Window -> IO ()

playAutoG grid count old showing marked [] w
  = playGameGridG grid count old showing marked w

playAutoG grid count old showing marked (point:rest) w
 = let eqs = fixSplit (getInfo count showing marked point)
       (newShow,newMark) = playAutoOne grid count showing marked point
       newPts = makeNeg eqs ++ makePos eqs
       mask   = zipWith (zipWith (||)) showing (zipWith (zipWith (||)) newShow newMark)
       size   = length count
       none   = replicate size (replicate size False)
   in if (showing,marked)==(newShow,newMark) 
   then playAutoG grid count old showing marked rest w
   else 
   do { -- putStr $ showEquations eqs ;
        drawInWindow w $ showPlayG none mask newMark count ;
	playAutoG grid count showing newShow newMark (nub(newPts++rest)) w}

