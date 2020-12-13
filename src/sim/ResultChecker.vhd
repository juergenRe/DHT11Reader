----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/13/2020 11:12:56 AM
-- Design Name: 
-- Module Name: ResultChecker - Behavioral
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
use work.GenFuncLib.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ResultChecker is
    generic (
        filename:       string := "result.txt"
    );
    port (
        StopClock:      in boolean;
        expectedData:   in t_testData;
        actualData:     in t_testData
    );
end ResultChecker;

architecture Behavioral of ResultChecker is
    signal actDataTransaction:  bit;
    signal expDataTransaction:  bit;
    signal Dummy:               boolean;
begin
    actDataTransaction <= actualData'Transaction;
    expDataTransaction <= expectedData'Transaction;

    checkRes_proc: process
        variable actTrans:  t_testData;
        variable expTrans:  t_testData;
        variable actResAry: t_results; 
        variable expResAry: t_results; 
        variable actRes:    std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
        variable expRes:    std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);
        variable result:    boolean;
        variable sh:        string(1 to 15);
        
        procedure writeResult(constant fn: in string; constant s: in string) is
            file f:         text;
            variable row:   line;
        begin
            file_open(f, fn, append_mode);
            write(row, s);
            writeline(f, row);
            wrOut(s);
            file_close(f);
        end;
        
    begin
        while Stopclock = false loop
            get(expTrans, expectedData, Dummy, expDataTransaction);
            get(actTrans, actualData, Dummy, actDataTransaction);
            actResAry := actTrans.expResult;
            expResAry := expTrans.expResult;
            result := true;
            --wrOut("CHK: -----------------------------------------------");
            writeResult(filename, "CHK: ---> " & expTrans.desc);
            for i in actResAry'range loop
                if expResAry(i).f = true then   -- do we have to check?
                    actRes := actResAry(i).res; 
                    expRes := expResAry(i).res;
                    if actRes /= expRes then
                        result := false;
                        sh := "CHK:   !!! Err ";
                    else
                        sh := "CHK:       OK  "; 
                    end if; 
                    writeResult(filename, sh & "res(" & integer'image(i) & "): exp: 0x" & to_hex_string(expRes) & " act: 0x" & to_hex_string(actRes));
                end if;
            end loop;
        end loop;
        wait;
    end process checkRes_proc;


end Behavioral;
