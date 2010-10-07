/* *************************************************** */
/* ************** W R D S   M A C R O S ************** */
/* ***************  Merging CRSP Data  *************** */
/* *************************************************** */
/* *** Date: May, 2009                                 */  
/* ***   By: Rabih Moussawi, Luis Palacios, WRDS       */  
/* *** Objective: Merge CRSP Stock and Events data     */
/*******************************************************/

%macro crspmerge (s=,start=,end=,sfvars=,sevars=,filters=,final_ds=);
/* Check Series: Daily or Monthly and define datasets - Default is Monthly  */
%if &s=D %then %let s=d; %else %if &s ne d %then %let s=m;
%if (%sysfunc(libref(crsp))) %then %do; 
	libname crsp "/wrds/crsp/sasdata/s&s.";  
%end;
%let sf       = crsp.&s.sf ;
%let se       = crsp.&s.seall ;
%let senames  = crsp.&s.senames ;

%put ; %put ; %put ; %put ; %put ; 
%put #### ## # Merging CRSP Stock File (&s.sf) and Event File (&s.se) # ## #### ;

options nonotes;
%let sdate = %sysfunc(putn("&start"d,5.)) ; 
%let edate = %sysfunc(putn("&end"d,5.)) ; 

%if %length(&sevars) > 2 %then %let sevars = %sysfunc(compbl(&sevars)); 
  %else %let sevars = ticker ncusip exchcd shrcd;
%let sevars  = %sysfunc(lowcase(&sevars));
%let nsevars = %eval(%sysfunc(length(&sevars))-%sysfunc(length(%sysfunc(compress(&sevars))))+1);

%* create lag event variable names to be used in the RETAIN statement ;
%let sevars_l = lag_%sysfunc(tranwrd(&sevars,%str( ),%str( lag_))); 

%if %length(&filters) > 2 %then %let filters = and &filters; 
  %else %let filters = %str( );
%if &final_ds = %str() %then %let final_ds = work.crsp_&s.;

%put #### ### ## # ;
/* Get stock data */
proc sql;
	create table sfdata 
	as select *
	from &sf (keep= permco permno date &sfvars)
	where date between &sdate and &edate and permno in 
	(select distinct permno from 
      &senames(WHERE=(&edate>=NAMEDT and &sdate<=NAMEENDT) 
         keep=permno namedt nameendt) )
	order by permno, date;
	quit; 
%put #### ### ## # ;
/* Get event data */
proc sql;
   create table sedata
   as select a.*
   from &se (keep= permco permno date &sevars exchcd) as a,
    (select distinct permno, min(namedt) as minnamedt from 
      &senames(WHERE=(&edate>=NAMEDT and &sdate<=NAMEENDT) 
         keep=permno namedt nameendt) group by permno) as b
	where a.date >= b.minnamedt and a.date <= &edate and a.permno =b.permno 
   order by a.permno, a.date;
   quit;
%put #### ### ## # ;
/* Merge stock and event data */
%let eventvars = ticker comnam ncusip shrout siccd exchcd shrcls shrcd shrflg trtscd nmsind mmcnt nsdinx;
* variables whose values need to be retain to fill the blanks;

data &final_ds (keep=permco permno date &sfvars &sevars exchcd);
merge sedata (in=eventdata) sfdata (in=stockdata);
by permno date; retain &sevars_l;
%do i = 1 %to &nsevars;
  %let var   = %scan(&sevars,&i,%str( ));
  %let var_l = %scan(&sevars_l,&i,%str( ));
  %if %sysfunc(index(&eventvars,&var))>0 %then
   %do; 
     if eventdata or first.permno then &var_l = &var. ;
	 else if not eventdata then &var = &var_l. ;
   %end;
 %end;
if eventdata and not stockdata then delete;
drop  &sevars_l ;
run;
%put #### ### ## # ;
    /* ------------------------------------------------------------------------------ */
    /* The following sort is included to handle duplicate observations when a company */
    /* has more than one distribution on a given date. For example, a stock and cash  */
    /* distribution on the same date will generate two records, identical except for  */
    /* different DISTCD and DISTAMT (and possibly other) values. The NODUPLICATES     */
    /* option only deletes a record if all values for all variables are the same as   */
    /* those in another record. So, in the above example, if DISTCD is included in    */
    /* &sevars a record will not be deleted, but a redundant record will be deleted   */
    /* if DISTCD and DISTAMT are not included in &sevars.                             */
    /* ------------------------------------------------------------------------------ */
proc sort data=&final_ds noduplicates;
    /* the "exchcd" condition below removes rows with empty stock price data created  */
    /* because CRSP event file track some event information even before the stock     */
    /* is trading in major stock exchange                                             */
where 1 &filters;
    by date permno;
run;
%put #### ### ## # ;

proc sql; 
drop table sedata, sfdata; 
quit; 

options notes;
%put #### ## # Done: Dataset &final_ds Created! # ## ####;
%put ; 

%mend crspmerge;


/* ***************************************************************************************** */
/* ***************************** Unless otherwise noted, *********************************** */
/* All material is Copyright 1994-2009: The Wharton School of the University of Pennsylvania */
/* ****************************** All rights reserved ************************************** */