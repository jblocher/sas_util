/*****************************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    December 2, 2008                                                         
/* LAST MODIFIED:   December 10, 2008                                                         
/* PROG NAME:       SI_Data_Download                                                               

/*****************************************************************************************/


*define some variables to subset the data if needed for quick testing;
%let beg = '01jan1987'd;
%let end = '31dec2008'd;


/* Create temporary crsp stock daily returns data view.
 * First, query CRSP Daily Stock File to get the KEEP values listed
 *      within the date values, deleting empty data 
 */

data wrds_temp_stock_1;
    set crsp.dsf (keep = PERMNO CUSIP DATE RET SHROUT HEXCD VOL);
    where DATE > &beg AND DATE < &end;
    * create date fields for later join;
    YEAR = year(DATE);
    MONTH = month(DATE);
run;

data wrds_temp_stock_2;
    set crsp.dsfhdr (keep = PERMNO HSHRCD);
    *get share code;
    where HSHRCD in (10,11);
run;

proc sql;
    create table jbdaily.wrds_temp_stock as
    select *
    from wrds_temp_stock_1 as a left join wrds_temp_stock_2 as b
    on (a.PERMNO = b.PERMNO);
quit;

* final data set has PERMNO CUSIP DATE RET SHROUT HEXCD VOL HSHRCD over date range, daily.;

/* Here, we're getting the S&P500 index to calculate our date indicators.
   We do this because we want to be sure to have valid indicators for each
   trading day and thus need an observation on every trading day in our sample */



data jbdaily.wrds_temp_index;
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
