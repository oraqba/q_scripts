alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';
set pages 0
SELECT 'Throughput: '||
       ROUND(SUM(v.value/1024/1024/1024/1024),1) || ' Tb so far @ ' ||
       ROUND(SUM(v.value     /1024/1024)/NVL((SELECT MIN(elapsed_seconds)
            FROM v$session_longops
            WHERE opname          LIKE 'RMAN: aggregate input'
              AND sofar           != TOTALWORK
              AND elapsed_seconds IS NOT NULL
       ),SUM(v.value     /1024/1024)),2) || ' Meg/sec'
 FROM gv$sesstat v, v$statname n, gv$session s
WHERE v.statistic# = n.statistic#
  AND n.name       = 'physical write total bytes'
  AND v.sid        = s.sid
  AND v.inst_id    = s.inst_id
  AND s.program LIKE 'rman@%'
GROUP BY n.name
/
select
  sid,
  start_time,
  totalwork
  sofar,
 (sofar/totalwork) * 100 pct_done
from
   gv$session_longops
where
   totalwork > sofar
AND
   opname NOT LIKE '%aggregate%'
AND   opname like 'RMAN%'
order by pct_done;
