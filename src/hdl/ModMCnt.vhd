----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:17:39 04/09/2012 
-- Design Name: 
-- Module Name:    ModMCnt - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity mod_m_counter is
    generic(
        N: integer := 4;     -- number of bits
        M: integer := 10     -- mod-M
    );
    port(
        clk, reset	    : in std_logic;
        clk_en		    : in std_logic;
        max_tick		: out std_logic;
        q				: out std_logic_vector(N-1 downto 0)
    );
end mod_m_counter;

architecture arch of mod_m_counter is
    signal r_reg	    : unsigned(N-1 downto 0);
    signal r_next       : unsigned(N-1 downto 0);
    signal r_inc        : unsigned(N-1 downto 0);
    type cnt_state is (stPwrOn, stRun);
    signal stCntReg     : cnt_state;
    signal stCntNxt     : cnt_state;
    
begin
    cnt_state_reg: process(clk, reset, clk_en)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                stCntReg <= stPwrOn;
                r_reg <= (others => '0');
            else
                stCntReg <= stCntNxt;
                r_reg <= r_next;
            end if;
        end if;
    end process cnt_state_reg;
    
    cnt_state_nxt: process(stCntReg, r_reg, clk_en)
    begin
        stCntNxt <= stCntReg;
        r_next <= r_reg;
        if stCntReg = stPwrOn then
            stCntNxt <= stRun;
            r_next <= (others => '0');
        end if;
        if stCntReg = stRun then
            if clk_en = '1' then
                r_next <= r_inc;
            end if;
        end if;
    end process cnt_state_nxt;
    
    -- next-state logic
    r_inc <= (others=>'0') when r_reg=(M-1) else r_reg + 1;

    -- output logic
    q <= std_logic_vector(r_reg);
    max_tick <= '1' when r_reg=(M-1) else '0';
end arch;

