module Solns5 where

import Prelude hiding (id)
import Test.QuickCheck
import Chapter5

-- Check that bk is in the list of loaned books to pers
-- after making the loan of book to pers and then 
-- making another random loan.

prop_db3 :: Database -> Person -> Book -> Person -> Book -> Bool

prop_db3 dBase pers bk pers2 bk2 =
    elem bk loanedAfterLoan2 == True
         where
           afterLoan = makeLoan dBase pers bk
           afterLoan2 = makeLoan afterLoan pers2 bk2
           loanedAfterLoan2 = books afterLoan2 pers

-- Check that bk is in the list of loaned books to pers
-- after making the loan of book to pers and then 
-- making another random return, as long as it's not
-- the loan of bk to pers.

prop_db4 :: Database -> Person -> Book -> Person -> Book -> Bool

prop_db4 dBase pers bk pers2 bk2 =
    elem bk loanedAfterReturn == True
         where
           afterLoan = makeLoan dBase pers bk
           afterReturn = if pers2/=pers || bk2/=bk 
                         then returnLoan afterLoan pers2 bk2 
                         else afterLoan
           loanedAfterReturn = books afterReturn pers

