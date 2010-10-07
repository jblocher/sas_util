
libname occ '\\kenan-flagler\fsdata\b\blocherj\Research\OCC Data\';

%let date = 12312008;


%macro import_occ(date = );
PROC IMPORT OUT= occ.RCL&date 
            DATAFILE= "\\kenan-flagler\fsdata\b\blocherj\Research\OCC Data\Data\FFIEC CDR Call Schedule RCL &date..txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=3; 
	 GUESSINGROWS = 3500;
RUN;
PROC IMPORT OUT= occ.POR&date 
            DATAFILE= "\\kenan-flagler\fsdata\b\blocherj\Research\OCC Data\Data\FFIEC CDR Call Bulk POR &date..txt" 
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
%mend import_occ;

%macro mass_import();
	%do y = 2001 %to 2008;
		%import_occ(date = 0331&y);
		%import_occ(date = 0630&y);
		%import_occ(date = 0930&y);
		%import_occ(date = 1231&y);
	%end;
%mend mass_import;

*%mass_import;
*%import_occ(date = 03312009);
proc contents data = occ.RCL03312009;
run;

%macro merge_occ(date = );
data tempPOR&date;
	set occ.Por&date(keep = IDRSSD FDIC_Certificate_Number OCC_Charter_Number OTS_Docket_Number Financial_Institution_Name);
	dateChar = put(&date,z8.);
	date = input(dateChar,MMDDYY8.);
	format date MMDDYY10.;
	drop dateChar;
run;
data tempRCL&date;
	set occ.Rcl&date(keep = IDRSSD RCFDC968 RCFDC969 RCFDC970 RCFDC971 RCFDC972 RCFDC973 RCFDC974 RCFDC975
	RCONC968 RCONC969 RCONC970 RCONC971 RCONC972 RCONC973 RCONC974 RCONC975);
run;

proc sql;
	create table occ.alldata&date as
	select a.*, coalesce(b.RCFDC968,b.RCONC968) as RCONC968 label = 'Notional CDS Sold',
				coalesce(b.RCFDC969,b.RCONC969) as RCONC969 label = 'Notional CDS Purch',
				coalesce(b.RCFDC970,b.RCONC970) as RCONC970 label = 'Notional Tot Ret Swap Sold',
				coalesce(b.RCFDC971,b.RCONC971) as RCONC971 label = 'Notional Tot Ret Swap Purch',
				coalesce(b.RCFDC972,b.RCONC972) as RCONC972 label = 'Notional Cr Options Sold',
				coalesce(b.RCFDC973,b.RCONC973) as RCONC973 label = 'Notional Cr Options Purch',
				coalesce(b.RCFDC974,b.RCONC974) as RCONC974 label = 'Notional Other Cr Der Sold',
				coalesce(b.RCFDC975,b.RCONC975) as RCONC975 label = 'Notional Other Cr Der Purch'
	from tempPOR&date as a
	inner join
	tempRCL&date as b
	on a.IDRSSD = b.IDRSSD;
quit;
%mend merge_occ;

%macro mass_merge(); *note, this only works starting Jan 2006 due to change in file;
	%do y = 2006 %to 2008;
		%merge_occ(date = 0331&y);
		%merge_occ(date = 0630&y);
		%merge_occ(date = 0930&y);
		%merge_occ(date = 1231&y);
	%end;
%mend mass_merge;

*%mass_merge;
*%merge_occ(date = 03312009);


/* Now, we do the same thing, but for the older data */

%macro merge_occ_old(date = );
data tempPOR&date;
	set occ.Por&date(keep = IDRSSD FDIC_Certificate_Number OCC_Charter_Number OTS_Docket_Number Financial_Institution_Name);
	dateChar = put(&date,z8.);
	date = input(dateChar,MMDDYY8.);
	format date MMDDYY10.;
	drop dateChar;
run;
data tempRCL&date;
	set occ.Rcl&date(keep = IDRSSD RCONA534 RCONA535  );
run;

proc sql;
	create table occ.alldata&date as
	select a.*, coalesce(b.RCFDA534,b.RCONA534) as RCONA534 label = 'Notional CDS Sold',
				coalesce(b.RCFDA535,b.RCONA535) as RCONA535 label = 'Notional CDS Purch'
	from tempPOR&date as a
	inner join
	tempRCL&date as b
	on a.IDRSSD = b.IDRSSD;
quit;
%mend merge_occ_old;

%macro mass_merge_old(); *note, this only works starting Jan 2006 due to change in file;
	%do y = 2001 %to 2005;
		%merge_occ_old(date = 0331&y);
		%merge_occ_old(date = 0630&y);
		%merge_occ_old(date = 0930&y);
		%merge_occ_old(date = 1231&y);
	%end;
%mend mass_merge_old;

%mass_merge_old;
