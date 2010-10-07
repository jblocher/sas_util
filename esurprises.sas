/******************************************************************************************************************/
/*                                                                                                                */
/* Program          : Esurprises.sas                                                                              */
/* Author           : Denys Glushkov, WRDS                                                                        */
/* Date Created     : Feb 2008                                                                                    */
/* Last Modified    : June 2009											  */
/* Location         : /wrds/ibes/samples                                                                          */
/*                                                                                                                */
/* Description:       Calculate quarterly standardized earnings surprises (SUE)                                   */
/*                                                                                                                */
/*                    This program is intended for calculation of quarterly standardized earnings surprises (SUE) */
/*                    based on time-series (seasonal random walk model) and analyst EPS forecasts. The short and  */
/*                    intermediate-term risk-adjusted returns associated with the earnings announcements are also */
/*                    calculated. The analysis is based on Livnat and Mendenhall (Journal of Accounting Research, */
/*                    Vol. 44, No.1, March 2006) "Comparing the Post-Earnings Announcement Drift for Surprises    */
/*                    Calculated from Analyst and Time Series Forecasts".                                         */
/*                                                                                                                */
/* Input              Tab-delimited TXT file containing a column of IBES (not official) tickers                   */
/*                    stored in your home WRDS directory                                                          */
/*                                                                                                                */
/* Output             The program stores 3 types of earnings surprises (SUE1, SUE2, SUE3) and                     */
/*                    associated cumulative abnormal returns (CAR1, CAR2) in SUECARS in your                      */
/*                    home WRDS directory.                                                                        */
/*                    SUE1: Earnings surprise is based on a rolling seasonal random walk model (LM, page 185)     */
/*                    SUE2: Earnings Surprise after exclusion of special items                                    */
/*                    SUE3: Earnings surprise is based on IBES reported analyst forecasts and actuals             */
/*                    CAR1: Cumulative abnormal return in (-1,1) window around earnings announcement dates        */
/*                    CAR2: Cumulative abnormal return over the period from two days after the announcement       */
/*                    through one day after the following quarterly earnings announcement (LM, page 187)          */
/*                                                                                                                */
/* Notes              To make proper comparisons between IBES and Compustat Data, the program uses the            */
/*                    unadjusted (for splits and stock dividends) IBES forecasts and actual earnings. This        */
/*                    avoids the potential rounding problem pointed out by Payne and Thomas                       */
/*                    ("The Implications of Using Stock-Split Adjusted IBES Data in Empirical Research",          */
/*                    Accounting Review 78, 2003). When matching IBES forecasts and Compustat actual earnings     */
/*                    figures, we use the earnings definition (primary or diluted EPS) as indicated by IBES       */
/*                    (for more details, see LM (2006))                                                           */
/*                                                                                                                */
/*                                                                                                                */
/* IMPORTANT          To be able to run the program, a user should have access to CRSP daily and monthly          */
/*                    stock, Compustat Annual and Quarterly sets, IBES and CRSP/Compustat Merged database         */
/*                                                                                                                */
/******************************************************************************************************************/

/****************************************
Remote Sign-on to WRDS Server
****************************************/

%let wrds = wrds.wharton.upenn.edu 4016;
options comamid=TCP;
signon wrds username=_prompt_;

/***********************************/
/* MAIN BODY OF THE PROGRAM        */
/***********************************/

RSUBMIT;

options errors=1 noovp;
options nocenter ps=max ls=78;
options mprint source nodate symbolgen macrogen;
options msglevel=i;

libname mine '~'; *define a home directory on WRDS;

%let begindate='01jan1980'd; * start calendar date of fiscal period end;
%let enddate='31mar2009'd; * end calendar date of fiscal period end;

*variables to extract from Compustat;
%let comp_list= gvkey fyearq fqtr conm datadate rdq epsfxq epspxq prccq ajexq spiq cshoq
cshprq cshfdq rdq saleq atq fyr consol indfmt datafmt popsrc datafqtr;

*variables to extract from IBES;
%let ibes_vars= ticker value fpedats anndats revdats measure fpi estimator analys pdf usfirm;

*IBES filters;
%let ibes_where1=where=(measure='EPS' and fpi in ('6','7') and &begindate<=fpedats<=&enddate);
%let ibes_where2=where=(missing(repdats)=0 and missing(anndats)=0 and 0<intck('day',anndats,repdats)<=90);

*timing and primary filters for Compustat Xpressfeed;
%let comp_where=where=(fyr>0 and (saleq>0 or atq>0) and consol='C' and popsrc='D' and
indfmt='INDL' and datafmt='STD' and missing(datafqtr)=0);

*filter from LM (2006):
- earnings announcement date is reported in Compustat
- the price per share is available from Compustat as of the end of the fiscal quarter and is greater than $1
- the market (book) value of equity at the fiscal quarter end is available and is larger than $5 mil;
%let LM_filter=(missing(rdq)=0 and prccq>1 and mcap>5.0);

*define a set of auxiliary macros;
%include '/wrds/ibes/samples/cibeslink.sas';
%include '/wrds/ibes/samples/ibes_sample.sas';
%include '/wrds/comp/samples/sue.sas';
%include '/wrds/comp/samples/size_bm.sas';
%include '/wrds/ibes/samples/iclink.sas'; *build CRSP-IBES permno-ticker link;


*CIBESLINK macro will create a linking table CIBESLNK between IBES ticker and Compustat GVKEY
*based on IBES ticker-CRSP permno (ICLINK) and CCM CRSP permno - Compustat GVKEY (CSTLINK2) link;
%CIBESLINK (begdt=&begindate, enddt=&enddate);

*Read in IBES tickers from the specified file stored in the user's home director on WRDS;
filename input '~/tickers.txt';
data tickers;
   infile input;
   informat ticker $6.;
   input @1 ticker;
run;

* Macro IBES_SAMPLE extracts the estimates from IBES Unadjusted file based on the user-provided
* input (SAS set tickers), links them to IBES actuals, puts estimates and actuals on the same basis
* by adjusting for stock splits using CRSP adjustment factor and calculates the median of analyst
* forecasts made in the 90 days prior to the earnings announcement date. Outputs file MEDEST into work
* directory;
%IBES_SAMPLE (infile=tickers, ibes1_where=&ibes_where1, ibes2_where=&ibes_where2, ibes_var=&ibes_vars);

*COMPUSTAT EXTRACT;
proc sql;
   create table gvkeys
   as select a.*
   from cibeslnk as a, tickers as b
   where a.ticker=b.ticker; *use CIBESLNK table to link IBES Ticker and GVKEY;

   create table comp (drop=consol indfmt datafmt popsrc)
   as select a.*, cshoq*prccq as mcap
   from comp.fundq (keep=&comp_list &comp_where) as a,
   gvkeys as b
   where a.gvkey=b.gvkey;

   create table comp
   as select *
   from comp a left join
   (select distinct gvkey,ibtic from comp.security
   (where=(missing(ibtic)=0))) b
   on a.gvkey=b.gvkey;
quit;

*Create calendar date of fiscal period end in Compustat extract;
data comp; set comp;
   if (1<=fyr<=5) then date_fyend=intnx('month',mdy(fyr,1,fyearq+1),0,'end');
   else if (6<=fyr<=12) then date_fyend=intnx('month',mdy(fyr,1,fyearq),0,'end');
   fqenddt=intnx('month',date_fyend,-3*(4-fqtr),'end');
   format fqenddt date9.;
   drop date_fyend;
run;

* a) Link Gvkey with Lpermno;
proc sql;
   create table comp1
   as select a.*, b.lpermno
   from comp (where=(&begindate<=fqenddt<=&enddate)) as a left join lnk as b
   on a.gvkey=b.gvkey and ((b.linkdt<=a.fqenddt <=b.linkenddt) or
   (b.linkdt<=a.fqenddt and b.linkenddt=.E) or
   (b.linkdt=.B and a.fqenddt <=b.linkenddt)) and b.usedflag=1;

* b) Link Gvkey with IBES Ticker;
create table comp1
   as select a.*, b.ticker
   from comp1 as a left join cibeslnk as b
   on a.gvkey=b.gvkey and ((b.fdate<=a.fqenddt <=b.ldate) or
   (b.fdate<=a.fqenddt and b.ldate=.E) or (b.fdate=.B and a.fqenddt <=b.ldate));

* c) Link IBES analysts' expectations (MEDEST), IBES report dates (repdats)
* and actuals (act) with Compustat data;
create table comp1
   as select a.*, b.medest, b.numest,b.repdats, b.act, b.basis
   from comp1 as a left join medest as b
   on a.ticker=b.ticker and
   year(a.fqenddt)*100+month(a.fqenddt)=year(b.fpedats)*100+month(b.fpedats);
quit;

*remove fully duplicate records and pre-sort;
proc sort data=comp1 noduprec; by _all_;run;
proc sort data=comp1; by gvkey fyearq fqtr;run;

* Macro SUE calculates standardized earnings surprises SUE1, SUE2, SUE3
* and outputs datasets comp_final&k into the work directory;
%MACRO Allsurprises;
   %do k=1 %to 3;
   %SUE (method=&k, input=comp1);
   %end;
%mend;
%Allsurprises;

* Merge all of the results together to get a dataset containing SUE1 , SUE2
* and SUE3 for all relevant (GVKEY-Report date) pairs;
data comp_final;
   merge comp_final1 comp_final2 (keep=gvkey fyearq fqtr sue2)
   comp_final3 (keep=gvkey fyearq fqtr sue3);
   by gvkey fyearq fqtr;
   label fqenddt='Calendar date of fiscal period end';
   keep ticker ibtic lpermno gvkey conm fyearq fqtr fyr fqenddt repdats rdq;
   keep sue1 sue2 sue3 basis actual expected deflator act medest numest prccq mcap;
run;

proc sort data=comp_final;
   *descending sort is intenational to define leads;
   by gvkey descending fyearq descending fqtr;
run;

* Shifting the announcement date to be a trading day;
* Defining the day after the following quarterly earnings announcement as leadrdq1;
data retdates; set comp_final;
   by gvkey;
   leadrdq=lag(rdq);
   if first.gvkey then leadrdq=intnx('month',rdq,3,'sameday');
   *if sunday move back by 2 days, if saturday move back by 1 day;
   if weekday(rdq)=1 then rdq1=intnx('day',rdq,-2); else
   if weekday(rdq)=7 then rdq1=intnx('day',rdq,-1); else rdq1=rdq;
   if weekday(leadrdq)=1 then leadrdq1=intnx('day',leadrdq,2); else
   if weekday(leadrdq)=7 then leadrdq1=intnx('day',leadrdq,3); else
   if weekday(leadrdq)=6 then leadrdq1=intnx('day',leadrdq,3);else
   leadrdq1=intnx('day',leadrdq,1);
   if leadrdq=rdq then delete;
   keep lpermno gvkey fyearq fqtr rdq1 leadrdq1 rdq;
   format rdq1 leadrdq1 date9.;
run;

* Apply LM filter
* Earnings report dates in Compustat and in IBES (if available)
* should not differ by more than one calendar day;
data comp_final;
   set comp_final;
   if &LM_filter and (((missing(sue1)=0 or missing(sue2)=0) and missing(repdats)=1)
   or (missing(repdats)=0 and abs(intck('day',repdats,rdq))<=1));
run;

* Extract file of raw daily returns around between earnings announcement dates;
proc sql;
   create table crsprets
   as select a.*, b.rdq1, b.leadrdq1, b.rdq
   from crsp.dsf (keep=permno ret date where=(&begindate<=date<=&enddate)) as a,
   retdates (where=(missing(rdq1)=0 and missing(leadrdq1)=0 and
   30<intck('day',rdq1,leadrdq1))) as b
   where a.permno=b.lpermno and intnx('day',rdq1,-5)<=a.date<=intnx('day',leadrdq1,5);
quit;

* Macro SIZE_BM assigns the stocks into six Size-BM portfolios based on the methodology
* outlined on Ken French webiste at
* http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/six_portfolios.html
* The size breakpoint for year t is the median NYSE market equity at the end of June of year t.
* BE/ME for June of year t is the book equity for the last fiscal year end in t-1 divided by ME
* for December of t-1. The BE/ME breakpoints are the 30th and 70th NYSE percentiles.
* Link dataset LINK is a linking table between GVKEY and NPERMNO with valid link dates
* After execution macro SIZE_BM creates dataset SIZE_BM_PORT containing size/BM stock assignments;
%SIZE_BM (bdate=&begindate, edate=&enddate, link=lnk);

* Performing characteristic risk-adjustment.
* Daily returns of six size-BM portfolios are in set portfolios_d;
proc sql;
   create table crsprets1
   as select a.*,b.size_port, b.bm_port,
   case when size_port='Small' and bm_port='Low' then ret-smlo_ewret
   when size_port='Small' and bm_port='Medium' then ret-smme_ewret
   when size_port='Small' and bm_port='High' then ret-smhi_ewret
   when size_port='Big' and bm_port='Low' then ret-bilo_ewret
   when size_port='Big' and bm_port='Medium' then ret-bime_ewret
   when size_port='Big' and bm_port='High' then ret-bihi_ewret
   else .A
   end as abret
   from crsprets as a, size_bm_port as b, ff.portfolios_d as c
   where a.permno=b.permno and b.size_date<=a.date<b.leaddate and a.date=c.date;
quit;

*remove fully duplicate records;
proc sort data=crsprets1 noduprec; by _all_;run;

*To estimate the drift, we compute CAR1 and CAR2;
proc sort data=crsprets1 out=temp1;
   where date lt rdq;
   by permno rdq descending date; *descending order is intentional;
run;

data temp1; set temp1;
   by permno rdq;
   if first.rdq then td_count=0;
   td_count=td_count-1; *increments in negative direction;
   retain td_count;
run;

proc sort data=crsprets1 out=temp2;
   where date ge rdq;
   by permno rdq date; *ascending order as default;
run;

data temp2; set temp2 ;
   by permno rdq;
   if first.rdq and date=rdq1 then td_count=0;
   td_count=td_count+1; *increments in positive direction;
   if date=rdq1 then td_count=0;
   retain td_count;
run;

data crsprets1; set temp1 temp2;run;
proc sort data=crsprets1; by permno rdq td_count;run;
proc sql; drop table temp1, temp2; quit;

* Calculate cumulative abornal returns:
* a) CAR1 (3-day window);
proc means data=crsprets1 noprint;
   *define the even window and check that the start date is not far from report date;
   where -1<=td_count<=1 and intck('day',rdq,date)<=5;
   by permno rdq;
   var abret;
   output out=CAR1 (rename=(_freq_=daysCAR1)) sum=CAR1;
run;

* b) CAR2 (between consequent quarterly earnings announcement dates);
proc means data=crsprets1 noprint;
   where 3<=td_count and date<=leadrdq1;
   by permno rdq;
   var abret;
   output out=CAR2 (rename=(_freq_=daysCAR2)) sum=CAR2;
run;

* Merge surprises with abnormal returns and place the final set into home directory;
* Use daysCAR1 and daysCAR2 to check for whether CAR1 and CAR2 are computed over
* potentially misleading time windows due to missing returns data in CRSP DSF file;
proc sql;
   create table suecars
   as select a.gvkey,a.lpermno label='CRSP PERMNO Identifier',
   a.ticker label='Historical IBES Ticker', a.ibtic, a.rdq, a.fqenddt, a.fyearq,
   a.fqtr, a.sue1 label='Earnings Surprise (Seasonal Random Walk)',
   a.sue2 label='Earnings Surprise (Excluding Special items)',
   a.sue3 label='Earnings Surprise (Analyst Forecast-based)',
   a.numest label='Number of analyst forecasts used in Analyst-based SUE',
   b.car1 label='Cumulative AR around EAD (-1,+1)',
   b.daysCAR1 label='Actual days used in CAR1 calculation',
   c.car2 label='Cumulative AR between Consequent EADs'
   from comp_final as a, car1 as b, car2 as c
   where a.lpermno=b.permno and a.rdq=b.rdq and a.lpermno=c.permno and a.rdq=c.rdq;
quit;

proc sort data=suecars out=mine.suecars; by gvkey fyearq fqtr;run;

/*house cleaning*/
proc sql;
   drop table crsprets, crsprets1, comp_final1, comp_final2, adjfactor, cibeslnk,
   comp_final3, car1, car2, comp, comp1, crsp1, crsp2, gvkeys,
   ibes2, link1_1, link1_2, link2_1, link2_2, link2_3, lnk, medest, msf2a, nomatch1,
   nomatch2, nomatch3, retdates, size_bm_port, temp, tickers;
quit;

ENDRSUBMIT;
