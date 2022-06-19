create or replace package skippy_group_ut as
    --%suite(skippy_group)
    --%suitepath(skippy_ut)
    
    --%rollback(manual)
    
    --%test(set group)
    procedure set_group;
    
    --%test(unset group)
    procedure unset_group;
    
    --%test( log group)
    procedure log_group;
    
    --%test( log no group)
    procedure log_no_group;

end skippy_group_ut;
/
