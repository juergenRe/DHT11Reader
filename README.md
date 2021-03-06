# DHT11 Reader
Component to read DHT11 humidity and temperature sensor via AXI-interface. 

Created for Vivado 2019.1

Address spaces:
  0x00 to 0x1F: reserved for data transfer.
  0x20 to 0x3F: reserved for interrupt registers

Data register description:
- Register 1 (00): (W0)   DTA Bits 31..24: Humidity integral; Bits 23..16: Humidity fractional; Bits 15..8:  Temperature integral; Bits  7..0:  Temperature fractional
- Register 2 (04): (RO)   STA Status Bit 7:4: actual error; bit 3: unused; bit 2: device ready; bit 1: data ready; bit 0: error
- Register 3 (08): (RO)   CTL Bit1: AutoTrigger enable; Bit0: Trigger; 
- Register 4 (0C): (R/W)  RES unused

Interrupt support:
- Register 1 (00): (R/W)  GIE Bit 0: Global interrupt enable
- Register 2 (04): (R/W)  IER Bit 1: Device ready; bit 0: Data available
- Register 3 (08): (RO):  IST Interrupt status
- Register 4 (0C): (WO):  IAC Interrupt acknowledge, will be read always as 0
- Register 5 (10): (RO):  IPE Interrupt pending

## Testing projects:
- DHT11DemoStandAlone: runs as non-BD project in PL to access directly the DHT11 component
- DHT11DemoWrapper: runs a non-BD project in PL using the wrapper designed to be integrated with AXI interface
Both projects aim to be able to debug the logic using ILA. 

### Preparation for test:
- uncomment mark debug nets
- set one of the test projects as Top
- enable constraints files
- Simulation set 3 is dedicated to test the AXI behavior. A structured testbench has been developped for this.

### Preparation for IP generation
- set DHT11Reader as TOP
- disable constraints files
- run synthesis as base check; especially check warnings!
- remove all ILA cores

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
- execution will create a new IP in its own folder within `CustomIP`
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
