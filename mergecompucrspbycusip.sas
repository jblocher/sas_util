*************************************************************************************************************
Program : mergecompucrspbycusip.sas 
Date Created : July 2008 
Location : '/wrds/crsp/samples/' 
      
Description : This Program merges CRSP and Compusat Xpressfeed databases by CUSIP. 
To be able to run the program, a user should have access to Compustat Annual Xpressfeed datasets
and CRSP monthly database 
 
************************************************************************************************************/

/****************************************
Remote Sign-on to WRDS Server 
****************************************;


%let wrds = wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=wrds;
signon username=_prompt_;
rsubmit;

title 'Merge Compustat and CRSP by cusip';
options source;

* Define data libraries;
libname comp1 '/wrds/comp/sasdata/na';
libname crsp '/wrds/crsp/sasdata/sm';

/************************************************************************************
* STEP ONE: Create Linking Table with 8-digit CUSIP; 
************************************************************************************/

* Create 8-digit CUSIP using "NAMES" file;
data compcusip (keep = gvkey cusip cusip8 tic);
set comp1.names;
where tic in ("DELL" "IBM" "MSFT" "F" "DIS");
cusip8 = substr (cusip,1,8);
run;

proc print data=compcusip noobs label;
var gvkey tic cusip cusip8;
run;

*Extract CRSP Cusip from "MSFNAMES" file;
proc sort data=crsp.msfnames (keep=cusip permco permno)out=crspcusip nodupkey;
by cusip;run;


* Merge Compusat cusip with CRSP cusip and create table "total";
proc sql;
create table total as select
compcusip.*,  crspcusip.*
from compcusip, crspcusip
where compcusip.cusip8 = crspcusip.cusip;
quit;
run;  

proc print noobs data = total;
var gvkey tic cusip8 permno;
run;

/************************************************************************************
* STEP TWO: Extract Compusat  data;
************************************************************************************/

* Selected GVKEYS-- use quotes to be consistent with character variables;
%let glist = '006066' '012141'  '014489';   

* Date range-- applied to FYEAR (Fiscal Year); 
%let fyear1= 1997;  
%let fyear2= 2006;

*  Selected data items (GVKEY, DATADATE, FYEAR and FYR are automatialy included);
%let vars=  gvkey fyr fyear datadate SALE AT INDFMT DATAFMT POPSRC CONSOL;

* Make extract from Compustat Annual Funda file;
data compx2;
   set comp1.funda (keep= &vars);
   where gvkey in (&glist) and fyear between &fyear1 and &fyear2;
   if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C';
   drop indfmt datafmt popsrc consol;  * Only used for the screening; 
   * create begin and end dates for fiscal year;
   endfyr= datadate; format endfyr date9.;
   begfyr= intnx('month',endfyr,-11,'beg'); format begfyr date9.; 
   *intnx(interval, from, n, 'aligment');
   sxa= sale/at;  * compute sales over assets ratio;
   keep gvkey begfyr endfyr sxa fyr fyear;* keep only relevant variables;
run;

proc sort; by gvkey endfyr; run;

proc print data=&syslast(obs=100); 
  by gvkey;
  id fyear;
  var fyear begfyr endfyr sxa;
run;

/****************************************************************************************
* STEP TWO: Link GVKEYS to CRSP Identifiers;
* Use CCMLINK2 table to obtain CRSP identifiers for our subset of companies/dates;
*****************************************************************************************/

*Merge Compusat set with Linking table;
proc sql;
create table mydata
as select *
from compx2 as a, total as b
where a.gvkey = b.gvkey;
quit;

proc print data=mydata (obs=30);
var gvkey permno permco endfyr sxa;
run;

/***************************************************************************************
* STEP THREE: Add CRSP Monthly price data;
***************************************************************************************/

* Option 1: Simple match at the end of the fiscal year;
proc sql;
create table mydata2
as select *
from mydata as a, crsp.msf as b
where a.permno = b.permno and
	month(a.endfyr) = month(b.date) and 
	year(a.endfyr) = year(b.date);
quit;

proc print data=mydata2 (obs=30);
var gvkey permno endfyr date sxa ret;
run;


/************************************************************************************
* Option 2: Alternative way of matching CRSP data;
* Match accounting data with fiscal yearends in month 't', 
  with CRSP return data from month 't+3' to month 't+14' (12 months); 
*************************************************************************************/
/*proc sql;
	create table mydata3 as select *
from mydata as a, crsp.msf as b
where a.permno = b.permno and 
	intck('month',a.endfyr,b.date)between 3 and 14;
quit;

proc print data=mydata3 (obs=30);
var gvkey permno endfyr date btm ret;
run;

