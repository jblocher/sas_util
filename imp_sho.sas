
filename F4 "/largefs/jabloche/NAS_regsho/tester/*.txt";
libname regsho '/largefs/jabloche/regsholib/';


data regsho.allpipefiles(drop=test);
	infile F4 length=ln firstobs=2 obs=max;
	input @;
	input wholeline $varying100. ln;
	test = substr( wholeline , 1 ,  15 );
	if test = 'MarketCenter|Sy' then delete;
run;

data regsho.lengths;
	set regsho.allpipefiles;

	wholelinespace	= tranwrd(wholeline,'|',' |');

	l1		= length( scan( wholelinespace , 1 , 	'|' ) );
	l2		= length( scan( wholelinespace , 2 , 	'|' ) );
	l3		= length( scan( wholelinespace , 3 , 	'|' ) );
	l4		= length( scan( wholelinespace , 4 , 	'|' ) );
	l5		= length( scan( wholelinespace , 5 , 	'|' ) );
	l6		= length( scan( wholelinespace , 6 , 	'|' ) );
	l7		= length( scan( wholelinespace , 7 , 	'|' ) );
	l8		= length( scan( wholelinespace , 8 , 	'|' ) );
	l9		= length( scan( wholelinespace , 9 , 	'|' ) );
	l10		= length( scan( wholelinespace , 10 , 	'|' ) );
	l11		= length( scan( wholelinespace , 11 , 	'|' ) );
	l12		= length( scan( wholelinespace , 12 , 	'|' ) );
	l13		= length( scan( wholelinespace , 13 , 	'|' ) );
	l14		= length( scan( wholelinespace , 14 , 	'|' ) );
	l15		= length( scan( wholelinespace , 15 , 	'|' ) );
run;

proc means data=regsho.lengths median mean max;
	var l1 l2 l3 l4 l5 l6 l7 l8 l9 l10 l11 l12 l13 l14 l15;
run;

data regsho.allpipefiles(drop=wholeline wholelinespace);
	set regsho.allpipefiles;

	wholelinespace	= tranwrd(wholeline,'|',' |');

	marketcenter	= input( scan( wholelinespace , 1 , '|' ), 	$1.	);
	symbol 		= input( scan( wholelinespace , 2 , '|' ), 	$5. 	);
	txtdate 	= input( scan( wholelinespace , 3 , '|' ), 	$8. 	);
	time 		= input( scan( wholelinespace , 4 , '|' ), 	$8.  	);
	shorttype 	= input( scan( wholelinespace , 5 , '|' ), 	$1. 	);
	size	 	= input( scan( wholelinespace , 6 , '|' ), 	7. 	);
	price		= input( scan( wholelinespace , 7 , '|' ), 	8. 	);
	linkindicator 	= input( scan( wholelinespace , 8 , '|' ), 	$1.	);
	shortsize 	= input( scan( wholelinespace , 9 , '|' ), 	7.	);

run;

data regsho.allpipefiles(keep=marketcenter symbol date time shorttype size price linkindicator shortsize);       
	set regsho.allpipefiles;

	year 	= int( txtdate / 10000 );
	month	= int( ( txtdate - year*10000 ) /100 );
	day	= int( txtdate - year*10000 - month*100 );
	date	= input( put( (year*10000 + month*100 + day), $8. ) , yymmdd8. );

	format date date9.;
run;

options obs=1000;
proc print;	

endsas;

