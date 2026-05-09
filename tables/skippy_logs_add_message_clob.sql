-- As suggested by Richard Martens :
-- Add a clob to hold a large output ( e.g. a rest service).

alter table skippy_logs add message_clob clob
/

comment on column skippy_logs.message_clob is 'Extra CLOB information like for example parameters, and json requests or results';

-- Also - make MESSAGE optional
alter table skippy_logs modify message null;