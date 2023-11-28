+incdir+$PROJ_ROOT/$L1D_ROOT/ruby/include
$PROJ_ROOT/rtl/rvh_pkg.sv
$PROJ_ROOT/rtl/uop_encoding_pkg.sv
$PROJ_ROOT/rtl/riscv_pkg.sv

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

// $PROJ_ROOT/$L1D_ROOT/models/cells/std_dff.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffe.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffr.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffre.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/std_dffrve.sv
$PROJ_ROOT/$L1D_ROOT/models/cells/rrv64_cell_clkgate.v

$PROJ_ROOT/$L1D_ROOT/models/plru/lru_get_new_line.sv
$PROJ_ROOT/$L1D_ROOT/models/plru/lru_update_on_hit.sv

$PROJ_ROOT/rtl/util/usage_manager.sv
$PROJ_ROOT/rtl/util/mp_fifo.sv
// $PROJ_ROOT/rtl/util/mp_fifo_ptr_output.sv
$PROJ_ROOT/rtl/util/sp_fifo_dat_vld_output.sv
$PROJ_ROOT/rtl/util/one_counter.sv
$PROJ_ROOT/rtl/util/priority_encoder.sv
$PROJ_ROOT/rtl/util/onehot_mux.sv
$PROJ_ROOT/rtl/util/one_hot_priority_encoder.sv
$PROJ_ROOT/rtl/util/left_circular_rotate.sv
$PROJ_ROOT/rtl/util/oh2idx.sv
$PROJ_ROOT/rtl/util/one_hot_rr_arb.sv
$PROJ_ROOT/rtl/util/select_two_from_n_valid.sv

$PROJ_ROOT/rtl/util/commoncell/src/Basic/hw/MuxOH.v
$PROJ_ROOT/rtl/util/commoncell/src/Queue/hw/AgeMatrixSelector.v

$PROJ_ROOT/$L1D_ROOT/wrapper/rrv64_generic_ram.v
$PROJ_ROOT/$L1D_ROOT/wrapper/generic_spram.v

$PROJ_ROOT/$L1D_ROOT/rvh_l1d_dec.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_ewrq.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_lst.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_mlfb.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_mshr_alloc.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_mshr.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_plru.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_lsu_hit_resp.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_bank_input_arb.sv
// $PROJ_ROOT/$L1D_ROOT/rvh_l1d_bank_axi_arb.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_bank_cc_arb.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_stb.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_ptw_replay_buffer.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_alu.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_amo_ctrl.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_snp_dec.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_snp_ctrl.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d_bank.sv
$PROJ_ROOT/$L1D_ROOT/rvh_l1d.sv

$PROJ_ROOT/$L1D_ROOT/rvh_scu_mshr.sv
$PROJ_ROOT/$L1D_ROOT/rvh_scu_repl_mshr.sv
// $PROJ_ROOT/$L1D_ROOT/rvh_scu_cc_arb.sv
$PROJ_ROOT/$L1D_ROOT/rvh_scu.sv

$PROJ_ROOT/$L1D_ROOT/ruby/ut_lib.sv
$PROJ_ROOT/$L1D_ROOT/ruby/ruby_top_l1d_adaptor.sv
$PROJ_ROOT/$L1D_ROOT/ruby/rubytest_core.sv
$PROJ_ROOT/$L1D_ROOT/ruby/rrv2rvh_ruby_reqtype_trans.sv
$PROJ_ROOT/$L1D_ROOT/ruby/rrv2rvh_ruby_stmask_trans.sv
$PROJ_ROOT/$L1D_ROOT/ruby/rrv2rvh_ruby_ldmask_trans.sv

$PROJ_ROOT/$L1D_ROOT/trace_input/trace_input.sv

// $PROJ_ROOT/$L1D_ROOT/top_whole_llc.sv
