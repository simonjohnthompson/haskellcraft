------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions12
--
------------------------------------------------------------------------------

module Solutions12 where

import Prelude hiding (succ,lines,Word)
import Chapter12 hiding (printPicture,splits,plus,succ)
import Pictures
import Test.QuickCheck
import Solutions11 (uncurry3)
import Chapter4                   -- for RPS
import Chapter8 hiding (Move(..)) -- for RPS
import qualified Chapter8 (Move)
import Chapter11 (mapFuns)
import Index
import qualified Chapter7

--
-- Solution 12.1,2
--

-- See section 4.6 and 6.5

--
-- Solution 12.3
--

-- first split the pixels into lines, then build lines
-- separately ...

makePicture :: Int -> Int -> [(Int,Int)] -> Picture

makePicture width height pixels
  = map (makeLine width) (pixelLists 0 height pixels)

pixelLists :: Int -> Int -> [(Int,Int)] -> [[Int]]

pixelLists sofar height pixels
  | sofar >= height        = []
  | otherwise              = map snd (takeWhile ((==sofar).fst) pixels)
                             : pixelLists (sofar+1) height (dropWhile ((==sofar).fst) pixels)

makeLine :: Int -> [Int] -> [Char]

makeLine width pixels
  = [ if elem n pixels then '#' else '.' | n<-[0..width-1]]

-- Arguably could make these more efficient:
--    - use splitWhile rather than take/dropWhile for a single traversal
--    - incorporate the application of snd into the traversal

-- Could also make pixelLists more "declarative", at the cost of 
-- traversing the pixel list n times.

pixelLists' height pixels
  = [ [ x | (y,x)<-pixels, y==h ] | h <- [0..height-1] ]

makePicture' width height pixels
  = map (makeLine width) (pixelLists' height pixels)

--
-- Solution 12.4
--

pictureToRep :: Picture -> (Int, Int, [(Int,Int)] )

pictureToRep pic
  = (width, height, concat [ lineToRep i line | (i,line)<-zip [0..height-1] pic ] )
    where 
    height = length pic
    width  = length (head pic)
    pair i x = (i,x)

lineToRep :: Int -> [Char] -> [(Int,Int)]

lineToRep i str 
  = concat [ if ch=='#' then [(i,j)] else [] | (ch,j) <- zip str [0..length str -1] ]

-- to test

testHorse = printPicture (uncurry3 makePicture (pictureToRep horse))

--
-- Solutions 12.5,6
--

-- Not so different for relfection and rotation, except that the functions mapped etc
-- do some numeric manipulation.

-- beside and above, need to do some index manipulation too (e.g. adding height1 to all 
-- the row numbers of the second pic)

-- combination is the most complex: invertColour need indexes precisely where they were
-- absent (could use list difference here) and superposition the most complex: need to merge
-- the two lists, eliminating duplicates.

-- all good exercises ... 

--
-- Solution 12.7
--

-- Make a random choice of which Strategy to use, 
-- each turn.

sToss :: Strategy -> Strategy -> Strategy

sToss str1 str2 moves =
    case randInt 2 of
      1 -> str1 moves
      0 -> str2 moves

--
-- Solution 12.8
--

alternativeList :: [Strategy] -> Strategy

alternativeList [] = randomStrategy

alternativeList strs 
  =  \moves -> (strs !! ((length moves) `rem` len)) moves 
     where
     len = length strs

--
-- Solution 12.9
--

sTossList :: [Strategy] -> Strategy
 
sTossList [] = randomStrategy

sTossList strs
  = \moves -> (strs !! fromIntegral (randInt (fromIntegral (length strs - 1)))) moves


--
-- Solution 12.10
--

-- make a random choice between the three constant strategies ...

randomStrategy' = sTossList [rock,paper,scissors]

--
-- Solution 12.11
--

majority :: [Strategy] -> Strategy

majority strs
  = \moves -> let 
               outcomes = mapFuns strs moves
               major    = undef :: [Chapter8.Move]
              in
               if null major 
                 then randomStrategy moves
                 else head major
               
undef = undef 

-- return the majority in a singleton list if
-- there is one, otherwise return []


maj moves
  = if rs>ss && rs>ps 
       then [Rock]
       else if ps>ss && ps>rs
            then [Paper]
            else if ss>ps && ss>rs
                 then [Scissors]
                 else []
      where
      rs = count Rock 
      ps = count Paper 
      ss = count Scissors 
      count mv = length [ 1 | m<-moves, m==mv]

--
-- Solution 12.12
--

-- Model the solution on 12.11 ...

--
-- Solution 12.13
--

splits :: [a] -> [([a],[a])]

splits [] = [([],[])]

splits ys@(x:xs) 
  = ([],ys) : map addX (splits xs)
    where
    addX (zs,ws) = (x:zs,ws)

--
-- Solution 12.14, 15
--

-- even-length lists of a's and b's

--
-- Solution 12.16
--

option :: RegExp -> RegExp

option e = e ||| epsilon

plus :: RegExp -> RegExp

plus e = e <++> star e

--
-- Solution 12.17
--

-- match single character in a given range

range :: Char -> Char -> RegExp

range lo hi str
  = length str == 1 && lo <= ch && ch <= hi
    where
    ch = head str

-- digit string staring with non-zero digit, or just char 0 

digString :: RegExp

digString = (range '1' '9' <++> (star (range '0' '9'))) ||| char '0'

-- following the decimal point is either 0 or digit string ending
-- with non-zero.

fraction :: RegExp

fraction = digString <++> char '.' <++> (((star (range '0' '9')) <++> range '1' '9') ||| char '0')

--
-- Solution 12.18
--

-- b*(a|eps)b*(a|eps)b*
-- b*ab*ab*
-- (a|b|eps)(a|b|eps)(a|b|eps)
-- (a|eps)(ba)*(b|eps)

--
-- Solution 12.19
--

-- This is tricky: not for the faint hearted.

-- first, is it properly defined: what if a label occurs within a star?
-- just can't make sense of it.

-- what about within an alternative? can deal with this, as each possibility
-- gives a binding or not.

-- it essentially becomes a parsing problem, as discussed in Section 17.5,
-- as we need to record what paer of the String has not been consumed in a
-- partial match so as to pass it to the match for the remaining names in the
-- part of the expression as yet unmatched. See discussion on pp 432-433 on 
-- designing data types for this.

--
-- Solution 12.20
--

succNat :: Natural a -> Natural a

succNat n = \f -> f . (n f)

plusNat :: Natural a -> Natural a -> Natural a

plusNat n m = \f -> (m f) . (n f)

timesNat :: Natural a -> Natural a -> Natural a

timesNat n m = \f -> m (n f)

--
-- Solution 12.21
--

toNatural :: Int -> Natural a

toNatural n
  | n<=0        = zero
  | otherwise   = succNat (toNatural (n-1))

-- conversion property

-- if number converted is non-negative and not too big, then 
-- conversion is identity.

prop_conversion :: Int -> Bool

prop_conversion n
  = n>1000 || n<0 || int (toNatural n) == n

prop_nat_plus :: Int ->  Int -> Bool

prop_nat_plus n m
  = n>1000 || m>1000 || n<0 || m<0 || int (plusNat (toNatural n) (toNatural m)) == n+m

--
-- Solution 12.22
--

--      |
--     -------------> x
--      |
--      |
--      |
--     \./
--      y

type Position = (Int,Int)

type Bitmap = Position -> Pixel

type Pixel = Char

type Bitmap1 = (Bitmap,Position)

type Bitmap2 = (Bitmap,Position,Position)

--
-- Solution 12.23
--

-- Convert from Picture to Bitmap1
-- Assumes that Picture is rectangular

convert1 :: Picture -> Bitmap1

convert1 pic
  = (picMap,(width,height))
    where
    picMap (x,y) = pic!!y!!x
    width        = length (head pic)
    height       = length pic

revert1 :: Bitmap1 -> Picture

revert1 (bm,(w,h))
  = [[ bm (j,i) | j<- [0..w-1] ] | i<-[0..h-1] ]

testRevConv = printPicture (revert1 (convert1 horse))
--
-- Solution 12.24
--

-- Investigation. Will have a map of maps, perhaps?

--
-- Solution 12.25
--

-- Assume here that w1=w2: and bm1 above bm2
-- beside is similar in other coordinate

aboveBM :: Bitmap1  -> Bitmap1  -> Bitmap1  

aboveBM (bm1,(w1,h1)) (bm2,(w2,h2))
  = (bm,(w1,h1+h2))
    where
    bm (i,j)
      | j < h1    = bm1 (i,j)
      | otherwise = bm2 (i,j-h1)

testAboveBM = printPicture (revert1 (aboveBM (convert1 horse) (convert1 horse)))

-- flipHBM is similar in other coordinate

flipVBM :: Bitmap1  -> Bitmap1 

flipVBM (bm,(w,h))
  = (bm',(w,h))
    where
    bm' (i,j) = bm (w-1-i,j)

testFlipVBM = printPicture (revert1 (flipVBM (convert1 horse)))

-- rotate as before flipV.flipH
-- rotate90, i<->j more or less
-- invert colour: compose the bm with the Pixel inversion function
-- superimpose: combine functions pointwise

--
-- Solution 12.26
--

-- As the last question, but using the particular representation in
-- Data.Map

--
-- Solutions 12.27-29
--

-- These are projects: essential ideas here, but the projects
--  require understandingmore of the "technology" on Hackage.

--
-- Solution 12.30
--

lines :: Doc -> [Line]

lines doc
  = if doc'==[]
       then []
       else line : lines (dropWhile (/= '\n') doc')
    where
    line = takeWhile (/= '\n') doc'
    doc' = (dropWhile (== '\n') doc) 

--
-- Solution 12.31
--

makeLists', makeLists'' ::  [ (Int,Word) ] -> [ ([Int],Word) ]
makeLists' 
  = map (\(n,st) -> ([n],st))

makeLists'' xs
  = [ ([n],st) | (n,st)<-xs ]

-- similarly for shorten

--
-- Solution 12.32
--

makeRanges :: [Int] -> [(Int,Int)]

toPairs :: [Int] -> [(Int,Int)]

joinRanges :: [(Int,Int)] -> [(Int,Int)]

makeRanges = joinRanges . toPairs

toPairs = map (\n -> (n,n))

joinRanges ((a,b):(c,d):rest)
  | b+1 >= c         = joinRanges ((a,d):rest)
  | otherwise        = (a,b) : joinRanges ((c,d):rest)
joinRanges xs        = xs

addRanges :: [([Int],Word)] -> [([(Int,Int)],Word)]

addRanges = map (\(ns,word) -> (makeRanges ns, word))

-- Insert addRanges into the >.> sequence before shorten.
-- Need to modify the type of shorten, too.

--
 -- Solution 12.33
--

-- in the def of smaller add "|| p==q" after "orderPair q p"

--
-- Solution 12.34
--

-- Can use getUntil to pull together all entries for a particular
-- word and then to amalgamate them.

---
-- Solution 12.35
--

sizer :: (a, [b]) -> Bool

sizer = (>3) . length . snd

--
-- Solution 12.36
--

--- need to make the call to amalgamate take (l1++l2,w1) at the 
-- head of the list, as there may be more entries for w1 in the
-- rest of the list.

--
-- Solution 12.37
--

showIndex :: [([Int],Word)] -> String

showIndex = concat . map showEntry

showEntry :: ([Int],Word) -> String

showEntry (ns, word) = word ++ replicate (20 - length word) ' ' ++ 
                       concat (intersperse ", " (map show ns)) ++ "\n"

intersperse :: String -> [String] -> [String]

intersperse st (x:y:xs) = (x++st) : intersperse st (y:xs)
intersperse st xs       = xs

--
-- Solution 12.38
--

-- redefine numWords like this:

numWords' (number , line)
  = [ (number , word) | word <- Chapter7.splitWords line , length word < 4]

--
-- Solution 12.39
--

-- least change: change sort so that don't remober duplicate entries from the
-- same line, and then finally replace [Int] by its length.

-- simplest solution: don't need to keep line numbers at all, just keep the words, 
-- sort and amalgamate the results.

--
-- Solution 12.40
--

-- one approach is to turn all words into no cap form, but this doesn't work with
-- proper names.

-- to deal with them, need to change the sorting algorithm so that it  deals 
-- with the non-capitalised version of words when sorting them,  but keeps them in
-- the index itself. 

--
-- Solution 12.41
--

sortLs' :: (a -> a -> Bool) -> [a] -> [a]

sortLs' orderPair []     = []
sortLs' orderPair (p:ps)
  = sortLs' orderPair smaller ++ [p] ++ sortLs' orderPair larger
    where
    smaller = [ q | q<-ps , orderPair q p ]
    larger  = [ q | q<-ps , orderPair p q ]

--
-- Solution 12.42
--

-- Need to remove (some) keywords.

--
-- Solution 12.43
--

rangeInts :: Int -> Int -> Int -> [Int]

rangeInts m n p 
  | m>p         = []
  | otherwise   = m : rangeInts n (n+(n-m)) p

--
-- Solution 12.44
--

-- can work by choping off characters from both ends

spal :: String -> Bool

spal st 
  | len <= 1            = True
  | otherwise           = head st == last st && spal (take (len-2) (tail st))
    where
    len = length st

-- can also do by comparing the first half to the reverse of the second half.

--
-- Solution 12.45
--

-- See Solutions7.