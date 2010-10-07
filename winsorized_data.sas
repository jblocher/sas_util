ods output winsorizedmeans=IMaster2_1;
proc univariate winsorized = 0.01 data=Master1_REGSHO;
by HEXCD LogMktCapRank yearEnd SIRank;
Var g1_ssvol_pct_s g2_ssvol_pct_s g3_ssvol_pct_s g4_ssvol_pct_s g5_ssvol_pct_s g6_ssvol_pct_s g7_ssvol_pct_s g8_ssvol_pct_s g9_ssvol_pct_s g10_ssvol_pct_s g11_ssvol_pct_s g12_ssvol_pct_s g13_ssvol_pct_s 
g1_norm_pct_s g2_norm_pct_s g3_norm_pct_s g4_norm_pct_s g5_norm_pct_s g6_norm_pct_s g7_norm_pct_s g8_norm_pct_s g9_norm_pct_s g10_norm_pct_s g11_norm_pct_s g12_norm_pct_s g13_norm_pct_s 
;
run ;
