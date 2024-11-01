SET SERVEROUTPUT ON SIZE UNLIMITED

DECLARE
  v_sql_id        VARCHAR2(20) := '&sql_id';

  v_sql_text      CLOB;
  v_profile_name  VARCHAR2(30);

BEGIN
  -- try to find SQL text in cursor cache
  BEGIN
    SELECT sql_fulltext
      INTO v_sql_text
      FROM v$sql
     WHERE sql_id       = v_sql_id
       AND ROWNUM       = 1; -- get any child, we only need SQL text

    DBMS_OUTPUT.put_line('sql_id `'||v_sql_id||'` found in cursor cache.');
  EXCEPTION
    WHEN no_data_found THEN
      DBMS_OUTPUT.put_line('sql_id `'||v_sql_id||'` not found in cursor cache.');
  END;

  -- if SQL text not found in cursor cache, try to find it in AWR
  IF NVL(DBMS_LOB.getlength(v_sql_text),0) = 0 THEN
    BEGIN
      SELECT sql_text
        INTO v_sql_text
        FROM dba_hist_sqltext
       WHERE sql_id       = v_sql_id
         AND ROWNUM       = 1; -- get any child, we only need SQL text

      DBMS_OUTPUT.put_line('sql_id `'||v_sql_id||'` found in AWR.');
    EXCEPTION
      WHEN no_data_found THEN
        DBMS_OUTPUT.put_line('sql_id `'||v_sql_id||'` not found in AWR.');
    END;
  END IF;

  -- if no SQl text found in cursor cache or AWR
  IF NVL(DBMS_LOB.getlength(v_sql_text),0) = 0 THEN
    DBMS_OUTPUT.put_line('No SQL profile created for sql_id `'||v_sql_id||'`');
    RETURN;
  END IF;

  v_profile_name := 'PROF_'||v_sql_id|| '_' || 'imported';

  DBMS_SQLTUNE.import_sql_profile(sql_text    => v_sql_text
                                 ,profile     => sqlprof_attr(
      'IGNORE_OPTIM_EMBEDDED_HINTS'
     ,'OPTIMIZER_FEATURES_ENABLE(''19.1.0'')'
     ,'DB_VERSION(''19.1.0'')'
     ,'OPT_PARAM(''_and_pruning_enabled'' ''false'')'
     ,'OPT_PARAM(''optimizer_index_cost_adj'' 10)'
     ,'OPT_PARAM(''optimizer_index_caching'' 95)'
     ,'OPT_PARAM(''optimizer_dynamic_sampling'' 6)'
     ,'ALL_ROWS'
     , '&hint'
)
                                 ,category    => 'DEFAULT'
                                 ,NAME        => v_profile_name
                                 ,force_match => FALSE
                                  );

  DBMS_OUTPUT.put_line('Created profile `'||v_profile_name||'` for sql_id `'||v_sql_id||'`');
END;
/

