alter session set STATISTICS_LEVEL=ALL;
query.sql
SELECT * FROM   TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ADVANCED RUNSTATS_LAST'));

select dbms_stats.create_extended_stats('CTS_OWNER','WS_OPNL_LEG_ACYS','(NVL(SCH_ARR_TM_DEV,SCH_ARR_DTM_UTC))') from dual;
--SYS_STU3FNOJ9D$P2UA2$DM$SVIN8_

select column_name,num_distinct,num_nulls,histogram from dba_tab_col_statistics where owner='CTS_OWNER' and table_name='WS_OPNL_LEG_ACYS' order by 1,2;

exec dbms_stats.gather_table_stats('CTS_OWNER','WS_OPNL_LEG_ACYS');
select * from dba_stat_extensions  where table_name='WS_OPNL_LEG_ACYS';
exec DBMS_STATS.DROP_EXTENDED_STATS('CTS_OWNER','WS_OPNL_LEG_ACYS','(NVL(SCH_ARR_TM_DEV,SCH_ARR_DTM_UTC))');


query.sql
SELECT * FROM   TABLE(DBMS_XPLAN.DISPLAY_CURSOR(format => 'ADVANCED RUNSTATS_LAST'));
