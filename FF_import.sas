libname lala 'H:\Research\sas_util\';

PROC IMPORT OUT= lala.ff10 
     DATAFILE= "H:\Research\sas_util\FFindustry10.csv" 
     DBMS=CSV REPLACE;
     DELIMITER=',';
     GETNAMES=YES;
     DATAROW=2; 
RUN;
