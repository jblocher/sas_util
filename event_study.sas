
* Event Study -- using SP500 additions list;
* M Boldin Oct 2003;
* http://wrds.wharton.upenn.edu/support/docs/eventstudy.shtml ;

options errors=3 noovp;
options nocenter ps=max ls=78;
options mprint source nodate symbolgen macrogen;
options msglevel=i;

libname crsp '/wrds/crsp/sasdata/sd';

Title " Event Study -- using SP500 additions list for 2000";

*The days1 and days2 numbers set the window around the event date for data extract;
%let days1= -60;
%let days2= +30;

*Step 0: Input the data: permnos and event dates;

data elist;
input permno edate yymmdd8.;
format edate date9.;
datalines;
75592 20020116
79057 20020129
80515 20020131
51706 20020208
36397 20020503
81285 20020510
81138 20020514
76240 20020514
80100 20020625
58094 20020716
10108 20020719
75828 20020719
86356 20020719
86868 20020719
87447 20020719
89195 20020719
89258 20020719
89179 20020724
86946 20020903
84373 20021211
;
run;
* proc print data=elist; run;

Title2 "Event date file";
proc sort; by permno edate;
proc print; run;

* Step 1: Getting the raw data: stock returns and market returns;

*Match-Merge security data from master file for event window;
proc sql;
create table dsfx
as select e.*, s.date, s.ret
from elist as e
left join crsp.dsf as s
on s.permno = e.permno
and (&days1 <= (s.date - e.edate) <= &days2);
quit;

* Above restricts security data date range to days1 before and days2 after the event;


*Add market return from indices file;
proc sql;
create table dsfx
as select s.*, i.vwretd
from dsfx as s
left join crsp.dsi as i
on i.date=s.date;
run;


Title2 "Data file with DSF and DSI items -- checking step";
proc print data= dsfx (obs=20); run;

proc means data=dsfx;
var ret vwretd;;
run;


* Step 2: Preparing data for analysis: Creating new variables;

* --1. create excess return variable RETXMKT (subtract market index);
* --2. create EDAYS variable time that is zero the event day, negative before and positive after the event day;
* --3. create variable TD_COUNT measuring trading days relative to event date (<= EDAYs, controlling for the days the market is
closed);

data dsfx;
set work.dsfx;
retxmkt = ret - vwretd;
edays = date - edate;
run;

* Need to count trading days;
* First, count trading days before event;

proc sort data=dsfx out=temp1;
where date lt edate;
by permno edate descending date; *descending order for date is intentional;
run;
data temp1;
set temp1;
by permno edate;
if first.edate=1 then td_count=0;
td_count=td_count-1; *increments in negative direction;
retain td_count;
run;

*proc print data= temp1;
*run;

*Next count trading days after event;
proc sort data=dsfx out=temp2;
where date ge edate;
by permno edate date; *ascending order as default;
run;
data temp2;
set temp2;
by permno edate;
if first.edate=1 then td_count=0;
td_count=td_count+1; *increments in positive direction;
if date = edate then td_count=0; *special case for even date;
retain td_count;
run;

*Rejoin the before and after days (concatenating) then sort;
data dsfx2;
set temp1 temp2;
run;
proc sort;
by permno td_count;
run;

Title2 "Data items on event days";
proc print data= dsfx2 (obs= 60);
* where edays=0;
run;


proc sort data= dsfx2;
by td_count permno;
run;

Title2 "Data items on event days: sorted by td_count";
proc print data= dsfx2 (obs= 20);
* where edays=0;
run;

*Step3: Start Analysis: Generate Stats;

Title2 "Stats grouped by trading day (td_count)";
proc means noprint n mean stderr;
var retxmkt;
by td_count;
output out=omeans2(drop=_TYPE_ _FREQ_)
n= mean= stderr= / autoname;
run;
proc print data=omeans2; run;


*Calculate addtional stats: t-statistic;
data omeans2;
set omeans2;
by td_count;

t_stat = retxmkt_mean / retxmkt_stderr;

* Compute Cumulative CAR calculations;
if _n_=1 then sum_ret_before = 0;
if sum_ret_before=. then sum_ret_before = 0;
if td_count < 0 then sum_ret_before = sum_ret_before + retxmkt_mean;

if td_count >= 0 then sum_ret_before=.;
if td_count= 1 then sum_ret_after = retxmkt_mean;
if td_count > 1 then sum_ret_after = sum_ret_after + retxmkt_mean;

retain sum_ret_before sum_ret_after;

run;

proc print data=omeans2; run;

Title2 ' Event day cases';
proc reg data=dsfx2;
where td_count=0;
model retxmkt =;
run;

Title2 ' 10 days before event date';
proc reg data=dsfx2;
where td_count between -10 and -1;
model retxmkt =;
run;

Title2 ' 10 days after event date';
proc reg data=dsfx2;
where td_count between 1 and 10;
model retxmkt =;
run;

*** end sas;
