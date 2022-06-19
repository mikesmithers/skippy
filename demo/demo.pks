create or replace package demo
as
    -- Package to demonstrate features of the SKIPPY logging framework.
 
    procedure jill;
    
    procedure boomer;

    procedure flyer(
        i_string in varchar2 default 'Skippy', 
        i_number in number default 91,
        i_date in date default to_date('19680502', 'YYYYMMDD'),
        i_boolean in boolean default true); 
        
    procedure joey;
    procedure jack;

    procedure run_all;
end demo;
/