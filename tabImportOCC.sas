libname occ "H:\Research\OCC Data\";


PROC IMPORT OUT= occ.tester 
            DATAFILE= 'H:\Research\OCC Data\2009-03-31\FFIEC CDR Call Schedule RCL 03312009.txt';
            DBMS=TAB REPLACE;
     GETNAMES=YES;
     DATAROW=3; 
RUN;
