-f $PROJ_ROOT/flist/include.syn.f

$PROJ_ROOT/tb/ruby_testbench/sky130_sram_1kbyte_1rw1r_32x256_8.v

-f $PROJ_ROOT/flist/l1d_backend.f

$PROJ_ROOT/$L1D_ROOT/rvh_scu_mshr.sv
$PROJ_ROOT/$L1D_ROOT/rvh_scu_repl_mshr.sv
$PROJ_ROOT/$L1D_ROOT/rvh_scu.sv

-f $PROJ_ROOT/flist/noc.syn.f
-f $PROJ_ROOT/flist/ebi.f

$PROJ_ROOT/rtl/rvh_node/wbarbiter.v
$PROJ_ROOT/rtl/rvh_node/axilrd2wbsp.v
$PROJ_ROOT/rtl/rvh_node/axilwr2wbsp.v
$PROJ_ROOT/rtl/rvh_node/axlite2wbsp.v
$PROJ_ROOT/rtl/rvh_node/llqspi.v
$PROJ_ROOT/rtl/rvh_node/wbqspiflash.v
$PROJ_ROOT/rtl/rvh_node/axi_qspi.sv
$PROJ_ROOT/tb/ruby_testbench/hn_tile.sv
$PROJ_ROOT/rtl/rvh_node/hn_wrapper.sv