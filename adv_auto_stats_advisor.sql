--AUTO_STATS_ADVISOR
--cleanup and check

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
