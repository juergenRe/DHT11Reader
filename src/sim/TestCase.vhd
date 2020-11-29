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

    signal StimTrans2 : t_testData;
    signal StimDone2  : boolean;

begin      

    channel: entity work.SynChannel
    port map (
        p           => StimTrans2,
        pDone       => StimDone2,
        g           => StimTrans,
        gRequest    => StimDone
    );

    GenCases: entity work.GenerateCases 
    generic map (
        filename => filename
    )
    port map ( 
        StimDone  => StimDone2,
        StimTrans => StimTrans2,
        EndOfFile => StopClock
    );

end architecture Behavioral;

