
** Create YRMO variable (called yearmon) with put statement;
create view _Temp
  as select a.*, b.permno, put(anndats, yymmn.) as yearmon
  from Ibes.Det (keep=&ibes_vars) a, _Sample b
  where a.ticker=b.ticker and not missing(fpedats) and not missing(anndats_act)
  and &ibes_filter and fpi='1' and a.anndats_act>a.revdats  and analys ne 0
  order by ticker, fpedats, analys, yearmon, anndats, revdats;
quit;

/*
Converting character or numeric variables to SAS date variables

This can be done using the INPUT function. The following code extracts date of birth from PNR and writes it out as a SAS date variable (click here for a complete example):
*/
birth=input(substr(pnr,2,6),yymmdd.);

/*
If the values of year, month, and day are stored in separate variables, these can be written to a single SAS date variable using the MDY function:
*/
sasdate=mdy(month, day, year);