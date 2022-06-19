create or replace package skippy_add_params_ut
as
    --%suite(skippy_params)
    --%suitepath(skippy_ut)

    --%test(add varchar param)
    procedure add_varchar_param;
    
    --%test(add number param)
    procedure add_number_param;
    
    --%test(add date param)
    procedure add_date_param;
    
    --%test(add boolean param)
    procedure add_boolean_param;
    
    --%test(build param string)
    procedure build_param_string;
    
end skippy_add_params_ut;
/
    