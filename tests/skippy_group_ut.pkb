create or replace package body skippy_group_ut as

    g_log_rec skippy_logs%rowtype;
    g_start_id number;

    --------------------
    -- Helpers
    --------------------
    
    procedure set_globals is
    begin
        g_log_rec.id := null;
        g_log_rec.log_ts := null;
        g_log_rec.username := sys_context('userenv', 'session_user');
        g_log_rec.os_user := sys_context('userenv', 'os_user');
        g_log_rec.instance := sys_context('userenv', 'instance');
        g_log_rec.sid := sys_context('userenv', 'sid');
        g_log_rec.serial := dbms_debug_jdwp.current_session_serial;
        g_log_rec.log_source := null;
        g_log_rec.message_type := 'A';
        g_log_rec.message_group := null;
        g_log_rec.message := null;
        
        select nvl(max(id), 0)
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

    
    --
    -- Tests
    --

    -- set group 
    procedure set_group 
    is
    begin
        -- setup
        set_globals;
        g_log_rec.message_group := 'GROUP_TEST';
        
        -- execute
        skippy.set_msg_group( g_log_rec.message_group);
        
        -- validate
        ut.expect(skippy.current_setting('group')).to_(equal(g_log_rec.message_group));
        
        -- teardown
        remove_log_records('SET_GROUP');
        
    end set_group;    
    
    -- unset group 
    procedure unset_group
    is
    begin
        -- setup
        set_globals;
        -- execute
        skippy.set_msg_group( g_log_rec.message_group);
        -- validate
        ut.expect(skippy.current_setting('group')).to_(be_null());

        -- teardown
        remove_log_records('UNSET_GROUP');

    end unset_group;    
    
    --  log group 
    procedure log_group
    is
        v_actual skippy_logs%rowtype;

    begin
        -- setup
        set_globals;
        g_log_rec.message_group := 'GROUP_TEST';
        g_log_rec.message := 'Log Group Message';
        -- execute
        skippy.set_msg_group( g_log_rec.message_group);
        skippy.set_log_level('A');        
        skippy.log(g_log_rec.message);

        -- validate
        select *
        into v_actual
        from skippy_logs
        where id = ( select max(id) from skippy_logs where log_source = 'SKIPPY_GROUP_UT.LOG_GROUP');

        ut.expect( v_actual.message_group).to_(equal(g_log_rec.message_group));
        
        -- teardown
        remove_log_records('LOG_GROUP');
        
    end log_group;    
    
    --  log no group 
    procedure log_no_group
    is
        v_actual skippy_logs%rowtype;

    begin
        -- setup
        set_globals;
        g_log_rec.message_group := 'GROUP_TEST';
        g_log_rec.message := 'Log Group Message2';
        
        -- Set then unset the group
        skippy.set_msg_group( g_log_rec.message_group);

        -- execute
        skippy.set_msg_group(null);    
        skippy.set_log_level('A');
        skippy.log(g_log_rec.message);

        -- validate

        select *
        into v_actual
        from skippy_logs
        where id = ( select max(id) from skippy_logs where log_source = 'SKIPPY_GROUP_UT.LOG_NO_GROUP');
        
        ut.expect( v_actual.message_group).to_(be_null());

        -- teardown
        remove_log_records('LOG_NO_GROUP');

    end log_no_group;    
    

end skippy_group_ut;
/
