------------------------------------------------------------------------------
--
-- 	Haskell: The Craft of Functional Programming
-- 	Simon Thompson
-- 	(c) Addison-Wesley, 2011.
-- 
-- 	UsePictures
-- 
--      Solutions to Exercises 2.1-2.4
--
------------------------------------------------------------------------------


module UsePictures where
import Pictures

--
-- Solution 2.1
--

blackHorse :: Picture  
blackHorse = (invertColour horse)

rotateHorse :: Picture
rotateHorse = flipH (flipV horse)

--
-- Solution 2.2
-- 

-- One approach is to define it all in one go ...

square1 :: Picture

square1 =  (black `beside` white) `above` (white `beside` black)

-- ... another uses some auxilary definitions:

bw, wb, square2 :: Picture

bw = black `beside` white
wb = white `beside` black

square2 = bw `above` wb

-- Other approaches put the squares above each other before putting 
-- the results beside each other, using auxiliary definitions or not.

-- Variants don't use infix functions, or define wb by inverting bw:

wb1 = invertColour bw

--
-- Solution 2.3
--

-- Some of hese solutions use two auxiliary definitions

-- White horse next to black horse, and vice versa

blackWhite, whiteBlack :: Picture
blackWhite = (beside horse blackHorse)
whiteBlack = (beside blackHorse horse)

-- A: White horse black horse, above black horse white horse

checkBoard1 :: Picture
checkBoard1 = (beside (above horse (blackHorse)) (above (blackHorse) horse))

-- B: White horse, black horse above black horse white horse, flipped vertically

checkBoard2 :: Picture
checkBoard2 = (above (blackWhite) (flipV blackWhite))

-- C: White horse black horse above black horse white horse, flipped horizontally

checkBoard3 :: Picture
checkBoard3 = (above (blackWhite) (flipV (flipH blackWhite)))

--
-- Solution 2.4
--

-- White horse black horse above upside down white horse black horse, flipped horizontally

checkBoard4 :: Picture
checkBoard4 = (above (blackWhite) (flipH whiteBlack))





