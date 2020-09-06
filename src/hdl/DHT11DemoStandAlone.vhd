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

entity DHT11DemoStandAlone is
    Port ( 
        clk         : in std_logic;
        led         : out std_logic_vector(3 downto 0);
        btn         : in std_logic_vector(3 downto 0);
        sw          : in std_logic_vector(1 downto 0);
        ck_io       : out std_logic_vector(1 downto 0);
        DataLine    : inout std_logic
    );
end DHT11DemoStandAlone;

architecture Behavioral of DHT11DemoStandAlone is

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
signal stTranReg:       t_stTran;
signal stTranNxt:       t_stTran;

signal reset:           std_logic;
signal cntTick:         std_logic;
signal trg:             std_logic;
signal rdy:             std_logic;
signal dhtIn:           std_logic;
signal dhtOut:          std_logic;
signal dataT:           std_logic_vector(15 downto 0);
signal dataH:           std_logic_vector(15 downto 0);
signal dataStatus:      std_logic_vector(2 downto 0);

-- debug attributes
attribute mark_debug : string;
--attribute mark_debug of btn_edge: signal is "true";
--attribute mark_debug of swTick: signal is "true";
--attribute mark_debug of stTranReg: signal is "true";
--attribute mark_debug of dataT: signal is "true";
--attribute mark_debug of dataH: signal is "true";
--attribute mark_debug of dataStatus: signal is "true";
--attribute mark_debug of rdy: signal is "true";
--attribute mark_debug of trg: signal is "true";
--attribute mark_debug of cntTick: signal is "true";
--attribute mark_debug of DataLine: signal is "true";

------------------------------------------------------------------------------------

component DHT11Control
    generic (
        NDIV:           integer := 99;                          -- 1us ticks @ 100MHz clock
        POWONDLY:       boolean := false                        -- enable simulation timings or real timings
    );
    port (
        clk:            in std_logic;
        reset:          in std_logic;
        cntTick:        out std_logic;                          -- counter tick
        outT:           out std_logic_vector(15 downto 0);      -- temperature out
        outH:           out std_logic_vector(15 downto 0);      -- humidity out
        outStatus:      out std_logic_vector(2 downto 0);       -- status out: [2]: Ready; [1]: short circuit; [0]: error
        trg:            in std_logic;                           -- new settings trigger
        rdy:            out std_logic;                          -- component ready to receive new settings
        dhtInSig:       in std_logic;                           -- input line from DHT11
        dhtOutSig:      out std_logic                           -- output line to DHT11
     );
end component;

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
    dht11: DHT11Control
    generic map(
        NDIV        => 124,    -- stand-alone: 125MHz base clock
        POWONDLY    => true
    )
    port map (
        clk         => clk,
        reset       => reset,
        cntTick     => cntTick,
        outT        => dataT,
        outH        => dataH,
        outStatus   => dataStatus,
        trg         => trg,
        rdy         => rdy,
        dhtInSig    => dhtIn,
        dhtOutSig   => dhtOut
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
dhtIn <= DataLine;
DataLine <= '0' when dhtOut = '0' else 'Z';

----------------------------------------------------
--
-- functions:
-- btn0: trigger sample
-- btn3: reset
-- sw0:  auto/single shot
-- led0: rdy
-- led1: auto
-- led3: reset

reset <= btn_dbc(3);
led(0) <= rdy;
led(1) <= sw(0);
led(2) <= '0';
led(3) <= btn(3);
ck_io(0) <= trg;
ck_io(1) <= rdy;

trg <= '1' when stTranReg = stSetTrg else '0';

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

proc_trans_nxt: process(stTranReg, swTick, btn_edge, rdy)
begin
    stTranNxt <= stTranReg;
    case stTranReg is
        when stPwrOn => 
            if rdy = '1' then
                stTranNxt <= stIdle;
            end if;
        when stIdle => 
            if btn_edge(0) = '1' then
                stTranNxt <= stWaitRdy;
            end if;
        when stWaitRdy => 
            if rdy = '1' then
                stTranNxt <= stSetTrg;
            end if;
        when stSetTrg =>
            if rdy = '0' then 
                stTranNxt <= stWaitDone;
            end if;
        when stWaitActive => 
            if rdy = '0' then
                stTranNxt <= stWaitDone;
            end if;
        when stWaitDone => 
            if rdy = '1' then
                stTranNxt <= stIdle;
            end if;
    end case;
end process proc_trans_nxt;

end Behavioral;
