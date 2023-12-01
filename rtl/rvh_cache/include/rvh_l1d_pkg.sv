package rvh_l1d_pkg;
import rvh_pkg::*;
import uop_encoding_pkg::*;
import rvh_l1d_cc_pkg::*;
import rvh_noc_pkg::*;
import rvh_uncore_param_pkg::*;

// `ifdef RUBY
//rubytop_l1d_adaptor
parameter RUBY_TOP_L1D_PORT_NUM = 2;
parameter RUBY_TOP_L1D_NUM = L1D_NUM;
// `endif

localparam L1D_BANK_LINE_DATA_SIZE = DATA_LINE_W; // bits

`ifdef SYNTHESIS
localparam L1D_BANK_SET_NUM = 2; // sets
`else
localparam L1D_BANK_SET_NUM = 32; // sets
`endif
localparam L1D_BANK_WAY_NUM = 4;
localparam L1D_BANK_ID_NUM = 2;

// localparam INDEX_WIDTH = $clog2(L1D_BANK_SET_NUM);
localparam L1D_INDEX_WIDTH  = $clog2(L1D_BANK_SET_NUM*L1D_BANK_ID_NUM);
localparam L1D_OFFSET_WIDTH = $clog2(L1D_BANK_LINE_DATA_SIZE/8);
localparam L1D_BIT_OFFSET_WIDTH = $clog2(L1D_BANK_LINE_DATA_SIZE);
localparam L1D_TAG_WIDTH    = PADDR_WIDTH-L1D_INDEX_WIDTH-L1D_OFFSET_WIDTH;

`ifdef SYNTHESIS
localparam L1D_STB_ID_NUM = 2;
`else
localparam L1D_STB_ID_NUM = 4;
`endif

localparam L1D_STB_ID_WIDTH = $clog2(L1D_STB_ID_NUM);
localparam L1D_STB_DATA_WIDTH = DATA_LINE_W;
localparam L1D_STB_LINE_ADDR_SIZE = PADDR_WIDTH-L1D_OFFSET_WIDTH;
localparam L1D_OFFSET_BIT_DIFF_STB_SEG = $clog2(L1D_BANK_LINE_DATA_SIZE/L1D_STB_DATA_WIDTH);

localparam L1D_BANK_SET_INDEX_WIDTH = $clog2(L1D_BANK_SET_NUM);
localparam L1D_BANK_ID_INDEX_WIDTH  = $clog2(L1D_BANK_ID_NUM);
localparam L1D_BANK_OFFSET_WIDTH  = L1D_OFFSET_WIDTH;
localparam L1D_BANK_TAG_WIDTH     = L1D_TAG_WIDTH;
localparam L1D_BANK_WAY_INDEX_WIDTH = $clog2(L1D_BANK_WAY_NUM);

localparam L1D_BANK_LINE_ADDR_SIZE = PADDR_WIDTH-L1D_OFFSET_WIDTH-L1D_BANK_ID_INDEX_WIDTH;
localparam L1D_BANK_PADDR_TAG_WIDTH = PADDR_WIDTH-L1D_BANK_SET_INDEX_WIDTH-L1D_BANK_ID_INDEX_WIDTH-L1D_BANK_OFFSET_WIDTH;
localparam L1D_BANK_TAG_RAM_WORD_WIDTH = L1D_BANK_PADDR_TAG_WIDTH; 

localparam L1D_BANK_SNOOP_REQ_BUFFER_DEPTH = VC_DEPTH_MAX; 


// s_axi_awsize    width(byte)
// 3'b000          1
// 3'b001          2
// 3'b010          4
// 3'b011          8
// 3'b100          16
// 3'b101          32
// 3'b110          64
// 3'b111          128
localparam MEM_DATA_WIDTH = 64;
localparam BURST_SIZE = L1D_BANK_LINE_DATA_SIZE/MEM_DATA_WIDTH;//8
localparam AXI_SIZE = $clog2(MEM_DATA_WIDTH/8);
localparam N_MSHR = L1D_MSHR_NUM; // num of MSHR
localparam N_MSHR_W = $clog2(N_MSHR);
// localparam PPN_WIDTH = 44;
localparam N_EWRQ = N_MSHR;
localparam N_MLFB = N_MSHR;


localparam MEMNOC_TID_MASTERID_SIZE  = L1D_BANK_ID_NUM > 1 ? $clog2(L1D_BANK_ID_NUM) : 1;
localparam MEMNOC_TID_TID_SIZE       = SCU_MSHR_NUM > 1 ? $clog2(SCU_MSHR_NUM) : 1;

`ifdef RUBY
// localparam RRV64_LSU_ID_WIDTH = LDQ_TAG_WIDTH + 2;
// parameter RT_TRANS_ID_NUM_W   = $clog2(RT_TRANS_ID_NUM);
localparam RRV64_LSU_ID_WIDTH = $clog2(32) + $clog2(RUBY_TOP_L1D_PORT_NUM*RUBY_TOP_L1D_NUM);
`endif

  typedef logic [N_MSHR_W-1:0]   mshr_id_t;

  typedef enum logic [1:0] {
    INVALID,
    SHARED,
    EXCLUSIVE,
    MODIFIED
  } rrv64_mesi_type_e;

  typedef struct packed {
    logic [MEMNOC_TID_MASTERID_SIZE-1:0] bid; // cache bank id, the highest used for distinguish i$/d$
    logic [MEMNOC_TID_TID_SIZE-1:0] tid;      // mshr id in ar and r
  } mem_tid_t;
  typedef enum logic[1:0] {
    AXI_RESP_OKAY = 2'b00,
    AXI_RESP_EXOKAY = 2'b01,
    AXI_RESP_SLVERR = 2'b10,
    AXI_RESP_DECERR = 2'b11
  } axi4_resp_t;

  typedef struct packed {
    logic IsShared;
    logic PassDarty;
    axi4_resp_t rresp_axi;
  } ace_resp_t;

  typedef struct packed {
    // ace aw
    logic [2:0] awsnoop;
    logic [1:0] awdomain;
    logic [1:0] awbar;
    logic       awunique;

    // axi aw
    mem_tid_t awid;
    logic [PADDR_WIDTH-1:0]  awaddr;
    logic [7 : 0] awlen;
    logic [2 : 0] awsize; // TODO: 
    logic [1 : 0] awburst; // TODO:
} cache_mem_if_aw_t;

  typedef struct packed {
    logic [MEM_DATA_WIDTH-1:0]  wdata;
    logic wlast;
    mem_tid_t wid;
} cache_mem_if_w_t;

  typedef struct packed {
    // ace ar
    logic [3:0] arsnoop;
    logic [1:0] ardomain;
    logic [1:0] arbar;

    // axi ar
    mem_tid_t   arid;
    logic [7:0] arlen;
    logic [2:0] arsize; // TODO: 
    logic [1:0] arburst; // TODO:
    logic [PADDR_WIDTH-1:0]  araddr;
  } cache_mem_if_ar_t;

  // typedef struct packed {
  //   mem_tid_t rid;
  //   logic [MEM_DATA_WIDTH-1:0]  rdata;
  //   axi4_resp_t rresp;
  //   logic rlast;
  // } cache_mem_if_r_t;

  typedef struct packed {
    // ace r
    ace_resp_t rresp;

    // axi r
    mem_tid_t                        rid;
    logic [MEM_DATA_WIDTH-1:0]       dat;
    logic                            err;
    rrv64_mesi_type_e                mesi_sta;
    // logic [RRV64_SCU_SST_IDX_W-1:0]  sst_idx;
    // axi4_resp_t rresp; // TODO: 
    logic rlast;  // TODO: 
  //    logic                            l2_hit;
  } cache_mem_if_r_t;

  typedef struct packed {
    mem_tid_t bid;
    axi4_resp_t bresp;
  } cache_mem_if_b_t;

  // ace5 snoop channels
    // snoop addr
  typedef struct packed {
    // mem_tid_t acid;
    logic [L1D_STB_LINE_ADDR_SIZE-1:0]  acaddr;
    logic [3:0]              acsoop;
    logic [2:0]              acprot;
  } cache_mem_if_ac_t;

    // snoop resp
  typedef struct packed {
    logic WasUnique;
    logic IsShared;
    logic PassDirty;
    logic Error; // for ECC, not used
    logic DataTransfer;
  } cr_crresp_t;

  typedef struct packed {
    // mem_tid_t crid;
    cr_crresp_t crresp;
  } cache_mem_if_cr_t;

    // snoop data
  typedef struct packed {
    // mem_tid_t cdid;
    logic [L1D_BANK_LINE_DATA_SIZE-1:0] cddata;
    logic                               cdlast;
  } cache_mem_if_cd_t;





  typedef enum logic [2:0] {
    AMOSWAP,
    AMOADD,
    AMOAND,
    AMOOR,
    AMOXOR,
    AMOMAX,
    AMOMIN
  } l1d_amo_type_e;

  typedef struct packed {
    logic          is_ld;
    logic          is_ptw_ld;
    logic          is_st;
    logic          is_amo;
    logic          amo_u;
    l1d_amo_type_e amo_type;
    logic          is_lr;
    logic          is_sc;
    logic          op_b;
    logic          op_hw;
    logic          op_w;
    logic          op_dw;
    logic          ld_u;
  } rrv64_l1d_req_type_dec_t;

typedef struct packed {
    rrv64_mesi_type_e  mesi_sta;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
    logic [DATA_BURST_NUM-1:0]  data_dirty;
`endif
} rrv64_l1d_lst_req_t;

typedef struct packed {
    rrv64_mesi_type_e [L1D_BANK_WAY_NUM-1:0] mesi_sta;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
    logic [L1D_BANK_WAY_NUM-1:0][DATA_BURST_NUM-1:0]  data_dirty;
`endif
} rrv64_l1d_lst_t;

typedef struct packed {
  // stage 1
  logic [     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_req_rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_req_prd;
  // logic [      LDU_OP_WIDTH-1:0] ls_pipe_l1d_req_opcode;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_req_lsu_tag;
`endif

  logic [L1D_BANK_SET_INDEX_WIDTH-1:0] ls_pipe_l1d_req_idx;
  logic [L1D_BANK_OFFSET_WIDTH-1:0   ] ls_pipe_l1d_req_offset;
  logic [L1D_BANK_TAG_WIDTH-1:0      ] ls_pipe_l1d_req_vtag; // for ld gen ptag when idx+offset<12
  
  logic [ L1D_BANK_PADDR_TAG_WIDTH-1:0 ] ls_pipe_l1d_st_req_tag; // for st: st paddr tag; for ptw: ptw ld paddr tag
  logic [       L1D_STB_DATA_WIDTH-1:0 ] ls_pipe_l1d_st_req_dat;
  logic [     L1D_STB_DATA_WIDTH/8-1:0 ] ls_pipe_l1d_st_req_dat_byte_mask;
  
  rrv64_l1d_lst_t                    lst_dat; // mesi, cover valid & dirty bit
  // logic                              is_lsu_ld_req;
  rrv64_l1d_req_type_dec_t           req_type_dec;
  
  logic                              is_evict;
  logic                              is_writeback;
  logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] evict_way_idx;

  logic                              sc_rt_check_succ; // sc
} l1d_pipe_s1_t;

typedef struct packed {
  // stage 2
//  logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_PADDR_TAG_WIDTH-1:0]               tram_rdat;
//  logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM-1:0]  dram_rdat;
//  logic [L1D_BANK_WAY_NUM-1:0]                                    vram_rdat;
  logic [     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_req_rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_req_prd;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_req_lsu_tag;
`endif

  logic                                     tag_compare_hit;
  logic [L1D_BANK_WAY_NUM-1:0]              tag_compare_hit_per_way;
  logic [L1D_BANK_WAY_NUM-1:0]              tag_compare_data_hit_permission_miss_per_way; // for S->M, no need data, need write permission
  // logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]      tag_compare_hit_way_idx;
  logic                                     ld_tlb_hit;
  logic [L1D_BANK_LINE_DATA_SIZE-1:0]       line_data;  // 1. for ld req: lsu_ld_hit_dat; 2. for st req: ls_pipe_l1d_st_req_dat; 3. for amo req: 
  logic [XLEN-1:0]                          amo_st_data; // for amo rs2 data

  rrv64_l1d_req_type_dec_t           req_type_dec;
  logic                              is_evict;
  logic                              is_writeback;

  // logic [       PADDR_WIDTH-1:0 ]           ls_pipe_l1d_ld_req_paddr;
  logic [       L1D_BANK_PADDR_TAG_WIDTH-1:0] ls_pipe_l1d_req_tag;
  logic [L1D_BANK_SET_INDEX_WIDTH-1:0    ] ls_pipe_l1d_req_idx;
  logic [       L1D_BANK_OFFSET_WIDTH-1:0   ] ls_pipe_l1d_req_offset;

  // logic [       L1D_STB_DATA_WIDTH-1:0 ] ls_pipe_l1d_st_req_dat;
  logic [     L1D_STB_DATA_WIDTH/8-1:0 ] ls_pipe_l1d_st_req_dat_byte_mask;

  // rrv64_mesi_type_e                     lst_mesi_sta;

  // snoop
  rrv64_l1d_lst_t                   lst_dat; // mesi, cover valid & dirty bit

  logic                             sc_rt_check_succ; // sc
} l1d_pipe_s2_t;

typedef struct packed {
  // stage 1
  l1d_pipe_s1_t s1;
  // stage 2
  l1d_pipe_s2_t s2;
} l1d_pipe_reg_t;

// fencei flush fsm
typedef enum logic [2:0] {
  FLUSH_IDLE,
  FLUSH_PENDING,
  FLUSH_READ_LST,                 // read lst and judge whether need to read data ram
  FLUSH_READ_DATA_RAM_WRITE_LST,  // read data ram if needed, write lst if needed
  FLUSH_ENQUEUE_EVICT_QUEUE,      // put the dirty data into evict queue if needed
  FLUSH_WAIT_EVICT_QUEUE_CLEAN,   // wait for evict queue clear
  FLUSH_FINISH
} l1d_bank_fencei_flush_state_t;

typedef enum logic [2:0] {
  FENCEI_IDLE,
  FENCEI_WAITING_FOR_STB_HSK,
  FENCEI_WAITING_FOR_STB_DONE,
  FENCEI_REQ_TO_BANK,
  FENCEI_WAITING_FOR_BANK_GRANT,
  FENCEI_FINISH
} l1d_fencei_state_t;

// ------------------------------
// store buffer
// st req pipe
typedef struct packed {
    logic [          ROB_TAG_WIDTH-1:0] rob_tag;
    logic [         PREG_TAG_WIDTH-1:0] prd;
    logic [           STU_OP_WIDTH-1:0] opcode;
    logic [ L1D_STB_LINE_ADDR_SIZE-1:0] line_paddr;
    logic [     L1D_STB_DATA_WIDTH-1:0] line_data;
    logic [   L1D_STB_DATA_WIDTH/8-1:0] write_byte_mask;
`ifdef RUBY
    logic [     RRV64_LSU_ID_WIDTH-1:0] lsu_tag;
`endif
    // sc
    logic                               sc_rt_check_succ;
    logic [       L1D_OFFSET_WIDTH-1:0] amo_offset; // offset used for amo & lr
  } stb_entry_t;

typedef struct packed {
  // stage 1
  logic [     ROB_TAG_WIDTH-1:0]  rob_tag;
  logic [    PREG_TAG_WIDTH-1:0]  prd;
  logic [      STU_OP_WIDTH-1:0]  opcode;
  logic [       PADDR_WIDTH-1:0]  paddr;
  logic [              XLEN-1:0]  data;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH-1:0]  lsu_tag;
`endif
  
  logic                           stb_hit;
  logic [L1D_STB_ENTRY_NUM-1:0]   stb_hit_entry_mask; // equals to N_STB
  
  // ===== TODO: here only work for 2 input ports ======
  logic                           hit_the_same_cache_line;
  // ===================================================

  // sc
  logic                           sc_rt_check_succ;
} l1d_stb_st_pipe_s1_t;

typedef struct packed {
  // stage 1
  l1d_stb_st_pipe_s1_t s1;
} l1d_stb_st_pipe_reg_t;

// ld req pipe
typedef struct packed {
  // stage 1
  logic [     ROB_TAG_WIDTH-1:0] rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] prd;
  logic [      LDU_OP_WIDTH-1:0] opcode;
  logic                          is_ptw_ld;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif

  logic [L1D_TAG_WIDTH-1:0    ] vtag; // for ld gen ptag when idx+offset<12 // for ptw, it is ptag
  logic [L1D_INDEX_WIDTH-1:0  ] index;
  logic [L1D_OFFSET_WIDTH-1:0 ] offset;
} l1d_stb_ld_pipe_s1_t;

typedef struct packed {
  // stage 2
  logic [     ROB_TAG_WIDTH-1:0] rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] prd;
  logic [      LDU_OP_WIDTH-1:0] opcode;
  logic                          is_ptw_ld;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif
  logic [L1D_OFFSET_WIDTH-1:0 ] offset;

  logic                         stb_hit;
  logic [L1D_STB_ENTRY_NUM-1:0] stb_hit_per_entry; // equals to N_STB
} l1d_stb_ld_pipe_s2_t;

typedef struct packed {
  // stage 1
  l1d_stb_ld_pipe_s1_t s1;
  // stage 2
  l1d_stb_ld_pipe_s2_t s2;
} l1d_stb_ld_pipe_reg_t;

// eviction fsm
typedef enum logic [1:0] {
  IDLE,
  IN_AGE_EVICT,     // stb full; 
  SELECTED_EVICT,   // load partial hit; coherence snoop hit;
  FLUSH             // stb flush (evict all);
} l1d_stb_evict_state_t;

  //------------------------------------------------------
  // MSHR definition
  typedef enum logic [2:0] {
    MSHR_WAIT_WRITE_BACK,
    MSHR_WRITE_BACK,
    MSHR_WAIT_ALLOCATE
  } mshr_state_t;

  typedef struct packed {
    // logic                 valid;

//    tid_t                 tid; // transaction id to the cpu side
    logic [ROB_TAG_WIDTH-1:0]  rob_tag;
    logic [PREG_TAG_WIDTH-1:0] prd;
`ifdef RUBY
    logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif
    
    logic                       rw; // read or write miss
    logic                       flush;
    logic                       no_write_alloc;
    logic [L1D_BANK_PADDR_TAG_WIDTH-1:0]  new_tag; // read addr 
    logic [L1D_BANK_SET_INDEX_WIDTH-1:0]  bank_index; // bank index (index - bank_id)
    logic [L1D_BANK_OFFSET_WIDTH-1:0]     offset;
    
    logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] way_id; // way id // TODO: store after mshr read tag
    logic [L1D_STB_DATA_WIDTH-1:0]      data; // data to write (for write miss)
    logic [L1D_STB_DATA_WIDTH/8-1:0 ]   data_byte_mask;
    rrv64_l1d_req_type_dec_t    req_type_dec;
//    cpu_byte_mask_t       byte_mask; // data read/write mask

    // snoop
    rrv64_mesi_type_e             old_lst_state;

    // amo
    logic [XLEN-1:0]              amo_st_data;

    // only tag match, no state match result, for S -> M
    logic [L1D_BANK_WAY_NUM-1:0]  tag_compare_data_hit_permission_miss_per_way;
  } mshr_t;

  typedef struct packed {
    // axi bus status
    logic                   waddr;
    logic                   wdata;
  } mshr_mem_state_t;

  // wdata pipeline registers
  // typedef struct packed {
  //   // bank_index_t                            waddr;
  //   // mshr_id_t                               wid;
  //   //logic                                   flush;
  //   logic                                   wvalid;
  //   //logic                                   wlast;
  //   //logic [$clog2(N_WAY)-1:0]               way_id;
  // } wdata_pipe_t;

  typedef struct packed {
    // cache data write pipeline
    logic                                   wvalid;
    // wdata_pipe_t                            wdata_pipe;
    logic [$clog2(BURST_SIZE)-1:0]          wdata_offset;
    //mshr_mem_state_t [N_MSHR-1:0]           mem_state;
    //mem_offset_t rdata_offset;

    // data output pipeline
  //  cpu_resp_t  rdata_pipe;
    // logic       rdata_pipe_valid;
  } mem_fsm_reg_t;

  typedef struct packed {
    mshr_id_t id;
    logic     rw;
    logic     no_write_alloc;
    logic     flush;
    logic     valid;
  } mshr_req_t; // request interface pipeline registers


// ------ mlfb ------// 
  typedef struct packed {
    logic [L1D_BANK_SET_INDEX_WIDTH-1:0] set_idx;
    logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] way_idx;
} rrv64_l1d_evict_req_t;

  typedef struct packed {
    logic [L1D_BANK_PADDR_TAG_WIDTH-1:0]      tag;
    logic [L1D_BANK_LINE_DATA_SIZE-1:0]    dat;
    logic [L1D_STB_DATA_WIDTH/8-1:0 ]      dat_byte_mask;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
    logic [L1D_STB_DATA_WIDTH/8-1:0 ]      dat_dirty_byte_mask;
`endif

    logic [L1D_BANK_SET_INDEX_WIDTH-1:0]  set_idx;
    logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  way_idx;
    rrv64_mesi_type_e                mesi_sta;
    logic                            is_lr;
    logic                            is_ld;

    logic [L1D_BANK_OFFSET_WIDTH-1:0]         offset;
    logic [ROB_TAG_WIDTH-1:0]         rob_tag;
    logic [PREG_TAG_WIDTH-1:0]        prd;
`ifdef RUBY
    logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif
    rrv64_l1d_req_type_dec_t        req_type_dec;
    logic                             ld_no_resp;
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
    logic                             ld_no_refill; // for critical word first, no refill needed, only resp
`endif

    // amo
    logic [XLEN-1:0]              amo_st_data;
  } rrv64_l1d_refill_req_t;





typedef struct packed {
    logic                             valid;
    logic [N_MSHR_W -1:0]       mshr_idx;
    logic                             err;
    rrv64_mesi_type_e                 mesi_sta;

    logic [PADDR_WIDTH-1:0]           paddr;
    logic [ROB_TAG_WIDTH-1:0]         rob_tag;
    logic [PREG_TAG_WIDTH-1:0]        prd;
`ifdef RUBY
    logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif

    logic                             peek_done;
    logic                             check_done;
    logic                             evict_done;
    logic                             refill_done;
//    logic                             stb_dat_done;
    logic  [L1D_BANK_LINE_DATA_SIZE -1:0] line_dat;
    logic                                 line_dat_vld; // for CleanUnique, it may get dataless resp if the private cache still holds the clean line

    logic  [L1D_STB_DATA_WIDTH-1:0]       st_dat;
    logic  [L1D_STB_DATA_WIDTH/8-1:0 ]    st_dat_byte_mask;
//    logic                             is_st;
    rrv64_l1d_req_type_dec_t           req_type_dec;
//    logic  [RRV64_L1D_DATA_ECC_W* RRV64_L1D_WAY_N -1:0] dat_ecc_ckbit;
//    logic  [RRV64_L1D_TAG_ECC_W -1:0] tag_ecc_ckbit;
    logic  [L1D_BANK_WAY_INDEX_WIDTH -1:0] avail_way_idx;
    logic  [L1D_BANK_WAY_INDEX_WIDTH -1:0] victim_way_idx;
    logic                             victim_set_full;
    logic                             victim_way_clean;
//    logic  [RRV64_SCU_SST_IDX_W -1:0] sst_idx;
//    logic                             stb_alloc;
//    logic                             l2_hit;

    logic                             ld_no_resp;

`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
    logic                             ld_no_refill; // for critical word first, no refill needed, only resp
    logic                             has_another_part; // corner case, only critical part transfer, no valid data for rest part.
`endif
    // amo
    logic [XLEN-1:0]              amo_st_data;

    logic [SCU_TID_W-1:0]           scu_tid;  // scu mshr id in snp
    logic [SCU_SLICE_NUM_W-1:0]     scu_sid;  // scu slice id

    // only tag match, no state match result, for S -> M
    logic [L1D_BANK_WAY_NUM-1:0]  tag_compare_data_hit_permission_miss_per_way;

} rrv64_l1d_mlfb_head_buf_t;

typedef struct packed {
  logic [N_MSHR_W-1:0]             mshr_idx;
  logic                            err;
  rrv64_mesi_type_e                mesi_sta;
  logic [DATA_BURST_NUM-1:0][DATA_LENGTH_PER_PKG-1:0]   data;
  logic                            data_valid; // for CleanUnique, it may get dataless resp if the private cache still holds the clean line

`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
  logic                             critical_received_wait_for_common; // only when critical part received and need to wait for common part, the mlfb should resp the critical word first transaction, other condition only need common refill transaction
  logic                             common_received_wait_for_critical; // rare: common part comes ahead of critical part, wait for critical part and do common refill transaction
  logic                             critical_part_resp_done; // the critical part has been resp to core, no resp needed in common refill transaction
  logic                             has_another_part; // corner case, only critical part transfer, no valid data for rest part.
`endif

  logic [SCU_TID_W-1:0]           scu_tid;  // scu mshr id in snp
  logic [SCU_SLICE_NUM_W-1:0]     scu_sid;  // scu slice id

  // logic [RRV64_SCU_SST_IDX_W-1:0]  sst_idx;
//  logic                            l2_hit;
} rrv64_l1d_mlfb_t;

typedef struct packed {
  logic [PTW_ID_WIDTH-1:0]       id;
  logic [PADDR_WIDTH-1:0 ]       paddr;
} ptw_req_buffer_t;


// ------ snp ctrl ------//
/*
typedef enum logic [3:0] {
  ReadShared          = 4'b0000,
  ReadClean           = 4'b0001,
  ReadNotSharedDirty  = 4'b0010, // need support
  ReadUnique          = 4'b0111, // need support
  CleanShared         = 4'b1000,
  CleanInvalid        = 4'b1001, // need support
  MakeInvalid         = 4'b1101,
  DVM_Complete        = 4'b1110,
  DVM_Message         = 4'b1111
} ace_acsoop_type_e;
*/
typedef struct packed {
  logic [L1D_STB_LINE_ADDR_SIZE-1:0]   snp_line_addr;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
  logic [L1D_OFFSET_WIDTH-1:0]   snp_line_addr_offset;
  logic                          data_resp_with_critical_word_first; // if there is a data resp, resp data with critical word first (for SCU_MSHR snp)
`endif
  logic                     snp_leave_invalid;
  logic                     snp_leave_sharedclean;
  logic                     snp_return_clean_data;
  logic                     snp_return_dirty_data;
  scu_cc_snp_tid_t          id;
  } snp_req_buf_t;

typedef struct packed {
  snp_req_buf_t   snp_req;

  logic           s1_conflict_check_done;
  // logic         s1_dataless_resp_i; // SnpResp_I

  logic           s2_read_tag_lst_done;
  rrv64_l1d_lst_t s2_lst_dat; // line state per way, read from lst

  logic           s3_rd_data_wr_lst_done;
  logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  s3_tag_compare_match_id;
  logic           s3_data_resp;  // resp with data
  logic           s3_resp_inv;   // SnpAck_FoundI
  logic           s3_resp_sc;    // SnpAck_FoundSorE
  logic           s3_resp_pd;    // pass dirty
  logic           s3_was_unique;

  logic           s4_snp_resp_done;
  logic           cr_hsk_done;
  logic           cd_hsk_done;
  logic [L1D_BANK_LINE_DATA_SIZE-1:0] cd_data_hold; // if cd channel not hsk immediately, buffer the data
  } snp_req_head_buf_t;

typedef struct packed {
  logic                                            s1_st_req_tag_hit;      // s0_1
  logic                                            s2_st_req_tag_hit;      // s0_1
  logic                                            s1_valid;               // s0_2 pipeline s1 vld
  logic                                            s2_valid;               // s0_2 pipeline s2 vld
  l1d_pipe_reg_t                                   cur;                    // s0_2 pipeline
  logic  [L1D_BANK_PADDR_TAG_WIDTH-1:0]            s1_tag_used_to_compare; // s0_2 pipeline for vipt s1 ptag
  logic  [N_MSHR-1:0]                              mshr_bank_valid;        // s0_2 mshr vld
  logic  [N_MSHR-1:0]                              mshr_bank_sent;         // s0_2 mshr sent
  mshr_t [N_MSHR-1:0]                              mshr_bank;              // s0_2 mshr
  logic  [N_EWRQ-1:0]                              ewrq_vld;               // s0_2 ewrq
  logic  [N_EWRQ-1:0][L1D_BANK_LINE_ADDR_SIZE-1:0] ewrq_addr;              // s0_2 addr
} snp_l1d_bank_snp_s0_t;

typedef struct packed {
  rrv64_l1d_lst_t               lst_dat; // line state per way, read from lst
} snp_l1d_bank_snp_s1_t;

typedef struct packed {
  logic [L1D_BANK_WAY_NUM-1:0]  tag_compare_result_per_way;
} snp_l1d_bank_snp_s2_t;

endpackage
