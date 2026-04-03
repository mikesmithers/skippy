-- As suggested by Richard Martens :
-- Add a clob to hold a large output ( e.g. a rest service).

alter table skippy_logs add extra clob
/

comment on column skippy_logs.extra is 'Extra CLOB information like for example parameters, and json requests or results';