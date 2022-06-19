create or replace package body skippy_log_ut
as
    --------------------
    -- Global Variables
    --------------------
    
    g_log_rec skippy_logs%rowtype;
    g_start_id number;
    
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
        g_log_rec.message_type := 'I';
        g_log_rec.message_group := null;
        g_log_rec.message := null;
        
        select nvl( max( id), 0)
        into g_start_id
        from skippy_logs;
        
    end set_globals;
    
    
    
    --------------------
    -- Helpers
    --------------------
    function get_message_id
        return skippy_logs.id%type
    is
        v_seq_name varchar2(4000);
        v_currval skippy_logs.id%type;
    begin
        -- Re-written to use the explicitly defined sequence now being used
        -- to maintain 11g compatability
        select skippy_logs_id_seq.currval into v_currval from dual;
        return v_currval; 
    end get_message_id;    

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

    --------------------
    -- Tests
    --------------------
    
    -- default message
    procedure write_default_message
    is 
        v_actual skippy_logs%rowtype;
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.WRITE_DEFAULT_MESSAGE';
        g_log_rec.message := q'[What's that Skippy ?]';
        
        -- Execute
        skippy.log(g_log_rec.message);
        
        -- Validate
        select *
        into v_actual
        from skippy_logs
        where id = get_message_id;
        
        ut.expect(g_log_rec.username).to_(equal(v_actual.username));
        ut.expect(g_log_rec.os_user).to_(equal(v_actual.os_user));
        ut.expect(g_log_rec.instance).to_(equal(v_actual.instance));
        ut.expect(g_log_rec.sid).to_(equal(v_actual.sid));
        ut.expect(g_log_rec.serial).to_(equal(v_actual.serial));
        ut.expect(g_log_rec.log_source).to_(equal(v_actual.log_source));
        ut.expect(g_log_rec.message_type).to_(equal(v_actual.message_type));
        ut.expect(v_actual.message_group).to_(be_null());
        ut.expect(g_log_rec.message).to_(equal(v_actual.message));

        -- teardown
        remove_log_records('WRITE_DEFAULT_MESSAGE');

    end write_default_message;
    
    -- non-default valid message level
    procedure valid_message_level
    is 
        v_actual skippy_logs%rowtype;
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.VALID_MESSAGE_LEVEL';
        g_log_rec.message := 'Down a mine shaft ?';
        g_log_rec.message_type := 'W';

        -- Execute
        skippy.set_log_level('A');
        skippy.log(g_log_rec.message, g_log_rec.message_type);
        
        -- Validate

        select *
        into v_actual
        from skippy_logs
        where id = get_message_id;

        ut.expect(g_log_rec.username).to_(equal(v_actual.username));
        ut.expect(g_log_rec.os_user).to_(equal(v_actual.os_user));
        ut.expect(g_log_rec.instance).to_(equal(v_actual.instance));
        ut.expect(g_log_rec.sid).to_(equal(v_actual.sid));
        ut.expect(g_log_rec.serial).to_(equal(v_actual.serial));
        ut.expect(g_log_rec.log_source).to_(equal(v_actual.log_source));
        ut.expect(g_log_rec.message_type).to_(equal(v_actual.message_type));
        ut.expect(v_actual.message_group).to_(be_null());
        ut.expect(g_log_rec.message).to_(equal(v_actual.message));

        -- teardown
        remove_log_records('VALID_MESSAGE_LEVEL');

    end valid_message_level;
    
    -- message group
    procedure message_group
    is 
        v_actual skippy_logs%rowtype;
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := $$plsql_unit||'.MESSAGE_GROUP';
        g_log_rec.message := 'Down the pub';
        g_log_rec.message_group := 'Test';

        -- Execute
        skippy.set_log_level('A');
        skippy.log(g_log_rec.message, i_group => g_log_rec.message_group);
        
        -- Validate
        select *
        into v_actual
        from skippy_logs
        where id = get_message_id;

        ut.expect(g_log_rec.username).to_(equal(v_actual.username));
        ut.expect(g_log_rec.os_user).to_(equal(v_actual.os_user));
        ut.expect(g_log_rec.instance).to_(equal(v_actual.instance));
        ut.expect(g_log_rec.sid).to_(equal(v_actual.sid));
        ut.expect(g_log_rec.serial).to_(equal(v_actual.serial));
        ut.expect(g_log_rec.log_source).to_(equal(v_actual.log_source));
        ut.expect(g_log_rec.message_type).to_(equal(v_actual.message_type));
        ut.expect(g_log_rec.message_group).to_(equal(v_actual.message_group));
        ut.expect(g_log_rec.message).to_(equal(v_actual.message));

        -- teardown
        remove_log_records('MESSAGE_GROUP');

    end message_group;    
    
    -- override source
    procedure override_source
    is 
        v_actual skippy_logs%rowtype;
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := $$plsql_unit||'.OVERRIDE_SOURCE';
        g_log_rec.message := 'Still in the pub';

        -- Execute
        skippy.set_log_level('A');
        skippy.log(g_log_rec.message, i_source => g_log_rec.log_source);
        
        -- Validate
        select *
        into v_actual
        from skippy_logs
        where id = get_message_id;

        ut.expect(g_log_rec.username).to_(equal(v_actual.username));
        ut.expect(g_log_rec.os_user).to_(equal(v_actual.os_user));
        ut.expect(g_log_rec.instance).to_(equal(v_actual.instance));
        ut.expect(g_log_rec.sid).to_(equal(v_actual.sid));
        ut.expect(g_log_rec.serial).to_(equal(v_actual.serial));
        ut.expect(g_log_rec.log_source).to_(equal(v_actual.log_source));
        ut.expect(g_log_rec.message_type).to_(equal(v_actual.message_type));
        ut.expect(g_log_rec.message_group).to_(equal(v_actual.message_group));
        ut.expect(g_log_rec.message).to_(equal(v_actual.message));
        
        -- teardown
        remove_log_records('OVERRIDE_SOURCE');

    end override_source;
    
    procedure override_line_no
    is
        v_actual skippy_logs%rowtype;
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := $$plsql_unit||'.OVERRIDE_LINE_NO';
        g_log_rec.message := 'Still in the pub';
        g_log_rec.line_no := $$plsql_line;
        -- Execute
        skippy.set_log_level('A');
        skippy.log(g_log_rec.message, i_source => g_log_rec.log_source, i_line_no => g_log_rec.line_no);
        
        -- Validate
        select *
        into v_actual
        from skippy_logs
        where id = get_message_id;

        ut.expect(g_log_rec.username).to_(equal(v_actual.username));
        ut.expect(g_log_rec.os_user).to_(equal(v_actual.os_user));
        ut.expect(g_log_rec.instance).to_(equal(v_actual.instance));
        ut.expect(g_log_rec.sid).to_(equal(v_actual.sid));
        ut.expect(g_log_rec.serial).to_(equal(v_actual.serial));
        ut.expect(g_log_rec.log_source).to_(equal(v_actual.log_source));
        ut.expect(g_log_rec.line_no).to_(equal(v_actual.line_no));
        ut.expect(g_log_rec.message_type).to_(equal(v_actual.message_type));
        ut.expect(g_log_rec.message_group).to_(equal(v_actual.message_group));
        ut.expect(g_log_rec.message).to_(equal(v_actual.message));

        -- teardown
        remove_log_records('OVERRIDE_LINE_NO');

    end override_line_no;
   
    procedure long_message
    is
        v_actual skippy_logs%rowtype;
        v_last_id skippy_logs.id%type;
        v_first_id skippy_logs.id%type;
        v_message varchar2(32000);
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.LONG_MESSAGE';
        v_message := rpad( 'Skippy ', 7500, 'The Bush Kangaroo');
        
        
        -- Execute
        skippy.set_log_level('A');
        skippy.log(v_message);
        
        -- Validate
        
        -- last id
        select max(id)
        into v_last_id
        from skippy_logs
        where log_source = 'SKIPPY_LOG_UT.LONG_MESSAGE';

        select max(id)
        into v_first_id
        from skippy_logs
        where log_source = 'SKIPPY_LOG_UT.LONG_MESSAGE'
        and id < v_last_id;

        -- First chunk
        select *
        into v_actual
        from skippy_logs
        where id = v_first_id;
        
        ut.expect(g_log_rec.username).to_(equal(v_actual.username));
        ut.expect(g_log_rec.os_user).to_(equal(v_actual.os_user));
        ut.expect(g_log_rec.instance).to_(equal(v_actual.instance));
        ut.expect(g_log_rec.sid).to_(equal(v_actual.sid));
        ut.expect(g_log_rec.serial).to_(equal(v_actual.serial));
        ut.expect(g_log_rec.log_source).to_(equal(v_actual.log_source));
        ut.expect(g_log_rec.message_type).to_(equal(v_actual.message_type));
        ut.expect(v_actual.message_group).to_(be_null());
        ut.expect(substr(v_message, 1, 4000)).to_(equal(v_actual.message));
        
        -- Second message chunk
        select *
        into v_actual
        from skippy_logs
        where id = v_last_id;

        ut.expect(g_log_rec.username).to_(equal(v_actual.username));
        ut.expect(g_log_rec.os_user).to_(equal(v_actual.os_user));
        ut.expect(g_log_rec.instance).to_(equal(v_actual.instance));
        ut.expect(g_log_rec.sid).to_(equal(v_actual.sid));
        ut.expect(g_log_rec.serial).to_(equal(v_actual.serial));
        ut.expect(g_log_rec.log_source).to_(equal(v_actual.log_source));
        ut.expect(g_log_rec.message_type).to_(equal(v_actual.message_type));
        ut.expect(v_actual.message_group).to_(be_null());
        ut.expect(substr(v_message, 4001)).to_(equal(v_actual.message));

        -- teardown
        remove_log_records('LONG_MESSAGE');

    end long_message;    
   
    -- logging_disabled
    procedure logging_disabled
    is
        v_count pls_integer;
        v_id skippy_logs.id%type;
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.WRITE_DEFAULT_MESSAGE';
        g_log_rec.message := q'[What's that Skippy ?]';

        v_id := get_message_id;
        v_id := v_id + 1;
        
        -- Execute
        skippy.disable_logging;
        skippy.log(g_log_rec.message);
        
        -- Validate

        select count(*)
        into v_count
        from skippy_logs
        where id = v_id;

        ut.expect(v_count).to_(equal(0));
    end logging_disabled;

end skippy_log_ut;
/
    