------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions14_1
--
------------------------------------------------------------------------------

module Solutions14_1 where

import Chapter14_1 hiding (Person,size,Expr(..),eval,BExp(..))
import Test.QuickCheck

--
-- Solution 14.1
--

-- Just a matter of changing pattern matching ...

--
-- Solution 14.2
--

-- We assume a special binding which returns current date

today :: Date -- type defined below
today = today -- dummy definition

-- First the types ...

data Item = Book Author Title | CD Author Title | Video Title
            deriving (Show,Read,Eq,Ord)

type Author = String 
type Title = String
type Person = String

data Loan = Loan Item Person Date -- item and due date
            deriving (Show,Read,Eq,Ord)

type Date = (Int,Int,Int) -- year month day

type DBase = [Loan]

-- .. then the function types ...

-- All have the same type as the representation we have chosen flttens them into 
-- a sinfglt type. Could have separate reps for each type, and then a union type
-- pulling them together.

items, books, cds, videos :: DBase -> Person -> [Item]

-- example: we use pattern matching to pull out only the CDs in the dbase

cds dbase person = [ CD a t | Loan (CD a t) pers _ <- dbase, person==pers ]

items = items -- dummy definition
books = books -- dummy definition
videos = videos -- dummy definition

-- The type Date is ordered and so we can use it for comparison with today.
-- When adding a loan to the database need to add the loan time to today's date,
-- so need some simple arithmetic on dates.

-- Alternatively use a custom type for dates.

--
-- Solution 14.3
--

-- An example:

-- eval (Add (Sub (Lit 3) (Lit 1)) (Lit 3))
--  --> eval (Sub (Lit 3) (Lit 1)) + eval (Lit 3)
--  --> (eval(Lit 3) - eval (Lit 1)) + 3
--  --> (3 - 1) + 3
--  --> 2 + 3
--  --> 5

--
-- Solution 14.4
--

size :: Expr -> Integer

size (Lit _) = 0
size (Add e1 e2) = 1 + size e1 + size e2
size (Sub e1 e2) = 1 + size e1 + size e2

--
-- Solution 14.5
--

data Expr = Lit Integer |
            Add Expr Expr |
            Sub Expr Expr |
            Mul Expr Expr |
            Div Expr Expr
                deriving (Show,Eq)

-- Redefining eval - note that we check for division by zero.

eval :: Expr -> Integer

eval (Lit n)     = n
eval (Add e1 e2) = (eval e1) + (eval e2)
eval (Sub e1 e2) = (eval e1) - (eval e2)
eval (Mul e1 e2) = (eval e1) * (eval e2)
eval (Div e1 e2) = if (eval e2)/=0 
                      then (eval e1) `div` (eval e2)
                      else 0

-- Similarly for show and size.

--
-- Solution 14.6
--

-- Can either do a two-level pattern matching
--   eval (Op Add e1 e2) = ... etc
-- or define a function to interpret the operators
-- directly:
--   evalOp :: Op -> (Int -> Int -> Int)
-- so that eval just calls this in the case of eval (Op ... )

-- See solution 14.15 for the second approach.

--
-- Solution 14.7
--

-- Standard line by line evaluation.

--
-- Solution 14.8
--

-- eval (e1 :+: e2) = eval e1 + eval e2 
-- etc.

--
-- Solution 14.9
--

-- These will fail if given a NilT "non-exhaustive pattern match"

left, right :: NTree -> NTree

left  (Node _ t _) = t
right (Node _ _ t) = t

--
-- Solution 14.10
--

elemT :: NTree -> Integer -> Bool

elemT (Node n t1 t2) m
  = n==m || elemT t1 m || elemT t2 m
elemT NilT _  = False

--
-- Solution 14.11
--

-- Undefined on a leaf

minT :: NTree -> Integer

minT (Node n t1 NilT)
  = min n (minT t1)
minT (Node n NilT t2)
  =  min n (minT t2)
minT (Node n t1 t2)
  = minimum [n, minT t1, minT t2]

-- Maximum is just the same with max and maximum in place of min and minimum.

--
-- Solution 14.12
--

reflectT :: NTree -> NTree

reflectT (Node n t1 t2)
  = Node n (reflectT t2) (reflectT t1)
reflectT NilT  = NilT

prop_reflectT :: NTree -> Bool

prop_reflectT t 
  = reflectT (reflectT t) == t

--
-- Solution 14.13
--

collapseT, sortT :: NTree -> [Integer]

collapseT NilT = []
collapseT (Node n t1 t2)
  = collapseT t1 ++ [n] ++ collapseT t2

sortT NilT = []
sortT (Node n t1 t2)
  = sortT t1 `merge` ([n] `merge` sortT t2)

merge :: [Integer] -> [Integer] -> [Integer] 

merge (x:xs) (y:ys) 
  | x<=y        = x : merge xs (y:ys)
  | otherwise   = y : merge (x:xs) ys
merge xs [] = xs
merge [] ys = ys

--
-- Solution 14.14
--

-- The case left incomplete are the simple non-recursive ones.

--
-- Solution 14.15
--

-- I have used Exp here just so it doesn't get confused with earlier 
-- definitions ...

data Exp = Num Integer 
         | Op Ops Exp Exp
         | If BExp Exp Exp
           deriving (Eq, Ord, Show, Read)

data BExp = BoolLit Bool
          | And BExp BExp
          | Not BExp
          | Equal Exp Exp
          | Greater Exp Exp
            deriving (Eq, Ord, Show, Read)

data Ops = Ad | Sb | Mu | Di
           deriving (Eq, Ord, Show, Read)

ev :: Exp -> Integer
bev :: BExp -> Bool
evop :: Ops -> (Integer -> Integer -> Integer)

ev (Num n) = n
ev (Op op e1 e2) = evop op (ev e1) (ev e2)

evop Ad = (+)
evop Sb = (-)
evop Mu = (*)
evop Di = \m n -> if n/=0 then m `div` n else 0

bev (BoolLit b) = b
bev (And be1 be2) = bev be1 && bev be2
bev (Not be) = not (bev be)
bev (Equal e1 e2) = ev e1 == ev e2
bev (Greater e1 e2) = ev e1 < ev e2