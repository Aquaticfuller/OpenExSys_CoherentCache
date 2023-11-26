# Git Hash: pygmy-es1x.git a65baabfdd0ce805b1d5f05e3ce85e620cef102f
# Git Hash: pygmy-es1x.git cf7bdf6ab822b021c88ca928f504a91770786c84
#**************************************************************
# Create Clock
#**************************************************************
set clk_period 0.6667
# set clk_period 0.66
set clk_uncertainty [expr $clk_period * 0.1]
set latency_input_transition [expr $clk_period * 0.04]
set latency_input_transition_clocks [expr $clk_period * 0.003]

#MARGIN 0.9/0.65/1.0
set MARGIN 0.9 
set period_1500m [expr $MARGIN      *  0.6667];

#**************************************************************
# List clk ports
#**************************************************************
set CLK_PORT_LIST_IN "clk"
set RST_PORT_LIST_IN "rst"

set main_clk [get_ports clk]
#**************************************************************
# Create Clock
#**************************************************************
#create_clock -period 0.500 -waveform {0.0 0.25} -name clk [get_ports clk]
set period_main_clock $period_1500m

#create_clock -name CLK -period $clk_period [get_ports clk]
create_clock -name main_clk -period $period_main_clock -waveform [list 0 [expr $period_main_clock *0.5]] $main_clk -add
create_clock -name vir_main_clk -period $period_main_clock

#**************************************************************
# Create Generated Clock
#**************************************************************
#derive_pll_clocks

#**************************************************************
# ScanEnable to be 0
#**************************************************************
# Please include vcore_fp_top.disable_scan_constraints.v

set DRC_data_max_transition 0.25
set DRC_clock_max_transition 0.15
#**************************************************************
# Power Pin
#**************************************************************
#set ours(iport,cfg_pwr) [get_ports {*/cfg_is_clk_gated */cfg_thread_cnt*} -filter "direction==in"]




#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************
#derive_clock_uncertainty
#set_clock_uncertainty 0.125 [all_clocks]
set_clock_uncertainty $clk_uncertainty [all_clocks]

#**************************************************************
# Set I/O Delay
#**************************************************************
set_input_delay   [expr 0.5 * $clk_period] -max -clock vir_main_clk [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay   [expr 0.0 * $clk_period] -min -clock vir_main_clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay  [expr 0.5 * $clk_period] -max -clock vir_main_clk [all_outputs]
set_output_delay  [expr 0.0 * $clk_period] -max -clock vir_main_clk [all_outputs]

#**************************************************************
# Set ideal_network
#**************************************************************
if {[sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~CKLNQD*"]]} {
	set_ideal_network [get_pins -filter "pin_direction == out" -of_object [get_cells -hierarchical -filter "ref_name =~ *CKLNQD*"]]
}
if {[sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~CKLHQD*"]]} {
	set_ideal_network [get_pins -filter "pin_direction == out" -of_object [get_cells -hierarchical -filter "ref_name =~ *CKKHQD*"]]
}

set_ideal_network   [get_ports -quiet  "$CLK_PORT_LIST_IN "]
set_ideal_network   [get_ports -quiet  "$RST_PORT_LIST_IN "]

set_ideal_network [get_attribute [get_clocks -filter "full_name !~ vir*"] source]
set_dont_touch_network [get_clocks -filter "full_name !~ vir*"]

#**************************************************************
# Set False Path
#**************************************************************
# false path to power switch control ack (use pre-placed and pre-routing in ICC2)
#set_false_path -from [get_ports */cfg_is_clk_gated] -to [get_ports */cfg_is_clk_gated]
#set_false_path -from [get_ports */cfg_thread_cnt* ] -to [get_ports */cfg_thread_cnt*]

# false path from SLP to Q in SRAM (SLP not valid in VCORE yet, only on top level)
#set ours(pin,sram_slp) [get_pins -of [get_cells * -hier -filter "ref_name=~TS*N28HPCP*"] -filter "full_name=~*/SLP"]
#set ours(pin,sram_q) [get_pins -of [get_cells * -hier -filter "ref_name=~TS*N28HPCP*"] -filter "full_name=~*/Q*"]
#set_false_path -th $ours(pin,sram_slp) -th $ours(pin,sram_q)

#**************************************************************
# Begin
#**************************************************************
set global_setup_uncertainty 0.09
set global_hold_uncertainty  0.08
set ENV_data_input_max_transition 0.25
set ENV_input_min_transition 0.010
set DRC_max_fanout_inner     40
set DRC_max_fanout_input     1

set_max_transition $DRC_data_max_transition 			 [current_design]
set_max_transition $DRC_data_max_transition	 -data_path  [all_clocks]
set_max_transition $DRC_clock_max_transition -clock_path [all_clocks]

set_max_fanout     $DRC_max_fanout_inner [current_design];#40
set_max_fanout     $DRC_max_fanout_input [all_inputs];#1

set inputs    [remove_from_collection [all_inputs] $CLK_PORT_LIST_IN]
set_input_transition -max $ENV_data_input_max_transition  $inputs
set_input_transition -min $ENV_input_min_transition       $inputs

set_load -max 0.050 [all_outputs]
set_load -max 0.004 [all_outputs]


if {[info exists dft_clks]} {
	set func_clocks [remove_from_collection [all_clocks] $dft_clks]
} else {
	set func_clocks [all_clocks]
}

set_clock_uncertainty -setup $global_setup_uncertainty $func_clocks
set_clock_uncertainty -hold  $global_hold_uncertainty [all_clocks]

#**************************************************************
# Set Multicycle Path
#**************************************************************

# set_multicycle_path 18 -setup -end \
# 		       -through [get_pins div_u/ff_div_a_u/q[*]] \
# 		       -through [get_pins div_u/ff_div_output_data_u/d[*]]
# set_multicycle_path 17 -hold -end \
# 		       -through [get_pins div_u/ff_div_a_u/q[*]] \
# 		       -through [get_pins div_u/ff_div_output_data_u/d[*]]
# set_multicycle_path 18 -setup -end \
# 		       -through [get_pins div_u/ff_div_b_u/q[*]] \
# 		       -through [get_pins div_u/ff_div_output_data_u/d[*]]
# set_multicycle_path 17 -hold -end \
# 		       -through [get_pins div_u/ff_div_b_u/q[*]] \
# 		       -through [get_pins div_u/ff_div_output_data_u/d[*]]

# set_multicycle_path -setup 2 -through [get_cells {btb_u/BTB_SET_*__btb_tag/*}] -to [get_cells { \
# npc_gen_u/* \
# icache_u/req_valid_s1_reg \
# instr_buffer/wr_ptr_reg* \
# kill_f1_reg \
# btq_u/target_ram_reg* \
# }]

# set_multicycle_path -setup 2 -through [get_pins  {btb_u/BTB_SET_*__btb_tag/*}]

# set_multicycle_path -setup 8 -through [get_pins {EX/DIV/*}] -to [get_pins { \
# EX/DIV/DW_DIV_SEQ/* \
# EX/DIV/* \
# }]
# set_multicycle_path -setup 8 -through [get_pins  {EX/DIV/*}]
# set_multicycle_path -hold 7  -through [get_pins  {EX/DIV/*}]
# set_multicycle_path -setup 8 -through [get_pins  {EX/DIV/*/*}]
# set_multicycle_path -hold 7  -through [get_pins  {EX/DIV/*/*}]
# set_multicycle_path -setup 5 -through [get_pins  {EX/MUL/*}]
# set_multicycle_path -hold 4  -through [get_pins  {EX/MUL/*}]
# set_multicycle_path -hold 7  -through [get_cells {EX/DIV/*}] -to [get_cells { \
# EX/DIV/* \
# EX/DIV/DW_DIV_SEQ_part_rem_reg_reg_*_ \
# EX/DIV/DW_DIV_SEQ_shf_reg_reg_*__*_ \
# EX/DIV/DW_DIV_SEQ*reg* \
# EX/ex2ma_ff_reg** \
# ID/id2div_ff_reg* \
# ID/id2ex_ff_reg* \
# ID/id2ex_ff_reg* \
# ID/id2ex_fp_rs1* \
# ID/id2fp_add_d_ff_reg* \
# ID/id2fp_add_s_ff_reg* \
# ID/id2fp_div_d_ff_reg* \
# ID/id2fp_div_s_ff_reg* \
# ID/id2fp_mac_d_ff_reg* \
# ID/id2fp_mac_s_ff_reg* \
# ID/id2fp_misc_ff_reg* \
# ID/id2fp_sqrt_d_ff_reg* \
# ID/id2fp_sqrt_s_ff_reg* \
# ID/id2mul_ff_reg* \
# itlb_u/dff_sfence_req_reg* \
# }]

# set_multicycle_path -hold 7 -through [get_pins {EX/DIV/*}] -to [get_pins { \
# EX/DIV/DW_DIV_SEQ/* \
# EX/DIV/* \
# }]
                                   
# set_multicycle_path -setup 5 -through [get_cells {EX/MUL/*}] -to [get_cells { \
# EX/ex2ma_ff_reg* \
# EX/MUL/DW_MULT_SEQ*reg* \
# EX/MUL/* \
# ID/id2div_ff_reg* \
# ID/id2ex_ff_reg* \
# ID/id2ex_ff_reg* \
# ID/id2ex_fp_rs1_ff_reg* \
# ID/id2fp_add_d_ff_reg* \
# ID/id2fp_add_s_ff_reg* \
# ID/id2fp_div_d_ff_reg* \
# ID/id2fp_div_s_ff_reg* \
# ID/id2fp_mac_d_ff_reg* \
# ID/id2fp_mac_s_ff_reg* \
# ID/id2fp_misc_ff_reg* \
# ID/id2fp_sqrt_d_ff_reg* \
# ID/id2fp_sqrt_s_ff_reg* \
# ID/id2mul_ff_reg* \
# itlb_u/dff_sfence_req_reg* \
# }]

# set_multicycle_path -setup 5 -through [get_pins {EX/MUL/*}] -to [get_pins { \
# EX/MUL/DW_MULT_SEQ/* \
# EX/MUL/* \
# }]
# set_multicycle_path -hold 4  -through [get_cells {EX/MUL/*}] -to [get_cells { \
# EX/ex2ma_ff_reg* \
# EX/MUL/DW_MULT_SEQ*reg* \
# EX/MUL/* \
# ID/id2div_ff_reg* \
# ID/id2ex_ff_reg* \
# ID/id2ex_ff_reg* \
# ID/id2ex_fp_rs1_ff_reg* \
# ID/id2fp_add_d_ff_reg* \
# ID/id2fp_add_s_ff_reg* \
# ID/id2fp_div_d_ff_reg* \
# ID/id2fp_div_s_ff_reg* \
# ID/id2fp_mac_d_ff_reg* \
# ID/id2fp_mac_s_ff_reg* \
# ID/id2fp_misc_ff_reg* \
# ID/id2fp_sqrt_d_ff_reg* \
# ID/id2fp_sqrt_s_ff_reg* \
# ID/id2mul_ff_reg* \
# itlb_u/dff_sfence_req_reg* \
# }]
# set_multicycle_path -hold 4 -through [get_pins {EX/MUL/*}] -to [get_pins { \
# EX/MUL/DW_MULT_SEQ/* \
# EX/MUL/* \
# }]


# set ours(ff,fp) [get_cells -hier {id2ex_ctrl_ff_reg*fp_* id2fp_add_s_ff_reg* id2fp_add_d_ff_reg* id2fp_mac_s_ff_reg* id2fp_mac_d_ff_reg* id2fp_div_s_ff_reg* id2fp_div_d_ff_reg* id2fp_sqrt_s_ff_reg* id2fp_sqrt_d_ff_reg* id2fp_misc_ff_reg*}]
# set ours(ff,fpsqrt) [get_cells -hier {id2fp_sqrt_s_ff_reg*}]

# # multicycle for fp units
# set_multicycle_path -setup 32 -from $ours(ff,fp)
# set_multicycle_path -hold 31 -from $ours(ff,fp)

# set_multicycle_path -setup 33 -from $ours(ff,fpsqrt)
# set_multicycle_path -hold 32 -from $ours(ff,fpsqrt)

# set_multicycle_path -setup 10 -from [get_ports {*_pwr_on* *rst_pc*}]
# set_multicycle_path -hold 9 -from [get_ports {*_pwr_on* *rst_pc*}]

# ## END ORV64
# ## ORV64 <-> VP
# #set vcore(orv,vc) [get_cells -hier { *VCORE_DEC_U* *orv2vc* *vc2orv*}]
# ### set vcore(orv,vc) [get_pins -hier {*orv2vc* *vc2orv*}]
# ### set_multicycle_path -setup 6 -from $vcore(orv,vc)
# ### set_multicycle_path -hold 4 -from $vcore(orv,vc)
# ## END ORV64 <-> VP

# #
# #set_max_delay 1.0 -to  _vector_core/u_FP__floatpoint/v_*___vector/regs__*__regs/regs_*__r/wq_reg/D
# #set_max_delay 1.0 -from _vector_core/u_FP__floatpoint/clk  -to  _vector_core/u_FP__floatpoint/v_*___vector/regs__*__regs/regs_*__r/wq_reg/D


# #**************************************************************
# # Set Maximum Delay
# #**************************************************************
# # assuming 14%
# set_input_delay [expr $clk_period * 0.5] -clock CLK [all_inputs]
# set_output_delay [expr $clk_period * 0.5] -clock CLK [all_outputs]



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************
#set_driving_cell -lib_cell  BUFFD12BWP35P140HVT [all_inputs]
#set_load [get_attr [get_lib_pin tcbn28hpcplusbwp35p140hvtssg0p81vm40c_ccs/BUFFD12BWP35P140HVT/I] pin_capacitance] [all_outputs]


#set_input_transition $latency_input_transition [all_inputs]
#set_input_transition $latency_input_transition_clocks [get_ports clk]


#**************************************************************
# Set Load
#**************************************************************
#set_load [expr $clk_period * 0.01] [all_outputs]
