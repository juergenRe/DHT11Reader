# DHT11 Reader
Component to read DHT11 humidity and temperature sensor via AXI-interface. 

Created for Vivado 2019.1

Register description:
- Register 1: (write-only) Bit31: Enable; Bit30: AutoTrigger; Bit 7..0: delay in s. 0: disable autotrigger
- Register 2: (read-only) Stauts Bit 31: new sample; bit 30: error during transmission, sample incorrect. Bits will be reset after reading register 3.
- Register 3: (read-only) Bits 31..24: Humidity integral; Bits 23..16: Humidity fractional; Bits 15..8:  Temperature integral; Bits  7..0:  Temperature fractional
- Register 4: unused

## Recreating the project
This should be done using the scripts in /proj subfolder:
- cd into <project folder>/proj
- `source ./create_project.tcl`

## Create recreation script
- cd into <project folder>/proj
- execute: `write_project_tcl -paths_relative_to . -origin_dir_override . -force create_project.tcl`

## create IP from it:
- cd into <project folder>/proj
- rename IP is necessary, also check top module and compile order at the end of the script
- execute: `source ./mkIP.tcl`
- commit changes in folders src, xgui and component.xml. Subfolder "project" might be deleted.
- recreate depending projects
- ipx::* is poorly documented; best choice is to use `help ipx::*` to get a list of commands and then call help for each command.

## Debugging with ILA at startup:
Ref: see UG908, Chapter 11, "Trigger at startup"

1. implement design and set triggers in ILA dashboard
2. cd to /proj folder
3. `run_hw_ila -file ila_trig.tas [get_hw_ilas hw_ila_1]`
4. open implemented design
5. `apply_hw_ila_trigger ila_trig.tas`
6. `write_bitstream -force trig_at_startup.bit`
7. reopen Hardware manager and select device (xc7c020)
8. select newly written bit file in properties window
i) reprogram device which should then trace immediately
