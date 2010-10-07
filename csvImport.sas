PROC IMPORT OUT= WORK.ff 
            DATAFILE= "\\kenan-flagler\fsdata\b\blocherj\Research\FFindu
stry.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
