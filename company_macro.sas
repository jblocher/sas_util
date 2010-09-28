/* *************************************************************************/
/* CREATED BY:      Joey Engelberg (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    ??                                                                                                            
/* PROG NAME:       company_macro(rev).sas                                                              
/* Project:         
/* This File:       Matches two datasets of Company Names
/************************************************************************************/

****Company Name Matching Macro;


****The purpose of the following macro is to 'match' the company names from two different datasets
	The macro works as follows:
	1) Separates every company (from both datasets) into words
	2) Eliminates common company words like CO, LLP, CORP, etc.
	3) Joins together the remaining words after the common words have been filtered out 
	4) Compares each consecutive pair of letters from each company in dataset1 with each company in dataset2
		to determine a score.  The score represents the fraction of letter pairs that matched
	5) Organizes the results to show the best match for each company;
	

%MACRO mfmatch(dataset1=,var1=,dataset2=,var2=,out_ds=); 	/*** dataset 1 and 2 are the two SAS datasets with the companies you wish to match***/;
												  			/*** var 1 and 2 are the two variables within the datasets which have the name of the companies***/;
												  			/** out_ds is the dataset with the vars and matches **/
												
Data Dummy1;
	Set &dataset1 NOBS=nobs1;  /***setting first dataset and finding number of observations***/;
	CALL SYMPUT("OBS",nobs1);  /***keeping the number of observations as a macrovariable called OBS ***/;
	Attrib &var1 CompA length=$200.;
	Comp1=UPCASE(&var1);	/***making the company names all uppercase***/;


	Comp1=TRANWRD(Comp1,' INTL',' INTERNATIONAL');
	Comp1=TRANWRD(Comp1,' LTD',' LIMITED');
	Comp1=TRANWRD(Comp1,'CL A','');
	Comp1=TRANWRD(Comp1,'CL B','');
	Comp1=TRANWRD(Comp1,'CL C','');
	Comp1=TRANWRD(Comp1,'-ADR','');
	Comp1=TRANWRD(Comp1,'-LP','');
	Comp1=TRANWRD(Comp1,'-SP','');
	Comp1=TRANWRD(Comp1,' ADR','');
	Comp1=TRANWRD(Comp1,'-REDH','');
	Comp1=TRANWRD(Comp1,'-SPON','');
	Comp1=TRANWRD(Comp1,'-OLD','');
	Comp1=TRANWRD(Comp1,' (NEW)','');
	Comp1=TRANWRD(Comp1,'-REDH','');
	Comp1=TRANWRD(Comp1,'/NEW','');
	Comp1=TRANWRD(Comp1,' L P','');
	Comp1=TRANWRD(Comp1,'/PRED','');
	Comp1=TRANWRD(Comp1,'/OLD','');
	Comp1=TRANWRD(Comp1,'/AL','');
	Comp1=TRANWRD(Comp1,'/AK','');
	Comp1=TRANWRD(Comp1,'/AZ','');
	Comp1=TRANWRD(Comp1,'/AR','');
	Comp1=TRANWRD(Comp1,'/CA','');
	Comp1=TRANWRD(Comp1,'/CO','');
	Comp1=TRANWRD(Comp1,'/CT','');
	Comp1=TRANWRD(Comp1,'/DE','');
	Comp1=TRANWRD(Comp1,'/DC','');
	Comp1=TRANWRD(Comp1,'/FL','');
	Comp1=TRANWRD(Comp1,'/FLA','');
	Comp1=TRANWRD(Comp1,'/GA','');
	Comp1=TRANWRD(Comp1,'/HI','');
	Comp1=TRANWRD(Comp1,'/IA','');
	Comp1=TRANWRD(Comp1,'/ID','');
	Comp1=TRANWRD(Comp1,'/IL','');
	Comp1=TRANWRD(Comp1,'/IN','');
	Comp1=TRANWRD(Comp1,'/KS','');
	Comp1=TRANWRD(Comp1,'/KY','');
	Comp1=TRANWRD(Comp1,'/LA','');
	Comp1=TRANWRD(Comp1,'/MA','');
	Comp1=TRANWRD(Comp1,'/MD','');
	Comp1=TRANWRD(Comp1,'/ME','');
	Comp1=TRANWRD(Comp1,'/MI','');
	Comp1=TRANWRD(Comp1,'/MN','');
	Comp1=TRANWRD(Comp1,'/MO','');
	Comp1=TRANWRD(Comp1,'/MS','');
	Comp1=TRANWRD(Comp1,'/MT','');
	Comp1=TRANWRD(Comp1,'/NC','');
	Comp1=TRANWRD(Comp1,'/ND','');
	Comp1=TRANWRD(Comp1,'/NE','');
	Comp1=TRANWRD(Comp1,'/NH','');
	Comp1=TRANWRD(Comp1,'/NJ','');
	Comp1=TRANWRD(Comp1,'/NM','');
	Comp1=TRANWRD(Comp1,'/NV','');
	Comp1=TRANWRD(Comp1,'/NY','');
	Comp1=TRANWRD(Comp1,'/OH','');
	Comp1=TRANWRD(Comp1,'/OK','');
	Comp1=TRANWRD(Comp1,'/OR','');
	Comp1=TRANWRD(Comp1,'/PA','');
	Comp1=TRANWRD(Comp1,'/RI','');
	Comp1=TRANWRD(Comp1,'/SC','');
	Comp1=TRANWRD(Comp1,'/SD','');
	Comp1=TRANWRD(Comp1,'/TN','');
	Comp1=TRANWRD(Comp1,'/TX','');
	Comp1=TRANWRD(Comp1,'/UT','');
	Comp1=TRANWRD(Comp1,'/VA','');
	Comp1=TRANWRD(Comp1,'/VT','');
	Comp1=TRANWRD(Comp1,'/WA','');
	Comp1=TRANWRD(Comp1,'/WV','');
	Comp1=TRANWRD(Comp1,'/WI','');
	Comp1=TRANWRD(Comp1,'/WY','');




	text1=scan(Comp1,1,' ,');	/***separating the company names into words (14 is the maximum number of words)***/;
	text2=scan(Comp1,2,' ,');
	text3=scan(Comp1,3,' ,');
	text4=scan(Comp1,4,' ,');
	text5=scan(Comp1,5,' ,');
	text6=scan(Comp1,6,' ,');
	text7=scan(Comp1,7,' ,');
	text8=scan(Comp1,8,' ,');
	text9=scan(Comp1,9,' ,');
	text10=scan(Comp1,10,' ,');
	text11=scan(Comp1,11,' ,');
	text12=scan(Comp1,12,' ,');
	text13=scan(Comp1,13,' ,');
	text14=scan(Comp1,14,' ,');		/***separating the company names into words (14 is the maximum number of words)***/;

	array text (14) text1 text2 text3 text4 text5 text6 text7 
					text8 text9 text10 text11 text12 text13 text14;
	Do i=1 to 14;
	If text(i)='INC.' 			THEN 		text(i)='';  /***getting rid of common words that add no value to the comparisons***/;
	If text(i)='INC' 			THEN 		text(i)=''; 
	If text(i)='CO.' 			THEN 		text(i)='';
	If text(i)='CO' 			THEN 		text(i)='';
	If text(i)='INC.' 			THEN 		text(i)=''; 
	If text(i)='INC' 			THEN 		text(i)=''; 
	If text(i)='CORP' 			THEN 		text(i)='';
	If text(i)='CORP.' 			THEN 		text(i)='';
	If text(i)='LTD' 			THEN 		text(i)='';
	If text(i)='LTD.' 			THEN 		text(i)='';
	If text(i)='LP' 			THEN 		text(i)='';
	If text(i)='LP.' 			THEN 		text(i)='';
	If text(i)='LLC' 			THEN 		text(i)='';
	If text(i)='LLC.' 			THEN 		text(i)='';		/***getting rid of common words that add no value to the comparisons***/;
	End;

	
	CompA=compress(trim(text1)||trim(text2)||trim(text3)||trim(text4)|| 
				trim(text5)||trim(text6)||trim(text7)||trim(text8)
				||trim(text9) ||trim(text10)||trim(text11)||trim(text12)||
				trim(text13)||trim(text14),' ,-/'); 						/***joining the remaining words (after the commom ones have been dropped), compressing them and elminating commas, spaces and dashes***/;
	lenA=length(trim(CompA));	/***determining the length of each compressed company***/;
	FirstLetterA=substr(CompA,1,1);		/***determining the first letter of each company***/;
	recno=_n_;															/***assigning a number to each observation***/;
	Drop i Comp1 text1 text2 text3 text4 text5 text6 text7 text8
						text9 text10 text11 text12 text13 text14; 		/***dropping unncessary variables***/;



Data Dummy2;
	Set &dataset2;
	Attrib &var2 CompB length=$200.;
	Comp2=UPCASE(&var2);					/***making the company names all uppercase***/;

	Comp2=TRANWRD(Comp2,' INTL',' INTERNATIONAL');
	Comp2=TRANWRD(Comp2,' LTD',' LIMITED');
	Comp2=TRANWRD(Comp2,'CL A','');
	Comp2=TRANWRD(Comp2,'CL B','');
	Comp2=TRANWRD(Comp2,'CL C','');
	Comp2=TRANWRD(Comp2,'-ADR','');
	Comp2=TRANWRD(Comp2,'-LP','');
	Comp2=TRANWRD(Comp2,'-SP','');
	Comp2=TRANWRD(Comp2,' ADR','');
	Comp2=TRANWRD(Comp2,'-REDH','');
	Comp2=TRANWRD(Comp2,'-SPON','');
	Comp2=TRANWRD(Comp2,'-OLD','');
	Comp2=TRANWRD(Comp2,' (NEW)','');
	Comp2=TRANWRD(Comp2,'-REDH','');
	Comp2=TRANWRD(Comp2,'/NEW','');
	Comp2=TRANWRD(Comp2,' L P','');
	Comp2=TRANWRD(Comp2,'/PRED','');
	Comp2=TRANWRD(Comp2,'/OLD','');
	Comp2=TRANWRD(Comp2,'/AL','');
	Comp2=TRANWRD(Comp2,'/AK','');
	Comp2=TRANWRD(Comp2,'/AZ','');
	Comp2=TRANWRD(Comp2,'/AR','');
	Comp2=TRANWRD(Comp2,'/CA','');
	Comp2=TRANWRD(Comp2,'/CO','');
	Comp2=TRANWRD(Comp2,'/CT','');
	Comp2=TRANWRD(Comp2,'/DE','');
	Comp2=TRANWRD(Comp2,'/DC','');
	Comp2=TRANWRD(Comp2,'/FL','');
	Comp2=TRANWRD(Comp2,'/FLA','');
	Comp2=TRANWRD(Comp2,'/GA','');
	Comp2=TRANWRD(Comp2,'/HI','');
	Comp2=TRANWRD(Comp2,'/IA','');
	Comp2=TRANWRD(Comp2,'/ID','');
	Comp2=TRANWRD(Comp2,'/IL','');
	Comp2=TRANWRD(Comp2,'/IN','');
	Comp2=TRANWRD(Comp2,'/KS','');
	Comp2=TRANWRD(Comp2,'/KY','');
	Comp2=TRANWRD(Comp2,'/LA','');
	Comp2=TRANWRD(Comp2,'/MA','');
	Comp2=TRANWRD(Comp2,'/MD','');
	Comp2=TRANWRD(Comp2,'/ME','');
	Comp2=TRANWRD(Comp2,'/MI','');
	Comp2=TRANWRD(Comp2,'/MN','');
	Comp2=TRANWRD(Comp2,'/MO','');
	Comp2=TRANWRD(Comp2,'/MS','');
	Comp2=TRANWRD(Comp2,'/MT','');
	Comp2=TRANWRD(Comp2,'/NC','');
	Comp2=TRANWRD(Comp2,'/ND','');
	Comp2=TRANWRD(Comp2,'/NE','');
	Comp2=TRANWRD(Comp2,'/NH','');
	Comp2=TRANWRD(Comp2,'/NJ','');
	Comp2=TRANWRD(Comp2,'/NM','');
	Comp2=TRANWRD(Comp2,'/NV','');
	Comp2=TRANWRD(Comp2,'/NY','');
	Comp2=TRANWRD(Comp2,'/OH','');
	Comp2=TRANWRD(Comp2,'/OK','');
	Comp2=TRANWRD(Comp2,'/OR','');
	Comp2=TRANWRD(Comp2,'/PA','');
	Comp2=TRANWRD(Comp2,'/RI','');
	Comp2=TRANWRD(Comp2,'/SC','');
	Comp2=TRANWRD(Comp2,'/SD','');
	Comp2=TRANWRD(Comp2,'/TN','');
	Comp2=TRANWRD(Comp2,'/TX','');
	Comp2=TRANWRD(Comp2,'/UT','');
	Comp2=TRANWRD(Comp2,'/VA','');
	Comp2=TRANWRD(Comp2,'/VT','');
	Comp2=TRANWRD(Comp2,'/WA','');
	Comp2=TRANWRD(Comp2,'/WV','');
	Comp2=TRANWRD(Comp2,'/WI','');
	Comp2=TRANWRD(Comp2,'/WY','');











	text1=scan(Comp2,1,' ,');		/***separating the company names into words (14 is the maximum number of words)***/;
	text2=scan(Comp2,2,' ,');
	text3=scan(Comp2,3,' ,');
	text4=scan(Comp2,4,' ,');
	text5=scan(Comp2,5,' ,');
	text6=scan(Comp2,6,' ,');
	text7=scan(Comp2,7,' ,');
	text8=scan(Comp2,8,' ,');
	text9=scan(Comp2,9,' ,');
	text10=scan(Comp2,10,' ,');
	text11=scan(Comp2,11,' ,');
	text12=scan(Comp2,12,' ,');
	text13=scan(Comp2,13,' ,');
	text14=scan(Comp2,14,' ,');			/***separating the company names into words (14 is the maximum number of words)***/;

	array text (14) text1 text2 text3 text4 text5 text6 text7 text8
					text9 text10 text11 text12 text13 text14;
	Do i=1 to 14;
	If text(i)='INC.' 			THEN 		text(i)=''; 	/***getting rid of common words that add no value to the comparisons***/;
	If text(i)='INC' 			THEN 		text(i)=''; 
	If text(i)='CO.' 			THEN 		text(i)='';
	If text(i)='CO' 			THEN 		text(i)='';
	If text(i)='INC.' 			THEN 		text(i)=''; 
	If text(i)='INC' 			THEN 		text(i)=''; 
	If text(i)='CORP' 			THEN 		text(i)='';
	If text(i)='CORP.' 			THEN 		text(i)='';
	If text(i)='LTD' 			THEN 		text(i)='';
	If text(i)='LTD.' 			THEN 		text(i)='';
	If text(i)='LP' 			THEN 		text(i)='';
	If text(i)='LP.' 			THEN 		text(i)='';
	If text(i)='LLC' 			THEN 		text(i)='';
	If text(i)='LLC.' 			THEN 		text(i)='';		/***getting rid of common words that add no value to the comparisons***/;
	End;

	
	CompB=compress(trim(text1)||trim(text2)||trim(text3)||trim(text4)||
trim(text5) ||trim(text6)||trim(text7)||trim(text8) ||trim(text9) ||
trim(text10) ||trim(text11)||trim(text12)||trim(text13)||trim(text14),' ,-'); 	/***joining the remaining words (after the commom ones have been dropped), compressing them and elminating commas, spaces and dashes***/;
	lenB=length(trim(CompB));		/***determining the length of each compressed company***/;
	FirstLetterB=substr(CompB,1,1);  /***determining the first letter of each company***/;
	Drop i Comp2 text1 text2 text3 text4 text5 text6 text7 text8 
						text9 text10 text11 text12 text13 text14; 		/***dropping unncessary variables***/;	


Data &out_ds;			/***creating any empty dataset called cumulative will eventually accumulate the final results of the matching procedure***/;	
	Set Dummy1;
	If CompA='';		


%DO b=1 %TO &OBS;		/***this is the macro do statement which loops through each observation***/;


Data Dummy3;			
	Set Dummy1;
	If recno=&b;		/***this subsetting statment takes the b observation only (recall from above that b is the variable that runs through each observation of dataset1)***/;	

DATA compare1;
        SET Dummy3;		
        DO k=1 TO nobs2;
            SET Dummy2 NOBS=nobs2 POINT=k;  /***this command requests each observation one at a time from dataset2***/;
			If trim(FirstLetterA)=trim(FirstLetterB) Then do;  /***runs the analysis only for companies who begin with the same first letter***/;
			Score1=0;
			Score2=0;
			
						Do m=1 to lenA;  /***repeats the analysis for each pair of letters (every compressed word has lenA-1 pairs)***/;
						If m<=lenA-1 Then do;
						pair=substr(CompA,m,2);	/***determining letter pair***/;
						If index(CompB,trim(pair))^=0 then score1=score1+1;	/***increasing score if letter pair matches within selected company in dataset2***/;				
						end;            
        				end;

/***repeats the analysis except now pairs from the selected company in dataset2 are compared with the selected company in dataset2***/;

						Do n=1 to lenB;
						If n<=lenB-1 Then do;
						pair=substr(CompB,n,2);
						If index(CompA,trim(pair))^=0 then score2=score2+1;						
						end;            
        				end;
						
						MatchPercent1=score1/(lenA-1); 		/***calculates a percent of pairs (from the selected company in dataset1) that matched***/;
						MatchPercent2=score2/(lenB-1);		/***calculates a percent of pairs (from the selected company in dataset2) that matched***/;
						TotalScore=MatchPercent1*MatchPercent2;		/***calculates a total score by multiplying the two percents together; clearly a total score of 1 is a perfect match.  A score of .7 and higher is a good match.***/;
			
						
		If TotalScore>.3 THEN OUTPUT;		/***outputs only those matches that have a TotalScore greater than .3 - typically matches less than .3 are bad matches***/;
		end;
    END;
Stop;
DROP pair m n;							/***drop unneeded variables***/;

PROC Sort Data=compare1 Out=compare1;			
By &var1 &var2;

Data compare3;
set compare1;
By &var1 &var2;

PROC SORT Data=Compare3 Out=Compare3;
By &var1 TotalScore;

Data compare4;
Set compare3;
By &var1;
If Last.&var1=1;				/***taking only best match***/;

Data &out_ds;
	Set &out_ds Compare4;	/***accumulates the best matches in the cumulative dataset***/;
	drop recno score1 score2 lenA lenB MatchPercent1 MatchPercent2;

%End;

%MEND mfmatch;






