-------------------------------------------------------------------------
-- 
--  Haskell: The Craft of Functional Programming, 3e
--  Simon Thompson
--  (c) Addison-Wesley, 1996-2011.
-- 
--      SolutionsParsing.hs 
-- 
--      Note that this is not a monadic approach to parsing.    
-- 
---------------------------------------------------------------------------                                                     

module SolutionsParsing where

import Data.Char

infixr 5 >*>
--  
-- Syntactic types                          
--  
type Var = Char

data Expr = Lit Int | Var Var | Op Op Expr Expr
            deriving (Show,Eq)
data Op   = Add | Sub | Mul | Div | Mod
            deriving (Show,Eq)

--  
-- The type of parsers.                     
--  
type Parse a b = [a] -> [(b,[a])]
--  
-- Some basic parsers                       
--  
--  
-- Fail on any input.                       
--  
none :: Parse a b
none inp = []
--  
-- Succeed, returning the value supplied.               
--  
succeed :: b -> Parse a b 
succeed val inp = [(val,inp)]
--  
-- token t recognises t as the first value in the input.        
--  
token :: Eq a => a -> Parse a a
token t (x:xs) 
  | t==x    = [(t,xs)]
  | otherwise   = []
token t []    = []
--  
-- spot whether an element with a particular property is the    
-- first element of input.                      
--  
spot :: (a -> Bool) -> Parse a a
spot p (x:xs) 
  | p x     = [(x,xs)]
  | otherwise   = []
spot p []    = []
--  
-- Examples.                            
--  
bracket = token '('
dig     =  spot isDigit
--  
-- Combining parsers                        
--  
--  
-- alt p1 p2 recognises anything recogniseed by p1 or by p2.    
--  
alt :: Parse a b -> Parse a b -> Parse a b
alt p1 p2 inp = p1 inp ++ p2 inp
exam1 = (bracket `alt` dig) "234" 
--  
-- Apply one parser then the second to the result(s) of the first.  
--  

(>*>) :: Parse a b -> Parse a c -> Parse a (b,c)
--  
(>*>) p1 p2 inp 
  = [((y,z),rem2) | (y,rem1) <- p1 inp , (z,rem2)  <- p2 rem1 ]
--  
-- Transform the results of the parses according to the function.   
--  
build :: Parse a b -> (b -> c) -> Parse a c
build p f inp = [ (f x,rem) | (x,rem) <- p inp ]
--  
-- Recognise a list of objects.                 
--  
--  
list :: Parse a b -> Parse a [b]
list p = (succeed []) `alt`
         ((p >*> list p) `build` convert)
         where
         convert = uncurry (:)
--  
-- Solutions 17.10,11.                      
--  

-- A non-empty list of objects.                     
--  
neList   :: Parse a b -> Parse a [b]
neList p = (p  `build` (:[]))
           `alt`
           ((p >*> list p) `build` (uncurry (:)))

-- Zero or one object.

optional :: Parse a b -> Parse a [b]
optional p = (succeed []) 
             `alt`  
             (p  `build` (:[]))

-- A given number of objects.

nTimes :: Int -> Parse a b -> Parse a [b]
nTimes 0 p        = succeed []
nTimes n p | n > 0 = (p >*> nTimes (n-1) p) `build` (uncurry (:))

--  
-- A parser for expressions                 
--  
--  
-- The parser has three components, corresponding to the three  
-- clauses in the definition of the syntactic type.     
--  
parser :: Parse Char Expr
parser = (litParse `alt` varParse) `alt` opExpParse
--  
-- Spotting variables.                      
--  
varParse :: Parse Char Expr
varParse = spot isVar `build` Var

isVar :: Char -> Bool
isVar x = ('a' <= x && x <= 'z')
--  
-- Parsing (fully bracketed) operator applications.     
--  
opExpParse 
  = (token '(' >*>
     parser    >*>
     spot isOp >*>
     parser    >*>
     token ')') 
     `build` makeExpr

makeExpr (_,(e1,(bop,(e2,_)))) = Op (charToOp bop) e1 e2

--
-- Solution 17.12

isOp :: Char -> Bool
isOp ch = elem ch "+-*/%"

charToOp :: Char -> Op
charToOp ch = case ch of
                   '+' -> Add
                   '-' -> Sub
                   '*' -> Mul
                   '/' -> Div
                   '%' -> Mod

--  
-- A number is a list of digits with an optional ~ at the front. 
--  
litParse 
  = ((optional (token '~')) >*>
     (neList (spot isDigit)))
     `build` (charlistToExpr.join) 
     where
     join = uncurry (++)
--  
-- Solution 17.14                       
--  
charlistToExpr :: [Char] -> Expr
charlistToExpr [] = Lit 0
charlistToExpr ys@(x:xs) 
  = if x=='~' 
       then Lit (- (convertDigList (reverse xs)))
       else Lit (convertDigList (reverse ys))

convertDigList [] = 0
convertDigList (x:xs)
  = conv x + 10*convertDigList xs
    where
    conv x = fromEnum x - fromEnum '0'

--  
-- The top-level parser                     
--  
topLevel :: Parse a b -> [a] -> b
topLevel p inp
  = case results of
      [] -> error "parse unsuccessful"
      _  -> head results
    where
    results = [ found | (found,[]) <- p inp ]
--  
-- The type of commands.                        
--  
data Command = Eval Expr | Assign Var Expr | Null
               deriving (Show,Eq)

--
-- Solution 17.15
--

commandParse :: Parse Char Command

commandParse
  = (((spot (\ch -> elem ch ['a'..'z']) >*>
     token ':') >*>
     parser) 
    `build`
     (\((ch,_),e) -> Assign ch e))
    `alt`
    (parser
     `build`
     \e -> Eval e)

--
-- Other solutions
--

--
-- Solution 17.13
--

-- One way to build this recogniser is to map snd on the results.

-- Build the library just as for parsing, except that don't need to keep track
-- of any return values.

--
-- Solution 17.16
--

fractionParse 
  = (optional (token '~') >*>
     neList (spot isDigit) >*>
     optional (token '.' >*>
               neList (spot isDigit)))
    `build`
     \(a,(b,c)) -> (a++b) ++ if c==[] then [] else (uncurry (:) (head c))

-- This returns a string: need then to covert
-- better to keep the pieces and to convert the
-- integer and fractional parts separately: exercise.

--
-- Solution 17.17
--

-- Parse a variable as a nonempty list of alphabetic characters, say

longVbl = neList (spot isAlpha)

--
-- Solution 17.18
--

-- Run through removing whitespace before parsing: filter (\ch -> not (elem ch " \t\n"))

--
-- Solution 17.19
--

-- Here's the grammar in BNF format.

--  
-- A grammar for unbracketed expressions.               
--                              
-- eXpr  ::= Int | Var | (eXpr Op eXpr) |               
--           lexpr mop mexpr | mexpr aop eXpr           
-- lexpr ::= Int | Var | (eXpr Op eXpr)             
-- mexpr ::= Int | Var | (eXpr Op eXpr) |   lexpr mop mexpr     
-- mop   ::= 'a' | '/' | '\%'                   
-- aop   ::= '+' | '-'                      
--  

-- Implementing this is entirely in line with the implementation of the 
-- simpler grammar. 

--
-- Solution 17.20
--

parseLists :: Parse Char [Int]
parseLists 
  = ((token '[' >*>
     list (parseInt >*>
           token ',') >*>
     parseInt >*>
     token ']')
     `build`
     (\(_,(b,(c,_))) -> map fst b ++ [c]))
     `alt`
     ((token '[' >*> token ']')
      `build`
      (\_ -> []))
     
parseInt :: Parse Char Int

parseInt = litParse `build` (\ (Lit i) -> i)

--
-- Solution 17.21
--

-- Pretty straigforward. Spotting tokens as lists of
-- characters. Then have some simple sentences
-- subject verb object etc. There's no recursion 
-- involved.

--
-- Solution 17.22
--

spotWhile :: (a -> Bool) -> Parse a [a]

spotWhile p [] = [([],[])]
spotWhile p st@(x:xs)
  | not (p x)         = [([],st)]
  | otherwise         = push x (spotWhile p xs)
    where
    push x (t:ts) = add x t : ts
    add x (a,b)   = (x:a,b)


