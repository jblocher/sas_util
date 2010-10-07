/* ****************************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    June 2010                                                         
/* LAST MODIFIED:                           
/* PROG NAME:       ccm_lnk                                                               
/* Project:         Utility
/* Proj Descr:      create work.lnk which is used by size_bm() macro for FF factors
/*****************************************************************************************/

%macro ccm_lnk(begdt =, enddt = );

proc sort data=crsp.ccmxpf_linktable out=lnk;
	where linktype in ("LU", "LC" /*,"LD", "LF", "LN", "LO", "LS", "LX"*/)  and 
	usedflag=1 and
	(year(&enddt)+1>=year(linkdt) or linkdt=.B) and
	(year(&begdt)-1<=year(linkenddt) or linkenddt=.E);
	by gvkey linkdt;
run;

%mend;