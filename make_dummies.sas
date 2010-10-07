** Note this is from the Accounting Group Macros.sas file, also included in its entirety;

/******************************************
Make dummy variables
 pre = prefix for dummy variable names
 ex: %make_dummies(dset=mydata, var=year, pre=dy_);
     %make_dummies(dset=mydata, var=industry, pre=di_);
*****************************************/

%macro make_dummies(dset=,var=,pre=d_);

proc sql noprint;
    select n(&var) into :n from (select distinct &var from &dset);
    %let n = %trim(&n);
    select xvar into :xvar1 - :xvar&n from (select distinct &var as xvar from &dset);
    quit;

data &dset;
    set &dset;
    %do i = 1 %to &n;
        if &var = "&&xvar&i" then &pre&&xvar&i = 1; else &pre&&xvar&i = 0;
    %end;
    run;

%mend make_dummies;