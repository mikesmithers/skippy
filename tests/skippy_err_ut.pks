create or replace package skippy_err_ut as
    --%suite(skippy_err)
    --%suitepath(skippy_ut)

    --%rollback(manual)
    
    --%test(exception_block)
    procedure exception_block;
    
    --%test(specify_group)
    procedure specify_group;
end skippy_err_ut;    