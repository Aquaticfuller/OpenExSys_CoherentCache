-f $PROJ_ROOT/flist/l1d_backend.f

$PROJ_ROOT/$NOC_ROOT/tb/v_noc_pkg.sv  
$PROJ_ROOT/rtl/util/mp_fifo_ptr_output.sv
$PROJ_ROOT/rtl/util/freelist.sv
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
$PROJ_ROOT/$NOC_ROOT/rtl/rn_router_sam.sv

-f $PROJ_ROOT/flist/ebi.f

$PROJ_ROOT/tb/ruby_testbench/rn_tile.sv
$PROJ_ROOT/rtl/rvh_node/rn_wrapper.sv