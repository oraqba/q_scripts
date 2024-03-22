col sql_id for a30
col sql_text for a100
SET LINESIZE 1000

prompt Last executed query :
column def_sql_id new_val def_sql_id
select distinct nvl(PREV_SQL_ID,'no_prev_sql_id') def_sql_id,sql_text from v$session,v$sql where PREV_SQL_ID=v$sql.sql_id and sid in (select distinct sid from v$mystat);

accept sql_id -
       prompt 'Enter sql_id ([last_executed_query]): ' -
       default '&def_sql_id'
accept PATH -
       prompt 'Provide path ([Current directory]) : ' -
       default ''   

--TXT--
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET LINESIZE 1000
SET PAGESIZE 0
SET TRIM ON
SET TRIMSPOOL ON
SET ECHO OFF
SET FEEDBACK OFF
VARIABLE sql_id VARCHAR2(200)
exec :sql_id :='&&sql_id'
column filename new_val filename
select '&&PATH'||'sqlmonitor_report_'||:sql_id||'_'|| to_char(sysdate, 'yyyymmdd' )||'.txt' filename from dual;
SPOOL &filename
SELECT DBMS_SQLTUNE.report_sql_monitor(
  sql_id       => :sql_id,
  type         => 'TEXT',
  report_level => 'ALL') AS report
FROM dual;
SPOOL OFF

select 'TEXT SQL Monitor Report saved under '||'&filename' from dual;


--HTML--
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET LINESIZE 1000
SET PAGESIZE 0
SET TRIM ON
SET TRIMSPOOL ON
SET ECHO OFF
SET FEEDBACK OFF
select '&&PATH'||'sqlmonitor_report_'||:sql_id||'_'|| to_char(sysdate, 'yyyymmdd' )||'.html' filename from dual;
SPOOL &filename
SELECT DBMS_SQLTUNE.report_sql_monitor(
  sql_id       => :sql_id,
  type         => 'HTML',
  report_level => 'ALL') AS report
FROM dual;
SPOOL OFF
select 'HTML SQL Monitor Report saved under '||'&filename' from dual;

--ACTIVE--
SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET LINESIZE 1000
SET PAGESIZE 0
SET TRIM ON
SET TRIMSPOOL ON
SET ECHO OFF
SET FEEDBACK OFF
select '&&PATH'||'sqlmonitor_activereport_'||:sql_id||'_'|| to_char(sysdate, 'yyyymmdd' )||'.html' filename from dual;
SPOOL &filename
SELECT DBMS_SQLTUNE.report_sql_monitor(
  sql_id       => :sql_id,
  type         => 'ACTIVE',
  report_level => 'ALL') AS report
FROM dual;
SPOOL OFF
select 'ACTIVE SQL Monitor Report saved under '||'&filename' from dual;
