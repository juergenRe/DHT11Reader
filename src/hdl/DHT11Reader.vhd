library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DHT11Reader is
	generic (
		-- Users to add parameters here
		NDIV                    : integer := 99;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
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
		s00_axi_rready	: in std_logic
	);
end DHT11Reader;

architecture arch_imp of DHT11Reader is
    constant PWRONDLY:      integer := 21;
    
    signal wr_tick:         std_logic;
    signal reset:           std_logic;
    signal rd_tick:         std_logic;
    signal act_control:     std_logic_vector(1 downto 0);
    signal act_status:      std_logic_vector(3 downto 0);
    signal act_values:      std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    
    signal dhtInSig:        std_logic;
    signal dhtOutSig:       std_logic;

	-- component declaration
	component DHT11_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer := 32;
		C_S_AXI_ADDR_WIDTH	: integer := 4
		);
		port (
		-- register assignment: 
		-- 0: U_VALUES; (read-only)
		-- 4: U_STATUS; (read-only)
		-- 8: U_CONTROL; (write-only)
		-- C: unused;
		-- 
		-- Control port: AUTO, TRG
        U_CONTROL       : out std_logic_vector(1 downto 0);
        --  Status bits: Ready, Error, DataValid
        U_STATUS        : in std_logic_vector(3 downto 0);
        -- measured values:
        -- U_VALUES(31 downto 16): 16 bits for humidity
        -- U_VALUES(15 downto 0):  16 bits for temperature
        U_VALUES        : in std_logic_vector(C_S_AXI_DATA_WIDTH -1 downto 0);
        U_WR_TICK       : out std_logic;
		U_RD_TICK       : in std_logic;

		S_AXI_ACLK	    : in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component DHT11_S00_AXI;

component DHT11Wrapper is
	generic (
		-- Users to add parameters here
		C_S_AXI_DATA_WIDTH	    : integer := 32;
		NDIV                    : integer := 99;
        PWRONDLY                : integer := 21
	);
	port (
	    clk         : in std_logic;
	    reset       : in std_logic;
		-- control bits to start conversion and have automatic conversion every second
        U_CONTROL   : in std_logic_vector(1 downto 0);
        --  Status bits: Ready, Error
        U_STATUS    : out std_logic_vector(3 downto 0);
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
end component DHT11Wrapper;
    
begin

-- Instantiation of Axi Bus Interface S00_AXI
DHT11_S00_AXI_inst: DHT11_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    U_CONTROL       => act_control,
	    U_STATUS        => act_status,
	    U_VALUES        => act_values,
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
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here
dht11wrapper_inst: DHT11Wrapper
    generic map (
        C_S_AXI_DATA_WIDTH      => C_S00_AXI_DATA_WIDTH,
        NDIV                    => NDIV,
        PWRONDLY                => PWRONDLY
    )
    port map (
        clk         => s00_axi_aclk,
        reset       => reset,
        U_CONTROL   => act_control,
        U_STATUS    => act_status,
        U_VALUES    => act_values,
        U_WR_TICK   => wr_tick,
        U_RD_TICK   => rd_tick,
        dhtInSig    => dhtInSig,
        dhtOutSig   => dhtOutSig
    );
	
    reset <= not s00_axi_aresetn;
    
    -- DHT11 bus signals
    dhtInSig <= DataLine;
    DataLine <= '0' when dhtOutSig = '0' else 'Z';

	-- User logic ends

end arch_imp;
