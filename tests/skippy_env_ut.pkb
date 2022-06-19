create or replace package body skippy_env_ut as
    -- Globals
    g_current_version number;
    g_chunk_size number;
    g_start_id number;

    -- Helpers
    procedure set_globals
    is
    begin
        g_current_version := dbms_db_version.version + (dbms_db_version.release/10);
        g_chunk_size := 4000;
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
    

    -- environment variables
    procedure environment_variables
    is 
        v_session_val varchar2(4000);
        v_expected varchar2(32767) := null;
        v_actual varchar2(4000);
        v_chunks pls_integer;
        v_msg_id number;
        v_start pls_integer := 1;
    begin
        -- setup
        set_globals;
        
        for r_param in ( select parameter_name, version_no from skippy_userenv_parameters order by parameter_name) loop
            if r_param.version_no <= g_current_version then
                v_session_val := sys_context('userenv', r_param.parameter_name);
                if v_session_val is not null then
                    v_expected := v_expected||case when nvl(length(v_expected), 0) > 0 then ', ' end||r_param.parameter_name||' => '||v_session_val;
                end if;
            end if;
        end loop;
        -- See how many chunks the message should be in
        v_chunks := ceil( length( v_expected)/ g_chunk_size);
        -- Execute
        skippy.set_log_level('A');
        skippy.env;

        -- Validate
        select max(id) - v_chunks
        into v_msg_id
        from skippy_logs
        where log_source = 'SKIPPY_ENV_UT.ENVIRONMENT_VARIABLES'
        and log_ts >= systimestamp - (1/24/60);

        for i in 1..v_chunks loop
            select message
            into v_actual
            from skippy_logs
            where id = v_msg_id + v_chunks;

            ut.expect(substr(v_expected, v_start, g_chunk_size)).to_(equal(v_actual));
            v_start := v_start + g_chunk_size;
        end loop;  
        
        -- Teardown
        remove_log_records( 'ENVIRONMENT_VARIABLES');
    end environment_variables;
    
    -- override message type
    procedure override_msg_type
    is
        v_session_val varchar2(4000);
        v_expected varchar2(32767) := null;
        v_chunks pls_integer;
        v_msg_id number;
        v_start pls_integer := 1;

        v_msg_type skippy_message_types.cid%type := 'D';
        v_actual_type skippy_message_types.cid%type;
    begin
        -- setup
        set_globals;
        for r_param in ( select parameter_name, version_no from skippy_userenv_parameters order by parameter_name) loop
            if r_param.version_no <= g_current_version then
                v_session_val := sys_context('userenv', r_param.parameter_name);
                if v_session_val is not null then
                    v_expected := v_expected||case when nvl(length(v_expected), 0) > 0 then ', ' end||r_param.parameter_name||' => '||v_session_val;
                end if;
            end if;
        end loop;
        -- See how many chunks the message should be in
        v_chunks := ceil( length( v_expected)/ g_chunk_size);

        -- Execute
        skippy.set_log_level('A');
        skippy.env( i_msg_type => v_msg_type);

        -- Validate
        select max(id) - v_chunks
        into v_msg_id
        from skippy_logs
        where log_source = 'SKIPPY_ENV_UT.OVERRIDE_MSG_TYPE'
        and log_ts >= systimestamp - (1/24/60);

        for i in 1..v_chunks loop
            select message_type
            into v_actual_type
            from skippy_logs
            where id = v_msg_id + v_chunks;

            ut.expect(v_actual_type).to_(equal(v_msg_type));
            
            v_start := v_start + g_chunk_size;
        end loop;    
        
        -- Teardown
        remove_log_records( 'OVERRIDE_MSG_TYPE');
    end override_msg_type;    
    
    -- specify message group
    procedure specify_msg_group is 
        v_session_val varchar2(4000);
        v_expected varchar2(32767) := null;
        v_chunks pls_integer;
        v_msg_id number;
        v_start pls_integer := 1;

        v_group varchar2(30) := 'COURT';
        v_actual_group varchar2(30);
    begin
        -- setup
        set_globals;
        for r_param in ( select parameter_name, version_no from skippy_userenv_parameters order by parameter_name) loop
            if r_param.version_no <= g_current_version then
                v_session_val := sys_context('userenv', r_param.parameter_name);
                if v_session_val is not null then
                    v_expected := v_expected||case when nvl(length(v_expected), 0) > 0 then ', ' end||r_param.parameter_name||' => '||v_session_val;
                end if;
            end if;
        end loop;
        -- See how many chunks the message should be in
        v_chunks := ceil( length( v_expected)/ g_chunk_size);

        -- Execute
        skippy.set_log_level('A');        
        skippy.env( i_group => v_group);

        -- Validate
        select max(id) - v_chunks
        into v_msg_id
        from skippy_logs
        where log_source = 'SKIPPY_ENV_UT.SPECIFY_MSG_GROUP'
        and log_ts >= systimestamp - (1/24/60);

        for i in 1..v_chunks loop
            select message_group
            into v_actual_group
            from skippy_logs
            where id = v_msg_id + v_chunks;

            ut.expect(v_actual_group).to_(equal(v_group));
            
            v_start := v_start + g_chunk_size;
        end loop;    

        -- Teardown
        remove_log_records('SPECIFY_MSG_GROUP');
        
    end specify_msg_group;
    
    
end skippy_env_ut;
/