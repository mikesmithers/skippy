--
-- Script to upgrade an existing installation.
-- Changes applied by this script are :
-- 1) Add the EXTRA column to SKIPPY_LOGS
-- 2) Convert SKIPPY_LOGS VARCHAR columns to use CHAR length semantics explicitly
-- 3) Add the facility to log parameters using  SKIPPY.T_PARAMS_TYPE 
--

prompt Adding column to SKIPPY_LOGS...
prompt
@tables/skippy_logs_add_message_clob.sql

prompt Converting SKIPPY_LOGS to use CHAR length semantics...
prompt
@tables/skippy_logs_char_semantics.sql

prompt Updating package SKIPPY...

@packages/skippy.pks
@packages/skippy.pkb