----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/02/2020 03:27:32 PM
-- Design Name: 
-- Module Name: DHT11AXI_tb - Behavioral
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

use work.GenFuncLib.ALL;
use work.AXISimuTestDefs.ALL;

-- Program is oriented at structured test bench at "https://www.edaplayground.com/x/328c"

entity DHT11AXI_tb is
--  Port ( );
end DHT11AXI_tb;

architecture Behavioral of DHT11AXI_tb is
   -- Clock period definitions
constant clk_period:    time := 10 ns;

constant C_U_STATUS_WIDTH:      integer := 8;
constant C_S_AXI_DATA_WIDTH:    integer := 32;
constant C_S_AXI_ADDR_WIDTH:    integer := 6;
constant C_NUM_OF_INTR:         integer := 2;
constant C_INTR_SENSITIVITY:    std_logic_vector := x"FFFFFFFF";
constant C_INTR_ACTIVE_STATE:   std_logic_vector := x"FFFFFFFF";
constant C_IRQ_SENSITIVITY:     integer := 1;
constant C_IRQ_ACTIVE_STATE	:   integer := 1;

constant N_AXI:         integer := C_S_AXI_DATA_WIDTH;
constant NDIV:          integer := 99;

constant C_DATA_REG:    integer := 0;
constant C_STATUS_REG:  integer := 4;
constant C_CTRL_REG:    integer := 8;

   --internal signals
signal clk:             std_logic := '0';
signal reset:           std_logic := '0';

-- user signals
signal U_CONTROL:       std_logic_vector(1 downto 0) := "00";
signal U_STATUS:        std_logic_vector(7 downto 0);
signal U_VALUES:        std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
signal U_WR_TICK:       std_logic := '0';
signal U_RD_TICK:       std_logic;
signal irq:             std_logic;

-- axi signals
--signal s00_axi_aclk	    : std_logic;
signal s00_axi_aresetn	: std_logic := '1';
signal s00_axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
signal s00_axi_awprot	: std_logic_vector(2 downto 0);
signal s00_axi_awvalid	: std_logic;
signal s00_axi_awready	: std_logic;
signal s00_axi_wdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
signal s00_axi_wstrb	: std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
signal s00_axi_wvalid	: std_logic;
signal s00_axi_wready	: std_logic;
signal s00_axi_bresp	: std_logic_vector(1 downto 0);
signal s00_axi_bvalid	: std_logic;
signal s00_axi_bready	: std_logic;
signal s00_axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
signal s00_axi_arprot	: std_logic_vector(2 downto 0);
signal s00_axi_arvalid	: std_logic;
signal s00_axi_arready	: std_logic;
signal s00_axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
signal s00_axi_rresp	: std_logic_vector(1 downto 0);
signal s00_axi_rvalid	: std_logic;
signal s00_axi_rready	: std_logic;

---------------------------------------
-- values behind AXI
signal axi_readData	    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

begin
uut: entity work.DHT11_S00_AXI
	generic map (
	    C_U_STATUS_WIDTH    => C_U_STATUS_WIDTH,
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH,
		C_NUM_OF_INTR	    => C_NUM_OF_INTR,
		C_INTR_SENSITIVITY	=> C_INTR_SENSITIVITY,
		C_INTR_ACTIVE_STATE	=> C_INTR_ACTIVE_STATE,
		C_IRQ_SENSITIVITY	=> C_IRQ_SENSITIVITY,
		C_IRQ_ACTIVE_STATE	=> C_IRQ_ACTIVE_STATE
	)
    port map (
        U_CONTROL       => U_CONTROL,       
        U_STATUS        => U_STATUS, 
        U_VALUES        => U_VALUES, 
	    U_INTR          => U_STATUS(3 downto 1),
        U_WR_TICK       => U_WR_TICK, 
		U_RD_TICK       => U_RD_TICK,
		irq             => irq,

		S_AXI_ACLK	    => clk,	  
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,	
		S_AXI_AWPROT	=> s00_axi_awprot,	
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	    => s00_axi_wdata,
		S_AXI_WSTRB	    => s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,	
		S_AXI_WREADY	=> s00_axi_wready,	
		S_AXI_BRESP	    => s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,	
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	    => s00_axi_rdata,
		S_AXI_RRESP	    => s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,	
		S_AXI_RREADY	=> s00_axi_rready
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
        variable data:      std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        
        procedure setResult(values: in std_logic_vector; status: in std_logic_vector) is
        begin
            U_VALUES <= values;
            U_STATUS <= status;
            wait until rising_edge(clk);
            U_RD_TICK <= '1';
            wait until rising_edge(clk);
            U_RD_TICK <= '0';
        end procedure setResult;
        
        procedure readData( addr: in integer; data: out std_logic_vector) is
        begin
            wait until rising_edge(clk);
            s00_axi_araddr <= std_logic_vector(to_unsigned(addr, C_S_AXI_ADDR_WIDTH));
            wait until rising_edge(clk);
            s00_axi_arvalid <= '1';
            s00_axi_rready <= '1';
            wait until s00_axi_arready = '1';
            wait until rising_edge(clk);
            s00_axi_arvalid <= '0';
            wait until s00_axi_rvalid = '1';
            wait until rising_edge(clk);
            data := s00_axi_rdata;            
            wait until rising_edge(clk);
            wait for 1ns;
            wait until rising_edge(clk);
            s00_axi_rready <= '0';
        end readData;
    
        procedure writeData( addr: in integer; data: in std_logic_vector) is
        begin
            wait until rising_edge(clk);
            s00_axi_awaddr <= std_logic_vector(to_unsigned(addr, C_S_AXI_ADDR_WIDTH));
            wait until rising_edge(clk);
            s00_axi_awvalid <= '1';
            s00_axi_wready <= '1';
            wait until s00_axi_awready = '1';
            wait until rising_edge(clk);
            s00_axi_awvalid <= '0';
            wait until rising_edge(clk);
            s00_axi_wdata <= data;            
            wait until rising_edge(clk);
            s00_axi_wvalid <= '1';
            wait until s00_axi_wready = '1';
            wait until rising_edge(clk);
            s00_axi_wvalid <= '0';
            wait until rising_edge(clk);
            s00_axi_wready <= '0';
        end writeData;
    
    begin
        s00_axi_awaddr <= (others => '0');
        s00_axi_araddr <= (others => '0');
        s00_axi_awprot <= "001";
        s00_axi_arprot <= "001";
        s00_axi_awvalid <= '0';
        s00_axi_arvalid <= '0';
        s00_axi_wdata <= (others => '0');
        s00_axi_wstrb <= (others => '0');
        s00_axi_wvalid <= '0';
        s00_axi_bready <= '0';
        s00_axi_rready <= '0';
        U_VALUES <= (others => '0');
        U_STATUS <= (others => '0');
        U_CONTROL <= (others => '0');
        U_WR_TICK <= '0';
        U_RD_TICK <= '0';
        
        axi_readData <= (others => '0');
        
        wait for 50ns;
        s00_axi_aresetn <= '0';
        wait for 100ns;
        s00_axi_aresetn <= '1';
        
        setResult(x"12345678", x"02");
        wait for 100ns;

        readData(C_STATUS_REG, data);
        axi_readData <= data;
        wait for 50ns;

        readData(C_DATA_REG, data);
        axi_readData <= data;
        wait for 50ns;

        readData(C_STATUS_REG, data);
        axi_readData <= data;
        
        wait for 1us;
        
    end process;
end Behavioral;
