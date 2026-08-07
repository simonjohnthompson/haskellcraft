------------------------------------------------------------------
--								--
--	Pic2000.hs							--
--								--
--	Simon Thompson						--
--	January, February 2002					--
--	(initially called PicturesSVG)				--
--								--
------------------------------------------------------------------

module Pic where
import System
import Pictures hiding (printPicture,width,height)
import qualified Pictures ( printPicture )


-- The data type
-- ^^^^^^^^^^^^^

-- A data type representing the Pictures developed in Haskell Craft 2e.

data Pic = SB | SW | Horse |
	       Beside Pic Pic |
	       Above Pic Pic |
	       Superimpose Pic Pic |
	       FlipH Pic |
	       FlipV Pic |
	       InvertColour Pic
	       

-- Conversion to ASCII
-- ^^^^^^^^^^^^^^^^^^^

sb = ["####","####","####","####"]
sw = ["....","....","....","...."]

-- Uses the functions in the Pictures module.
-- Constructors converted to their lower case equivalent.

picToASCII :: Pic -> Picture
 
picToASCII SB		       = sb
picToASCII SW		       = sw
picToASCII Horse                   = horse
picToASCII (Beside pic1 pic2)      = beside (picToASCII pic1) (picToASCII pic2)
picToASCII (Above pic1 pic2)       = above (picToASCII pic1) (picToASCII pic2)
picToASCII (Superimpose pic1 pic2) = superimpose (picToASCII pic1) (picToASCII pic2)
picToASCII (FlipH pic)             = flipH (picToASCII pic)
picToASCII (FlipV pic)             = flipV (picToASCII pic)
picToASCII (InvertColour pic)      = invertColour (picToASCII pic)

-- Put a picture on the screen: the analogue of the old printPicture.

picToScreen :: Pic -> IO ()

picToScreen = Pictures.printPicture . picToASCII


-- Conversion to SVG
-- ^^^^^^^^^^^^^^^^^

-- Converting a Pic to a String representation of the
-- SVG graphics for it.

picToSVG :: Pic -> String

picToSVG SB 
  = "<g id=\"sb\"> \
  \<rect style=\"fill:red;\" width=\"50\" height=\"50\"/>\
\</g>" ++"\n"

picToSVG SW 
  = "<g id=\"sw\"> \
  \<rect style=\"fill:blue;\" width=\"50\" height=\"50\"/>\
\</g>" ++"\n"

picToSVG Horse 
  = "<g id=\"horse\"> \
  \<rect style=\"fill:blue;\" width=\"250\" height=\"300\"/>\
  \<text style=\"fill:yellow;\" y=\"15\">This is a horse.</text>\
  \<path style=\"fill:red;\" d=\"M 25 175 L 75 100 L 225 10 L 230 150 L 170\
	 \ 125 L 180 275 z\"/>\
\</g>" ++"\n"

picToSVG (Above pic1 pic2)
  = "<g>" ++ picToSVG pic1 ++ "<g transform=\"translate(0 " 
  			   ++ show (height pic1) ++ ")\">"
	  ++ picToSVG pic2 ++ "</g>\n</g>" ++"\n"

picToSVG (Beside pic1 pic2)
  = "<g>" ++ picToSVG pic1 ++ "<g transform=\"translate(" 
  			   ++ show (width pic1) ++ ")\">"
	  ++ picToSVG pic2 ++ "</g>\n</g>" ++"\n"

picToSVG (Superimpose pic1 pic2)
  = "<g>" ++ picToSVG pic1
          ++ subst "blue" "none" (picToSVG pic2) ++ "</g>\n"

picToSVG (FlipH pic)
  = "<g transform=\"scale(1 -1) translate(0 -" ++ show (height pic) ++ ")\">"
    ++ picToSVG pic ++ "</g>" ++"\n"

picToSVG (FlipV pic)
  = "<g transform=\"scale(-1 1) translate(-" ++ show (width pic) ++ ")\">"
    ++ picToSVG pic ++ "</g>" ++"\n"

picToSVG (InvertColour pic)
  = swap "red" "blue" (picToSVG pic)

-- The header and footer for an SVG description.

headerSVG, footerSVG :: String

headerSVG 
  = "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\n\
\<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 20000303 Stylable//EN\"\n\
 \ \"http://www.w3.org/TR/2000/03/WD-SVG-20000303/DTD/svg-20000303-stylable.dtd\">\n\
\<svg xml:space=\"preserve\" width=\"4in\" height=\"6in\" viewBox=\"0 0\
 \ 500 600\">\n\n"

footerSVG = "\n</svg>\n"

-- Adding the header and footer to an svg description.

picToSVGcomplete :: Pic -> String

picToSVGcomplete pic = headerSVG ++ picToSVG pic ++ footerSVG


-- Printing to an SVG file
-- ^^^^^^^^^^^^^^^^^^^^^^^

-- Putting a Pic into a .svg file

picToFile :: Pic -> String -> IO ()

picToFile pic filename
  = do writeFile (filename++".svg") (picToSVGcomplete pic)


-- Viewing SVG files
-- ^^^^^^^^^^^^^^^^^

-- Loads a picture into internet explorer.
-- This requires the Adobe SVG Viewer (a plugin for Windows and Mac OS)
-- For details and download see:	
--	http://www.adobe.com/svg/main.html

-- You need to replace the string
--	\"c:\\program files\\internet explorer\\iexplore.exe\"
-- with the full path of iexplore.exe on your machine, quoting the 
-- " and \ characters as above.

-- The file needs to be loaded with a full pathname.

printPicture :: Pic -> IO ()

printPicture pic
  = do
    picToFile pic "tempo"
    system "\"c:\\program files\\internet explorer\\iexplore.exe\" d:\\svg\\tempo.svg"
    return ()


-- Loads a picture into the batik SVG browser
-- You can run the browser separately by typing
--	\\raptor\files\packages\batik\batik-svgbrowser.bat
-- to the command prompt
-- Batik, a java application can be downloaded from
--	http://xml.apache.org/batik/
-- Installation and running instructions are on the web.

-- The visible version uses \\raptor.... naming
-- The first hidden version assumes that the x: drive is 
-- mapped to \\raptor\files
-- The second hidden version uses the full path name of the file to be
-- viewed.

printPictureB :: Pic -> IO ()

printPictureB pic
  = do
    picToFile pic "tempo"
    system "\\\\raptor\\files\\packages\\batik\\batik-svgbrowser.bat \"tempo.svg\""
    -- system "x:packages\\batik\\batik-svgbrowser.bat \"tempo.svg\""
    -- system "x:packages\\batik\\batik-svgbrowser.bat \"d:\\svg\\tempo.svg\""
    return ()


-- Examples of Pictures.
-- ^^^^^^^^^^^^^^^^^^^^^

fourHorse :: Pic
fourHorse
  = twoHorse `Above` (FlipH twoHorse)
    where
    twoHorse = Horse `Beside` (FlipV Horse)

fourHorse2 :: Pic
fourHorse2
  = twoHorse `Above` (InvertColour (FlipH twoHorse))
    where
    twoHorse = Horse `Beside` (FlipV Horse)

superHorses :: Pic
superHorses = Superimpose Horse (FlipV Horse)

-- A chessboard

chess :: Int -> Pic

chess n
  | n==1	= SB
  | n>1		= line n `Above` (col (n-1) `Beside` chess (n-1))
  | otherwise	= error "chessboard size"

line n
  | n==1	= SB
  | n>1		= SB `Beside` line' (n-1)

line' n
  | n==1	= SW
  | n>1		= SW `Beside` line (n-1)

col n
  | n==1	= SW
  | n>1		= SW `Above` col' (n-1)

col' n
  | n==1	= SB
  | n>1		= SB `Above` col (n-1)





-- Auxiliary functions
-- ^^^^^^^^^^^^^^^^^^^

max2 :: Int -> Int -> Int
max2 x y = if x>=y then x else y

-- Substitute every occurrence of old with new in the String st.
-- A one pass algorithm, doesn't substitute for overlapping occurrences
-- or for occurrences which result from earlier substitutions.

subst :: String -> String -> String -> String

subst old new st
 | len < oldlen	= st
 | chew==old 	= new ++ subst old new rest
 | otherwise	= head st : subst old new (tail st)
   where
   len = length st
   oldlen = length old
   (chew,rest) = splitAt oldlen st

-- Swap all occurrences of old and new in the String st.
-- Assumes that the string "TEMP" doesn't occur in the string.
-- Carries the caveats of the subst function.

swap :: String -> String -> String -> String

swap old new = subst "TEMP" new . subst new old. subst old "TEMP"
 
-- Calculating the height and width of the (rectangular bounding box
-- for) a picture.

height, width :: Pic -> Int
height SB		       = 50
height SW		       = 50
height Horse                   = 300
height (Beside pic1 pic2)  = max2 (height pic1) (height pic2)
height (Above pic1 pic2)       = (height pic1) + (height pic2)
height (Superimpose pic1 pic2) = max2 (height pic1) (height pic2)
height (FlipH pic)             = height pic
height (FlipV pic)             = height pic
height (InvertColour pic)      = height pic

width SB		      = 50
width SW		      = 50
width Horse                   = 250
width (Beside pic1 pic2)  = (width pic1) + (width pic2)
width (Above pic1 pic2)       = max2 (width pic1) (width pic2)
width (Superimpose pic1 pic2) = max2 (width pic1) (width pic2)
width (FlipH pic)             = width pic
width (FlipV pic)             = width pic
width (InvertColour pic)      = width pic

