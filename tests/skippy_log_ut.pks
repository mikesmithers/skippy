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

    --%test(long_message);
    procedure long_message;

    --%test(logging_disabled)
    procedure logging_disabled;
    
    --%test(Interactive output enabled);
    procedure output_enabled;
    
    --%test(Interactive output disabled);
    procedure output_disabled;
    
end skippy_log_ut;
/
    