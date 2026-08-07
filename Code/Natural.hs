module Natural where

type Natural a = (a->a) -> (a->a)

zero,one,two :: Natural a 

zero _ = id

one = id

two f = f.f

succ :: Natural a -> Natural a

succ n f = f. n f

plus :: Natural a -> Natural a -> Natural a

plus n m f = n f . m f

times :: Natural a -> Natural a -> Natural a

times n m f = n (m f)



int :: Natural Int -> Int

int n = n (+1) 0

 