From Matt:

proc univariate data=trades noprint;
	by firmid cusip date;
	where sizecat ne 'sm';
	var special rate;
	weight specweight;
	output out=medlg(keep=firmid cusip date mdlgvwspec mdlgvwrate sdmdlgvwspec_weight) mean=mdlgvwspec mdlgvwrate std=sdmdlgvwspec_weight t1;
run;

proc univariate data=sorted_rdate noprint;
	by rdate;
	var held_pct;
	output out=medlg(keep=rdate n_hldpct nm_hldpct mean_hldpct std_hldpct min_hldpct p1_hldpct p5_heldpct p10_hldpct
							p25_hldpct p50_hldpct p75_hldpct p90_hldpct p95_hldpct p99_hldpct max_hldpct) 	
																			mean=mean_hldpct std= std_hldpct 
																			nmiss = nm_hldpct n=n_hldpct
																			min = min_hldpct
																			p1 = p1_hldpct p5 = p5_heldpct p10 = p10_hldpct
																			q1 = p25_hldpct median = p50_hldpct q3 = p75_hldpct
																			p90 = p90_hldpct p95 = p95_hldpct p99 = p99_hldpct
																			max = max_hldpct;
run;