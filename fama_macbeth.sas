** Note this is from the Accounting Group Macros.sas file, also included in its entirety;

/**********************************************************************************************/
/* CREATED BY:    Scott Dyreng (UNC-Chapel Hill)                                               */
/* MODIFIED BY:     Scott Dyreng (UNC-Chapel Hill)                                               */
/* DATE CREATED:    December 16, 2005                                                         */
/* LAST MODIFIED:   December 16, 2005                                                         */
/* MACRO NAME:      FMB				                                                          */
/* ARGUMENTS:       1)       */
/* DESCRIPTION:     This macro computes Fama McBeth Regression Estimates;                   */
/**********************************************************************************************/


%macro FMB(data=_last_, byvars=, depvar=, indvars=, testvar1=0, testvar2=0, testname=diff);
proc sort data=&data;
   by &byvars;
	run;
proc reg noprint data=&data outest=FMBtemp1;
   by &byvars;
	model &depvar = &indvars / adjrsq;
	run;
	quit;
data FMBtemp1;
   set FMBtemp1;
	&testname = &testvar1 - &testvar2;
	run;
data FMBtemp2;
   set &data;
	array vars1(*) &depvar;
	array vars2(*) &indvars;
	do i=1 to dim(vars1);
	if missing(vars1(i))=1 then delete;
	end;
	do j=1 to dim(vars2);
	if missing(vars2(j))=1 then delete;
	end;
	run;
proc means data=FMBtemp1 n mean median stderr t probt;
   title "Fama McBeth Estimates";
   var  intercept &indvars &testname;
	run;
proc sort data=FMBtemp2;
   by &byvars;
	run;
proc means data=FMBtemp2 noprint;
   by &byvars;
	var &depvar;
	output out=FMBtemp2(drop=_type_ _freq_) n=nobs;
	run;
proc print data=FMBtemp2;
   title "Number of Observations per Cross Section";
   run;  
proc print data=FMBtemp1;
   title "Cross Sectional Coefficient Estimates by &byvars";
	var &byvars intercept &indvars &testname _RSQ_ _ADJRSQ_ _EDF_;
	run;
proc datasets lib=work nolist;
   delete FMBtemp1 FMBtemp2;
	run;
	quit;
%mend FMB;
