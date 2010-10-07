*** First, run with White Std Errors ;
* this is pretty standards - just clusters the standard errors;
ODS Trace On;
ODS CSV file="/home/unc/jblocher/SupplyandDemand/csv/ami_w_cts_nomiss.csv";
	PROC SurveyReg Data=supdem.&ds._nomiss;
		cluster permno;
		model &lhs =  &model1;
	QUIT;
	RUN;
ODS Trace Off; 
ODS CSV Close; 


*** Now, Simple  Stock Fixed Effects;
ODS Trace On;
ODS CSV file="/home/unc/jblocher/SupplyandDemand/csv/ami_w_cts_nomiss.csv";
	PROC SurveyReg Data=supdem.&ds._nomiss;
		cluster permno;
		model &lhs =  permno &model1;
	QUIT;
	RUN;
ODS Trace Off; 
ODS CSV Close; 


*** Now, run with Stock Fixed Effects - use ABSROB if there are a lot of them;

ODS Trace On;
ODS CSV file="/home/unc/jblocher/SupplyandDemand/csv/fe_ami_w_cts_nomiss.csv";
	PROC GLM Data=supdem.&ds._nomiss;
		absorb permno;
		model &lhs = &model1 permno /solution;
	QUIT;
	RUN;
ODS Trace Off; 
ODS CSV Close; 

ODS LISTING Close;
