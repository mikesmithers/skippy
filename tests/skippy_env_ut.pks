create or replace package skippy_env_ut as
    --%suite(skippy_env)
    --%suitepath(skippy_ut)
    
    --%rollback(manual)
    
    --%test(environment variables)
    procedure environment_variables;
    
    --%test(override message type)
    procedure override_msg_type;
    
    --%test(specify message group)
    procedure specify_msg_group;
end skippy_env_ut;    