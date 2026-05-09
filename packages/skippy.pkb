create or replace package body skippy as

    -- Private
    g_crlf constant char(1 char) := chr(10);
    
    g_param_separator constant varchar2(4 char) :=  ' => ';
    g_level_num skippy_message_types.log_level%type := 999;
    g_level_cid skippy_message_types.cid%type := 'A';
    g_msg_group skippy_logs.message_group%type;
    
    function format_params_from_array( i_params in t_params_type ) 
        return skippy_logs.message_clob%type 
    is
       v_retval skippy_logs.message_clob%type;
       v_key    paramname_type := i_params.first;
    begin
       
       <<input_parameters>>
       while v_key is not null
       loop
          v_retval := v_retval || g_crlf || v_key || g_param_separator || i_params(v_key);
          v_key := i_params.next(v_key);
       end loop input_parameters;
       
       return trim(g_crlf from v_retval);
       
    end format_params_from_array;

    function logit( i_msg_type in varchar2)
        return boolean deterministic
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
        io_list := io_list||i_name||g_param_separator||i_value;
    end add_param;

    procedure add_param( i_name in varchar2, i_value in number, io_list in out varchar2)
    is
    begin
        if io_list is not null then
            io_list := io_list||', ';
        end if;
        io_list := io_list||i_name||g_param_separator||to_char( i_value);
    end add_param;

    procedure add_param( i_name in varchar2, i_value in date, io_list in out varchar2)
    is
    begin
        if io_list is not null then
            io_list := io_list||', ';
        end if;
        io_list := io_list||i_name||g_param_separator||to_char( i_value, sys_context('userenv', 'nls_date_format'));
    end add_param;

    procedure add_param( i_name in varchar2, i_value in boolean, io_list in out varchar2)
    is
    begin
        if io_list is not null then
            io_list := io_list||', ';
        end if;
        io_list := io_list||i_name||g_param_separator||case when i_value then 'TRUE' else 'FALSE' end;
    end add_param;


    procedure log(
        i_msg in varchar2,
        i_msg_type in skippy_logs.message_type%type default 'I',
        i_source in skippy_logs.log_source%type default null,
        i_line_no in pls_integer default null,
        i_group in skippy_logs.message_group%type default null,
        i_extra in clob default null,
        i_params in t_params_type default t_params_type())
    is
        v_owner user_users.username%type := null;
        v_name user_objects.object_name%type := null;
        v_line number := null;
        v_type user_objects.object_type%type := null;

        v_start pls_integer := 1;
        v_len pls_integer;
        v_member varchar2(128);

        v_msg skippy_logs.message%type;
        v_msg_length pls_integer;
        v_param_length pls_integer;
        v_have_extra boolean;
        v_params skippy_logs.message_clob%type;
        v_extra clob;

        C_EXTRA_MESSAGE constant varchar2(50) := 'Message stored in MESSAGE_CLOB';        
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
 
 
        --
        -- Determine the message contents and where to put everything
        --
        v_msg_length := nvl(length(i_msg), 0);

        --
        -- Nested block to isolate any exceptions and ensure that we log what we can
        --
        begin
            v_params := case when i_params.count > 0 then format_params_from_array(i_params=>i_params) end;
        exception when others then
            v_params := 'Error reading i_params : '||get_err;
        end;
        
        v_param_length := nvl(length(v_params), 0);

        v_have_extra := i_extra is not null;

        -- If we have a message check that it will fit into the MESSAGE column
        if v_msg_length between 1 and GC_MAX_MSG_LEN then
            v_msg := i_msg;
        end if;    
    
        -- I_PARAMS parameters may be stored either in the MESSAGE or the MESSAGE_CLOB column.
        -- If the message is going into the message_clob column then the parameters will be stored BEFORE the message.
        if v_param_length between 1 and GC_MAX_MSG_LEN then
            if v_msg_length = 0 then
                v_msg := v_params;
            else
                v_msg := nvl(v_msg, C_EXTRA_MESSAGE);
                v_extra := v_params;
            end if;
        elsif v_param_length > GC_MAX_MSG_LEN then 
            v_msg := nvl(v_msg, C_EXTRA_MESSAGE);
            v_extra := v_extra||case when v_extra is not null then g_crlf end|| v_params;
        end if;

        -- Message too long to go into MESSAGE so put it in MESSAGE_CLOB.
        -- It will appear AFTER any parameters
        if v_msg_length > GC_MAX_MSG_LEN then
            v_msg := nvl(v_msg, C_EXTRA_MESSAGE);
            v_extra := v_extra||case when v_extra is not null then g_crlf end ||i_msg;
        end if;    
    
        -- I_EXTRA parameter
        if v_have_extra then 
            v_msg := nvl(v_msg, C_EXTRA_MESSAGE);
            v_extra := v_extra||case when v_extra is not null then g_crlf end|| i_extra;
        end if;

        insert into skippy_logs
        (
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
            message,
            message_clob
        )
        values
        (
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
            v_msg,  -- message
            v_extra -- extra
        );
        
        commit;
        
        -- Output to console if enabled
        -- This is in a neseted block so that any error is non-fatal
        begin
            if g_interactive = 'Y' then
                dbms_output.put_line(v_msg);
            end if;
        end;    

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
