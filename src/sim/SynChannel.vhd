----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/22/2020 05:45:35 PM
-- Design Name: 
-- Module Name: SynChannel - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SyncChannel is
  Port (
    -- put interface - receives Req 
    P : in t_testData;
    pDone : out BOOLEAN;
    
    -- get interface - sends Req
    G : out t_testData;
    gRequest : in BOOLEAN
   );
end SyncChannel;

architecture Behavioral of SyncChannel is

  signal count : natural;
  signal p_trans, g_trans : bit;

begin

  p_trans <= p'TRANSACTION;
  g_trans <= gRequest'TRANSACTION;
  
  process
    constant NDEBUG             : BOOLEAN := TRUE;
    variable pendingRequest     : BOOLEAN := FALSE;
    variable pendingTransaction : BOOLEAN := FALSE;
    variable doChannel          : BOOLEAN := false;
    variable itsDone            : BOOLEAN := TRUE;
  begin
    
    assert NDEBUG report "awaiting put transaction" severity note;
      
    -- Wait for a new transaction to arrive on the put side,
    -- or for a request on the get side.
    wait on p'TRANSACTION, gRequest'TRANSACTION;
      
    -- both could happen simultaneously
    if p'TRANSACTION'EVENT then
      pendingTransaction := true;
    end if;
      
    if gRequest'TRANSACTION'EVENT then
      pendingRequest := TRUE;
    end if;
      
    if pendingTransaction and pendingRequest then
      doChannel := true;
    elsif pendingTransaction and not pendingRequest then
      wait on gRequest'TRANSACTION;
      doChannel := true;
    elsif not pendingTransaction and pendingRequest then
      wait on p'TRANSACTION;
      doChannel := true;
    end if;
      
    -- if the request has arrived from the get side, and the 
    -- new transaction has arrived from the put side, transfer
    -- the transation from put to get.
    if doChannel then
      g <= p;
      count <= count + 1;
      pendingTransaction := false;
      pendingRequest := false;
      doChannel := false;
      pdone <= itsDone;
    end if;
    
  end process;    
end Behavioral;
