/*******************************************************************************************/
/* FileName: iclink.sas                                                                    */
/* Date: Sept 25, 2006                                                                     */
/* Author: Rabih Moussawi                                                                  */
/* Description: Create IBES - CRSP Link Table                                              */

/* FUNCTION: - Creates a link table between IBES TICKER and CRSP PERMNO                    */
/*           - Scores links from 0 (best link) to 6                                        */
/*                                                                                         */
/* INPUT:                                                                                  */
/*       - IBES: IDUSM file                                                                */
/*       - CRSP: STOCKNAMES file                                                           */
/*                                                                                         */
/* OUTPUT: ICLINK set stored in home directory                                             */
/*         ICLINK has 15,187 unique IBES TICKER - CRSP PERMNO links                        */
/*         ICLINK contains IBES TICKER and the matching CRSP PERMNO and other fields:      */
/*           - IBES and CRSP Company names                                                 */
/*           - SCORE variable: lower scores are better and high scores may need further    */
/*               checking before using them to link CRSP & IBES data.                      */
/*               In computing the score, a CUSIP match is considered better than a         */
/*               TICKER match.  The score also includes a penalty for differences in       */
/*               company names-- CNAME in IBES and COMNAM in CRSP. The name penalty is     */
/*               based upon SPEDIS, which is the spelling distance function in SAS.        */
/*               SPEDIS(cname,comnam)=0 is a perfect score and SPEDIS < 30 is usually good */
/*               enough to be considered a name match.                                     */
/*                                                                                         */
/*              "SCORE" levels:                                                            */
/*               - 0: BEST match: using (cusip, cusip dates and company names)             */
/*                               or (exchange ticker, company names and 6-digit cusip)     */
/*               - 1: Cusips and cusip dates match but company names do not match          */
/*               - 2: Cusips and company names match but cusip dates do not match          */
/*               - 3: Cusips match but cusip dates and company names do not match          */
/*               - 4: Exch tickers and 6-digit cusips match but company names do not match */
/*               - 5: Exch tickers and company names match but 6-digit cusips do not match */
/*               - 6: Exch tickers match but company names and 6-digit cusips do not match */
/*                                                                                         */
/*         ICLINK Example:                                                                 */
/*    TICKER  CNAME                           PERMNO  COMNAM                         SCORE */
/*     BAC    BANKAMERICA CORPORATION          58827  BANKAMERICA CORP                 0   */
/*     DELL   DELL INC                         11081  DELL INC                         0   */
/*     FFS    1ST FED BCP DEL                  75161  FIRST FEDERAL BANCORP DE         3   */
/*     IBM    INTERNATIONAL BUSINESS MACHINES  12490  INTERNATIONAL BUSINESS MACHS CO  0   */
/*     MSFT   MICROSOFT CORP                   10107  MICROSOFT CORP                   0   */
/*                                                                                         */
/*******************************************************************************************/

 * Possible IBES ID (names) file to use (as of April 2006);
 *    Detail History: ID file : 23808 unique US and Canadian company IBES TICKERs;
 *    Summary History: IDSUM File: 15576 unique US company IBES TICKERs;
 *    Recommendation Summary Statistics: RECDSUM File 12465 unique US company IBES tickers;
 * It seems that the Summary History Identifier file IDSUM is best 
                 because USFIRM dummy is used to designate only US companies;

%let IBES1= IBES.IDSUM;
%let CRSP1= CRSP.STOCKNAMES;

*** Edit: Remove home directory (also changed at end) instead put in earnsup ;
%include 'earnsup_header.sas'; *header file with basic options and libraries;
*libname home '~'; * Save link table in home directory;

/* Step 1: Link by CUSIP */
/* IBES: Get the list of IBES TICKERS for US firms in IBES */
proc sort data=&IBES1 out=IBES1 (keep=ticker cusip CNAME sdates);
  where USFIRM=1 and not(missing(cusip));
  by ticker cusip sdates;
run;

/* Create first and last 'start dates' for CUSIP link */
proc sql;
  create table IBES2
  as select *, min(sdates) as fdate, max(sdates) as ldate
  from IBES1
  group by ticker, cusip
  order by ticker, cusip, sdates;
quit;

/* Label date range variables and keep only most recent company name for CUSIP link */
data IBES2;
  set IBES2;
  by ticker cusip;
  if last.cusip;
  label fdate="First Start date of CUSIP record";
  label ldate="Last Start date of CUSIP record";
  format fdate ldate date9.;
  drop sdates;
run;

/* CRSP: Get all PERMNO-NCUSIP combinations */
proc sort data=&CRSP1 out=CRSP1 (keep=PERMNO NCUSIP comnam namedt nameenddt);
  where not missing(NCUSIP);
  by PERMNO NCUSIP namedt; 
run;

/* Arrange effective dates for CUSIP link */
proc sql;
  create table CRSP2
  as select PERMNO,NCUSIP,comnam,min(namedt)as namedt,max(nameenddt) as nameenddt
  from CRSP1
  group by PERMNO, NCUSIP
  order by PERMNO, NCUSIP, NAMEDT;
quit;

/* Label date range variables and keep only most recent company name */
data CRSP2;
  set CRSP2;
  by permno ncusip;
  if last.ncusip;
  label namedt="Start date of CUSIP record";
  label nameenddt="End date of CUSIP record";
  format namedt nameenddt date9.;
run;

/* Create CUSIP Link Table */ 
/* CUSIP date ranges are only used in scoring as CUSIPs are not reused for 
    different companies overtime */
proc sql;
  create table LINK1_1
  as select *
  from IBES2 as a, CRSP2 as b
  where a.CUSIP = b.NCUSIP
  order by TICKER, PERMNO, ldate;
quit; * 14,591 IBES TICKERs matched to CRSP PERMNOs;

/* Score links using CUSIP date range and company name spelling distance */
/* Idea: date ranges the same cusip was used in CRSP and IBES should intersect */
data LINK1_2;
  set LINK1_1;
  by TICKER PERMNO;
  if last.permno; * Keep link with most recent company name;
  name_dist = min(spedis(cname,comnam),spedis(comnam,cname));
  if (not ((ldate<namedt) or (fdate>nameenddt))) and name_dist < 30 then SCORE = 0;
    else if (not ((ldate<namedt) or (fdate>nameenddt))) then score = 1;
	else if name_dist < 30 then SCORE = 2; 
	  else SCORE = 3;
  keep TICKER PERMNO cname comnam score;
run;

/* Step 2: Find links for the remaining unmatched cases using Exchange Ticker */
/* Identify remaining unmatched cases */
proc sql;
  create table NOMATCH1
  as select distinct a.*
  from IBES1 (keep=ticker) as a 
  where a.ticker NOT in (select ticker from LINK1_2)
  order by a.ticker;
quit; * 990 IBES TICKERs not matched with CRSP PERMNOs using CUSIP;

/* Add IBES identifying information */
proc sql;
  create table NOMATCH2
  as select b.ticker, b.CNAME, b.OFTIC, b.sdates, b.cusip
  from NOMATCH1 as a, &IBES1 as b
  where a.ticker = b.ticker and not (missing(b.OFTIC))
  order by ticker, oftic, sdates;
quit;  * 4,157 observations;

/* Create first and last 'start dates' for Exchange Tickers */
proc sql;
  create table NOMATCH3
  as select *, min(sdates) as fdate, max(sdates) as ldate
  from NOMATCH2
  group by ticker, oftic
  order by ticker, oftic, sdates;
quit;

/* Label date range variables and keep only most recent company name */
data NOMATCH3;
  set NOMATCH3;
  by ticker oftic;
  if last.oftic;
  label fdate="First Start date of OFTIC record";
  label ldate="Last Start date of OFTIC record";
  format fdate ldate date9.;
  drop sdates;
run;

/* Get entire list of CRSP stocks with Exchange Ticker information */
proc sort data=&CRSP1 out=CRSP1 (keep=ticker comnam permno ncusip namedt nameenddt);
  where not missing(ticker);
  by permno ticker namedt; 
run;

/* Arrange effective dates for link by Exchange Ticker */
proc sql;
  create table CRSP2
  as select permno,comnam,ticker as crsp_ticker,ncusip,
              min(namedt)as namedt,max(nameenddt) as nameenddt
  from CRSP1
  group by permno, ticker
  order by permno, crsp_ticker, namedt;
quit; * CRSP exchange ticker renamed to crsp_ticker to avoid confusion with IBES TICKER;

/* Label date range variables and keep only most recent company name */
data CRSP2;
  set CRSP2;
  if  last.crsp_ticker;
  by permno crsp_ticker;
  label namedt="Start date of exch. ticker record";
  label nameenddt="End date of exch. ticker record";
  format namedt nameenddt date9.;
run;

/* Merge remaining unmatched cases using Exchange Ticker */
/* Note: Use ticker date ranges as exchange tickers are reused overtime */
proc sql;
  create table LINK2_1
  as select a.ticker,a.oftic, b.permno, a.cname, b.comnam, a.cusip, b.ncusip, a.ldate
  from NOMATCH3 as a, CRSP2 as b
  where a.oftic = b.crsp_ticker and 
	 (ldate>=namedt) and (fdate<=nameenddt)
  order by ticker, oftic, ldate;
quit; * 146 new match of 136 IBES TICKERs; 

/* Score using company name using 6-digit CUSIP and company name spelling distance */
data LINK2_2;
  set LINK2_1;
  name_dist = min(spedis(cname,comnam),spedis(comnam,cname));
  if substr(cusip,1,6)=substr(ncusip,1,6) and name_dist < 30 then SCORE=0;
  else if substr(cusip,1,6)=substr(ncusip,1,6) then score = 4;
  else if name_dist < 30 then SCORE = 5; 
      else SCORE = 6;
run;

/* Some companies may have more than one TICKER-PERMNO link,         */
/* so re-sort and keep the case (PERMNO & Company name from CRSP)    */
/* that gives the lowest score for each IBES TICKER (first.ticker=1) */
proc sort data=LINK2_2; by ticker score; run;
data LINK2_3;
  set LINK2_2;
  by ticker score;
  if first.ticker;
  keep ticker permno cname comnam permno score;
run;


/* Step 3: Add Exchange Ticker links to CUSIP links */ 
/* Create final link table and save it in home directory */
data earnsup.ICLINK;
  set LINK1_2 LINK2_3;
run;

proc sort data=earnsup.ICLINK; by TICKER PERMNO; run;

/* Create Labels for ICLINK dataset and variables */
proc datasets lib=earnsup nolist;
	    modify ICLINK (label="IBES-CRSP Link Table");
            label CNAME = "Company Name in IBES";
			label COMNAM= "Company Name in CRSP";
			label SCORE= "Link Score: 0(best) - 6";
		run;
quit;

/****************************************************************************************************/
/*   Program         : CIBESLINK.sas                                                                */
/*   Author          : Denys Glushkov, WRDS                                                         */
/*   Date Created    : Feb 2008                                                                     */
/*   Last Modified   : Jun 2009									    */ 
/*                                                                                                  */
/*   Description: Link IBES ticker to Compustat GVKEY                                               */
/*                                                                                                  */
/* CIBESLINK macro will create a linking table CIBESLNK between IBES ticker and Compustat GVKEY     */
/* based on IBES ticker-CRSP permno (ICLINK) and CCM CRSP permno - Compustat GVKEY (CSTLINK2) link  */
/****************************************************************************************************/
* Edit: Remove the macro, just run to get the link table;
*%include 'earnsup_header.sas'; *header file with basic options and libraries;
%let begdt = &start_date; *from header file;
%let enddt = &end_date;

proc sort data=crsp.ccmxpf_linktable out=lnk;
	where linktype in ("LU", "LC" /*,"LD", "LF", "LN", "LO", "LS", "LX"*/)  and 
	usedflag=1 and
	(year(&enddt)+1>=year(linkdt) or linkdt=.B) and
	(year(&begdt)-1<=year(linkenddt) or linkenddt=.E);
	by gvkey linkdt;
run;

/*Creating GVKEY-TICKER link for CRSP firms, call it CIBESLNK*/
proc sql; create table lnk1 (drop=permno score where=(missing(ticker)=0))
	as select *
	from lnk (keep=gvkey lpermno lpermco linkdt linkenddt) as a left join 
	earnsup.iclink (keep=ticker permno score where=(score in (0,1,2))) as b
	on a.lpermno=b.permno;
quit;

proc sort data=lnk1; 
	by gvkey ticker linkdt;
run;

data fdate ldate; set lnk1;
	by gvkey ticker;
	if first.ticker then output fdate;
	if last.ticker then output ldate;
run;

data temp; 	merge 
		fdate (keep=gvkey ticker linkdt rename=(linkdt=fdate)) 
		ldate (keep=gvkey ticker linkenddt rename=(linkenddt=ldate));
	by gvkey ticker;
run;

/*Check for duplicates*/
data dups nodups; set temp;
	by gvkey ticker;
	if first.gvkey=0 or last.gvkey=0 then output dups;
	if not (first.gvkey=0 or last.gvkey=0) then output nodups;
run;

proc sort data=dups; 
	by gvkey fdate ldate ticker;
run;

data dups (where=(flag ne 1)); 
	set dups;
	by gvkey;
	if first.gvkey=0 and (fdate<=lag(ldate) or lag(ldate)=.E) then flag=1;
run;

/*CIBESLNK contains gvkey-ticker links over non-overlapping time periods*/
data earnsup.cibeslnk; 
	set nodups dups (drop=flag);
run;

proc sql; drop table nodups, dups, fdate, ldate, lnk1;quit;

