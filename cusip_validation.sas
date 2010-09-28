/* *************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)
/* MODIFIED BY:
/* DATE CREATED:    Aug 2010
/* PROG NAME:       cusip_validation.sas
/* Project:         Utility
/* This File:       Validates a cusip. returns 1 if valid, 0 if not.
/************************************************************************************/

** This macro takes in a SAS dataset with a set of cusips and adds a new variable with validation output;
** ds is dataset;
** cusip is field with CUSIP in it;
** valid is newly created field with valid result;

%macro iterateDigit(cusip= );
	%do i=1 %to 8;
		length c&i $ 1;
		c&i = substr(&cusip, &i, 1);
		
		if prxmatch('/\d/',c&i ) then do;
			v&i = c&i * 1;	
		end;
		else if prxmatch('/[A-Z]/',c&i ) then do;
			ind = index('ABCDEFGHIJKLMNOPQRSTUVWXYZ', c&i );
			v&i = ind + 9;
		end;
		else if prxmatch('/\*/',c&i ) then do;
			v&i = 36;
		end;
		else if prxmatch('/\@/',c&i ) then do;
			v&i = 37;
		end;
		else if prxmatch('/\#/',c&i ) then do;
			v&i = 38;
		end;
		
		if mod(&i ,2) = 0 then v&i = v&i * 2;
		vsum&i = floor(v&i /10) + mod(v&i , 10);

	%end;
%mend;



%macro validateCusips( ds_in=, cusip=,ds_out=, valid= );

data &ds_out (drop = CUSIP9 ninthDigit c1-c8 v1-v8 vsum1-vsum8 ind sumDigits checksum);
	set &ds_in;
	
	if ~missing(&cusip) then do;
		CUSIP9 = upcase(&cusip);
		length ninthDigit $ 1;
		ninthDigit = substr(&cusip , 9,1);
		*check ninth digit;
		if prxmatch('/[A-Z]/',ninthDigit ) or missing(ninthDigit) then do;
			&valid = 0;
		end;
		else do;
			%iterateDigit(cusip=CUSIP9);
				
			sumDigits = sum(of vsum1-vsum8);
			checksum = mod(  (10 - mod(sumDigits,10) )  , 10);
		
			if checksum = ninthDigit then &valid = 1;
			else &valid = 0;
		end;
	end;
	else do;
		&valid = .;
	end;
	
run;

%mend;



** Test routine;
/*
%include 'marketnet_header.sas'; *header file with basic options and libraries;

data test_cusip;
	set mkn_work.temp_test_cusip;
	if _N_ = 1 then do;
	new_cusip = '12#4@6*89';
	end;
	else new_cusip = cusip;
run;
*options spool;
%validateCusips(ds_in=test_cusip, cusip=new_cusip ,ds_out=mkn_work.test, valid=vCusip );

proc print data = mkn_work.test;
*var cusip new_cusip cusip9 v1-v8 vsum1-vsum8 ninthDigit checksum vCusip;
var new_cusip vCusip;
run;
proc contents data = mkn_work.test; run;
*/