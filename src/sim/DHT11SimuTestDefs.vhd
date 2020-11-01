----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/01/2020 04:55:42 PM
-- Design Name: 
-- Module Name: TestDef - Behavioral
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

package DHT11SimuTestDefs is

-----------------------------------
-- dht11 simulation signals
--
constant NDATABIT:      integer := 40;

-- timing constants: base timing, can be streteched by MULT
-- times are nominal times
constant MULT:          integer := 5;
constant TSTRTIN:       time := 10us;               -- min time to detect a trigger
constant TWAKE:         time := 30us;               -- wake up 20..40us
constant TSTRTL:        time := 80us;               -- duration of start bit low of DHT
constant TSTRTH:        time := 80us;               -- duration of start bit high
constant TBITL:         time := 50us;               -- duration of bit low time
constant TBITH0:        time := 27us;               -- duration of bit high when transmitting '0'
constant TBITH1:        time := 70us;               -- duration of bit high when transmitting '1'
constant TEXCESSTIME:   time := 17ms;               -- excessive hold of one state

constant TVAR_WAKE_MN:  time := 10us;               -- variation to get minimum time 
constant TVAR_WAKE_MX:  time := 10us;               -- variation to get maximum time 
constant TVAR_STRT_MN:  time := 20us;               -- variation to get minimum time 
constant TVAR_STRT_MX:  time := 20us;               -- variation to get maximum time 
constant TVAR_BITL_MN:  time := 10us;               -- variation to get minimum time 
constant TVAR_BITL_MX:  time := 10us;               -- variation to get maximum time 
constant TVAR_BITH0_MN: time := 13us;               -- variation to get minimum time 
constant TVAR_BITH0_MX: time := 13us;               -- variation to get maximum time 
constant TVAR_BITH1_MN: time := 10us;               -- variation to get minimum time 
constant TVAR_BITH1_MX: time := 10us;               -- variation to get maximum time 

constant TD_ERROR:      time :=  1us;               -- additaional time increment to get out of good window

constant ERR_OK:        integer := 0;
constant ERR_NoDevice:  integer := 1;
constant ERR_DHTStartBit: integer := 2;
constant ERR_SC:        integer := 3;
constant ERR_TxHigh:    integer := 4;
constant ERR_TxLow:     integer := 5;
constant ERR_TxTOH:     integer := 6;
constant ERR_TxTOL:     integer := 7;
constant ERR_ChkSum:    integer := 8;

signal txData:          std_logic_vector(NDATABIT-1 downto 0) := (others => '0');

signal t_trigin:        time;                   -- min external start bit
signal t_wakeup:        time;
signal t_startL:        time;
signal t_startH:        time;
signal t_bitL:          time;
signal t_bitH0:         time;
signal t_bitH1:         time;
signal b_chk:           std_logic;


-- Test Data definiton
constant NB_TIMES:      natural := 7;
type t_timing_ary is array (natural range <>) of time;
type t_testdata is record
      timings   : t_timing_ary(0 to NB_TIMES-1);	-- timing array
      b_chk     : std_logic;                        -- provoke checksum error
	  data	    : std_logic_vector(31 downto 0); 	-- data to transmit
	  expectRes	: integer;						    -- expected result
	  desc      : string(1 to 40);                  -- description string
end record;
type t_trgdata is record
    d_trg1      : std_logic_vector(1 downto 0);     -- setting to trigger the first conversion 
    d_trg       : std_logic_vector(1 downto 0);     -- setting to trigger a conversion after 1st pass
    d_smpl      : std_logic_vector(1 downto 0);     -- setting after conversion has started
    d_tend      : std_logic_vector(1 downto 0);     -- setting to be applied a the end of a single pass
    d_off       : std_logic_vector(1 downto 0);     -- setting to stop everything after n passes
    desc        : string(1 to 40);
end record;
type t_test_ary is array (natural range <>) of t_testdata;
type t_trg_ary is array (natural range <>) of t_trgdata;

constant trg_data: t_trg_ary := (
    0       => ( -- standard one shot with reset by driver
      d_trg1    => "01",
      d_trg     => "01",
      d_smpl    => "00",
      d_tend    => "00",
      d_off     => "00",
      desc      => "One shot [drv]                          "),
      --           "0123456789012345678901234567890123456789"
    1       => ( -- standard one shot with reset at end of conversion
      d_trg1    => "01",
      d_trg     => "01",
      d_smpl    => "01",
      d_tend    => "00",
      d_off     => "00",
      desc      => "One shot [comp]                         "),
      --           "0123456789012345678901234567890123456789"
    2       => ( -- standard auto sample with reset at end of pass
      d_trg1    => "11",
      d_trg     => "10",
      d_smpl    => "10",
      d_tend    => "10",
      d_off     => "00",
      desc      => "Auto [once]                             "),
      --           "0123456789012345678901234567890123456789"
    3       => ( -- standard auto sample with reset at end of all passes
      d_trg1    => "11",
      d_trg     => "11",
      d_smpl    => "11",
      d_tend    => "11",
      d_off     => "00",
      desc      => "Auto [cont]                             "),
      --           "0123456789012345678901234567890123456789"
    4       => ( -- standard auto sample with reset of AUTO only at end of all passes
      d_trg1    => "11",
      d_trg     => "11",
      d_smpl    => "11",
      d_tend    => "11",
      d_off     => "01",
      desc      => "Auto [cont] + OS at end                 ")
      --           "0123456789012345678901234567890123456789"
);

constant test_data : t_test_ary := (
    0       => (            -- good timing
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_OK,
      desc      => "<0> Good timings A                      "),
    1       => (            -- good timing
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"00000000",
      expectRes => ERR_OK,
      desc      => "<1> Good timings B                      "),
    2       => (            -- good timing
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"FFFFFFFF",
      expectRes => ERR_OK,
      desc      => "<2> Good timings C                      "),
    3       => (            -- wake up too long
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE + TVAR_WAKE_MX + TD_ERROR,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_NoDevice,
      desc      => "<3> Wake up too long                    "),
    4       => (            -- Start bit "0" DHT too short
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL - TVAR_STRT_MN - TD_ERROR,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_DHTStartBit,
      desc      => "<4> Start bit DHT too short             "),
    5       => (            -- Start bit "0" DHT too long
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL + TVAR_STRT_MX + TD_ERROR,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_DHTStartBit,
      desc      => "<5> Start bit DHT too long              "),
    6       => (            -- Start bit "1" DHT too short
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH - TVAR_STRT_MN - TD_ERROR,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_DHTStartBit,
      desc      => "<6> Start bit DHT High too short        "),
    7       => (            -- Start bit "1" DHT too long
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH + TVAR_STRT_MX + TD_ERROR,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_DHTStartBit,
      desc      => "<7> Start bit DHT High too long         "),
    8       => (            -- TXLow phase too short
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,
                     4 => TBITL - TVAR_BITL_MN - TD_ERROR,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_TxLow,
      desc      => "<8> TX Bit low too short                "),
    9       => (            -- TXLow phase too long
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL + TVAR_BITL_MX + TD_ERROR,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_TxLow,
      desc      => "<9> TX Bit low too long                 "),
    10      => (            -- TXHigh phase too short (less than '0' bit length)
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,
                     4 => TBITL,  
                     5 => TBITH0 - TVAR_BITH0_MN - TD_ERROR,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_TxHigh,
      desc      => "<10> TX Bit High too short for '0'      "),
      --           "0123456789012345678901234567890123456789"
    11      => (            -- TXHigh phase too long for '0'
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0 + TVAR_BITH0_MX + TD_ERROR,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_TxHigh,
      desc      => "<11> TX Bit High too long for '0'       "),
      --           "0123456789012345678901234567890123456789"
    12      => (            -- TXHigh phase too short for '1'
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1 - TVAR_BITH1_MN - TD_ERROR),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_TxHigh,
      desc      => "<12> TX Bit High too short for '1'      "),
      --           "0123456789012345678901234567890123456789"
    13      => (            -- TXHigh phase too long for '1'
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1 + TVAR_BITH1_MX + TD_ERROR),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_TxHigh,
      desc      => "<13> TX Bit High too long for '1'       "),
    14      => (            -- repeat good timing to check if status is reset correctly
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_OK,
      desc      => "<14> Good timings A (repeat)            "),
    15      => (            -- excessive start bit low --> counter overflow
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TEXCESSTIME,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_SC,
      desc      => "<15> Excess start bit L                 "),
    16      => (            -- excessive start bit high --> counter overflow
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TEXCESSTIME,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_DHTStartBit,
      desc      => "<16> Excess start bit H                 "),
    17      => (            -- excessive Tx bit high --> counter overflow
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TEXCESSTIME,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_TxTOL,
      desc      => "<17> Excess Tx bit L                    "),
    18      => (            -- excessive Tx bit low --> counter overflow
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TEXCESSTIME,  
                     6 => TBITH1),
      b_chk     => '0',
      data      => x"5577AA33",
      expectRes => ERR_TxTOH,
      desc      => "<18> Excess Tx bit H                    "),
    19      => (            -- simulate checksumm error
      timings   => ( 0 => TSTRTIN,
                     1 => TWAKE,
                     2 => TSTRTL,  
                     3 => TSTRTH,  
                     4 => TBITL,  
                     5 => TBITH0,  
                     6 => TBITH1),
      b_chk     => '1',
      data      => x"5577AA33",
      expectRes => ERR_ChkSum,
      desc      => "<19> Checksum error                     ")
      --           "0123456789012345678901234567890123456789"
      ); 
  
    -- function prototypes
        function calc_crc ( data : in std_logic_vector) return std_logic_vector;
		function test_data_length return natural;
		function trg_data_length return natural;
        procedure getActData(idx: in natural; 
                         dx: out std_logic_vector;
                         t_trigin: out time; 
                         t_wakeup: out time; 
                         t_startL: out time; 
                         t_startH: out time; 
                         t_bitL: out time; 
                         t_bitH0: out time; 
                         t_bitH1: out time; 
                         bchk: out std_logic;
                         expectResult: out integer; 
                         desc: out string);
        procedure getActTrigger(idx: in natural;
                                trgStart1: out std_logic_vector; 
                                trgStart: out std_logic_vector; 
                                trgSmpl: out std_logic_vector; 
                                trgPassEnd: out std_logic_vector;
                                trgEnd: out std_logic_vector; 
                                desc: out string);

end DHT11SimuTestDefs;

package body DHT11SimuTestDefs is
        
        function calc_crc ( data : in std_logic_vector) return std_logic_vector is
            variable crc: std_logic_vector(7 downto 0);
		begin
		    crc := data(31 downto 24) + data(23 downto 16) + data(15 downto 8) + data(7 downto 0);
		    return crc;
		end calc_crc;
		
		function test_data_length return natural is
		begin
		    return test_data'length;
		end test_data_length;
		
		function trg_data_length return natural is
		begin
		    return trg_data'length;
		end trg_data_length;

        procedure getActData(idx: in natural; 
                             dx: out std_logic_vector;
                             t_trigin: out time; 
                             t_wakeup: out time; 
                             t_startL: out time; 
                             t_startH: out time; 
                             t_bitL: out time; 
                             t_bitH0: out time; 
                             t_bitH1: out time; 
                             bchk: out std_logic;
                             expectResult: out integer; 
                             desc: out string) is
        begin
            dx := test_data(idx).data;
            t_trigin := test_data(idx).timings(0);
            t_wakeup := test_data(idx).timings(1);
            t_startL := test_data(idx).timings(2);
            t_startH := test_data(idx).timings(3);
            t_bitL   := test_data(idx).timings(4);
            t_bitH0  := test_data(idx).timings(5);
            t_bitH1  := test_data(idx).timings(6);
            bchk     := test_data(idx).b_chk;
            expectResult := test_data(idx).expectRes;
            desc := test_data(idx).desc;
        end getActData;

        procedure getActTrigger(idx: in natural;
                                trgStart1: out std_logic_vector; 
                                trgStart: out std_logic_vector; 
                                trgSmpl: out std_logic_vector; 
                                trgPassEnd: out std_logic_vector;
                                trgEnd: out std_logic_vector; 
                                desc: out string) is
        begin
            trgStart1 := trg_data(idx).d_trg1;
            trgStart := trg_data(idx).d_trg;
            trgSmpl := trg_data(idx).d_smpl;
            trgPassEnd := trg_data(idx).d_tend;
            trgEnd := trg_data(idx).d_off;
            desc := trg_data(idx).desc;
        end getActTrigger;

end DHT11SimuTestDefs;
