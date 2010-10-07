** Note this is from the Accounting Group Macros.sas file, also included in its entirety;

/***************************************************
Descriptive Statistics by groups
 You can group by more than one variable,just separate by spaces
 ex: %descr_by(dset=mydata, byvar=year industry, vars=assets earnings, stats=n mean median);
***************************************************/

%macro descr_by(dset=,byvar=,vars=,stats=n mean min p1 q1 median q3 p99 max);

%let j=1;
%do %until ( %scan(&vars,&j)= );
  %let var&j = %scan(&vars,&j);
  %let j=%EVAL(&j+1);
%end;

proc sort data=&dset out=xtemp;
    by &byvar;
    run;

ods listing close;
proc means data=xtemp &stats;
    by &byvar;
    var &vars;
    ods output Summary = xout;
    run;
ods listing;

%do k = 1 %to %EVAL(&j-1);

  %let base = &&var&k;

  proc print data=xout noobs;
      var &byvar &base._:;
      format &base._: 10.4;
      format &base._N comma10.0;
      run;

%end;
%mend descr_by;