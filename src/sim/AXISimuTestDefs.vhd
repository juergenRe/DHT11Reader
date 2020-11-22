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

package AXISimuTestDefs is

constant C_AXI_DATA_WIDTH	: integer := 32;   -- Width of S_AXI data bus
constant C_AXI_ADDR_WIDTH	: integer := 6;    -- Width of S_AXI address bus

constant C_INT_DATA_WIDTH	: integer := 32;   
constant C_INT_STATUS_WIDTH	: integer := 8;   

type t_transaction is (TransExt, transInt);
type t_operation is (None, Read, Write);

type t_internData is record
    data        : std_logic_vector(C_INT_DATA_WIDTH-1 downto 0);
    status      : std_logic_vector(C_INT_STATUS_WIDTH-1 downto 0);
end record;

type t_externData is record
    data        : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    addr        : std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);
    op          : t_operation;
end record;

type t_testData is record
    trans       : t_transaction;
    intData     : t_internData;
    extData     : t_externData;
    expResult   : std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
    desc        : string(1 to 40);
end record;

type t_test_ary is array (natural range <>) of t_testData;
constant test_data : t_test_ary := (
    0       => (            -- set interndata
      trans     => TransInt,
      intData   => (data => x"12345678", status => x"A2"),
      extData   => (data => x"00000000", addr => "000000", op => None),
      expResult => x"00000000",
      desc      => "write int R0/R1                         "),
    1       => (           
      trans     => TransExt,
      intData   => (data => x"00000000", status => x"00"),
      extData   => (data => x"00000000", addr => "000000", op => Read),
      expResult => x"12345678",
      desc      => "read AXI R0                             "),
    2       => (           
      trans     => TransExt,
      intData   => (data => x"00000000", status => x"00"),
      extData   => (data => x"00000000", addr => "000100", op => Read),
      expResult => x"000000A2",
      desc      => "read AXI R1                             ")
   );

    -- function prototypes
    procedure put(constant reqToPut: in t_testData; signal req: out t_testData; signal hs: in bit);
    procedure get(variable reqGot: out t_testData; signal req: in t_testData; signal dataReady: out Boolean; signal hs: in bit);
    
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
end AXISimuTestDefs;