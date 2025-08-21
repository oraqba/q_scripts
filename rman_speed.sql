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


SELECT
     a.device_type, a.TYPE, b.status, b.mbytes_processed AS "Total MB", a.filename, ROUND(a.bytes/(1024*1024)) AS "Size MB", TO_CHAR(a.open_time,'dd-mon-yyyy hh24:mi:ss') AS open_time,
     ROUND(a.elapsed_time/100) AS "Time (s)", ROUND(a.elapsed_time/100) AS "Elapsed (s)", ROUND(a.effective_bytes_per_second/(1024*1024)) AS "MB/s"
     FROM v$backup_async_io a, v$rman_status b
     WHERE a.rman_status_recid = b.recid
     ORDER BY a.use_count;

SELECT
     a.device_type, a.TYPE, b.status, b.mbytes_processed AS "Total MB", a.filename, ROUND(a.bytes/(1024*1024)) AS "Size MB", TO_CHAR(a.open_time,'dd-mon-yyyy hh24:mi:ss') AS open_time,
     ROUND(a.elapsed_time/100) AS "Time (s)", ROUND(a.elapsed_time/100) AS "Elsapsed (s)", ROUND(a.effective_bytes_per_second/(1024*1024)) AS "MB/s"
     FROM v$backup_sync_io a, v$rman_status b
     WHERE a.rman_status_recid = b.recid
     ORDER BY a.use_count;
