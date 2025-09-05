select instance_number,sql_id,max(TEMP_SPACE_ALLOCATED/1024/1024/1024) gb,'AWR' SAMPLE_FROM,dba_users.user_id,username
from DBA_HIST_ACTIVE_SESS_HISTORY,dba_users where
DBA_HIST_ACTIVE_SESS_HISTORY.USER_ID=DBA_USERS.USER_ID
and TEMP_SPACE_ALLOCATED is not null
group by instance_number,sql_id,dba_users.user_id,username
order by gb desc;
 
 
 
 
--or  pga_usage
 
 
 
select instance_number,sql_id,max(PGA_ALLOCATED/1024/1024/1024) gb,'AWR' SAMPLE_FROM,dba_users.user_id,username
from DBA_HIST_ACTIVE_SESS_HISTORY,dba_users where
DBA_HIST_ACTIVE_SESS_HISTORY.USER_ID=DBA_USERS.USER_ID
and PGA_ALLOCATED is not null
group by instance_number,sql_id,dba_users.user_id,username
union all
select inst_id,sql_id,max(PGA_ALLOCATED/1024/1024/1024) gb,'ASH',dba_users.user_id,username
from GV$ACTIVE_SESSION_HISTORY,dba_users where
GV$ACTIVE_SESSION_HISTORY.USER_ID=DBA_USERS.USER_ID
and PGA_ALLOCATED is not null
group by inst_id,sql_id,dba_users.user_id,username order by 3 desc;
 
 
 
 
select instance_number,sql_id,sum(PGA_ALLOCATED/1024/1024/1024) gb,'AWR' SAMPLE_FROM,sample_time,sample_id
from DBA_HIST_ACTIVE_SESS_HISTORY where
PGA_ALLOCATED is not null
and sql_id is not null
and sql_id='3pfzm1qhxaub8'
group by instance_number,sql_id,sample_time,sample_id
having  sum(PGA_ALLOCATED/1024/1024/1024)   > 30
order by GB desc;
 
set lines 300
set pages 300
select instance_number,sum(PGA_ALLOCATED/1024/1024/1024) gb,'AWR' SAMPLE_FROM,sample_time,sample_id
from DBA_HIST_ACTIVE_SESS_HISTORY
where PGA_ALLOCATED is not null
group by instance_number,sample_time,sample_id
union all
select inst_id,sum(PGA_ALLOCATED/1024/1024/1024) gb,'ASH' SAMPLE_FROM,sample_time,sample_id
from GV$ACTIVE_SESSION_HISTORY
where PGA_ALLOCATED is not null
group by inst_id,sample_time,sample_id
order by 2 asc;
 
 
 
 
 
select inst_id,sql_id,max(TEMP_SPACE_ALLOCATED/1024/1024/1024) gb,'ASH',dba_users.user_id,username
from GV$ACTIVE_SESSION_HISTORY,dba_users where
GV$ACTIVE_SESSION_HISTORY.USER_ID=DBA_USERS.USER_ID
and TEMP_SPACE_ALLOCATED is not null
and SAMPLE_ID in (select max(SAMPLE_ID) from GV$ACTIVE_SESSION_HISTORY)
group by inst_id,sql_id,dba_users.user_id,username order by 3 desc;
