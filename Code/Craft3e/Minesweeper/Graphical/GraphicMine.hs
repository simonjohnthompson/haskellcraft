----------------------------------------------------------
--
--	GraphicMine.hs
--
--	Simon Thompson, June 2002
--	Modernized to use the `gloss` graphics library, 2026
--
----------------------------------------------------------

-- A graphical interface to the Minesweeper game defined in
-- Minesweeper5.hs. This single file replaces the four incremental
-- versions (GraphicMine.hs through GraphicMine4.hs) that used to be
-- kept here, each built on a graphics library, GraphicsUtils, that
-- no longer exists anywhere -- neither in this repository nor on
-- Hackage. All of the features those four files added one by one
-- (revealing and flagging cells, starting a new game, and a
-- deduction assist) are built in here from the start, using the
-- actively-maintained `gloss` package instead.
--
-- To play: run the "minesweeperGraphical" executable (`cabal run
-- minesweeperGraphical`), or load this module and call playGameG
-- directly, e.g. `playGameG 10 8` for a 10-mine, 8x8 board.

module GraphicMine where

import Graphics.Gloss hiding ( Point )
import Graphics.Gloss.Interface.Pure.Game hiding ( Point )
import System.Random ( StdGen, newStdGen, random )

import MineRandom ( randomGridDyn )
import Minesweeper5
    ( Point, Equations
    , countConfig, updateArray, uncoverClosure
    , getInfo, fixSplit, makePos, makeNeg, (!!!)
    )

-- Board geometry
-- ^^^^^^^^^^^^^^

cellSize :: Float
cellSize = 40

headerHeight :: Float
headerHeight = 60

-- Game state
-- ^^^^^^^^^^

data Status = Playing | Won | Lost deriving (Eq, Show)

data World = World
  { wSize    :: Int
  , wMines   :: Int
  , wGrid    :: [[Bool]]    -- True where a mine sits
  , wCount   :: [[Int]]     -- adjacency counts
  , wShowing :: [[Bool]]    -- revealed cells
  , wMarked  :: [[Bool]]    -- flagged cells
  , wStatus  :: Status
  , wGen     :: StdGen      -- source of the seed for the next new game
  }

-- A fresh board of the given size and mine count, from a seed.

newBoard :: Int -> Int -> Int -> StdGen -> World
newBoard mines size seed gen
  = World
      { wSize = size, wMines = mines
      , wGrid = grid, wCount = countConfig grid
      , wShowing = blank, wMarked = blank
      , wStatus = Playing, wGen = gen
      }
    where
    grid  = randomGridDyn seed mines size size
    blank = replicate size (replicate size False)

-- Play the game; pass in the number of mines and the (square) board size.

playGameG :: Int -> Int -> IO ()

playGameG mines size
  = do
      gen0 <- newStdGen
      let (seed, gen1) = random gen0 :: (Int, StdGen)
      play (InWindow "Minesweeper" (windowW, windowH) (100, 100))
           white 30 (newBoard mines size seed gen1) render handleEvent (const id)
    where
    windowW = round (fromIntegral size * cellSize)
    windowH = round (fromIntegral size * cellSize + headerHeight)

-- Turning game state into a picture
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

render :: World -> Picture

render w
  = pictures (header : [ renderCell w row col
                        | row <- [0 .. wSize w - 1], col <- [0 .. wSize w - 1] ])
    where
    header
      = translate (- boardW w / 2) (boardH w / 2 + 10)
      $ scale 0.13 0.13
      $ color black
      $ Text (statusText w)

boardW, boardH :: World -> Float
boardW w = fromIntegral (wSize w) * cellSize
boardH w = fromIntegral (wSize w) * cellSize

statusText :: World -> String
statusText w
  = case wStatus w of
      Won     -> "You win!  Press N for a new game."
      Lost    -> "Boom!  Press N for a new game."
      Playing -> show (wMines w) ++
                 " mines.  Click: reveal   Right-click: flag   N: new game   A: assist"

renderCell :: World -> Int -> Int -> Picture

renderCell w row col
  = translate x y (pictures (box : maybe [] (:[]) label))
    where
    x = - boardW w / 2 + (fromIntegral col + 0.5) * cellSize
    y =   boardH w / 2 - headerHeight - (fromIntegral row + 0.5) * cellSize

    point    = (row, col)
    revealed = wShowing w !!! point
    flagged  = wMarked  w !!! point
    mined    = wGrid    w !!! point
    n        = wCount   w !!! point
    showMine = wStatus w == Lost && mined

    box = color cellColour (rectangleSolid (cellSize - 2) (cellSize - 2))
    cellColour
      | showMine  = red
      | flagged   = orange
      | revealed  = greyN 0.85
      | otherwise = greyN 0.55

    label
      | showMine                 = Just (cellLabel black "*")
      | flagged && not revealed  = Just (cellLabel black "F")
      | revealed && n > 0        = Just (cellLabel (countColour n) (show n))
      | otherwise                = Nothing

    cellLabel colour str
      = color colour $ translate (-7) (-7) $ scale 0.13 0.13 $ Text str

-- The classic Minesweeper colour-per-count convention.

countColour :: Int -> Color
countColour n
  = case n of
      1 -> blue
      2 -> dark green
      3 -> red
      4 -> violet
      5 -> makeColor 0.5 0 0 1
      6 -> cyan
      7 -> black
      _ -> greyN 0.4

-- Handling clicks and key presses
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

handleEvent :: Event -> World -> World

handleEvent (EventKey (Char 'n') Down _ _) w
  = newGame w
handleEvent (EventKey (Char 'N') Down _ _) w
  = newGame w
handleEvent (EventKey (Char 'a') Down _ _) w
  | wStatus w == Playing = assist w
handleEvent (EventKey (Char 'A') Down _ _) w
  | wStatus w == Playing = assist w
handleEvent (EventKey (MouseButton LeftButton) Down _ pos) w
  | wStatus w == Playing = maybe w (reveal w) (cellAt w pos)
handleEvent (EventKey (MouseButton RightButton) Down _ pos) w
  | wStatus w == Playing = maybe w (flagCell w) (cellAt w pos)
handleEvent _ w = w

-- Which cell, if any, a click at this window position lands on.

cellAt :: World -> (Float, Float) -> Maybe Point

cellAt w (mx, my)
  | row >= 0 && row < size && col >= 0 && col < size = Just (row, col)
  | otherwise                                        = Nothing
    where
    size = wSize w
    col  = floor ((mx + boardW w / 2) / cellSize)
    row  = floor ((boardH w / 2 - headerHeight - my) / cellSize)

-- Revealing a cell: losing if it's a mine, otherwise uncovering its
-- closure of neighbouring zero-count cells, exactly as playGameGrid
-- does in Minesweeper5.hs.

reveal :: World -> Point -> World

reveal w point
  | wMarked w !!! point = w
  | wGrid w !!! point   = w { wStatus = Lost }
  | otherwise           = checkWin w { wShowing = uncoverClosure (wCount w) point (wShowing w) }

-- Toggling a flag on a covered cell.

flagCell :: World -> Point -> World

flagCell w point
  | wShowing w !!! point = w
  | otherwise = w { wMarked = updateArray point (not (wMarked w !!! point)) (wMarked w) }

-- The game is won once every non-mine cell has been revealed.

checkWin :: World -> World

checkWin w
  | all and (zipWith (zipWith (||)) (wGrid w) (wShowing w)) = w { wStatus = Won }
  | otherwise                                           = w

-- A new board, same mines/size, using the next seed from wGen.

newGame :: World -> World

newGame w = newBoard (wMines w) (wSize w) seed gen'
    where
    (seed, gen') = random (wGen w) :: (Int, StdGen)

-- One round of deduction assist: for every equation derivable from
-- the currently-revealed cells (using the same getInfo/fixSplit
-- machinery Minesweeper5.hs's own 's'/'a' commands use), reveal
-- every cell a determined-safe equation names, and flag every cell
-- a determined-mined equation names.

assist :: World -> World

assist w
  = checkWin w { wShowing = foldr (uncoverClosure (wCount w)) (wShowing w) safe
               , wMarked  = foldr (\pt -> updateArray pt True) (wMarked w) mines
               }
    where
    shown  = [ (r, c) | r <- [0 .. wSize w - 1], c <- [0 .. wSize w - 1]
                       , wShowing w !!! (r, c) ]
    eqs    = fixSplit (concatMap (getInfo (wCount w) (wShowing w) (wMarked w)) shown)
             :: Equations
    safe   = makeNeg eqs
    mines  = makePos eqs
