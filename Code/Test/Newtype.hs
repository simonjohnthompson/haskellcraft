module Newtype ( Store ) where

newtype Store = Store [Integer]
	deriving (Show,Eq)

