----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/06/2020 05:43:56 PM
-- Design Name: 
-- Module Name: ShiftRight - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ShiftLeft is
generic (
    NBITS            : positive := 15
);
port (
    clk              : in std_logic;
    reset            : in std_logic;
    -- Input
    setEnable        : in std_logic;
    dataIn           : in std_logic_vector(NBITS-1 downto 0);
    dataBit          : in std_logic;
    -- Control
    shiftEnable      : in std_logic;
    -- Output
    dataOut          : out std_logic_vector(NBITS-1 downto 0)
);
end ShiftLeft;

architecture rtl of ShiftLeft is

    signal data      : unsigned(NBITS-1 downto 0);

begin

    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset
            data <= (others => '0');
        elsif rising_edge(clk) then
            if setEnable = '1' then
                -- Load new input
                data <= unsigned(dataIn);
            elsif shiftEnable = '1' then
                -- Shift right
                data <= data(NBITS-2 downto 0) & dataBit;
            end if;
        end if;
    end process;
    dataOut <= std_logic_vector(data);

end rtl;
