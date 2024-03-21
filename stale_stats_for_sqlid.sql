---https://blogs.oracle.com/optimizer/post/check-sql-stale-statistics
set pagesize 100
set linesize 300
set trims off
set tab off
set verify off
column table_name format a50
column index_name format a50
column object_type format a40
column owner format a40

accept sql_id prompt 'Enter the SQL ID: ' 
PROMPT ==========
PROMPT Tables
PROMPT ==========
with plan_tables as (
select distinct object_name,object_owner, object_type 
from v$sql_plan 
where object_type like 'TABLE%' 
and   sql_id      = '&sql_id')
select t.object_owner owner,
       t.object_name table_name,
       t.object_type object_type,
       decode(stale_stats,'NO','OK',NULL, 'NO STATS!', 'STALE!') staleness   
from   dba_tab_statistics s,
       plan_tables        t
where  s.table_name = t.object_name
and    s.owner      = t.object_owner
and    s.partition_name is null
and    s.subpartition_name is null
order by t.object_owner, t.object_name;

PROMPT ==========
PROMPT Indexes
PROMPT ==========
with plan_indexes as (
select distinct object_name,object_owner, object_type
from v$sql_plan
where object_type like 'INDEX%'
and   sql_id      = '&sql_id')
select i.object_owner owner,
       i.object_name index_name,
       i.object_type object_type,
       decode(stale_stats,'NO','OK',NULL, 'NO STATS!', 'STALE!') staleness
from   dba_ind_statistics s,
       plan_indexes       i
where  s.index_name = i.object_name
and    s.owner      = i.object_owner
and    s.partition_name is null
and    s.subpartition_name is null
order by i.object_owner, i.object_name;
