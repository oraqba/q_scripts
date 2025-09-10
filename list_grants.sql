set serveroutput on format wrapped;
DECLARE
    procedure printRolePrivileges(
      p_role             in varchar2,
      p_spaces_to_indent in number) IS
      v_child_roles   DBMS_SQL.VARCHAR2_TABLE;
      v_system_privs  DBMS_SQL.VARCHAR2_TABLE;
      v_table_privs   DBMS_SQL.VARCHAR2_TABLE;
      v_indent_spaces varchar2(2048);
    BEGIN
      -- Indentation for nested privileges via granted roles.
      for space in 1..p_spaces_to_indent LOOP
        v_indent_spaces := v_indent_spaces || ' ';
      end LOOP;
      -- Get the system privileges granted to p_role
      select PRIVILEGE bulk collect into v_system_privs
      from DBA_SYS_PRIVS
      where GRANTEE = p_role
      order by PRIVILEGE;
      -- Print the system privileges granted to p_role
      for privind in 1..v_system_privs.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
          v_indent_spaces || 'System priv: ' || v_system_privs(privind));
      END LOOP;
      -- Get the object privileges granted to p_role
      select PRIVILEGE || ' ' || OWNER || '.' || TABLE_NAME
        bulk collect into v_table_privs
      from DBA_TAB_PRIVS
      where GRANTEE = p_role
      order by TABLE_NAME asc;
      -- Print the object privileges granted to p_role
      for tabprivind in 1..v_table_privs.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE(
          v_indent_spaces || 'Object priv: ' || v_table_privs(tabprivind));
      END LOOP;
      -- get all roles granted to p_role
      select GRANTED_ROLE bulk collect into v_child_roles
      from DBA_ROLE_PRIVS
      where GRANTEE = p_role
      order by GRANTED_ROLE asc;
      -- Print all roles granted to p_role and handle child roles recursively.
      for roleind in 1..v_child_roles.COUNT LOOP
        -- Print child role
        DBMS_OUTPUT.PUT_LINE(
         v_indent_spaces || 'Role priv: ' || v_child_roles(roleind));
        -- Print privileges for the child role recursively. Pass 2 additional
        -- spaces to illustrate these privileges belong to a child role.
        printRolePrivileges(v_child_roles(roleind), p_spaces_to_indent + 2);
      END LOOP;
      EXCEPTION
        when OTHERS then
          DBMS_OUTPUT.PUT_LINE('Got exception: ' || SQLERRM );
    END printRolePrivileges;
BEGIN
    printRolePrivileges('&username', 0);
END;
/
