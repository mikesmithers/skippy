--
-- Convert the VARCHAR2 columns in SKIPPY_LOGS to use CHAR length semantics
--
alter table skippy_logs modify 
(
    username varchar2(128 char),
    os_user varchar2(4000 char),
    log_source varchar2(4000 char),
    message_type varchar2(25 char), 
    message_group varchar2(4000 char),
    message varchar2(4000 char)
)
/