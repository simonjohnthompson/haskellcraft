------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions14_2
--
------------------------------------------------------------------------------

module Solutions14_2 where

import Chapter14_1(Season(..),Temp(..),weather)
import Chapter14_2 hiding (Either(..),either,Maybe(..),maybe,mapMaybe,edit)
import Test.QuickCheck

--
-- Solution 14.16
--

-- Anyhting that doesn't explictly need the elements to be
-- Integers. Even sorting can be polymporphic in types that
-- have an Ordering (i.e. instances of the Ord class).

--
-- Solution 14.17
--

twist :: Either a b -> Either b a

twist (Left x) = Right x
twist (Right y) = Left y

-- twist.twist == id

--
-- Solution 14.18
--

applyLeft' :: (a -> c) -> Either a b -> c

applyLeft' f  = either f (\_ -> error "applyLeft")

--
-- Solution 14.19
--

toEitherL :: (a -> b) -> a -> Either b c

toEitherL f = Left . f


toEitherR :: (a -> c) -> a -> Either b c

toEitherR f = Right . f

--
-- Solution 14.20
--

join :: (a -> c) -> (b -> d) -> Either a b -> Either c d

join f g = either (toEitherL f) (toEitherR g)

--
-- Solution 14.21
--

leaves :: GTree a -> Int

leaves (Leaf _)   = 1
leaves (Gnode ts) = sum (map leaves ts)

depthGT :: GTree a -> Int

depthGT (Leaf _)   = 1
depthGT (Gnode ts) = 1 + maximum (map depthGT ts)

sumGT :: GTree Int -> Int

sumGT (Leaf n)   = n
sumGT (Gnode ts) = sum (map sumGT ts)

elemGT :: Eq a => a -> GTree a -> Bool

elemGT m (Leaf n)   = n==m
elemGT m (Gnode ts) = or (map (elemGT m) ts)

mapGT :: (a -> b) -> GTree a -> GTree b

mapGT f (Leaf n)   = Leaf (f n)
mapGT f (Gnode ts) = Gnode (map (mapGT f) ts)

flattenGT :: GTree a -> [a]

flattenGT (Leaf n)   = [n]
flattenGT (Gnode ts) = concat (map flattenGT ts)

--
-- Solution 14.22
--

emptyGT :: GTree a

emptyGT = Gnode []

--
-- Solution 14.23
--

lookupList :: Int -> [a] -> Maybe a

lookupList n xs
  | 0<=n && n<=(length xs) - 1      = Just (xs!!n)
  | otherwise                       = Nothing

-- defining it from scratch ..

process :: [Int] -> Int -> Int -> Int

process xs n m 
  = case lookupList n xs of
         Nothing -> 0
         Just x  -> case lookupList m xs of
                         Nothing -> 0
                         Just y  -> (x+y)

-- ... and using the combinators; it's proably easier to see
-- this once the version above is written ...

process' :: [Int] -> Int -> Int -> Int

process' xs n m 
  = maybe 0 (\n -> maybe 0 (n+) (lookupList m xs)) (lookupList n xs)

--
-- Solution 14.24
--

-- Discussion about how errors are handled by the calling context.

--
-- Solution 14.25
--

-- Values of the form Just (Just x), Just Nothing and Nothing.

squashMaybe :: Maybe (Maybe a) -> Maybe a

squashMaybe (Just (Just x)) = Just x
squashMaybe (Just Nothing)  = Nothing
squashMaybe Nothing         = Nothing

--
-- Solution 14.26
--

mapMaybe :: (a -> b) -> Maybe a -> Maybe b

mapMaybe g Nothing  = Nothing
mapMaybe g (Just a) = Just (g a)

-- Can define this using map and squash ...

composeMaybe :: (a -> Maybe b) -> (b -> Maybe c) -> a -> Maybe c

composeMaybe f g 
  = squashMaybe . mapMaybe g . f
 
--
-- Solution 14.27
--

-- This is a question of how error messages are transmitted and
-- combined by the various combinators.
 
--
-- Solution 14.28
--

-- Need to add an option to the "otherwise" case of transform:

--      Swap : transform (head ys : tail xs) (head xs : tail ys)

-- and the Swap constructor to the Edit data type.
 
--
-- Solution 14.29
--

-- The edit function "folds in" the edStep function along
-- the list of edits. No it doesn't! How the edits interact
-- with the strong depends on the particular values of the edits
-- themselves.

edit :: [Edit] -> String -> String

edit [] st       = st 

edit (Change new:eds) (old:st) = new : edit eds st
edit (Copy:eds) (old:st)       = old : edit eds st
edit (Delete:eds) (old:st)     = edit eds st
edit (Insert new:eds) st       = new : edit eds st
edit (Kill:eds) st             = edit eds []

testEdit = edit [Insert 'c', Change 'h', Copy, Insert 'p', Copy, Kill] "fish"
 
--
-- Solution 14.30
--

-- cost of the identity should be 0.

prop_identity :: String -> Bool

prop_identity st
  = cost (transform st st) == 0

-- This is <=1 and not ==1 as only need a final Kill in case st2/=[].

prop_subseq1 :: String -> String -> Bool

prop_subseq1 st1 st2
  = cost (transform (st1++st2) st1) <= 1

prop_subseq2 :: String -> String -> Bool

prop_subseq2 st1 st2
  = cost (transform st1 (st1++st2)) == length st2

-- This next property fails: need st1/=[] and st1/=st2 and ...
-- Nice to see it being refined by getting counterexamples and
-- eliminating these from the test.

prop_subseq3 :: String -> String -> Bool

prop_subseq3 st1 st2
  = cost (transform (st2++st1) st1) == length st2 
 
--
-- Solutions 14.31,2
--

-- Not efficient: would benefit from memoisation (see Ch 20).
 
--
-- Solutions 14.33-36
--

-- General principle here: keep it as simple as possible. Don't 
-- over-engineer, and only add features when they are necessary.

-- For example in 14.33 just use (a type represening) number plates;
-- might need some unversal representation if will include cars 
-- from outside the UK. Could have a structured representation of UK
-- plates and freeform String for the rest, or just use String itself.

-- In 14.34 could argue that this information should be stored elsewhere
-- in some sort of store which is keyed on number plate.

-- Again can assume Student ID is a key for students, and can therefore
-- store mark info keyed on this (and other keys such as module and
-- class ids.

-- 14.36 We saw Shape earlier. Need location etc as well as key coordinates.
 
--
-- Solutions 14.37
--

instance Movable b => Movable (b,c) where
  move v (x,y) = (move v x, y)
  reflectX (x,y) = (reflectX x,y)
  reflectY (x,y) = (reflectY x,y)

instance Named c => Named (b,c) where
  lookName (x,y) = lookName y
  giveName st (x,y) = (x,giveName st y)
 
--
-- Solutions 14.38
--

-- There's nothing at all specific to Movable or Named in the solution above,
-- so can apply for any two classes.
 
--
-- Solutions 14.39
--

-- Again, there's nothing specific to the Named/String example.
 
--
-- Solutions 14.40
--

-- It depends. If you're sure that all exisiting (and future (?)) instances of
-- Movable will have this extended interface, then no reason not to extend Movable
-- itself. Of course, will have to extend all instances to do this.

-- If you define a new class that extends the existing one, then no need to update 
-- all the existing instance declarations. To use the new class then need new 
-- instances, but at least existing code isn't broken.
 
--
-- Solutions 14.41
--

-- Base class for account, with extensions for different interfaces.
 
--
-- Solutions 14.42
--

newWeather :: Season -> Temp

newWeather = makeHot . (==Summer)

makeHot True = Hot
makeHot False = Cold

prop_weather :: Season -> Bool
 
prop_weather season
  = weather season == newWeather season

instance Arbitrary Season where
  arbitrary = oneof (map return [Spring .. Winter])
 
--
-- Solutions 14.43
--

-- Not unless you check that e.g. height and width are non-negative.
 
--
-- Solutions 14.44
--

-- the functions ...

size :: Tree a -> Integer

size Nil = 0
size (Node _ t1 t2) = 1 + size t1 + size t2


depth :: Tree a -> Integer

depth Nil = 0
depth (Node _ t1 t2) = 1 + max (depth t1) (depth t2)

-- .. and the property.

prop_tree_size :: Tree a -> Bool

prop_tree_size tr
 = size tr < 2^(depth tr)

-- The proof is by structural induction over the tree.
 
--
-- Solutions 14.45
--

-- Doing this will need some lemmas too, about how length works with (++)
 
--
-- Solutions 14.46
--

-- Prove this for all finite tr by proving
--       twist (twist tr) = tr
-- by structural induction over tr.
 
--
-- Solutions 14.47
--

-- Principle of induction for GTree a.

-- To prove P(x) for all finite x::Gtree a

-- I1: prove P (Leaf x), for all x::a
-- I2: prove P (Gnode xs), for all finite lists xs, assuming that P(x) holds for every
--     element x of the list xs.

-- expect to be able to prove for all t
--        map f (collapse t) = collapse (mapTree f t)  

-- I1: map f (collapse (Leaf s)) = map f [s] = [f s]
--     collapse (mapTree f (Leaf s)) = collapse (Leaf (f s)) = [f s]
-- so the base case holds.

-- I2: we assume that map f (collapse x) = collapse (mapTree f x)     
--     holds for every element x of xs and aim to prove that
--     map f (collapse (Gnode xs)) = collapse (mapTree f (Gnode xs))
--
--     map f (collapse (Gnode xs)) = map f (concat (map collapse xs))
--                                 = concat (map (map f) (map collapse xs))
--                                 = concat (map (map f . collapse) xs)
--                                 = concat (map (collapse . mapTree f) xs) [by induction]
--                                 = concat (map collapse (map (mapTree f) xs))
--                                 = collapse (map (mapTree f) xs)
--                                 = collapse (mapTree f (Gnode xs))

