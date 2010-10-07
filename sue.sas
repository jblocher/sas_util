/***********************************************************************************************/
/* Program      : SUE.sas                                                                      */
/* Author       : Denys Glushkov, WRDS                                                         */
/* Date Created : Feb 2008                                                                     */	
/* Last Modified: Jun 2009								       */
/*                                                                                             */
/* Description: 3 Methods of calculating standardized earnings surprises                       */
/*                                                                                             */
/* Macro SUE calculates standardized earnings surprises using 3 (three) methods considered     */
/* by LM (2006). Method 1 assumes a rolling seasonal random walk model. Method 2 excludes      */
/* "special items" from the Compustat Data. In these two methods, if most analyst forecasts of */
/* EPS are based on diluted (primary) EPS, Macro uses Compustat's diluted (basic) figures      */
/* Method 3 is based solely on IBES median estimates/actuals and does not use Compustat data   */
/***********************************************************************************************/

%MACRO SUE (method=, input=);
/* Process Compustat Data on a seasonal year-quarter basis*/
%local i;
%do i=1 %to 4;
proc sort data=&input (where=(fqtr=&i)) out=qtr;
	by gvkey fyearq fqtr;
run;

data qtr; set qtr;
	by gvkey fyearq;
	%if &method=1 %then 
	 %do;
	 	lageps_p=lag(epspxq);lageps_d=lag(epsfxq);lagadj=lag(ajexq);
		if first.gvkey then do; lageps_p=.;lageps_d=.;lagadj=.;end;
		select (basis);
	 	when ('P') do; actual=epspxq/ajexq; expected=lageps_p/lagadj;end;
		when ('D') do; actual=epsfxq/ajexq; expected=lageps_d/lagadj;end;
		otherwise do; actual=epspxq/ajexq; expected=lageps_p/lagadj;end;
		end;
		drop lageps_p lageps_d lagadj;
		deflator=prccq/ajexq;
	%end;%else;
	%if &method=2 %then 
	 %do;
	 	lageps_p=lag(epspxq);lagshr_p=lag(cshprq);lagadj=lag(ajexq);
		lageps_d=lag(epsfxq);lagshr_d=lag(cshfdq);lagspiq=lag(spiq);
		if first.gvkey then do; lageps_p=.;lageps_d=.;lagshr_p=.;
								lagshr_d=.;lagadj=.;lagspiq=.;end;
		select (basis);
   		when ('P') do; actual=sum(epspxq,-0.65*spiq/cshprq)/ajexq; expected=sum(lageps_p,-0.65*lagspiq/lagshr_p)/lagadj;end;
		when ('D') do; actual=sum(epsfxq,-0.65*spiq/cshfdq)/ajexq; expected=sum(lageps_d,-0.65*lagspiq/lagshr_d)/lagadj;end;
		otherwise do; actual=sum(epspxq,-0.65*spiq/cshprq)/ajexq; expected=sum(lageps_p,-0.65*lagspiq/lagshr_p)/lagadj;end;
		end;
		drop lageps_p lagshr_p lagadj lageps_d lagshr_d lagspiq;
		deflator=prccq/ajexq;
		%end;%else;
	%if &method=3 %then 
	 %do;
		actual=act;
		expected=medest;
		deflator=prccq;
	 %end;
	sue&method=(actual-expected)/deflator;
	format sue&method percent7.4;
run;

proc append base=comp_final&method data=qtr;run;
proc sql; drop table qtr;quit;
%end;

proc sort data=comp_final&method; by gvkey fyearq fqtr;run;
%MEND;
