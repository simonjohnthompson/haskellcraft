-----------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Simon Thompson, 1996-2011.
--
--  Chapter 19
--
-----------------------------------------------------------------------


module Chapter19 where

import Prelude hiding (lookup)
import Control.Monad (liftM, ap)
import Control.Monad.Identity

-- Abstraction: functors, monads and folding
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


-- Abstraction
-- ^^^^^^^^^^^

-- Spotting the pattern of mapping along a list ...

--  map :: (a -> b) -> [a] -> [b]

-- ... and the pattern of folding along a list.

--  foldr :: (a -> b -> b) -> b -> [a] -> b
--
--  foldr g s []     = s
--  foldr g s (x:xs) = g x (foldr g s xs)


-- The Functor class
-- ^^^^^^^^^^^^^^^^^

--  class Functor g where
--    fmap :: (a -> b) -> g a -> g b

-- A first example, the Maybe type; Functor Maybe is already an instance
-- in the standard libraries, so this is given as a comment.

--  instance Functor Maybe where
--    fmap f Nothing  = Nothing
--    fmap f (Just x) = Just (f x)

-- The list instance is standard too.

--  instance Functor [] where
--    fmap f []     = []
--    fmap f (x:xs) = f x : fmap f xs

-- Instances for the tree type used later in this chapter (Section
-- 19.5, "Example: monadic computation over trees") are given as real
-- code once that type has been declared, below.


-- The Applicative class
-- ^^^^^^^^^^^^^^^^^^^^^

--  class Functor g => Applicative g where
--    pure   :: a -> g a
--    (<*>)  :: g (a -> b) -> g a -> g b
--    liftA2 :: (a -> b -> c) -> g a -> g b -> g c

-- Applicative Maybe is already an instance in the standard libraries,
-- so both of the styles of definition discussed in the book -- via
-- liftA2, and via <*> -- are given here as comments.

--  instance Applicative Maybe where
--    pure x = Just x
--
--    liftA2 f (Just x) (Just y) = Just (f x y)
--    liftA2 _ _        _        = Nothing

--  instance Applicative Maybe where
--    ...
--    (Just f) <*> (Just x) = Just (f x)
--    _        <*> _        = Nothing

-- The Applicative instance for the tree type is given as real code
-- once that type has been declared, below.


-- The do notation revisited
-- ^^^^^^^^^^^^^^^^^^^^^^^^^

addOneInt :: IO ()

addOneInt
  = do line <- getLine
       putStrLn (show (1 + read line :: Int))

addOneInt'
  = getLine >>= \line ->
    putStrLn (show (1 + read line :: Int))

-- Monads: languages for functional programming
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-- The definition of the Monad class
--  class Monad m where
--    (>>=)  :: m a -> (a -> m b) -> m b
--    return :: a -> m a

-- Adding failure: the MonadFail class

--  class Monad m => MonadFail m where
--    fail :: String -> m a

-- Kleisli composition for monadic functions.

-- (>=>) :: Monad m => (a -> m b) ->
--                     (b -> m c) ->
--                     (a -> m c)

-- f >=> g = \ x -> (f x) >>= g


-- Some examples of monads
-- ^^^^^^^^^^^^^^^^^^^^^^^

-- Some examples from the standard prelude.

-- The list monad

--  instance Monad [] where
--    xs >>= f  = concat (map f xs)
--    return x  = [x]
--    zero      = []

-- The Maybe monad

--  instance Monad Maybe where
--    (Just x) >>= k  =  k x
--    Nothing  >>= k  =  Nothing
--    return          =  Just


-- The parsing monad

--  data SParse a b = SParse (Parse a b)

--  instance Monad (SParse a) where
--    return x = SParse (succeed x)
--    zero     = SParse fail
--    (SParse pr) >>= f
--      = SParse (\s -> concat [ sparse (f x) rest | (x,rest) <- pr st ])

--  sparse :: SParse a b -> Parse a b
--  sparse (SParse pr) = pr

-- A state monad (the state need not be a table; this example is designed
-- to support the example discussed below.)

type Table a = [a]

data State a b = State (Table a -> (Table a , b))

instance Monad (State a) where

  return x = State (\tab -> (tab,x))

  (State st) >>= f
    = State (\tab -> let
                     (newTab,y)    = st tab
                     (State trans) = f y
                     in
                     trans newTab)

instance Applicative (State a) where
  pure = return
  (<*>) = ap

instance Functor (State a) where
  fmap = liftM


-- Folding over data: the Foldable class
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

--  class Foldable t where
--    foldr :: (a -> b -> b) -> b -> t a -> b
--    -- see :info Foldable for rest of the API

-- Foldable Maybe is already an instance in the standard libraries, so
-- this is given as a comment.

--  instance Foldable Maybe where
--    foldr g a Nothing  = a
--    foldr g a (Just x) = g x a

-- The Foldable instance for the tree type is given as real code once
-- that type has been declared, below.


-- Example: Monadic computation over trees
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-- A type of binary trees.

data Tree a = Nil | Node a (Tree a) (Tree a)
              deriving (Eq,Ord,Show)

-- Tree as an instance of Functor: mapping f over every value stored
-- at a node.

instance Functor Tree where
  fmap f Nil            = Nil
  fmap f (Node x t1 t2) = Node (f x) (fmap f t1) (fmap f t2)

-- Tree as an instance of Applicative, following the same pattern as
-- the liftA2 definition for Maybe above: pure builds a single-node
-- tree, and liftA2 f applies f pointwise to two trees of the same
-- shape, returning Nil as soon as either side runs out of structure.

instance Applicative Tree where
  pure x = Node x Nil Nil

  liftA2 f Nil _ = Nil
  liftA2 f _ Nil = Nil
  liftA2 f (Node x t1 t2) (Node y s1 s2)
    = Node (f x y) (liftA2 f t1 s1) (liftA2 f t2 s2)

-- Tree as an instance of Foldable: folding f over every value stored
-- at a node, traversing the left subtree, then the node's own value,
-- then the right subtree (an in-order traversal).

instance Foldable Tree where
  foldr f z Nil            = z
  foldr f z (Node x t1 t2) = foldr f (f x (foldr f z t2)) t1

exT :: Tree Integer
exT = Node 3 (Node 6 Nil Nil) (Node 2 Nil Nil)

-- Summing a tree of integers

-- A direct solution:

sTree :: Tree Integer -> Integer

sTree Nil            = 0
sTree (Node n t1 t2) = n + sTree t1 + sTree t2

-- A monadic solution: first giving a value of type Identity Int ...

sumTree :: Tree Integer -> Identity Integer

sumTree Nil = return 0

sumTree (Node n t1 t2)
  = do num <- return n
       s1  <- sumTree t1
       s2  <- sumTree t2
       return (num + s1 + s2)

-- ... then adapted to give an Int solution

sTree' :: Tree Integer -> Integer

sTree' = identity . sumTree

identity :: Identity a -> a

identity (Identity x) = x

-- Using a state monad in a tree calculation
-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

-- The top level function ...

numTree :: Eq a => Tree a -> Tree Integer

-- ... and the function which does all the work:

numberTree :: Eq a => Tree a -> State a (Tree Integer)

-- Its structure mirrors exactly the structure of the earlier program to
-- sum the tree.

numberTree Nil = return Nil

numberTree (Node x t1 t2)
  = do num <- numberNode x
       nt1 <- numberTree t1
       nt2 <- numberTree t2
       return (Node num nt1 nt2)

-- The work of the algorithm is done node by node, hence the function

numberNode :: Eq a => a -> State a Integer

numberNode x = State (nNode x)

--
-- Looking up a value in the table; will side-effect the table if the value
-- is not present.

nNode :: Eq a => a -> (Table a -> (Table a , Integer))
nNode x table
  | elem x table        = (table      , lookup x table)
  | otherwise           = (table++[x] , integerLength table)
    where
      integerLength = toInteger.length

-- Looking up a value in the table when known to be present

lookup :: Eq a => a -> Table a -> Integer

lookup x tab =
    locate 0 tab
           where
             locate n (y:ys) =
                 if x==y then n else locate (n+1) ys

-- Extracting a value froma state monad.

runST :: State a b -> b
runST (State st) = snd (st [])

-- The top-level function defined eventually.

numTree = runST . numberTree

-- Example tree

egTree :: Tree String

egTree = Node "Moon"
               (Node "Ahmet" Nil Nil)
               (Node "Dweezil"
                        (Node "Ahmet" Nil Nil)
                        (Node "Moon" Nil Nil))
