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
** %MACRO CIBESLINK (begdt=,enddt=);
%include 'earnsup_header.sas'; *header file with basic options and libraries;
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
* %MEND;
