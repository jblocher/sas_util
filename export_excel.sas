libname div '\\kenan-flagler\fsdata\b\blocherj\Research\03 Supply and Demand for Shares\Dividends\investment\';

proc export data = div.hprprc_hist_wide
	outfile = '\\kenan-flagler\fsdata\b\blocherj\Research\03 Supply and Demand for Shares\Dividends\hprprc_hist_wide.csv'
	dbms = csv replace;
run;
proc export data = div.hprprc_hist_narrow
	outfile = '\\kenan-flagler\fsdata\b\blocherj\Research\03 Supply and Demand for Shares\Dividends\hprprc_hist_narrow.csv'
	dbms = csv replace;
run;

