create or replace package body skippy_current_settings_ut
as
    -- Get Current Log Level
    procedure get_log_level is
        v_expected varchar2(1);
    begin
        -- Setup
        select cid
        into v_expected
        from skippy_message_types
        where log_level = ( select max( log_level) from skippy_message_types);

        skippy.set_log_level(v_expected);
        
        -- Execute
        ut.expect(skippy.current_setting('LEVEL')).to_(equal(v_expected));
    end get_log_level;
    
    -- Get current Message Group when set
    procedure get_group
    is
        v_expected varchar2(30) := 'AC/DC'; -- Skippy's favourite group
    begin
        -- Setup
        skippy.set_msg_group(v_expected);

        -- Execute/Validate
        ut.expect(skippy.current_setting('GROUP')).to_(equal(v_expected));
    end get_group;
    
    -- Get current Message Group when not set
    
    procedure get_group_not_set is
    begin
        -- Setup
        skippy.set_msg_group(null);

        -- Execute/Validate
        ut.expect(skippy.current_setting('GROUP')).to_(be_null());
    end get_group_not_set;
    
end skippy_current_settings_ut;
/