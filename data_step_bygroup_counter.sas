proc sort data = dr_work.first_ts_merge out = sorted_merge noduprec;
by permno CumDt date;
run;
data dr_work.event_block_data;
	set sorted_merge;
	by permno CumDt date;
	if first.CumDt then counter = 1;
	else counter = counter + 1;
	retain counter;
run;
proc print data = dr_work.event_block_data (obs = 200);
var permno date counter;
run;

* Key is that CumDt is unique for the block. By starting with the first date, we're getting counters on date while the others are unchanged;