******************************************************;
*** CHAPTER 10 PROGRAM                             ***;
*** Program to analyze transactions and quote data ***;
*** NOTE: If the data are first read directly from ***;
*** a source such as WRDS or TAQ, the code in the  ***;
*** Appendix must be run first                     ***;
******************************************************;
/* Program and commentary from the book "Using SAS in
 * Financial Research" 2002 by Boehmer, Broussard and 
 * Kallunki. ISBN-13: 978-1590470398
 */
 
 /* Commentary:
 Two commonly used procedures to infer trade direction from trade and quote data are 
 the tick test and the quote test (L&R 1991). The tick test classifies a trade as buyer-
 initiated, if the trade price is above the previous price. Correspondingly, when the 
 current price is below the previous one, the trade is classified as seller-initiated. 
 
 The quote test compares the current price to the prevailing quote. If the transaction 
 takes place above the quote midpoint, it is deemed buyer-initiated; if it is below the 
 midpoint, it is deemed to be initiated by the seller. In this chapter, we compute both 
 measures and, as suggested by Lee and Ready, use a combination to infer trade direction.
 */

* Code 10.1: Combine trades at the same price and time;
*** Program to read TAQ data, compute spreads, and estimate a VAR model;

 /* %let d = 0505;  for testing */

%macro lee_ready(d = );

/* subset the data */
data lr_ct_small;
	set taq.ct&d;
	where symbol in ("IBM" "A" "MMM");
run;
data lr_cq_small;
	set taq.cq&d;
	where symbol in ("IBM" "A" "MMM");
run;


*** combine all trades at the same time and price into one;
proc sort data=lr_ct_small out=trades;
	by symbol date time price; 
/* PROC MEANS to aggregate all trades in a single second together into one "trade". */	
proc means data=trades noprint;
	by symbol date time price;
	output out=adjtrades (rename=(_freq_=numtrades) drop=_type_) sum(size)=size; 
	run;
	
 /* Commentary:
 This DATA step reads the consolidated trades and creates a new data set NTRADES. The 
 next statement creates a unique trade record identifier, TID. This is very useful for 
 matching purposes.

 To adjust the trade time, we subtract 5 seconds from the reported time and store the 
 difference in the variable TIME. The original time is retained in the variable TIME_REAL
 for debugging. Next, the tick test variable TICK is computed. Here, we go back two trades
 to infer trade direction: if the current price is the same as the previous one, we also 
 check the next previous price. You may want to limit this comparison to one price, or 
 extend to longer intervals, depending on the specific application. If the tick test does
 not yield an answer, the TICK variable is set to zero. Then, they label and run PROC FREQ
 to list frequency of buys vs. sells.
 */
* Code 10.2: Compute tick test and adjust for late trade reporting;
*** adjust trade time stamp and prepare for tick test;
data ntrades;
	set adjtrades;
	* create unique trade identifier;
	tid = _n_;
	* advance trades by 5 secs to adjust for late reporting;
	time_real = time; 
	time = time - 5;
	label time='trade time - 5 secs';
	label time_real = 'reported trade time';
	format time_real time8.;
	* compute variable for tick test;
	* note: this step can be modified to look back further than one trade;
	lagprice  = lag(price);
	lag2price = lag2(price);
	if price > lagprice then tick =  1;
	if price < lagprice then tick = -1;
	if price = lagprice then do;
		if lagprice > lag2price then tick =  1;
		if lagprice < lag2price then tick = -1;
	end;
	if _n_ < 3 then tick=0;	
	if tick = . then tick = 0;
	drop time_real lagprice lag2price;
	label tick      = 'trade indicator based on tick test';
	label tid       = 'trade identifier';
	label numtrades = 'number of aggregated trades';
	run;
* Code 10.3: Frequency analysis for tick test;
* print frequency counts for tick test;
proc freq data=ntrades;
	by symbol;
	tables tick;
	run;
	
	
 /* Commentary:
 Computing Quote Changes and Combining them with Trades
 In this step, we first identify quote changes that also affected the quote midpoint. 
 These midpoint changes are needed for our later analysis of the effect of trades on 
 quote updates. Next, these quotes and all trades are combined into one file. Note that
 this intermediate step eliminates quote changes from the sample where the midpoint 
 remained the same (for example, when the quoted spread widens symmetrically around 
 the midpoint). In many studies of bid-ask spreads, these spreads may be of particular
 interest and thus hsould not be excluded.
 */
* Code 10.4: Compute quote changes and combine them with trade records;
* compute quote changes;
proc sort data=lr_cq_small;
	by symbol date time;
data allqchange;
	set lr_cq_small;
	by symbol;
	midpoint = (bid+ofr)/2;
	oldmp = lag(midpoint);
	if first.symbol then oldmp = .;
	* create unique quote identifier;
	qid = _n_;
	* output only if the quote has changed;
	drop oldmp;
	label qid      = 'quote identifier';
	label midpoint = 'quote midpoint';
	if midpoint ne oldmp then output; run;
* combine trades and quotes;
data qandt;     
	set allqchange (in=a) ntrades (in=b);
	if a then trade=0;
	if b then trade=1;
	run;
 /* Post commentary on Code 10.4:
 Code 10.4 reads the quotes and creates a new data set ALLCHANGE, which contains only 
 quote updates. First, a new variable MIDPOINT is defined as the arithmetic average of 
 the bid and ask quotes. We also create a unique record identifier, QID, Only if the 
 current midpoint is different from the previous one is the record written to the output
 data set. Again, this procedure is not appropriate for all applications. Here, the 
 primary interest is in the path of quote midpoint; if the spread is of greater 
 importance, you should identify changes of bid *and* ask, and not just those of 
 the midpoint.
 The second data step reads the new trade and quote files and combines them into one 
 data set. Note that both share and the variables SYMBOL, DATE, and TIME, but both have
 additional variables that are unique to trades or quotes. We use the SET statement to 
 combine both data sets and create a new indicator variable, TRADE, that classifies each
 record either as a trade or as a quote. To create this indicator, the data set option 
 IN is used. For example, when a set reads a record from NTRADES, the variable B is 
 assigned a value of one. When a quote is read, B is missing. Because the variables 
 created by the IN option are not permanent, their values have to be assigned to a new 
 variable if they need to be written to the output data set; here, both A and B are 
 combined into the TRADE variable.
Note that we use the SET statement and list both the trade and quote data sets in the 
same statement. This instructs SAS to first read all observations from the first data 
set, and then from the second. Thus, the output data set contains all variables that 
appear in either input data set, and as many observations as both input data sets 
combined. If a variable appears in only one of the input data sets, its value will be 
set to missing when records are read from the other input data set. It is important to 
distinguish the use of a single SET statement with multiple data set from the use of 
multiple SET statements, which operate more like (but not identical to) a MERGE statement.
The data set QANDT now contains all quote (midpoint) changes and all aggregated trade 
records for both GE and AT&T. Most importantly, each record is identified by stock symbol,
date, and time, allowing us to subset the data in a way that is useful to our analysis. 
As discussed earlier in this chapter, the procedure to do that depends on the type of 
questions we need to answer. We first present a solution to the trading-cost estimation,
and later one for the VAR analysis.
*/
	
	
/* Commentary:
 Estimation of Trading Costs
 To estimate measures of trading cost, we are interested in the quotes that were posted 
 at the time a trade was executed (ideally, the quote at the time the order was entered, 
 but those data are not public). Thus, the data set QANDT only needs to be sorted by date
 and time for each security. Because the data contain all quote changes, after sorting, 
 the most recent quote record that precedes a certain trade is the prevailing quote for 
 this trade. The only complication is that often one or more trades follow each other 
 without intervening quote changes; this has to be accounted for.
 */
* Code 10.5: Compute net order flow and various spread measures;
*** sort and compute spreads;
title1 'Spread estimation';
proc sort data=qandt;
	by symbol date time;
data spread;
	set qandt;
	by symbol date;
	* reset retained variables if a new ticker or new day starts;
	if first.symbol or first.date then do;
	nbid = .; nofr = .; currentmidpoint = .; end;
	* assign bid and ask to new variables for retaining;
	if bid      ne . then nbid            = bid;
	if ofr      ne . then nofr            = ofr;
	if midpoint ne . then currentmidpoint = midpoint;
	* compute spread measures;
	effsprd = abs(price - (nbid+nofr)/2) * 2;
	asprd   = nofr - nbid;
	rsprd   = asprd / price;
	*** compute variables for trade direction;
	if currentmidpoint ne . then do;
		* quote test - compare current trade to quote: -1 is a sell, +1 is a buy;
		if price < currentmidpoint then ordersign = -1;
		if price > currentmidpoint then ordersign =  1;
		* tick test for midpoint trades;
		if price = currentmidpoint then do;
			if tick =  1 then ordersign =  1;
			if tick = -1 then ordersign = -1;
			if tick =  0 then ordersign =  0;
		end;
		* signed net order flow;
		nof = ordersign * size;
	end;
	* labels;
	label nbid      = 'last outstanding bid';
	label nofr      = 'last outstanding ofr';
	label effsprd   = 'effective spread';
	label asprd     = 'absolute spread';
	label rsprd     = 'relative spread';
	label nof       = 'net order flow';
	label ordersign = 'indicator for trade direction';
	* output to data set;
	if trade=1 then output spread;
	retain nbid nofr currentmidpoint;
	drop bid ofr midpoint qid trade;
	run;
proc freq data=spread;
	by symbol;
	tables ordersign;
	run;
/* Post commentary on 10.5:
The program first sorts the data by stock, date, time. The sorted records are then read
in BY groups corresponding to the sorting. This technique has the advantage that SAS 
automatically marks the first and last record for each of those groups; these indicators
will be used by the program. The basic programming intuition is to first check whether a
record is a quote or a trade. If it is a quote, it will be retained. If the next record 
is again a quote, the new record will overwrite the old retained one. On the other hand,
if the next record is a trade, the retained variables (the prevailing quote) will be 
added to the trade record and then written to the output data set SPREAD. 
The first step is to initialize the retainer variables NBID, NOFR, and CURRENTMIDPOINT. 
Whenever the first record of a stock or of a new day is read, they are set to missing. 
Next, they are assigned the current values of bid, ask, and midpoint, respectively. Note
that the "If BID(OFR,MIDPOINT) NE . " conditions are satisfied only by quote records; 
trade records all have missing values there. Thus, these statements always assign the 
most recent quotes to the retainer variables.
Next, the program computes three spread measures, the effective, absolute, and relative 
spreads. The absolute spread is defined as the dollar difference between ask and bid, 
and the relative spread is additionally scaled by the midpoint. The effective spread 
is based on the difference between trade price and midpoint. It is computed as twice 
the absolute value of this difference.
To infer trade direction, the third section of the code applies a combined quote and 
tick test to trade records. This new variable ORDERSIGN is set to one (minus one) if 
the trade price is above (below) the prevailing quote midpoint. For trades at the 
midpoint, the previously computed tick test is applied. Finally, the signed net order 
flow is computed as the product of ORDERSIGN and SIZE, the trading volume of each 
transaction.
After assigning the appropriate labels to each new variable, all trade records (which 
now include the prevailing quotes) are written to the new data set SPREAD. Note the 
RETAIN statement below the OUTPUT statement; it tells SAS note to set all variables 
to missing before it reads the next record from the input data set. Instead, the 
current values of the retainer variables are preserved.
The following PROC MEANS statement is used to produce descriptive statistics for each stock.
*/

* Code 10.6: Compute descriptive statistics for net order flow and spread measures;
proc means data=spread n mean median min max;
	by symbol;
	var price size effsprd asprd rsprd ordersign nof;
	run;
/* Post commentary on 10.6:
The output shown in the table below (labels are omitted to save space). It is always 
important to check outliers in the data. For example, the table for GE shows that the 
absolute spread becomes as large as $1.00; this is very large compared to the mean of 
about 8.7 cents. When checking this observation in the original data, you will find 
that this and more large estimates mostly appear around the opening of trading on 
Feb 3, 1998. Depending on your application, you may want to go into greater detail 
in verifying that these numbers indeed represent spreads that were quoted at those 
times and not potential data errors. Similarly, the huge effective spread of $1.94 
may be due to a mismatch of quotes and trades or due to a data entry error. It is 
important for most applications that these extreme values be checked. 
*/
%mend lee_ready;

%lee_ready(d = 0301);
%lee_ready(d = 0302);
%lee_ready(d = 0303);
