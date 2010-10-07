** Note this is from the Accounting Group Macros.sas file, also included in its entirety;

/**********************************************************************************************/
/* CREATED BY:     Ryan Ball (UNC-Chapel Hill)                                               */
/* MODIFIED BY:     Scott Dyreng (UNC-Chapel Hill)                                               */
/* DATE CREATED:    November 29, 2005                                                         */
/* LAST MODIFIED:   November 29, 2005                                                         */
/* MACRO NAME:      Lags				                                                          */
/* ARGUMENTS:       1) DATA: input dataset containing variables that will be lagged         */
/*                  2) FIRMID: firm-specific identification variable                          */
/*                  3) TIMEID: date variable (e.g fyenddt, fqenddt)                           */
/*                  4) VARS: variable(s) that will be lagged..macro will automatically add a  */
/*                           '_lead#' or '_lag#' suffix to all lead/lag variables             */
/*                  5) LAG_TYPE: = 1 if monthly data is used                                  */
/*                               = 3 if quarterly data is used                                */
/*                               = 12 if yearly data is used (default)                        */
/*                  5) NUM_LAGS: number of lags taken...positive values represent lags of each*/
/*                               variable while negative value represent lead values          */
/*                  6) OUT: = output dataset with orinal plus lagged variables           */
/* DESCRIPTION:     This macro takes the input variables and computes lagged variables based  */
/*                  on other specifications (e.g. FIRMID, TIMEID, LAG_TYPE)                   */
/**********************************************************************************************/

%macro lags (data = _LAST_,
                      firmid = ,
                      timeid = ,
                      vars = ,
                      lag_type = 12, 
                      num_lags = 1,
                      out = );

/*set LAG_TYPE = 12 (default) if something other than 1 or 3 is specified*/
 	%if &out = %then %let out = &data;
    %if &lag_type ne 1 & &lag_type ne 3 & &lag_type ne 12 %then %let lag_type = "OOPS!";
    %if &num_lags < 0 %then %do;
        %let temp_suffix = %eval(-1 * &num_lags);
        %let prefix = lead&temp_suffix;
    %end;
    %else %if &num_lags >= 0 %then %do;
        %let prefix = lag&num_lags;
    %end;


/*create a macro variable with the names of the lagged variables*/
    %let lagged_names =;
    %let variable_index = 1;

    %do %until (%scan(&vars,&variable_index)= );
        %let token = %scan(&vars,&variable_index);
        %let lagged_names = &lagged_names &token._&prefix;
        %let variable_index = %eval(&variable_index + 1);
    %end;



/*sort data in ascending order*/
    proc sort data = &data;
        by &firmid &timeid;
    run;

 
/*create duplicate dataset but change the date to correspond to lagged dates*/
    data temp;
        set &data;
        array vars(*) &vars;
        array nvars(*) &lagged_names;
        &timeid = intnx('month', &timeid, 1 + &num_lags * &lag_type) - 1;
        do i = 1 to dim(nvars);
            nvars(i) = vars(i); /*method of renaming variables*/
        end; 
        keep &timeid &firmid &lagged_names;
    run;

    proc sql;
        create table &out
        as select a.*, b.*
        from &data as a left join temp as b
        on a.&firmid = b.&firmid & month(a.&timeid) = month(b.&timeid) &
            year(a.&timeid) = year(b.&timeid);
    quit;run;


    proc sort data = &out;
        by &firmid &timeid;
    quit;run;

	 proc datasets library=work nolist;
	    delete temp;
		 quit;
		 run;

%mend;


/**********************************************************************************************/
/* CREATED BY:    Scott Dyreng (UNC-Chapel Hill)                                               */
/* MODIFIED BY:     Scott Dyreng (UNC-Chapel Hill)                                               */
/* DATE CREATED:    December 16, 2005                                                         */
/* LAST MODIFIED:   December 16, 2005                                                         */
/* MACRO NAME:      LagsYA				                                                          */
/* ARGUMENTS:       1) DATA: input dataset containing variables that will be lagged         */
/*                  2) FIRMID: firm-specific identification variable                          */
/*                  4) VARS: variable(s) that will be lagged..macro will automatically add a  */
/*                           '_lead#' or '_lag#' suffix to all lead/lag variables             */
/*                  
/*                  5) NUM_LAGS: number of lags taken...positive values represent lags of each*/
/*                               variable while negative value represent lead values          */
/*                  6) OUT: = output dataset with orinal plus lagged variables           */
/* DESCRIPTION:     This macro is the same as the lags macro, except it only works
                     for compustat where the time identifier is yeara.                    */
/**********************************************************************************************/

%macro lagsYA (data = _LAST_,
                      firmid = ,
                      vars = ,
                      num_lags = 1,
                      out =,
                       yearid=yeara);

/*set LAG_TYPE = 12 (default) if something other than 1 or 3 is specified*/
 	%if &out = %then %let out = &data;
    %if &num_lags < 0 %then %do;
        %let temp_suffix = %eval(-1 * &num_lags);
        %let prefix = lead&temp_suffix;
    %end;
    %else %if &num_lags >= 0 %then %do;
        %let prefix = lag&num_lags;
    %end;


/*create a macro variable with the names of the lagged variables*/
    %let lagged_names =;
    %let variable_index = 1;

    %do %until (%scan(&vars,&variable_index)= );
        %let token = %scan(&vars,&variable_index);
        %let lagged_names = &lagged_names &token._&prefix;
        %let variable_index = %eval(&variable_index + 1);
    %end;



/*sort data in ascending order*/
    proc sort data = &data;
        by &firmid &yearid;
    run;

 
/*create duplicate dataset but change the date to correspond to lagged dates*/
    data temp;
        set &data;
        array vars(*) &vars;
        array nvars(*) &lagged_names;
        &yearid = &yearid + &num_lags;
        do i = 1 to dim(nvars);
            nvars(i) = vars(i); /*method of renaming variables*/
        end; 
        keep &yearid &firmid &lagged_names;
    run;

    proc sql;
        create table &out
        as select a.*, b.*
        from &data as a left join temp as b
        on a.&firmid = b.&firmid & a.&yearid = b.&yearid;
    quit;run;


    proc sort data = &out;
        by &firmid &yearid;
    quit;run;

	 proc datasets library=work nolist;
	    delete temp;
		 quit;
		 run;

%mend;