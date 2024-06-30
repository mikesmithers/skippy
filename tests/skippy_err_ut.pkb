create or replace package body skippy_err_ut as

    -- globals
    g_start_id number;

    -- Helpers
    procedure set_globals is
    begin
        select nvl( max(id), 0)
        into g_start_id
        from skippy_logs;
    end set_globals;
    
    procedure remove_log_records( i_test in varchar2)
    is
        v_source varchar2(500);
        pragma autonomous_transaction;
    begin
        v_source := $$plsql_unit||'.'||i_test;
        delete from skippy_logs
        where log_source = v_source
        and id >= g_start_id;
        commit;
    end remove_log_records;    

    -- exception_block
    procedure exception_block
    is

        v_log_source varchar2(500);
        v_actual skippy_logs%rowtype;
        v_expected varchar2(4000);
        
        
        procedure buggy is
            e_spurious exception;
            pragma exception_init( e_spurious, -1476);
        begin
            raise e_spurious;
        end buggy;    
        
    begin
        -- Setup
        set_globals;
        v_expected := 'ORA-01476: divisor is equal to zero'
            ||chr(10)||'ORA-06512: at "MIKE.SKIPPY_ERR_UT", line 39'
            ||chr(10)||'ORA-06512: at "MIKE.SKIPPY_ERR_UT", line 53'||chr(10);

        skippy.set_log_level('A');        
        
        -- Execute
        begin
            buggy;
        exception when others then
            skippy.err;
        end;
        
        -- Validate
        -- The log source is reported differently in 11g to later versions.
        if dbms_db_version.ver_le_11 then
            v_log_source := 'SKIPPY_ERR_UT.BUGGY';
        else
            v_log_source := 'SKIPPY_ERR_UT.EXCEPTION_BLOCK';
        end if;
        
        select *
        into v_actual
        from skippy_logs
        where id = ( select max(id) from skippy_logs where log_source = v_log_source);
        
        ut.expect( v_actual.message).to_(equal(v_expected));
        
        -- Teardown
        remove_log_records('EXCEPTION_BLOCK');
        
    end exception_block;    
    
    procedure specify_group
    is
        v_group varchar2(30) := 'MOB';
        v_actual varchar2(30);
    begin
        -- Setup
        set_globals;
        skippy.set_log_level('A');        
        raise_application_error(-20999, 'Another Error');
    exception when others then
        -- Execute
        skippy.err(v_group);
        
        -- Validate
        select message_group
        into v_actual
        from skippy_logs
        where id = ( select max(id) from skippy_logs where log_source = 'SKIPPY_ERR_UT.SPECIFY_GROUP');
        
        ut.expect( v_actual).to_(equal(v_group));
        
        -- Teardown
        remove_log_records('SPECIFY_GROUP');
    end specify_group;    
    
    -- get_err function
    procedure err_function
    is
        v_joey number;
        v_expected varchar2(4000);
        v_actual skippy_logs.message%type;
    begin
        -- Setup

        v_expected := 'ORA-06502: PL/SQL: numeric or value error: character to number conversion error'
            ||chr(10)||'ORA-06512: at "MIKE.SKIPPY_ERR_UT", line 118'||chr(10);

        
        -- Execute
        begin
            v_joey := 'No worries';
        exception when others then
            v_actual := skippy.get_err;
        end;
        
        -- Validate
        ut.expect( v_actual).to_(equal(v_expected));
        
    end err_function;    
    
end skippy_err_ut;    