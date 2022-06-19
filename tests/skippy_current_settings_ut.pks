create or replace package skippy_current_settings_ut
as
    --%suite(skippy_current_settings)
    --%suitepath(skippy_ut)
    
    --%test(Get Current Log Level)
    procedure get_log_level;
    
    --%test(Get current Message Group when set)
    procedure get_group;

    --%test(Get current Message Group when not set)
    procedure get_group_not_set;
    
end skippy_current_settings_ut;
/
    
    
