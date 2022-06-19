clear screen
exec dbms_session.modify_package_state(dbms_session.reinitialize);
set serverout on

column db_version new_value v_version noprint

select version as db_version
from dba_registry
where comp_id = 'CATALOG'
/

spool 'test_output_&v_version..txt'

prompt Running Full Test Suite on Oracle Database Version &v_version

exec ut.run(':skippy_ut');

spool off

