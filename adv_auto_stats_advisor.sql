--AUTO_STATS_ADVISOR
--cleanup and check

--change retention
EXEC DBMS_ADVISOR.SET_TASK_PARAMETER(task_name=> 'AUTO_STATS_ADVISOR_TASK', parameter=> 'EXECUTION_DAYS_TO_EXPIRE', value => 7);

--check if AUTO_STATS_ADVISOR is enabled
select dbms_stats.get_prefs('AUTO_STATS_ADVISOR_TASK') from dual;
exec dbms_stats.set_global_prefs('AUTO_STATS_ADVISOR_TASK','FALSE');

col task_name format a25
col EXECUTION_NAME format a15
col OCCUPANT_NAME for a40
select TASK_ID,TASK_NAME,EXECUTION_NAME ,execution_start from dba_advisor_executions where TASK_NAME='AUTO_STATS_ADVISOR_TASK';
SELECT occupant_name, space_usage_kbytes/1024 MB FROM V$SYSAUX_OCCUPANTS where occupant_name='SM/ADVISOR';
SELECT COUNT(*) CNT FROM DBA_ADVISOR_OBJECTS where TASK_NAME='AUTO_STATS_ADVISOR_TASK';
SELECT EXECUTION_NAME,COUNT(*) CNT FROM DBA_ADVISOR_OBJECTS where TASK_NAME='AUTO_STATS_ADVISOR_TASK' group by EXECUTION_NAME order by 2;

--cleanup in chunks
set timing on    
    set serveroutput on
    DECLARE
        v_oldest INTEGER := 30;    -- the oldest entry
        v_increment INTEGER := 1;
        v_cur_age INTEGER;
        v_min_age INTEGER := 1;     -- days to retian.
    BEGIN
        v_cur_age := v_oldest;
        WHILE v_cur_age >= v_min_age LOOP
            dbms_sqltune.set_tuning_task_parameter(task_name => 'AUTO_STATS_ADVISOR_TASK', parameter => 'EXECUTION_DAYS_TO_EXPIRE', value => v_cur_age);
            prvt_advisor.delete_expired_tasks;
            v_cur_age := v_cur_age - v_increment;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Execution halted with error number ' || sqlerrm);
    END;
    /


--cleanup everything
DECLARE
v_tname VARCHAR2(32767);
BEGIN
v_tname := 'AUTO_STATS_ADVISOR_TASK';
DBMS_STATS.DROP_ADVISOR_TASK(v_tname);
END;
/

--after cleanup
alter table WRI$_ADV_OBJECTS move;
alter index WRI$_ADV_OBJECTS_PK rebuild;
alter index WRI$_ADV_OBJECTS_IDX_01 rebuild;
alter index WRI$_ADV_OBJECTS_IDX_02 rebuild;
EXEC DBMS_STATS.INIT_PACKAGE();



--report example
COL EXECUTION_NAME FORMAT a14
SELECT EXECUTION_NAME, EXECUTION_END, STATUS
FROM   DBA_ADVISOR_EXECUTIONS
WHERE  TASK_NAME = 'AUTO_STATS_ADVISOR_TASK'
ORDER BY 2;

EXECUTION_NAME EXECUTION_END       STATUS
-------------- ------------------- ---------------------------------
EXEC_22247     19.01.2023 22:02:09 COMPLETED

SET LINESIZE 3000
SET LONG 500000
SET PAGESIZE 0
SET LONGCHUNKSIZE 100000
SELECT DBMS_STATS.REPORT_ADVISOR_TASK('AUTO_STATS_ADVISOR_TASK', 'EXEC_22247','TEXT', 'ALL', 'ALL') AS REPORT
FROM   DUAL;

GENERAL INFORMATION
-------------------------------------------------------------------------------

 Task Name       : AUTO_STATS_ADVISOR_TASK
 Execution Name  : EXEC_22247
 Created         : 08-05-22 03:35:23
 Last Modified   : 01-20-23 12:04:04
-------------------------------------------------------------------------------
SUMMARY
-------------------------------------------------------------------------------
 For execution EXEC_22247 of task AUTO_STATS_ADVISOR_TASK, the Statistics
 Advisor has 4 finding(s). The findings are related to the following rules:
 USECONCURRENT, AVOIDSTALESTATS, UNLOCKNONVOLATILETABLE, AVOIDDROPRECREATE.
 Please refer to the finding section for detailed information.
-------------------------------------------------------------------------------
FINDINGS
-------------------------------------------------------------------------------
 Rule Name:         UseConcurrent
 Rule Description:  Use Concurrent preference for Statistics Collection
 Finding:  The CONCURRENT preference is not used.

 Recommendation:  Set the CONCURRENT preference.
 Example:
 dbms_stats.set_global_prefs('CONCURRENT', 'ALL');
 Rationale:  The systems condition satisfies the use of concurrent statistics
             gathering. Using CONCURRENT increases the efficiency of statistics
             gathering.
----------------------------------------------------
 Rule Name:         AvoidStaleStats
 Rule Description:  Avoid objects with stale or no statistics
 Finding:  There are 1 object(s) with stale statistics.
 Schema:
 DBSNMP
 Objects:
 BSLN_TIMEGROUPS

 Recommendation:  Regather statistics on objects with stale statistics.
 Example:
 -- Gathering statistics for tables with stale or no statistics in schema, SH:
 exec dbms_stats.gather_schema_stats('SH', options => 'GATHER AUTO')
 Rationale:  Stale statistics or no statistics will result in bad plans.
----------------------------------------------------
 Rule Name:         UnlockNonVolatileTable
 Rule Description:  Statistics for objects with non-volatile should not be
                    locked
 Finding:  Statistics are locked on 1 table(s) which are not volatile.
 Schema:
 SYS
 Objects:
 KUPC$DATAPUMP_QUETAB_1

 Recommendation:  Unlock the statistics on non-volatile tables, and use gather
                  statistics operations to gather statistics for these tables.
 Example:
 -- Unlocking statistics for 'SH.SALES':
 dbms_stats.unlock_table_stats('SH', 'SALES');
 Rationale:  Statistics gathering operations will skip locked objects and may
             lead to stale or inaccurate statistics.
----------------------------------------------------
 Rule Name:         AvoidDropRecreate
 Rule Description:  Avoid drop and recreate object seqauences
 Finding:  There are 7 table(s) which have been dropped multiple times.

 Recommendation:  Use TRUNCATE TABLE instead of DROP TABLE commands on these
                  tables.
 Example:
 truncate table T1;
 Rationale:  After the table is dropped, we will lose the column usage
             information for that table. That might prevent some statistics
             (for example, histograms) from being collected in the future.
----------------------------------------------------
-------------------------------------------------------------------------------
