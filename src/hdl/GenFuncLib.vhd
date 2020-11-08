----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/08/2020 12:34:09 PM
-- Design Name: 
-- Module Name: GenFuncLib - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--      Package of generic functions to be used several times
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package GenFuncLib is

    function tif(cond : boolean; res_true, res_false : integer) return integer;
    procedure wrOut (arg : in string := "");
end GenFuncLib;

package body GenFuncLib is
    -- ternary if function for integer return valus
    function tif(cond : boolean; res_true, res_false : integer) return integer is
    begin
      if cond then
        return res_true;
      else
        return res_false;
      end if;
    end function;
    
    procedure wrOut (arg : in string := "") is
    begin
      std.textio.write(std.textio.output, arg & LF);
    end procedure wrOut;

end GenFuncLib;
