/*****************************************************************************************/
/* CREATED BY:      Jesse Blocher (UNC-Chapel Hill)                                               
/* MODIFIED BY:                                                   
/* DATE CREATED:    Apr 2009                                                         
/* LAST MODIFIED:   May 2009                                                         
/* PROG NAME:       ma_import.sas                                                               
/* Project:         Supply and Demand for Shares
/* This File:       Import Large M&A dataset from SDC
/*****************************************************************************************/

options mprint symbolgen linesize = 100 pagesize = max;

libname ma 'H:\Research\Supply and Demand for Shares\sas\SDCtoSAS\';
filename AcqData 'H:\Research\Supply and Demand for Shares\sas\SDCtoSAS\MA_Acquirors_large_notitle.txt';
filename TarData 'H:\Research\Supply and Demand for Shares\sas\SDCtoSAS\MA_Targets_large_notitle.txt';


/* 
 * Data Sets needed for input: 
 * MA_Acquirors_large_notitle.txt		: Exported from SDC with session. Highly dependent on file structure.
 * MA_Targets_large_notitle.txt		: Exported from SDC with session. Highly dependent on file structure.
 *
 * Data Set Produced:
 * ma.raw_ma_acq_data
 * ma.raw_ma_tar_data
 *
 * Next step: merge with existing dataset to identify more changes in SHROUT
 */ 

*%let data_analyze = ma.raw_ma_acq_data;
%let data_analyze = ma.raw_ma_tar_data;

data &data_analyze;
	*infile AcqData;
	infile TarData;
	input 	master_deal_no COMMA11. +3
			date_effective MMDDYY8. +5
			date_eff_uncon MMDDYY8. +9
			pctacq COMMA6.2 +4
			pctown COMMA6.2 +4
			a_cusip $6. +6
			a_shrout COMMA8.2 +12
			a_ticker $6. +7
			a_dilute_shr COMMA8.2 +5
			shrs_acquired COMMA8.2 +6
			consid_struct $14. +2
			form_of_deal $17. +1
			t_cusip $6. +6
			t_shrout comma9.2 +5
			t_12mo_shrout comma12.2 +6
			t_dilute_shr comma9.2 +4
			t_ticker $6. +7
			equity_carveout $1. +11
			creep_acq $3. +11
			funds_common_stock $3. +9
			funds_rights_issue $1. +9
			recapitalization $3. +8
			spin_off $3. +5
			split_off $3. +7
			stake_purch $3. +7
			stock_swap $3. +6
			sweep_purch $3. +8;
  
			label master_deal_no = 'SDC Deal Number';
			label date_effective = 'Date Effective';
			format date_effective DATE8.;
			label date_eff_uncon = 'Date Unconditional';
			format date_eff_uncon DATE8.;
			label pctacq  = 'Percent of Shares Acquired in Transaction';
			label pctown = 'Percent of Shares Owned after Transaction';
			label a_cusip = 'Acquiror CUSIP';
			label a_shrout = 'Acquiror Actual SHROUT (Mil)';
			label a_ticker ='Acquiror Ticker';
			label a_dilute_shr ='Acquiror Diluted SHROUT (Mil)';
			label shrs_acquired ='Common Shares Acquired in Transaction (Mil)';
			label consid_struct = 'Consideration Structure';
			label form_of_deal = 'Form of the Deal';
			label t_cusip = 'Target CUSIP';
			label t_shrout = 'Target Actual SHROUT (Mil)';
			label t_12mo_shrout ='Target SHROUT last 12 Mo (Mil)';
			label t_dilute_shr ='Target Diluted SHROUT(Mil)';
			label t_ticker ='Target Ticker';
			label equity_carveout = 'Equity Carveout Flag';
			label creep_acq = 'Creeping Acquisition Flag';
			label funds_common_stock ='Source of Funds - Common Stock Flag';
			label funds_rights_issue ='Source of Funds - Rights Issue Flag';
			label recapitalization ='Recapitalization Flag';
			label spin_off ='Spin Off Flag';
			label split_off ='Split Off Flag';
			label stake_purch ='Stake Purchase Flag';
			label stock_swap = 'Stock Swap Flag';
			label sweep_purch = 'Sweeping Purchase Flag';
			/* drop these since they don't work */
			drop equity_carveout creep_acq funds_common_stock funds_rights_issue recapitalization spin_off
			split_off stake_purch stock_swap  sweep_purch;
run;

proc contents data = &data_analyze;
run;

Title "Frequency of Basic Categories";
proc freq data = &data_analyze;
tables consid_struct form_of_deal;
run;

Title "Frequency of Various Flags";
proc freq data = &data_analyze;
tables equity_carveout creep_acq funds_common_stock funds_rights_issue recapitalization spin_off
		split_off stake_purch stock_swap  sweep_purch;
run;

Title "Univariate of Level Vars - Acquiror";
ods select BasicMeasures ExtremeObs Quantiles; 
proc univariate data = &data_analyze;
var a_shrout a_dilute_shr;
run;

Title "Univariate of Level Vars - Deal";
ods select BasicMeasures ExtremeObs Quantiles; 
proc univariate data = &data_analyze;
var pctacq shrs_acquired ;
run;
Title "Univariate of Level Vars - Target";
ods select BasicMeasures ExtremeObs Quantiles; 
proc univariate data = &data_analyze;
var t_shrout t_12mo_shrout ;
run;





