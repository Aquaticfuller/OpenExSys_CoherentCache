//===============================================
// Filename     : rrv64_core_be_param_pkg.sv
// Author       : cuiluping
// Email        : luping.cui@rivai.ai
// Date         : 2022-04-14 16:34:48
// Description  : 
//================================================
//Backend parameters
//===============================================

parameter   RRV64_INT_PHY_REG_NUM           = 64;
parameter   RRV64_INT_REG_NUM               = 32;
parameter   RRV64_INT_REG_ADDR_W            = $clog2(RRV64_INT_REG_NUM);
parameter   RRV64_INT_REG_DATA_W            = 64;
parameter   RRV64_INT_PHY_REG_ADDR_W        = $clog2(RRV64_INT_PHY_REG_NUM);

parameter   RRV64_FP_PHY_REG_NUM            = 48;
parameter   RRV64_FP_REG_NUM                = 32;
parameter   RRV64_FP_REG_ADDR_W             = $clog2(RRV64_FP_REG_NUM);
parameter   RRV64_FP_REG_DATA_W             = 64;
parameter   RRV64_FP_PHY_REG_ADDR_W         = $clog2(RRV64_FP_PHY_REG_NUM);

parameter   RRV64_PHY_REG_NUM               = RRV64_INT_PHY_REG_NUM;
parameter   RRV64_REG_NUM                   = RRV64_INT_REG_NUM;
parameter   RRV64_REG_ADDR_W                = $clog2(RRV64_REG_NUM);
parameter   RRV64_REG_DATA_W                = RRV64_INT_REG_DATA_W;
parameter   RRV64_PHY_REG_ADDR_W            = $clog2(RRV64_PHY_REG_NUM);

parameter   RRV64_VPC_W                     = RRV64_VIR_ADDR_WIDTH;
parameter   RRV64_EXE_SUB_OP_W              = 6;
parameter   RRV64_DCD_IMM_W                 = 20;
parameter   RRV64_ROB_ADDR_W                = $clog2(RRV64_ROB_ENTRY_NUM);
parameter   RRV64_ALU_IMM_W                 = 20;
parameter   RRV64_BRU_IMM_W                 = 20;
parameter   RRV64_LSU_IMM_W                 = 12;
parameter   RRV64_ISSUEQ_NUM                = 7;
parameter   RRV64_ISSUE_PORT_NUM            = 8;
parameter   RRV64_LSU_ISSUE_NUM             = 2;
parameter   RRV64_LSU_ISSUEQ_NUM            = 1;
parameter   RRV64_LSU_WAKEUP_NUM            = 1;
parameter   RRV64_LSU_POB_WR_NUM            = 2;
parameter   RRV64_ISSUEW_IPRF_RD_PORT_NUM   = 16;
parameter   RRV64_IPRF_RD_PORT_NUM          = 6;
parameter   RRV64_IPRF_WR_PORT_NUM          = 4;
parameter   RRV64_EXE_INT_EARLY_WR_PORT_NUM = 3;
parameter   RRV64_EXE_INT_WR_PORT_NUM       = 8;
parameter   RRV64_ISSUEW_FPRF_RD_PORT_NUM   = 4;
parameter   RRV64_EXE_FP_WR_PORT_NUM        = 2;
parameter   RRV64_FPRF_RD_PORT_NUM          = 4;
parameter   RRV64_FPRF_WR_PORT_NUM          = 2;
parameter   RRV64_EXE_ROB_WR_PORT_NUM       = 9;
parameter   RRV64_ISSUEW_ROB_RD_PORT_NUM    = 3;

parameter   RRV64_ALU_QUEUE_WS              = 4;//ALU queue window size for out of order issue
parameter   RRV64_MUL_QUEUE_WS              = 4;


parameter   RRV64_HARTID_W                  = 8;
parameter   RRV64_CSR_ADDR_W                = 12;

parameter   RRV64_N_CYCLE_INT_DIV           = 30;

//paramter for fpu
//--------------------------------------------
parameter   FP_CNTR_BIT_WIDTH               = 6;
parameter   RRV64_N_CYCLE_FP_ADD_S          = FP_CNTR_BIT_WIDTH'(6);
parameter   RRV64_N_CYCLE_FP_ADD_D          = FP_CNTR_BIT_WIDTH'(6);
parameter   RRV64_N_CYCLE_FP_CMP_S          = FP_CNTR_BIT_WIDTH'(3);
parameter   RRV64_N_CYCLE_FP_CMP_D          = FP_CNTR_BIT_WIDTH'(3);
parameter   RRV64_N_CYCLE_FP_MAC_S          = FP_CNTR_BIT_WIDTH'(8);
parameter   RRV64_N_CYCLE_FP_MAC_D          = FP_CNTR_BIT_WIDTH'(10);
parameter   RRV64_N_CYCLE_FP_MUL_S          = FP_CNTR_BIT_WIDTH'(5);
parameter   RRV64_N_CYCLE_FP_MUL_D          = FP_CNTR_BIT_WIDTH'(6);
parameter   RRV64_N_CYCLE_FP_DIV_S          = FP_CNTR_BIT_WIDTH'(13);
parameter   RRV64_N_CYCLE_FP_DIV_D          = FP_CNTR_BIT_WIDTH'(13);
parameter   RRV64_N_CYCLE_FP_SQRT_S         = FP_CNTR_BIT_WIDTH'(12);
parameter   RRV64_N_CYCLE_FP_SQRT_D         = FP_CNTR_BIT_WIDTH'(13);
parameter   RRV64_N_CYCLE_FP_MISC           = FP_CNTR_BIT_WIDTH'(5);
parameter   RRV64_N_CYCLE_FP_MV             = FP_CNTR_BIT_WIDTH'(1);

parameter   RRV64_FPU_SD_DIFF_IDX           = 5;

//constant for floating-points
parameter   RRV64_CONST_FP_D_CANON_NAN      = {1'b0,{11{1'b1}},1'b1,51'b0};
parameter   RRV64_CONST_FP_D_ZERO           = 63'b0;
parameter   RRV64_CONST_FP_D_POS_ZERO       = 64'b0;
parameter   RRV64_CONST_FP_D_NEG_ZERO       = {1'b1,63'b0};
parameter   RRV64_CONST_FP_D_POS_INF        = {1'b0,{11{1'b1}},52'b0};
parameter   RRV64_CONST_FP_D_NEG_INF        = {1'b1,{11{1'b1}},52'b0};

parameter   RRV64_CONST_FP_S_CANON_NAN      = {1'b0,{8{1'b1}},1'b1,22'b0};
parameter   RRV64_CONST_FP_S_ZERO           = 31'b0;
parameter   RRV64_CONST_FP_S_POS_ZERO       = 32'b0;
parameter   RRV64_CONST_FP_S_NEG_ZERO       = {1'b1,31'b0};
parameter   RRV64_CONST_FP_S_POS_INF        = {1'b0,{8{1'b1}},23'b0};
parameter   RRV64_CONST_FP_S_NEG_INF        = {1'b1,{8{1'b1}},23'b0};
