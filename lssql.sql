set lines 300
col execs for 999,999,999
col avg_etime for 999,999.999
col avg_lio for 999,999,999.9
col begin_interval_time for a30
col node for 99999
select inst_id node,first_load_time,last_load_time, sql_id, plan_hash_value,
nvl(executions,0) execs,
round((elapsed_time/decode(nvl(executions,0),0,1,executions))/1000000,4) avg_etime_s,
round((buffer_gets/decode(nvl(buffer_gets,0),0,1,executions))) avg_lio,
(ROWS_PROCESSED/decode(nvl(ROWS_PROCESSED,0),0,1,executions)) "rows",
sql_profile,sql_plan_baseline
from gv$sql 
where sql_id = nvl('&sql_id','8c2dm7muhuwdz')
and executions > 0
order by 1, 2, 3
/
