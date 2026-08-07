module TypeError where

-- fun :: Int -> Bool -> Int

fun True 0 = 0
fun True n = n-1
fun _ n    = n

-- test :: Bool -> Int -> Int -> Int

test True x y = x
test False x y = y


member []	y = False 
member (x:xs) y = (x==y) || member xs y
