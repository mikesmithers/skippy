create or replace package body demo as
    procedure jill
    is
    begin
        -- Default usage for writing a log message
        skippy.log('Morning everyone !');
    end jill;    
        
    procedure boomer
    is
    begin 
        -- set the group for the current session. Log messages will be assigned to this group
        -- unless the group is overridden
        skippy.set_msg_group('TROUPE');
        
        skippy.log(q'[G'day mate]');
        
        -- Log the current not null sys_context userenv settings
        skippy.env;
    end boomer;    

    procedure flyer( 
        i_string in varchar2 default 'Skippy', 
        i_number in number default 91,
        i_date in date default to_date('19680502', 'YYYYMMDD'),
        i_boolean in boolean default true)
    is
        v_paramlist varchar2(4000);  
    begin
        -- build a list of parameter values to log
        skippy.add_param( 'I_STRING', i_string, v_paramlist);
        skippy.add_param( 'I_NUMBER', i_number, v_paramlist);
        skippy.add_param( 'I_DATE', i_date, v_paramlist);
        skippy.add_param( 'I_BOOLEAN', i_boolean, v_paramlist);

        skippy.log( v_paramlist);
    end flyer;
    
    procedure joey 
    is
    begin
        raise_application_error(-20501, 'Who are you calling a wallaby ?');
    exception when others then
        -- Log the error stack
        skippy.err;
    end joey;    
    
    procedure jack
    is
    begin
        -- Setting the log level to W(arning)...
        skippy.set_log_level('W');
        -- ...means that this message will not be logged
        skippy.log(q'[What's that Skippy ?]');
        -- ...but this one will
        skippy.log('Down a mine shaft ?', 'W');
    end jack;
    
    procedure run_all
    is
    begin
        jill;
        boomer;
        flyer;
        joey;
        -- Turn off message grouping in this session
        skippy.set_msg_group(null);
        
        jack;
        
        -- Explicitly set the message group
        skippy.log('No worries', i_group=> 'TROUPE');
    end run_all;    
end demo;
/