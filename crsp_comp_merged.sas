/*****************************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    Oct 2009                                                      
/* LAST MODIFIED:                                                           
/* PROG NAME:       crsp_comp_merged
/* Project:         Utility
/* Proj Descr:      Example code to merge CRSP and Compustat
/*****************************************************************************************/


** I had to add this to get the WRDS code to work;

proc sort data =  crsp.ccmxpf_lnkused out = temp1;
by ugvkey uiid upermno upermco ulinkdt ulinkenddt;
run;
proc sort data = crsp.ccmxpf_lnkhist out = temp2;
by gvkey liid lpermno lpermco linkdt linkenddt;
run;

** Copied from WRDS CCM Link help files; 

  data CCMXPF_LINKTABLE (label="CRSP/COMPUSTAT Merged - Link History w/ Used Flag");
    merge temp1 (in=u keep=ugvkey uiid upermno upermco ulinkdt ulinkenddt usedflag rename=(ugvkey=gvkey uiid=liid upermno=lpermno upermco=lpermco ulinkdt=linkdt ulinkenddt=linkenddt))
          temp2 (in=h);
    by gvkey liid lpermno lpermco linkdt linkenddt;
    if h=1 and u=0 and missing (usedflag) then usedflag=0;
  run;

  proc sort data=CCMXPF_LINKTABLE noduprec;
   by gvkey lpermno lpermco linkdt linkenddt;
  run;
** End WRDS code;

data cclink;
	set CCMXPF_LINKTABLE (keep = LINKDT LINKENDDT LPERMNO GVKEY);
	if missing(LINKENDDT) then endyr = 2009;
	else endyr = year(LINKENDDT);
	startyr = year(LINKDT);
run;

proc sql;
	create table compustat_db_with_permno as
	select a.*, cclink.LPERMNO
	from your_compustat_db as a, cclink as b
	where a.gvkey = b.gvkey
		and ( 
			  ( missing(b.linkenddt) and b.startyr <= a.year )
		      or 
		      ( b.startyr <= a.year <= b.endyr  )
			);
quit;
