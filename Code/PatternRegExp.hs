module PatternRegExp where

data Pattern = Epsilon
             | Chr Char
             | L Pattern 
             | R Pattern 
             | Seq Pattern Pattern String
             | Star [(Pattern,String)]
]
               deriving Show

type Name = String

type RegExp = String -> [Pattern]

epsilon :: RegExp

epsilon = 
    \x -> if (x=="") 
          then [Epsilon] 
          else []

char :: Char -> RegExp

char ch =
    \x -> if (x==[ch]) 
          then [Chr ch] 
          else []

(|||) :: RegExp -> RegExp ->  RegExp

e1 ||| e2 = 
    \x -> [L p | p <-e1 x] ++ [R p | p <-e2 x]

(<*>) :: RegExp -> RegExp ->  RegExp

e1 <*> e2 =
    \x -> [ Seq p q x | (y,z) <- splits x,
                                  p <- e1 y,
                                  q <- e2 z ]

(<**>) :: RegExp -> RegExp ->  RegExp

e1 <**> e2 =
    \x -> [ Seq p q x | (y,z) <- fsplits x,
                                  p <- e1 y,
                                  q <- e2 z ]

splits xs = [splitAt n xs | n<-[0..len]]
    where
      len = length xs

star :: RegExp -> RegExp

star p = epsilon ||| (p <**> star p)
--           epsilon ||| (p <*> star p)
-- is OK as long as p can't have epsilon match

fsplits xs = tail (splits xs)

a = char 'a'

b = char 'b'