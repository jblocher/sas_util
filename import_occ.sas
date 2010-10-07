/*****************************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                   
/* DATE CREATED:    July 2009                                                         
/* LAST MODIFIED:                                                            
/* PROG NAME:       import_occ.sas                                                               
/* Project:         Limits of Diversification - Counterparty Risk and Complext Networks
/* This File:       Imports multiple files retrieved from Call Reports data - RCL
/*****************************************************************************************/

options mprint symbolgen linesize = 100 pagesize = max;

/* 
 * Data Sets needed for input: 
 * FFIEC CDR Call Schedule RCL MMDDYYY.txt	: Exported from FFIEC.
 *
 * Data Set Produced:
 *
 * Next step: 
 */ 
 
libname occraw '/smallfs/jabloche/occdata/';
libname occ '/largefs/jabloche/occ/';

%let date = 03312009;

filename indata pipe "ls -c1 /smallfs/jabloche/occdata/FFIEC CDR Call Schedule RCL &date..txt";

%let data_analyze = occ.raw_occ_data;
%let data_final = occ.RCL&date;

data &data_analyze;
	infile indata truncover;
	input f2r $60.;
	infile dummy filevar = f2r end=done delimiter = ',' FLOWOVER DSD lrecl=32767 firstobs=4 ;
	
	* Begin Informatting and Formatting;
	informat VAR1 $40. ;
	informat VAR2 $8. ;
	informat VAR3 $14. ;
	informat VAR4 $8. ;
	informat VAR5 COMMA6.2 ;
	informat VAR6 COMMA14.2 ;
	informat VAR7 COMMA14.2 ;
	informat VAR8 COMMA14.2 ;
	informat VAR9 $4. ;
	informat VAR10 $4. ;
	informat VAR11 MMDDYY10. ;
	informat VAR12 COMMA6.2 ;
	informat VAR13 $20. ;
	informat VAR14 $40. ;
	
	format VAR1 $40. ;
	format VAR2 $8. ;
	format VAR3 $14. ;
	format VAR4 $8. ;
	format VAR5 COMMA6.2 ;
	format VAR6 COMMA14.2 ;
	format VAR7 COMMA14.2 ;
	format VAR8 COMMA14.2 ;
	format VAR9 $4. ;
	format VAR10 $4. ;
	format VAR11 DATE8. ;
	format VAR12 COMMA6.2 ;
	format VAR13 $20. ;
	format VAR14 $40. ;
	 
	*Must loop here because by default will only get first line;
	do while(not done);
		input
           VAR1 $
           VAR2 $
           VAR3 $
           VAR4 $
           VAR5 
           VAR6
           VAR7
           VAR8
           VAR9 $
           VAR10 $
           VAR11 
           VAR12 
           VAR13 $
           VAR14 $;
           date = input(substr(f2r,38,8),mmddyy8.);
           rowID = input(substr(f2r,51,3),3.);
           output;
	end;
	
run;
*now, lets get proper names and labels;
data &data_final;
	set &data_analyze;
	* Now, define real variables;
	Name = VAR1;
	Ticker = VAR2;
	ISIN = VAR3;
	CUSIP = VAR4;
	Portfolio_pct = VAR5;
	Position_mkt_value = VAR6;
	Shares = VAR7;
	Share_Change = VAR8;
	Currency = VAR9;
	Country = VAR10;
	Maturity = VAR11;
	Coupon_pct = VAR12;
	Sector = VAR13;
	Detail_Holding_Type = VAR14;
	*Note_Eff_Date = VAR15 OMITTED ABOVE;
	
	format date DATE8.;
	
	drop VAR1-VAR14;
	
	label name = 'Security Name';
	label Ticker = 'Security Ticker';
	label Portfolio_pct = 'Portfolio % of whole';
	label Position_mkt_value = 'Market Value of Position';
	label Share_change = 'Change in Shares since last reported';
run;
%mend import_mstar;

* This creates all the smaller datasets;

%macro importit();
	%do b = 0 %to 2;
		%do a = 0 %to 9;
		%import_mstar(first = &b, second = &a);
		%end;
	%end;
	
	%do a = 0 %to 3;
	%import_mstar(first = 3, second = &a);
	%end;

%mend importit;

%macro appendit();
	* now, set the base dataset for appending;
	data morning.morningstar_hf_data;
		set morning.morningstar_hf_data00;
	run;

	* append the rest of that series;
	%do a = 1 %to 9;
	proc append base = morning.morningstar_hf_data data = morning.morningstar_hf_data0&a;
	run;
	%end;

	*append the rest;
	%do b = 1 %to 2;
		%do a = 0 %to 9;
		proc append base = morning.morningstar_hf_data data = morning.morningstar_hf_data&b.&a;
		run;
		%end;
	%end;
	
	%do a = 0 %to 3;
		proc append base = morning.morningstar_hf_data data = morning.morningstar_hf_data3&a;
		run;
	%end;
%mend appendit;

%importit;
%appendit;

proc contents data = morning.morningstar_hf_data;
run;

proc print data = morning.morningstar_hf_data (obs = 200);
run;



