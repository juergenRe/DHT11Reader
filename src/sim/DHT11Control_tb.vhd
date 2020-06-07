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
use IEEE.std_logic_unsigned.all;

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

constant TVAR_WAKE:     integer := 30;          -- 10% variation for wake-up time
constant TVAR_STRT:     integer := 25;          -- 25% variation for start bit
constant TVAR_BITL:     integer := 20;          -- 20% variation for Bit low time
constant TVAR_BITH0:    integer := 8;           -- 8% variation for a '0' bit
constant TVAR_BITH1:    integer := 15;          -- 15% variation for '1' bit
constant TVAT_END:      integer := 50;

signal t_trigin:        time;                   -- min external start bit
signal t_wakeup:        time;
signal t_startL:        time;
signal t_startH:        time;
signal t_bitL:          time;
signal t_bitH0:         time;
signal t_bitH1:         time;

-- Test Data definiton
constant NB_TIMES:      natural := 7;
type t_timing_ary is array (natural range <>) of time;
type t_testdata is record
      timings   : t_timing_ary(0 to NB_TIMES-1);	-- timing array
	  data	    : std_logic_vector(31 downto 0); 	-- data to transmit
	  expectRes	: boolean;						    -- expected result
end record;
type t_test_ary is array (natural range <>) of t_testdata;

  ------------------------------------------------------------------------------
  -- Stimulus data
  ------------------------------------------------------------------------------
  -- The following constant holds the stimulus for the testbench. It is
  -- an ordered array of timings and data to transmit.
  ------------------------------------------------------------------------------
constant test_data : t_test_ary := (
    0       => (
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      data      => x"5577AA33",
      expectRes => true)
      ); 

----------------------------------------------------------------
-- DHT11 states 

type t_dhtState is (  stPowOn, stIdle, srSetTimings,
                        stRcvStartBit, stWakeUp, 
                        stTxStartBitLow, stTxStartBitHigh, 
                        stTxBitLow, stTxBitHigh1, stTxBitHigh0);
signal dhtState:    t_dhtState;
signal txData:      std_logic_vector(NDATABIT-1 downto 0);
signal txDebug:     std_logic_vector(NDATABIT+8 downto 0) := (others => '0');
signal expectResult:boolean;

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
            trg         => trg,
            rdy         => rdy,
            dhtInSig    => dhtInSig,
            dhtOutSig   => dhtOutSig
         );

   -------------------------------------------------------------------
	-- Clock process definitions
	clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

   -------------------------------------------------------------------
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

----------------------------------------------------------------------------------
-- DHT11 sensor simulation
    dht11simu_proc: process
        variable bitcnt: integer := 0;
        variable txBit: std_logic;
        variable dataVal: std_logic_vector(31 downto 0);
        function calc_crc ( data : in std_logic_vector) return std_logic_vector is
            variable crc: std_logic_vector(7 downto 0);
		begin
		    crc := data(31 downto 24) + data(23 downto 16) + data(15 downto 8) + data(7 downto 0);
		    return crc;
		end;
        procedure getActData(idx: in natural; dx: out std_logic_vector) is
        begin
            dx := test_data(idx).data;
            t_trigin <= test_data(idx).timings(0);
            t_wakeup <= test_data(idx).timings(1);
            t_startL <= test_data(idx).timings(2);
            t_startH <= test_data(idx).timings(3);
            t_bitL  <= test_data(idx).timings(4);
            t_bitH0 <= test_data(idx).timings(5);
            t_bitH1 <= test_data(idx).timings(6);
            expectResult <= test_data(idx).expectRes;
        end;
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
                    dhtState <= srSetTimings;
                when srSetTimings =>
                    getActData(0, dataVal);
                    txData <= dataVal & calc_crc(dataVal);
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
  
    
   
   
    
   
   
