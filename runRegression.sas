/**********************************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                    
/* DATE CREATED:    November 24, 2008                                                         
/* LAST MODIFIED:   November 24, 2008                                                         
/* PROG NAME:       runRegression		                                                          
/* DESCRIPTION:     runs regression on merged CRSP and Compustat short interest and return data
/**********************************************************************************************/

proc datasets library=Shortint nolist;
contents data=mergedData;
run;

proc reg data = mergedData;
	model retx = monthEnd qtrEnd yearEnd shortint
run;
