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
        StimFilename:   string := "?";
        ResultFilename: string := "?"
    );
    port (
        TrgStart:   in bit;
        StimDone:   in  boolean;
        StimTrans:  out t_testData;
        StopClock:  out boolean;
        MonTrans:   in  t_testData
    );
end entity Testcase;

architecture Behavioral of Testcase is

    -- buffering of generated stimulans
    signal StimTransFromGen:    t_testData;
    signal StimTranstoUUT:      t_testData;
    signal StimDoneToGen:       boolean;
    signal StopClock_i:         boolean;

begin      
    StimTrans <= StimTranstoUUT;
    StopClock <= StopClock_i;
    
    -- feed the generated into a queue, output of the queue will give the current test stimulans
    -- reverse direction will feed the "StimeDone" signal to provide a new stimulans
    channel: entity work.SynChannel
    port map (
        p           => StimTransFromGen,
        pDone       => StimDoneToGen,
        g           => StimTranstoUUT,
        gRequest    => StimDone
    );

    -- generate test cases and provide them as "StimTrans*"
    GenCases: entity work.GenerateCases 
    generic map (
        filename => StimFilename
    )
    port map ( 
        TrgStart  => TrgStart,
        StimDone  => StimDoneToGen,
        StimTrans => StimTransFromGen,
        EndOfFile => StopClock_i
    );

    Checker: entity work.ResultChecker
    generic map (
        filename  => ResultFilename
    )
    port map (
        StopClock       => StopClock_i,
        expectedData    => StimTranstoUUT,
        actualData      => MonTrans
    );
end architecture Behavioral;

