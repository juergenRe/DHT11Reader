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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

use work.GenFuncLib.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DHT11Control is
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
        rdy:            out std_logic;                          -- sample data ready
        dhtInSig:       in std_logic;                           -- input line from DHT11
        dhtOutSig:      out std_logic                           -- output line to DHT11: '0': drives actively low
     );
end DHT11Control;

architecture Behavioral of DHT11Control is

function cnvError(err: integer) return std_logic_vector is
begin
    return std_logic_vector(to_unsigned(err, 4));
end;

constant NDIVL:         integer := 12;                          -- 12 bits for prescaler assuming NDIV < 4098

-- Prescaler variables
type tPreCnt is (stPowOn, stRun);
signal stPreCntReg:     tPreCnt;
signal stPreCntNxt:     tPreCnt;

signal preCntReg:   std_logic_vector(NDIVL-1 downto 0);
signal preCntNxt:   std_logic_vector(NDIVL-1 downto 0);
signal tickPreCnt:  std_logic;

-- Sampling state machine
--constant CNT_BITS:          integer := 5;                      -- 17 bits counter for init delay --> 1.3s
--constant CNT_START_BIT:     integer := 3;                      -- start bit length ca. 20ms --> go when bit 12 is set
--constant CNT_TIMEOUT_BIT:   integer := 4;                       -- general timeout bit --> we assume that transfer was aborted
constant CNT_START_BIT:     integer := 12;                      -- start bit length ca. 20ms --> go when bit 12 is set
constant CNT_TIMEOUT_BIT:   integer := 14;                      -- general timeout bit --> we assume that transfer was aborted

constant CNT_DLY_START_BIT: integer := 20480;                     -- start bit length > 18ms
constant CNT_DLY_WAIT:      integer := 40-1;                      -- DHT has to respond after 40us, otherwise error
constant CNT_DLY_BITL_MN:   integer := 60-1;                      -- start bit DHT > 60us < 100us
constant CNT_DLY_BITL_MX:   integer := 100-1;                     -- start bit DHT > 60us < 100us
constant CNT_DLY_TXL_MN:    integer := 40-1;                      -- Tx start DHT >40us < 60us
constant CNT_DLY_TXL_MX:    integer := 60-1;                      -- Tx start DHT >40us < 60us
constant CNT_DLY_TXH0_MN:   integer := 14-1;                      -- '0'-Bit min 20us high
constant CNT_DLY_TXH0_MX:   integer := 40-1;                      -- '0'-Bit max 40us high, after this: undefined status
constant CNT_DLY_TXH1_MN:   integer := 60-1;                      -- '1'-Bit min 60us high
constant CNT_DLY_TXH1_MX:   integer := 80-1;                      -- '1'-Bit max 80us high --> after this: error
constant CNT_DLY_POWON:     integer := tif(POWONDLY, 20, CNT_TIMEOUT_BIT);         -- power on timeout
constant CNT_BITS:          integer := CNT_DLY_POWON + 1;         -- 21 bits counter for init delay --> ca. 2s max delay

type tSmplStates is (stPowOn, stPowOnDly, stIdle,
                    stTrgSampling, stWaitStartBitHigh,
                    stWaitDHTStartBitLow, stWaitDHTStartBitHigh,
                    stWaitTxHigh, stWaitTxLow, stShiftLow, stShiftHigh,
                    stChkSum, stStoreResult, stDly,
                    stErrWaitEnd, stErrWaitOnLow, stError,
                    stErrNoDevice, stErrDHTStartBit, stErrSC, stErrTxHigh, stErrTxLow, 
                    stErrTxTOH, stErrTxTOL, stErrChkSum);
signal stSmplReg:       tSmplStates;
signal stSmplNxt:       tSmplStates;
signal smplCntReg:      std_logic_vector(CNT_BITS-1 downto 0);
signal smplCntNxt:      std_logic_vector(CNT_BITS-1 downto 0);
--signal cntMaxInit:      std_logic_vector(CNT_BITS-1 downto 0);

-- Data In register and bit counter
constant DHTDATA_X_BOT: integer := 0;
constant DHTDATA_X_TOP: integer := 8;
constant DHTDATA_T_BOT: integer := DHTDATA_X_TOP;
constant DHTDATA_T_TOP: integer := DHTDATA_T_BOT + 16;
constant DHTDATA_H_BOT: integer := DHTDATA_T_TOP;
constant DHTDATA_H_TOP: integer := DHTDATA_H_BOT + 16;

constant DHTDATALEN:    integer := DHTDATA_H_TOP;
constant DHTBITLEN:     integer := 6;

constant ERR_OK:        integer := 0;
constant ERR_NoDevice:  integer := 1;
constant ERR_DHTStartBit: integer := 2;
constant ERR_SC:        integer := 3;
constant ERR_TxHigh:    integer := 4;
constant ERR_TxLow:     integer := 5;
constant ERR_TxTOH:     integer := 6;
constant ERR_TxTOL:     integer := 7;
constant ERR_ChkSum:    integer := 8;

signal actBit:          std_logic;
signal shiftEnable:     std_logic;
signal actData:         std_logic_vector(DHTDATALEN-1 downto 0);    -- data from shift register
signal bitCntNxt:       std_logic_vector(DHTBITLEN-1 downto 0);
signal bitCntReg:       std_logic_vector(DHTBITLEN-1 downto 0);
signal chkSum:          std_logic_vector(DHTDATA_X_TOP-1 downto DHTDATA_X_BOT);
signal sr_reset:        std_logic;
signal rdy_int:         std_logic;

signal errCodeReg:      std_logic_vector (3 downto 0);
signal errCodeNxt:      std_logic_vector (3 downto 0);

-- preparing output data state machine
type tDataSmpl is (stPowOn, stChkNewData);
signal stDataSmplReg:   tDataSmpl;
signal stDataSmplNxt:   tDataSmpl;
signal dataSampleReg:   std_logic_vector(DHTDATALEN-1 downto 0);    -- final sample after finishing read
signal dataSampleNxt:   std_logic_vector(DHTDATALEN-1 downto 0);    -- final sample after finishing read

-- debug attributes
--attribute mark_debug : string;
--attribute mark_debug of smplCntReg: signal is "true";
--attribute mark_debug of stDataSmplReg: signal is "true";
--attribute mark_debug of stSmplReg: signal is "true";
--attribute mark_debug of dataSampleReg: signal is "true";
--attribute mark_debug of dataStatusReg: signal is "true";
--attribute mark_debug of actBit: signal is "true";
--attribute mark_debug of shiftEnable: signal is "true";
--attribute mark_debug of sr_reset: signal is "true";
--attribute mark_debug of tickPreCnt: signal is "true";
--attribute mark_debug of actData: signal is "true";
--attribute mark_debug of bitCntReg: signal is "true";

begin

    --cntMaxInit <= '0' & x"124FF";             -- set a max value to compare for init
    
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
    cntTick <= tickPreCnt;
    dhtOutSig <= '0' when (stSmplReg = stTrgSampling) else '1';
    rdy_int <= '1' when (stSmplReg = stIdle) else '0';
    rdy <= rdy_int;
    actBit <= '1' when (stSmplReg = stShiftHigh) else '0';
    shiftEnable <= '1' when (((stSmplReg = stShiftHigh) or (stSmplReg = stShiftLow)) and (tickPreCnt = '1')) else '0';
    chkSum <= actData(15 downto 8) + actData(23 downto 16) + actData(31 downto 24) + actData(39 downto 32);
    
    sr_reset <= '1' when reset = '1' or (stDataSmplReg = stPowOn) else '0';
    
    dataRegister: entity work.ShiftLeft
        generic map (
            NBITS       => DHTDATALEN
        )
        port map (
        clk             => clk,
        reset           => sr_reset,
        setEnable       => '0',   
        dataIn          => (others => '0'),
        dataBit         => actBit,
        shiftEnable     => shiftEnable, 
        dataOut         => actData     
        );
        
    out_smpl_reg: process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                stDataSmplReg <= stPowOn;
                dataSampleReg <= (others => '0');
            else
                stDataSmplReg <= stDataSmplNxt;
                dataSampleReg <= dataSampleNxt;
            end if;
        end if;
    end process out_smpl_reg;
    
    out_smpl_nxt: process(tickPreCnt, stDataSmplReg, stSmplReg, dataSampleReg, actData)
    begin
        stDataSmplNxt <= stDataSmplReg;
        dataSampleNxt <= dataSampleReg;
        case stDataSmplReg is
            when stPowOn =>
                dataSampleNxt <= (others => '0');
                stDataSmplNxt <= stChkNewData;
            when stChkNewData =>
                if tickPreCnt = '1' and (stSmplReg = stStoreResult) then
                    dataSampleNxt <= actData;
                end if;
         end case;
    end process out_smpl_nxt;
    
    outData <= dataSampleReg(DHTDATA_H_TOP-1 downto DHTDATA_X_TOP);
    outErr <= errCodeReg;
    
    smpl_state_proc_reg: process(clk, reset, tickPreCnt)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                stSmplReg <= stPowOn;
                smplCntReg <= (others => '0');
                bitCntReg <= (others => '0');
                errCodeReg <= (others => '0');
            else
                if tickPreCnt = '1' then
                    stSmplReg <= stSmplNxt;
                    smplCntReg <= smplCntNxt;
                    bitCntReg <= bitCntNxt;
                    errCodeReg <= errCodeNxt;
                else
                    stSmplReg <= stSmplReg;
                    smplCntReg <= smplCntReg;
                    bitCntReg <= bitCntReg;
                    errCodeReg <= errCodeReg;
                end if;
            end if;
        end if;
    end process smpl_state_proc_reg;
    
    smpl_state_proc_nxt: process(stSmplReg, errCodeReg, smplCntReg, bitCntReg, dhtInSig, trg, chkSum, actData)
    begin
        stSmplNxt <= stSmplReg;
        bitCntNxt <= bitCntReg;
        smplCntNxt <= smplCntReg;
        errCodeNxt <= errCodeReg;
        case stSmplReg is
            when stPowOn =>
                stSmplNxt <= stPowOnDly;
                smplCntNxt <= (others => '0');
                bitCntNxt <= (others => '0');
                errCodeNxt <= (others => '0');
            when stPowOnDly =>
                smplCntNxt <= smplCntReg + 1;
                if smplCntReg(CNT_DLY_POWON) = '1' then
                    stSmplNxt <= stIdle;
                end if;
            when stIdle =>
                if trg = '1' then
                    stSmplNxt <= stTrgSampling;
                    smplCntNxt <= (others => '0');
                    errCodeNxt <= cnvError(ERR_OK);
                end if;
            when stTrgSampling =>           -- drive output to DHT low for > 18ms
                smplCntNxt <= smplCntReg + 1;
    --            if smplCntReg(CNT_START_BIT) = '1' then
                if smplCntReg = CNT_DLY_START_BIT then
                    stSmplNxt <= stWaitStartBitHigh;
                    smplCntNxt <= (others => '0');
                    errCodeNxt <= (others => '0');          -- reset error code
                end if;
            when stWaitStartBitHigh =>       -- drive output to DHT high for 20..40us
                smplCntNxt <= smplCntReg + 1;
                if dhtInSig = '0' then          -- detected falling edge
                    stSmplNxt <= stWaitDHTStartBitLow;
                    smplCntNxt <= (others => '0');
                elsif smplCntReg > CNT_DLY_WAIT then
                    stSmplNxt <= stErrNoDevice;
                end if;
            when stWaitDHTStartBitLow =>        -- wait for the time start bit is driven low by DHT11
                smplCntNxt <= smplCntReg + 1;
                if dhtInSig = '1' then
                    smplCntNxt <= (others => '0');
                    if smplCntReg >= CNT_DLY_BITL_MN then
                        if smplCntReg < CNT_DLY_BITL_MX then
                            stSmplNxt <= stWaitDHTStartBitHigh;
                        else
                            stSmplNxt <= stErrDHTStartBit;
                        end if;
                    else
                        stSmplNxt <= stErrDHTStartBit;
                    end if;
                else                            -- check overflow on counter. go to unconditional wait during '0' 
                  if smplCntReg(CNT_TIMEOUT_BIT) = '1' then
                    stSmplNxt <= stErrSC;
                  end if;
                end if;   
            when stWaitDHTStartBitHigh =>       -- wait for the time start bit is driven high by DHT11
                smplCntNxt <= smplCntReg + 1;
                if dhtInSig = '0' then
                    bitCntNxt <= (others => '0');
                    smplCntNxt <= (others => '0');
                    if smplCntReg >= CNT_DLY_BITL_MN then
                        if smplCntReg < CNT_DLY_BITL_MX then
                            stSmplNxt <= stDly;
                        else
                            stSmplNxt <= stErrDHTStartBit;
                        end if;
                    else
                        stSmplNxt <= stErrDHTStartBit;
                    end if;
                else                            -- check overflow on counter. go to unconditional wait during '0' 
                    if smplCntReg(CNT_TIMEOUT_BIT) = '1' then
                        smplCntNxt <= (others => '0');
                        stSmplNxt <= stErrDHTStartBit;
                    end if;
                end if;   
            when stDly =>               -- needed to compensate for chksum treatment in counting delays
                stSmplNxt <= stWaitTxHigh;       
            when stWaitTxHigh =>        -- wait for rising edge of input signal to check low phase
                smplCntNxt <= smplCntReg + 1;
                if dhtInSig = '1' then
                    smplCntNxt <= (others => '0');
                    if smplCntReg >= CNT_DLY_TXL_MN then
                        if bitCntReg = DHTDATALEN then
                            stSmplNxt <= stChkSum;
                        else
                            if smplCntReg < CNT_DLY_TXL_MX then
                                stSmplNxt <= stWaitTxLow;
                            else
                                stSmplNxt <= stErrTxLow;
                            end if;
                        end if;
                    else
                        stSmplNxt <= stErrTxLow;  -- low phase too short
                    end if;
                else                            -- check overflow on counter. go to unconditional wait during '0' 
                  if smplCntReg(CNT_TIMEOUT_BIT) = '1' then
                    stSmplNxt <= stErrTxTOL;
                  end if;
                end if;   
            when stWaitTxLow =>         -- wait for falling edge of input signal to check high phase and determine bit value
                smplCntNxt <= smplCntReg + 1;
                if dhtInSig = '0' then
                    smplCntNxt <= (others => '0');
                    if smplCntReg >= CNT_DLY_TXH0_MN then
                        if smplCntReg < CNT_DLY_TXH0_MX then
                            -- found BITx = 0
                            stSmplNxt <= stShiftLow;
                        elsif smplCntReg < CNT_DLY_TXH1_MN then 
                            stSmplNxt <= stErrTxHigh;
                        elsif smplCntReg < CNT_DLY_TXH1_MX then
                            -- found BITx = 1
                            stSmplNxt <= stShiftHigh;
                        else
                            stSmplNxt <= stErrTxHigh;
                        end if;
                    else
                        stSmplNxt <= stErrTxHigh;  -- high phase too short
                    end if;
                else                            -- check overflow on counter. go to unconditional wait during '0' 
                    if smplCntReg(CNT_TIMEOUT_BIT) = '1' then
                        stSmplNxt <= stErrTxTOH;
                        smplCntNxt <= (others => '0');
                    end if;
                end if;
            when stShiftLow =>
                stSmplNxt <= stWaitTxHigh;
                bitCntNxt <= bitcntReg + 1;
            when stShiftHigh =>    
                stSmplNxt <= stWaitTxHigh;
                bitCntNxt <= bitcntReg + 1;
            when stChkSum =>
                if chkSum = actData(DHTDATA_X_TOP-1 downto DHTDATA_X_BOT) then
                    stSmplNxt <= stStoreResult;
                else
                   stSmplNxt <= stErrChkSum;
                end if;
            when stStoreResult =>
                stSmplNxt <= stIdle;
            when stErrWaitOnLow =>
                if dhtInSig = '1' then
                    smplCntNxt <= (others => '0');
                    stSmplNxt <= stErrWaitEnd;
                end if;
            when stErrWaitEnd =>
                -- wait CNT_TIMEOUT_BIT times that input remains high
                smplCntNxt <= smplCntReg + 1;
                if dhtInSig = '0' then
                    -- reset counter 
                    smplCntNxt <= (others => '0');
                end if;
                if smplCntReg(CNT_TIMEOUT_BIT) = '1' then
                    stSmplNxt <= stError;
                end if;
            when stError =>
                stSmplNxt <= stIdle;
            -- creating error bits
            when stErrNoDevice =>
                errCodeNxt <= cnvError(ERR_NoDevice);
                stSmplNxt <= stErrWaitEnd;                
            when stErrDHTStartBit =>
                errCodeNxt <= cnvError(ERR_DHTStartBit);
                stSmplNxt <= stErrWaitEnd;                
            when stErrSC => 
                errCodeNxt <= cnvError(ERR_SC);
                stSmplNxt <= stErrWaitOnLow;                
            when stErrTxLow =>
                errCodeNxt <= cnvError(ERR_TxLow);
                stSmplNxt <= stErrWaitEnd;                
            when stErrTxHigh =>
                errCodeNxt <= cnvError(ERR_TxHigh);
                stSmplNxt <= stErrWaitEnd;                
            when stErrTxTOL =>
                errCodeNxt <= cnvError(ERR_TxTOL);
                stSmplNxt <= stErrWaitOnLow;                
            when stErrTxTOH =>
                errCodeNxt <= cnvError(ERR_TxTOH);
                stSmplNxt <= stErrWaitEnd;                
            when stErrChkSum =>
                errCodeNxt <= cnvError(ERR_ChkSum);
                stSmplNxt <= stError;                
        end case;
    end process smpl_state_proc_nxt;



end Behavioral;
