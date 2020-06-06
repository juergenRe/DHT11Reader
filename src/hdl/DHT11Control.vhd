----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/01/2020 10:08:03 AM
-- Design Name: 
-- Module Name: DHT11Control - Behavioral
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
-- use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DHT11Control is
    generic (
        NDIV:   integer := 500            -- 1250 for 125MhZ clock; shall divide to 5us base clock
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
end DHT11Control;

architecture Behavioral of DHT11Control is
constant NDIVL:         integer := 12;                          -- 12 bits for prescaler assuming NDIV < 4098

-- Prescaler variables
type tPreCnt is (stPowOn, stRun);
signal stPreCntReg:     tPreCnt;
signal stPreCntNxt:     tPreCnt;

signal preCntReg:   std_logic_vector(NDIVL-1 downto 0);
signal preCntNxt:   std_logic_vector(NDIVL-1 downto 0);
signal tickPreCnt:  std_logic;

-- Sampling state machine
constant CNT_BITS:          integer := 5;                      -- 17 bits counter for init delay --> 1.3s
constant CNT_START_BIT:     integer := 3;                      -- start bit length ca. 20ms --> go when bit 12 is set
--constant CNT_BITS:          integer := 18;                      -- 17 bits counter for init delay --> 1.3s
--constant CNT_START_BIT:     integer := 12;                      -- start bit length ca. 20ms --> go when bit 12 is set
constant CNT_DLY_WAIT:      integer := 8;                       -- DHT has to respond after 40us, otherwise error
constant CNT_DLY_BITL_MN:   integer := 5;                       -- start bit DHT > 60us < 100us
constant CNT_DLY_BITL_MX:   integer := 8;                       -- start bit DHT > 60us < 100us
constant CNT_DLY_TXL_MN:    integer := 2;                       -- Tx start DHT >40us < 60us
constant CNT_DLY_TXL_MX:    integer := 4;                       -- Tx start DHT >40us < 60us
constant CNT_DLY_TXH0_MN:   integer := 1;                       -- '0'-Bit min 20us high
constant CNT_DLY_TXHU_MN:   integer := 3;                       -- '0'-Bit max 40us high, after this: undefined status
constant CNT_DLY_TXH1_MN:   integer := 5;                       -- '1'-Bit min 60us high
constant CNT_DLY_TXH1_MX:   integer := 7;                       -- '1'-Bit max 80us high --> after this: error
constant CNT_DLY_TIMEOUT:   integer := 20;                      -- general timeout --> we assume that transfer was aborted

type tSmplStates is (stPowOn, stPowOnDly, stIdle,
                    stTrgSampling, stWaitStartBitHigh,
                    stDHTStartBitLow, stWaitDHTStartBitLow, stWaitDHTStartBitHigh,
                    stWaitTxHigh, stWaitTxLow, stShiftLow, stShiftHigh,
                    stStoreResult, stDly,
                    stError);
signal stSmplReg:       tSmplStates;
signal stSmplNxt:       tSmplStates;
signal smplCntReg:      std_logic_vector(CNT_BITS-1 downto 0);
signal smplCntNxt:      std_logic_vector(CNT_BITS-1 downto 0);
signal cntMax:          std_logic_vector(CNT_BITS-1 downto 0);

-- Data In register and bit counter
constant DHTDATALEN:    integer := 40;
constant DHTBITLEN:     integer := 6;
signal actBit:          std_logic;
signal shiftEnable:     std_logic;
signal actData:         std_logic_vector(DHTDATALEN-1 downto 0);
signal bitCntNxt:       std_logic_vector(DHTBITLEN-1 downto 0);
signal bitCntReg:       std_logic_vector(DHTBITLEN-1 downto 0);

-- shift register for input data
component ShiftLeft is
generic (
    NBITS            : positive := 15
);
port (
    clk              : in std_logic;
    reset            : in std_logic;
    -- Input
    setEnable        : in std_logic;
    dataIn           : in std_logic_vector(NBITS-1 downto 0);
    dataBit          : in std_logic;
    -- Control
    shiftEnable      : in std_logic;
    -- Output
    dataOut          : out std_logic_vector(NBITS-1 downto 0)
);
end component;

begin

cntMax <= (others => '1');             -- set a max value to compare with

    -- prescaler to reduce input clock
clk_div_reg: process (clk, reset)
begin
    if rising_edge(clk) then
        if reset = '1' then
            stPreCntReg <= stPowOn;
            PreCntReg <= (others => '1');
        else
            stPreCntReg <= stPreCntNxt;
            preCntReg <= preCntNxt;
        end if;
    end if;
end process clk_div_reg;

clk_div_nxt: process(stPreCntReg, preCntReg)
begin
    stPreCntNxt <= stPreCntReg;
    preCntNxt <= preCntReg;
    case stPreCntReg is
        when stPowOn =>
            preCntNxt <= (others => '1');
            stPreCntNxt <= stRun;
        when stRun =>
            if preCntReg >= NDIV then
                preCntNxt <= (others => '0');
            else
                preCntNxt <= preCntReg + 1;
            end if;
    end case;
end process clk_div_nxt;

tickPreCnt <= '1' when (preCntReg = 0) else '0';
dhtOutSig <= '0' when (stSmplReg = stTrgSampling) else '1';
rdy <= '1' when (stSmplReg = stIdle) else '0';
actBit <= '1' when (stSmplReg = stShiftHigh) else '0';
shiftEnable <= '1' when (((stSmplReg = stShiftHigh) or (stSmplReg = stShiftLow)) and (tickPreCnt = '1')) else '0';

dataRegister: ShiftLeft
    generic map (
        NBITS       => DHTDATALEN
    )
    port map (
    clk             => clk,
    reset           => reset,
    setEnable       => '0',   
    dataIn          => (others => '0'),
    dataBit         => actBit,
    shiftEnable     => shiftEnable, 
    dataOut         => actData     
    );
    
smpl_state_proc_reg: process(clk, reset, tickPreCnt)
begin
    if rising_edge(clk) then
        if reset = '1' then
            stSmplReg <= stPowOn;
            smplCntReg <= (others => '0');
            bitCntReg <= (others => '0');
        else
            if tickPreCnt = '1' then
                stSmplReg <= stSmplNxt;
                smplCntReg <= smplCntNxt;
                bitCntReg <= bitCntNxt;
            else
                stSmplReg <= stSmplReg;
                smplCntReg <= smplCntReg;
                bitCntReg <= bitCntReg;
            end if;
        end if;
    end if;
end process smpl_state_proc_reg;

smpl_state_proc_nxt: process(stSmplReg, smplCntReg, dhtInSig, trg)
begin
    stSmplNxt <= stSmplReg;
    case stSmplReg is
        when stPowOn =>
            stSmplNxt <= stPowOnDly;
            smplCntNxt <= (others => '0');
            bitCntNxt <= (others => '0');
        when stPowOnDly =>
            smplCntNxt <= smplCntReg + 1;
            if smplCntReg = cntMax then
                stSmplNxt <= stIdle;
            end if;
        when stIdle =>
            if trg = '1' then
                stSmplNxt <= stTrgSampling;
            end if;
        when stTrgSampling =>           -- drive output to DHT low for > 18ms
            smplCntNxt <= smplCntReg + 1;
            if smplCntReg(CNT_START_BIT) = '1' then
                stSmplNxt <= stWaitStartBitHigh;
                smplCntNxt <= (others => '0');
            end if;
        when stWaitStartBitHigh =>       -- drive output to DHT high for 20..40us
            smplCntNxt <= smplCntReg + 1;
            if dhtInSig = '0' then          -- detected falling edge
                stSmplNxt <= stWaitDHTStartBitLow;
                smplCntNxt <= (others => '0');
            elsif smplCntReg > CNT_DLY_WAIT then
                stSmplNxt <= stError;
            end if;
        when stWaitDHTStartBitLow =>
            smplCntNxt <= smplCntReg + 1;
            if dhtInSig = '1' then
                smplCntNxt <= (others => '0');
                if smplCntReg >= CNT_DLY_BITL_MN then
                    if smplCntReg < CNT_DLY_BITL_MX then
                        stSmplNxt <= stWaitDHTStartBitHigh;
                    else
                        stSmplNxt <= stError;
                    end if;
                end if;
            end if;   
        when stWaitDHTStartBitHigh =>
            smplCntNxt <= smplCntReg + 1;
            if dhtInSig = '0' then
                bitCntNxt <= (others => '0');
                smplCntNxt <= (others => '0');
                if smplCntReg >= CNT_DLY_BITL_MN then
                    if smplCntReg < CNT_DLY_BITL_MX then
                        stSmplNxt <= stDly;
                    else
                        stSmplNxt <= stError;
                    end if;
                end if;
            end if;   
        when stDly =>
            stSmplNxt <= stWaitTxHigh;       
        when stWaitTxHigh =>
            smplCntNxt <= smplCntReg + 1;
            if dhtInSig = '1' then
                smplCntNxt <= (others => '0');
                if smplCntReg >= CNT_DLY_TXL_MN then
                    if bitCntReg = DHTDATALEN then
                        stSmplNxt <= stStoreResult;
                    else
                        if smplCntReg < CNT_DLY_TXL_MX then
                            stSmplNxt <= stWaitTxLow;
                        else
                            stSmplNxt <= stError;
                        end if;
                    end if;
                end if;
            end if;   
        when stWaitTxLow =>
            smplCntNxt <= smplCntReg + 1;
            if dhtInSig = '0' then
                smplCntNxt <= (others => '0');
                if smplCntReg >= CNT_DLY_TXH0_MN then
                    if smplCntReg < CNT_DLY_TXHU_MN then
                        -- found BITx = 0
                        stSmplNxt <= stShiftLow;
                    elsif smplCntReg < CNT_DLY_TXH1_MN then 
                        stSmplNxt <= stError;
                    elsif smplCntReg < CNT_DLY_TXH1_MX then
                        -- found BITx = 1
                        stSmplNxt <= stShiftHigh;
                    else
                        stSmplNxt <= stError;
                    end if;
                end if;
            else
                if smplCntReg > CNT_DLY_TIMEOUT then
                    stSmplNxt <= stError;
                end if; 
            end if;
        when stShiftLow =>
            stSmplNxt <= stWaitTxHigh;
            bitCntNxt <= bitcntReg + 1;
        when stShiftHigh =>    
            stSmplNxt <= stWaitTxHigh;
            bitCntNxt <= bitcntReg + 1;
        when stStoreResult =>
            stSmplNxt <= stIdle;
        when others =>
    end case;
end process smpl_state_proc_nxt;


end Behavioral;
