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

    constant DUMP_DATA:     bit := '0';
    signal   dump_done:     bit := '0';

    signal StimDone:        boolean;
    signal StimTrans:       t_testData;
    
    signal MonTrans:        t_testData;
    signal StopClock:       boolean;
    signal TrgStart:        bit := '0';


begin      
    TrgStart <= dump_done;
    
    TCG: entity work.Testcase
    generic map (
        StimFilename => "sim_3_test_data.txt",
        ResultFilename => "sim_3_result_data.txt"
    )
    port map ( 
        TrgStart    => TrgStart,        -- in
        StimDone    => StimDone,        -- in
        StimTrans   => StimTrans,       -- out
        StopClock   => StopClock,       -- out
        MonTrans    => MonTrans         -- in
    );

  DHT11Harness: entity work.DHT11AXIHarness 
    port map (
        TrgStart    => TrgStart,        -- in
        StimDone    => StimDone,        -- out
        StimTrans   => StimTrans,       -- in
        StopClock   => StopClock,       -- in
        MonTrans    => MonTrans         -- out
    );
    
 -------------------------------------------------------------------   
 -- dump test data cases to a file
 -- location will be in proj\DHT11Reader.sim\sim_3\behav\xsim
    dump_data_proc: process
    begin
        if DUMP_DATA = '1' then
            if dump_done = '0' then
                wrOut("Write test data to file");
                writeTestData("sim_3_test_data.txt", test_data);
                wait for 100ns;
                dump_done <= '1';
                wrOut("Dump done");
                wait for 100ms;
            end if;
        else
            dump_done <= '1';
        end if;
        wait for 100ms;
    end process dump_data_proc;
    
    
end architecture Bench;

