----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/29/2020 12:30:27 PM
-- Design Name: 
-- Module Name: TestCase - Behavioral
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
use IEEE.STD_LOGIC_1164.all;
use work.AXISimuTestDefs.ALL;


entity Testcase is
    generic (
        filename : string := "none.txt"
    );
    port (
        StimDone  : in  boolean;
        StimTrans : out t_testData;
        StopClock : out boolean;
        MonTrans  : in  t_testData
    );
end entity Testcase;

architecture Behavioral of Testcase is

    -- buffering of generated stimulans
    signal StimTransFromGen : t_testData;
    signal StimDoneToGen  : boolean;

begin      

    -- feed the generated into a queue, output of the queue will give the current test stimulans
    -- reverse direction will feed the "StimeDone" signal to provide a new stimulans
    channel: entity work.SynChannel
    port map (
        p           => StimTransFromGen,
        pDone       => StimDoneToGen,
        g           => StimTrans,
        gRequest    => StimDone
    );

    -- generate test cases and provide them as "StimTrans*"
    GenCases: entity work.GenerateCases 
    generic map (
        filename => filename
    )
    port map ( 
        StimDone  => StimDoneToGen,
        StimTrans => StimTransFromGen,
        EndOfFile => StopClock
    );

end architecture Behavioral;

