----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/29/2020 11:52:40 AM
-- Design Name: 
-- Module Name: Testbench - Behavioral
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
use work.GenFuncLib.ALL;
use work.AXISimuTestDefs.ALL;

entity Testbench is
end Testbench;

architecture Bench of Testbench is

    constant DUMP_DATA:     integer := 0;
    signal   dump_done:     integer := 0;

    signal StimDone:        boolean;
    signal StimTrans:       t_testData;
    
    signal MonTrans:        t_testData;
    signal StopClock:       boolean;


begin      
     
  TCG: entity work.Testcase
    generic map (
        Filename => "sim_3_test_data.txt"
    )
    port map ( 
        StimDone    => StimDone,
        StimTrans   => StimTrans,
        StopClock   => StopClock,
        MonTrans    => MonTrans
    );

  DHT11Harness: entity work.DHT11AXIHarness 
    port map (
        StimDone    => StimDone,
        StimTrans   => StimTrans,
        StopClock   => StopClock,
        MonTrans    => MonTrans
    );
    
 -------------------------------------------------------------------   
 -- dump test data cases to a file
    dump_data_proc: process
    begin
        if DUMP_DATA = 1 then
            if dump_done = 0 then
                wrOut("Write test data to file");
                writeTestData("sim_3_test_data.txt", test_data);
                dump_done <= 1;
                wrOut("Dump done");
                wait for 100ms;
            end if;
        end if;
        wait for 100ms;
    end process dump_data_proc;
    
    
end architecture Bench;

