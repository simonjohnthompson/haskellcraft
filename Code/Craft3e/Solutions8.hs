------------------------------------------------------------------------------
--
--  Haskell: The Craft of Functional Programming
--  Simon Thompson
--  (c) Addison-Wesley, 2011.
-- 
--  Solutions8
--
------------------------------------------------------------------------------

module Solutions8 where
import Chapter8 hiding (outcome, tournamentOutcome,sLostLast,putNtimes,playSvsS,result)
import Solutions7 (palCheck)
import Chapter7 (splitWords,ins)

--
-- Solution 8.1
-- 

-- Outcome of a play
--   +1 for first player wins
--   -1 for second player wins
--    0 for a draw

outcome :: Move -> Move -> Integer

outcome Rock Rock = 0
outcome Rock Paper = -1
outcome Rock Scissors = 1
outcome Paper Rock = 1
outcome Paper Paper = 0
outcome Paper Scissors = -1
outcome Scissors Rock = -1
outcome Scissors Paper = 1
outcome Scissors Scissors = 0

--
-- Solution 8.2
-- 

tournamentOutcome :: Tournament -> Integer

tournamentOutcome (moves1,moves2)
  = sum [ outcome move1 move2 | (move1,move2) <- zip moves1 moves2 ]

testTournament :: Tournament

testTournament = ([Rock,Rock,Paper], [Scissors, Paper, Rock])

--
-- Solution 8.3
-- 

-- Echo a move that would have lost the last play; 
-- also have to supply starting Move.

sLostLast :: Move -> Strategy

sLostLast start moves 
      = case moves of
          [] -> start
          (last:_) -> lose last

-- Echo a move that would have won the last play; 
-- also have to supply starting Move.

sWinLast :: Move -> Strategy

sWinLast start moves 
      = case moves of
          [] -> start
          (last:_) -> beat last

--
-- Solution 8.4
-- 

sRepeats :: Strategy

sRepeats moves
  | length moves >=2 && last moves == last (init moves)   = case randInt 2 of
                                                                 0 -> (last moves)
                                                                 1 -> lose (last moves)
  | otherwise                                             = randomStrategy moves
   
--
-- Solution 8.5
-- 

freqs :: [Move] -> [(Move,Int)]

freqs moves
  = [ (move, count move moves) | move<-[Rock,Paper,Scissors] ]
    where 
    count move []     = 0
    count move (m:ms) = (if move==m then 1 else 0) + count move ms

sAnalyse :: Strategy

sAnalyse moves 
  | noMin                        = randomStrategy moves
  | otherwise                    = beat minFreq
    where
    frequencies = freqs moves
    [ (Rock,rockVal), (Paper, paperVal), (Scissors, scissorsVal)] = frequencies
    noMin       = (rockVal==paperVal && rockVal<=scissorsVal) ||
                  (rockVal==scissorsVal && rockVal<=paperVal) ||
                  (scissorsVal==paperVal && paperVal<=rockVal)
    minFreq     = if (rockVal<paperVal && rockVal<scissorsVal)
                     then Rock
                     else if (paperVal<scissorsVal && paperVal<rockVal) 
                          then Paper
                          else Scissors

--
-- Solution 8.6
-- 

-- up to you!


--
-- Solution 8.7
-- 

alternate :: Strategy -> Strategy -> Strategy

alternate str1 str2 moves =
    case length moves `rem` 2 of
      1 -> str1 moves
      0 -> str2 moves

--
-- Solutions 8.8-8.9
-- 

-- Up to you: open-ended questions.

--
-- Solution 8.10
-- 

interactivePalCheck :: IO ()

interactivePalCheck
  = do putStr "Input a string for palindrome check: "
       st <- getLine
       if palCheck st 
          then putStr "Palindrome.\n"
          else putStr "Not a palindrome.\n"

--
-- Solution 8.11
-- 

interactiveIntSum :: IO ()

interactiveIntSum
  = do putStr "Input an integer (followed by Return): "
       st1 <- getLine
       let int1 = (read st1) :: Int
       putStr "Input another integer (followed by Return): "
       st2 <- getLine
       let int2 = read st2 :: Int
       putStrLn ("The sum of these integers is "++ show (int1+int2))

--
-- Solution 8.12
-- 

putNtimes :: Integer -> String -> IO ()

putNtimes n st
  = if n<=0 
       then return ()
       else do putStrLn st
               putNtimes (n-1) st                                                   

--
-- Solution 8.13
-- 

-- Instead of solving this as a single function, worth thinking about how you can 
-- decompose the problem: wriet a function to get an integer, and another
-- to do the summing.

-- Useful auxiliary function, taking the prompt as parameter.

getInteger :: String -> IO Integer

getInteger prompt
  = do putStr prompt
       st <- getLine
       return (read st :: Integer)

-- Sum N integers: prompt, number to sum and and "sum so far" are the parameters

sumNints :: String -> Integer -> Integer -> IO Integer

sumNints prompt n s
  = if n<=0 
       then return s
       else do m <- getInteger prompt
               sumNints prompt (n-1) (s+m)


--- The function itself

getNints :: IO ()

getNints
  = do bound <- getInteger "Input the number of integers to add: "
       sum <- sumNints "Input an integer: " bound 0
       putStrLn ("The sum of these integers is "++ show sum)

--
-- Solution 8.14
-- 

-- One solution is to write a function that simply accumulates all the lines
-- into a single string and then uses the wc function in the Solutions7 module.

-- Here we do the counting line-by-line. The argument to the function is
-- the "counts so far". If we have a non-empty line then after processing the line
-- these counts are increased by 
--       lines: 1 
--       words: length (splitWords line)
--       chars: length line

interactiveWC :: (Int,Int,Int) -> IO ()

interactiveWC (l,w,c)
  = do line <- getLine
       if line==[] 
          then do putStr ("Lines: "++show l)
                  putStr (" Words: "++show w)
                  putStrLn (" Chars: "++show c)
          else interactiveWC (l+1, w + length (splitWords line), c + length line)


--
-- Solution 8.15
-- 

-- See 8.10 ...


--
-- Solution 8.16
-- 

repeatedPalCheck :: IO ()

repeatedPalCheck
  = do putStr "Input a string for palindrome check (empty to end): "
       st <- getLine
       if st==[]
          then return ()
          else do if palCheck st 
                     then putStr "Palindrome.\n"
                      else putStr "Not a palindrome.\n"
                  repeatedPalCheck

--
-- Solution 8.17
-- 

-- See Chapter17.hs

--
-- Solution 8.18
-- 

-- the argument is the "sorted list so far"

-- to call it interactively, call thus:
--    interactiveSort []

interactiveSort :: [Integer] -> IO ()

interactiveSort sList
  = do int <- getInteger "Input an integer (0 to stop): "
       if int==0 
          then putStrLn ("Sorted list: "++show sList)
          else interactiveSort (ins int sList)

--
-- Solution 8.19
-- 

-- Need to think about the different instances of line here: which instances
-- refar to which defining instances?

--
-- Solution 8.20
-- 


playSvsS :: Strategy -> Strategy -> Integer -> Tournament

playSvsS strategyA strategyB n
     = if n<=0 then ([],[]) else step strategyA strategyB (playSvsS strategyA strategyB (n-1))

--
-- Solution 8.21
-- 

-- The result of a Tournament, calculates the outcome of each
-- stage and sums the results.

result :: Tournament -> Integer

result = sum . map (uncurry outcome) . uncurry zip


showTournament :: Tournament -> String

showTournament tournament
  = concat [ showPlay play | play<-tourPairs tournament ] ++
    showResult tournament
    where 
    tourPairs (playsA, playsB) = zip playsA playsB

showPlay :: (Move, Move) -> String

showPlay (moveA,moveB)
  = "A: " ++ show moveA ++ " B: " ++ show moveB ++ ".  " ++
    if out==1 
       then " A wins.\n"
       else if out==(-1)
               then " B wins.\n"
               else " Draw.\n"
    where
    out = outcome moveA moveB         

showResult :: Tournament -> String

showResult tournament
  = "Result is: " ++ show res ++ ".   " ++
    if res>0 
       then "A wins tournament.\n"
       else if res<0
               then "B wins tournament.\n"
               else "Tournament drawn.\n" 
    where
    res = result tournament

-- for testing

tour = playSvsS randomStrategy randomStrategy 10

--
-- Solution 8.22
-- 

-- In principle makes no difference, as given your strategy and their moves 
-- can always re-calculate your moves in response to theirs.

--
-- Solution 8.23
-- 

-- Not really. Though check out the RPS website ...


