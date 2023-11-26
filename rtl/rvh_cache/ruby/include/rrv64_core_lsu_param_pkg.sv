import rvh_l1d_pkg::*;

parameter RRV64_LSU_P_NUM = RRV64_AGU_NUM;

parameter RRV64_LSU_OPCODE_WIDTH   = 8;
parameter RRV64_LSU_TRANS_ID_WIDTH   = 8;
parameter RRV64_LSU_SIZE_WIDTH   = 4;
parameter RRV64_LSU_ERROR_WIDTH   = 4;
parameter RRV64_LSU_REQ_D_WIDTH   = 64;
parameter RRV64_LSU_RESP_D_WIDTH   = 64;

parameter RRV64_LSU_FIFO_DEPTH   =    8;
parameter RRV64_LSU_QID_NUM = RRV64_LSU_FIFO_DEPTH;
parameter RRV64_LSU_QID_WIDTH = $clog2(RRV64_LSU_QID_NUM);
`ifdef RUBY
parameter RRV64_LSU_ID_WIDTH = $clog2(32) + $clog2(RUBY_TOP_L1D_PORT_NUM*RUBY_TOP_L1D_NUM);;
`else
parameter RRV64_LSU_ID_WIDTH = RRV64_LSU_QID_WIDTH + 2 + 1;
`endif
parameter RRV64_LSU_CACHE_FLUSH_OPCODE_WIDTH = 6;

parameter LSU_REQ_SRC_BE  = 2'h0;
parameter LSU_REQ_SRC_PTW = 2'h1;

parameter RRV64_LSU_EXCP_FIFO_DEPTH   =    2;
parameter RRV64_LSU_MISS_QUEUE_DEPTH   =   3;

parameter RRV64_LSU_PA_CHK_BITS = 33;//8GB. 506 on need 4GB - 8GB can be constrain with pmp


//uncore's CFG space range
parameter LSU_UNCORE_CFG_MIN_ADDR = 'hFF02_4000;
parameter LSU_UNCORE_CFG_MAX_ADDR = 'hFF02_4FFF;