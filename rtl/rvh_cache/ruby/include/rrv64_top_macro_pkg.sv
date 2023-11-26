package rrv64_top_macro_pkg;
//`define RRV64_MODEL_MODE
//`define RRV64_ENABLE_FP
//`define FPGA_ONLY_CORE0
//`define RRV64_ASSERTION_EN//FIXME,should be added in testbench file
`define RRV64_ENABLE_OOO_ISSUE
`define RRV64_CPU_VERSION
`define RRV64_SUPPORT_P_FILTER
//`define RRV64_RCU_VERSION
//
`ifdef RRV64_CPU_VERSION
  `define RRV64_SUPPORT_AXI_M_1
  `define RRV64_SUPPORT_AXI_M_PERI
  `define RRV64_SUPPORT_L2
//  `define RRV64_SUPPORT_AXI_S_TCM
  `define RRV64_SUPPORT_AXI_S_ACP
  `define RRV64_SUPPORT_MMU
`endif

`ifdef RRV64_RCU_VERSION
  `define RRV64_SUPPORT_AXI_M_1
  `define RRV64_SUPPORT_AXI_M_PERI
  `define RRV64_SUPPORT_L2
  `define RRV64_SUPPORT_AXI_S_TCM
  `define RRV64_SUPPORT_AXI_S_ACP
`endif

`ifdef RRV64_SUPPORT_L2
  //`define RRV64_SUPPORT_L1L2_INCLUSIVE
  `define RRV64_SUPPORT_L1L2_EXCLUSIVE
`endif


endpackage
