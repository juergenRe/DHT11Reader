

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 2 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 2 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {dht11/dataStatusReg[0]} {dht11/dataStatusReg[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 6 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {dht11/bitCntReg[0]} {dht11/bitCntReg[1]} {dht11/bitCntReg[2]} {dht11/bitCntReg[3]} {dht11/bitCntReg[4]} {dht11/bitCntReg[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 21 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {dht11/smplCntReg[0]} {dht11/smplCntReg[1]} {dht11/smplCntReg[2]} {dht11/smplCntReg[3]} {dht11/smplCntReg[4]} {dht11/smplCntReg[5]} {dht11/smplCntReg[6]} {dht11/smplCntReg[7]} {dht11/smplCntReg[8]} {dht11/smplCntReg[9]} {dht11/smplCntReg[10]} {dht11/smplCntReg[11]} {dht11/smplCntReg[12]} {dht11/smplCntReg[13]} {dht11/smplCntReg[14]} {dht11/smplCntReg[15]} {dht11/smplCntReg[16]} {dht11/smplCntReg[17]} {dht11/smplCntReg[18]} {dht11/smplCntReg[19]} {dht11/smplCntReg[20]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 40 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {dht11/dataSampleReg[0]} {dht11/dataSampleReg[1]} {dht11/dataSampleReg[2]} {dht11/dataSampleReg[3]} {dht11/dataSampleReg[4]} {dht11/dataSampleReg[5]} {dht11/dataSampleReg[6]} {dht11/dataSampleReg[7]} {dht11/dataSampleReg[8]} {dht11/dataSampleReg[9]} {dht11/dataSampleReg[10]} {dht11/dataSampleReg[11]} {dht11/dataSampleReg[12]} {dht11/dataSampleReg[13]} {dht11/dataSampleReg[14]} {dht11/dataSampleReg[15]} {dht11/dataSampleReg[16]} {dht11/dataSampleReg[17]} {dht11/dataSampleReg[18]} {dht11/dataSampleReg[19]} {dht11/dataSampleReg[20]} {dht11/dataSampleReg[21]} {dht11/dataSampleReg[22]} {dht11/dataSampleReg[23]} {dht11/dataSampleReg[24]} {dht11/dataSampleReg[25]} {dht11/dataSampleReg[26]} {dht11/dataSampleReg[27]} {dht11/dataSampleReg[28]} {dht11/dataSampleReg[29]} {dht11/dataSampleReg[30]} {dht11/dataSampleReg[31]} {dht11/dataSampleReg[32]} {dht11/dataSampleReg[33]} {dht11/dataSampleReg[34]} {dht11/dataSampleReg[35]} {dht11/dataSampleReg[36]} {dht11/dataSampleReg[37]} {dht11/dataSampleReg[38]} {dht11/dataSampleReg[39]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 5 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {dht11/stSmplReg[0]} {dht11/stSmplReg[1]} {dht11/stSmplReg[2]} {dht11/stSmplReg[3]} {dht11/stSmplReg[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 40 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {dht11/actData[0]} {dht11/actData[1]} {dht11/actData[2]} {dht11/actData[3]} {dht11/actData[4]} {dht11/actData[5]} {dht11/actData[6]} {dht11/actData[7]} {dht11/actData[8]} {dht11/actData[9]} {dht11/actData[10]} {dht11/actData[11]} {dht11/actData[12]} {dht11/actData[13]} {dht11/actData[14]} {dht11/actData[15]} {dht11/actData[16]} {dht11/actData[17]} {dht11/actData[18]} {dht11/actData[19]} {dht11/actData[20]} {dht11/actData[21]} {dht11/actData[22]} {dht11/actData[23]} {dht11/actData[24]} {dht11/actData[25]} {dht11/actData[26]} {dht11/actData[27]} {dht11/actData[28]} {dht11/actData[29]} {dht11/actData[30]} {dht11/actData[31]} {dht11/actData[32]} {dht11/actData[33]} {dht11/actData[34]} {dht11/actData[35]} {dht11/actData[36]} {dht11/actData[37]} {dht11/actData[38]} {dht11/actData[39]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 1 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list dht11/actBit]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list DataLine_IBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list DataLine_OBUF]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list dht11/shiftEnable]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list dht11/sr_reset]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
set_property port_width 1 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list dht11/stDataSmplReg]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 1 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list dht11/tickPreCnt]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_IBUF_BUFG]
