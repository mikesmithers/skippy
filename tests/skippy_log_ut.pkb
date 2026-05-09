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
        g_log_rec.message_clob := null;
        
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
        
        -- teardown
        skippy.set_log_level('A');
        
    end logging_disabled;

    --%test(Interactive output enabled);
    procedure output_enabled
    is
        v_count pls_integer;

        v_msg skippy_logs.message%type;
        v_status pls_integer;
        
        v_actual_log skippy_logs%rowtype;
    begin
        -- setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.OUTPUT_ENABLED';
        g_log_rec.message := 'Wallaby will be';

        -- execute
        skippy.enable_output;
        skippy.log(g_log_rec.message);
        dbms_output.get_line(v_msg, v_status);
        
        -- Validate
        select *
        into v_actual_log
        from skippy_logs
        where id = get_message_id;
        
        -- DBMS_OUTPUT check
        ut.expect(v_status).to_(equal(0));
        ut.expect( v_msg).to_(equal(g_log_rec.message));
        
        -- Log record check
        ut.expect(g_log_rec.log_source).to_(equal(v_actual_log.log_source));
        ut.expect(g_log_rec.message).to_(equal(v_actual_log.message));

        -- teardown
        remove_log_records('OUTPUT_ENABLED');
    end output_enabled;
        
        
    --%test(Interactive output disabled);
    procedure output_disabled
    is
        v_count pls_integer;
        v_id skippy_logs.id%type;

        v_msg skippy_logs.message%type;
        v_status pls_integer;
        
        v_actual_log skippy_logs%rowtype;
    begin
        -- setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.OUTPUT_DISABLED';
        g_log_rec.message := 'Wallaby will be';

        v_id := get_message_id;
        v_id := v_id + 1;
    
        -- execute
        skippy.disable_output;
        skippy.log(g_log_rec.message);
        dbms_output.get_line(v_msg, v_status);
        
        -- Validate
        select *
        into v_actual_log
        from skippy_logs
        where id = get_message_id;
        
        -- DBMS_OUTPUT check
        ut.expect(v_status).to_(equal(1));
        ut.expect( v_msg).to_(be_null());
        
        -- Log record check
        ut.expect(g_log_rec.log_source).to_(equal(v_actual_log.log_source));
        ut.expect(g_log_rec.message).to_(equal(v_actual_log.message));

        -- teardown
        remove_log_records('OUTPUT_DISABLED');
    end output_disabled;    

    -- Write to the message_clob column explicitly
    procedure write_message_clob 
    is 
        v_actual_log skippy_logs%rowtype;
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.WRITE_MESSAGE_CLOB';
        g_log_rec.message := 'CLOB Message Test';
        g_log_rec.message_clob := 'Should fit into a CLOB';
        
        -- execute
        skippy.log(g_log_rec.message, i_extra => g_log_rec.message_clob);
        
        -- Validate
        select *
        into v_actual_log
        from skippy_logs
        where id = get_message_id;

        ut.expect(g_log_rec.log_source).to_(equal(v_actual_log.log_source));
        ut.expect(g_log_rec.message).to_(equal(v_actual_log.message));
        ut.expect(g_log_rec.message_clob).to_(equal(v_actual_log.message_clob));
        -- teardown
        remove_log_records('WRITE_MESSAGE_CLOB');
        
    end write_message_clob;

    procedure long_message
    is
        v_actual skippy_logs%rowtype;
        v_message varchar2(32000);

        v_expected_start varchar2(4000);        
        v_expected_len pls_integer;
        v_actual_start varchar2(4000);
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.LONG_MESSAGE';
        v_message := rpad( 'Skippy ', 7500, 'The Bush Kangaroo');
        v_expected_start := substr(v_message, 1,24);
        v_expected_len := length(v_message);
        
        -- Execute
        skippy.set_log_level('A');
        skippy.log(v_message);
        
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
        ut.expect(v_actual.message).to_(equal('Message stored in MESSAGE_CLOB'));
        --
        -- Cannot use the equal matcher to compare clob to varchar in UtPLSQL 3.14
        -- so...
        v_actual_start := substr(v_actual.message_clob,1,24);
        ut.expect(v_actual_start).to_(equal(v_expected_start));
        ut.expect(length(v_actual.message_clob)).to_(equal(v_expected_len));
        
        -- teardown
        remove_log_records('LONG_MESSAGE');

    end long_message;    
    
    -- Log parameters with a message
    procedure params_with_message
    is
        t_params skippy.t_params_type;
        v_expected_params clob;
        v_actual_message skippy_logs.message%type;
        v_actual_extra skippy_logs.message_clob%type;
        
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.PARAMS_WITH_MESSAGE';
        g_log_rec.message := 'Start';
        
        -- NOTE - irrespectie of the order in which these variables are initialised they
        -- will be stored in alphabetical order of the key
        
        t_params('i_varchar_param') := q'[These aren't the Roos you're looking for]';
        t_params('i_number_param') := -66;
        t_params('i_date_param') := date '2026-05-04';
        t_params('i_bool_param') := 'N';
        
        v_expected_params := 
            'i_bool_param => '||t_params('i_bool_param')||chr(10)
            ||'i_date_param => '||t_params('i_date_param')||chr(10)
            ||'i_number_param => '||t_params('i_number_param')||chr(10)
            ||'i_varchar_param => '||t_params('i_varchar_param');

        -- Execute
        skippy.set_log_level('A');            
        skippy.log(g_log_rec.message,i_params => t_params);
        
        -- Validate
        select message, message_clob
        into v_actual_message, v_actual_extra
        from skippy_logs
        where id = get_message_id;
        
        ut.expect(g_log_rec.message).to_(equal(v_actual_message));
        ut.expect(v_expected_params).to_(equal(v_actual_extra));

        -- Teardown
        remove_log_records('PARAMS_WITH_MESSAGE');
    end params_with_message;    
    
    -- Log parameters with no message
    procedure params_no_message 
    is 
        t_params skippy.t_params_type;
        v_expected_params varchar2(4000);
        v_actual_message skippy_logs.message%type;
        v_actual_extra skippy_logs.message_clob%type;
        
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.PARAMS_NO_MESSAGE';
        
        -- NOTE - irrespective of the order in which these variables are initialised they
        -- will be stored in alphabetical order of the key
        
        t_params('last_jedi') := 'Luke Skywalker';
        
        v_expected_params := 'last_jedi => '||t_params('last_jedi');
           
        -- Execute
        skippy.set_log_level('A');
        skippy.log(i_params => t_params);
        
        -- Validate
        select message, message_clob
        into v_actual_message, v_actual_extra
        from skippy_logs
        where id = get_message_id;
        
        ut.expect(v_actual_message).to_(equal(v_expected_params));
        ut.expect(v_actual_extra).to_(be_null());

        -- Teardown
        remove_log_records('PARAMS_NO_MESSAGE');
    end params_no_message;    
    
    -- log a long message and parameter
    procedure long_message_and_param
    is
        v_message clob;
        v_expected_end varchar2(4000);
        v_expected_len pls_integer;
        
        t_params skippy.t_params_type;
        v_expected_params varchar2(4000);
        
        v_actual_message varchar2(4000);
        v_actual_message_clob clob;
        v_actual_start varchar2(4000);
        v_actual_end varchar2(4000);

    begin
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.LONG_MESSAGE_AND_PARAM';

        v_message := rpad( 'Skippy ', 4010, 'The Bush Kangaroo');
        
        t_params('phantom_menace') := 'Darth Sidious';
        t_params('attack_of_the_clones') := 'Darth Tyranus';
        
        v_expected_params := 'attack_of_the_clones => '||t_params('attack_of_the_clones')||chr(10)||'phantom_menace => '||t_params('phantom_menace');

        v_expected_end := substr(v_message, -4);
        -- Add 1 to account for the CRLF between the two elements of the message
        v_expected_len := length(v_message) + length(v_expected_params) + 1;        
        
        -- Execute
        skippy.set_log_level('A');
        skippy.log(v_message, i_params => t_params);
        
        -- Validate
        select message, message_clob
        into v_actual_message, v_actual_message_clob
        from skippy_logs
        where id = get_message_id;
        
        ut.expect(v_actual_message).to_(equal('Message stored in MESSAGE_CLOB'));
        --
        -- Cannot use the equal matcher to compare clob to varchar in UtPLSQL 3.14
        -- so...
        v_actual_start := substr(v_actual_message_clob,1, length(v_expected_params));
        v_actual_end := substr(v_actual_message_clob, -4);
        
        ut.expect(v_actual_start).to_(equal(v_expected_params));
        ut.expect(v_actual_end).to_(equal(v_expected_end));
        ut.expect(length(v_actual_message_clob)).to_(equal(v_expected_len));
        
        -- Teardown
        remove_log_records('LONG_MESSAGE_AND_PARAM');
        
    end long_message_and_param;    

    -- log a long message and a clob
    procedure long_message_and_clob
    is
        v_message clob;
        v_extra clob;
        v_message_start varchar2(4000);
        v_expected_end varchar2(25);
        v_expected_len pls_integer;
        v_actual_message varchar2(250);
        v_actual_message_clob clob;
        v_actual_start varchar2(4000);
        v_actual_end varchar2(25);
    begin

       -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.LONG_MESSAGE_AND_CLOB';

        v_message := rpad( 'Skippy ', 4010, 'The Bush Kangaroo');
        v_message_start := substr(v_message, 1, 4000);
        v_extra := q'[What's that Skippy ?]';
        
        v_expected_end := substr(v_extra, -8);
        -- Add 1 to account for the CRLF between the two elements of the message
        v_expected_len := length(v_message) + length(v_extra) + 1;        
        
        -- Execute
        skippy.set_log_level('A');
        skippy.log(v_message, i_extra => v_extra);
        
        -- Validate
        select message, message_clob
        into v_actual_message, v_actual_message_clob
        from skippy_logs
        where id = get_message_id;
        
        ut.expect(v_actual_message).to_(equal('Message stored in MESSAGE_CLOB'));
        --
        -- Cannot use the equal matcher to compare clob to varchar in UtPLSQL 3.14
        -- so...
        v_actual_start := substr(v_actual_message_clob,1, 4000);
        v_actual_end := substr(v_actual_message_clob, -8);
        
        ut.expect(v_actual_start).to_(equal(v_message_start));
        ut.expect(v_actual_end).to_(equal(v_expected_end));
        ut.expect(length(v_actual_message_clob)).to_(equal(v_expected_len));
        
        -- Teardown
        remove_log_records('LONG_MESSAGE_AND_CLOB');
    end long_message_and_clob;

    -- log a long parameter with no message
    procedure log_long_params 
    is 
        v_message varchar2(100);
        
        t_params skippy.t_params_type;   
        v_expected_params clob;
        v_expected_start varchar2(50);
        v_expected_end varchar2(50);
        v_expected_len pls_integer;
        
        v_actual clob;
        v_actual_start varchar2(50);
        v_actual_end varchar2(50);

    begin 

        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.LOG_LONG_PARAMS';
        
        t_params('Down') := rpad('Down', 4000, 'x');
        t_params('A') := 'a';
        t_params('Mineshaft') := 'Mineshaft';

        v_expected_params := 'A => '||t_params('A')||chr(10)||'Down => '||t_params('Down')||chr(10)||'Mineshaft => '||t_params('Mineshaft');
        v_expected_start := substr(v_expected_params,1,4);
        v_expected_end := substr(v_expected_params, -9);
        v_expected_len := length(v_expected_params);
        
        -- Execute
        skippy.set_log_level('A');
        skippy.log(i_params => t_params);
        
        -- Validate
        select message, message_clob
        into v_message, v_actual
        from skippy_logs
        where id = get_message_id;
        
        v_actual_start := substr(v_actual,1,4);
        v_actual_end := substr(v_actual, -9);
        
        ut.expect(v_message).to_(equal('Message stored in MESSAGE_CLOB'));
        ut.expect(v_expected_start).to_(equal(v_actual_start));
        ut.expect(v_expected_end).to_(equal(v_actual_end));
        ut.expect(v_expected_len).to_(equal(length(v_actual)));

        -- Teardown
        remove_log_records('LOG_LONG_PARAMS');
        

    end log_long_params;

/* Got to here */    
    -- log a long parameter and a clob
    procedure long_param_and_clob 
    is 
        v_message varchar2(100);
        t_params skippy.t_params_type;   
        v_expected_params clob;
        v_expected_start varchar2(50);
        v_expected_end varchar2(50);
        v_expected_len pls_integer;
        
        v_extra clob := 'Morning everyone';
        
        v_actual clob;
        v_actual_start varchar2(50);
        v_actual_end varchar2(50);
    
    
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.LONG_PARAM_AND_CLOB';
        
        t_params('Down') := rpad('Down', 4000, 'x');
        t_params('A') := 'a';
        t_params('Mineshaft') := 'Mineshaft';

        v_expected_params := 'A => '||t_params('A')||chr(10)||'Down => '||t_params('Down')||chr(10)||'Mineshaft => '||t_params('Mineshaft');
        v_expected_start := substr(v_expected_params,1,4);
        v_expected_end := v_extra;
        v_expected_len := length(v_expected_params) + length(v_extra) + 1;
        
        
        -- Execute
        skippy.set_log_level('A');        
        skippy.log(i_params => t_params, i_extra => v_extra);
        
        -- Validate
        select message, message_clob
        into v_message, v_actual
        from skippy_logs
        where id = get_message_id;
        
        v_actual_start := substr(v_actual,1,4);
        v_actual_end := substr(v_actual, -16);

        ut.expect(v_message).to_(equal('Message stored in MESSAGE_CLOB'));        
        ut.expect(v_expected_start).to_(equal(v_actual_start));
        ut.expect(v_expected_end).to_(equal(v_actual_end));
        ut.expect(v_expected_len).to_(equal(length(v_actual)));
        
        -- Teardown
        remove_log_records('LONG_PARAM_AND_CLOB');        

    end long_param_and_clob;
    
    -- log a long message, long parameter and clob
    procedure all_long 
    is 
        v_message clob;
        t_params skippy.t_params_type;
        v_extra clob;
        
        v_expected_params varchar2(4000);
        v_expected_item1 varchar2(4000);
        v_expected_item2 varchar2(4000);
        v_expected_item3 varchar2(4000);
        
        v_expected_len pls_integer;
        v_actual skippy_logs%rowtype;
        
        v_actual_item1 varchar2(4000);
        v_actual_item2 varchar2(4000);
        v_actual_item3 varchar2(4000);
        
    begin 

        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.ALL_LONG';

        v_message := rpad('Skippy ', 4010, 'the bush Kangaroo');
        v_extra := 'Happy as a Kookaburra laughing in a tree';
        t_params('hippity') := 'hop';
    
        v_expected_params := 'hippity => '||t_params('hippity');

        v_expected_item1 := v_expected_params;
        v_expected_item2 := substr(v_message,1,6);
        v_expected_item3 := v_extra;
        
        v_expected_len := length(v_message) + length(v_extra) + length(v_expected_params) + 2;
        
        -- Execute
        skippy.set_log_level('A');
        skippy.log(v_message, i_params => t_params, i_extra => v_extra);
        
        -- Validate
        select *
        into v_actual
        from skippy_logs
        where id = get_message_id;
        
        v_actual_item1 := substr(v_actual.message_clob,1 ,instr(v_actual.message_clob, chr(10),1,1) -1);
        v_actual_item2 := substr(v_actual.message_clob, instr(v_actual.message_clob, chr(10),1,1) +1, length(v_expected_item2));
        v_actual_item3 := substr(v_actual.message_clob, instr( v_actual.message_clob, chr(10),1,2)+1);

        ut.expect(v_actual_item1).to_(equal(v_expected_item1)); 
        ut.expect( v_actual_item2).to_(equal(v_expected_item2));
        ut.expect( v_actual_item3).to_(equal(v_expected_item3));
        ut.expect( length(v_actual.message_clob)).to_(equal(v_expected_len));
        
        -- Teardown 
        remove_log_records('ALL_LONG');        
        
    end all_long;

    -- Log a conventional length message, parameters and extra
    procedure log_all 
        is 
        v_message varchar2(4000);
        t_params skippy.t_params_type;
        v_extra varchar2(4000);
        
        v_expected_params varchar2(4000);
        
        v_expected_len pls_integer;
        v_actual skippy_logs%rowtype;
        
        v_actual_params varchar2(4000);
        v_actual_extra varchar2(4000);
        
    begin 

        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.LOG_ALL';

        v_message := 'Skippy the bush kangaroo';
        t_params('hippity') := 'hop';
        v_extra := 'Happy as a Kookaburra laughing in a tree';

    
        v_expected_params := 'hippity => '||t_params('hippity');

        v_expected_len := length(v_extra) + length(v_expected_params) + 1;
        
        -- Execute
        skippy.set_log_level('A');
        skippy.log(v_message, i_params => t_params, i_extra => v_extra);
        
        -- Validate
        select *
        into v_actual
        from skippy_logs
        where id = get_message_id;
        
        v_actual_params := substr(v_actual.message_clob, 1, length(v_expected_params));
        v_actual_extra := substr(v_actual.message_clob, instr(v_actual.message_clob, chr(10),1,1) + 1);

        ut.expect( v_actual.message).to_(equal(v_message)); 
        ut.expect( v_actual_params).to_(equal(v_expected_params));
        ut.expect( v_actual_extra).to_(equal(v_extra));
        ut.expect( length(v_actual.message_clob)).to_(equal(v_expected_len));
        
        -- Teardown 
        remove_log_records('LOG_ALL');        
        

    end log_all;
    
    -- Log Extra only
    procedure extra_only 
    is 
        v_extra varchar2(4000); 
        v_actual_extra varchar2(4000);
        
        v_actual skippy_logs%rowtype;
        
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.EXTRA_ONLY';

        v_extra := 'Vegimite sandwich anyone ?';
        
        -- Execute
        skippy.set_log_level('A');
        skippy.log(i_extra => v_extra);
        
        -- Validate
        select *
        into v_actual
        from skippy_logs
        where id = get_message_id;
        
        v_actual_extra := v_actual.message_clob;
        
        ut.expect( v_actual.message).to_(equal('Message stored in MESSAGE_CLOB')); 
        ut.expect( v_actual_extra).to_(equal(v_extra));
        
        -- Teardown 
        remove_log_records('EXTRA_ONLY');        
        
    end extra_only;    
    
    -- all blank
    procedure all_blank 
    is 
        v_actual skippy_logs%rowtype;
    begin 
        -- Setup
        set_globals;
        g_log_rec.log_source := 'SKIPPY_LOG_UT.ALL_BLANK';
        
        -- Execute
        skippy.log;
        
        -- Validate
        select *
        into v_actual
        from skippy_logs
        where id = get_message_id;
        
        ut.expect(v_actual.message).to_(be_null());
        
        -- Teardown 
        remove_log_records('ALL_BLANK');        

    end all_blank;
    

end skippy_log_ut;
/
    