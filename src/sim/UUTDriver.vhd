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
use ieee.numeric_std.all;

use STD.TEXTIO.all;
--use IEEE.std_logic_textio.all;
use work.GenFuncLib.ALL;

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
    constant C_UP_INT_BIT   : integer := 2;

    signal StimTransTrans:      bit;
    signal clk:                 std_logic;

    signal s00_axi_araddr:      std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal s00_axi_arprot:      std_logic_vector(2 downto 0);
	signal s00_axi_arvalid:     std_logic;
	signal s00_axi_rready:      std_logic;
	signal s00_axi_awaddr:      std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal s00_axi_awvalid:     std_logic;
	signal s00_axi_wdata:       std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal s00_axi_wvalid:      std_logic;
	signal s00_axi_bready:      std_logic;

begin
    clk <= S_AXI_ACLK;
    
    S_AXI_ARADDR    <= s00_axi_araddr;
    S_AXI_ARVALID   <= s00_axi_arvalid;
    S_AXI_ARPROT    <= "011";
    S_AXI_RREADY    <= s00_axi_rready;

    S_AXI_AWADDR    <= s00_axi_awaddr;
    S_AXI_AWVALID   <= s00_axi_awvalid;
    S_AXI_AWPROT    <= "011";
    S_AXI_WSTRB     <= "1111";
    S_AXI_WVALID    <= s00_axi_wvalid;
    S_AXI_WDATA     <= s00_axi_wdata;
    
    -- handle bready/bvalid signals: just short circuit them
    S_AXI_BREADY    <= s00_axi_bready;
    s00_axi_bready  <= S_AXI_BVALID; 
    
    drive_proc: process
        variable td: t_testData;
        variable axiData: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        variable intCntrlData: std_logic_vector(1 downto 0);
        variable res: t_result;
        
        -- set internal registers driven via DHT11 reader
        procedure writeIntData(values: in std_logic_vector; status: in std_logic_vector) is
        begin
            U_VALUES <= values;
            U_STATUS <= status;
            U_INTR <= status(C_UP_INT_BIT downto C_UP_INT_BIT - (C_NUM_OF_INTR -1));
            wait until rising_edge(clk);
            U_RD_TICK <= '1';
            wait until rising_edge(clk);
            U_RD_TICK <= '0';
        end procedure writeIntData;
        
        -- read actual set of control register and validate with expected setting
        procedure readIntData(value: out std_logic_vector) is
        begin
            value := U_CONTROL; 
        end; 
        
        -- drive ACI4 Lite bus to read data from a given address
        procedure readExtData( addr: in std_logic_vector; data: out std_logic_vector) is
        begin
            wait until rising_edge(clk);
            s00_axi_araddr <= addr;
            wait until rising_edge(clk);
            s00_axi_arvalid <= '1';
            s00_axi_rready <= '1';
            wait until s_axi_arready = '1';
            wait until rising_edge(clk);
            s00_axi_araddr <= (others => '0');
            s00_axi_arvalid <= '0';
            wait until s_axi_rvalid = '1';
            wait until rising_edge(clk);
            data := s_axi_rdata;            
            s00_axi_rready <= '0';
        end readExtData;

        -- drive AXI4 Lite but to write data to a given address
        procedure writeExtData( addr: in std_logic_vector; data: in std_logic_vector) is
        begin
            wait until rising_edge(clk);
            s00_axi_awaddr <= addr;
            wait until rising_edge(clk);
            s00_axi_awvalid <= '1';
            wait until rising_edge(clk);
            s00_axi_wvalid <= '1';
            s00_axi_wdata <= data;            
--            wait until s_axi_awready = '1';
--            wait until rising_edge(clk);
            wait until s_axi_wready = '1';
            wait until rising_edge(clk);
            s00_axi_awvalid <= '0';
            s00_axi_wvalid <= '0';
        end writeExtData;
    
        
    ------------------------------------------------------------------------------
    begin
        -- setting defualt values
        U_VALUES <= (others => 'Z');
        U_STATUS <= (others => 'Z');
        U_INTR <= (others => 'Z');
        U_RD_TICK <= '0';
        S_AXI_ARESETN <= '1';

        s00_axi_araddr <= (others => '0');
        s00_axi_arvalid <= '0';
        s00_axi_rready <= '0';
        
        s00_axi_awaddr <= (others => '0');
        s00_axi_awvalid <= '0';
        s00_axi_wvalid <= '0';
        s00_axi_wdata <= (others => '0');
        
        get(td, StimTrans, StimDone, StimTrans'Transaction);
        wrOut("--- " & td.desc);
        
        -- Reset Transaction
        if td.trans = TransReset then
            wait until rising_edge(clk);
            S_AXI_ARESETN <= '0';
            wait for 100ns;            
            wait until rising_edge(clk);
            S_AXI_ARESETN <= '1';            
        
        -- external transaction
        elsif td.trans = TransExt then
            if td.extData.op = Read then
                readExtData(td.extData.addr, axiData);
                
                -- check results; external transactions will return only one value corresponding to the first result entry
                res := td.expResult(1);
                if res.f = true then
                    assert(res.res = axiData) report "read value unequal: exp: 0x" & to_hex_string(res.res) & " act: 0x" & to_hex_string(axiData);
                end if; 
            elsif td.extData.op = Write then
                writeExtData(td.extData.addr, td.extData.data);
            else
                wait for 100ns;
            end if;
            
        -- internal transaction
        elsif td.trans = TransInt then
            if td.intData.op = Write then
                writeIntData(td.intData.data, td.intData.status);
            elsif td.intData.op = Read then
                readIntData(intCntrlData);
            else
                wait for 100ns;
            end if;
        
        -- not recognized transaction
        else
            wait for 50ns;
        end if;
        wait until falling_edge(clk);
    end process drive_proc;

end Behavioral;
