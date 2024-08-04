create or replace package body skippy as

    -- Private
    g_level_num skippy_message_types.log_level%type := 999;
    g_level_cid skippy_message_types.cid%type := 'A';
    g_msg_group skippy_logs.message_group%type;
    
    function logit( i_msg_type in varchar2)
        return boolean
    is
        v_level number;
    begin
        select log_level
        into v_level
        from skippy_message_types
        where cid = upper(i_msg_type);
        
        return v_level <= g_level_num;
    exception when no_data_found then
        return true;
    end logit;    
    
    function legacy_members( 
        i_owner in all_identifiers.owner%type,
        i_object in all_identifiers.object_name%type,
        i_line in all_identifiers.line%type)
        return varchar2
        -- In 11g, owa_util.who_called_me only gives the name of the calling package, not the member
        -- therefore, we need to see if we can find it another way
    is
        v_rtn all_identifiers.name%type;
    begin
        with package_members as (
            select name, line
            from all_identifiers
            where type in ('FUNCTION', 'PROCEDURE')
            and usage = 'DEFINITION'
            and object_type = 'PACKAGE BODY'
            and owner = upper(i_owner)
            and object_name = upper(i_object))
        select name
        into v_rtn
        from package_members
        where line = ( select max(line) from package_members where line < i_line);
        
        return v_rtn;
    exception when no_data_found then
        -- Package not compiled with plscope_settings of identifiers:all so we can't get the member this way
        return null;
    end legacy_members;    
    -- Public 
    
    function db_version return number
    is
    begin
        return dbms_db_version.version + (dbms_db_version.release/10);
    end db_version;    
    
    procedure set_msg_group( i_group in skippy_logs.message_group%type)
    is
    begin
        g_msg_group := i_group;
    end set_msg_group;    
    
    procedure set_log_level( i_level in skippy_message_types.cid%type)
    is
    begin
        select log_level
        into g_level_num
        from skippy_message_types
        where cid = upper(i_level);
        
        g_level_cid := upper(i_level);
    exception when no_data_found then
        raise_application_error(-20901, i_level||' is not a valid CID in skippy_message_types');
    end set_log_level;
    
    procedure disable_logging
    is
    begin
        g_level_num := 0;
        g_level_cid := null;
    end disable_logging;
    
    procedure enable_output 
    is   
    begin 
        g_interactive := 'Y';
    end enable_output;

    procedure disable_output 
    is    
    begin 
        g_interactive := 'N';
    end disable_output;

    function current_setting( i_setting in varchar2) return varchar2
    is
    begin
        if upper(i_setting) = 'GROUP' then
            return g_msg_group;
        elsif upper(i_setting) = 'LEVEL' then
            return g_level_cid;
        else
            raise_application_error(-20902, i_setting||q'[ is not recognized. Valid values are GROUP or LEVEL.]');
        end if;
    end current_setting;
    
    procedure add_param( i_name in varchar2, i_value in varchar2, io_list in out varchar2)
    is
    begin
        if io_list is not null then
            io_list := io_list||', ';
        end if;
        io_list := io_list||i_name||' => '||i_value;
    end add_param;
    
    procedure add_param( i_name in varchar2, i_value in number, io_list in out varchar2)
    is
    begin
        if io_list is not null then
            io_list := io_list||', ';
        end if;
        io_list := io_list||i_name||' => '||to_char( i_value);
    end add_param;
    
    procedure add_param( i_name in varchar2, i_value in date, io_list in out varchar2)
    is
    begin
        if io_list is not null then
            io_list := io_list||', ';
        end if;
        io_list := io_list||i_name||' => '||to_char( i_value, sys_context('userenv', 'nls_date_format'));
    end add_param;    
    
    procedure add_param( i_name in varchar2, i_value in boolean, io_list in out varchar2)
    is
    begin
        if io_list is not null then
            io_list := io_list||', ';
        end if;
        io_list := io_list||i_name||' => '||case when i_value then 'TRUE' else 'FALSE' end;
    end add_param;    
    
    
    procedure log(
        i_msg in varchar2,
        i_msg_type in skippy_logs.message_type%type default 'I',
        i_source in skippy_logs.log_source%type default null,
        i_line_no in pls_integer default null,
        i_group in skippy_logs.message_group%type default null)
    is
        v_owner user_users.username%type := null;
        v_name user_objects.object_name%type := null;
        v_line number := null;
        v_type user_objects.object_type%type := null;
        
        v_start pls_integer := 1;
        v_len pls_integer;
        v_member varchar2(128);
        
        v_msg_chunk skippy_logs.message%type;
        
        pragma autonomous_transaction;
    begin
        if not logit( i_msg_type) then
            return;
        end if;    

        if i_source is null then
            owa_util.who_called_me(
                owner => v_owner,
                name => v_name,
                lineno => v_line,
                caller_t => v_type);
                
        else
            v_name := i_source;
            v_line := i_line_no;
        end if;    
      
        if v_type = 'PACKAGE BODY' and dbms_db_version.ver_le_11 
            and instr(v_name, '.',1,1) = 0
        then
            v_member := legacy_members( v_owner, v_name, v_line);
            if v_member is not null then
                v_name := v_name||'.'||v_member;
            end if;
        end if;
        
        v_len := nvl( length( i_msg), 0);

        while v_start <= v_len loop
            -- For 11g, we need an intermediate variable to store any long messages
            -- as otherwise, we'll get ORA-01461 : Can only bind a long variable for insert into a LONG column
            v_msg_chunk := substr(i_msg, v_start, GC_MAX_MSG_LEN);
            insert into skippy_logs(
                id,
                log_ts,
                username,
                os_user,
                instance,
                sid,
                serial,
                log_source,
                line_no,
                message_type,
                message_group,
                message)
            values(
                skippy_logs_id_seq.nextval, -- id,
                systimestamp, -- log_ts
                sys_context('userenv', 'session_user'), -- username
                sys_context('userenv', 'os_user'), -- os_user
                sys_context('userenv', 'instance'), -- instance
                sys_context('userenv', 'sid'), -- sid
                dbms_debug_jdwp.current_session_serial, -- serial#
                v_name, -- log_source
                v_line, -- line_no
                nvl(i_msg_type, 'A'), -- message_type
                nvl(i_group, g_msg_group), -- message_group
                v_msg_chunk); -- message

            v_start := v_start + GC_MAX_MSG_LEN;
            commit;

            -- Output to console if enabled
            -- This is in a nested block so that any error is non-fatal
            begin
                if g_interactive = 'Y' then
                    dbms_output.put_line(v_msg_chunk);
                end if;
            end;
        end loop;    
    exception
        when others then null;
    end log;    
    
    procedure env( 
        i_msg_type in skippy_logs.message_type%type default 'I', 
        i_group in skippy_logs.message_group%type default null)
    is

        v_owner user_users.username%type;
        v_source skippy_logs.log_source%type;
        v_line pls_integer;
        v_type varchar2(128);
       
        v_member varchar2(128);

        v_paramlist varchar2(32767);
    begin
    
        owa_util.who_called_me(
            owner => v_owner,
            name => v_source,
            lineno => v_line,
            caller_t => v_type);

        -- If we're on 11g then we'll need to find a package member as well
        if v_type = 'PACKAGE BODY' and dbms_db_version.ver_le_11 then
            v_member := legacy_members( v_owner, v_source, v_line);
            if v_member is not null then
                v_source := v_source||'.'||v_member;
            end if;
        end if;

        for r_param in (
            select parameter_name, 
                sys_context('userenv', parameter_name) as session_value
            from skippy_userenv_parameters
            where version_no <= skippy.db_version
            order by 1)
        loop
            -- We need to check the null value here rather than in the query as otherwise we
            -- run into ORA-02003 : Invalid USERENV parameter ( up to and including 18c)
            if r_param.session_value is not null then
                add_param( r_param.parameter_name, r_param.session_value, v_paramlist);
            end if;    
        end loop;
        log( 
            i_msg => v_paramlist, 
            i_msg_type => i_msg_type, 
            i_source => v_source,
            i_line_no =>  v_line,
            i_group => i_group);
    end env;    
    
    function get_err return varchar2
    is
    begin 
        return sqlerrm||chr(10)||dbms_utility.format_error_backtrace;
    end get_err;

    procedure err( i_group in skippy_logs.message_group%type default null)
    is
        v_msg varchar2(4000);
        v_owner user_users.username%type;
        v_source skippy_logs.log_source%type;
        v_line pls_integer;
        v_type varchar2(128);
        
        v_member varchar2(128);
        
    begin
        v_msg := sqlerrm||chr(10)||dbms_utility.format_error_backtrace;
        
        owa_util.who_called_me(
            owner => v_owner,
            name => v_source,
            lineno => v_line,
            caller_t => v_type);

        -- If we're on 11g then we'll need to find a package member as well
        if v_type = 'PACKAGE BODY' and dbms_db_version.ver_le_11 then
            v_member := legacy_members( v_owner, v_source, v_line);
            if v_member is not null then
                v_source := v_source||'.'||v_member;
            end if;
        end if;
        log(
            i_msg => v_msg, 
            i_msg_type => 'E', 
            i_source => v_source, 
            i_line_no => v_line,
            i_group => i_group);
    end err;    
end skippy;
/