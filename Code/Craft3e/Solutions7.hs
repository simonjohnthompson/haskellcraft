------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions7
--
------------------------------------------------------------------------------

module Solutions7 where

import Test.QuickCheck
import Chapter7 hiding (head,tail,zip,dropLine,concat)
import Chapter5 (digits)
import Prelude hiding (product,and,or,(++),reverse,unzip,take,drop,zip3,sum)
import qualified Prelude
import Data.Char

--
-- Solution 7.1
-- 

-- Note that can use a wildcard for the tail of the non-empty list.

firstInt :: [Integer] -> Integer

firstInt []    = 0
firstInt (n:_) = n+1


--
-- Solution 7.2
-- 

-- Again we can use wildcards here.

sft :: [Integer] -> Integer

sft (n:m:_) = n+m
sft [n]     = n
sft _       = 0

-- could also replce [n] by (n:_) and the final
-- wildcard by [] for clarity.

--
-- Solution 7.3
-- 

firstInt' :: [Integer] -> Integer

firstInt' ns
  = if ns==[] 
       then 0 
       else head ns + 1

sft' :: [Integer] -> Integer

sft' ns
  = if ns==[]
       then 0
       else if tail ns == []
               then head ns
               else head ns + head (tail ns)

--
-- Solution 7.4
-- 

firstDigit' :: String -> Char

firstDigit' st
  = if digs==[]
       then '\0'
       else head digs
    where
    digs = digits st

--
-- Solution 7.5
-- 

product :: [Integer] -> Integer

product []     = 1
product (n:ns) = n * product ns

--
-- Solution 7.6
-- 

and,or :: [Bool] -> Bool

and []     = True
and (b:bs) = b && and bs

or []     = False
or (b:bs) = b || or bs

--
-- Solution 7.7
-- 

-- For example ...

prop_conjunction :: [Bool] -> Bool

prop_conjunction bs
  = and bs == Prelude.and bs

--
-- Solution 7.8
-- 

elemNum :: Integer -> [Integer] -> Integer

elemNum n []     = 0
elemNum n (x:xs) 
  | n==x         = 1 + elemNum n xs
  | otherwise    =     elemNum n xs

--
-- Solution 7.9
-- 

unique :: [Integer] -> [Integer]

unique ns
  = [ n | n<-ns, elemNum n ns == 1 ]

unique' :: [Integer] -> [Integer]

unique' [] = []
unique' (n:ns)
  | elem n ns     = unique' [ m | m<-ns, m/=n ]
  | otherwise     = n : unique' ns

--
-- Solution 7.10
-- 

-- Remember that "not a || b" is equivalent to "a implies b" ...

prop_uniqueness :: Integer -> [Integer] -> Bool

prop_uniqueness n ns
  = (elemNum n ns /= 1 || elem n (unique ns)) &&
    ( not (elem n (unique ns)) || elemNum n ns == 1)

--
-- Solution 7.11
-- 

reverse :: [Integer] -> [Integer]

reverse []     = []
reverse (n:ns) = reverse ns ++ [n]

unzip :: [(Integer,Integer)] -> ([Integer],[Integer])

unzip []         = ([],[])
unzip ((n,m):ps) = (n:ns,m:ms)
                   where
                   (ns,ms) = unzip ps

--
-- Solution 7.12
-- 

-- assumes that argument is non-empty.

mini,maxi :: [Integer] -> Integer

mini ns = head (iSort ns)

maxi ns = last (iSort ns)


--
-- Solution 7.13
-- 

-- Insert into an empty list
-- for a non-empty list look at
--  - insert at start, second place, middle, penultimate, at end
--  - could also check what happens with instered element already in the list


--
-- Solution 7.14
-- 

isSorted :: [Integer] -> Bool

isSorted []       = True
isSorted [x]      = True
isSorted (x:y:zs) = x<=y && isSorted (y:zs)

prop_ins :: Integer ->  [Integer] -> Bool

prop_ins n ms
  = not (isSorted ms) || isSorted (ins n ms)

-- note that prop_iSort doesn't guanrantee that 
-- the elements of the list are preserved.

prop_iSort :: [Integer] -> Bool

prop_iSort ms
  = isSorted (iSort ms)

--
-- Solution 7.15
-- 

-- This checks that each element occurs the same number of times
-- in the input and output

prop_sort_perm :: Integer -> [Integer] -> Bool

prop_sort_perm m ns 
  = elemNum m ns == elemNum m (iSort ns)

--
-- Solution 7.16
-- 

ins' :: Integer -> [Integer] -> [Integer]

ins' n [] = [n]
ins' n (m:ms)
  | n>=m      = n :(m:ms)
  | otherwise = m : ins' n ms


ins'' :: Integer -> [Integer] -> [Integer]

ins'' n [] = [n]
ins'' n (m:ms)
  | n<m       = n :(m:ms)
  | n==m      = m:ms  
  | otherwise = m : ins' n ms


--
-- Solution 7.17
-- 

-- This prefigures the situation where the 
-- insertion function is passed in as an argument.


--
-- Solution 7.18
-- 


dupSort :: [Integer] -> [Integer]

dupSort [] = []
dupSort (x:xs) = ins'' x (dupSort xs)

prop_dupSort :: [Integer] -> Bool

prop_dupSort ms
  = isSorted (iSort ms)

prop_dupSort_perm :: Integer -> [Integer] -> Bool

prop_dupSort_perm m ns 
  = elem m ns == elem m (dupSort ns)

-- The following property fails (eventually!) ...
-- ... this is a good lesson that 100 tests passed
-- don't mean that a property holds.

prop_dupSort_perm2 :: Integer -> [Integer] -> Bool

prop_dupSort_perm2 m ns 
  = elemNum m ns == elemNum m (dupSort ns)


--
-- Solution 7.19
-- 

-- The pair ordering is given by

pairOrd :: (Integer,Integer) -> (Integer,Integer) -> Bool

pairOrd (a,b) (c,d) 
  = a<c || (a==c && b<d)

-- ... then build variants of ins and iSort on top.
-- Of course, could make ins and iSort parametric on this 
-- ordering.

--
-- Solution 7.20
-- 

drop :: Int -> [a] -> [a]

drop 0 xs = xs
drop _ [] = []
drop n (x:xs)
  | n>0         = drop (n-1) xs
drop _ _ = error "drop"

-- The following property fails without the check for n<0.

prop_take_drop :: Int -> [Integer] -> Bool

prop_take_drop n xs
  = n<0 || (take n xs ++ drop n xs == xs)

--
-- Solution 7.21
-- 

take' :: Int -> [a] -> [a]

take' n xs
  | n<0         = error "negative argument to take"
-- with the rest of the defintion as before (with last case omitted)

--
-- Solution 7.22
-- 

zip' (xs,ys) = zip xs ys

-- This one holds

prop_zip_unzip :: [(Integer,Integer)] -> Bool

prop_zip_unzip zs
  = zip' (unzip zs) == zs

-- This one fails with lists of different lengths

prop_unzip_zip :: [Integer] -> [Integer] -> Bool

prop_unzip_zip xs ys
  = unzip (zip' (xs,ys)) == (xs,ys)

--
-- Solution 7.23
-- 

zip3 :: [a] -> [b] -> [c] -> [(a,b,c)]

zip3 (x:xs) (y:ys) (z:zs) = (x,y,z) : zip3 xs ys zs
zip3 _ _ _                = []

zip3' :: [a] -> [b] -> [c] -> [(a,b,c)]

zip3' xs ys zs 
  = [ (x,y,z) | (x,(y,z))<- zip xs (zip ys zs) ]

prop_zip3 :: [Integer] -> [Integer] -> [Integer] -> Bool

prop_zip3 xs ys zs
  = zip3 xs ys zs == zip3' xs ys zs

--
-- Solution 7.24
-- 

-- swap the order of the recursive calls:
--   qSort larger ++ [x] ++ qSort smaller

-- make the selection in smaller part *strict* y<x rather than y<=x

--
-- Solution 7.25
-- 

-- Can make this more general, in fact, for any type which has equality.
--   subList :: Eq a => [a] -> [a] -> Bool

subList :: String -> String -> Bool

subList [] xs     = True
subList (x:xs) [] = False
subList (x:xs) (y:ys)
  = (x==y && subList xs ys) ||
    subList (x:xs) ys

-- subsequence is a bit trickier: once you have begun a subsequence
-- the remainder must follow immediately: hence the definition of
-- the auxiliary function frontSub

subSeq :: String -> String -> Bool

subSeq [] xs     = True
subSeq (x:xs) [] = False
subSeq (x:xs) (y:ys)
  = (x==y && frontSub xs ys) ||
    subSeq (x:xs) ys 

frontSub :: String -> String -> Bool

frontSub [] xs     = True
frontSub (x:xs) [] = False
frontSub (x:xs) (y:ys)
  = (x==y && frontSub xs ys) 

--
-- Solution 7.26
-- 

prop_subSeq xs ys zs
  = subSeq ys (xs++ys++zs)

-- subSeq implies subList ..

prop_subFuns xs ys
  = not (subSeq xs ys) || subList xs ys

-- .. but not the other way round: the 
-- counterexample you get here shows the
-- difference between the two functions

prop_subFuns2 xs ys
  = not (subList xs ys) || subSeq xs ys

--
-- Solution 7.27
-- 

-- Dropping the first line from a list of words.

dropLine :: Int -> [Word] -> Line

dropLine len []     = []
dropLine len (w:ws)
  | length w <= len     = dropLine newlen ws 
  | otherwise           = w:ws
    where
    newlen      = len - (length w + 1)

carnaval :: String

carnaval = "The heat bloomed     in December\n as the   carnival  season\n            kicked into  gear.\nNearly helpless with sun and glare, I avoided Rio's brilliant\nsidewalks\n  and glittering beaches,\npanting in dark   corners\nand waiting out the inverted southern summer."

--
-- Solution 7.28
-- 

joinLine :: Line -> String

joinLine line
  = init (concat [word++" " | word <- line])

--
-- Solution 7.29
-- 

joinLines :: [Line] -> String

joinLines lines
  = concat [ joinLine line ++ "\n" | line<-lines ]

--
-- Solution 7.30
-- 

-- Ideally this should make the program more efficient, as there will be a single 
-- traversal of lists (of letters, words) rather than a double traversal.

-- This has also incorporated into 

getDropWord :: String -> (String,String)

getDropWord []        = ([],[])
getDropWord ys@(x:xs)   
  | elem x whitespace = ([],dropSpace ys)
  | otherwise         = (x:gs,ds)
                        where
                        (gs,ds) = getDropWord xs

--
-- Solution 7.31
-- 

-- if we have k words in the line (and assuming k>1), then we know that there are k-1 gaps, and
-- that we must put at least one space into each. How many spaces do we have to distribute?
--   nSpaces = lineLen - length (concat line)
-- and we have to divide these up somehow. We should put nSpaces `div` (k-1) into each gap, 
-- leaving nSpaces `rem` (k-1) to distribute somehow. The simplest mechanism is to add them to the 
-- spaces on the left, but that leads to a model where there's more white space to the left of
-- the page. A simple remedy for this is to define another function that adds them to the right
-- and to alternate the two.

justify :: Line -> String

justify line
  = concat (front ++ rear ++ end)
    where
    k        = length line
    nSpaces  = lineLen - length (concat line)
    base     = replicate (nSpaces `div` (k-1)) ' '
    basePlus = replicate (nSpaces `div` (k-1) + 1) ' '
    extra    = nSpaces `rem` (k-1)
    front    = [ word ++ basePlus | word <- take extra line]
    rear     = [ word ++ base     | word <- init (drop extra line)]
    end      = [ last line ]

-- A property to check behaviour.

prop_justify :: Line -> Bool

prop_justify line
  = length line <= 1 || lineLen - length (concat line) < length line || length (justify line) == lineLen

--
-- Solution 7.32
-- 

wc :: String -> (Int,Int,Int)

wc text
  = (length text, length (splitWords text), length [ 1 | '\n'<-text ])

-- wcFormat: just compose with the filling function (pretty printed)

--
-- Solution 7.33
-- 

-- Is it literally a palindrome?

simplePalCheck :: String -> Bool

simplePalCheck st
  = st == Prelude.reverse st

-- Uses Prelude.reverse here because defined earlier to work only
-- on Integer lists, whereas the Prelude version works on any lists.

-- Remove punctuation and whitespace and make capital letters small.

cleanup :: String -> String

cleanup st
  = [ toSmall ch | ch<-st, not (elem ch ".,;:\'\"/?~-_\t\n ") ] 
    
toSmall ch
  | isUpper ch     = toLower ch
  | otherwise      = ch

--- Putting the two parts together

palCheck  :: String -> Bool

palCheck st
  = clean == Prelude.reverse clean
    where
    clean = cleanup st

--
-- Solution 7.34
-- 

subst :: String -> String -> String -> String

subst oldSub newSub st 
  | length oldSub > length st   = st
  | frontSub oldSub st          = newSub ++ drop (length oldSub) st
  | otherwise                   = head st : subst oldSub newSub (tail st) 



--
-- Solution 7.35
-- 

-- if old is not a subSeq of st, then subst should do nothing

prop_subst1 :: String -> String -> String -> Bool

prop_subst1 old new st
  = subSeq old st || st == subst old new st

prop_subst2, prop_subst3  :: String -> String -> Bool

-- substituting old for itself should leave the string unchanged

prop_subst2 old st
  = st == subst old old st

-- substituting new for old in old, the result is new

prop_subst3 old new
  = new == subst old new old


