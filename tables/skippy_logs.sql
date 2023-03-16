create table skippy_logs(
    id number, -- not using an identity column to remain backward compatible with 11g
    log_ts timestamp not null,
    username varchar2(128),
    os_user varchar2(4000),
    instance number,
    sid number,
    serial number,
    log_source varchar2(4000),
    line_no number,
    message_type varchar2(25) not null,
    message_group varchar2(4000),
    message varchar2(4000) not null,
    constraint skippy_logs_pk primary key (id),
    constraint skippy_logs_message_types_fk foreign key (message_type) references skippy_message_types(cid))
/

create sequence skippy_logs_id_seq;

comment on table skippy_logs is 'Logging table for the PLSLOG framework';
comment on column skippy_logs.id is 'Unique Identifier for the message. Primary Key.Generated by SKIPPY_LOGS_ID_SEQ';
comment on column skippy_logs.log_ts is 'The timestamp when this message was written';
comment on column skippy_logs.username is 'The database user for the session from which this message originated.';
comment on column skippy_logs.os_user is q'[The value of SYS_CONTEXT('USERVENV', 'OS_USER') in the logging session]';
comment on column skippy_logs.instance is q'[The value of SYS_CONTEXT('USERENV', 'INSTANCE') in the logging session]';
comment on column skippy_logs.sid is q'[The session sid value as found in V$SESSION.SID]';
comment on column skippy_logs.serial is q'[The session serial# value as found in V$SESSION.SERIAL#]';
comment on column skippy_logs.log_source is 'The source of the log message';
comment on column skippy_logs.line_no is 'The line number in the caller from where this message was written';
comment on column skippy_logs.message_type is 'The SKIPPY_MESSAGE_TYPES.CID of this message';
comment on column skippy_logs.message_group is 'The user-defined group to which this message belongs';
comment on column skippy_logs.message is 'The actual log message';

