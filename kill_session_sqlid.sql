accept sql_id prompt 'Enter the SQL ID: '
accept kill_method prompt 'Kill Method (KILL/DISCONNECT/[CANCEL_SQL]) : ' -
       default 'CANCEL_SQL'


set serveroutput on
declare
sql_stmt varchar2(100);
BEGIN
for rec in (SELECT sid,serial#,sql_id
  FROM v$session 
 WHERE status = 'ACTIVE' 
   AND sql_id ='&sql_id' ) loop
         IF '&kill_method' = 'KILL' THEN sql_stmt  := 'alter system kill session '''|| rec.Sid || ',' || rec.Serial# || ''' IMMEDIATE';
         ELSIF '&kill_method' = 'DISCONNECT' THEN sql_stmt  := 'alter system disconnect session '''|| rec.Sid || ',' || rec.Serial# || '''';
         ELSE    sql_stmt  := 'alter system cancel sql '''|| rec.Sid || ',' || rec.Serial#|| ','  || rec.sql_id||'''';
         END IF;
   DBMS_OUTPUT.put_line (sql_stmt);
 execute immediate sql_stmt;
 end loop;
END;
/