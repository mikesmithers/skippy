create or replace package skippy_log_ut
as
    --%suite(skippy_log)
    --%suitepath(skippy_ut)
    
    --%rollback(manual)

    function get_message_id return skippy_logs.id%type;
    
    --%test(default message)
    procedure write_default_message;
    
    --%test(non-default valid message level)
    procedure valid_message_level;
    
    --%test( message group)
    procedure message_group;
    
    --%test(override source)
    procedure override_source;
    
    --%test(override_line_no)
    procedure override_line_no;

    --%test(logging_disabled)
    procedure logging_disabled;
    
    --%test(Interactive output enabled);
    procedure output_enabled;
    
    --%test(Interactive output disabled);
    procedure output_disabled;

    -- New tests for v1.1    
    
    --%test(Write to the message_clob column explicitly)
    procedure write_message_clob;

    --%test(long_message);
    procedure long_message;
    
    --%test( Log parameters with a message)
    procedure params_with_message;
    
    --%test( Log parameters with no message)
    procedure params_no_message;
  
    --%test( log a long message and parameter)
    procedure long_message_and_param;
    
    --%test( log a long message and a clob)
    procedure long_message_and_clob;
    
    --%test( log a long parameter with no message)
    procedure log_long_params;

    --%test( log a long parameter and a clob)
    procedure long_param_and_clob;
    
    --%test( log a long message, long parameter and clob)
    procedure all_long;

    --%test( Log a conventional length message, parameters and extra)
    procedure log_all;
    
    --%test( Log Extra only)
    procedure extra_only;
    
    --%test( all blank)
    procedure all_blank;
    
end skippy_log_ut;
/
    