----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/12/2020 05:07:48 PM
-- Design Name: 
-- Module Name: UUTMonitor - Behavioral
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

use work.AXISimuTestDefs.ALL;
use ieee.numeric_std.all;

use STD.TEXTIO.all;
use work.GenFuncLib.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UUTMonitor is
	generic (
        C_U_STATUS_WIDTH    : integer := 1;    -- Width of status signal
		C_S_AXI_DATA_WIDTH	: integer := 32;   -- Width of S_AXI data bus
		C_S_AXI_ADDR_WIDTH	: integer := 4;    -- Width of S_AXI address bus
		C_NUM_OF_INTR	    : integer := 2
	);
    port (
        TrgStart:       in bit;
        MonTrans:       out t_testData;
        StimTrans:      in t_testData;
        
        U_CONTROL:      in std_logic_vector(1 downto 0);
        U_STATUS:       in std_logic_vector(C_U_STATUS_WIDTH-1 downto 0);
        U_VALUES:       in std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
        U_INTR:         in std_logic_vector(C_NUM_OF_INTR-1 downto 0);
		U_WR_TICK:      in std_logic;
        U_RD_TICK:      in std_logic;

		S_AXI_ACLK:     in std_logic;
		S_AXI_ARESETN:  in std_logic;
		S_AXI_AWADDR:   in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT:   in std_logic_vector(2 downto 0);
		S_AXI_AWVALID:  in std_logic;
		S_AXI_AWREADY:  in std_logic;
		S_AXI_WDATA:    in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB:    in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID:   in std_logic;
		S_AXI_WREADY:   in std_logic;
		S_AXI_BRESP:    in std_logic_vector(1 downto 0);
		S_AXI_BVALID:   in std_logic;
		S_AXI_BREADY:   in std_logic;
		S_AXI_ARADDR:   in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT:   in std_logic_vector(2 downto 0);
		S_AXI_ARVALID:  in std_logic;
		S_AXI_ARREADY:  in std_logic;
		S_AXI_RDATA:    in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP:    in std_logic_vector(1 downto 0);
		S_AXI_RVALID:   in std_logic;
		S_AXI_RREADY:   in std_logic;
		irq:            in std_logic
    );
end UUTMonitor;

architecture Behavioral of UUTMonitor is
    signal clk:                 std_logic;
    signal trgStimTrans:        std_logic := '0';
    signal trgMonTrans:         std_logic := '0';
    signal Dummy:               boolean;

begin
    clk <= S_AXI_ACLK;
    
    mon_proc: process
--        variable vStimu:    t_testData;
        variable vMoni:     t_testData;
        variable vData1: std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
        variable vData2: std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
        variable vData3: std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
        variable nullTrg: std_logic_vector(C_NB_TRIGGERS-1 downto 0) := (others => '0');
    begin
        vData1 := (others => '0');
        vData2 := (others => '0');
        vData3 := (others => '0');
        trgStimTrans <= '0';
        trgMonTrans <= '0';
        if TrgStart = '0' then
            wrOut("MON: Wait on TrgStart");
            wait until TrgStart = '1';  -- do not operate when not yet started
        end if;

--        wait until StimTrans'Transaction'Event;
        get(vMoni, StimTrans, Dummy, StimTrans'Transaction);
        trgStimTrans <= '1';
        if StimTrans.trans = TransReset then
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            vData1(1 downto 0) := U_CONTROL;
        elsif StimTrans.trans = TransInt and StimTrans.intData.op = Read then -- check for internal read
            vData1(1 downto 0) := U_CONTROL;
        elsif StimTrans.trans = TransInt and StimTrans.intData.op = Write then
            wait until rising_edge(U_RD_TICK);
            wait until falling_edge(clk);
            vData1 := (others => '0');
        elsif StimTrans.trans = TransExt and StimTrans.extData.op = Read then
            wait until rising_edge(S_AXI_RVALID);
            wait until falling_edge(clk);
            vData1 := S_AXI_RDATA;
        elsif StimTrans.trans = TransExt and StimTrans.extData.op = Write then
            wait until rising_edge(S_AXI_WREADY);
            vData1 := S_AXI_WDATA;
        end if;

        vMoni.expResult(1).f := true;
        vMoni.expResult(1).res := vData1; 
        trgMonTrans <= '1';
        nb_put(vMoni, MonTrans);
--        MonDataPut(vData1, vData2, vData3, 1, Montrans);       -- create monitoring out of collected data        
        wait until rising_edge(clk);
    end process mon_proc;

end Behavioral;
