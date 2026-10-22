import Prelude hiding (print,lookup)

{-
A suite of functions for handling arithmetical expressions

Expressions are represented like this

    Num N
    Var A
    Add E1 E2 
    Mul E1 E2 

where N is a number, A is a character
and E1, E2 are themselves expressions,
-}

data Expr =
    Num Int
  | Var Char
  | Add Expr Expr
  | Mul Expr Expr
    deriving (Eq,Ord,Show)

expr1, expr2 :: Expr

expr1 = Add (Var 'a') (Mul (Num 2) (Var 'b'))

expr2 =
  Add (Mul (Num 1) (Var 'b'))
      (Mul (Add (Mul (Num 2) (Var 'b')) (Mul (Num 1) (Var 'b'))) (Num 0))

{-}
Printing

Turn an expression into a string, so that
  Add (Var 'a') (Mul (Num 2) (Var 'b'))
 is turned into
  "(a+(2*b))"
-}


print :: Expr -> String

print (Num n) = show n
print (Var v) = [v]
print (Add e1 e2) =
    "(" ++ print e1 ++ "+" ++ print e2 ++")"
print (Mul e1 e2) =
    "(" ++ print e1 ++ "*" ++ print e2 ++")"

{-

parsing


recognise expressions
deterministic, recursive descent, parser.

the function returns two things
  - an expression recognised at the beginning of the string
    (in fact, the longest such expression)
  - whatever of the string is left

for example, parse("(-55*e)+1111)") is
  (Mul (Num (-55)) (Var 'e') , "+1111)")
-}

{-
recognise a fully-bracketed expression, with no spaces etc.
-}

{-
First some auxiliary functions to get a sequence of characters.
Used in parsing an integer.
-}

is_digit :: Char -> Bool

is_digit ch =
  '0' <= ch && ch <= '9'

{-
get the longest initial sequence from the list where
each element satisfies the predicate
-}


get_while :: (a -> Bool) -> [a] -> ([a],[a])

get_while p (y:ys) = 
    if p y
      then
        let (zs,rest) = get_while p ys in
        (y:zs,rest)
      else
        ([],y:ys)
get_while p []  = 
      ([],[])

get_digits :: [Char] -> ([Char],[Char])


get_digits =
  get_while is_digit

{-  
recognise an integer, a sequence of digits
with an optional '-' sign at the start
-}

get_int :: [Char] -> ([Char],[Char])

get_int [] = ([],[])
get_int (y:ys) =
    if y=='-'
    then
      let (n,rest) = get_digits ys in
      (y:n,rest)
    else
      get_digits (y:ys)

{-      
convert a list of digits (with optional -) into an int
-}

list_to_int :: [Char] -> Int

list_to_int [] = 0
list_to_int chars =
  case chars of
    ('-':rest) -> (-1)* worker (reverse rest)
    xs -> worker (reverse xs)
  where
    worker [] = 0
    worker (d:ds) =
        (fromEnum d - fromEnum '0') + 10 * (worker ds)


parse :: [Char] -> (Expr,[Char])

parse ('(':rest) =
    let (e1,rest1)  = parse rest 
        (op:rest2)  = rest1 
        (e2,rest3)  = parse rest2
        (')':rest4) = rest3 in
    ((case op of
        '+' -> Add e1 e2
        '*' -> Mul e1 e2),
     rest4)
parse (ch:rest) =
    if ('a'<= ch && ch <= 'z')
      then
        (Var ch, rest)
      else
        let (ns,rest1) = get_int (ch:rest) in
        (Num (list_to_int ns), rest1)

{-
Evaluate an expression in an environment.
-}

type Env = [(Char,Int)] 

env1 :: Env

env1 = [ ('a',12), ('b', -11) ]

lookup :: Char -> Env -> Int

lookup v []
     = 0
lookup v ((x,n):ps) = 
    if x==v then n else lookup v ps

eval :: Env -> Expr -> Int

eval env (Num n) = n
eval env (Var v) = lookup v env
eval env (Add e1 e2) = eval env e1 + eval env e2
eval env (Mul e1 e2) = eval env e1 * eval env e2

{-
Compiler and virtual machine
-}

{-
Instructions
   Push N - push integer N onto the stack
   Fetch A - lookup value of variable a and push the result onto the stack
   Add2 - pop the top two elements of the stack, add, and push the result
   Mul2 - pop the top two elements of the stack, multiply, and push the result
-}

data Instr =
    Push Int
  | Fetch Char
  | Add2
  | Mul2

type Program = [Instr]

type Stack = [Int]

{-
compiler
-}

compile :: Expr -> Program

compile (Num n) = [Push n]
compile (Var v) = [Fetch v]
compile (Add e1 e2) = compile e2 ++ compile e1 ++ [Add2]
compile (Mul e1 e2) = compile e2 ++ compile e1 ++ [Mul2]

{-
execute an instruction, and when the code is exhausted,
return the top of the stack as result.
classic tail recursion
-}

run :: Program -> Env -> Stack -> Int
  
run (Push n : cont) env stack =
    run cont env (n:stack)
run (Fetch v : cont) env stack =
    run cont env (lookup v env : stack)
run (Add2 : cont) env (n1:n2:rest) =
    run cont env (n1+n2:rest)
run (Mul2 : cont) env (n1:n2:rest) =
    run cont env (n1*n2:rest)
run [] env (n:_) = 
    n

{-    
compile then run … should be the same as eval
-}

execute :: Env-> Expr -> Int

execute env e =
  run (compile e) env []

simplify :: Expr -> Expr  

simplify (Add e1 (Num 0)) = simplify e1
simplify (Add (Num 0) e2) = simplify e2
simplify (Add (Num n) (Num m)) = Num (n+m)
simplify (Mul e1 (Num 1)) = simplify e1
simplify (Mul (Num 1) e2) = simplify e2
simplify (Mul e1 (Num 0)) = Num 0
simplify (Mul (Num 0) e2) = Num 0
-- simplify (Add e1 e2) = simplify (Add (simplify e1) (simplify e2))

simplify (Add e1 e2) =
    if not(s1==e1 && s2==e2)
        then 
            simplify (Add s1 s2)
        else
            Add s1 s2
      where
        s1 = simplify e1
        s2 = simplify e2
        
simplify (Mul e1 e2) =
    if not(s1==e1 && s2==e2)
        then 
            simplify (Mul s1 s2)
        else
            Mul s1 s2
        where
        s1 = simplify e1
        s2 = simplify e2
      
