------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions6
--
------------------------------------------------------------------------------

module Solutions6 where

-- import Pictures hiding (printPicture,prop_AboveFlipH)
import Test.QuickCheck
import Chapter6 hiding (prop_AboveFlipH, Image, Position)
import Prelude hiding (lookup)


--
-- Solutions 6.1-6.3
-- 

-- snd :: (a,b) -> a

-- This assumes it takes a list of lists into a list of lists, but in fact 
-- can take *any* type to that type.

-- shift :: ((a,b),c) -> (a,(b,c))

--
-- Solution 6.4
-- 

superimposeChar :: Char -> Char -> Char

superimposeChar '.' '.' = '.'
superimposeChar  _   _  = '#'

--
-- Solution 6.5
-- 

superimposeLine :: [Char] -> [Char] -> [Char]

superimposeLine line1 line2
  = [ superimposeChar ch1 ch2 | (ch1,ch2) <- zip line1 line2 ]

--
-- Solution 6.6
-- 

superimpose :: Picture -> Picture -> Picture

superimpose pic1 pic2
  = [ superimposeLine line1 line2 | (line1,line2) <- zip pic1 pic2 ]

--
-- Solution 6.7
-- 

printPicture :: Picture -> IO ()
printPicture pic
  = putStr (concat [ line ++ "\n" | line <-pic ])

--
-- Solution 6.8
-- 

rotate90 :: Picture -> Picture

rotate90 pic
  = [ [ line!!i | line <- reverse pic] | i <- [0 .. numCols-1] ]
    where
    numCols = length (head pic)

-- The number of columns in the original picture is given by 
-- taking the length of one of the rows (all assumed to be the
-- same length).

-- We then get the first row in the new picture by picking out the
-- ith element of each line in the original picture for i, running 
-- through the lines in reverse order: see following diagram

{-

original pic

 0-----<
 1-----<
 2-----<

new pic

 210
 |||
 |||
 |||
 |||
 ^^^

-}

--
-- Solution 6.9
-- 

rotate270 :: Picture -> Picture

rotate270 pic
  = rotate (rotate90 pic)

-- to rotate through 180 degrees flip horizontally and vertically

rotate pic = flipH (flipV pic)

--
-- Solution 6.10
-- 

scaleLine :: [Char] -> Int -> [Char]

scaleLine line n
  = concat [ replicate n ch | ch<-line ]

scale :: Picture -> Int -> Picture

scale pic n
  = concat [ replicate n (scaleLine line n) | line <- pic]

--
-- Solution 6.11
-- 

prop_AboveFlipH :: Picture -> Picture -> Bool

prop_AboveFlipH pic1 pic2 = 
    flipH (pic1 `above` pic2) == (flipH pic2) `above` (flipH pic1) 

--
-- Solution 6.12
-- 

-- Why doesn't this work? only ok of the two pictures the same height.

prop_BesideFlipH, prop_BesideFlipV :: Picture -> Picture -> Bool

prop_BesideFlipH pic1 pic2 = 
    flipH (pic1 `beside` pic2) == (flipH pic1) `beside` (flipH pic2) 

-- This works with arbitary pictures ...

prop_BesideFlipV pic1 pic2 = 
    flipV (pic1 `beside` pic2) == (flipV pic2) `beside` (flipV pic1) 

--
-- Solution 6.13
-- 

prop_FourPix :: Picture -> Bool

prop_FourPix pic
  = ((pic `beside` pic) `above` (pic `beside` pic)) 
      ==
    ((pic `above` pic) `beside` (pic `above` pic))

--
-- Solution 6.14
-- 

-- property: will this hold?

prop_rotate90 :: Picture -> Bool

prop_rotate90 pic
  = pic == rotate90 (rotate270 pic)

--
-- Solution 6.15
-- 

-- Would expect that inverting twice would go back to the original
-- picture, but can only be sure of this if the original picture is
-- made up of '.' and '#' only.

--
-- Solution 6.16
-- 

-- Best thing is to try it out: does it pass tests? If so, looks ok,
-- otherwise need to add a condition.

prop_AboveBeside4 :: Picture -> Picture -> Bool

prop_AboveBeside4 n s =
  (n `beside` n) `above` (s `beside` s) 
  == 
  (n `above` s) `beside` (n `above` s) 

--
-- Solution 6.17
-- 

-- Assumption here is that Pictures are rectangular; the 
-- functions defined here will preserve that.

widthP, heightP :: Picture -> Int

widthP pic = length (head pic)
heightP pic = length pic

abovePad :: Picture -> Picture -> Picture

abovePad pic1 pic2
 = above pic1Pad pic2Pad
   where
   pic1Pad = if width1 < width2
                then padRight pic1 (width2 - width1)
                else pic1
   pic2Pad = if width2 < width1
                then padRight pic2 (width1 - width2)
                else pic2
   width1 = widthP pic1
   width2 = widthP pic2

padRight :: Picture -> Int -> Picture

padRight pic n 
  = [ line ++ replicate n '.' | line<-pic ]

-- Similarly for beside and the other functions ....

--
-- Solution 6.18
-- 

padPicture :: Picture -> Picture

--- takes an arbitrary picture and pads it out to the right.

padPicture pic
  = [ line ++ replicate (maxLen - length line) '.' | line <- pic ]
    where
    maxLen = maximum [ length line | line <- pic ]

--
-- Solution 6.19
-- 

-- Don't need to change things like above or beside; only thing
-- that would need to change is the set of superimposition functions
-- and a function to print the results. Can do this by a conversion function:

convertB :: [[Bool]] -> Picture

convertB bpic
  = [ [ if b then '#' else '.' | b<-bline ] | bline<-bpic ]

--
-- Solution 6.20
--

-- Will have similar definitions but with the roles of above and beside
-- reversed.

--
-- Solution 6.21
--

-- The easiest way of doing this is to convert from a column representation
-- and then to pront as a standard Picture.

convertCol :: Picture -> Picture

convertCol colPic
  = [ [col!!i | col<-colPic ] | i<-[0..numRows-1] ]
    where
    numRows = length (head colPic)

--
-- Solution 6.22
--

-- It will be easier to print these things, and to put one picture above
-- another, but much more difficult to put one picture beside another. 
-- Basically to do that, need first to process into [[Char]] style pictures
-- and then to perform beside over this representation.

--
-- Solution 6.23
--

-- The same implementation works for above, beside and rotate. Need to think
-- harder about how to define rotate90, superimpose etc.

-- Thinking about rotate90, need to define the equivalent of line!!i when
-- the line is run-length encoded. Will need to take acount of encoding in 
-- looking up. One mechanism is to make the conversion into an "ordinary" line
-- and then to lookup the ith element using !!i.

convertRun :: [(Int,Char)] -> [Char]

convertRun line
  = concat [ replicate n ch | (n,ch)<-line ]

-- Given this conversion function can the print using printPicture.

--
-- Solution 6.24
--

-- This is tricky to do with the tools that we have at our disposal
-- as we really need to use recursion, as introduced in Chapter 7.

-- For example, this normalises run-length encodings, and one option is 
-- to perform the operations and then normalise afterwards.

normaliseRep :: [(Int,Char)] -> [(Int,Char)]

normaliseRep ((n,ch1):(m,ch2):rest)
  | ch1==ch2    = normaliseRep ((n+m,ch1):rest)
  | otherwise   = (n,ch1) : normaliseRep ((m,ch2):rest)

normaliseRep xs = xs

--
-- Solution 6.25
--

-- Need to modify the types of the functions declared, but once that's done
-- the properties should be the same.

-- One place where properties might fail is the case where runlength encoding
-- is used, since this can be non-canonical: when comparing two such representations
-- need to make sure that both sides are normalised before comparing for equality.

--
-- Solution 6.26
--

-- This representation makes defining some of the functions much more difficult:
--   - above can be implemented by ++ (followed by normalisation)
--   - beside is a real problem: need to convert the representation into lines
--     before doing the operation; then re-normalise
--   - rotate is given by reversing the list, but flipV and flipH also need representation
--     to be converted into lies before performing the operation
-- It's a general point that we can always represent a transformation by
--    convert from Picture . do the transformation on Picture . convert to Picture
-- whatever the representation.

--
-- Solution 6.27
--

-- Just give the list of lengths together with the starting symbol.

--
-- Solution 6.28
--

-- There are lots of different possible mechanisms
--  - represent by quadtrees: divide at the top level into 4 areas
--    NW, NE, SW, SE which themselves are constant or a quadtree themselves
--  - mapping from ([0..n],[0..m]) to values (Char or Bool or ...)

--
-- Solution 6.29
--

type Position = (Int,Int)

type Image = (Picture,Position)

makeImage :: Picture -> Position -> Image

makeImage pic pos = (pic,pos)

--
-- Solution 6.30
--

changePosition :: Image -> Position -> Image

changePosition (pic,_) pos = (pic,pos)

--
-- Solution 6.31
--

moveImage :: Image -> Int -> Int -> Image

moveImage (pic,(x,y)) n m = (pic, (x+n,y+m))

--
-- Solution 6.32
--

-- one way of doing this is just to print the picture part ...

printImage :: Image -> IO ()

printImage (pic,_) = printPicture pic

-- ... alternatively could try to offset from the origin in printing.

--
-- Solution 6.33-4
--

-- Here we give the geometrical view of the transformations.

-- assuming that the horizontal mirror is along the x axis

flipHimage :: Image -> Image

flipHimage (pic, (x,y))
  = (flipH pic, newPos)
    where
    newPos = (x, -y-(heightP pic))

flipVimage :: Image -> Image

flipVimage (pic, (x,y))
  = (flipV pic, newPos)
    where
    newPos = (-x-(widthP pic), y)

rotateImage :: Image -> Image

rotateImage img = flipVimage (flipHimage img)

-- rotate90 is left as an exericise.

--
-- Solutions 6.35-38
--

-- Padding treated earlier in the chapter.
-- Once padding is given, superimposition is straightforward.

--
-- Solution 6.39
--

formatPence :: Price -> String

formatPence n 
  = show pounds  ++ "." ++ pad (show pence)
    where
    pounds = n `div` 100
    pence  = n `rem` 100
    pad st = replicate (2 -length st) '0'++ st
    
--
-- Solution 6.40
--

formatLine :: (Name,Price) -> String

formatLine (str,price)
  = str ++ replicate (lineLength - length str - length priStr) '.' ++ priStr ++ "\n"
    where
    priStr = formatPence price

-- price >=0 && length str < lineLength - length (show price) ==> length (formatLine (str,price)) == lineLength

prop_formatLine (str,price)
  = price<0 || length str >= lineLength - length (show price) || length (formatLine (str,price)) == lineLength+1

--
-- Solution 6.41
--

formatLines :: BillType -> String

formatLines lines
  = concat [ formatLine line | line <- lines ]

--
-- Solution 6.42
--

makeTotal :: BillType -> Price

makeTotal bill
  = sum [ price | (_,price)<- bill ]

--
-- Solution 6.43
--

formatTotal :: Price -> String

formatTotal total
  = "\n" ++ formatLine ("Total",total)

--
-- Solution 6.44
--

formatBill :: BillType -> String

formatBill bill
  = heading ++ items ++ tot
    where
    heading = "        Haskell Stores\n\n"
    items = formatLines bill
    tot   = formatTotal (makeTotal bill)

exampleBill :: BillType

exampleBill = [ ("Dry Sherry, 1lt", 540), ("Fish Fingers" , 121),
                ("Orange Jelly", 56), ("Hula Hoops (Giant)", 133),
                ("Unknown Item", 0), ("Dry Sherry, 1lt", 540) ]

--
-- Solution 6.45
--

look :: Database -> BarCode -> (Name,Price)

look [] _ = ("Unknown Item", 0)
look ((bc,name,price):db) code
  | bc==code     = (name,price)
  | otherwise    = look db code

--
-- Solution 6.46
--

-- Need to include the directive
--  import Prelude hiding (lookup)
-- to hide the Prelude version of lookup.

lookup :: BarCode -> (Name,Price)

lookup bc = look codeIndex bc

--
-- Solution 6.47
--

makeBill :: TillType -> BillType

makeBill till
  = [ lookup bc | bc<-till ]

egTill :: TillType

egTill = [1234, 4719, 3814, 1112, 1113, 1234]

example = putStr (formatBill (makeBill egTill))

--
-- Solution 6.48
--

makeDiscount :: BillType -> Price

makeDiscount bill
  = 100 * (sum [ 1 | item<-bill, item==("Dry Sherry, 1lt", 540) ] `div` 2)

formatDiscount :: Price -> String

formatDiscount price 
  = "\n" ++ formatLine ("Discount",price)

formatBillDiscount :: BillType -> String

formatBillDiscount bill
  = heading ++ items ++ discount ++ tot
    where
    heading = "        Haskell Stores\n\n"
    items    = formatLines bill
    disc     = makeDiscount bill
    discount = formatDiscount disc
    total    = makeTotal bill - disc
    tot      = formatTotal total

--
-- Solution 6.49
--

-- Modelled on makeLoan for the library database.

--
-- Solution 6.50
--

-- The hints explain the two possible mechanisms
-- to implement the latter need to change the implementation of look
-- in the [] case.

--
-- Solution 6.51
--

-- Probably best to unit test the various functions which perform
-- the functionality: testing the formatting functions is of less value, 
-- and more sensitive to trivial errors than the actual "under the hood"
-- mechanism.

--
-- Solution 6.52
--

-- Project.


--
-- Solution 6.53
--

-- These are nice exercises in data design. Agruably it is better to look at these
-- once students have met recursion in Chapter 7, as this allows more natural 
-- definitions of some of the functions, e.g. to search for the winning card in a
-- trick.

data Suit = Clubs 
          | Diamonds
          | Hearts
          | Spades
          deriving (Eq,Ord,Show,Enum)

--- Deriving Enum means that we can number the suits
-- from 0 (Clubs) to 3 (Spades) and move between the
-- two using fromEnum and toEunum

-- It's very useful to derive Ord on
-- Value, so that we can compare values.

data Value = Two
           | Three
           | Four
           | Five
           | Six
           | Seven
           | Eight
           | Nine
           | Ten
           | Jack
           | Queem
           | King
           | Ace
           deriving (Eq,Ord,Show,Enum)

-- Would it have been clearer to call this Card instead of Deck?

data Deck = Card Suit Value
          deriving (Eq,Ord,Show)

--
-- Solution 6.54
--

-- Discussion

--
-- Solution 6.55
--

-- Players are ordered clockwise.

data Player = North
            | East
            | South
            | West
            deriving (Eq,Ord,Show,Enum)

--
-- Solution 6.56
--

type Trick = (Player,[Deck])

-- the Player is the lead, the cards are those played, starting with the leader,
-- in clockwise order

-- ALTERNATIVE: could have the cards in order North ... clockwise. Might make things
-- simpler in later exercises ...


--
-- Solution 6.57
--

-- Need to find the highest card of the suit led,
-- and to return the corresponding player.

-- See note at the start of the section: might be clearer to do this 
-- with recursion, so could return to / postpone until Chapter 7.

-- Idea in this algorithm:
--  - find winning card
--  - look it up in the list

winNT :: Trick -> Player

winNT (lead,cards)
  = findCard maxCard (lead,cards) -- auxiliary function, defined next
  where
  maxCard  = maximum [ card | card<-cards, suit card == suitLead ]
  suitLead = suit (head cards)

suit :: Deck -> Suit
suit (Card s _) = s

-- This is a bit tricky because we don't have recursion. We pair up the 
-- cards with their position in the list, and return the position the 
-- card we're looking for (find). Because we're using a list comprehension
-- we return a list, and so we need to take the head to get the (single)
-- element in the list.

-- We then associate that with the appropriate player by index trickery.

findCard :: Deck -> Trick -> Player

findCard find (lead,cards)
  = toEnum ((fromEnum lead + head [ n | (card,n) <- zip cards [0..3], card==find ]) `rem` 4)

-- Example trick

trick1 :: Trick
trick1 = (South,[Card Spades King, Card Spades Two, Card Spades Ace, Card Clubs Two])

--
-- Solution 6.58
--

-- Note reuse of the functions defined in winNT

winT :: Suit -> Trick -> Player

winT trumps (lead,cards)
  | noTrumps    = winNT (lead,cards)
  | otherwise   = findCard maxCard (lead,cards)
  where
  noTrumps = [ card | card<-cards, suit card == trumps ] == []   -- there are no trump cards in the trick
  maxCard  = maximum [ card | card<-cards, suit card == trumps ] -- the maximum trump card

--
-- Solution 6.59
--

type Hand = [Deck]

--
-- Solution 6.60
--

-- In this defintion we use a list to store the four hands in a 
-- list starting with North. 

type Hands = [Hand]

-- Could alternatively have them as four values, as in

data Hands2 = FourHands Hand Hand Hand Hand

-- Or anticipating chapter 8, use a function type.

type Hands3 = Player -> Hand

--
-- Solution 6.61
--

-- An annoyance here is that the Hands are in order from North, 
-- whereas in the trick

possiblePlay :: Hands -> Trick -> Bool

possiblePlay hands (lead,cards)
  = and [ elem card hand | (hand,card) <- zip hands (fromNorth lead cards) ]

-- take a list of cards beginning at Player and 
-- turn it into a list from North:

fromNorth :: Player -> [Deck] -> [Deck]

fromNorth player cards
  = rear ++ front
    where
    offset = 4 - fromEnum player
    rear = drop offset cards
    front = take offset cards

-- Once we've defined the simpler function possiblePlay we can use it as a 
-- model for the more complicated legalPlay, again reusing the auxiliary 
-- function fromNorth

legalPlay :: Hands -> Trick -> Bool

legalPlay hands (lead,cards)
  = and [ legal leadSuit card hand | (hand,card) <- zip hands (fromNorth lead cards) ]
    where
    leadSuit = suit (head cards) -- the lead suit is the suit of the first card.

-- The Suit here is the suit led, and so should be played if there's any such 
-- card available; otherwise can play anything you wish.

legal :: Suit -> Deck -> Hand -> Bool

legal leadSuit card hand
  = if [ card | card<-hand, suit card == leadSuit ] /= [] 
       then suit card == leadSuit
       else True

-- Finally ..

checkPlay :: Hands -> Trick -> Bool

checkPlay hands trick 
  = possiblePlay hands trick && legalPlay hands trick

-- It's possible to put these two sub-functions into a single 
-- top-level definition of checkPlay, but the development here
-- represents a natural way of building the functions.

--
-- Solutions 6.62 and 6.63
--

-- Left for the reader.


