insert into skippy_message_types( cid, log_level, description)
values('E', 10, 'Error');

insert into skippy_message_types( cid, log_level, description)
values('W', 20, 'Warning');

insert into skippy_message_types( cid, log_level, description)
values('I', 30, 'Information');

insert into skippy_message_types( cid, log_level, description)
values('D', 40, 'Debug');

insert into skippy_message_types( cid, log_level, description)
values('A', 999, 'All - the default message type');

commit;