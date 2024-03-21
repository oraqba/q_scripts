exec DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO();
accept owner -
       prompt 'Enter owner name : ' -
       default ''

accept table_name -
       prompt 'Enter table name : ' -
       default ''

accept index_name -
       prompt 'Enter index name : ' -
       default ''

accept ORACLE_MAINTAINED -
       prompt 'Include ORACLE_MAINTAINED (Y/[N]) : ' -
       default 'N'

set feedback off
--set sqlblanklines on
set verify off
set pages 300 lines 300
col owner for a30
col table_owner for a30
col index_name for a30
col table_name for a30
col partition_name for a30
col inserts for 9999999999
col updates for 9999999999
col deletes for 9999999999
col COLUMN_NAME for a30

prompt 'Table modification'

SELECT TABLES.OWNER, TABLES.TABLE_NAME,
ROUND((DELETES + UPDATES + INSERTS)/NUM_ROWS*100) PERCENTAGE,
DELETES,UPDATES,INSERTS,NUM_ROWS
FROM DBA_TABLES TABLES, DBA_TAB_MODIFICATIONS MODIFICATIONS
WHERE TABLES.OWNER = MODIFICATIONS.TABLE_OWNER
AND TABLES.TABLE_NAME = MODIFICATIONS.TABLE_NAME
AND NUM_ROWS > 0
AND ROUND ( (DELETES + UPDATES + INSERTS) / NUM_ROWS * 100) >= 10
AND TABLES.OWNER like upper('&&owner%')
AND TABLES.TABLE_NAME like upper('&&table_name%')
AND TABLES.OWNER in (select username from dba_users where ORACLE_MAINTAINED in ('N','&&ORACLE_MAINTAINED'))
ORDER BY 1,2 desc
/


prompt 'Table stale stats'

select owner,table_name,partition_name,num_rows,last_analyzed,decode(stale_stats,'NO','NO',NULL, 'NO STATS', 'YES') stale_stats
from dba_tab_statistics
where (stale_stats='YES' or stale_stats is null)
and OWNER like upper('&&owner%')
AND TABLE_NAME like upper('&&table_name%')
AND OWNER in (select username from dba_users where ORACLE_MAINTAINED in ('N','&&ORACLE_MAINTAINED'))
order by owner,table_name
/

prompt 'Index stale stats'

select table_owner,table_name,index_name,partition_name,num_rows,last_analyzed,decode(stale_stats,'NO','NO',NULL, 'NO STATS', 'YES') stale_stats
from dba_ind_statistics
where (stale_stats='YES' or stale_stats is null)
and TABLE_OWNER like upper('&&owner%')
AND TABLE_NAME like upper('&&table_name%')
AND INDEX_NAME like upper('&&index_name%')
AND TABLE_OWNER in (select username from dba_users where ORACLE_MAINTAINED in ('N','&&ORACLE_MAINTAINED'))
order by owner,table_name,index_name
/

col gather_stats for a100
select distinct 'exec DBMS_STATS.GATHER_SCHEMA_STATS('''||owner||''',options =>''GATHER AUTO'',degree=>4);' GATHER_STATS from dba_tab_statistics
where (stale_stats='YES' or stale_stats is null)
AND OWNER in (select username from dba_users where ORACLE_MAINTAINED in ('N','&&ORACLE_MAINTAINED'))
order by 1;

undef owner
undef table_name
undef index_name
undef ORACLE_MAINTAINED
