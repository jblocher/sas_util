
libname morning "H:\Research\MorningstarData";

PROC IMPORT OUT= morning.hf_master_data 
            DATAFILE= "H:\Research\MorningstarData\336_HF_Master.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
