----------------------------------------------------------
--
--	RunGraphicMine.hs
--
--	Simon Thompson, 2026
--
----------------------------------------------------------

-- The executable entry point for the graphical Minesweeper in
-- GraphicMine.hs: `cabal run minesweeperGraphical`.

module Main where

import GraphicMine ( playGameG )

main :: IO ()
main = playGameG 10 8
