prompt Installing the Skippy Logging framework :
prompt

prompt Creating Tables...
prompt

@tables/skippy_userenv_parameters.sql
@tables/skippy_message_types.sql
@tables/skippy_logs.sql

prompt Creating Reference Data...
prompt

@tables/skippy_userenv_parameters_dml.sql
@tables/skippy_message_types_dml.sql

prompt Creating Package
prompt

@packages/skippy.pks
@packages/skippy.pkb

prompt Creating Views
prompt

@views/skippy_env.sql