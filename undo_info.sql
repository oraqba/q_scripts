show parameter undo

pause Show Undo usage and size
prompt 

set linesize 132 tab off trimspool on
set pagesize 105
set pause off
set echo off
set feedb on
column "TOTAL ALLOC (MB)" format 999,999,990.00
column "TOTAL PHYS ALLOC (MB)" format 999,999,990.00
column "USED (MB)" format  999,999,990.00
column "FREE (MB)" format 999,999,990.00
column "% USED" format 990.00
select a.tablespace_name,
       a.bytes_alloc/(1024*1024) "TOTAL ALLOC (MB)",
       a.physical_bytes/(1024*1024) "TOTAL PHYS ALLOC (MB)",
       nvl(b.tot_used,0)/(1024*1024) "USED (MB)",
       (nvl(b.tot_used,0)/a.bytes_alloc)*100 "% USED"
from ( select tablespace_name,
       sum(bytes) physical_bytes,
       sum(decode(autoextensible,'NO',bytes,'YES',maxbytes)) bytes_alloc
       from dba_data_files
       group by tablespace_name ) a,
     ( select tablespace_name, sum(bytes) tot_used
       from dba_segments
       group by tablespace_name ) b
where a.tablespace_name = b.tablespace_name (+)
--and   (nvl(b.tot_used,0)/a.bytes_alloc)*100 > 10
and   a.tablespace_name not in (select distinct tablespace_name from dba_temp_files)
and   a.tablespace_name like 'UNDO%'
order by 1
--order by 5
/
select TABLESPACE_NAME,retention from dba_tablespaces where TABLESPACE_NAME like '%UNDO%';

pause Show Undo errors
prompt 

column UNXPSTEALCNT heading "# Unexpired|Stolen"
column EXPSTEALCNT heading "# Expired|Reused"
column SSOLDERRCNT heading "ORA-1555|Error"
column NOSPACEERRCNT heading "Out-Of-space|Error"
column MAXQUERYLEN heading "Max Query|Length"
select to_char(begin_time,'DD/MM/YYYY HH24:MI') begin_time,
to_char(end_time,'MM/DD/YYYY HH24:MI') end_time,MAXQUERYID,
UNXPSTEALCNT, EXPSTEALCNT , SSOLDERRCNT, NOSPACEERRCNT, MAXQUERYLEN
from v$UNDOSTAT
where (UNXPSTEALCNT+EXPSTEALCNT+SSOLDERRCNT+NOSPACEERRCNT)> 0
and SSOLDERRCNT>0
order by begin_time;

pause Causes for High Undo Tablespace Space Usage (Doc ID 1951402.1)
select max(maxquerylen),max(tuned_undoretention) from v$undostat where END_TIME>sysdate-7;
select max(maxquerylen),max(tuned_undoretention) from DBA_HIST_UNDOSTAT;

prompt -- Causes for High Undo Tablespace Space Usage (Doc ID 1951402.1)
prompt -- High Undo Utilization On 19c PDB Database due to Automatic TUNED_UNDORETENTION (Doc ID 2710337.1)

pause Show max(maxquerylen),max(tuned_undoretention)
prompt -- The undo space usage is due to the undo records retained for the undo retention period. Check the output of the following query:
select TABLESPACE_NAME,STATUS, round(SUM(BYTES)/1024/1024/1024) GB, COUNT(*) FROM DBA_UNDO_EXTENTS GROUP BY tablespace_name,STATUS order by tablespace_name;
prompt --If the majority of the Undo extents is of status Active, the Undo space is used by active transaction. This indicates a genuine space requirement and hence the solution is to add more space (as mentioned in Step 1).
prompt --If the majority of the Undo extents are of status Unexpired, the undo space usage is due to undo records which are retained for a high duration. This is most often due to the high TUNED_UNDORETENTION value.
prompt --If the majority of the Undo extents are of status Expired, those extents are available for reuse for the subsequent transactions.

pause Show current undo usage by sql_id
select start_time, username, r.name, t.status,used_ublk, (used_ublk*16384)/1024/1024 mb, used_urec, sql_id,PREV_SQL_ID from v$transaction t, v$rollname r, v$session s
where xidusn=usn
and s.saddr=t.ses_addr
order by 1;

prompt --To tune SQL queries or to check on runaway queries, use the value of the SQLID column provided in the long query or in the V$UNDOSTAT or WRH$_UNDOSTAT views to retrieve SQL text and other details on the SQL from V$SQL view.
pause Show usage over the time
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
select BEGIN_TIME,END_TIME,UNDOBLKS,MAXQUERYLEN,MAXQUERYID,ACTIVEBLKS,UNEXPIREDBLKS,EXPIREDBLKS,TUNED_UNDORETENTION,SSOLDERRCNT from v$undostat order by 1 desc;
--select *from WRH$_UNDOSTAT where begin_time>sysdate-2 order by 1 desc;

pause Show undo advisors
SELECT 'The Length of the Longest Query in Memory is ' || dbms_undo_adv.longest_query LONGEST_QUERY FROM dual;
SELECT 'The Length of the Longest Query During This Time Range is ' ||dbms_undo_adv.longest_query(SYSDATE-1/24, SYSDATE) LONGEST_QUERY FROM dual;
SELECT 'The Required undo_retention using Statistics In Memory is ' || dbms_undo_adv.required_retention required_retention FROM dual;
SELECT 'The Required undo_retention During This Time Range is ' ||dbms_undo_adv.required_retention(SYSDATE-1/24, SYSDATE) required_retention FROM dual;
SELECT 'The best possible value for undo_retention the current undo tablespace can satisfy is ' ||dbms_undo_adv.best_possible_retention(SYSDATE-1/24, SYSDATE) best_retention FROM dual;
SELECT 'The Required undo tablespace size using Statistics In Memory is ' || dbms_undo_adv.required_undo_size(900) || ' MB' required_undo_size FROM dual;

pause Run advisor
--Script - Check Current Undo Configuration and Advise Recommended Setup (Doc ID 1579035.1
SET SERVEROUTPUT ON
SET LINES 600
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';
DECLARE
    v_analyse_start_time    DATE := SYSDATE - 7;
    v_analyse_end_time      DATE := SYSDATE;
    v_cur_dt                DATE;
    v_undo_info_ret         BOOLEAN;
    v_cur_undo_mb           NUMBER;
    v_undo_tbs_name         VARCHAR2(100);
    v_undo_tbs_size         NUMBER;
    v_undo_autoext          BOOLEAN;
    v_undo_retention        NUMBER(6);
    v_undo_guarantee        BOOLEAN;
    v_instance_number       NUMBER;
    v_undo_advisor_advice   VARCHAR2(100);
    v_undo_health_ret       NUMBER;
    v_problem               VARCHAR2(1000);
    v_recommendation        VARCHAR2(1000);
    v_rationale             VARCHAR2(1000);
    v_retention             NUMBER;
    v_utbsize               NUMBER;
    v_best_retention        NUMBER;
    v_longest_query         NUMBER;
    v_required_retention    NUMBER;
BEGIN
    select sysdate into v_cur_dt from dual;
    DBMS_OUTPUT.PUT_LINE(CHR(9));
    DBMS_OUTPUT.PUT_LINE('- Undo Analysis started at : ' || v_cur_dt || ' -');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');
    v_undo_info_ret := DBMS_UNDO_ADV.UNDO_INFO(v_undo_tbs_name, v_undo_tbs_size, v_undo_autoext, v_undo_retention, v_undo_guarantee);
    select sum(bytes)/1024/1024 into v_cur_undo_mb from dba_data_files where tablespace_name = v_undo_tbs_name;
    DBMS_OUTPUT.PUT_LINE('NOTE:The following analysis is based upon the database workload during the period -');
    DBMS_OUTPUT.PUT_LINE('Begin Time : ' || v_analyse_start_time);
    DBMS_OUTPUT.PUT_LINE('End Time   : ' || v_analyse_end_time);
    DBMS_OUTPUT.PUT_LINE(CHR(9));
    DBMS_OUTPUT.PUT_LINE('Current Undo Configuration');
    DBMS_OUTPUT.PUT_LINE('--------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('Current undo tablespace',55) || ' : ' || v_undo_tbs_name);
    DBMS_OUTPUT.PUT_LINE(RPAD('Current undo tablespace size (datafile size now) ',55) || ' : ' || v_cur_undo_mb || 'M');
    DBMS_OUTPUT.PUT_LINE(RPAD('Current undo tablespace size (consider autoextend) ',55) || ' : ' || v_undo_tbs_size || 'M');
    IF V_UNDO_AUTOEXT THEN
        DBMS_OUTPUT.PUT_LINE(RPAD('AUTOEXTEND for undo tablespace is',55) || ' : ON');
    ELSE
        DBMS_OUTPUT.PUT_LINE(RPAD('AUTOEXTEND for undo tablespace is',55) || ' : OFF');
    END IF;
    DBMS_OUTPUT.PUT_LINE(RPAD('Current undo retention',55) || ' : ' || v_undo_retention);
    IF v_undo_guarantee THEN
        DBMS_OUTPUT.PUT_LINE(RPAD('UNDO GUARANTEE is set to',55) || ' : TRUE');
    ELSE
        dbms_output.put_line(RPAD('UNDO GUARANTEE is set to',55) || ' : FALSE');
    END IF;
    DBMS_OUTPUT.PUT_LINE(CHR(9));
    SELECT instance_number INTO v_instance_number FROM V$INSTANCE;
    DBMS_OUTPUT.PUT_LINE('Undo Advisor Summary');
    DBMS_OUTPUT.PUT_LINE('---------------------------');
    v_undo_advisor_advice := dbms_undo_adv.undo_advisor(v_analyse_start_time, v_analyse_end_time, v_instance_number);
    DBMS_OUTPUT.PUT_LINE(v_undo_advisor_advice);
    DBMS_OUTPUT.PUT_LINE(CHR(9));
    DBMS_OUTPUT.PUT_LINE('Undo Space Recommendation');
    DBMS_OUTPUT.PUT_LINE('-------------------------');
    v_undo_health_ret := dbms_undo_adv.undo_health(v_analyse_start_time, v_analyse_end_time, v_problem, v_recommendation, v_rationale, v_retention, v_utbsize);
    IF v_undo_health_ret > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Minimum Recommendation           : ' || v_recommendation);
        DBMS_OUTPUT.PUT_LINE('Rationale                        : ' || v_rationale);
        DBMS_OUTPUT.PUT_LINE('Recommended Undo Tablespace Size : ' || v_utbsize || 'M');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Allocated undo space is sufficient for the current workload.');
    END IF;
    SELECT dbms_undo_adv.best_possible_retention(v_analyse_start_time, v_analyse_end_time) into v_best_retention FROM dual;
    SELECT dbms_undo_adv.longest_query(v_analyse_start_time, v_analyse_end_time) into v_longest_query FROM dual;
    SELECT dbms_undo_adv.required_retention(v_analyse_start_time, v_analyse_end_time) into v_required_retention FROM dual;
    DBMS_OUTPUT.PUT_LINE(CHR(9));
    DBMS_OUTPUT.PUT_LINE('Retention Recommendation');
    DBMS_OUTPUT.PUT_LINE('------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('The best possible retention with current configuration is ',60) || ' : ' || v_best_retention || ' Seconds');
    DBMS_OUTPUT.PUT_LINE(RPAD('The longest running query ran for ',60) || ' : ' || v_longest_query || ' Seconds');
    DBMS_OUTPUT.PUT_LINE(RPAD('The undo retention required to avoid errors is ',60) || ' : ' || v_required_retention || ' Seconds');
END;
/
