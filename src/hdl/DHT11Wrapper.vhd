----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/23/2020 02:41:33 PM
-- Design Name: 
-- Module Name: DHT11Wrapper - Behavioral
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DHT11Wrapper is
	generic (
		-- Users to add parameters here
		C_U_STATUS_WIDTH        : integer := 1;
		C_S_AXI_DATA_WIDTH	    : integer := 32;
		NDIV                    : integer := 99;
        PWRONDLY                : integer := 21
	);
	port (
	    clk         : in std_logic;
	    reset       : in std_logic;
		-- control bits to start conversion and have automatic conversion every second: Auto Sample, Start
        U_CONTROL   : in std_logic_vector(1 downto 0);
        --  Status bits: 7:4: Error code; 3: unused; 2: Rdy 1: Data avail; 0: Error bit
        U_STATUS    : out std_logic_vector(7 downto 0);
        -- measured values:
        -- U_VALUES(31 downto 16): 16 bits for humidity
        -- U_VALUES(15 downto 0):  16 bits for temperature 
        U_VALUES    : out std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
		-- output from AXI-module: '1' for one cycle when data is written.
		-- validates U_CONTROL
		U_WR_TICK   : in std_logic;
		-- input to AXI-module: writes actual U_STATUS and U_VALUES values in register 2 + 3 to be read
		U_RD_TICK   : out std_logic;
		-- feed through of DHT signals
        dhtInSig    : in std_logic;                           -- input line from DHT11
        dhtOutSig   : out std_logic                           -- output line to DHT11
	);
end DHT11Wrapper;

architecture Behavioral of DHT11Wrapper is
--    constant CFG_ONOFF:     integer := C_S_AXI_DATA_WIDTH -1;
--    constant CFG_STATUS:    integer := C_S_AXI_DATA_WIDTH -1;

    constant STATUS_RDY:    integer := 3;                           -- bit for Ready
    constant DATA_AVAIL:    integer := 2;                           -- bit for new data available
    constant STATUS_SHC:    integer := 1;                           -- bit for short circuit indication
    constant STATUS_ERR:    integer := 0;                           -- bit error
    
    constant CNTRL_AUTO:    integer := 1;                           -- bit for automatic sampling
    constant CNTRL_TRG:     integer := 0;                           -- bit for trigger sampling

    constant SPMPLDLYBITS:  integer := PWRONDLY;                    -- counter length to have delay of 1s@1us tick 
    
    -- feed through of DHT pins
    signal dhtInSignal:     std_logic;
    signal dhtOutSignal:    std_logic;
    signal outData:         std_logic_vector(31 downto 0);      -- temperature
    signal outErr:          std_logic_vector(3 downto 0);       -- status: [2]: sample available; [1]: short circuit; [0]: error
    signal errBit:          std_logic;
    
    signal cfg_tick:        std_logic;
    signal dav_r_tick:      std_logic;
    signal dav_f_tick:      std_logic;
    signal dav_status:      std_logic;
    signal rdy_r_tick:      std_logic;
    signal rdy_f_tick:      std_logic;
    signal rdy_status:      std_logic;
    signal int_reset:       std_logic;

    type t_stSmplState is (stPwrOn, stIdle, stSampleStart, stSample, stWait, stResetCnt);
    signal stSmplStateReg:     t_stSmplState;    
    signal stSmplStateNxt:     t_stSmplState;
    
    signal rdy:             std_logic;                          -- component ready to receive new settings
    signal trg:             std_logic;                          -- new settings trigger
    signal cntTick:         std_logic;
    signal smplRun:         std_logic;
    
    signal cntEn:           std_logic;
    signal cntDone:         std_logic;
    signal smplTrg:         std_logic;
    
    type t_saState is (saPwrOn, saIdle, saOSTrg, saOSRun, saARun, saATrg);
    signal actControlReg:   t_saState;       
    signal actControlNxt:   t_saState;
    
    signal actCount:        std_logic_vector(SPMPLDLYBITS-1 downto 0);

    -- debug attributes
--    attribute mark_debug : string;
--    attribute mark_debug of trg: signal is "true";
--    attribute mark_debug of rdy: signal is "true";
----    attribute mark_debug of cntTick: signal is "true";
----    attribute mark_debug of cntDone: signal is "true";
----    attribute mark_debug of actCount: signal is "true";
--    attribute mark_debug of stSmplStateReg: signal is "true";
--    attribute mark_debug of rdy_status: signal is "true";
--    attribute mark_debug of U_WR_TICK: signal is "true";
--    attribute mark_debug of U_RD_TICK: signal is "true";
--    attribute mark_debug of U_CONTROL: signal is "true";
--    attribute mark_debug of U_STATUS: signal is "true";
--    attribute mark_debug of U_VALUES: signal is "true";
    
    component DHT11Control
        generic (
            NDIV:           integer := 99;                          -- 1us ticks @ 100MHz clock
            POWONDLY:       boolean := false                        -- enable simulation timings or real timings
        );
        port (
            clk:            in std_logic;
            reset:          in std_logic;
            cntTick:        out std_logic;                          -- counter tick
            outData:        out std_logic_vector(31 downto 0);      -- sampled data values
            outErr:         out std_logic_vector(3 downto 0);       -- detailed error code
            trg:            in std_logic;                           -- new settings trigger
            rdy:            out std_logic;                          -- component ready to receive new settings
            dhtInSig:       in std_logic;                           -- input line from DHT11
            dhtOutSig:      out std_logic                           -- output line to DHT11
         );
    end component;

    component EdgeDetect is
	port(
		clk			: in std_logic;
		reset		: in std_logic;
		level		: in std_logic;
		tick_rise	: out std_logic;
		tick_fall	: out std_logic
	);
    end component;

    component mod_m_counter is
       generic(
          N: integer := 4;     -- number of bits
          M: integer := 10     -- mod-M
      );
       port(
          clk, reset	: in std_logic;
          clk_en		: in std_logic;
          max_tick		: out std_logic;
          q				: out std_logic_vector(N-1 downto 0)
       );
    end component;

begin
    dht11Control_inst: DHT11Control
        generic map(
            NDIV        => NDIV,  
            POWONDLY    => false
        )
        port map (
            clk         => clk,     
            reset       => reset,
            cntTick     => cntTick,
            outData     => outData,
            outErr      => outErr,
            trg         => trg,
            rdy         => rdy,
            dhtInSig    => dhtInSignal,
            dhtOutSig   => dhtOutSignal
         );
    dhtInSignal <= dhtInSig;
    dhtOutSig <= dhtOutSignal;
    
    errBit <= outErr(3) or outErr(2) or outErr(1) or outErr(0);
    U_STATUS <= outErr & '0' & rdy_status & dav_status & errBit;
    U_VALUES <= outData;

    -- 1s delay counter for power on and waiting time after a sample
    dly_inst: mod_m_counter
        generic map (
            N       => SPMPLDLYBITS,
            M       => 2**(SPMPLDLYBITS-1)
        )
        port map (
            clk         => clk,
            reset       => reset,
            clk_en      => cntEn,
            max_tick    => cntDone,
            q           => actCount
        );
    cntEn <= '1' when ((stSmplStateReg = stWait) or (stSmplStateReg = stPwrOn) or (stSmplStateReg = stResetCnt)) and cntTick = '1' else '0';    
     
    cfg_tick <= U_WR_TICK;
    int_reset <= '1' when reset = '1' or stSmplStateReg = stPwrOn else '0';
    smplRun <= '1' when stSmplStateReg = stSample else '0';
    smplTrg <= '1' when ((actControlReg = saOSTrg) or (actControlReg = saATrg)) else '0' ;

    -- handle automatic / one shot sampling states
    -- one shot: after a successful sample, control need to be set again
    -- U_CONTROL    smplRun smplTrg state
    --  00          x       0       saIdle
    --  01          0       1       saOSTrg
    --  01          1       0       saOSRun     --> saIdle when CNTRL_TRG=0
    --  10          0       0       saIdle      stay in saIdle when only CNTRL_AUTO goes to 1, need CNTRL_TRG for start
    --  10          1       1       saARun      --> saATrg when conversion done, --> saIdle when U_CONTROL = "00"
    --  11          0       1       saATrg      --> saARun when CNTRL_TRG = 1
    --  11          1       1       saARun      --> saATrg when converion done, --> saIdle when U_CONTROL = "00"
    p_auto_reg: process(clk, int_reset)
    begin
        if rising_edge(clk) then
            if int_reset ='1' then
                actControlReg <= saPwrOn;
            else
                actControlReg <= actControlNxt;
            end if;
        end if;
    end process p_auto_reg;
    
    p_auto_nxt: process(actControlReg, stSmplStateReg, cfg_tick, smplRun, rdy_r_tick)
    begin
        actControlNxt <= actControlReg;
        case actControlReg is
            when saPwrOn =>
                if stSmplStateReg = stIdle then
                    actControlNxt <= saIdle;
                end if;
            when saIdle =>
                if cfg_tick = '1' and U_CONTROL(CNTRL_TRG) = '1' then
                    if U_CONTROL(CNTRL_AUTO) = '1' then
                        actControlNxt <= saATrg;
                    else
                        actControlNxt <= saOSTrg;
                    end if;
                end if;
            when saOSTrg =>
                if smplRun = '1' then
                    actControlNxt <= saOSRun;
                end if;
            when saOSRun =>
                -- either return when conversion finished or a new setting written, but TRG has to be 0
                if (rdy_r_tick = '1' or cfg_tick = '1') and U_CONTROL(CNTRL_TRG) = '0' then
                    actControlNxt <= saIdle;
                end if;
            when saATrg =>
                if smplRun = '1' then
                    actControlNxt <= saARun;
                end if;
            when saArun =>
                if rdy_r_tick = '1' then 
                    if U_CONTROL(CNTRL_AUTO) = '0' then
                        if U_CONTROL(CNTRL_TRG) = '1' then
                            actControlNxt <= saOSRun;       -- wait for falling edge of TRG to return to idle
                        else                
                            actControlNxt <= saIdle;
                        end if;
                    else
                        actControlNxt <= saATrg;
                    end if;
                end if;
        end case;
    end process p_auto_nxt;
    
    -- handle sampling of the DHT11 including power on and wait after getting a new sample
    p_smplState_reg: process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset ='1' then
                stSmplStateReg <= stPwrOn;
            else
                stSmplStateReg <= stSmplStateNxt;
            end if;
        end if;
    end process p_smplState_reg;
    
    p_smplState_nxt: process(stSmplStateReg, smplTrg, cntDone, rdy)
    begin
        stSmplStateNxt <= stSmplStateReg;
        case stSmplStateReg is
            when stPwrOn =>
                if cntDone = '1' then
                    stSmplStateNxt <= stResetCnt;
                end if;
            when stIdle =>
                if smplTrg = '1' and rdy = '1' then
                    stSmplStateNxt <= stSampleStart;
                end if;
            when stSampleStart =>
                if rdy = '0' then
                    stSmplStateNxt <= stSample;
                end if;
            when stSample =>
                if rdy = '1' then
                    stSmplStateNxt <= stWait;
                end if;
            when stWait =>
                if cntDone = '1' then
                    stSmplStateNxt <= stResetCnt;
                end if;
            when stResetCnt =>
                if cntDone = '0' then
                    stSmplStateNxt <= stIdle;
                end if;
        end case;
    end process p_smplState_nxt;
    trg <= '1' when stSmplStateReg = stSampleStart else '0';
    
    -- conditions for updating the status register resp. the output value register
    dav_status <= '0' when (stSmplStateReg = stSample) or (stSmplStateReg = stPwrOn) else '1';
    rdy_status <= '1' when stSmplStateReg = stIdle else '0';
    
	dav_tick_inst: EdgeDetect
        port map (
            clk         => clk,
            reset       => reset,
            level       => dav_status,
            tick_rise   => dav_r_tick,
            tick_fall   => dav_f_tick
        );

	rdy_tick_inst: EdgeDetect
        port map (
            clk         => clk,
            reset       => reset,
            level       => rdy_status,
            tick_rise   => rdy_r_tick,
            tick_fall   => rdy_f_tick
        );
    U_RD_TICK <= dav_r_tick or dav_f_tick or rdy_r_tick or rdy_f_tick;

end Behavioral;
