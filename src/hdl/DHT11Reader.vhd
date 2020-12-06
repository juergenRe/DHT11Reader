library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Sensor reader with interrupt capability
--
-- Addressing scheme:
-- 00   RO  data values
-- 04   RO  status values + error codes
-- 08   WO  control register
-- 0C - 2F  reserved
-- 20   R/W Global interrupt enable/disable (Bit 0)
-- 24   R/W specific interrupt enable/disable according # of interrupts set
-- 28   RO  activation status of specific interrupts 
-- 2C   R/W specific interrupt acknowledge by writing '1'
-- 30   RO  pending status of specific interrupts
-- 34 .. 3F reserved
--
-- all registers are 32bit wide; address range 6bit (00..3F)
--
entity DHT11Reader is
	generic (
		-- Users to add parameters here
		NDIV                    : integer := 99;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 6;  -- address space used
		C_NUM_OF_INTR	        : integer	:= 2;
		C_INTR_SENSITIVITY	    : std_logic_vector	:= x"FFFFFFFF";
		C_INTR_ACTIVE_STATE	    : std_logic_vector	:= x"FFFFFFFF";
		C_IRQ_SENSITIVITY	    : integer	:= 1;
		C_IRQ_ACTIVE_STATE	    : integer	:= 1
	);
	port (
		-- Users to add ports here
        DataLine    : inout std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;
		irq	            : out std_logic
	);
end DHT11Reader;

architecture arch_imp of DHT11Reader is
    constant C_U_STATUS_WIDTH: integer := 8;
    constant PWRONDLY       : integer := 21;
    constant C_DREG_WIDTH   : integer := 2;     -- addresses 00..1F are reserved for data registers
    constant C_IREG_WIDTH   : integer := 3;     -- addresses 20..3F are reserved for interrupt registers
    constant C_UP_INT_BIT   : integer := 2;
    
    signal wr_tick          : std_logic;
    signal reset            : std_logic;
    signal rd_tick          : std_logic;
    signal act_control      : std_logic_vector(1 downto 0);
    signal act_status       : std_logic_vector(7 downto 0);
    signal act_values       : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal intr             : std_logic_vector(C_NUM_OF_INTR-1 downto 0);
    signal dhtInSig         : std_logic;
    signal dhtOutSig        : std_logic;

begin

-- Instantiation of Axi Bus Interface S00_AXI
DHT11_S00_AXI_inst: entity work.DHT11_S00_AXI
	generic map (
	    C_U_STATUS_WIDTH    => C_U_STATUS_WIDTH,
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH,
		C_NUM_OF_INTR	    => C_NUM_OF_INTR,
		C_INTR_SENSITIVITY	=> C_INTR_SENSITIVITY,
		C_INTR_ACTIVE_STATE	=> C_INTR_ACTIVE_STATE,
		C_IRQ_SENSITIVITY	=> C_IRQ_SENSITIVITY,
		C_IRQ_ACTIVE_STATE	=> C_IRQ_ACTIVE_STATE
	)
	port map (
	    U_CONTROL       => act_control,
	    U_STATUS        => act_status,
	    U_VALUES        => act_values,
	    U_INTR          => act_status(C_UP_INT_BIT downto C_UP_INT_BIT - (C_NUM_OF_INTR -1)),
	    U_WR_TICK       => wr_tick,
	    U_RD_TICK       => rd_tick,
	    ------------------------------- 
		S_AXI_ACLK	    => s00_axi_aclk,
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
		S_AXI_RREADY	=> s00_axi_rready,
		irq             => irq
	);

	
	-- Add user logic here
dht11wrapper_inst: entity work.DHT11Wrapper
    generic map (
	    C_U_STATUS_WIDTH        => C_U_STATUS_WIDTH,
        C_S_AXI_DATA_WIDTH      => C_S00_AXI_DATA_WIDTH,
        NDIV                    => NDIV,
        SIMU_FLG                => false
    )
    port map (
        clk         => s00_axi_aclk,
        reset       => reset,
        U_CONTROL   => act_control,
        U_STATUS    => act_status,
        U_VALUES    => act_values,
        U_WR_TICK   => wr_tick,
        U_RD_TICK   => rd_tick,
        U_INTR      => intr,
        dhtInSig    => dhtInSig,
        dhtOutSig   => dhtOutSig
    );
	
    reset <= not s00_axi_aresetn;
    
    -- DHT11 bus signals
    dhtInSig <= DataLine;
    DataLine <= '0' when dhtOutSig = '0' else 'Z';

	-- User logic ends

end arch_imp;