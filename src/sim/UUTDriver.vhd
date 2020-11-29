----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/29/2020 02:28:41 PM
-- Design Name: 
-- Module Name: UUTDriver - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UUTDriver is
	generic (
        C_U_STATUS_WIDTH    : integer := 1;    -- Width of status signal
		C_S_AXI_DATA_WIDTH	: integer := 32;   -- Width of S_AXI data bus
		C_S_AXI_ADDR_WIDTH	: integer := 4;    -- Width of S_AXI address bus
		C_NUM_OF_INTR	    : integer := 2
	);
    port (
        StimDone:       out BOOLEAN;
        StimTrans:      in t_testData;
        
        U_CONTROL:      in std_logic_vector(1 downto 0);
        U_STATUS:       out std_logic_vector(C_U_STATUS_WIDTH-1 downto 0);
        U_VALUES:       out std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
        U_INTR:         out std_logic_vector(C_NUM_OF_INTR-1 downto 0);
		U_WR_TICK:      in  std_logic;
        U_RD_TICK:      out std_logic;

		S_AXI_ACLK:     in std_logic;
		S_AXI_ARESETN:  out std_logic;
		S_AXI_AWADDR:   out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT:   out std_logic_vector(2 downto 0);
		S_AXI_AWVALID:  out std_logic;
		S_AXI_AWREADY:  in  std_logic;
		S_AXI_WDATA:    out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB:    out std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID:   out std_logic;
		S_AXI_WREADY:   in std_logic;
		S_AXI_BRESP:    in std_logic_vector(1 downto 0);
		S_AXI_BVALID:   in std_logic;
		S_AXI_BREADY:   out std_logic;
		S_AXI_ARADDR:   out std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT:   out std_logic_vector(2 downto 0);
		S_AXI_ARVALID:  out std_logic;
		S_AXI_ARREADY:  in std_logic;
		S_AXI_RDATA:    in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP:    in std_logic_vector(1 downto 0);
		S_AXI_RVALID:   in std_logic;
		S_AXI_RREADY:   out std_logic;
		irq:            in std_logic
    );
end UUTDriver;

architecture Behavioral of UUTDriver is
    signal StimTransTrans:      bit;
    
    signal clk:                 std_logic;
begin
    clk <= S_AXI_ACLK;
    
    drive_proc: process
        variable td: t_testData;
    begin
        get(td, StimTrans, StimDone, StimTrans'Transaction);
        wait for 100ns;
        wait until falling_edge(clk);
    end process drive_proc;
--   -------------------------------------------------------------------
--   -- Stimulus process
--    stim_proc: process
--        variable data:      std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        
--        procedure setResult(values: in std_logic_vector; status: in std_logic_vector) is
--        begin
--            U_VALUES <= values;
--            U_STATUS <= status;
--            wait until rising_edge(clk);
--            U_RD_TICK <= '1';
--            wait until rising_edge(clk);
--            U_RD_TICK <= '0';
--        end procedure setResult;
        
--        procedure readData( addr: in integer; data: out std_logic_vector) is
--        begin
--            wait until rising_edge(clk);
--            s00_axi_araddr <= std_logic_vector(to_unsigned(addr, C_S_AXI_ADDR_WIDTH));
--            wait until rising_edge(clk);
--            s00_axi_arvalid <= '1';
--            s00_axi_rready <= '1';
--            wait until s00_axi_arready = '1';
--            wait until rising_edge(clk);
--            s00_axi_arvalid <= '0';
--            wait until s00_axi_rvalid = '1';
--            wait until rising_edge(clk);
--            data := s00_axi_rdata;            
--            wait until rising_edge(clk);
--            wait for 1ns;
--            wait until rising_edge(clk);
--            s00_axi_rready <= '0';
--        end readData;
    
--        procedure writeData( addr: in integer; data: in std_logic_vector) is
--        begin
--            wait until rising_edge(clk);
--            s00_axi_awaddr <= std_logic_vector(to_unsigned(addr, C_S_AXI_ADDR_WIDTH));
--            wait until rising_edge(clk);
--            s00_axi_awvalid <= '1';
--            s00_axi_wready <= '1';
--            wait until s00_axi_awready = '1';
--            wait until rising_edge(clk);
--            s00_axi_awvalid <= '0';
--            wait until rising_edge(clk);
--            s00_axi_wdata <= data;            
--            wait until rising_edge(clk);
--            s00_axi_wvalid <= '1';
--            wait until s00_axi_wready = '1';
--            wait until rising_edge(clk);
--            s00_axi_wvalid <= '0';
--            wait until rising_edge(clk);
--            s00_axi_wready <= '0';
--        end writeData;
    
--    begin
--        s00_axi_awaddr <= (others => '0');
--        s00_axi_araddr <= (others => '0');
--        s00_axi_awprot <= "001";
--        s00_axi_arprot <= "001";
--        s00_axi_awvalid <= '0';
--        s00_axi_arvalid <= '0';
--        s00_axi_wdata <= (others => '0');
--        s00_axi_wstrb <= (others => '0');
--        s00_axi_wvalid <= '0';
--        s00_axi_bready <= '0';
--        s00_axi_rready <= '0';
--        U_VALUES <= (others => '0');
--        U_STATUS <= (others => '0');
--        U_CONTROL <= (others => '0');
--        U_WR_TICK <= '0';
--        U_RD_TICK <= '0';
        
--        axi_readData <= (others => '0');
        
--        wait for 50ns;
--        s00_axi_aresetn <= '0';
--        wait for 100ns;
--        s00_axi_aresetn <= '1';
        
--        setResult(x"12345678", x"02");
--        wait for 100ns;

--        readData(C_STATUS_REG, data);
--        axi_readData <= data;
--        wait for 50ns;

--        readData(C_DATA_REG, data);
--        axi_readData <= data;
--        wait for 50ns;

--        readData(C_STATUS_REG, data);
--        axi_readData <= data;
        
--        wait for 1us;
        
--    end process;

end Behavioral;
