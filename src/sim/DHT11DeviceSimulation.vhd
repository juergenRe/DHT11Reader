----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/29/2020 01:02:15 PM
-- Design Name: 
-- Module Name: DHT11DeviceSimulation - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DHT11DeviceSimulation is
    generic (
        NDATABIT:      integer := 40
    );
    port (
        clk:            in std_logic;
        reset:          in std_logic;
        dhtInSig:       out std_logic;                          -- input line from DHT11
        dhtOutSig:      in std_logic;                           -- output line to DHT11
        -- configuration inputs for device
        t_trigin:       in time;
        t_wakeup:       in time;
        t_startL:       in time;
        t_startH:       in time;
        t_bitL:         in time;
        t_bitH0:        in time;
        t_bitH1:        in time;
        txData:         in std_logic_vector(NDATABIT-1 downto 0)
     );
end DHT11DeviceSimulation;

architecture Behavioral of DHT11DeviceSimulation is


-- DHT11 states 
type t_dhtState is (  stPowOn, stIdle, 
                        stRcvStartBit, stWakeUp, 
                        stTxStartBitLow, stTxStartBitHigh, 
                        stTxBitLow, stTxBitHigh1, stTxBitHigh0);
signal dhtState:    t_dhtState;
signal txDebug:     std_logic_vector(NDATABIT+8 downto 0) := (others => '0');

begin

	dhtInSig <= '0' when ((dhtState = stTxStartBitLow) or (dhtState = stTxBitLow)) else '1';

----------------------------------------------------------------------------------
-- DHT11 sensor simulation
dht11simu_proc: process
        variable bitcnt: integer := 0;
        variable txBit: std_logic;
    begin
        wait until rising_edge(clk);
        if reset = '1' then
            dhtState <= stPowOn;
        else
            case dhtState is
                when stPowOn =>
                    wait for 500ns;
                    dhtState <= stIdle;
                when stIdle =>
                    wait until dhtOutSig = '0';
                    bitcnt := 39;
                    dhtState <= stRcvStartBit;
                when stRcvStartBit =>
                    wait for t_trigin;  
                    if dhtOutSig = '1' then
                        dhtState <= stIdle;
                    else
                        wait until dhtOutSig = '1';
                        dhtState <= stWakeUp;
                    end if;
                when stWakeUp =>
                    wait for t_wakeup;
                    txDebug <= (others => '0');
                    dhtState <= stTxStartBitLow;
                when stTxStartBitLow =>
                    wait for t_startL;
                    dhtState <= stTxStartBitHigh;
                when stTxStartBitHigh =>
                    wait for t_startH;
                    dhtState <= stTxBitLow;
                when stTxBitLow =>
                    wait for t_bitL;
                    if bitcnt >= 0 then
                        txBit := txData(bitcnt);
                        txDebug(bitcnt) <= '1';
                        bitcnt := bitcnt -1;
                        if txBit = '0' then
                            dhtState <= stTxBitHigh0;
                        else
                            dhtState <= stTxBitHigh1;
                        end if;
                    else
                        dhtState <= stIdle;
                    end if;                   
                when stTxBitHigh0 =>
                    wait for t_bitH0;
                    dhtState <= stTxBitLow;
                when stTxBitHigh1 =>
                    wait for t_bitH1;
                    dhtState <= stTxBitLow;
            end case;
        end if;
    end process;


end Behavioral;
