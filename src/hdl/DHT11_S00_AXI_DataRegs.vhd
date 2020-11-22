----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/15/2020 06:29:36 PM
-- Design Name: 
-- Module Name: DHT11_S00_AXI_DataRegs - Behavioral
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

entity DHT11_S00_AXI_DataRegs is
	generic (
        C_U_STATUS_WIDTH    : integer := 1;    -- Width of status signal
		C_S_AXI_DATA_WIDTH	: integer := 32;   -- Width of S_AXI data bus
		C_S_AXI_ADDR_WIDTH	: integer := 4;    -- Width of S_AXI address bus
		C_ADDR_LSB          : integer := 2
	);
    port (
        U_CONTROL:          out std_logic_vector(1 downto 0);
        U_STATUS:           in std_logic_vector(C_U_STATUS_WIDTH-1 downto 0);          --  Status bits: Ready, Error, DataValid
        U_VALUES:           in std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);      -- measured values:
		U_WR_TICK:          out std_logic;
        U_RD_TICK:          in std_logic;
    
		S_AXI_ACLK:         in std_logic;
		S_AXI_ARESETN:      in std_logic;
		S_AXI_WSTRB:        in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WDATA:        in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

        axi_awaddr:         in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);   
        axi_araddr:         in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
        den_w:              in std_logic;
        den_r:              in std_logic;
        reg_data_out:       out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0)
	);
end DHT11_S00_AXI_DataRegs;

architecture Behavioral of DHT11_S00_AXI_DataRegs is
    constant C_DREG_WIDTH: integer := 2;         -- we use only 4 aregisters in that implementation

	---- Number of Slave Registers 4
	signal slv_reg0:       std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg1:       std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg2:       std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3:       std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    
    signal wren_dly:        std_logic;

begin
    U_CONTROL <= slv_reg2(1 downto 0);
    U_WR_TICK <= wren_dly;
    
	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(C_DREG_WIDTH-1 downto 0); 
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
--	      slv_reg0 <= (others => '0');
--	      slv_reg1 <= (others => '0');
	      slv_reg2 <= (others => '0');
	      slv_reg3 <= (others => '0');
	    else
	      loc_addr := axi_awaddr(C_ADDR_LSB + C_DREG_WIDTH-1 downto C_ADDR_LSB);
	      if (den_w = '1') then
	        case loc_addr is
             -- slv_reg0 and 1 will not written to from AXI, read-only
--	          when b"00" =>
--	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
--	                -- Respective byte enables are asserted as per write strobes                   
--	                -- slave registor 0
--	                slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--	              end if;
--	            end loop;
--	          when b"01" =>
--	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
--	                -- Respective byte enables are asserted as per write strobes                   
--	                -- slave registor 1
--	                slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--	              end if;
--	            end loop;
	          when b"10" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 2
	                slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"11" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 3
	                slv_reg3(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when others =>
--	            slv_reg0 <= slv_reg0;
--	            slv_reg1 <= slv_reg1;
	            slv_reg2 <= slv_reg2;
	            slv_reg3 <= slv_reg3;
	        end case;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, axi_araddr)
	variable loc_addr :std_logic_vector(C_DREG_WIDTH-1 downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(C_ADDR_LSB + C_DREG_WIDTH-1 downto C_ADDR_LSB);
	    case loc_addr is
	      when b"00" =>
	        reg_data_out <= slv_reg0;
	      when b"01" =>
	        reg_data_out <= slv_reg1;
	      when b"10" =>
	        reg_data_out <= slv_reg2;
	      when b"11" =>
	        reg_data_out <= slv_reg3;
	      when others =>
	        reg_data_out  <= (others => '0');
	    end case;
	end process; 

	-- Add user logic here
    -- write result data to registers 0 and 1
	wr_out_data: process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      slv_reg0 <= (others => '0');
	      slv_reg1 <= (others => '0');
	    else
	      if U_RD_TICK = '1' then
            slv_reg0 <= U_VALUES;
            slv_reg1(C_U_STATUS_WIDTH-1 downto 0) <= U_STATUS;
            slv_reg1(C_S_AXI_DATA_WIDTH-1 downto C_U_STATUS_WIDTH) <= slv_reg1(C_S_AXI_DATA_WIDTH-1 downto C_U_STATUS_WIDTH);  
          else
            slv_reg0 <= slv_reg0;
            slv_reg1 <= slv_reg1;
          end if;
        end if;
      end if;
    end process wr_out_data;
    
    -- generate the write tick with a delay of one clk cycle, otherwise data has not yet propagated
    wr_tick_gen: process(S_AXI_ACLK)
    begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      wren_dly <= '0';
	    else
          if den_w = '1' then
            wren_dly <= '1';
          else
            wren_dly <= '0';
          end if;
        end if;
      end if; 
    end process wr_tick_gen;
	-- User logic ends
    


end Behavioral;
