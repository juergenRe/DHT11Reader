----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/01/2020 10:26:36 AM
-- Design Name: 
-- Module Name: DHT11Control_tb - Behavioral
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

entity DHT11Control_tb is
end DHT11Control_tb;

architecture Behavioral of DHT11Control_tb is
   -- Clock period definitions
constant clk_period:    time := 10 ns;

   --internal signals
signal clk:             std_logic := '0';
signal reset:           std_logic := '0';

-- inputs to DHT11Reader block
constant NDIV:          integer := 4;

signal outT:           std_logic_vector(15 downto 0);      -- temperature
signal outH:           std_logic_vector(15 downto 0);      -- humidity
signal outStatus:      std_logic_vector(1 downto 0);       -- status: [1]: sample available; [0]: error
signal rdy:            std_logic;                          -- component ready to receive new settings
signal dhtOutSig:      std_logic;                          -- driver line to DHT11

signal trg:            std_logic := '0';                   -- new settings trigger
signal inTSample:      std_logic_vector(7 downto 0) := (others => '0');        -- sample time 1... 256s for auto trigger; 0: sample on trg
signal dhtInSig:       std_logic := '1';                   -- input line towards simulated DHT11

-----------------------------------
-- dht11 simulation signals
--
constant NDATABIT:      integer := 40;

-- timing contants: base timing in ns, can be streteched by MULT
constant MULT:          integer := 5;
constant TSTRTIN:       time := 250ns;
constant TWAKE:         time := 20ns * MULT;       -- min timing, max is double
constant TSTRTL:        time := 80ns * MULT;
constant TSTRTH:        time := 80ns * MULT;
constant TBITL:         time := 50ns * MULT;
constant TBITH0:        time := 26ns * MULT;
constant TBITH1:        time := 70ns * MULT;


type t_dhtState is (  stPowOn, stIdle, 
                        stRcvStartBit, stWakeUp, 
                        stTxStartBitLow, stTxStartBitHigh, 
                        stTxBitLow, stTxBitHigh1, stTxBitHigh0);
signal dhtState:    t_dhtState;
signal txData:      std_logic_vector(NDATABIT-1 downto 0) := x"5577AA334B";
signal txDebug:     std_logic_vector(NDATABIT+8 downto 0) := (others => '0');

----------------------------------------
component DHT11Control
    generic (
        NDIV:   integer := 500            -- 1250 for 125MhZ clock; shall divide to 10us base clock
    );
    port (
        clk:            in std_logic;
        reset:          in std_logic;
        outT:           out std_logic_vector(15 downto 0);      -- temperature out
        outH:           out std_logic_vector(15 downto 0);      -- humidity out
        outStatus:      out std_logic_vector(1 downto 0);       -- status out: [1]: sample available; [0]: error
        inTSample:      in std_logic_vector(7 downto 0);        -- sample time 1... 256s for auto trigger; 0: sample on trg
        trg:            in std_logic;                           -- new settings trigger
        rdy:            out std_logic;                          -- component ready to receive new settings
        dhtInSig:       in std_logic;                           -- input line from DHT11
        dhtOutSig:      out std_logic                           -- output line to DHT11
     );
end component;

begin
    uut: DHT11Control
        generic map(
            NDIV => NDIV  
        )
        port map (
            clk         => clk,     
            reset       => reset,
            outT        => outT,
            outH        => outH,
            outStatus   => outStatus,
            inTSample   => inTSample,
            trg         => trg,
            rdy         => rdy,
            dhtInSig    => dhtInSig,
            dhtOutSig   => dhtOutSig
         );

	-- Clock process definitions
	clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
	
   -- Stimulus process
    stim_proc: process
    begin
        -- check behaviour when no reset is given
        wait for 200 ns;
        reset <= '1';
        wait for 100ns;
        reset <= '0';
		wait until rdy = '1';
		wait for 200ns;
		wait until clk = '0';
		trg <= '1';
		wait until rdy = '0';
		wait until clk = '0';
		trg <= '0';
		
		wait for 100us;
	end process;
	
	dhtInSig <= '0' when ((dhtState = stTxStartBitLow) or (dhtState = stTxBitLow)) else '1';
	
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
                    wait for TSTRTIN;
                    if dhtOutSig = '1' then
                        dhtState <= stIdle;
                    else
                        wait until dhtOutSig = '1';
                        dhtState <= stWakeUp;
                    end if;
                when stWakeUp =>
                    wait for TWAKE;
                    txDebug <= (others => '0');
                    dhtState <= stTxStartBitLow;
                when stTxStartBitLow =>
                    wait for TSTRTL;
                    dhtState <= stTxStartBitHigh;
                when stTxStartBitHigh =>
                    wait for TSTRTH;
                    dhtState <= stTxBitLow;
                when stTxBitLow =>
                    wait for TBITL;
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
                    wait for TBITH0;
                    dhtState <= stTxBitLow;
                when stTxBitHigh1 =>
                    wait for TBITH1;
                    dhtState <= stTxBitLow;
            end case;
        end if;
    end process;

end Behavioral;
  
    
   
   
    
   
   
