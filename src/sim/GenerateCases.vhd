----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/28/2020 04:22:11 PM
-- Design Name: 
-- Module Name: GenerateCases - Behavioral
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
use IEEE.std_logic_1164.all;
use STD.TEXTIO.all;
use IEEE.STD_LOGIC_TEXTIO.all;

use work.AXISimuTestDefs.ALL;

entity GenerateCases is 
    generic (
        Filename : string
    );
    port (
        StimDone : in boolean;
        StimTrans : out t_testData;
        EndOfFile : out boolean);
    end entity GenerateCases;

architecture Behavioral of GenerateCases is
    signal StimDoneTrans : bit;
begin
    StimDoneTrans <= StimDone'TRANSACTION;

    genCase_proc: process
        file f:             text open READ_MODE is Filename;
        variable row:       line;
        variable TData:     t_testData;
--        variable VData: DataT;
    begin
        EndOfFile <= FALSE;
        readline(f, row);           -- read header
        while not endfile(f) loop
            
            readline(f, row);
            readTdElement(row, TData);
            put( TData, StimTrans, StimDone'TRANSACTION);      
        end loop;
        wait for 100 ns;
        EndOfFile <= TRUE;
        wait;
    end process genCase_proc;

end architecture Behavioral;
  
