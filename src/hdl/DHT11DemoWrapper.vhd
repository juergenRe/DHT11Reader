----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/29/2020 03:38:13 PM
-- Design Name: 
-- Module Name: DHT11DemoStandAlone - Behavioral
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

entity DHT11DemoWrapper is
    Port ( 
        clk         : in std_logic;
        led         : out std_logic_vector(3 downto 0);
        btn         : in std_logic_vector(3 downto 0);
        sw          : in std_logic_vector(1 downto 0);
        ck_io       : out std_logic_vector(1 downto 0);
        DataLine    : inout std_logic
    );
end DHT11DemoWrapper;

architecture Behavioral of DHT11DemoWrapper is

constant NBtn:          integer := 4;

signal btn_edge:        std_logic_vector(NBtn-1 downto 0);
signal btn_dbc:         std_logic_vector(NBtn-1 downto 0);
signal swTick:          std_logic_vector(1 downto 0);
signal lunused:         std_logic_vector(NBtn-1 downto 0);
signal btnSet:          std_logic_vector(NBtn-1 downto 0);
signal btnSetNxt:       std_logic_vector(NBtn-1 downto 0);
signal btnTick:         std_logic;

type t_stTran is (
    stPwrOn,
    stIdle,
    stWaitRdy,
    stSetTrg,
    stWaitActive,
    stWaitDone
);

constant 		C_S00_AXI_DATA_WIDTH: integer := 32;
constant        PWRONDLY:             integer := 21;

signal stTranReg:       t_stTran;
signal stTranNxt:       t_stTran;

signal wr_tick:         std_logic;
signal reset:           std_logic;
signal rd_tick:         std_logic;
signal act_control:     std_logic_vector(1 downto 0);
signal act_status:      std_logic_vector(2 downto 0);
signal act_values:      std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);

signal dhtInSig:        std_logic;
signal dhtOutSig:       std_logic;

-- debug attributes
--attribute mark_debug : string;
--attribute mark_debug of btn_edge: signal is "true";
--attribute mark_debug of stTranReg: signal is "true";
--attribute mark_debug of act_values: signal is "true";
--attribute mark_debug of act_control: signal is "true";
--attribute mark_debug of act_status: signal is "true";
--attribute mark_debug of rd_tick: signal is "true";
--attribute mark_debug of wr_tick: signal is "true";

------------------------------------------------------------------------------------

component DHT11Wrapper is
	generic (
		-- Users to add parameters here
		C_S_AXI_DATA_WIDTH	    : integer := 32;
		NDIV                    : integer := 99;
        PWRONDLY                : integer := 21
	);
	port (
	    clk         : in std_logic;
	    reset       : in std_logic;
		-- control bits to start conversion and have automatic conversion every second
        U_CONTROL   : in std_logic_vector(1 downto 0);
        --  Status bits: Ready, Error
        U_STATUS    : out std_logic_vector(2 downto 0);
        -- measured values:
        -- U_VALUES(31 downto 16): 16 bits for temperature
        -- U_VALUES(15 downto 0):  16 bits for hunidity
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
end component DHT11Wrapper;

component Debounce is
   generic (
		N			: integer := 19		--counting size: 2^N * 20ns = 10ms tick
   );
   port(
		clk			: in std_logic;
		reset		: in std_logic;
		sw			: in std_logic;			--bouncing input
		db			: out std_logic			--debounced output
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

function sumTick(inTickVect: std_logic_vector) return std_logic is
variable tv: std_logic;
begin
    tv := '0';
    for i in inTickVect'range loop
        if inTickVect(i) = '1' then
            tv := '1';
        end if;
    end loop;
    return tv;
end sumTick;

begin
dht11wrapper_inst: DHT11Wrapper
    generic map (
        C_S_AXI_DATA_WIDTH      => C_S00_AXI_DATA_WIDTH,
        NDIV                    => 124,
        PWRONDLY                => PWRONDLY
    )
    port map (
        clk         => clk,
        reset       => reset,
        U_CONTROL   => act_control,
        U_STATUS    => act_status,
        U_VALUES    => act_values,
        U_WR_TICK   => wr_tick,
        U_RD_TICK   => rd_tick,
        dhtInSig    => dhtInSig,
        dhtOutSig   => dhtOutSig
    );

-- generate debounced button signals
dbce_gen_btn: for k in 0 to NBtn-1 generate
    dbnc_btn_k: Debounce
        generic map (
            N       => 20
        )
        port map(
            clk			=> clk,
            reset		=> '0',
            sw			=> btn(k),
            db			=> btn_dbc(k)
        );
end generate dbce_gen_btn;
   
-- generate edge detectors
edge_gen_btn: for k in 0 to NBtn-1 generate
    edge_btn_k: EdgeDetect
    port map (
        clk         => clk,
        reset       => '0',
        level       => btn_dbc(k),
        tick_rise   => btn_edge(k),
        tick_fall   => open
    );
end generate edge_gen_btn;

edge_gen_sw: for k in 0 to 1 generate
    edge_sw_k: EdgeDetect
        port map (
            clk         => clk,
            reset       => '0',
            level       => sw(k),
            tick_rise   => swTick(k),
            tick_fall   => open
        );
end generate edge_gen_sw;

----------------------------------------------------
    -- DHT11 bus signals
    dhtInSig <= DataLine;
    DataLine <= '0' when dhtOutSig = '0' else 'Z';

----------------------------------------------------
--
-- functions:
-- btn0: trigger sample
-- btn3: reset
-- sw0:  auto/single shot
-- led0: rdy
-- led1: error
-- led2: auto
-- led3: reset

reset <= btn_dbc(3);
led(0) <= act_status(2);
led(1) <= act_status(0);
led(2) <= sw(0);
led(3) <= btn(3);
--ck_io(0) <= trg;
--ck_io(1) <= rdy;

act_control(0) <= '1' when ((stTranReg = stWaitRdy) or (stTranReg = stSetTrg) or (stTranReg = stWaitActive)) else '0';
act_control(1) <= sw(0);
wr_tick <= '1' when stTranReg = stSetTrg else '0';

--------------------------------------------------------------
-- state machine to transfer data to pwm component    
proc_trans_reg: process(clk, reset)
begin
    if rising_edge(clk) then
        if reset = '1' then
            stTranReg <= stPwrOn;
        else
            stTranReg <= stTranNxt;
        end if;
    end if;
end process proc_trans_reg;

proc_trans_nxt: process(stTranReg, rd_tick, act_status)
begin
    stTranNxt <= stTranReg;
    case stTranReg is
        when stPwrOn => 
            if act_status(2) = '1' then
                stTranNxt <= stIdle;
            end if;
        when stIdle => 
            if btn_edge(0) = '1' then
                stTranNxt <= stWaitRdy;
            end if;
        when stWaitRdy => 
            if act_status(2) = '1' then
                stTranNxt <= stSetTrg;
            end if;
        when stSetTrg =>
            if act_status(2) = '0' then 
                stTranNxt <= stWaitDone;
            end if;
        when stWaitActive => 
            if act_status(2) = '0' then
                stTranNxt <= stWaitDone;
            end if;
        when stWaitDone => 
            if act_status(2) = '1' then
                stTranNxt <= stIdle;
            end if;
    end case;
end process proc_trans_nxt;

end Behavioral;
