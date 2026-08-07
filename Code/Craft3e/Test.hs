module Test where  

import PicturesSVG
    
ex :: Integer
ex = 3+4

double :: Integer -> Integer
double x = 2*x

trip :: Integer -> Integer
trip y = 3*y

pic1 :: Picture
pic1 = horse `beside` flipV (invert horse)

pic2 :: Picture
pic2 = pic1 `above` invert pic1

howManyEqual :: Integer -> Integer -> Integer -> Integer

howManyEqual x y z 
  | x==y && y==z            = 3
  | x==y || y==z || z==x    = 2
  | otherwise               = 0


(^^^) :: Integer -> Integer -> Integer
x ^^^ y 
    | x>= y      = x
    | otherwise  = y

fac :: Integer -> Integer

fac 0               = 1
fac n 
    | n>0           = n * fac (n-1)
    | otherwise     = 0



maxThreeOccurs :: Integer -> Integer -> Integer -> (Integer,Integer)

maxThreeOccurs x y z =
  (theMax,occurs)
  where
    theMax = max (max x y) z
    occurs = eq x + eq y + eq z
    eq w = if w==theMax then 1 else 0

pow :: Integer -> Integer

pow n 
  | n==0      = 1
  | n>0       = 2 * pow (n-1) 
  | otherwise = 0      

sumFun :: (Integer -> Integer) -> Integer -> Integer
  
sumFun f n 
  | n==0      = f 0
  | n>0       = sumFun f (n-1) + f n
  | otherwise = 0  


fibP :: Integer -> (Integer,Integer)

fibP 0 = (0,1)
fibP n = (v,u+v)
         where
         (u,v) = fibP (n-1)


fib :: Integer -> Integer

fib 0 = 0
fib 1 = 1
fib n = fib (n-2) + fib (n-1)
