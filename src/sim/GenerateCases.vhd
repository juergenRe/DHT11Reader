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
use work.GenFuncLib.ALL;

entity GenerateCases is 
    generic (
        Filename : string
    );
    port (
        TrgStart:   in bit;
        StimDone:   in boolean;
        StimTrans:  out t_testData;
        EndOfFile:  out boolean);
    end entity GenerateCases;

architecture Behavioral of GenerateCases is
    signal StimDoneTrans:   bit;
    signal Cnt:             integer := -1;         
begin
    StimDoneTrans <= StimDone'TRANSACTION;

    genCase_proc: process
        file f:             text; 
        variable row:       line;
        variable TData:     t_testData;
--        variable VData: DataT;
    begin
        wait until TrgStart = '1';
        wrOut(" ");
        wrOut("GEN: --- Start generating test cases ---");
        file_open(f, Filename, read_mode);
        EndOfFile <= false;
        readline(f, row);           -- read header
        while not endfile(f) loop
            
            readline(f, row);
            readTdElement(row, TData);
            put( TData, StimTrans, StimDone'TRANSACTION); 
            Cnt <= Cnt + 1;     
        end loop;
        wait for 100 ns;
        EndOfFile <= true;
        wait;
    end process genCase_proc;

end architecture Behavioral;
  
