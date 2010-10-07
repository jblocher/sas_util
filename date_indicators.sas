/*****************************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    April, 2009                                                         
/* LAST MODIFIED:   December 10, 2008                                                         
/* PROG NAME:       trading_day_indicators.sas                                                              
/* Project:         Utility
/* Proj Descr:      Queries CRSP to get S&P index, and thus all trading days, also labels
					Quarters, and Month/Quarter/Year End and Beginnings.
/*****************************************************************************************/

/* Datasets required: None. Just CRSP and COMPUSTAT access on WRDS.
 *
 * Datasets Produced:
 *   jbdaily.wrds_temp_index    : S&P500 vwretd index for date range specified, to
 *								: 	accurately specify month,qtr,yr end.
 */



*define some variables to subset the data if needed for quick testing;
*%let beg = '01jan1987'd;
*%let end = '31dec2008'd;


%macro date_indicators(beg = , end = );

/* Here, we're getting the S&P500 index to calculate our date indicators.
   We do this because we want to be sure to have valid indicators for each
   trading day and thus need an observation on every trading day in our sample */

data wrds_temp_index1;
    set crsp.dsi (keep = DATE VWRETD);
    where DATE > &beg AND DATE < &end;
    *use index data to set date values to be sure we get all trading days;
    YEAR = year(DATE);
    MONTH = month(DATE);
    DAY = day(DATE);
    if (MONTH = 1) or (MONTH = 2) or (MONTH = 3) then QTR = 1;
    if (MONTH = 4) or (MONTH = 5) or (MONTH = 6) then QTR = 2;
    if (MONTH = 7) or (MONTH = 8) or (MONTH = 9) then QTR = 3;
    if (MONTH = 10) or (MONTH = 11) or (MONTH = 12) then QTR = 4;
run;

proc sort data = wrds_temp_index1;
    by year month day;
run;

* Create End of Month Indicator;
data wrds_temp_index1;
    set wrds_temp_index1;
    by year qtr month;
    if first.month then monthBeg = 1; else monthBeg = 0;
    if last.month then monthEnd = 1; else monthEnd = 0;
    label monthBeg = "MonthBegin Indicator";
    label monthEnd = "MonthEnd Indicator";
run;

* create EOQ indicator;
data wrds_temp_index1;
    set wrds_temp_index1;
    by year qtr;
    if first.qtr then qtrBeg = 1; else qtrBeg = 0;
    if last.qtr then qtrEnd = 1; else qtrEnd = 0;
    label qtrBeg = "QuarterBegin Indicator";
    label qtrEnd = "QuarterEnd Indicator";
run;

/* create EOY indicator */
/* IMPORTANT: DATA MUST END ON 12/31 or a FALSE EOY INDICATOR WILL BE CREATED */
/* this is because I'm using the last.<var> keyword, so whatever the last entry is will get the EOY ind = 1 
/* Also, data must end on a month and quarter end as well, but ending on 12/31 solves all 3 */

data wrds_temp_index1;
    set wrds_temp_index1;
    by year;
    if first.year then yearBeg = 1; else yearBeg = 0;
    if last.year then yearEnd = 1; else yearEnd = 0;
    label yearBeg = "YearBegin Indicator";
    label yearEnd = "YearEnd Indicator";
run;

data date_indicators;
	set wrds_temp_index1;
	*Fix indicator variables;
	if qtrEnd = 1 then monthEnd = 0;
	if qtrBeg = 1 then monthBeg = 0;
	if yearEnd = 1 then qtrEnd = 0;
	if yearBeg = 1 then qtrBeg = 0;
	* end fix indicator vars;
run;

* For testing;
*proc print data = date_indicators;
*title 'Period Indicators';
*where yearEnd = 1 or monthEnd = 1 or qtrEnd = 1 or yearBeg = 1 or monthBeg = 1 or qtrBeg = 1;
*run;

%mend;