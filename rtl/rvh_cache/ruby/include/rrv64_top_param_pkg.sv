package rrv64_top_param_pkg;
  import rrv64_top_macro_pkg::*;
///////////add by yangzhilei 2021/12/30/////
parameter RRV64_CORE_N = 4;

`ifdef CORE_NUM_4
  parameter RRV64_CORE_N = 4;
`elsif CORE_NUM_3
  parameter RRV64_CORE_N = 3;
`elsif CORE_NUM_2
  parameter RRV64_CORE_N = 2;
`elsif CORE_NUM_1
  parameter RRV64_CORE_N = 1;
`elsif CORE_NUM_5
  parameter RRV64_CORE_N = 5;
`elsif CORE_NUM_6
  parameter RRV64_CORE_N = 6;
`elsif CORE_NUM_7
  parameter RRV64_CORE_N = 7;
`elsif CORE_NUM_8
  parameter RRV64_CORE_N = 8;
`else
`endif





parameter CORE_NUM            =RRV64_CORE_N;
parameter RRV64_CORE_IDX_W = $clog2(RRV64_CORE_N);
parameter VIR_ADDR_WIDTH        = 39;
parameter PHY_ADDR_WIDTH        = 56;
////////////////////////////////////////////////
////////////////CACHE para/////////////////////////
///////////////////////////////////////////////
parameter  RRV64_LINE_ADDR_W   =  50;
parameter  RRV64_LINE_DATA_W   = 512;
parameter  RRV64_LINE_SEG_DATA_W   = 128;
parameter  RRV64_BUS_DATA_W    = 128;
parameter  RRV64_OUT_BUS_DATA_W    = 64;
parameter  RRV64_LINE_OFFSET_W = 6;
parameter  RRV64_BUS_LINE_BURST_N = RRV64_LINE_DATA_W/RRV64_BUS_DATA_W;
parameter  RRV64_OUT_BUS_LINE_BURST_N = RRV64_LINE_DATA_W/RRV64_OUT_BUS_DATA_W;

//RRV64_OUT M channel 0/1
  parameter UNCORE_OUT_AXI_M_RID_WIDTH    = 4;
  parameter UNCORE_OUT_AXI_M_RADDR_WIDTH  = PHY_ADDR_WIDTH;
  parameter UNCORE_OUT_AXI_M_RDATA_WIDTH  = RRV64_OUT_BUS_DATA_W;
  parameter UNCORE_OUT_AXI_M_WID_WIDTH    = 2;
  parameter UNCORE_OUT_AXI_M_WADDR_WIDTH  = PHY_ADDR_WIDTH;
  parameter UNCORE_OUT_AXI_M_WDATA_WIDTH  = RRV64_OUT_BUS_DATA_W;
////RRV64_OUT M channel peri
  parameter UNCORE_OUT_AXI_M_PERI_RID_WIDTH    = 2;
  parameter UNCORE_OUT_AXI_M_PERI_RADDR_WIDTH  = PHY_ADDR_WIDTH;
  parameter UNCORE_OUT_AXI_M_PERI_RDATA_WIDTH  = RRV64_OUT_BUS_DATA_W;
  parameter UNCORE_OUT_AXI_M_PERI_WID_WIDTH    = 2;
  parameter UNCORE_OUT_AXI_M_PERI_WADDR_WIDTH  = PHY_ADDR_WIDTH;
  parameter UNCORE_OUT_AXI_M_PERI_WDATA_WIDTH  = RRV64_OUT_BUS_DATA_W;
// //OUT_RRV64 ACP S channel
  parameter OUT_UNCORE_AXI_S_TCM_RID_WIDTH    = 8;
  parameter OUT_UNCORE_AXI_S_TCM_RADDR_WIDTH  = PHY_ADDR_WIDTH;
  parameter OUT_UNCORE_AXI_S_TCM_RDATA_WIDTH  = RRV64_OUT_BUS_DATA_W;
  parameter OUT_UNCORE_AXI_S_TCM_WID_WIDTH    = 8;
  parameter OUT_UNCORE_AXI_S_TCM_WADDR_WIDTH  = PHY_ADDR_WIDTH;
  parameter OUT_UNCORE_AXI_S_TCM_WDATA_WIDTH  = RRV64_OUT_BUS_DATA_W;
//OUT_RRV64 ACP S channel
  parameter OUT_UNCORE_AXI_S_ACP_RID_WIDTH    = 8;
  parameter OUT_UNCORE_AXI_S_ACP_RADDR_WIDTH  = PHY_ADDR_WIDTH;
  parameter OUT_UNCORE_AXI_S_ACP_RDATA_WIDTH  = RRV64_OUT_BUS_DATA_W;
  parameter OUT_UNCORE_AXI_S_ACP_WID_WIDTH    = 8;
  parameter OUT_UNCORE_AXI_S_ACP_WADDR_WIDTH  = PHY_ADDR_WIDTH;
  parameter OUT_UNCORE_AXI_S_ACP_WDATA_WIDTH  = RRV64_OUT_BUS_DATA_W;


//L1-L2 axi channel
//Icache
parameter L1I_L2_AXI_RID_WIDTH    = 5;
parameter L1I_L2_AXI_RADDR_WIDTH  = PHY_ADDR_WIDTH;
parameter L1I_L2_AXI_RDATA_WIDTH  = RRV64_BUS_DATA_W;
//Dcache
parameter L1D_L2_AXI_RID_WIDTH     = 3;
parameter L1D_L2_AXI_RADDR_WIDTH   = PHY_ADDR_WIDTH;
parameter L1D_L2_AXI_RDATA_WIDTH   = RRV64_BUS_DATA_W;
parameter L1D_L2_AXI_WID_WIDTH     = 3;
parameter L1D_L2_AXI_WADDR_WIDTH   = PHY_ADDR_WIDTH;
parameter L1D_L2_AXI_WDATA_WIDTH   = RRV64_BUS_DATA_W;



endpackage
