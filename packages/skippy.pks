create or replace package skippy as

    GC_MAX_MSG_LEN constant pls_integer := 4000; -- max length of a message

    function db_version return number;
    
    procedure set_msg_group( i_group in skippy_logs.message_group%type);

    procedure set_log_level( i_level in skippy_message_types.cid%type);
    procedure disable_logging;

    -- Return the current Message Group ( i_setting = 'GROUP') or Logging level ( i_setting = 'LEVEL')
    -- for this session
    --
    function current_setting( i_setting in varchar2) return varchar2;
    
    -- Overloaded procedure to facilitate building a parameter list string
    -- Points to note 
    -- 1 - using the base PL/SQL type for the type family :
    --  see https://docs.oracle.com/en/database/oracle/oracle-database/18/lnpls/plsql-predefined-data-types.html
    -- 2 - since 12c, passing a null value to an overloaded procedure no longer causes a PLS-00307 : too many declarations error.
    -- provided the type of the parameter is known.
    --
    procedure add_param( i_name in varchar2, i_value in varchar2, io_list in out varchar2);
    procedure add_param( i_name in varchar2, i_value in number, io_list in out varchar2);
    procedure add_param( i_name in varchar2, i_value in date, io_list in out varchar2);
    procedure add_param( i_name in varchar2, i_value in boolean, io_list in out varchar2);
    
    -- Usage examples :
    -- skippy.log(q'[What's that Skippy ?]');
    -- skippy.log('Down a mine shaft ?', 'W');
    -- skippy.log('Skippy the Bush Kangaroo', i_source => 'mypackage.procedure');
    -- skippy.log('What is a Wallaby', i_group => 'DAILY_BATCH_RUN');
    
    procedure log(
        i_msg in varchar2,
        i_msg_type in skippy_logs.message_type%type default 'I',
        i_source in skippy_logs.log_source%type default null,
        i_line_no in pls_integer default null,
        i_group in skippy_logs.message_group%type default null);
        
    -- Log the current sys_context('userenv') parameter settings where they are not null
    procedure env(
        i_msg_type in skippy_logs.message_type%type default 'I', 
        i_group in skippy_logs.message_group%type default null);    
    
    -- Log the current error stack
    procedure err( i_group in skippy_logs.message_group%type default null);
end skippy;
/
