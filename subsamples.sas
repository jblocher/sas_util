/* *********************************************************************************************/
/* CREATED BY:      Jesse Blcoher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                 
/* DATE CREATED:    October 2009                                                         
/* LAST MODIFIED:                                                            
/* MACRO NAME:      Lags				                                                          
/* ARGUMENTS:       1) ds: input dataset containing variables that will be printed         
/*                  2) byvar: variable which creates strata for sampling 
/*								(equal number from each group)
/*                  3) varlist: variables to print
/* DESCRIPTION:     This macro samples a dataset and prints 100 observations
/* *********************************************************************************************/
%macro print_sample100(ds = ,byvar = ,varlist = );
	proc sort data = &ds out = temp1;
	by &byvar;
	run;
	proc surveyselect data = temp1
		method = srs
		n = 25
		out = temp2;
		strata &byvar;
	title "Print Random Sample of Data by &byvar";
	run;
	proc print data =  temp2;
	var &varlist;
	run;
%mend print_sample100;