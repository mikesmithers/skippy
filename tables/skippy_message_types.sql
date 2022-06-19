create table skippy_message_types(
    cid varchar2(25),
    log_level number(3) default 999,
    description varchar2(4000),
    constraint skippy_message_types_pk primary key (cid))
/

comment on table skippy_message_types is 'Log message types used in the PLSLOG framework';
comment on column skippy_message_types.cid is 'Character identifier for the log level. Primary Key';
comment on column skippy_message_types.log_level is 'The numeric log level for this message type';
comment on column skippy_message_types.description is 'Description of this message type';

    