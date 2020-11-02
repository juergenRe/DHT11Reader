----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/29/2020 12:22:19 PM
-- Design Name: 
-- Module Name: DHT11ControlWrap_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--   Simulates DHT11Wrapper with all test cases in single shot mode 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

use work.DHT11SimuTestDefs.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DHT11ControlWrap_tb is
end DHT11ControlWrap_tb;

architecture Behavioral of DHT11ControlWrap_tb is
   -- Clock period definitions
constant clk_period:    time := 10 ns;
constant C_S_AXI_DATA_WIDTH:    integer := 32;
constant C_U_STATUS_WIDTH: integer := 8;

   --internal signals
signal clk:             std_logic := '0';
signal reset:           std_logic := '0';

constant N_AXI:         integer := 32;
constant NDIV:          integer := 99;

constant BIT_RDY:       integer := 2;
constant BIT_DAV:       integer := 1;
constant BIT_ERR:       integer := 0;

signal U_CONTROL:       std_logic_vector(1 downto 0) := "00";
signal U_STATUS:        std_logic_vector(7 downto 0);
signal U_VALUES:        std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
signal U_WR_TICK:       std_logic := '0';
signal U_RD_TICK:       std_logic;
signal dhtInSig:        std_logic;
signal dhtOutSig:       std_logic;

signal actStatus:       std_logic_vector(7 downto 0);
signal expectErr:       integer;
signal b_chksumErr:     std_logic;
signal outErr:          std_logic_vector(3 downto 0);       -- error code

type t_testState is (stPowOn, stForceReset, stIdle, stTestSetUp, stTestStart, stTestAssertStart, stTestRun, stTestEnd);
signal testStateAct:    t_testState;
--signal testStateNxt:    t_testState;
signal startTest:       std_logic := '0';
signal testDone:        std_logic := '0';
signal testCnt:         unsigned(4 downto 0);       -- holds the current test index
signal trgSetControl:   std_logic := '0';
signal trgSetControlDone: std_logic := '0';
signal trgSetTiming:    std_logic := '0';
signal trgSetTimingDone: std_logic := '0';

signal tt0, tt1:        time;


component DHT11Wrapper is
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
		-- control bits to start conversion and have automatic conversion every second
        U_CONTROL   : in std_logic_vector(1 downto 0);
        --  Status bits: 7:4: Error code; 3: unused; 2: Rdy 1: Data avail; 0: Error bit
        U_STATUS    : out std_logic_vector(7 downto 0);
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
end component;

component DHT11DeviceSimulation is
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
        b_chksumErr:    in std_logic;
        txData:         in std_logic_vector(NDATABIT-1 downto 0)
     );
end component;

procedure wrOut (arg : in string := "") is
begin
  std.textio.write(std.textio.output, arg & LF);
end procedure wrOut;

-- waits for status change
procedure waitForStatusChng( actStatus: out std_logic_vector; checkBit: in integer; chkVal: in std_logic; tout: in time) is
    variable cond: boolean := False;
    variable status: std_logic_vector(7 downto 0);
    variable ts: time;   -- start time
    
    -- calculate time out condition
    function tocond(tout: time; ts: time) return boolean is
    begin
        return (tout > 0ns) and ((now - ts) > tout);
    end function;
begin
    ts := now;
    while not cond loop
        wait until (U_RD_TICK = '1') or tocond(tout, ts);
        status := U_STATUS;
        if tocond(tout, ts) then
            exit;
        end if;
        if status(checkBit) = chkVal then
            exit;
        end if;
        wait until (U_RD_TICK = '0') or tocond(tout, ts);
        status := U_STATUS;
        if tocond(tout, ts) then
            exit;
        end if;
    end loop;
    actStatus := status;
end waitForStatusChng;


begin

uut: DHT11Wrapper
    generic map (
	    C_U_STATUS_WIDTH        => C_U_STATUS_WIDTH,
        C_S_AXI_DATA_WIDTH      => N_AXI,
        NDIV                    => NDIV,
        PWRONDLY                => 10
    )
    port map (
        clk         => clk,
        reset       => reset,
        U_CONTROL   => U_CONTROL,
        U_STATUS    => U_STATUS,
        U_VALUES    => U_VALUES,
        U_WR_TICK   => U_WR_TICK,
        U_RD_TICK   => U_RD_TICK,
        dhtInSig    => dhtInSig,
        dhtOutSig   => dhtOutSig
    );

dht11_dvc: DHT11DeviceSimulation
    generic map (     
        NDATABIT    => NDATABIT
    )          
    port map (        
        clk         => clk,
        reset       => reset,
        dhtInSig    => dhtInSig,
        dhtOutSig   => dhtOutSig,
        t_trigin    => t_trigin, 
        t_wakeup    => t_wakeup,
        t_startL    => t_startL,
        t_startH    => t_startH,
        t_bitL      => t_bitL, 
        t_bitH0     => t_bitH0,
        t_bitH1     => t_bitH1,  
        b_chksumErr => b_chksumErr,
        txData      => txData    
     );           	
    outErr <= U_STATUS(7 downto 4);     -- extract error code

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
        startTest <= '0';
        wait for 200 ns;
		wait until rising_edge(clk);

		wait until testDone = '1';
		wait until rising_edge(clk);

		startTest <= '1';
		wait until rising_edge(clk);

		wait until testDone = '0';
		wait until rising_edge(clk);

		startTest <= '0';
		wait until testDone = '1';
		
		wait for 1ms;
		assert false report "Simulation done" severity failure;
	end process;
	
----------------------------------------------------------------------------------
    
    dht11_test_pattern_nxt: process   
        variable actIdx:    integer := 0;
        variable dataVal:   std_logic_vector(31 downto 0);
        variable errC:      integer;
        variable errBit:    std_logic;
        variable desc:      string(1 to 40);
        variable res:       integer;
        variable errCode:   integer;
        variable stat:      std_logic_vector(7 downto 0);
        variable t0, t1, t2, t3, t4, t5, t6: time;
        variable bchk:      std_logic;
        variable testStateReg: t_testState := stPowOn;
        variable testStateNxt: t_testState := stPowOn;
        
        -- trigger change on U_CONTROL
        procedure setControlReg(value: in std_logic_vector) is
        begin
            U_CONTROL <= value;
            wait until rising_edge(clk);
            U_WR_TICK <= '1';
            wait until rising_edge(clk);
            U_WR_TICK <= '0';
        end procedure setControlReg;

        -- set timing parameters for DHT11 simulation
        procedure setTiming(t0, t1, t2, t3, t4, t5, t6: in time) is
        begin
            t_trigin    <= t0; 
            t_wakeup    <= t1; 
            t_startL    <= t2;
            t_startH    <= t3;
            t_bitL      <= t4;
            t_bitH0     <= t5;
            t_bitH1     <= t6;
        end;
    begin
        wait until rising_edge(clk);
        testStateReg := testStateNxt;
        testStateAct <= testStateReg;
        testDone <= '0';
        case testStateReg is
            when stPowOn =>
                -- check behaviour when no reset is given
                testCnt <= (others => '0');
                waitForStatusChng(stat, BIT_RDY, '1', 0ns);
                actStatus <= stat;
                testStateNxt := stForceReset;
            when stForceReset =>
                wait for 200 ns;
                -- apply reset & wait till ready
                reset <= '1';
                wait for 100ns;
                reset <= '0';
        
                waitForStatusChng(stat, BIT_RDY, '1', 0ns);
                actStatus <= stat;
                wait for 200 ns;
                testStateNxt := stIdle;
            when stIdle =>
                actIdx := 0;
                testDone <= '1';
                if startTest = '1' then
                    testStateNxt := stTestSetUp;
                end if;
            when stTestSetUp =>
                testCnt <= TO_UNSIGNED(actIdx, 5);
                getActData(actIdx, dataVal, t0, t1, t2, t3, t4, t5, t6, bchk, errC, desc);
                setTiming(t0, t1, t2, t3, t4, t5, t6);
                b_chksumErr <= bchk;
                txData <= dataVal & calc_crc(dataVal);
                if errC > ERR_OK then
                    errBit := '1';
                else
                    errbit := '0';
                end if;
                expectErr <= errC;
                wrOut("---------------------------------------------");
                wrOut("Start Test: " & desc);
                testStateNxt := stTestStart;
            when stTestStart =>
                -- initiate a sample
                setControlReg("01");
                waitForStatusChng(stat, BIT_RDY, '0', 0ns);
                setControlReg("00");
                testStateNxt := stTestAssertStart;
            when stTestAssertStart =>
                tt0 <= now;
                waitForStatusChng(stat, BIT_DAV, '0', 1100ns);
                assert (now - tt0) < 1100ns
                    report "Falling Edge dav_status missing" severity failure;
                testStateNxt := stTestRun;
            when stTestRun => 
                -- executing reception, wait till finished
                waitForStatusChng(stat, BIT_DAV, '1', 0ns);
                actStatus <= stat;
                assert (stat and x"07") = "01" & errBit
                    report "Act status RDY/ERR unexpected: expect=" & integer'image(conv_integer("01" & errBit)) & " => measured=" & integer'image(conv_integer(stat)) severity error;
                    
                waitForStatusChng(stat, BIT_RDY, '1', 0ns); 
                res := conv_integer(U_VALUES);
                errCode := conv_integer(outErr);
                assert (errC = errCode)
                    report "Expected status unequal: expect=" & integer'image(errC) & " => measured=" & integer'image(errCode) severity error;
                    
                if errCode = 0 then
                    assert res = conv_integer(dataVal)
                        report "Expected data values unequal: expect data=" & integer'image(conv_integer(dataVal)) & " => measured data: " & integer'image(res) severity error;
                end if;

                testStateNxt := stTestSetUp;
                actIdx := actIdx + 1;
                if actIdx = test_data'length then
                    testStateNxt := stTestEnd;
                end if;
            when stTestEnd =>
                wrOut("---------------------------------------------");
                wrOut("Test done");
                testStateNxt := stIdle; 
        end case;
    end process dht11_test_pattern_nxt;

end Behavioral;
