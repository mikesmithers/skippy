create table skippy_userenv_parameters(
    parameter_name varchar2(128),
    db_version number not null,
    db_release number not null,
    version_no as (db_version + (db_release / 10)), 
    constraint skippy_userenv_parameters_pk primary key (parameter_name))
/

comment on table skippy_userenv_parameters is 'Parameters in the USERENV namespace for use in SYS_CONTEXT calls';
comment on column skippy_userenv_parameters.parameter_name is 'The USERENV parameter name';
comment on column skippy_userenv_parameters.db_version is 'The major release number in which this parameter was first available ( or 11 if earlier than 11.2). Corresponds to the DBMS_DB_VERSION.VERSION value';
comment on column skippy_userenv_parameters.db_release is 'The minor release (version) number in which this parameter was first available ( or 2 if earlier than 11.2). Corresponds to the DBMS_DB_VERSION.RELEASE value';
comment on column skippy_userenv_parameters.version_no is 'Virtual column to provide a decimal database release e.g. 12.2 for db_version 12 db_release 2';