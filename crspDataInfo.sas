/****************************************
Remote Sign-on to WRDS Server 
****************************************/


%let wrds = wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=wrds;
signon username=_prompt_;
rsubmit;

title 'Test Data Connections';
options source; * don't know what this is;


*proc contents data=crsp.dse; *Daily Stock - Events;
*proc contents data=crsp.dseall; *not sure - seems to be similar to Events;
proc contents data=crsp.dsfhdr; *Daily Stock - Securities (main price/return info);
*proc contents data=work.ff; *Daily Index for VWRETD - value weighted return with Dividends
*proc contents data=comp.names; *Compustat NA ??;
*proc contents data=comp.secm; *Compustat NA Security Monthly;

run;

/*
rsubmit;
data temp;
	set crsp.dsi (keep = vwretd date);
	where DATE > '31dec2007'd;
run;
*/
