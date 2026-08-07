------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions16
--
------------------------------------------------------------------------------

module Solutions16 where

import Tree
import UseTree

-- The type Var.

type Var = Char

--
-- Solution 16.1
--

-- The implementation here has names suffixed with "S"

type StoreS = [(Var, Integer)]

initialS :: StoreS

initialS = []

-- Note that in case the variable isn't bound, returns 0.

valueS :: StoreS -> Var -> Integer

valueS [] v = 0 

valueS ((w,n):sto) v
  | w<v            = valueS sto v
  | w==v           = n
  | otherwise      = 0

-- This implementation overwrites the previous binding (assumed
-- to be unique).

updateS :: StoreS -> Var -> Integer -> StoreS

updateS [] v n = [(v,n)]

updateS ((w,m):sto) v n
  | w<v         = (w,m) : updateS sto v n
  | w==v        = (v,n) : sto
  | otherwise   = (v,n) : (w,m) : sto

--
-- Solution 16.2
--

-- For the implemetation in 16.1 it's actual equality. For the non-
-- ordered implementation in the chapter, need only to look at the first 
-- values given to variables: variable,value pairs later in the list are
-- ignored.

-- For function types need some indication of what the domain is. The neatest
-- way to do this is to pair the function with a list of variables which 
-- gives the set of variables defined. Need just to check equalities on these
-- lists.

--
-- Solution 16.3
--

-- Using a maybe type we can avoid returning the conventional 0 when a
-- variable isn't defined. Instead say this, modifying the solution to
-- 16.1.

valueS' :: StoreS -> Var -> Maybe Integer

valueS' [] _ = Nothing 

valueS' ((w,n):sto) v
  | w<v            = valueS' sto v
  | w==v           = Just n
  | otherwise      = Nothing

--
-- Solution 16.4
--

hasVal ::  StoreS -> Var -> Bool

hasVal [] _ = False 

hasVal ((w,n):sto) v
  | w<v            = hasVal sto v
  | w==v           = True
  | otherwise      = False

--
-- Solution 16.5
--

-- Easy for the functional implementation.

-- For the list implementation would have to define a "catch all" variable, or
-- ass an extr field to a record which is the default value for variables as
-- yet unassigned.

--
-- Solution 16.6
--

-- Need to choose an appropriat esubset of the type signatures of the functions
-- in the case study. 

-- An important point is not to include in the API functions which can be defined
-- in terms of other API functions. If that's the case, define them in this was so
-- that if/when the API is redefined these functions don't need to be redefined.

--
-- Solution 16.7
--

-- Standard calculations.

--
-- Solution 16.8
--

-- This exercise helps to make concrete the differences between the three implementations.

--
-- Solution 16.9
--

-- If a queue is not empty, then the the first element to be removed will
-- be the same before and after adding another element to the queue.

-- If a queue is empty and x is added, then x is the first element in the 
-- queue.

--
-- Solution 16.10
--

-- Can add elements to either end of the queue and if it is non-empty
-- can remove an element from either end too. Could implement with a single
-- list, or with a pair of lists: the latter should be much more efficient.

-- In both cases it's a matter of extending one of the existing implementations
-- with implmentations of the two new operations.

--
-- Solution 16.11
--

-- Same API as the ordinary queue; need to implement so that don't add a new
-- entry for a value already in the queue.

-- Alternatively could add another operation to the queue to check when an
-- entry is already present, so that can know when it's (not) worth adding
-- an entry. 

--
-- Solution 16.12
--

type Priority = Int

-- Store elements in descending order of priority. Within a particular priority 
-- store in FIFO form.

-- Note that this is a "concrete" implementation. If it's to be an ADT then
-- need to declare as a newtype with a wrapping constructor.

type PriQ a = [(Int,[a])]

emptyPQ = []

isEmptyPQ [] = True
isEmptyPQ _  = False

addPQ :: a -> Priority -> PriQ a -> PriQ a

addPQ x p [] = [(p,[x])]
addPQ x p qs@((q,ys):rest)
  | p>q         = (p,[x]):qs
  | p==q        = (q,ys++[x]):rest
  | p<q         = (q,ys) : addPQ x p rest

remPQ :: PriQ a -> (Maybe a, PriQ a)

remPQ q
  | isEmptyPQ q   = (Nothing, q)
  | otherwise     = (Nothing, [])

--
-- Solution 16.13
--

-- Once accumulated the scores of each letter can put into a priority queue; this
-- could help in tree building.

--
-- Solution 16.14
--

-- Can define isNil from isNode, and vice versa

-- Can define isNil from minTree: it will return Nothing iff tree is Nil.

-- Given any (finite) tree value t where elements are in Ord a can define nil thus:

{-
makeNil :: Ord a => Tree a -> Tree a
makeNil t
  | res == Nothing      = t
  | otherwise           = makeNil (delete min t)
    where
    res = minTree t
    Just min = res
-}

--
-- Solution 16.15
--

-- Depends a bit on what the database is to do, but need lookups and updates, as
-- well as initial value. Can define e.g. number of loans from the interface functions.

--
-- Solution 16.16
--

-- Two sorts of interface here

-- Using an existing index: take word to page range. Take page to all entries, perhaps?

-- Building an index: take a text to an index.

--
-- Solution 16.17
--

-- QueueState:
-- can define queueEmpty from queueLength

-- ServerState:
-- can define simulationStep using serverStep, shortestQueue and addToQueue
-- is it enough to have simulationStep, serverStart and serverSize? certainly
-- it is to actually run the simulation step by step.

--
-- Solution 16.18
--

-- In the light of the previous answer, it would be enough to include
-- simulationStep, serverStart and serverSize in an interface, and to have
-- the "next queue" as an element of the state, but not directly accessible
-- from the interface:

-- type NextState      = Int
-- newtype ServerState = SS ([QueueState],NextState)

-- Alternatively if more is to be exposed, then need a function to reveal
-- the current value of the "next state

--
-- Solutions 16.19,20
--

-- Standard calculations.

--
-- Solution 16.21
--

-- QueueState: running the queue to completion on a list of n inputs
-- should produce a list of n outputs, processed in order in which they 
-- arrived. In order to do this need to define a number of auxiliary 
-- functions, the major one being a funciton to run the queue to 
-- completion on an input list.

-- Need to take account here of the arrival times: can't expect to 
-- process something (at least) until it has arrived. Halt processing when
-- there are no more input messages to process and the queue itself is
-- empty.

--
-- Solution 16.22
--

-- Need to know how many queues there are, and can't tell this from an 
-- arbitrary function of type (Int -> QueueState); need to pair this function
-- with an Int telling you the number of queues. Once that's there, replace 
-- accessing a queue by list indexing and instead just use function application.
-- e.g. in the definition of addToQueue don't have to split the list up,
-- operate on one element and then form another list; instead simply change the 
-- value of the function on argument n.

--
-- Solution 16.23
--

-- See solution 16.17 above.

--
-- Solutions 16.24-25
--

-- See solution 16.18 above.

--
-- Solution 16.26
--

-- A different version of the round robin implemetation 
-- will keep a, ordered list of (Int,Queue) pairs and ensure that
-- the current/next queue is always at the head.

--
-- Solution 16.27,28
--

-- There are two approaches here: could test the accessor, selector
-- and discriminator functions, but we should be able to assume these
-- are ok. Here we test for the top level properties of how elementhood
-- interacts with insertion and deletion:

prop_add_tree :: Int -> Int -> Tree Int -> Bool

prop_add_tree n m t
  = elemT n t == elemT n (insTree m t) || n==m

prop_delete_tree :: Int -> Int -> Tree Int -> Bool

prop_delete_tree n m t
  = elemT n t == elemT n (delete m t) || n==m

-- Could also check that the minTree function indeed picks the minimum
-- value in the tree by comparing it with the nth value in the tree:

prop_min_tree :: Integer -> Tree Int -> Bool

prop_min_tree i t
  = let Just min = minTree t in
        min <= indexT i t || isNil t -- || "i not valid"

-- would be easier for this to be defined if indexT returned a Maybe a
-- indicating whether or not the index is in range: exercise.

--
-- Solution 16.29
--

{-
successor :: Ord a => a -> Tree a -> Maybe a

successor v Nil = Nothing
successor v (Node x t1 t2)
  | x<=v          = successor v t2
  | otherwise     = case maxT t1 of
                      Nothing -> x
                      Just y  -> if y>v 
                                    then successor v t1
                                    else x

maxT :: Ord a => Tree a -> Maybe a

maxT Nil            = Nothing
maxT (Node x _ Nil) = Just x
maxT (Node x _ t2)  = maxT t2
-}

--
-- Solution 16.30
--

-- Stree is defined on p398.

-- The paradigm for the solution is given on p398
-- where it is shown that the new field gives the value it
-- should, while the other functions need to maintain that
-- value.

--
-- Solution 16.31
--

-- Built on the model of Stree: need to make sure that the 
-- functions manipulate the "cached" values appropriately.

-- This is not caching the size, incidentally.

data MMtree a = NilMM | NodeMM a a a (MMtree a) (MMtree a)

insTreeMM :: Ord a => a -> MMtree a -> MMtree a

insTreeMM val NilMM = NodeMM val val val NilMM NilMM

insTreeMM val (NodeMM x minV maxV t1 t2)
  | val<=x          = NodeMM x newMin maxV newT1 t2
  | val>x           = NodeMM x minV newMax t1 newT2
    where
    newMin      = min val minV
    newMax      = max val maxV
    newT1       = insTreeMM val t1
    newT2       = insTreeMM val t2 

-- Note that because of lazy evaluation (Chapter 17) in each
-- case will only compute one of newMin / newMax and newT1 / newT2
-- according to the relation between val and x, the value at the
-- root of the tree.

--
-- Solution 16.32
--

-- The implentation type could remain the same, but it would be better to 
-- store an occurrence count with each element (with the assumption 
-- that no element occurs more than once). 

-- If the implementation type remains the same, then need to scan for all
-- occurrences of a particular element when looking for its occurrence 
-- count.

-- Should extend the interface with an element occurrence function, rather
-- than simply checking elementhood. This effectively gives "bags" rather
-- than "sets".

--
-- Solution 16.33
--

-- Search trees keep the implementation ordered. This is a straightforward 
-- re-implementation of the application.

--
-- Solution 16.34
--

-- This solution takes a different approach. Update the b value by passing in
-- an update function, of type (b -> b), to the insertion. This is applied to, e.g.
-- add an instance of a word to a list of instances, so might be (++[newOccurrence])
-- in that case.

data GenTree a b = GenNil b
                 | GenNode a b (GenTree a b) (GenTree a b)

insertGenTree :: Ord a => a -> (b -> b) -> GenTree a b -> GenTree a b

insertGenTree x f (GenNil b)
  = GenNode x (f b) (GenNil b) (GenNil b)

insertGenTree x f (GenNode a b t1 t2)
  | x==a          = GenNode a (f b) t1 t2
  | x<a           = GenNode a b (insertGenTree x f t1) t2
  | x>a           = GenNode a b t1 (insertGenTree x f t2)

--
-- Solution 16.35
--

-- One gives a total ordering, but of less value than a (partial) subset ordering.

--
-- Solutions 16.36 - 16.44 SEE SolutionsSet.hs
--

--
-- Solutions 16.45 - 16.50 SEE SolutionsRelation.hs
--


