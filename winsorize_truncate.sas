** Note this is from the Accounting Group Macros.sas file, also included in its entirety;

**********************************************************************************************/
/* ORIGINAL AUTHOR:	Steve Stubben (Stanford University)                     				  */
/* MODIFIED BY:		Ryan Ball (UNC-Chapel Hill), Scott Dyreng (UNC-Chapel Hill)												  */
/* DATE CREATED:  	August 3, 2005	                                        				  */
/* LAST MODIFIED:	December 7, 2005															  */
/* MACRO NAME:  	WT		                                				  */
/* ARGUMENTS:  1) data: input dataset containing variables that will be win/trunc.	  */
/*					2) out: output dataset (leave blank to overwrite data)			  */
/*					3) BYVAR: variable(s) used to form groups (leave blank for total sample)  */
/*					4) VARS: variable(s) that will be winsorized/truncated					  */
/*					5) TYPE: = W to winsorize and = T (or anything else) to truncate		  */
/*					6) PCTL = percentile points (in ascending order) to truncate/winsorize	  */
/*						      values.  Default is 1st and 99th percentiles.					  */
/* DESCRIPTION:		This macro is capable of both truncating and winsorizing one or multiple  */
/*					variables.  Truncated values are replaced with a missing observation	  */
/*					rather than deleting the observation.  This gives the user more control   */
/*					over the resulting dataset.												  */
/* EXAMPLE(S):		1) %WT(data = mydata, out = mydata2, byvar = year,  */
/*					        vars = assets earnings, type = W, pctl = 0 98)					  */
/*						==> Winsorizes by year at 98% and puts resulting dataset into mydata2 */
/**********************************************************************************************/;

%macro WT(data=_last_, out=, byvar=none, vars=, type = W, pctl = 1 99, drop= N);

	%if &out = %then %let out = &data;
    
	%let varLow=;
	%let varHigh=;
	%let xn=1;

	%do %until (%scan(&vars,&xn)= );
    	%let token = %scan(&vars,&xn);
    	%let varLow = &varLow &token.Low;
    	%let varHigh = &varHigh &token.High;
    	%let xn = %EVAL(&xn + 1);
	%end;

	%let xn = %eval(&xn-1);

	data xtemp;
   	 	set &data;

	%let dropvar = ;
	%if &byvar = none %then %do;
		data xtemp;
        	set xtemp;
        	xbyvar = 1;

    	%let byvar = xbyvar;
    	%let dropvar = xbyvar;
	%end;

	proc sort data = xtemp;
   		by &byvar;

	/*compute percentage cutoff values*/
	proc univariate data = xtemp noprint;
    	by &byvar;
    	var &vars;
    	output out = xtemp_pctl PCTLPTS = &pctl PCTLPRE = &vars PCTLNAME = Low High;

	data &out;
    	merge xtemp xtemp_pctl; /*merge percentage cutoff values into main dataset*/
    	by &byvar;
    	array trimvars{&xn} &vars;
    	array trimvarl{&xn} &varLow;
    	array trimvarh{&xn} &varHigh;

    	do xi = 1 to dim(trimvars);
			/*winsorize variables*/
        	%if &type = W %then %do;
            	if trimvars{xi} ne . then do;
              		if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = trimvarl{xi};
              		if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = trimvarh{xi};
            	end;
        	%end;
			/*truncate variables*/
        	%else %do;
            	if trimvars{xi} ne . then do;
              		if (trimvars{xi} < trimvarl{xi}) then trimvars{xi} = .T;
              		if (trimvars{xi} > trimvarh{xi}) then trimvars{xi} = .T;
            	end;
        	%end;

			%if &drop = Y %then %do;
			   if trimvars{xi} = .T then delete;
			%end;

		end;
    	drop &varLow &varHigh &dropvar xi;

	/*delete temporary datasets created during macro execution*/
	proc datasets library=work nolist;
		delete xtemp xtemp_pctl; quit; run;

%mend;


**********************************************************************************************/
/* ORIGINAL AUTHOR:	Steve Stubben (Stanford University)                     				  */
/* MODIFIED BY:		Ryan Ball (UNC-Chapel Hill), Scott Dyreng (UNC-Chapel Hill)												  */
/* DATE CREATED:  	August 3, 2005	                                        				  */
/* LAST MODIFIED:	December 7, 2005															  */
/* MACRO NAME:  	WTSTD		                                				  */
/* ARGUMENTS:  1) data: input dataset containing variables that will be win/trunc.	  */
/*					2) out: output dataset (leave blank to overwrite data)			  */
/*					3) BYVAR: variable(s) used to form groups (leave blank for total sample)  */
/*					4) VARS: variable(s) that will be winsorized/truncated					  */
/*					5) TYPE: = W to winsorize and = T (or anything else) to truncate		  */
/*					6) deviations = number of standard deviations away from the mean to winsorize/truncate*/
/* DESCRIPTION:		This macro is capable of both truncating and winsorizing one or multiple  */
/*					variables.  Truncated values are replaced with a missing observation	  */
/*					rather than deleting the observation.  This gives the user more control   */
/*					over the resulting dataset.												  */
/* EXAMPLE(S):		1) %WT(data = mydata, out = mydata2, byvar = year,  */
/*					        vars = assets earnings, type = W, pctl = 0 98)					  */
/*						==> Winsorizes by year at 98% and puts resulting dataset into mydata2 */
/**********************************************************************************************/;

%macro WTSTD(data=_last_, out=, byvar=none, vars=, type = W, deviations = 3, drop= N);

	%if &out = %then %let out = &data;
    
	%let var_stddev=;
	%let var_mean=;
	%let xn=1;

	%do %until (%scan(&vars,&xn)= );
    	%let token = %scan(&vars,&xn);
    	%let var_stddev = &var_stddev &token._stddev;
		%let var_mean = &var_mean &token._mean;
    	%let xn = %EVAL(&xn + 1);
	%end;

	%let xn = %eval(&xn-1);

	data xtemp;
   	 	set &data;

	%let dropvar = ;
	%if &byvar = none %then %do;
		data xtemp;
        	set xtemp;
        	xbyvar = 1;

    	%let byvar = xbyvar;
    	%let dropvar = xbyvar;
	%end;

	proc sort data = xtemp;
   		by &byvar;

	/*compute percentage cutoff values*/
	proc means data = xtemp noprint;
    	by &byvar;
    	var &vars;
    	output out = xtemp_pctl(drop=_type_ _freq_) std= mean=/autoname;
		run;


	data &out;
    	merge xtemp xtemp_pctl; /*merge percentage cutoff values into main dataset*/
    	by &byvar;
    	array trimvars{&xn} &vars;
    	array trimvar_std{&xn} &var_stddev;
	  	array trimvar_mean{&xn} &var_mean;

    	do xi = 1 to dim(trimvars);
			/*winsorize variables*/
        	%if &type = W %then %do;
            	if trimvars{xi} ne . then do;
              		if (trimvars{xi} < trimvar_mean{xi}-(trimvar_std{xi}*&deviations)) 
                       then trimvars{xi} = trimvar_mean{xi}-(trimvar_std{xi}*&deviations));
              		if (trimvars{xi} > trimvar_mean{xi}+(trimvar_std{xi}*&deviations)) 
                       then trimvars{xi} = trimvar_mean{xi}+(trimvar_std{xi}*&deviations));
            	end;
        	%end;
			/*truncate variables*/
        	%else %do;
            	if trimvars{xi} ne . then do;
              		if (trimvars{xi} < trimvar_mean{xi}-(trimvar_std{xi}*&deviations)) 
                       then trimvars{xi} = .T;
              		if (trimvars{xi} > trimvar_mean{xi}+(trimvar_std{xi}*&deviations)) 
                       then trimvars{xi} = .T;
            	end;
        	%end;

			%if &drop = Y %then %do;
			   if trimvars{xi} = .T then delete;
			%end;

		end;
    	drop &var_stddev &var_mean &dropvar xi;

	/*delete temporary datasets created during macro execution*/
	proc datasets library=work nolist;
		delete xtemp xtemp_pctl; quit; run;

%mend;

