------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions5
--
------------------------------------------------------------------------------

module Solutions5 where

import Chapter5 hiding (Shape(..),area)
import Test.QuickCheck 
import Test.HUnit
import Solutions3 hiding ((&&),(||)) -- for minThree
import Chapter3   hiding (max,toUpper)       -- for maxThree
import Data.Char
import Prelude hiding (elem)
import Data.List

--
-- Solution 5.1
--

maxOccurs :: Integer -> Integer -> (Integer,Integer)

maxOccurs x y 
          | x==y        = (x,       2)
          | otherwise   = (max x y, 1)

-- The first definition of maxThreeOccurs uses maxOccurs ...

maxThreeOccurs :: Integer -> Integer -> Integer -> (Integer,Integer)

maxThreeOccurs x y z
          | x==maxYZ       = (x, occsYZ+1)
          | x>maxYZ        = (x, 1) 
          | otherwise      = a
            where
            a@(maxYZ,occsYZ) = maxOccurs y z

-- ... while the second is more like a reference implementation:

maxThreeOccurs' :: Integer -> Integer -> Integer -> (Integer,Integer)

maxThreeOccurs' x y z
               = (maxVal, occurs maxVal)
                 where
                 maxVal = x `max` y `max` z
                 occurs a = occ x + occ y + occ z
                            where
                            occ v = if v==a then 1 else 0 

--
-- Solution 5.2
--

orderTriple:: (Integer,Integer,Integer) -> (Integer,Integer,Integer)

orderTriple (x,y,z)
  = (minThree x y z , middle (x,y,z) , maxThree x y z)

-- This isn't a very pleasant exercise: could optimise the 
-- number of tests by nesting ifs, for example. Interesting
-- case of a list being a neater data structure than a tuple.

middle :: (Integer,Integer,Integer) -> Integer

middle (x,y,z)
  | (x<=y && y<=z) || (x>=y && y>= z)     = y
  | (y<=x && x<=z) || (y>=x && x>= z)     = x
  | otherwise                             = z

--
-- Solution 5.3
--

-- Suppose equation is y = a*x + b, and intercept a b to give 
-- the result

intercept :: Double -> Double -> (Double,Bool)

intercept a b 
  | a==0      = (0,False)
  | otherwise = ((-b)/a,True)

--
-- Solution 5.4
--

-- To test maxThreeOccurs with QuickCheck: 
-- check the two implementations give the same result.

prop_maxThreeOccs :: Integer -> Integer -> Integer -> Bool

prop_maxThreeOccs x y z = 
                  (maxThreeOccurs x y z == maxThreeOccurs' x y z)

-- Otherwise to test it with HUnit will need to think about choosing
-- representative data. One way of cutting it is:
--   - all equal
--   - two equal, one smaller, all three orderings
--   - two equal, one larger, all three orderings
--   - all different, all six orderings


-- To test orderTriple can write another function to check ordering

ordered :: (Integer,Integer,Integer) -> Bool

ordered (x,y,z) = x<=y && y<=z

-- ... and then use that in testing the function itself, by testing that
-- the result is ordered. 

prop_orderTriple :: (Integer,Integer,Integer) -> Bool

prop_orderTriple (x,y,z) 
  = ordered (orderTriple (x,y,z))

-- What else do we need to test? That the elements are the same, and we do that
-- by writing a function to check membership of a triple ...

memberTriple :: (Integer,Integer,Integer) -> Integer -> Bool

memberTriple (x,y,z) w 
  = x==w || y==w || z==w

-- .. and use it in a property which checks whether a random element is
-- a member of the input/output.

prop_orderTriple2 :: (Integer,Integer,Integer) -> Integer -> Bool

prop_orderTriple2 (x,y,z) w
  = memberTriple (x,y,z) w == memberTriple (orderTriple (x,y,z)) w

-- To test the line intercept, need to look at special case and 
-- general case. NB, the y = a*x + b doen't fit the special
-- case of a vertical line, defined by x = c.

--
-- Solution 5.5
--

-- Already adds the extra constructor added in 5.7

perimeter :: Shape -> Float

perimeter (Circle r)       = 2*pi*r
perimeter (Rectangle h w)  = 2*(h+w)
perimeter (Triangle a b c) = a+b+c

--
-- Solution 5.6
--

-- data Item = Item String Int

--
-- Solution 5.7
--

data Shape = Circle Float |
             Rectangle Float Float |
             Triangle Float Float Float
         deriving (Show,Read)

-- A triangle is represented by its three sides.
-- Note that we're not checking that the values represent
-- a "real" triangle.

area :: Shape -> Float

area (Circle r)       = pi*r*r
area (Rectangle h w)  = h*w
area (Triangle a b c) = sqrt(s*(s-a)*(s-b)*(s-c))
                                where
                                s = (a+b+c)/2

-- The definition of isRound doesn't change, in fact, because
-- the Triangle case is handled by the wild card.

isRound :: Shape -> Bool

isRound (Circle _) = True
isRound _          = False

--
-- Solution 5.8
--

regular :: Shape -> Bool

regular (Circle _) = True
regular (Rectangle h w) = h==w
regular (Triangle a b c) = a==b && b==c

--
-- Solution 5.9
--

-- Not mush to say here ... just look at some examples.

--
-- Solution 5.10
--

-- To make this a real equality we use a construct that's introduced 
-- later in the book. Alternatively can define a function
--   eq :: Shape -> Shape -> Bool

instance Eq Shape where
  Circle r == Circle s  = if r<0 && s<0 then True else r==s
  Circle r == _         = False
  Rectangle h w == Rectangle h' w' 
                        = if (h<0 || w<0) && (h'<0 || w'<0) then True else h==h' && w==w'
  _   == _              = False -- to be completed.

--
-- Solution 5.11
--

-- Define a type for positions ...

data Pos = Pos Float Float
     deriving (Eq, Ord,Show, Read)

-- ... which can be used in the NewShape definition

data NewShape = CircleP Float Pos |
                RectangleP Float Float Pos |
                TriangleP Float Float Float Pos
            deriving (Show,Read)

--
-- Solution 5.12
--

move :: Float -> Float -> NewShape -> NewShape

move x y (CircleP r p) = CircleP r (movePos x y p)
move x y (RectangleP h w p) = RectangleP h w (movePos x y p)
move x y (TriangleP a b c p) = TriangleP a b c (movePos x y p)

movePos :: Float -> Float -> Pos -> Pos

movePos x y (Pos x' y') = Pos (x+x') (y+y')

--
-- Solution 5.13
--

-- Throught the solution we assume that the shapes are proper e.g. positive lengths for 
-- size etc.

-- This is more complicated than one might like

overlap :: NewShape -> NewShape -> Bool

-- two rectangles: horizontal distance between centres less than half  
-- of the sum of their width and similar for vertical

overlap (RectangleP h w (Pos x y)) (RectangleP h' w' (Pos x' y'))
  = (w+w')/2 >= abs (x-x') && (h+h')/2 >= abs (y-y')
    

-- two circles: distance between their centres is less than or
-- equal to the sum of their radii

overlap (CircleP r (Pos x y)) (CircleP r' (Pos x' y'))
  = sqrt( sq(x-x') + sq(y-y') ) <= r+r'
    where sq v = v*v

-- a circle and a rectangle: more special cases. Need to look at 
-- how the distance between the centres of the two shapes relate
-- to the corners of the rectangle. Need the sume of these distances
-- to be smallet than the inter-centre distance.

--
-- Solution 5.14
--

data NumOrName = Number Int |
                 Name String
                 deriving (Show)

-- Printing a "number or name"
-- Note that if we just derive the show function, then this will give 
--   show (Name "foo") = "Name \"foo\""
-- rather than just "foo"

showNumOrName :: NumOrName -> String

showNumOrName (Number n)  = show n
showNumOrName (Name name) = name

data NameAddress = NA String Address

-- Note the following definition which gives comments
-- on the purpose of the fields.

data Address = Address 
               NumOrName -- house number/name
               String    -- street
               String    -- city
               String    -- postcode

--
-- Solutions 5.15-17
--



-- These are exercises to get students to understand
-- some of the "corner cases" of the range notation, and what 
-- happens in calculating termination conditions.

--
-- Solution 5.18
--

doubleAll :: [Integer] -> [Integer]

doubleAll ns = [ 2*n | n<-ns ]

--
-- Solution 5.19
--

-- Solutions here use standard functions from Data.Char

capitalize :: String -> String

capitalize str = [ cap ch | ch<-str ]
                 where
                 cap ch = if isLower ch 
                             then toUpper ch
                             else ch

--- to select just the letters, need to add a test:

capitalizeLetters :: String -> String

capitalizeLetters str = [ cap ch | ch<-str, isLetter ch ]
                 where
                 cap ch = if isLower ch 
                             then toUpper ch
                             else ch

--
-- Solution 5.20
--

divisors :: Integer -> [Integer]

divisors n = [ m | m <- [1..n], n `rem` m == 0]

isPrime :: Integer -> Bool

isPrime n = length (divisors n) == 2

--
-- Solution 5.21
--

matches :: Integer -> [Integer] -> [Integer]

matches m ns 
  = [ n | n<-ns, n==m]

{-

commented out as need the orginal definition of elem
later in the chapter

elem :: Integer -> [Integer] -> Bool

elem m ns = matches m ns /= []
-}

--
-- Solution 5.22
--

-- uses the built-in function concat which joins a list-- of lists into a single list

onSeparateLines :: [String] -> String

onSeparateLines strs
  = concat [ st++"\n" | st <- strs ]

--
-- Solution 5.23
--

duplicate :: String -> Integer -> String

duplicate st n
  = concat [ st | m<-[1..n] ]

--
-- Solution 5.24
--

pushRight :: String -> String

pushRight st = duplicate " " (12 - fromIntegral (length st)) ++ st

-- A property for pushRight: either the string's longer than 12 to 
-- start with, or the result of pushRight is of length 12.

prop_pushRight :: String -> Bool

prop_pushRight st = length st > 12 || length (pushRight st) == 12

--- Generalising over the line length ... 

pushRight' :: Int -> String -> String

pushRight' linelen st = duplicate " " (fromIntegral (linelen - (length st))) ++ st

-- Without the initial bound on the size of the Int get some ridiculous line lengths!

prop_pushRight' :: Int -> String -> Bool

prop_pushRight' linelen st = linelen >= 1000 || length st > linelen || length (pushRight' linelen st) == linelen

--
-- Solution 5.25
--

-- Problem: what if the string is longer than the line. 
-- One way this is apparent is in from writing the naive property, for which
-- the simplest counterexample is 
--   *** Failed! Falsifiable (after 19 tests and 14 shrinks):     
--   "aaaaaaaaaaaaa"

prop_pushRightNaive :: String -> Bool

prop_pushRightNaive st = length (pushRight st) == 12

--
-- Solution 5.26
--

-- Can use many of the functions defined earlier:

fibTable :: Integer -> String

fibTable n 
  = onSeparateLines (header : body)
    where
    header = pushRight "n" ++ pushRight "fib n"
    body = [ pushRight (show m) ++ pushRight (show (fib m)) | m<-[1..n] ]
    fib 1 = 1
    fib 2 = 1
    fib n = fib (n-1) + fib (n-2)

-- to have this print properly use e.g.
--   putStr (fibTable 12)

--
-- Solution 5.28
--

borrowers :: Database -> Book -> [Person]
borrowers dBase findBook
  = [ person | (person,book) <- dBase , book==findBook ]

borrowed :: Database -> Book -> Bool
borrowed dBase findBook
  = borrowers dBase findBook /= []

numBorrowed :: Database -> Person -> Int

numBorrowed db findBook = length (books db findBook)

--
-- Solution 5.30
--

-- Need to rrplace all pattern matches 
--    (person,book) <- dBase
-- by
--    Loan person book <- dBase

--
-- Solution 5.31
--

-- "if not blah then foo" is equivalent to "blah || foo"


prop_Loan :: Book -> Book -> Person -> Database -> Bool

prop_Loan bk bk2 pers db
  = elem pers (borrowers db bk) || not (elem pers (borrowers afterLoan bk))
    where
    afterLoan = makeLoan db pers bk2

-- This property fails, because bk and bk2 can be the same. So, we just want to look at the case where 
-- bk and bk2 are different: can achieve this by adding to the test a disjunction bk==bk2, 
-- which is equaivalent to
--    if bk/=bk2 then ....

--
-- Solution 5.32
--

-- Need to redefine all the functions. With the representation [(Person,[Book])] 
-- it's easier to define books, but harder to define borrowers

type NewBase = [(Person,[Book])]

books' :: NewBase -> Person -> [Book]

books' ndb per 
  = head [ books | (pers,books)<-ndb , pers==per ]

-- why the head here? Because books is a [Book] and so the list containing just
-- this is a [[Book]]: we get its only element by taking its head. 

-- We could avaoid this by defining the function using recursion, which we find 
-- out about in the chapter 7.

booksRec :: NewBase -> Person -> [Book]

booksRec [] per = []

booksRec ((pers,books):db) per
  = if pers==per 
       then books 
       else booksRec db per

-- need to check whether the findBook is a member of the books list belonging
-- to each person ...

borrowers' :: NewBase -> Book -> [Person]

borrowers' dBase findBook
  = [ person | (person,books) <- dBase , elem findBook books ]

-- 
-- Solution 5.33
--

-- As long as the interfaces are the same, the tests can still be used, with 
-- the appropriate modification to the type declaration from Database to NewBase

-- 
-- Solution 5.34
--

-- Use a tablular format as in solution 5.26
-- Can re-use functions defined earlier in the chapter, just
-- as 5.26 does.
