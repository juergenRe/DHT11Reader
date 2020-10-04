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
use IEEE.numeric_std.all;
use work.DHT11SimuTestDefs.ALL;

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
constant NDIV:          integer := 99;

signal outData:        std_logic_vector(31 downto 0);      -- data value
signal outErr:         std_logic_vector(3 downto 0);       -- error code
signal rdy:            std_logic;                          -- component ready to receive new settings
signal dhtOutSig:      std_logic;                          -- driver line to DHT11

signal trg:            std_logic := '0';                   -- new settings trigger
signal dhtInSig:       std_logic := '1';                   -- input line towards simulated DHT11

type t_testState is (stPowOn, stIdle, stTestSetUp, stTestStart, stTestRun, stTestEnd);
signal testStateReg:    t_testState;
signal testStateNxt:    t_testState;
signal startTest:       std_logic;
signal testDone:        std_logic;
signal testCnt:         unsigned(4 downto 0);       -- holds the current test index

----------------------------------------------------------------
signal expectErr:       integer;

----------------------------------------
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
        txData:         in std_logic_vector(NDATABIT-1 downto 0)
     );
end component;

procedure wrOut (arg : in string := "") is
begin
  std.textio.write(std.textio.output, arg & LF);
end procedure wrOut;

begin
    uut: DHT11Control
        generic map(
            NDIV        => NDIV,  
            POWONDLY    => false
        )
        port map (
            clk         => clk,     
            reset       => reset,
            cntTick     => open,
            outData     => outData,
            outErr      => outErr,
            trg         => trg,
            rdy         => rdy,
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
            txData      => txData    
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
        startTest <= '0';
        wait for 200 ns;
        reset <= '1';
        wait for 100ns;
        reset <= '0';
		wait until rdy = '1';
		wait for 200ns;
		wait until rising_edge(clk);
		--wait until testDone = '1';
		startTest <= '1';
		wait until rising_edge(clk);
		wait until testDone = '0';
		wait until rising_edge(clk);
		startTest <= '0';
		wait until testDone = '1';
		
		wait for 100ns;
		assert false report "Simulation done" severity failure;
	end process;
	

----------------------------------------------------------------------------------
-- traverse through test sets triggered by trg signal
    dht11_test_pattern_reg: process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                testStateReg <= stPowOn;
            else
                testStateReg <= testStateNxt;
            end if;
        end if;
    end process dht11_test_pattern_reg;
    
    testDone <= '1' when (testStateReg = stIdle) else '0';

    dht11_test_pattern_nxt: process(testStateReg, startTest, rdy)
        variable actIdx:    integer := 0;
        variable dataVal:   std_logic_vector(31 downto 0);
        variable errC:      integer;
        variable desc:      string(1 to 40);
        variable res:       integer;
        variable errCode:   integer;
        variable t0, t1, t2, t3, t4, t5, t6: time;
        
        procedure setTiming(t0, t1, t2, t3, t4, t5, t6: in time) is
        begin
            t_trigin <= t0; 
            t_wakeup <= t1; 
            t_startL <= t2;
            t_startH <= t3;
            t_bitL   <= t4;
            t_bitH0  <= t5;
            t_bitH1  <= t6;
        end;
    begin
        case testStateReg is
            when stPowOn =>
                testStateNxt <= stIdle;
                testCnt <= (others => '0');
            when stIdle =>
                actIdx := 0;
                if startTest = '1' and rdy = '1' then
                    testStateNxt <= stTestSetUp;
                end if;
            when stTestSetUp =>
                testCnt <= TO_UNSIGNED(actIdx, 5);
                getActData(actIdx, dataVal, t0, t1, t2, t3, t4, t5, t6, errC, desc);
                setTiming(t0, t1, t2, t3, t4, t5, t6);
                txData <= dataVal & calc_crc(dataVal);
                expectErr <= errC;
                wrOut("---------------------------------------------");
                wrOut("Start Test: " & desc);
                testStateNxt <= stTestStart;
            when stTestStart =>
                trg <= '1';
                if rdy = '0' then
                    testStateNxt <= stTestRun;
                    trg <= '0';
                end if;
            when stTestRun => 
                -- executing reception, wait till finished
                if rdy = '1' then
                    res := conv_integer(outdata);
                    errCode := conv_integer(outErr);
                    assert (errC = errCode)
                        report "Expected status unequal expect=" & integer'image(errC) & " => measured=" & integer'image(errCode) severity error;
                        
                    if errCode = 0 then
                        assert res = conv_integer(dataVal)
                            report "Expected data values unequal data=" & integer'image(conv_integer(dataVal)) & " => outH/T: " & integer'image(res) severity error;
                    end if;

                    testStateNxt <= stTestSetUp;
                    actIdx := actIdx + 1;
                    if actIdx = test_data'length then
                        testStateNxt <= stTestEnd;
                    end if;
                end if;
            when stTestEnd =>
                wrOut("---------------------------------------------");
                wrOut("Test done");
                testStateNxt <= stIdle; 
        end case;
    end process dht11_test_pattern_nxt;
    
end Behavioral;
  
    
   
   
    
   
   
