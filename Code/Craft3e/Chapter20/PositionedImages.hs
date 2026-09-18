{-# OPTIONS_GHC -fglasgow-exts #-}



module PositionedImages where

import System.IO

import Control.Monad
import Control.Monad.State

import Data.Map hiding (map)

--
-- Geometric types
--

-- Points measured with Int coordinates thus:
--
--  o------> x axis
--  |
--  |
--  V
--  y axis

type Point = (Int,Int)

origin = (0,0)

-- Bounding box: represented by NW and SE corners:
--
--  o------+
--  |      |
--  |      |
--  +------o
--  

data Box = Box Point Point
           deriving (Show, Eq)

emptyBox = Box origin origin

-- 
-- Images and pictures
-- 

-- Pictures are rectangular assemblies of Basic images.
-- Each picture has a bounding box, memoised in the data structure 

-- An image is contained in a file ...

data File  = File String
             deriving (Show)

-- ... and is displayed in an area of size given by the Point:

data Image = Image File Point
             deriving (Show)

-- A basic image is an image, with the Point of its origin, and a Filter 
-- of effects to be applied.

data Basic = Basic Image Point Filter
             deriving (Show)

data Filter = Filter {fH, fV, neg :: Bool}
              deriving (Show)

newFilter = Filter False False False

-- A Picture is a list of Basics.

data Picture = Picture [Basic]

-- Convert an Image to a Basic and to a Picture

basic :: Image -> Basic 

basic img = 
 Basic img origin newFilter

img :: Image -> Picture 

img img@(Image _ point) = 
 Picture [Basic img origin newFilter]

box :: Basic -> Box
  
box (Basic img@(Image _ (x,y)) (x',y') _)
 = Box (x',y') (x'+x, y'+y)


--
-- The monad
--

-- Simple state monad keeping track of the dimensions of the current picture.
-- Folds into the definition the calculation of width and height and the
-- calculation of flatten, which is done as the picture is constructed.

type Def a = State Info a

-- State is a finite map from Ints to Basic images

type Info = Map Id Basic

-- Ids are Ints, which are the keys for the Info map

type Id = Int

-- Positions of the four corners of a rectangular image
-- Could also add N, W, E, S and Centre   TO DO

data Position = NW | NE | SW | SE

-- Monadic functions

-- Place an image at a given point in the canvas

placeId :: Image -> Point -> Def Id
placeId image point
 = 
   do
     n <- gets size
     let basic = Basic image point newFilter
     modify (insert n basic) 
     return n

place :: Image -> Point -> Def ()
place image point
 = 
   do
     n <- gets size
     let basic = Basic image point newFilter
     modify (insert n basic) 
     return ()

positionId :: Image -> Id -> Position -> Def Id
positionId image id pos
 = 
   do
     n <- gets size
     b <- gets (box . just . Data.Map.lookup id)
     let  basic = Basic image (getPosition pos b) newFilter
     modify (insert n basic) 
     return n

position :: Image -> Id -> Position -> Def ()
position image id pos
 = 
   do
     n <- gets size
     b <- gets (box . just . Data.Map.lookup id)
     let  basic = Basic image (getPosition pos b) newFilter
     modify (insert n basic) 
     return ()

just (Just n) = n

flatten :: Def a -> Picture

flatten defs 
  = makePicture (execState defs empty)

makePicture :: Map Int Basic -> Picture
makePicture picMap  
  = Picture $ fold (:) [] picMap

--
-- Library functions
--

-- Extracting coordinates of the four corners of a box

getPosition :: Position -> Box -> Point

getPosition NW (Box pt _) = pt
getPosition NE (Box (_, y0) (x1, _)) = (x1, y0)
getPosition SW (Box (x0, _) (_, y1)) = (x0, y1)
getPosition SE (Box _ pt) = pt


--
-- examples
--

horse :: Image

horse = Image (File "blk_horse_head.jpg") (150, 200)

test :: Def ()

test
  = 
    do
      pic <- placeId horse (100,100)
      pic2 <- positionId horse pic SE
      position horse pic2 SW
      
testProgram :: IO ()

testProgram = render $ flatten $ test

-- flipFH is flip in a horizontal axis
-- flipFV is flip in a vertical axis
-- flipNeg negative negates each pixel
-- flip one of the flags for transforms / filter

flipFH (Basic img point f@(Filter {fH=boo})) = Basic img point f{fH = not boo}
flipFV (Basic img point f@(Filter {fV=boo})) = Basic img point f{fV = not boo}
flipNeg (Basic img point f@(Filter {neg=boo})) = Basic img point f{neg = not boo}

-- Convert is unchaged from the previous version, converts a basic 
-- image to an SVG object.

convert :: Basic -> String

convert (Basic (Image (File name) (width, height)) (x, y) (Filter fH fV neg))
  = "\n  <image x=\"" ++ show x ++ "\" y=\"" ++ show y ++ "\" width=\"" ++ show width ++ "\" height=\"" ++
    show height ++ "\" xlink:href=\"" ++ name ++ "\"" ++ flipPart ++ negPart ++ "/>\n"
        where
          flipPart = if fH && not fV 
                     then " transform=\"translate(0," ++ show (2*y + height) ++ ") scale(1,-1)\" " 
                     else 
                         if fV && not fH 
                         then " transform=\"translate(" ++ show (2*x + width) ++ ",0) scale(-1,1)\" " 
                         else 
                             if fV && fH 
                             then " transform=\"translate(" ++ show (2*x + width) ++ "," ++ show (2*y + height) ++ ") scale(-1,-1)\" " 
                             else ""
          negPart = if neg then " filter=\"url(#negative)\"" else "" 

-- Rendering a picture to a file

render :: Picture -> IO ()

render pic 
 = 
   let
       Picture picList = pic
       svgString = concat (map convert picList)
       newFile = preamble ++ svgString ++ postamble
   in
     do
       outh <- openFile "/Users/simonthompson/Dropbox/craft3e/DSLs/svg/svgOut.xml" WriteMode
       hPutStrLn outh newFile
       hClose outh

preamble
 = "<svg width=\"100%\" height=\"200%\" version=\"1.1\"\n" ++
   "xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\">\n" ++
   "<filter id=\"negative\">\n" ++
   "<feColorMatrix type=\"matrix\"\n"++
   "values=\"-1 0  0  0  0  0 -1  0  0  0  0  0 -1  0  0  1  1  1  0  0\" />\n" ++
   "</filter>\n"

postamble
 = "\n</svg>\n"