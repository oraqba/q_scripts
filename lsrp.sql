col RESTORE_NAME for a30
col storage_size for 99999999999999
col creation_time for a20
select NAME RESTORE_NAME, 
to_char(TIME,'YYYY-MM-DD HH24:MI:SS') creation_time, round((sysdate-CAST(TIME as date))*24,2) hours_ago, 
round(STORAGE_SIZE/1024/1024/1024,2) GB 
from v$restore_point 
where GUARANTEE_FLASHBACK_DATABASE='YES'
order by TIME asc
