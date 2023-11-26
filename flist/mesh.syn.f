+incdir+$PROJ_ROOT/$L1D_ROOT/ruby/include
$PROJ_ROOT/rtl/rvh_pkg.sv
$PROJ_ROOT/rtl/uop_encoding_pkg.sv
$PROJ_ROOT/rtl/riscv_pkg.sv

$PROJ_ROOT/$NOC_ROOT/rtl/include/rvh_noc_pkg.sv
$PROJ_ROOT/$NOC_ROOT/tb/v_noc_pkg.sv  
$PROJ_ROOT/$L1D_ROOT/include/rvh_uncore_param_pkg.sv
$PROJ_ROOT/$L1D_ROOT/include/rvh_l1d_cc_pkg.sv
$PROJ_ROOT/$L1D_ROOT/include/rvh_l1d_pkg.sv
$PROJ_ROOT/$L1D_ROOT/ruby/include/rubytest_define.sv


$PROJ_ROOT/$L1D_ROOT/ruby/include/rrv64_top_macro_pkg.sv
$PROJ_ROOT/$L1D_ROOT/ruby/include/rrv64_top_param_pkg.sv
$PROJ_ROOT/$L1D_ROOT/ruby/include/rrv64_core_param_pkg.sv
$PROJ_ROOT/$L1D_ROOT/ruby/include/rrv64_top_typedef_pkg.sv
$PROJ_ROOT/$L1D_ROOT/ruby/include/rrv64_core_typedef_pkg.sv
$PROJ_ROOT/$L1D_ROOT/ruby/include/rrv64_uncore_param_pkg.sv
$PROJ_ROOT/$L1D_ROOT/ruby/include/rrv64_uncore_typedef_pkg.sv
$PROJ_ROOT/$L1D_ROOT/ruby/include/rrv64_core_func_pkg.sv

$PROJ_ROOT/$L1D_ROOT/ruby/include/ruby_pkg.sv



$PROJ_ROOT/tb/ruby_testbench/sky130_sram_1kbyte_1rw1r_32x256_8.v


$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffe.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffr.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffre.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffrve.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/rrv64_cell_clkgate.v
$PROJ_ROOT/$L1D_ROOT/models/plru/lru_get_new_line.sv
$PROJ_ROOT/$L1D_ROOT/models/plru/lru_update_on_hit.sv

$PROJ_ROOT/rtl/util/usage_manager.sv
$PROJ_ROOT/rtl/util/mp_fifo.sv
$PROJ_ROOT/rtl/util/mp_fifo_ptr_output.sv
$PROJ_ROOT/rtl/util/sp_fifo_dat_vld_output.sv
$PROJ_ROOT/rtl/util/one_counter.sv
$PROJ_ROOT/rtl/util/priority_encoder.sv
$PROJ_ROOT/rtl/util/onehot_mux.sv
$PROJ_ROOT/rtl/util/one_hot_priority_encoder.sv
$PROJ_ROOT/rtl/util/left_circular_rotate.sv
$PROJ_ROOT/rtl/util/oh2idx.sv
$PROJ_ROOT/rtl/util/one_hot_rr_arb.sv
$PROJ_ROOT/rtl/util/select_two_from_n_valid.sv
$PROJ_ROOT/rtl/util/freelist.sv

$PROJ_ROOT/rtl/util/commoncell/src/Basic/hw/MuxOH.v
$PROJ_ROOT/rtl/util/commoncell/src/Queue/hw/AgeMatrixSelector.v

// $PROJ_ROOT/$L1D_ROOT/wrapper/rrv64_generic_ram.v
$PROJ_ROOT/$L1D_ROOT/wrapper/generic_spram.v

$PROJ_ROOT/$L1D_ROOT/rvh_l1d_mshr_alloc.sv


$PROJ_ROOT/$L1D_ROOT/rvh_scu_mshr.sv
$PROJ_ROOT/$L1D_ROOT/rvh_scu_repl_mshr.sv
$PROJ_ROOT/$L1D_ROOT/rvh_scu.sv

$PROJ_ROOT/$NOC_ROOT/rtl/model/simple_dual_one_clock.v

$PROJ_ROOT/$NOC_ROOT/rtl/input_port.sv
$PROJ_ROOT/$NOC_ROOT/rtl/look_adead_routing.sv
$PROJ_ROOT/$NOC_ROOT/rtl/output_port_vc_selection.sv
$PROJ_ROOT/$NOC_ROOT/rtl/input_port_vc.sv
$PROJ_ROOT/$NOC_ROOT/rtl/output_port_vc_assignment.sv
$PROJ_ROOT/$NOC_ROOT/rtl/priority_req_select.sv
$PROJ_ROOT/$NOC_ROOT/rtl/sa_global.sv
$PROJ_ROOT/$NOC_ROOT/rtl/switch.sv
$PROJ_ROOT/$NOC_ROOT/rtl/input_port_flit_decoder.sv
$PROJ_ROOT/$NOC_ROOT/rtl/input_to_output.sv
$PROJ_ROOT/$NOC_ROOT/rtl/output_port_vc_credit_counter.sv
$PROJ_ROOT/$NOC_ROOT/rtl/sa_local.sv
$PROJ_ROOT/$NOC_ROOT/rtl/performance_monitor.sv
$PROJ_ROOT/$NOC_ROOT/rtl/vnet_router.sv


$PROJ_ROOT/$NOC_ROOT/rtl/local_port_look_adead_routing.sv
$PROJ_ROOT/$NOC_ROOT/rtl/local_port_couple_module.sv

$PROJ_ROOT/$NOC_ROOT/rtl/hn_router_sam.sv
// $PROJ_ROOT/$NOC_ROOT/rtl/rn_router_sam.sv
// $PROJ_ROOT/tb/ruby_testbench/rn_tile.sv
$PROJ_ROOT/tb/ruby_testbench/hn_tile.sv

$PROJ_ROOT/tb/ruby_testbench/mesh_hn_top.sv