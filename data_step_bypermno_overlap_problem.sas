/* This is some example code of how to get around the overlapping data lagX() problem when you sort
 * 	by permno date;
 * because if your do lag1(X) and it is the first record, then you'll get the value from the previous 
 * permno in the sort. Same (but bigger) problem for lag10(X), etc.
 *
 * The key is to grab the lagged permno and check to make sure you're still in the same block. 
 * this code does it with cusips, but you get the idea.
 */
 
proc sort data = earnings;
	by earnings cusip descending rptdate;
run;

data earnings(keep=cusip rptdate next1rpt next2rpt next3rpt);
                set earnings;
                
                l1cusip = lag1(cusip);
                l2cusip = lag2(cusip);
                l3cusip = lag3(cusip);

                l1rptdt = lag1(rptdate);
                l2rptdt = lag2(rptdate);
                l3rptdt = lag3(rptdate);

                l1nqtr = lag1(nrptqtr);
                l2nqtr = lag2(nrptqtr);
                l3nqtr = lag3(nrptqtr);

                if (l1cusip = cusip) and (nrptqtr-1) = l1nqtr then next1rpt = l1rptdt;
                if (l2cusip = cusip) and (nrptqtr-2) = l2nqtr then next2rpt = l2rptdt;
                if (l3cusip = cusip) and (nrptqtr-3) = l3nqtr then next3rpt = l3rptdt;
                
run;
