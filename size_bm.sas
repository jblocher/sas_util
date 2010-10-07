/*************************************************************************************************/
/*  Program      : SIZE_BM.sas                                                                   */
/*  Author       : Denys Glushkov, WRDS                                                          */
/*  Date Created : Feb 2008                                                                      */
/*  Last Modified: Jun 2009									 */	
/*                                                                                               */
/*  Description: Assign stocks into 6 Size-BM portfolios                                         */
/*                                                                                               */
/* Macro assigns the stocks into six Size-BM portfolios based on the methodology outlined on Ken */
/* French webiste at                                                                             */
/* http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/Data_Library/six_portfolios.html       */
/* The size breakpoint for year t is the median NYSE market equity at the end of June of year t. */
/* BE/ME for June of year t is the book equity for the last fiscal year end in t-1 divided by ME */
/* for December of t-1. The BE/ME breakpoints are the 30th and 70th NYSE percentiles.            */
/*************************************************************************************************/	

%MACRO SIZE_BM (bdate=, edate=, link=);
	 %local msfars;
	 %local msevars;
	 %local sharecode;
	 %local exchangecode;
	 %local begdate;
	 %local enddate;
     %let msfvars = prc ret shrout;
      * Selected variables from the CRSP monthly data 
         file (crsp.msf file);

     %let msevars = exchcd shrcd dlret; 
      * Selected variables from the CRSP monthly event 
         file (crsp.mse);

     %let sharecode = and shrcd in (10,11); 
      * Restriction on the type of shares (e.g. common stocks);

      %let exchangecode = ; 
       * In this case, no restrictions on the exchange codes; 
		
	  %let begdate=intck('year',&bdate,-1); 
	  %let enddate=&edate;

** 1.2. Call and Run the msf2a.sas program **; 
	
%include '/wrds/crsp/samples/msf2a.sas';

data msex2;
   set mylib.msf2a;
   by permno date;
   * Create size variable;
   size=abs(prc)*shrout; * Absolute Value of Price since, by convention, 
   CRSP assigns a negative value when the Bid-Ask average is used;
   * Lag Size for weights;
   size_lag=lag(size);
   ldate = lag(date);
   if first.permno then size_lag = size / (1+ret); 
   * Option for Delisting Returns;
   ret = sum(ret,dlret);
   * Comment previous line not to adjust for delisting events;
    if size>0;
   drop prc shrout ldate;
run;

*******************************************
1. Assign Stocks to NYSE Size-Based groups 
*******************************************;

proc sort data=msex2 (keep=date size exchcd) out=msex3;
   where month(date)=6 and exchcd=1;
   by date;
run;

proc means data=msex3 noprint;
   var size;
   by date;
   output out=nyse (drop=_freq_ _type_) median=/autoname;
run;

proc sql;
   create table size_assign
   as select a.permno, a.date, a.size,
	case when size<=size_median then 'Small' else 'Big'
		end as size_port
   from msex2 (keep=permno date size where = (month(date)=6)) as a
   left join nyse as b
   on a.date= b.date;
quit;

*************************************
2. Create Book Equity(BE) measure 
from Compustat (definition from Daniel and Titman (JF, 2006)
************************************;
data comp_extract;
   set comp.funda 
   (where=(fyr>0 and at>0 and consol='C' and 
           indfmt='INDL' and datafmt='STD' and popsrc='D'));
   if missing(SEQ)=0 then she=SEQ;else
   if missing(CEQ)=0 and missing(PSTK)=0 then she=CEQ+PSTK;else
   if missing(AT)=0 and missing(LT)=0 and missing(MIB)=0 then she=AT-(LT+MIB);else she=.;
   if missing(PSTKRV)=0 then BE0=she-PSTKRV;else if missing(PSTKL)=0 then BE0=she-PSTKL;
   else if missing(PSTK)=0 then BE0=she-PSTK; else BE0=.;
   * Converts fiscal year into calendar year data;
 	if (1<=fyr<=5) then date_fyend=intnx('month',mdy(fyr,1,fyear+1),0,'end');
	else if (6<=fyr<=12) then date_fyend=intnx('month',mdy(fyr,1,fyear),0,'end');
  	calyear=year(date_fyend);
  	format date_fyend date9.;
	* Accounting data since calendar year 't-1';
   if (year(date_fyend) >= year(&bdate) - 1) and (year(date_fyend) <=year(&edate) + 1);
   keep gvkey calyear fyr BE0 date_fyend indfmt consol datafmt popsrc datadate TXDITC;
run;

proc sql; create table comp_extract
as select a.gvkey, a.calyear, a.fyr, a.date_fyend, 
		  case when missing(TXDITC)=0 and missing(PRBA)=0 then BE0+TXDITC-PRBA else BE0
		  end as BE
	from comp_extract as a left join 
		 comp.aco_pnfnda (keep=gvkey indfmt consol datafmt popsrc datadate prba) as b
on a.gvkey=b.gvkey and a.indfmt=b.indfmt and a.consol=b.consol and a.datafmt=b.datafmt 
   and a.popsrc=b.popsrc and a.datadate=b.datadate;
quit;

*************************************
3. Create Book to Market (BM) ratios 
at December 
************************************;
proc sql;
   create table BM0	(where=(BM>0))
   as select a.gvkey, a.calyear, c.permno, c.exchcd, c.date, a.be/(abs(c.prc)*c.shrout/1000) as BM
   from comp_extract as a, 
		&link as b,		
		mylib.msf2a (where=( month(date)=12)) as c
	where a.gvkey=b.gvkey and 
		  ((b.linkdt<=c.date<=b.linkenddt) or (b.linkdt<=c.date and b.linkenddt=.E) 
		  or (c.date<=b.linkenddt and b.linkdt=.B)) and b.lpermno=c.permno
   and a.calyear = year(c.date) and (abs(c.prc)*c.shrout)>0;
quit;

*************************************
4. Keep only those cases with valid 
stock market in June 
************************************;
proc sql;
   create table BM
   as select a.gvkey, a.permno, a.bm, a.calyear, a.date as decdate, 
			 a.exchcd, b.date, b.size, b.size_port
   from BM0 as a, size_assign as b
   where a.permno=b.permno
   and intck('month',a.date,b.date)=6 and b.size>0;
quit;

***************************************************
5. Assign stocks to NYSE BM-based groups 
***************************************************;
proc sort data=BM out=nyse1 (keep=permno bm calyear decdate);
   where exchcd=1;
   by decdate;
run;

proc univariate data=nyse1 noprint;
   var bm;
   by decdate;
   output out=nyse2 pctlpts = 30 70 pctlpre=per;
run;

*Merge back with master file that contains all securities 
from NYSE, Nasdaq and AMEX;
proc sql;
   create table bm1
   as select a.permno, a.gvkey, a.bm, a.size, a.size_port, a.date, a.decdate,
   case when bm<=per30 then 'Low'
   		when per30<bm<=per70 then 'Medium'
		else 'High' 
		end as bm_port
   from BM as a, nyse2 as b
   where a.decdate=b.decdate;
   * The 'date' variable refers to June, the 'decdate' variable refers to December of the previous year;
quit;

proc sort data=bm1; by permno descending date;run;

data size_bm_port; set bm1;
by permno;
leaddate=lag(date);
if first.permno then leaddate=intnx('month',date,-12,'end');
format date leaddate decdate date9.;
rename date=size_date decdate=bm_date;
label date='Valid date for firm size';
label decdate='Valid date for Book-to-Market';
run;

proc sort data=size_bm_port; by permno size_date;run;

proc sql; drop table nyse1, nyse2, nyse, size_assign, 
			msex2, msex3, msedata, bm, bm0, bm1, comp_extract;
quit;
%MEND;
