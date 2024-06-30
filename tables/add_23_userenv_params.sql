--
-- Update skippy_userenv_parameters with the new parameters in 23AI
-- Reference documentation : https://docs.oracle.com/en/database/oracle/oracle-database/23/sqlrf/SYS_CONTEXT.html#GUID-B9934A5D-D97B-4E51-B01B-80C76A5BD086
-- NOTE - there are various errors and omissions in the documentation, so some of these parameters are also added as available from 19c
-- 
update skippy_userenv_parameters
set db_version = 23,
db_release = 0
where parameter_name = 'CDB_DOMAIN';

-- Not documented in 19c docs but available
insert into skippy_userenv_parameters( parameter_name, db_version, db_release) 
values( 'CLOUD_SERVICE', 19, 0);

-- Either the docs have been updated or I missed these first time round...
insert into skippy_userenv_parameters( parameter_name, db_version, db_release) 
values( 'CURRENT_SQL_LENGTH', 19, 0);

insert into skippy_userenv_parameters( parameter_name, db_version, db_release) 
values( 'DRAIN_STATUS', 19, 0);

-- 23ai new params
insert into skippy_userenv_parameters( parameter_name, db_version, db_release) 
values( 'STANDBY_MAX_DATA_DELAY', 23, 0);

insert into skippy_userenv_parameters( parameter_name, db_version, db_release) 
values( 'TLS_CIPHERSUITE', 23, 0);

insert into skippy_userenv_parameters( parameter_name, db_version, db_release) 
values( 'TLS_VERSION', 23, 0);

commit;
