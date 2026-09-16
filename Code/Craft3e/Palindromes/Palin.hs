
------------------------------------------------------------------
--								--
--	Solution to the palindrome problem			--
--								--
--	(c) Simon Thompson, University of Kent, 1997-2011       --
--                                                              --
------------------------------------------------------------------

module Palin where

import Data.Char

palin :: String -> Bool

palin st = simplePalin (disregard st)

simplePalin :: String -> Bool

simplePalin st = (rev st == st)

rev :: String -> String

rev []	   = []
rev (a:st) = rev st ++ [a]

disregard :: String -> String

disregard = change . remove

remove :: String -> String
change :: String -> String

remove []	= []
remove (a:st) 
  | notPunct a  = a : remove st   
  | otherwise   =     remove st	

notPunct ch = isAlpha ch || isDigit ch

change []	= []
change (a:st) = convert a : change st

convert :: Char -> Char

convert ch 
  | isCap ch      = toEnum (fromEnum ch + offset)
  | otherwise     = ch
    where
    offset = fromEnum 'a' - fromEnum 'A'

isCap :: Char -> Bool

isCap ch = 'A' <= ch && ch <= 'Z'

