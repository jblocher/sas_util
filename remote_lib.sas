%let wrds = wrds.wharton.upenn.edu 4016;
options comamid=TCP remote=wrds;
signon username=_prompt_;

rsubmit;
libname supdem '/sastemp12/supplydemand/';
endrsubmit;

libname rsupdem slibref=supdem server=wrds;


