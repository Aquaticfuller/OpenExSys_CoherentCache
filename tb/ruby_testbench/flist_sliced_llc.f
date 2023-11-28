-f $PROJ_ROOT/flist/include.syn.f
-f $PROJ_ROOT/flist/l1d.f
-f $PROJ_ROOT/$NOC_ROOT/tb/flist_mesh_3x3.f
$PROJ_ROOT/tb/ruby_testbench/mixed_tile.sv
-f $PROJ_ROOT/flist/ebi.f
$PROJ_ROOT/$L1D_ROOT/models/memory/dpram64.v
$PROJ_ROOT/$L1D_ROOT/models/memory/axi_mem.v
$PROJ_ROOT/$L1D_ROOT/models/memory/axi2mem.sv
top_sliced_llc.sv