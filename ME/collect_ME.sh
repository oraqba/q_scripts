#!/bin/bash


export ORACLE_SID=emrep
export ORAENV_ASK=NO;. oraenv > /dev/null;
export SPOOLFILE=/tmp/emcli_collect_ME_tmp.sql
$ORACLE_HOME/bin/sqlplus -s sysman/Nsb0326TLP9 <<EOF
set lines 300 pages 0
set feed 0
set head off
set echo off
spool ${SPOOLFILE}
select 'collect_metric  -target_type=oracle_database  -target_name='||target_name
||' -metric_name="ME\$init_param_temp_file_drift_collector"'
from mgmt\$target
where target_type='oracle_database'
order by 1;
select 'collect_metric  -target_type=host  -target_name='||target_name||' -metric_name="ME\$old_java"'
from mgmt\$target
where target_type='host'
order by 1;
EOF

export ORACLE_SID=oms
export ORAENV_ASK=NO;. oraenv > /dev/null;
emcli argfile ${SPOOLFILE}
