create or replace view skippy_env as
    select parameter_name, 
        sys_context('userenv', parameter_name) as session_value
    from skippy_userenv_parameters
    where version_no <= skippy.db_version
/    