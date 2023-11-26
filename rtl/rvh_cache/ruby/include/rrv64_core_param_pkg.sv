package rrv64_core_param_pkg;
  parameter RRV64_XLEN             = 64;
  parameter RRV64_INSTR_WIDTH      = 32;
  parameter RRV64_PHY_ADDR_WIDTH   = 56;
  parameter RRV64_VIR_ADDR_WIDTH   = 39;

  parameter RRV64_HART_ID_WIDTH  = 4;


  parameter RRV64_L1C_LINE_WIDTH          = 512;
  parameter RRV64_L1C_LINE_BYTE           = RRV64_L1C_LINE_WIDTH/8;
  parameter RRV64_L1C_LINE_BYTE_W         = $clog2(RRV64_L1C_LINE_BYTE);
  parameter RRV64_L1IC_WAY_NUM         = 4;
  parameter RRV64_L1IC_OPCODE_WIDTH   = 4;
  parameter RRV64_L1IC_TRANS_ID_WIDTH = 8;
  parameter RRV64_L1IC_ERROR_WIDTH    = 4;
  parameter RRV64_L1IC_FETCH_WIDTH   = RRV64_L1C_LINE_WIDTH/4;

  parameter TCM_INDEX_SIZE  =16;
  parameter RRV64_TCM_BASE_ADDR           = 0 ;
  parameter RRV64_TCM_OFFSET              = 10 ;
  parameter ADDR_MASK_WIDTH               = 56;
  parameter AXI_DATA_WIDTH                =128;
  parameter RRV64_L1IC_BYTES            =32*1024;
  parameter RRV64_MSHR_CNT_WIDTH     = 4 ;
  parameter RRV64_L1IC_MSHR_NUM      = 1;//TBD
  parameter RRV64_L1IC_SET_NUM       = (RRV64_L1IC_BYTES/RRV64_L1C_LINE_BYTE/RRV64_L1IC_WAY_NUM);
  parameter RRV64_L1IC_IDX_W     = $clog2(RRV64_L1IC_SET_NUM);
  parameter RRV64_L1IC_ADDR_IDX_W  = RRV64_L1IC_IDX_W + RRV64_L1C_LINE_BYTE_W;
  parameter RRV64_L1IC_WAY_W     = $clog2(RRV64_L1IC_WAY_NUM);



  parameter RRV64_ICACHE_RAM_TAG_WIDTH = RRV64_PHY_ADDR_WIDTH - 12;


  parameter RRV64_L1DC_OPCODE_WIDTH   = 8;
  parameter RRV64_L1DC_TRANS_ID_WIDTH   = 8;
  parameter RRV64_L1DC_SIZE_WIDTH       = 4;
  parameter RRV64_L1DC_ERROR_WIDTH      = 4;
  parameter RRV64_L1DC_REQ_D_WIDTH      = 64;
  parameter RRV64_L1DC_RESP_D_WIDTH     = 64;

  
  parameter RRV64_ISSUE_NUM        = 3;
  parameter RRV64_L1DC_P_NUM       = 2;
  parameter RRV64_BPU_PD_NUM       = 2;
  parameter RRV64_BPU_MATCH_NUM    = RRV64_L1IC_FETCH_WIDTH / 16;

  parameter RRV64_ROB_ENTRY_NUM    = 64;
  parameter RRV64_RF_RD_P_NUM      = RRV64_ISSUE_NUM * 2;
  parameter RRV64_RF_WR_P_NUM      = RRV64_ISSUE_NUM;
  parameter RRV64_RS_FWD_SRC_NUM   = 8;
  parameter RRV64_ALU_NUM = 2;
  parameter RRV64_AGU_NUM = 2;
  parameter RRV64_BRU_NUM = 2;
  parameter RRV64_MUL_NUM = 2;
  parameter RRV64_DIV_NUM = 1;
  parameter RRV64_WB_NUM = RRV64_ALU_NUM + RRV64_AGU_NUM + RRV64_BRU_NUM + RRV64_MUL_NUM + RRV64_DIV_NUM;
  parameter RRV64_RETIRE_NUM = RRV64_ISSUE_NUM;


  parameter RRV64_L1_TLB_TRANS_ID_WIDTH =2;
  parameter RRV64_N_FIELDS_PMPCFG = 8;
  parameter RRV64_N_PMP_CSR = 16;
  parameter int RRV64_PHY_PAGE_PART_WIDTH = 9;
  parameter RRV64_NUM_PAGE_LEVELS = 3;
  parameter RRV64_PTW_LVL_CNT_WIDTH = $clog2(RRV64_NUM_PAGE_LEVELS);
  parameter RRV64_PAGE_SIZE_BYTE = 4096;
  parameter RRV64_PAGE_OFFSET_WIDTH = 12;
  parameter RRV64_PTE_WIDTH = 64;
  parameter RRV64_NUM_PTE_PAGE = (RRV64_PAGE_SIZE_BYTE*8)/RRV64_PTE_WIDTH;
  parameter RRV64_PTE_IDX_WIDTH = $clog2(RRV64_NUM_PTE_PAGE);
  parameter RRV64_PTE_OFFSET_WIDTH = 3;
  parameter RRV64_ASID_WIDTH = 16;
  parameter RRV64_PPN_WIDTH = 44;
  parameter RRV64_VPN_WIDTH = 27;
  parameter RRV64_PPN_PART_WIDTH = 9;
  parameter RRV64_VPN_PART_WIDTH = 9;
  parameter RRV64_NUM_ITLB_ENTRIES = 8;
  parameter RRV64_NUM_DTLB_ENTRIES = 8;
//  parameter RRV64_NUM_L2TLB_ENTRIES = 1024;
//  parameter RRV64_NUM_L2TLB_WAYS = 4;


  parameter RRV64_REDIRECT_OPCODE_WIDTH    = 4;

  parameter RRV64_CSR_OPCODE_WIDTH   = 4;


//Backend parameters
//=================================================
`include "rrv64_core_be_param_pkg.sv"
//
//LSU parameters
`include "rrv64_core_lsu_param_pkg.sv"
//
//{{{
//L2 TLB parameters
parameter RRV64_L2TLB_ENTRY_NUM = 512;
parameter RRV64_L2TLB_WAY_NUM   = 4;
parameter RRV64_L2TLB_SET_NUM   = (RRV64_L2TLB_ENTRY_NUM / RRV64_L2TLB_WAY_NUM);
parameter RRV64_L2TLB_MSHR_NUM  = 4;//1 ITLB + 2 DTLB +S1
parameter RRV64_L2TLB_IDX_W     = $clog2(RRV64_L2TLB_SET_NUM);
parameter RRV64_L2TLB_WAY_W     = $clog2(RRV64_L2TLB_WAY_NUM);
//}}}

//
//ptw parameters
//{{{
parameter RRV64_PTW_CORE_NUM     = 1;
//}}}
//
//
//
//l1d parameters
//================================================
parameter RRV64_L1D_PORT_N =2;
parameter RRV64_L1D_BK_N =2;


parameter RRV64_L1D_TAG_ECC_W      = 0;
parameter RRV64_L1D_DATA_ECC_W      = 0;

parameter RRV64_L1D_TAG_W     =  43;
parameter RRV64_L1D_SET_N       = 64 ;
parameter RRV64_L1D_SET_IDX_W =$clog2(RRV64_L1D_SET_N);
parameter RRV64_L1D_WAY_N       = 4;
parameter RRV64_L1D_WAY_IDX_W =$clog2(RRV64_L1D_WAY_N);


parameter RRV64_L1D_STG_N  = 3;
parameter RRV64_L1D_MSHR_D =4;
parameter RRV64_L1D_MSHR_IDX_W = $clog2(RRV64_L1D_MSHR_D);
parameter RRV64_L1D_SRQ_D  =4;
parameter RRV64_L1D_SRQ_IDX_W = $clog2(RRV64_L1D_SRQ_D);
parameter RRV64_L1D_EWRQ_D  =4;
parameter RRV64_L1D_IORQ_D  =4;

parameter RRV64_L1D_STB_D = 16;
parameter RRV64_L1D_STB_IDX_W = $clog2(RRV64_L1D_STB_D);


parameter RRV64_L1D_TCM_BK_N = 8;
parameter RRV64_L1D_TCM_BK_IDX_W = $clog2(RRV64_L1D_TCM_BK_N);

parameter RRV64_L1D_TCM_DATA_W = 256;
parameter RRV64_L1D_TCM_ENT_N = 128;
parameter RRV64_L1D_TCM_DATA_MASK_W = RRV64_L1D_TCM_DATA_W/64;
parameter RRV64_L1D_TCM_DATA_IDX_W = $clog2(RRV64_L1D_TCM_DATA_MASK_W);
parameter RRV64_L1D_TCM_ENT_IDX_W =  $clog2(RRV64_L1D_TCM_ENT_N);
parameter RRV64_L1D_TCM_OFFSET_W  = 3; //64bits
parameter RRV64_L1D_TCM_ADDR_W = RRV64_L1D_TCM_BK_IDX_W + RRV64_L1D_TCM_ENT_IDX_W + RRV64_L1D_TCM_DATA_IDX_W + RRV64_L1D_TCM_DATA_MASK_W + RRV64_L1D_TCM_OFFSET_W;


//
//BPU
//{{{
  parameter  RRV64_BPU_FETCH_SIZE   = RRV64_L1IC_FETCH_WIDTH/8;
  parameter  RRV64_BPU_FETCH_SIZE_W = $clog2(RRV64_BPU_FETCH_SIZE);
  parameter  RRV64_BPU_BTB_ENTRIES  = 256;
  parameter  RRV64_BPU_BTB_WAYS     = 4;
  parameter  RRV64_BPU_BTB_BLK_SIZE = RRV64_BPU_FETCH_SIZE/RRV64_BPU_BTB_WAYS;
  parameter  RRV64_BPU_BTB_BLK_SIZE_W = $clog2(RRV64_BPU_BTB_BLK_SIZE);
  parameter  RRV64_BPU_BTB_WAY_W    = $clog2(RRV64_BPU_BTB_WAYS);
  parameter  RRV64_BPU_BTB_SETS     = RRV64_BPU_BTB_ENTRIES/RRV64_BPU_BTB_WAYS;
  parameter  RRV64_BPU_BTB_SETS_W   = $clog2(RRV64_BPU_BTB_SETS);
  parameter  RRV64_BPU_RAS_ENTRIES  = 4;
  parameter  RRV64_BPU_OFFSET_W  = $clog2(RRV64_BPU_FETCH_SIZE) - 1;
  parameter  RRV64_BPU_BTB_TAG_W    = RRV64_VIR_ADDR_WIDTH - RRV64_BPU_BTB_SETS_W - RRV64_BPU_FETCH_SIZE_W;

  parameter  RRV64_BPU_LOOKUP_PN    = RRV64_BPU_BTB_WAYS;//look up port number
  //parameter  RRV64_BPU_UPDATE_PN    = 2;//update port number
  parameter RRV64_BPU_GHR_SIZE    = 9;
  parameter RRV64_BPU_BHT_ENTRIES = 512;
  parameter RRV64_BPU_BHT_ADDR_W  = $clog2(RRV64_BPU_BHT_ENTRIES);
  parameter RRV64_BPU_BHT_CNT_W   = 2;
//   parameter RRV64_BPU_PIPE_NUM    = 2;

//   parameter RRV64_BPU_LHR_SIZE    = 10;
//   parameter RRV64_BPU_LHT_ENTRIES = 1024;
//   parameter RRV64_BPU_LHT_ADDR_W  = $clog2(RRV64_BPU_LHT_ENTRIES);

//   parameter RRV64_BPU_SLT_CNT_W   = 2;
//   parameter RRV64_BPU_SLT_ENTRIES = 4096;
//   parameter RRV64_BPU_SLT_ADDR_W  = $clog2(RRV64_BPU_SLT_ENTRIES);

// //uBTB related
//   //uBTB uBTB module
//   parameter  RRV64_BPU_UBTB_UBTB_ENTRY_N = 64;
//   parameter  RRV64_BPU_UBTB_UBTB_ENTRY_W = $clog2(RRV64_BPU_UBTB_UBTB_ENTRY_N);

//   //uBTB BHT module
//   parameter  RRV64_BPU_UBTB_BHT_ENTRY_N = 128;
//   parameter  RRV64_BPU_UBTB_BHT_ENTRY_W = $clog2(RRV64_BPU_UBTB_BHT_ENTRY_N);
//   parameter  RRV64_BPU_UBTB_BHT_SAT_CNT_W = 2;

//}}} 
  
//memory size paramemter
  // parameter RRV64_L1DC_DATA_MEM_BITEN_W = 137;
  // parameter RRV64_L1DC_DATA_MEM_ADDR_W = 137;
  // parameter RRV64_L1DC_DATA_MEM_DATA_W = 137;
  
  // parameter RRV64_L1DC_TAG_MEM_NUM = 137;
  // parameter RRV64_L1DC_TAG_MEM_BITEN_W = 137;
  // parameter RRV64_L1DC_TAG_MEM_ADDR_W = 137;
  // parameter RRV64_L1DC_TAG_MEM_DATA_W = 137;


endpackage
