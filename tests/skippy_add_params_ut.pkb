create or replace package body skippy_add_params_ut
as
    
    g_char_param varchar2(4000);
    g_num_param number;
    g_date_param date;
    g_bool_param boolean;
    
    procedure set_globals is
    begin
        g_char_param := 'Skippy';
        g_num_param := 91; -- number of episodes of Skippy the Bush Kangaroo
        g_date_param := date '1968-02-05'; -- date the program was first broadcast
        g_bool_param := false;
        
    end set_globals;
    
    -- add varchar param
    procedure add_varchar_param is 
        v_param_name varchar2(30) := 'i_star';
        v_paramlist varchar2(4000);
    begin 
        -- setup
        set_globals;
        
        -- execute
        skippy.add_param( v_param_name, g_char_param, v_paramlist);
        
        -- validate
        ut.expect(v_paramlist).to_(equal(v_param_name||' => '||g_char_param));
    end add_varchar_param;
    
    -- add number param
    procedure add_number_param is 
        v_param_name varchar2(30) := 'i_episodes';
        v_paramlist varchar2(4000);
    begin 
        -- setup
        set_globals;
        
        -- execute
        skippy.add_param( v_param_name, g_num_param, v_paramlist);
        
        -- validate
        ut.expect(v_paramlist).to_(equal(v_param_name||' => '||g_num_param));
    end add_number_param;
    
    -- add date param
    procedure add_date_param is 
        v_param_name varchar2(30) := 'i_first_air';
        v_paramlist varchar2(4000);
    begin 
        -- setup
        set_globals;
        
        -- execute
        skippy.add_param( v_param_name, g_date_param, v_paramlist);
        
        -- validate
        ut.expect(v_paramlist).to_(equal(v_param_name||' => '||to_char(g_date_param, sys_context('userenv', 'nls_date_format'))));
    end add_date_param;
    
    -- add boolean param
    procedure add_boolean_param is 
        v_param_name varchar2(30) := 'i_is_wallaby';
        v_expected varchar2(4000);
        v_paramlist varchar2(4000);
    begin 
        -- setup
        set_globals;
        
        v_expected := v_param_name||' => '||case when g_bool_param then 'TRUE' else 'FALSE' end;
        -- execute
        skippy.add_param( v_param_name, g_bool_param, v_paramlist);
        
        -- validate
        ut.expect(v_paramlist).to_(equal(v_expected));
    
    end add_boolean_param;
    
    -- build param string
    procedure build_param_string is 
        v_expected varchar2(4000);
        v_paramlist varchar2(4000);
        v_par1_name varchar2(30) := 'i_star';
        v_par2_name varchar2(30) := 'i_episodes';
    begin 
        -- setup
        set_globals;
        v_expected := v_par1_name||' => '||g_char_param||', '||v_par2_name||' => '||g_num_param;
        
        -- execute
        skippy.add_param( v_par1_name, g_char_param, v_paramlist);
        skippy.add_param( v_par2_name, g_num_param, v_paramlist);
        
        -- validate
        ut.expect( v_paramlist).to_(equal(v_expected));
    end build_param_string;    
        
    
end skippy_add_params_ut;
/