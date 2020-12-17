library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DHT11_S00_AXI is
	generic (
        C_U_STATUS_WIDTH    : integer := 1;    -- Width of status signal
		C_S_AXI_DATA_WIDTH	: integer := 32;   -- Width of S_AXI data bus
		C_S_AXI_ADDR_WIDTH	: integer := 4;    -- Width of S_AXI address bus
		C_NUM_OF_INTR	    : integer := 2;
		C_INTR_SENSITIVITY	: std_logic_vector := x"FFFFFFFF";
		C_INTR_ACTIVE_STATE	: std_logic_vector := x"FFFFFFFF";
		C_IRQ_SENSITIVITY	: integer := 1;
		C_IRQ_ACTIVE_STATE	: integer := 1
	);
	port (
		-- Users to add ports here:
		-- register assignment: 0: U_VALUES; 4: U_STATUS; 8: U_CONTROL 
		-- Control port: AUTO, TRG
        U_CONTROL   : out std_logic_vector(1 downto 0);
        --  Status bits: Ready, Error, DataValid
        U_STATUS    : in std_logic_vector(C_U_STATUS_WIDTH-1 downto 0);
        -- measured values:
        -- U_VALUES(31 downto 16): 16 bits for humidity
        -- U_VALUES(15 downto 0):  16 bits for temperature
        U_VALUES    : in std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
        -- user interrupt entris
        U_INTR      : in std_logic_vector(C_NUM_OF_INTR-1 downto 0);
		-- User ports ends
		-- Do not modify the ports beyond this line
		U_WR_TICK:  out std_logic;
        -- tick for updating new data in register
        U_RD_TICK: in std_logic;

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic;
		irq             : out std_logic
	);
end DHT11_S00_AXI;

architecture arch_imp of DHT11_S00_AXI is

	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- C_ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- C_ADDR_LSB = 2 for 32 bits (n downto 2)
	-- C_ADDR_LSB = 3 for 64 bits (n downto 3)
	-- C_DREG_WIDTH = 2 when addressing 4 register
	-- DREG_MASK will in that case contain 2 bits
    constant C_DREG_WIDTH: integer := 3;        --  using addresses from 0x00 to 0x1F --> 3 bits
	constant C_ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant C_DREG_MASK : positive:= C_ADDR_LSB + C_DREG_WIDTH;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	signal slv_reg_rden	   : std_logic;
	signal slv_reg_wren	   : std_logic;
	signal reg_data_out	   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal reg_int_out	   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	   : integer;
	signal aw_en	       : std_logic;
	signal is_int_reg_selw : std_logic;
	signal is_int_reg_selr : std_logic;
	signal is_int_reg_w    : std_logic;
	signal is_int_reg_r    : std_logic;
	signal is_data_reg_w   : std_logic;
	signal is_data_reg_r   : std_logic;
	signal awaddr_masked   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto C_DREG_MASK);
	signal araddr_masked   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto C_DREG_MASK);
	signal addr_int        : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto C_DREG_MASK);

    -- debug attributes
--    attribute mark_debug : string;
--    attribute mark_debug of reg_data_out: signal is "true";
--    attribute mark_debug of axi_araddr: signal is "true";
--    attribute mark_debug of axi_rvalid: signal is "true";

begin
    -- create address enable signals for accessing data or interrupt registers
    addr_int        <= (others => '1');
    awaddr_masked   <= axi_awaddr(C_S_AXI_ADDR_WIDTH-1 downto C_DREG_MASK);
    araddr_masked   <= axi_araddr(C_S_AXI_ADDR_WIDTH-1 downto C_DREG_MASK);
    is_int_reg_selw <= '1' when (awaddr_masked = addr_int) else '0';
    is_int_reg_selr <= '1' when (araddr_masked = addr_int) else '0';
    is_int_reg_w    <= is_int_reg_selw and slv_reg_wren;
    is_int_reg_r    <= is_int_reg_selr and slv_reg_rden;
    is_data_reg_w   <= not is_int_reg_selw and slv_reg_wren;
    is_data_reg_r   <= not is_int_reg_selr and slv_reg_rden;
    
	-- output connections assignments
	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	    <= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	    <= axi_rdata;
	S_AXI_RRESP	    <= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	
DHT11_S00_AXI_DataRegs_inst: entity work.DHT11_S00_AXI_DataRegs
	generic map (
        C_U_STATUS_WIDTH    => C_U_STATUS_WIDTH,
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH,
		C_ADDR_LSB          => C_ADDR_LSB
	)
	port map (
	    U_CONTROL       => U_CONTROL,
	    U_STATUS        => U_STATUS,
	    U_VALUES        => U_VALUES,
	    U_WR_TICK       => U_WR_TICK,
	    U_RD_TICK       => U_RD_TICK,
	    ------------------------------- 
		S_AXI_ACLK	    => S_AXI_ACLK,
		S_AXI_ARESETN	=> S_AXI_ARESETN,
		S_AXI_WSTRB     => S_AXI_WSTRB,
		S_AXI_WDATA     => S_AXI_WDATA,
                       
        axi_awaddr      => axi_awaddr,
        axi_araddr      => axi_araddr,
        den_w           => is_data_reg_w,
        den_r           => is_data_reg_r,
        reg_data_out    => reg_data_out
    );
    	
DHT11_S00_AXI_IntRegs_inst: entity work.DHT11_S00_AXI_IntRegs
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH,
		C_NUM_OF_INTR	    => C_NUM_OF_INTR,
		C_INTR_SENSITIVITY	=> C_INTR_SENSITIVITY,
		C_INTR_ACTIVE_STATE	=> C_INTR_ACTIVE_STATE,
		C_IRQ_SENSITIVITY	=> C_IRQ_SENSITIVITY,
		C_IRQ_ACTIVE_STATE	=> C_IRQ_ACTIVE_STATE
	)
	port map (
        USER_INTR           => U_INTR,
		irq	                => irq,
                            
		S_AXI_ACLK	        => S_AXI_ACLK,
		S_AXI_ARESETN	    => S_AXI_ARESETN, 
		S_AXI_WDATA         => S_AXI_WDATA,
        axi_awaddr          => axi_awaddr,
        axi_araddr          => axi_araddr,
        den_w               => is_int_reg_w,
        den_r               => is_int_reg_r,
        reg_int_out         => reg_int_out
    );
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	           axi_awready <= '1';
	           aw_en <= '0';
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	           aw_en <= '1';
	           axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	-- Output register or memory read data
	process( S_AXI_ACLK ) is
	begin
	  if (rising_edge (S_AXI_ACLK)) then
	    if ( S_AXI_ARESETN = '0' ) then
	      axi_rdata  <= (others => '0');
	    else
	      if (is_data_reg_r = '1') then
	        -- When there is a valid read address (S_AXI_ARVALID) with 
	        -- acceptance of read address by the slave (axi_arready), 
	        -- output the read dada 
	        -- Read address mux
	          axi_rdata <= reg_data_out;     -- register read data
	      elsif (is_int_reg_r = '1') then
	          axi_rdata <= reg_int_out;
	      else
	          axi_rdata <= (others => '0');
	      end if;   
	    end if;
	  end if;
	end process;


end arch_imp;
