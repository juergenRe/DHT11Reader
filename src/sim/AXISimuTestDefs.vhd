----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/22/2020 03:59:39 PM
-- Design Name: 
-- Module Name: AXISimuTestDefs - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

use STD.TEXTIO.all;
use work.GenFuncLib.ALL;

package AXISimuTestDefs is

constant C_AXI_DATA_WIDTH	: integer := 32;   -- Width of S_AXI data bus
constant C_AXI_ADDR_WIDTH	: integer := 6;    -- Width of S_AXI address bus

constant C_INT_DATA_WIDTH	: integer := 32;   
constant C_INT_STATUS_WIDTH	: integer := 8;   

type t_transaction is (TransNone, TransExt, TransInt, TransReset);
type t_operation is (None, Read, Write);

-- internData: values coming from the sensor and to be stored in the internal registers
-- externData: values to be read/written via AXI operation
-- expected result: result obtained via AXI read
type t_internData is record
    data        : std_logic_vector(C_INT_DATA_WIDTH-1 downto 0);
    status      : std_logic_vector(C_INT_STATUS_WIDTH-1 downto 0);
    control     : std_logic_vector(1 downto 0);
    op          : t_operation;
end record;

type t_externData is record
    data        : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    addr        : std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    op          : t_operation;
end record;

type t_result is record
    f           : boolean;
    res         : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
end record;    
    
type t_results is array(1 to 3) of t_result;

type t_testData is record
    trans       : t_transaction;
    intData     : t_internData;
    extData     : t_externData;
    expResult   : t_results; 
    desc        : string(1 to 40);
end record;

type t_test_ary is array (natural range <>) of t_testData;
constant test_data : t_test_ary := (
    0       => (            -- set interndata
      trans     => TransReset,
      intData   => (data => x"FFFFFFFF", status => x"FF", control => "00", op => None),
      extData   => (data => x"A5A5A5A5", addr => "000000", op => None),
      expResult => ( (f => false, res => x"00000000"), (f => false, res => x"00000000"), (f => false, res => x"00000000")), 
      desc      => "issue reset                             "),
    1       => (            -- set interndata
      trans     => TransInt,
      intData   => (data => x"12345678", status => x"A2", control => "00", op => Write),
      extData   => (data => x"00000000", addr => "000000", op => None),
      expResult => ( (f => false, res => x"00000000"), (f => false, res => x"00000000"), (f => false, res => x"00000000")), 
      desc      => "internal preset R0/R1                   "),
    2       => (           
      trans     => TransExt,
      intData   => (data => x"00000000", status => x"00", control => "00", op => None),
      extData   => (data => x"00000000", addr => "000000", op => Read),
      expResult => ( (f => true, res => x"12345678"), (f => false, res => x"00000000"), (f => false, res => x"00000000")), 
      desc      => "read AXI R0                             "),
    3       => (           
      trans     => TransExt,
      intData   => (data => x"00000000", status => x"00", control => "00", op => None),
      extData   => (data => x"00000000", addr => "000100", op => Read),
      expResult => ( (f => True, res => x"000000A2"), (f => false, res => x"00000000"), (f => false, res => x"00000000")), 
      desc      => "read AXI R1                             "),
    4       => (           
      trans     => TransExt,
      intData   => (data => x"00000000", status => x"00", control => "00", op => None),
      extData   => (data => x"00000001", addr => "001000", op => Write),
      expResult => ( (f => false, res => x"00000000"), (f => false, res => x"00000000"), (f => false, res => x"00000000")), 
      desc      => "write AXI R2                            "),
    5       => (           
      trans     => TransInt,
      intData   => (data => x"00000000", status => x"00", control => "00", op => Read),
      extData   => (data => x"00000001", addr => "001000", op => none),
      expResult => ( (f => false, res => x"12345678"), (f => false, res => x"000000A2"), (f => true, res => x"00000001")), 
      desc      => "internal read control                   ")
   );

    -- function prototypes
    procedure put(constant reqToPut: in t_testData; signal req: out t_testData; signal hs: in bit);
    procedure get(variable reqGot: out t_testData; signal req: in t_testData; signal dataReady: out Boolean; signal hs: in bit);

    function t_transaction_to_integer(constant tr: in t_transaction) return integer;
    function t_operation_to_integer(constant op: in t_operation) return integer;
    function to_t_transaction(constant tr: in integer) return t_transaction;
    function to_t_operation(constant op: in integer) return t_operation;
    
    procedure writeTestData(constant fn: in string; constant tdary: in t_test_ary);
    procedure readTdElement(variable row: inout line; variable td: out t_testData);

end AXISimuTestDefs;

package body AXISimuTestDefs is
    procedure put(constant reqToPut: in t_testData; signal req: out t_testData; signal hs: in bit) is
    begin
        req <= reqToPut;
        wait on hs;
    end;
    
    procedure get(variable reqGot: out t_testData; signal req: in t_testData; signal dataReady: out Boolean; signal hs: in bit) is
    begin
        dataReady <= TRUE;
        wait on hs;
        reqGot := req;
    end; 
    
    function t_transaction_to_integer(constant tr: in t_transaction) return integer is 
    begin
        if tr = TransInt then
            return 1;
        elsif tr = TransExt then
            return 2;
        elsif tr = TransReset then
            return 3;
        else
            return 0;
        end if;
    end;
    
    
    function t_operation_to_integer(constant op: in t_operation) return integer is 
    begin
        case op is
            when Read =>
                return 1;
            when Write =>
                return 2;
            when others =>
                return 0;
        end case;
    end;
    
    function to_t_transaction(constant tr: in integer) return t_transaction is 
    begin
        if tr = 1 then
            return TransInt;
        elsif tr = 2 then
            return TransExt;
        elsif tr = 3 then
            return TransReset;
        else
            return TransNone;
        end if;
    end;
    
    
    function to_t_operation(constant op: in integer) return t_operation is 
    begin
        case op is
            when 1 =>
                return Read;
            when 2 =>
                return Write;
            when others =>
                return None;
        end case;
    end;
    
    procedure writeResultElement(variable row: inout line; constant result: in t_result) is
        variable f: natural;
    begin
        if result.f = true then
            f := 1;
        else
            f := 0;
        end if;
        write(row, f, right, 2);
        write(row, conv_integer(result.res), right, 15);
    end;
    
    procedure readResultElement(variable row: inout line; variable result: out t_result) is
        variable intData: integer;
        variable ins: string(1 to 20);
    begin
--        wrOut("ReadResult - 1");
        read(row, intData);
        if intData = 1 then
            result.f := true;
        else
            result.f := false;
        end if;
        read(row, intData);
        result.res := std_logic_vector(to_unsigned(intData, result.res'length));
    end;
    
    procedure writeTestData(constant fn: in string; constant tdary: in t_test_ary) is
        file f:         text open WRITE_MODE is fn;
        variable row:   line;
        variable td:    t_testData;
        variable ra:    t_results;
        constant hd:    string := " Line |    TransType |     Int Data |    IntStatus |   IntControl |        IntOp |     ExtData |      ExtAddr |        ExtOp |      Result[1] |      Result[2] |      Result[3] | Description"; 
    begin
        write(row, hd, left, 0);
        writeline(f, row);
        for i in tdary'range loop
            wrOut("Line " & integer'image(i));
            td := tdary(i);
            write(row, i, right, 5);
            write(row, t_transaction_to_integer(td.trans), right, 15);
            write(row, conv_integer(td.intData.data), right, 15);
            write(row, conv_integer(td.intData.status), right, 15);
            write(row, conv_integer(td.intData.control), right, 15);
            write(row, t_operation_to_integer(td.intData.op), right, 15);
            write(row, conv_integer(td.extData.data), right, 15);
            write(row, conv_integer(td.extData.addr), right, 15);
            write(row, t_operation_to_integer(td.extData.op), right, 15);
            ra := td.expResult;
            for r in ra'range loop
                writeResultElement(row, ra(r));
            end loop;
            write(row, string'("  "));
            write(row, td.desc, left, 50);
            
            writeline(f, row);
        end loop;
        file_close(f);
    end;
    
    procedure readTdElement(variable row: inout line; variable td: out t_testData) is
        variable lineNr:    integer;
        variable intData:   integer;
        variable strData:   string(1 to 50); 
        variable ra:        t_results;
        variable res:       t_result;
    begin
        read(row, lineNr);
        wrOut("   readTDElement of line " & integer'image(lineNr));
        
        td := ( 
            trans     => TransNone,
            intData   => (data => x"FFFFFFFF", status => x"00", control => x"00", op => None),
            extData   => (data => x"00000000", addr => "000000", op => None),
            expResult => ( (f => True, res => x"000000A2"), (f => false, res => x"00000000"), (f => false, res => x"00000000")), 
            desc      => "init values                             ");

        read(row, intData);
        td.trans := to_t_transaction(intData);
        -- rad internal data set
        read(row, intData);
        td.intData.data := std_logic_vector(to_unsigned(intData, td.intData.data'length));
        read(row, intData);
        td.intData.status := std_logic_vector(to_unsigned(intData, td.intData.status'length));
        read(row, intData);
        td.intData.control := std_logic_vector(to_unsigned(intData, td.intData.control'length));
        read(row, intData);
        td.intData.op := to_t_operation(intData);
        
        -- reas external data
        read(row, intData);
        td.extData.data := std_logic_vector(to_unsigned(intData, td.extData.data'length));
        read(row, intData);
        td.extData.addr := std_logic_vector(to_unsigned(intData, td.extData.addr'length));
        read(row, intData);
        td.extData.op := to_t_operation(intData);
        
        -- read results
        for r in ra'range loop
            readResultElement(row, res);
            td.expResult(r) := res;
        end loop;
        
        -- read description
        read(row, strData);
        td.desc := strData(1 to td.desc'length);
    end;
    
end AXISimuTestDefs;