/*******************************************************************************************/
/*   Program       : IBES_Sample.sas                                                       */
/*   Author        : Denys Glushkov, WRDS                                                  */
/*   Date Created  : Feb 2008                                                              */   
/*   Last Modified : June 2009								   */
/*                                                                                         */
/*   Description: Extract estimates and link to actuals                                    */
/*                                                                                         */
/* Macro IBES_SAMPLE extracts the estimates from the IBES Unadjusted file based on         */
/* the user-provided input, links them to actuals, puts estimates and actuals on the       */
/* same basis by adjusting for stock splits using CRSP adjustment factor and calculates    */
/* the median of analyst forecasts made in the 90 days prior to the earnings announcement  */
/* date.                                                                                   */
/*******************************************************************************************/
%MACRO IBES_SAMPLE (infile=, ibes1_where=, ibes2_where=, ibes_var=);

proc sql; create table ibes (drop=measure fpi)
        as select *
        from ibes.detu (&ibes1_where keep=&ibes_var) as a,             /* ibes1_where and ibes_var are specified*/
             &infile as b                                              /* prior to invoking IBES_SAMPLE*/
        where a.ticker=b.ticker
        order by a.ticker, fpedats, estimator, analys, anndats, revdats;
quit;

/*Select the last estimate for a firm within broker-analyst group*/     
data ibes; set ibes;
        by ticker fpedats estimator analys;
        if last.analys;
run;

/*How many estimates are reported on primary/diluted basis?*/
proc sql; 
        create table ibes 
                as select a.*, sum(pdf='P') as p_count, sum(pdf='D') as d_count
                from ibes as a
                group by ticker, fpedats;

/* a. Link unadjusted estimates with unadjusted actuals and CRSP permnos                                */
/* b. Adjust report and estimate dates to be CRSP trading days                                          */
        create table ibes1 (&ibes2_where)
                as select a.*, b.anndats as repdats, b.value as act, c.permno,
                case when weekday(a.anndats)=1 then intnx('day',a.anndats,-2)                  /*if sunday move back by 2 days;*/
                     when weekday(a.anndats)=7 then intnx('day',a.anndats,-1) else a.anndats   /*if saturday move back by 1 day*/
                end as estdats1,
                case when weekday(b.anndats)=1 then intnx('day',b.anndats,1)                  /*if sunday move forward by 1 day  */
                     when weekday(b.anndats)=7 then intnx('day',b.anndats,2) else b.anndats   /*if saturday move forward by 2 days*/
               end as repdats1
                from ibes as a, ibes.actu as b, mine.iclink as c
                where a.ticker=b.ticker and a.fpedats=b.pends and a.usfirm=b.usfirm and b.pdicity='QTR' 
                          and b.measure='EPS' and a.ticker=c.ticker and c.score in (0,1,2);

/*   Making sure that estimates and actuals are on the same basis
                        */
/*   1. retrieve CRSP cumulative adjustment factor for IBES report and estimate dates                                           */
        create table adjfactor
                as select distinct a.*
                from crsp.dsf (keep=permno date cfacshr) as a, ibes1 as b
                where a.permno=b.permno and (a.date=b.estdats1 or a.date=b.repdats1);
        
/*      2.if adjustment factors are not the same, adjust the estimate to be on the same basis with the actual   */
        create table ibes1
                as select distinct a.*, b.est_factor, c.rep_factor, 
                        case when (b.est_factor ne c.rep_factor) and missing(b.est_factor)=0 and missing(c.rep_factor)=0
                         then (rep_factor/est_factor)*value else value end as new_value
                from ibes1 as a, 
                        adjfactor (rename=(cfacshr=est_factor)) as b, 
                        adjfactor (rename=(cfacshr=rep_factor)) as c 
                        where (a.permno=b.permno and a.estdats1=b.date) and
                                  (a.permno=c.permno and a.repdats1=c.date);
quit;

/* Make sure the last observation per analyst is included
                        */
proc sort data=ibes1; 
        by ticker fpedats estimator analys anndats revdats;
run;

data ibes1; set ibes1;
by ticker fpedats estimator analys;
if last.analys;
run;

/* Compute the median forecast based on estimates in the 90 days prior to the report date                            */
proc means data=ibes1 noprint;
        by ticker fpedats;
        var /*value*/ new_value;                         /* new_value is the estimate appropriately adjusted         */
        output out= medest (drop=_type_ _freq_)         /* to be on the same basis with the actual reported earnings */
        median=medest n=numest;
run;

/* Merge median estimates with ancillary information on permno, actuals and report dates                              */
/* Determine whether most analysts are reporting estimates on primary or diluted basis                                */
/* following the methodology outlined in Livnat and Mendenhall (2006)                                                 */
proc sql; create table medest 
        as select distinct a.*, b.repdats, b.act, b.permno,
        case when p_count>d_count then 'P' 
             when p_count<=d_count then 'D' 
        end as basis                                                                             
        from medest as a left join ibes1 as b
        on a.ticker=b.ticker and a.fpedats=b.fpedats;
quit;

proc sql; 
        drop table ibes, ibes1;
quit;
%MEND;
