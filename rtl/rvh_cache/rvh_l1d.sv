module rvh_l1d
  import rvh_pkg::*;
  import riscv_pkg::*;
  import uop_encoding_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_uncore_param_pkg::*;
`ifdef RUBY
    
`endif
#(
  parameter int CORE_ID = 0
)
(
    // LS Pipe -> D$ : Load request
    input  logic [LSU_ADDR_PIPE_COUNT-1:0]                         ls_pipe_l1d_ld_req_vld_i,
    input  logic [LSU_ADDR_PIPE_COUNT-1:0]                         ls_pipe_l1d_ld_req_io_i,
    input  logic [LSU_ADDR_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_rob_tag_i,
    input  logic [LSU_ADDR_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_prd_i,
    input  logic [LSU_ADDR_PIPE_COUNT-1:0][      LDU_OP_WIDTH-1:0] ls_pipe_l1d_ld_req_opcode_i,
`ifdef RUBY
    input  logic [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] ls_pipe_l1d_ld_req_lsu_tag_i,
`endif

    input  logic [LSU_ADDR_PIPE_COUNT-1:0][       L1D_INDEX_WIDTH-1:0] ls_pipe_l1d_ld_req_index_i, //
    input  logic [LSU_ADDR_PIPE_COUNT-1:0][      L1D_OFFSET_WIDTH-1:0] ls_pipe_l1d_ld_req_offset_i, //
    input  logic [LSU_ADDR_PIPE_COUNT-1:0][     L1D_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_vtag_i, // vtag
    output logic [LSU_ADDR_PIPE_COUNT-1:0]                         ls_pipe_l1d_ld_req_rdy_o,
`ifdef RUBY
    output logic [LSU_ADDR_PIPE_COUNT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0] ls_pipe_l1d_ld_req_hit_bank_id_o,
    output logic [LSU_DATA_PIPE_COUNT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0] ls_pipe_l1d_st_req_hit_bank_id_o,
`endif
    // LS Pipe -> D$ : DTLB response
    input  logic [LSU_ADDR_PIPE_COUNT-1:0]                         ls_pipe_l1d_dtlb_resp_vld_i,
    input  logic [LSU_ADDR_PIPE_COUNT-1:0][         PPN_WIDTH-1:0] ls_pipe_l1d_dtlb_resp_ppn_i,
    input  logic [LSU_ADDR_PIPE_COUNT-1:0]                         ls_pipe_l1d_dtlb_resp_excp_vld_i,
    input  logic [LSU_ADDR_PIPE_COUNT-1:0]                         ls_pipe_l1d_dtlb_resp_hit_i,
    input  logic [LSU_ADDR_PIPE_COUNT-1:0]                         ls_pipe_l1d_dtlb_resp_miss_i,
    // LS Pipe -> D$ : Store request
    input  logic [LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_vld_i,
    input  logic [LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_io_i,
    input  logic [LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_is_fence_i,
    input  logic [LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_rob_tag_i,
    input  logic [LSU_DATA_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_prd_i,
    input  logic [LSU_DATA_PIPE_COUNT-1:0][      STU_OP_WIDTH-1:0] ls_pipe_l1d_st_req_opcode_i,
`ifdef RUBY
    input  logic [LSU_DATA_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] ls_pipe_l1d_st_req_lsu_tag_i,
`endif
    // input  logic [LSU_DATA_PIPE_COUNT-1:0][   L1D_INDEX_WIDTH-1:0] ls_pipe_l1d_st_req_index_i,
    // input  logic [LSU_DATA_PIPE_COUNT-1:0][     L1D_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_tag_i,
    input  logic [LSU_DATA_PIPE_COUNT-1:0][       PADDR_WIDTH-1:0] ls_pipe_l1d_st_req_paddr_i, //
    input  logic [LSU_DATA_PIPE_COUNT-1:0][              XLEN-1:0] ls_pipe_l1d_st_req_data_i,
    output logic [LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_rdy_o,
    
`ifdef RUBY
    output logic [LSU_DATA_PIPE_COUNT-1:0]                         l1d_lsu_st_lsu_tag_vld_per_input_port_o,
    output logic [LSU_DATA_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] l1d_lsu_st_lsu_tag_per_input_port_o,
    input  logic [LSU_DATA_PIPE_COUNT-1:0]                         l1d_lsu_st_lsu_tag_rdy_per_input_port_i,
`endif
    
    // L1D -> LS Pipe ld replay: 1. mshr full or 2. stb partial hit 
    output logic [LSU_ADDR_PIPE_COUNT-1:0]                         l1d_ls_pipe_ld_replay_valid_o,
`ifdef RUBY
    output logic [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] l1d_ls_pipe_replay_lsu_tag_o,
`endif

    // LS Pipe -> L1D : Kill D-Cache Response
    input  logic [LSU_ADDR_PIPE_COUNT-1:0]                         ls_pipe_l1d_kill_resp_i,
    // D$ -> ROB : Write Back
    output logic [LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0]                         l1d_rob_wb_vld_o,
    output logic [LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] l1d_rob_wb_rob_tag_o,
    // D$ -> Int PRF : Write Back
    output logic [LSU_ADDR_PIPE_COUNT-1:0]                         l1d_int_prf_wb_vld_o,
    output logic [LSU_ADDR_PIPE_COUNT-1:0][INT_PREG_TAG_WIDTH-1:0] l1d_int_prf_wb_tag_o,
    output logic [LSU_ADDR_PIPE_COUNT-1:0][              XLEN-1:0] l1d_int_prf_wb_data_o,
`ifdef RUBY
    output logic [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] l1d_lsu_lsu_tag_o,
`endif

    // ptw walk request port
    input  logic                          ptw_walk_req_vld_i,
    input  logic [      PTW_ID_WIDTH-1:0] ptw_walk_req_id_i,
    input  logic [       PADDR_WIDTH-1:0] ptw_walk_req_addr_i,
    output logic                          ptw_walk_req_rdy_o,
    // ptw walk response port
    output logic                          ptw_walk_resp_vld_o,
    output logic [      PTW_ID_WIDTH-1:0] ptw_walk_resp_id_o,
    output logic [         PTE_WIDTH-1:0] ptw_walk_resp_pte_o,
    input  logic                          ptw_walk_resp_rdy_i,

    // cache tx port, private cache -> scu
      // req
    output logic                        pc_scu_req_vld_o,
    output cache_scu_cc_req_t           pc_scu_req_o,
    input  logic                        pc_scu_req_rdy_i,
  
      // resp
    output logic                        pc_scu_resp_vld_o,
    output cache_scu_cc_resp_t          pc_scu_resp_o,
    input  logic                        pc_scu_resp_rdy_i,
  
      // evict/wb
    output logic                        pc_scu_evict_vld_o,
    output cache_scu_cc_req_t           pc_scu_evict_o,
    input  logic                        pc_scu_evict_rdy_i,
  
      // data
    output logic                        pc_scu_data_vld_o,
    output cache_scu_cc_data_t          pc_scu_data_o,
    input  logic                        pc_scu_data_rdy_i,
  
    // cache rx port, scu -> private cache
      // resp
    input  logic                        scu_pc_resp_vld_i,
    input  cache_scu_cc_resp_t          scu_pc_resp_i,
    output logic                        scu_pc_resp_rdy_o,
  
      // snp
    input  logic                        scu_pc_snp_vld_i,
    input  cache_scu_cc_snp_t           scu_pc_snp_i,
    output logic                        scu_pc_snp_rdy_o,
  
      // data
    input  logic                        scu_pc_data_vld_i,
    input  cache_scu_cc_data_t          scu_pc_data_i,
    output logic                        scu_pc_data_rdy_o,

    output logic [L1D_BANK_ID_NUM-1:0]  snp_req_head_buf_valid_clr_o,

    input logic rob_flush_i,

    input  logic fencei_flush_vld_i,
    output logic fencei_flush_grant_o,

    input clk,
    input rst
);

genvar i, j, k;

// amo
logic                         in_amo_state;

// fencei
l1d_fencei_state_t            l1d_fencei_state_d, l1d_fencei_state_q;
logic                         l1d_fencei_state_d_ena;
logic [L1D_BANK_ID_NUM-1:0]   fencei_flush_grant_per_bank_out, fencei_flush_grant_per_bank_d, fencei_flush_grant_per_bank_q;
logic [L1D_BANK_ID_NUM-1:0]   fencei_flush_grant_per_bank_d_ena;
logic                         in_fencei_flush;

logic fencei_flush_stb_vld;
logic fencei_flush_stb_rdy;
logic fencei_flush_stb_done;

logic fencei_flush_bank_vld;

  // if fencei valid comes but not all banks are fencei ready, mask all req valid to cache bank, as well as the fencei valid, until all banks are fencei ready and the fencei is taken
logic [LSU_ADDR_PIPE_COUNT-1:0] ls_pipe_l1d_ld_req_vld_masked;
logic [LSU_ADDR_PIPE_COUNT-1:0] ls_pipe_l1d_ld_req_rdy_unmasked;
logic [LSU_DATA_PIPE_COUNT-1:0] ls_pipe_l1d_st_req_vld_masked;
logic [LSU_DATA_PIPE_COUNT-1:0] ls_pipe_l1d_st_req_rdy_unmasked;
logic                           ptw_walk_req_vld_masked;
logic                           ptw_walk_req_rdy_unmasked;

assign ls_pipe_l1d_ld_req_vld_masked  = ls_pipe_l1d_ld_req_vld_i & ~{LSU_ADDR_PIPE_COUNT{in_fencei_flush}} & ~{LSU_ADDR_PIPE_COUNT{in_amo_state}};
assign ls_pipe_l1d_ld_req_rdy_o       = ls_pipe_l1d_ld_req_rdy_unmasked & ~{LSU_ADDR_PIPE_COUNT{in_fencei_flush}} & ~{LSU_ADDR_PIPE_COUNT{in_amo_state}};

assign ls_pipe_l1d_st_req_vld_masked  = ls_pipe_l1d_st_req_vld_i & ~{LSU_DATA_PIPE_COUNT{in_fencei_flush}};
assign ls_pipe_l1d_st_req_rdy_o       = ls_pipe_l1d_st_req_rdy_unmasked & ~{LSU_DATA_PIPE_COUNT{in_fencei_flush}};

assign ptw_walk_req_vld_masked        = ptw_walk_req_vld_i & ~in_fencei_flush;
assign ptw_walk_req_rdy_o             = ptw_walk_req_rdy_unmasked & ~in_fencei_flush;


  // fencei fsm
always_comb begin: case_l1d_fencei_state_d
  l1d_fencei_state_d = FENCEI_IDLE;
  l1d_fencei_state_d_ena = 1'b0;

  fencei_flush_stb_vld = '0;
  fencei_flush_bank_vld = '0;

  fencei_flush_grant_per_bank_d_ena = '0;
  fencei_flush_grant_per_bank_d     = fencei_flush_grant_per_bank_out;
  fencei_flush_grant_o              = '0;

  case(l1d_fencei_state_q)
    FENCEI_IDLE: begin
      fencei_flush_stb_vld = fencei_flush_vld_i;
      if(fencei_flush_vld_i & fencei_flush_stb_rdy) begin // fencei stb hsk success
        l1d_fencei_state_d     = FENCEI_WAITING_FOR_STB_DONE;
        l1d_fencei_state_d_ena = 1'b1;
      end else if(fencei_flush_vld_i) begin // fencei stb hsk failed
        l1d_fencei_state_d     = FENCEI_WAITING_FOR_STB_HSK;
        l1d_fencei_state_d_ena = 1'b1;
      end
    end
    FENCEI_WAITING_FOR_STB_HSK: begin
      fencei_flush_stb_vld = 1'b1;
      if(fencei_flush_stb_rdy) begin // hsk success
        l1d_fencei_state_d     = FENCEI_WAITING_FOR_STB_DONE;
        l1d_fencei_state_d_ena = 1'b1;
      end else begin
        l1d_fencei_state_d     = FENCEI_WAITING_FOR_STB_HSK;
        l1d_fencei_state_d_ena = 1'b0;
      end
    end
    FENCEI_WAITING_FOR_STB_DONE: begin
      if(fencei_flush_stb_done) begin // stb fencei flush done
        l1d_fencei_state_d     = FENCEI_REQ_TO_BANK;
        l1d_fencei_state_d_ena = 1'b1;
      end else begin
        l1d_fencei_state_d     = FENCEI_WAITING_FOR_STB_DONE;
        l1d_fencei_state_d_ena = 1'b0;
      end
    end
    FENCEI_REQ_TO_BANK: begin
      fencei_flush_bank_vld  = 1'b1;
      l1d_fencei_state_d     = FENCEI_WAITING_FOR_BANK_GRANT;
      l1d_fencei_state_d_ena = 1'b1;
    end
    FENCEI_WAITING_FOR_BANK_GRANT: begin
      fencei_flush_grant_per_bank_d_ena = ~fencei_flush_grant_per_bank_q & fencei_flush_grant_per_bank_d;
      if((&fencei_flush_grant_per_bank_q) == 1'b1) begin // all bank frant collected
        l1d_fencei_state_d     = FENCEI_FINISH;
        l1d_fencei_state_d_ena = 1'b1;
      end
    end
    FENCEI_FINISH: begin
      fencei_flush_grant_o = 1'b1;

      fencei_flush_grant_per_bank_d = '0;
      fencei_flush_grant_per_bank_d_ena = '1;
      
      l1d_fencei_state_d     = FENCEI_IDLE;
      l1d_fencei_state_d_ena = 1'b1;
    end
    default: begin
      l1d_fencei_state_d     = FENCEI_IDLE;
      l1d_fencei_state_d_ena = 1'b1;
    end
  endcase
end

assign in_fencei_flush = (l1d_fencei_state_q != FENCEI_IDLE);

std_dffrve
#(.WIDTH($bits(l1d_fencei_state_t)))
U_FENCEI_STATE_REG
(
  .clk(clk),
  .rstn(rst),
  .rst_val(FENCEI_IDLE),
  .en(l1d_fencei_state_d_ena),
  .d(l1d_fencei_state_d),
  .q(l1d_fencei_state_q)
);
generate
  for(i = 0; i < L1D_BANK_ID_NUM; i++) begin: gen_fencei_flush_grant_per_bank_q
    std_dffre
    #(.WIDTH(1)) 
    U_FENCEI_FLUSH_GRANT_PER_BANK_REG
    (
      .clk(clk),
      .rstn(rst),
      .en(fencei_flush_grant_per_bank_d_ena[i]),
      .d(fencei_flush_grant_per_bank_d[i]),
      .q(fencei_flush_grant_per_bank_q[i])
      );
  end
endgenerate


// l1d arb -> l1d banks
  // LS_PIPE -> D$ : LD Request
logic [L1D_BANK_ID_NUM-1:0]                          l1d_arb_bank_ld_req_vld;                                      
logic [L1D_BANK_ID_NUM-1:0][ ROB_TAG_WIDTH-1:0]      l1d_arb_bank_ld_req_rob_tag;                                  
logic [L1D_BANK_ID_NUM-1:0][PREG_TAG_WIDTH-1:0]      l1d_arb_bank_ld_req_prd;                                      
logic [L1D_BANK_ID_NUM-1:0][  LDU_OP_WIDTH-1:0]      l1d_arb_bank_ld_req_opcode;                                   
`ifdef RUBY                                                                                           
logic [L1D_BANK_ID_NUM-1:0][RRV64_LSU_ID_WIDTH -1:0] l1d_arb_bank_ld_req_lsu_tag;                                  
`endif                                                                                               
                                                                                                          
logic [L1D_BANK_ID_NUM-1:0][L1D_BANK_SET_INDEX_WIDTH-1:0]   l1d_arb_bank_ld_req_idx;                                      
logic [L1D_BANK_ID_NUM-1:0][L1D_BANK_OFFSET_WIDTH-1:0]      l1d_arb_bank_ld_req_offset; 
logic [L1D_BANK_ID_NUM-1:0][L1D_BANK_TAG_WIDTH-1:0]         l1d_arb_bank_ld_req_vtag;

                                                                                                          
logic [L1D_BANK_ID_NUM-1:0]                          l1d_arb_bank_stb_ld_req_rdy;                                     
logic [L1D_BANK_ID_NUM-1:0]                          l1d_arb_bank_ld_req_rdy;                                     

  // DTLB -> D$                                                                                           
logic [L1D_BANK_ID_NUM-1:0]                         l1d_arb_bank_dtlb_resp_vld;                              
logic [L1D_BANK_ID_NUM-1:0]                         l1d_arb_bank_dtlb_resp_excp_vld; // s1 kill              
logic [L1D_BANK_ID_NUM-1:0]                         l1d_arb_bank_dtlb_resp_hit;      // s1 kill              
logic [L1D_BANK_ID_NUM-1:0][     PPN_WIDTH-1:0]     l1d_arb_bank_dtlb_resp_ppn; // VIPT, get at s1 if tlb hit
logic [L1D_BANK_ID_NUM-1:0]                         l1d_arb_bank_dtlb_resp_rdy;                              

  // LS_PIPE -> D$ : ST Request                                                                                   
logic [L1D_BANK_ID_NUM-1:0]                          l1d_arb_bank_st_req_vld;                                      
logic [L1D_BANK_ID_NUM-1:0]                          l1d_arb_bank_st_req_io_region;                                
logic [L1D_BANK_ID_NUM-1:0][     ROB_TAG_WIDTH-1:0]  l1d_arb_bank_st_req_rob_tag;                                  
logic [L1D_BANK_ID_NUM-1:0][    PREG_TAG_WIDTH-1:0]  l1d_arb_bank_st_req_prd;                                      
logic [L1D_BANK_ID_NUM-1:0][      STU_OP_WIDTH-1:0]  l1d_arb_bank_st_req_opcode;                                   
`ifdef RUBY 
logic [L1D_BANK_ID_NUM-1:0][RRV64_LSU_ID_WIDTH -1:0] l1d_arb_bank_st_req_lsu_tag;                                  
`endif

logic [L1D_BANK_ID_NUM-1:0][       PADDR_WIDTH-1:0]  l1d_arb_bank_st_req_paddr;                                    
logic [L1D_BANK_ID_NUM-1:0][  L1D_STB_DATA_WIDTH  -1:0]  l1d_arb_bank_st_req_data; // data from stb                    
logic [L1D_BANK_ID_NUM-1:0][  L1D_STB_DATA_WIDTH/8-1:0]  l1d_arb_bank_st_req_data_byte_mask; // data byte mask from stb
logic [L1D_BANK_ID_NUM-1:0]                              l1d_arb_bank_st_req_sc_rt_check_succ; // sc
logic [L1D_BANK_ID_NUM-1:0][      L1D_OFFSET_WIDTH-1:0]  l1d_arb_bank_st_req_sc_amo_offset;

logic [L1D_BANK_ID_NUM-1:0]                          l1d_arb_bank_st_req_rdy;                                    

// D$ -> LSQ ld replay: 1. mshr full or 2. stb partial hit 
logic [L1D_BANK_ID_NUM-1:0]                          bank_l1d_replay_vld;
logic [L1D_BANK_ID_NUM-1:0]                          bank_l1d_mshr_full;
`ifdef RUBY
logic [L1D_BANK_ID_NUM-1:0][RRV64_LSU_ID_WIDTH-1:0]  bank_l1d_replay_lsu_tag;
`endif

// MMU PTW LD -> D$ bank req
logic [L1D_BANK_ID_NUM-1:0]                          l1d_arb_bank_ptw_walk_req_vld;                                      
logic [L1D_BANK_ID_NUM-1:0][      PTW_ID_WIDTH-1:0]  l1d_arb_bank_ptw_walk_req_id;                                      
logic [L1D_BANK_ID_NUM-1:0][       PADDR_WIDTH-1:0]  l1d_arb_bank_ptw_walk_req_paddr;                                   
logic [L1D_BANK_ID_NUM-1:0]                          l1d_arb_bank_ptw_walk_req_rdy;

logic                                                l1d_arb_stb_ptw_walk_req_rdy;

// PTW REPLAY BUFFER LD -> D$ bank req
logic                           ptw_replay_bank_ptw_walk_req_vld;                                      
logic [      PTW_ID_WIDTH-1:0]  ptw_replay_bank_ptw_walk_req_id;                                      
logic [       PADDR_WIDTH-1:0]  ptw_replay_bank_ptw_walk_req_paddr;                                   
logic                           ptw_replay_bank_ptw_walk_req_rdy;

// D$ bank -> MMU PTW LD resp 
logic [L1D_BANK_ID_NUM-1:0]                          band_l1d_arb_ptw_walk_resp_vld;
logic [L1D_BANK_ID_NUM-1:0][      PTW_ID_WIDTH-1:0]  band_l1d_arb_ptw_walk_resp_id ;
logic [L1D_BANK_ID_NUM-1:0][         PTE_WIDTH-1:0]  band_l1d_arb_ptw_walk_resp_pte;
// logic [L1D_BANK_ID_NUM-1:0]                          band_l1d_arb_ptw_walk_resp_rdy;


// L1D banks -> cc arb
  // private cache -> scu
    // req
logic               [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_req_vld;
cache_scu_cc_req_t  [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_req;
logic               [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_req_rdy;

    // resp
logic               [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_resp_vld;
cache_scu_cc_resp_t [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_resp;
logic               [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_resp_rdy;

    // evict/wb
logic               [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_evict_vld;
cache_scu_cc_req_t  [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_evict;
logic               [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_evict_rdy;

    // data
logic               [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_data_vld;
cache_scu_cc_data_t [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_data;
logic               [L1D_BANK_ID_NUM-1:0]  pc_cc_arb_data_rdy;

  // scu -> private cache
    // resp
logic               [L1D_BANK_ID_NUM-1:0]  cc_arb_pc_resp_vld;
cache_scu_cc_resp_t [L1D_BANK_ID_NUM-1:0]  cc_arb_pc_resp;
logic               [L1D_BANK_ID_NUM-1:0]  cc_arb_pc_resp_rdy;

    // snp
logic               [L1D_BANK_ID_NUM-1:0]  cc_arb_pc_snp_vld;
cache_scu_cc_snp_t  [L1D_BANK_ID_NUM-1:0]  cc_arb_pc_snp;
logic               [L1D_BANK_ID_NUM-1:0]  cc_arb_pc_snp_rdy;

    // data
logic               [L1D_BANK_ID_NUM-1:0]  cc_arb_pc_data_vld;
cache_scu_cc_data_t [L1D_BANK_ID_NUM-1:0]  cc_arb_pc_data;
logic               [L1D_BANK_ID_NUM-1:0]  cc_arb_pc_data_rdy;


// arbiter for resp and snp output, priority snp > bank
  // private cache -> scu
    // resp
logic               [L1D_BANK_ID_NUM-1:0]  l1d_bank_cc_arb_resp_vld;
cache_scu_cc_resp_t [L1D_BANK_ID_NUM-1:0]  l1d_bank_cc_arb_resp;
logic               [L1D_BANK_ID_NUM-1:0]  l1d_bank_cc_arb_resp_rdy;
  // data
logic               [L1D_BANK_ID_NUM-1:0]  l1d_bank_cc_arb_data_vld;
cache_scu_cc_data_t [L1D_BANK_ID_NUM-1:0]  l1d_bank_cc_arb_data;
logic               [L1D_BANK_ID_NUM-1:0]  l1d_bank_cc_arb_data_rdy;

  // private cache -> scu
  // resp
logic               [L1D_BANK_ID_NUM-1:0]  l1d_snp_cc_arb_resp_vld;
cache_scu_cc_resp_t [L1D_BANK_ID_NUM-1:0]  l1d_snp_cc_arb_resp;
logic               [L1D_BANK_ID_NUM-1:0]  l1d_snp_cc_arb_resp_rdy;
  // data
logic               [L1D_BANK_ID_NUM-1:0]  l1d_snp_cc_arb_data_vld;
cache_scu_cc_data_t [L1D_BANK_ID_NUM-1:0]  l1d_snp_cc_arb_data;
logic               [L1D_BANK_ID_NUM-1:0]  l1d_snp_cc_arb_data_rdy;

generate
  for(i = 0; i < L1D_BANK_ID_NUM; i++) begin: gen_pc_cc_arb_resp
    assign pc_cc_arb_resp_vld [i] = l1d_snp_cc_arb_resp_vld[i] | l1d_bank_cc_arb_resp_vld[i];
    assign pc_cc_arb_resp     [i] = l1d_snp_cc_arb_resp_vld[i] ? l1d_snp_cc_arb_resp[i] : l1d_bank_cc_arb_resp[i];
    assign l1d_snp_cc_arb_resp_rdy [i] = pc_cc_arb_resp_rdy[i];
    assign l1d_bank_cc_arb_resp_rdy[i] = pc_cc_arb_resp_rdy[i] & ~l1d_snp_cc_arb_resp_vld[i];
  end
endgenerate


generate
  for(i = 0; i < L1D_BANK_ID_NUM; i++) begin: gen_pc_cc_arb_data
    assign pc_cc_arb_data_vld [i] = l1d_snp_cc_arb_data_vld[i] | l1d_bank_cc_arb_data_vld[i];
    assign pc_cc_arb_data     [i] = l1d_snp_cc_arb_data_vld[i] ? l1d_snp_cc_arb_data[i] : l1d_bank_cc_arb_data[i];
    assign l1d_snp_cc_arb_data_rdy [i] = pc_cc_arb_data_rdy[i];
    assign l1d_bank_cc_arb_data_rdy[i] = pc_cc_arb_data_rdy[i] & ~l1d_snp_cc_arb_data_vld[i];
  end
endgenerate


// D$ -> ROB : Write Back
logic [L1D_BANK_ID_NUM-1:0]                         l1d_rob_wb_vld;
logic [L1D_BANK_ID_NUM-1:0][     ROB_TAG_WIDTH-1:0] l1d_rob_wb_rob_tag;

// D$ -> Int PRF : Write Back
logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_l1d_wb_vld;
logic [L1D_BANK_ID_NUM-1:0][INT_PREG_TAG_WIDTH-1:0]  l1d_bank_l1d_wb_tag;
logic [L1D_BANK_ID_NUM-1:0][              XLEN-1:0]  l1d_bank_l1d_wb_data;
logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_l1d_wb_vld_from_mlfb;
logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_l1d_wb_rdy_from_mlfb;
`ifdef RUBY
logic [L1D_BANK_ID_NUM-1:0][RRV64_LSU_ID_WIDTH-1:0]  l1d_bank_l1d_lsu_tag;
`endif

// snp ctrl <-> l1d bank intf
snp_req_head_buf_t   [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_req;
// s0 req
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s0_req_vld; // vld for: all_1
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s0_req_hsk;
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s0_turn_down_refill_ready_vld; // all_2
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s0_req_rdy;
snp_l1d_bank_snp_s0_t[L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s0;
// s1 req
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s1_req_vld; // vld for: all_1
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s1_req_hsk; // hsk for: s1_1
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s1_req_rdy;
snp_l1d_bank_snp_s1_t[L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s1;
// s2 req
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s2_req_vld; // vld for: all_1
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s2_req_hsk; // hsk for: s2_3
rrv64_mesi_type_e    [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s2_req_new_line_state;
logic                [L1D_BANK_ID_NUM-1:0][L1D_BANK_WAY_INDEX_WIDTH-1:0]  snp_l1d_bank_snp_s2_req_way_id;
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s2_req_data_ram_rd_vld; // vld for: s2_2
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s2_req_rdy;
snp_l1d_bank_snp_s2_t[L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s2;
// s3 req
logic                [L1D_BANK_ID_NUM-1:0]  snp_l1d_bank_snp_s3_req_vld; // vld for: all_1
logic                [L1D_BANK_ID_NUM-1:0][L1D_BANK_WAY_INDEX_WIDTH-1:0] snp_l1d_bank_snp_s3_tag_compare_match_id;
logic                [L1D_BANK_ID_NUM-1:0][L1D_BANK_LINE_DATA_SIZE-1:0] snp_l1d_bank_snp_s3_req_line_data;




// l1d arb & l1d stb -> lsu
  // ld req ready
logic [LSU_ADDR_PIPE_COUNT-1:0]                      ls_pipe_stb_ld_req_rdy;
logic [LSU_ADDR_PIPE_COUNT-1:0]                      ls_pipe_l1d_bank_ld_req_rdy;

generate
  for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin: gen_ls_pipe_l1d_ld_req_rdy_o
    assign ls_pipe_l1d_ld_req_rdy_unmasked[i] = ls_pipe_stb_ld_req_rdy[i] & ls_pipe_l1d_bank_ld_req_rdy[i];
  end
endgenerate

// l1d stb -> l1d arb: stb store req
    // STB -> D$ Pipeline : ST Request
logic                           stb_l1d_arb_st_req_vld;
logic [     ROB_TAG_WIDTH-1:0]  stb_l1d_arb_st_req_rob_tag;
logic [    PREG_TAG_WIDTH-1:0]  stb_l1d_arb_st_req_prd;
logic [      STU_OP_WIDTH-1:0]  stb_l1d_arb_st_req_opcode;
logic [       PADDR_WIDTH-1:0]  stb_l1d_arb_st_req_paddr;
logic [L1D_STB_DATA_WIDTH-1:0]  stb_l1d_arb_st_req_data;
logic [L1D_STB_DATA_WIDTH/8-1:0]  stb_l1d_arb_st_req_data_byte_mask;
`ifdef RUBY
logic [RRV64_LSU_ID_WIDTH-1:0]  stb_l1d_arb_st_req_lsu_tag;
`endif
logic                           stb_l1d_arb_st_req_sc_rt_check_succ;
logic [   L1D_OFFSET_WIDTH-1:0] stb_l1d_arb_st_req_amo_offset;
logic                           stb_l1d_arb_st_req_rdy;

  // D$ -> ROB : Write Back, choose from stb resp and l1d bank resp
logic [LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0]                         stb_rob_wb_vld;
logic [LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] stb_rob_wb_rob_tag;
  // D$ -> Int PRF : Write Back, choose from stb resp and l1d bank resp
logic [LSU_ADDR_PIPE_COUNT-1:0]                         stb_int_prf_wb_vld;
logic [LSU_ADDR_PIPE_COUNT-1:0][INT_PREG_TAG_WIDTH-1:0] stb_int_prf_wb_tag;
logic [LSU_ADDR_PIPE_COUNT-1:0][              XLEN-1:0] stb_int_prf_wb_data;
logic [LSU_ADDR_PIPE_COUNT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] stb_l1d_arb_bank_id;
`ifdef RUBY
logic [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] stb_lsu_lsu_tag;
`endif

logic [LSU_ADDR_PIPE_COUNT-1:0]                       stb_l1d_ld_replay_vld;
logic                                                 stb_l1d_ptw_replay_vld;


logic [LSU_ADDR_PIPE_COUNT-1:0][L1D_BANK_ID_NUM-1:0]            stb_l1d_arb_bank_id_mask;

logic [LSU_ADDR_PIPE_COUNT-1:0][L1D_BANK_ID_NUM-1:0]            stb_l1d_bank_ld_bypass_valid_per_ld_pipe;
logic [LSU_ADDR_PIPE_COUNT-1:0][L1D_BANK_ID_NUM-1:0][XLEN-1:0]  stb_l1d_bank_ld_bypass_data_per_ld_pipe;
logic [LSU_ADDR_PIPE_COUNT-1:0][L1D_BANK_ID_NUM-1:0]            stb_l1d_bank_ld_replay_vld_per_ld_pipe;

logic [L1D_BANK_ID_NUM-1:0]                                     stb_l1d_bank_ld_bypass_valid;
logic [L1D_BANK_ID_NUM-1:0][XLEN-1:0]                           stb_l1d_bank_ld_bypass_data;
logic [L1D_BANK_ID_NUM-1:0]                                     stb_l1d_bank_ld_replay_vld;

// stb load bypass -> l1d bank
always_comb begin: comb_stb_l1d_arb_bank_id_mask
  stb_l1d_arb_bank_id_mask = '0;
  for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
    for(int j = 0; j < L1D_BANK_ID_NUM; j++) begin
      if(stb_l1d_arb_bank_id[i] == j[L1D_BANK_ID_INDEX_WIDTH-1:0]) begin
        stb_l1d_arb_bank_id_mask[i][j] = 1'b1;
      end
    end
  end
end

generate
  for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin: gen_stb_l1d_bank_ld_bypass_valid_per_bank
    for(j = 0; j < L1D_BANK_ID_NUM; j++) begin
      assign stb_l1d_bank_ld_bypass_valid_per_ld_pipe[i][j] = stb_l1d_arb_bank_id_mask[i][j] & stb_int_prf_wb_vld[i];
      assign stb_l1d_bank_ld_replay_vld_per_ld_pipe  [i][j] = stb_l1d_arb_bank_id_mask[i][j] & stb_l1d_ld_replay_vld[i];
    end
  end
endgenerate

generate
  for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin: gen_stb_l1d_bank_ld_bypass_data_per_bank
    for(j = 0; j < L1D_BANK_ID_NUM; j++) begin
      for(k = 0; k < XLEN; k++) begin
        assign stb_l1d_bank_ld_bypass_data_per_ld_pipe[i][j][k] = stb_l1d_arb_bank_id_mask[i][j] & stb_int_prf_wb_data[i][k] & stb_int_prf_wb_vld[i];
      end
    end
  end
endgenerate

    // ===== TODO: here only work for 2 input ports ======
assign stb_l1d_bank_ld_bypass_valid = stb_l1d_bank_ld_bypass_valid_per_ld_pipe[0] | stb_l1d_bank_ld_bypass_valid_per_ld_pipe[1];
assign stb_l1d_bank_ld_bypass_data  = stb_l1d_bank_ld_bypass_data_per_ld_pipe[0]  | stb_l1d_bank_ld_bypass_data_per_ld_pipe[1];
assign stb_l1d_bank_ld_replay_vld   = stb_l1d_bank_ld_replay_vld_per_ld_pipe[0] | stb_l1d_bank_ld_replay_vld_per_ld_pipe[1];

    // ===================================================

// stb store req -> l1d bank
always_comb begin
  l1d_arb_bank_st_req_vld = '0;
  stb_l1d_arb_st_req_rdy  = '1;

  l1d_arb_bank_st_req_io_region = '0;
  l1d_arb_bank_st_req_rob_tag   = '0;
  l1d_arb_bank_st_req_prd       = '0;
  l1d_arb_bank_st_req_opcode    = '0;
  l1d_arb_bank_st_req_paddr     = '0;
  l1d_arb_bank_st_req_data      = '0;
  l1d_arb_bank_st_req_data_byte_mask = '0;
  l1d_arb_bank_st_req_sc_rt_check_succ = '0;
  l1d_arb_bank_st_req_sc_amo_offset = '0;

  for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
    if(stb_l1d_arb_st_req_paddr[L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_OFFSET_WIDTH] == i[L1D_BANK_ID_INDEX_WIDTH-1:0]) begin
      l1d_arb_bank_st_req_vld             [i] = stb_l1d_arb_st_req_vld;
      l1d_arb_bank_st_req_io_region       [i] = 1'b0; // TODO: 
      l1d_arb_bank_st_req_rob_tag         [i] = stb_l1d_arb_st_req_rob_tag;
      l1d_arb_bank_st_req_prd             [i] = stb_l1d_arb_st_req_prd;
      l1d_arb_bank_st_req_opcode          [i] = stb_l1d_arb_st_req_opcode;
`ifdef RUBY
      l1d_arb_bank_st_req_lsu_tag         [i] = stb_l1d_arb_st_req_lsu_tag;
`endif
      l1d_arb_bank_st_req_paddr           [i] = stb_l1d_arb_st_req_paddr;
      l1d_arb_bank_st_req_data            [i] = stb_l1d_arb_st_req_data;
      l1d_arb_bank_st_req_data_byte_mask  [i] = stb_l1d_arb_st_req_data_byte_mask;
      l1d_arb_bank_st_req_sc_rt_check_succ[i] = stb_l1d_arb_st_req_sc_rt_check_succ;
      l1d_arb_bank_st_req_sc_amo_offset   [i] = stb_l1d_arb_st_req_amo_offset;

      stb_l1d_arb_st_req_rdy =  l1d_arb_bank_st_req_rdy[i];
    end
  end
end

// ptw walk req -> l1d bank
always_comb begin
  l1d_arb_bank_ptw_walk_req_vld = '0;
  ptw_walk_req_rdy_unmasked  = '1;
  ptw_replay_bank_ptw_walk_req_rdy = '1;

  l1d_arb_bank_ptw_walk_req_id    = '0;
  l1d_arb_bank_ptw_walk_req_paddr = '0;

  if(ptw_replay_bank_ptw_walk_req_vld) begin // ptw req replay has higher priority
    for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
      if(ptw_walk_req_addr_i[L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_OFFSET_WIDTH] == i[L1D_BANK_ID_INDEX_WIDTH-1:0]) begin
        l1d_arb_bank_ptw_walk_req_vld     [i] = 1'b1;
        l1d_arb_bank_ptw_walk_req_id      [i] = ptw_replay_bank_ptw_walk_req_id; 
        l1d_arb_bank_ptw_walk_req_paddr   [i] = ptw_replay_bank_ptw_walk_req_paddr;

        ptw_walk_req_rdy_unmasked  =  1'b0;
        ptw_replay_bank_ptw_walk_req_rdy = l1d_arb_stb_ptw_walk_req_rdy & l1d_arb_bank_ptw_walk_req_rdy[i];
      end
    end
  end else begin
    for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
      if(ptw_walk_req_addr_i[L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_OFFSET_WIDTH] == i[L1D_BANK_ID_INDEX_WIDTH-1:0]) begin
        l1d_arb_bank_ptw_walk_req_vld     [i] = ptw_walk_req_vld_masked;
        l1d_arb_bank_ptw_walk_req_id      [i] = ptw_walk_req_id_i; 
        l1d_arb_bank_ptw_walk_req_paddr   [i] = ptw_walk_req_addr_i;
  
        ptw_walk_req_rdy_unmasked  =  l1d_arb_stb_ptw_walk_req_rdy & l1d_arb_bank_ptw_walk_req_rdy[i];
        ptw_replay_bank_ptw_walk_req_rdy = 1'b0;
      end
    end
  end
end

// l1d bank resp -> ptw walk
always_comb begin
  ptw_walk_resp_vld_o = '0;

  ptw_walk_resp_id_o  = '0;
  ptw_walk_resp_pte_o = '0;

  for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
    if(band_l1d_arb_ptw_walk_resp_vld[i] == 1'b1) begin
      ptw_walk_resp_vld_o = 1'b1;
      ptw_walk_resp_id_o  = band_l1d_arb_ptw_walk_resp_id [i];
      ptw_walk_resp_pte_o = band_l1d_arb_ptw_walk_resp_pte[i];
    end
  end
end

`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rst) ($onehot0(band_l1d_arb_ptw_walk_resp_vld)))
    else $fatal("l1d: band_l1d_arb_ptw_walk_resp_vld should at most 1 bit to be 1");
`endif



// lsu/dtlb -> cache bank input arbiter
logic [LSU_ADDR_PIPE_COUNT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0] ls_pipe_l1d_ld_req_hit_bank_id;
`ifdef RUBY
generate
  assign ls_pipe_l1d_ld_req_hit_bank_id   = ls_pipe_l1d_ld_req_hit_bank_id_o;
  for(i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
    assign ls_pipe_l1d_st_req_hit_bank_id_o[i] = ls_pipe_l1d_st_req_paddr_i[i][L1D_BANK_OFFSET_WIDTH+:L1D_BANK_ID_INDEX_WIDTH];
  end
endgenerate
`endif 

rvh_l1d_bank_input_arb 
#(
)
L1D_CACHE_BANK_INPUT_ARB
(
// input from lsu
  // LS Pipe -> D$ : Load request
  .ls_pipe_l1d_ld_req_vld_i         (ls_pipe_l1d_ld_req_vld_masked    ),
  .ls_pipe_l1d_ld_req_io_i          (ls_pipe_l1d_ld_req_io_i     ),
  .ls_pipe_l1d_ld_req_rob_tag_i     (ls_pipe_l1d_ld_req_rob_tag_i),
  .ls_pipe_l1d_ld_req_prd_i         (ls_pipe_l1d_ld_req_prd_i    ),
  .ls_pipe_l1d_ld_req_opcode_i      (ls_pipe_l1d_ld_req_opcode_i ),
`ifdef RUBY
  .ls_pipe_l1d_ld_req_lsu_tag_i     (ls_pipe_l1d_ld_req_lsu_tag_i),
`endif
  .ls_pipe_l1d_ld_req_idx_i         (ls_pipe_l1d_ld_req_index_i    ),
  .ls_pipe_l1d_ld_req_offset_i      (ls_pipe_l1d_ld_req_offset_i ),
  .ls_pipe_l1d_ld_req_vtag_i        (ls_pipe_l1d_ld_req_vtag_i   ),
  .stb_l1d_ld_req_rdy_i             (ls_pipe_stb_ld_req_rdy      ),
  .ls_pipe_l1d_ld_req_rdy_o         (ls_pipe_l1d_bank_ld_req_rdy ),
  
`ifdef RUBY
  .ls_pipe_l1d_ld_req_hit_bank_id_o (ls_pipe_l1d_ld_req_hit_bank_id_o),
  .ls_pipe_l1d_st_req_hit_bank_id_o (),
`else
  .ls_pipe_l1d_ld_req_hit_bank_id_o (ls_pipe_l1d_ld_req_hit_bank_id  ),
`endif
      
  .ls_pipe_l1d_dtlb_resp_vld_i      (ls_pipe_l1d_dtlb_resp_vld_i     ),    
  .ls_pipe_l1d_dtlb_resp_ppn_i      (ls_pipe_l1d_dtlb_resp_ppn_i     ),    
  .ls_pipe_l1d_dtlb_resp_excp_vld_i (ls_pipe_l1d_dtlb_resp_excp_vld_i),
  .ls_pipe_l1d_dtlb_resp_hit_i      (ls_pipe_l1d_dtlb_resp_hit_i     ),    
  .ls_pipe_l1d_dtlb_resp_miss_i     (ls_pipe_l1d_dtlb_resp_miss_i    ),   

  // LS Pipe -> D$ : Store request                               
//   .ls_pipe_l1d_st_req_vld_i         (stb_l1d_arb_st_req_vld    ),
//   .ls_pipe_l1d_st_req_io_i          (1'b0     ), // TODO: 
//   .ls_pipe_l1d_st_req_rob_tag_i     (stb_l1d_arb_st_req_rob_tag),
//   .ls_pipe_l1d_st_req_prd_i         (stb_l1d_arb_st_req_prd    ),
//   .ls_pipe_l1d_st_req_opcode_i      (stb_l1d_arb_st_req_opcode ),
// `ifdef RUBY
//   .ls_pipe_l1d_st_req_lsu_tag_i     (stb_l1d_arb_st_req_lsu_tag),
// `endif
//   // .ls_pipe_l1d_st_req_index_i       (ls_pipe_l1d_st_req_index_i  ),
//   // .ls_pipe_l1d_st_req_tag_i         (ls_pipe_l1d_st_req_tag_i    ),
//   .ls_pipe_l1d_st_req_paddr_i       (stb_l1d_arb_st_req_paddr  ),
//   .ls_pipe_l1d_st_req_data_i        (stb_l1d_arb_st_req_data   ),
//   .ls_pipe_l1d_st_req_rdy_o         (stb_l1d_arb_st_req_rdy    ),
  .ls_pipe_l1d_st_req_vld_i         ('0    ),
  .ls_pipe_l1d_st_req_io_i          (1'b0     ), // TODO: 
  .ls_pipe_l1d_st_req_rob_tag_i     ('0),
  .ls_pipe_l1d_st_req_prd_i         ('0    ),
  .ls_pipe_l1d_st_req_opcode_i      ('0 ),
`ifdef RUBY
  .ls_pipe_l1d_st_req_lsu_tag_i     ('0),
`endif
  // .ls_pipe_l1d_st_req_index_i       (ls_pipe_l1d_st_req_index_i  ),
  // .ls_pipe_l1d_st_req_tag_i         (ls_pipe_l1d_st_req_tag_i    ),
  .ls_pipe_l1d_st_req_paddr_i       ('0  ),
  .ls_pipe_l1d_st_req_data_i        ('0   ),
  .ls_pipe_l1d_st_req_rdy_o         (    ),
  
  
  
// output to l1d cache banks
  // LS_PIPE -> D$ : LD Request
  .l1d_bank_ld_req_vld_o            (l1d_arb_bank_ld_req_vld           ),
  .l1d_bank_ld_req_rob_tag_o        (l1d_arb_bank_ld_req_rob_tag       ),
  .l1d_bank_ld_req_prd_o            (l1d_arb_bank_ld_req_prd           ),
  .l1d_bank_ld_req_opcode_o         (l1d_arb_bank_ld_req_opcode        ),
`ifdef RUBY
  .l1d_bank_ld_req_lsu_tag_o        (l1d_arb_bank_ld_req_lsu_tag       ),
`endif
  .l1d_bank_ld_req_idx_o            (l1d_arb_bank_ld_req_idx           ),
  .l1d_bank_ld_req_offset_o         (l1d_arb_bank_ld_req_offset        ),
  .l1d_bank_ld_req_vtag_o           (l1d_arb_bank_ld_req_vtag          ),

  .l1d_bank_stb_ld_req_rdy_o        (l1d_arb_bank_stb_ld_req_rdy       ),
  .l1d_bank_ld_req_rdy_i            (l1d_arb_bank_ld_req_rdy           ),

  // DTLB -> D$   
  .dtlb_l1d_resp_vld_o              (l1d_arb_bank_dtlb_resp_vld       ),     
  .dtlb_l1d_resp_excp_vld_o         (l1d_arb_bank_dtlb_resp_excp_vld  ),
  .dtlb_l1d_resp_hit_o              (l1d_arb_bank_dtlb_resp_hit       ),
  .dtlb_l1d_resp_ppn_o              (l1d_arb_bank_dtlb_resp_ppn       ),
  .dtlb_l1d_resp_rdy_i              (l1d_arb_bank_dtlb_resp_rdy       ),


  // LS_PIPE -> D$ : ST Request     (// LS_PIPE -> D$ : ST Request    ),
//   .l1d_bank_st_req_vld_o            (l1d_arb_bank_st_req_vld           ),
//   .l1d_bank_st_req_io_region_o      (l1d_arb_bank_st_req_io_region     ),
//   .l1d_bank_st_req_rob_tag_o        (l1d_arb_bank_st_req_rob_tag       ),
//   .l1d_bank_st_req_prd_o            (l1d_arb_bank_st_req_prd           ),
//   .l1d_bank_st_req_opcode_o         (l1d_arb_bank_st_req_opcode        ),
// `ifdef RUBY
//   .l1d_bank_st_req_lsu_tag_o        (l1d_arb_bank_st_req_lsu_tag       ),
// `endif
//   .l1d_bank_st_req_paddr_o          (l1d_arb_bank_st_req_paddr         ),
//   .l1d_bank_st_req_data_o           (l1d_arb_bank_st_req_data          ),// data f
//   .l1d_bank_st_req_data_byte_mask_o (l1d_arb_bank_st_req_data_byte_mask),

//   .l1d_bank_st_req_rdy_i            (l1d_arb_bank_st_req_rdy           ),
  .l1d_bank_st_req_vld_o            (   ),
  .l1d_bank_st_req_io_region_o      (   ),
  .l1d_bank_st_req_rob_tag_o        (   ),
  .l1d_bank_st_req_prd_o            (   ),
  .l1d_bank_st_req_opcode_o         (   ),
`ifdef RUBY
  .l1d_bank_st_req_lsu_tag_o        (   ),
`endif
  .l1d_bank_st_req_paddr_o          (   ),
  .l1d_bank_st_req_data_o           (   ),// data f
  .l1d_bank_st_req_data_byte_mask_o (   ),

  .l1d_bank_st_req_rdy_i            ('0           ),


  .clk                              (clk                               ),
  .rst                              (rst                               )
);


//stb -> l1d bank
// cache bank resp arbiter
logic [L1D_BANK_ID_NUM-1:0]                          l1d_bank_l1d_wb_vld_from_cache_hit;

logic [LSU_ADDR_PIPE_COUNT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] l1d_wb_from_cache_hit_port_id;
logic [LSU_ADDR_PIPE_COUNT-1:0]                       l1d_wb_from_cache_hit_port_id_vld;
logic                          [L1D_BANK_ID_INDEX_WIDTH-1:0] l1d_wb_from_mlfb_port_id;
logic                                                 l1d_wb_from_mlfb_port_id_vld;

logic [LSU_ADDR_PIPE_COUNT-1:0]                       l1d_int_prf_wb_vld_from_cache_hit_selected;
logic                                                 l1d_int_prf_wb_vld_from_mlfb_selected;

logic                                                 l1d_wb_port_full_from_cache_hit;


// ===== TODO: here only work for 2 wb ports ======
assign l1d_bank_l1d_wb_vld_from_cache_hit = l1d_bank_l1d_wb_vld & ~l1d_bank_l1d_wb_vld_from_mlfb;

select_two_from_n_valid
#(
    .SEL_WIDTH    (L1D_BANK_ID_NUM)
)
get_wb_bank_id_u
(
    .sel_i              (l1d_bank_l1d_wb_vld_from_cache_hit   ),
    .first_id_needed_vld_i  (1'b1                             ),
    .second_id_needed_vld_i (1'b1                             ),
    .first_id_vld_o     (l1d_wb_from_cache_hit_port_id_vld[0] ),
    .second_id_vld_o    (l1d_wb_from_cache_hit_port_id_vld[1] ),
    .first_id_o         (l1d_wb_from_cache_hit_port_id[0]     ),
    .second_id_o        (l1d_wb_from_cache_hit_port_id[1]     )
);

priority_encoder
#(
    .SEL_WIDTH    (L1D_BANK_ID_NUM)
)
mlfb_wb_vld_sel
(
    .sel_i      (l1d_bank_l1d_wb_vld_from_mlfb                ),
    .id_vld_o   (l1d_wb_from_mlfb_port_id_vld                 ),
    .id_o       (l1d_wb_from_mlfb_port_id                     )
);

assign l1d_int_prf_wb_vld_from_cache_hit_selected[0] = l1d_wb_from_cache_hit_port_id_vld[0];
assign l1d_int_prf_wb_vld_from_cache_hit_selected[1] = l1d_wb_from_cache_hit_port_id_vld[1];
assign l1d_int_prf_wb_vld_from_mlfb_selected         = l1d_wb_from_mlfb_port_id_vld & ~(&l1d_int_prf_wb_vld_from_cache_hit_selected);

 // l1d wb -> prf
assign l1d_int_prf_wb_vld_o[0]  = l1d_int_prf_wb_vld_from_cache_hit_selected[0] | l1d_int_prf_wb_vld_from_mlfb_selected;
assign l1d_int_prf_wb_vld_o[1]  = l1d_int_prf_wb_vld_from_cache_hit_selected[1] | (l1d_int_prf_wb_vld_from_cache_hit_selected[0] & l1d_int_prf_wb_vld_from_mlfb_selected);

assign l1d_int_prf_wb_tag_o[0]  = l1d_int_prf_wb_vld_from_cache_hit_selected[0]  ? l1d_bank_l1d_wb_tag[l1d_wb_from_cache_hit_port_id[0]]
                                                                                : l1d_bank_l1d_wb_tag[l1d_wb_from_mlfb_port_id];
assign l1d_int_prf_wb_tag_o[1]  = l1d_int_prf_wb_vld_from_cache_hit_selected[1]  ? l1d_bank_l1d_wb_tag[l1d_wb_from_cache_hit_port_id[1]]
                                                                                : l1d_bank_l1d_wb_tag[l1d_wb_from_mlfb_port_id];
assign l1d_int_prf_wb_data_o[0] = l1d_int_prf_wb_vld_from_cache_hit_selected[0]  ? l1d_bank_l1d_wb_data[l1d_wb_from_cache_hit_port_id[0]]
                                                                                : l1d_bank_l1d_wb_data[l1d_wb_from_mlfb_port_id];
assign l1d_int_prf_wb_data_o[1] = l1d_int_prf_wb_vld_from_cache_hit_selected[1]  ? l1d_bank_l1d_wb_data[l1d_wb_from_cache_hit_port_id[1]]
                                                                                : l1d_bank_l1d_wb_data[l1d_wb_from_mlfb_port_id];

`ifdef RUBY
assign l1d_lsu_lsu_tag_o[0]  = l1d_int_prf_wb_vld_from_cache_hit_selected[0]  ? l1d_bank_l1d_lsu_tag[l1d_wb_from_cache_hit_port_id[0]]
                                                                              : l1d_bank_l1d_lsu_tag[l1d_wb_from_mlfb_port_id];
assign l1d_lsu_lsu_tag_o[1]  = l1d_int_prf_wb_vld_from_cache_hit_selected[1]  ? l1d_bank_l1d_lsu_tag[l1d_wb_from_cache_hit_port_id[1]]
                                                                              : l1d_bank_l1d_lsu_tag[l1d_wb_from_mlfb_port_id];
`endif

 // l1d resp -> rob
generate
  for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
    assign l1d_rob_wb_vld_o     [i] = l1d_int_prf_wb_vld_o[i];
    assign l1d_rob_wb_rob_tag_o [i] = l1d_int_prf_wb_vld_from_cache_hit_selected[i]  ? l1d_rob_wb_rob_tag[l1d_wb_from_cache_hit_port_id[i]]
                                                                                     : l1d_rob_wb_rob_tag[l1d_wb_from_mlfb_port_id];
  end
  for(i = LSU_ADDR_PIPE_COUNT; i < LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT; i++) begin
    assign l1d_rob_wb_vld_o     [i] = (ls_pipe_l1d_st_req_vld_masked[i-LSU_ADDR_PIPE_COUNT] & ls_pipe_l1d_st_req_rdy_unmasked[i-LSU_ADDR_PIPE_COUNT] & ~ls_pipe_l1d_st_req_is_fence_i[i-LSU_ADDR_PIPE_COUNT]) | // common ld req hsk
                                      stb_rob_wb_vld[i];
    assign l1d_rob_wb_rob_tag_o [i] = stb_rob_wb_vld[i] ? stb_rob_wb_rob_tag[i] : ls_pipe_l1d_st_req_rob_tag_i[i-LSU_ADDR_PIPE_COUNT];
  end
endgenerate

// l1d -> l1d banks
assign l1d_wb_port_full_from_cache_hit = &l1d_int_prf_wb_vld_from_cache_hit_selected;
always_comb begin
  l1d_bank_l1d_wb_rdy_from_mlfb = '0;
  for(int i = 0; i < L1D_BANK_ID_NUM; i++) begin
    if(l1d_wb_from_mlfb_port_id == i[L1D_BANK_ID_INDEX_WIDTH-1:0]) begin
      l1d_bank_l1d_wb_rdy_from_mlfb[i] = ~l1d_wb_port_full_from_cache_hit;
    end
  end
end

// =================================================

// D$ -> LSQ, mshr full replay
//logic [L1D_BANK_ID_NUM-1:0]                          bank_l1d_replay_vld;
//logic [L1D_BANK_ID_NUM-1:0]                          bank_l1d_mshr_full;
//`ifdef RUBY
//logic [L1D_BANK_ID_NUM-1:0][RRV64_LSU_ID_WIDTH-1:0]  bank_l1d_replay_lsu_tag;
//`endif

//    output logic [LSU_ADDR_PIPE_COUNT-1:0]                         l1d_ls_pipe_ld_replay_valid_o,
//`ifdef RUBY
//    output logic [RRV64_LSU_ID_WIDTH-1:0]                          l1d_ls_pipe_replay_lsu_tag_o,
//`endif

// logic [L1D_BANK_ID_NUM-1:0]        bank_l1d_replay_vld_rev;
// logic [LSU_ADDR_PIPE_COUNT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] bank_l1d_replay_port_id;
// logic [LSU_ADDR_PIPE_COUNT-1:0]                       bank_l1d_replay_port_id_vld;
// logic [LSU_ADDR_PIPE_COUNT-1:0]                       stb_l1d_ld_replay_vld;
// logic                                                 stb_l1d_ptw_replay_vld;
// ===== TODO: here only work for 2 replay ports ======
// generate
//   for(i = 0; i < L1D_BANK_ID_NUM; i++) begin
//     assign bank_l1d_replay_vld_rev[i] = bank_l1d_replay_vld[L1D_BANK_ID_NUM-1-i];
//   end
// endgenerate

// priority_encoder
// #(
//     .SEL_WIDTH    (L1D_BANK_ID_NUM)
// )
// first_replay_wb_vld_sel
// (
//     .sel_i      (bank_l1d_replay_vld   ),
//     .id_vld_o   (bank_l1d_replay_port_id_vld[0]                ),
//     .id_o       (bank_l1d_replay_port_id[0]                    )
// );

// priority_encoder
// #(
//     .SEL_WIDTH    (L1D_BANK_ID_NUM)
// )
// second_replay_vld_sel
// (
//     .sel_i      (bank_l1d_replay_vld_rev ),
//     .id_vld_o   (bank_l1d_replay_port_id_vld[1]                  ),
//     .id_o       (bank_l1d_replay_port_id[1]                      )
// );

typedef logic[L1D_BANK_ID_INDEX_WIDTH-1:0] in_pipe_bank_id_t;
in_pipe_bank_id_t [LSU_ADDR_PIPE_COUNT-1:0] s1_ld_bank_id;
in_pipe_bank_id_t [LSU_ADDR_PIPE_COUNT-1:0] s2_ld_bank_id;
logic [LSU_ADDR_PIPE_COUNT-1:0] s1_ld_bank_id_vld;
logic [LSU_ADDR_PIPE_COUNT-1:0] s2_ld_bank_id_vld;

`ifdef RUBY
  always_comb begin
    l1d_ls_pipe_ld_replay_valid_o = '0;
    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      for(int j = 0; j < L1D_BANK_ID_NUM; j++) begin
        if((bank_l1d_replay_lsu_tag[j][RRV64_LSU_ID_WIDTH-1-:$clog2(LSU_ADDR_PIPE_COUNT)] ==  i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0])
            && bank_l1d_replay_vld[j]
        ) begin
          l1d_ls_pipe_ld_replay_valid_o [i] = 1'b1;
          l1d_ls_pipe_replay_lsu_tag_o  [i] = bank_l1d_replay_lsu_tag[j];
        end
      end
    end
  end
`else
  logic [LSU_ADDR_PIPE_COUNT-1:0] l1d_ls_pipe_ld_replay_valid_mid;
  always_comb begin
    l1d_ls_pipe_ld_replay_valid_mid = '0;
    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      for(int j = 0; j < L1D_BANK_ID_NUM; j++) begin
        if(s2_ld_bank_id_vld[i] & (s2_ld_bank_id[i] ==  j)) begin
          l1d_ls_pipe_ld_replay_valid_mid [i] = bank_l1d_replay_vld[j];
        end
      end
    end
  end
  assign l1d_ls_pipe_ld_replay_valid_o = l1d_ls_pipe_ld_replay_valid_mid | stb_l1d_ld_replay_vld;
`endif

// lsu -> l1d kill at s2
  logic [LSU_ADDR_PIPE_COUNT-1:0] lsu_pipe_ld_req_hsk;
  
  logic [L1D_BANK_ID_NUM-1:0][LSU_ADDR_PIPE_COUNT-1:0]    l1d_arb_bank_ld_kill_resp_mid;
  logic [L1D_BANK_ID_NUM-1:0]                             l1d_arb_bank_ld_kill_resp;
  
  generate
    for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin: gen_stage_ld_bank_id
      assign lsu_pipe_ld_req_hsk[i] = ls_pipe_l1d_ld_req_vld_masked[i] & ls_pipe_l1d_bank_ld_req_rdy[i];
      std_dffre #(.WIDTH($bits(in_pipe_bank_id_t))) U_IN_PIPE_BANK_ID_S1 (.clk(clk), .rstn(rst), .en(lsu_pipe_ld_req_hsk[i]), .d(ls_pipe_l1d_ld_req_hit_bank_id[i]),.q(s1_ld_bank_id[i]));
      std_dffr  #(.WIDTH($bits(in_pipe_bank_id_t))) U_IN_PIPE_BANK_ID_S2 (.clk(clk), .rstn(rst), .d(s1_ld_bank_id[i]), .q(s2_ld_bank_id[i]));

      std_dffr  #(.WIDTH(1)) U_IN_PIPE_BANK_ID_S1_VLD (.clk(clk), .rstn(rst), .d(lsu_pipe_ld_req_hsk[i]),.q(s1_ld_bank_id_vld[i]));
      std_dffr  #(.WIDTH(1)) U_IN_PIPE_BANK_ID_S2_VLD (.clk(clk), .rstn(rst), .d(s1_ld_bank_id_vld[i]),  .q(s2_ld_bank_id_vld[i]));
    end
  endgenerate
  
  always_comb begin: comb_l1d_arb_bank_ld_kill_resp_mid
    l1d_arb_bank_ld_kill_resp_mid = '0;
    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      for(int j = 0; j < L1D_BANK_ID_NUM; j++) begin
        if(s2_ld_bank_id[i] == j) begin
          l1d_arb_bank_ld_kill_resp_mid[j][i] = ls_pipe_l1d_kill_resp_i[i] | stb_l1d_ld_replay_vld[i];
        end
      end
    end
  end
  
  generate
    for(i = 0; i < L1D_BANK_ID_NUM; i++) begin: gen_l1d_arb_bank_ld_kill_resp
      assign l1d_arb_bank_ld_kill_resp[i] = |(l1d_arb_bank_ld_kill_resp_mid[i]);
    end
  endgenerate
  
// to host exit
`ifndef SYNTHESIS
  logic l1d_exit_flag;
  logic [PADDR_WIDTH-1:0] tohost_addr;
  always_ff @(posedge clk) begin
    if (rst) begin
      l1d_exit_flag <= 0;
    end
    for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
      if(ls_pipe_l1d_st_req_vld_i[i] & ~ls_pipe_l1d_st_req_is_fence_i[i] & ls_pipe_l1d_st_req_rdy_o[i] & (ls_pipe_l1d_st_req_paddr_i[i] == tohost_addr)) begin
        $display("write to to host paddr: %h", ls_pipe_l1d_st_req_paddr_i[i]);
        $display("write to to host data : %h", ls_pipe_l1d_st_req_data_i[i]);
        // if(ls_pipe_l1d_st_req_data_i[i][0] == 1'b1) begin
          $display("exit");
          l1d_exit_flag <= 1;
          // $finish();
        // end
      end
    end
  end
`endif

// amo ctrl fsm
  logic [LSU_DATA_PIPE_COUNT-1:0]                         amo_ctrl_stb_st_req_vld;
  logic [LSU_DATA_PIPE_COUNT-1:0]                         amo_ctrl_stb_st_req_is_fence;
  logic                                                   amo_ctrl_stb_st_req_no_fence_wb_resp;
  logic                                                   amo_ctrl_stb_st_req_sc_rt_check_succ;
  logic [LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] amo_ctrl_stb_st_req_rob_tag;
  logic [LSU_DATA_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0] amo_ctrl_stb_st_req_prd;
  logic [LSU_DATA_PIPE_COUNT-1:0][      STU_OP_WIDTH-1:0] amo_ctrl_stb_st_req_opcode;
  logic [LSU_DATA_PIPE_COUNT-1:0][       PADDR_WIDTH-1:0] amo_ctrl_stb_st_req_paddr;
  logic [LSU_DATA_PIPE_COUNT-1:0][              XLEN-1:0] amo_ctrl_stb_st_req_data;
`ifdef RUBY
  logic [LSU_DATA_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] amo_ctrl_stb_st_req_lsu_tag;
`endif
  logic [LSU_DATA_PIPE_COUNT-1:0]                         amo_ctrl_stb_st_req_rdy;

  rvh_l1d_amo_ctrl 
  #(
    .N_STB_ST_IN_PORT ( LSU_DATA_PIPE_COUNT )
  )
  AMO_CTRL_U (
  // input st req from lsu
    .ls_pipe_amo_ctrl_st_req_vld_i      (ls_pipe_l1d_st_req_vld_masked ),
    .ls_pipe_amo_ctrl_st_req_is_fence_i (ls_pipe_l1d_st_req_is_fence_i ),
    .ls_pipe_amo_ctrl_st_req_rob_tag_i  (ls_pipe_l1d_st_req_rob_tag_i ),
    .ls_pipe_amo_ctrl_st_req_prd_i      (ls_pipe_l1d_st_req_prd_i ),
    .ls_pipe_amo_ctrl_st_req_opcode_i   (ls_pipe_l1d_st_req_opcode_i ),
    .ls_pipe_amo_ctrl_st_req_paddr_i    (ls_pipe_l1d_st_req_paddr_i ),
    .ls_pipe_amo_ctrl_st_req_data_i     (ls_pipe_l1d_st_req_data_i ),
`ifdef RUBY
    .ls_pipe_amo_ctrl_st_req_lsu_tag_i  (ls_pipe_l1d_st_req_lsu_tag_i ),
`endif
    .ls_pipe_amo_ctrl_st_req_rdy_o      (ls_pipe_l1d_st_req_rdy_unmasked ),

  // output st req to stb
    .amo_ctrl_stb_st_req_vld_o          (amo_ctrl_stb_st_req_vld ),
    .amo_ctrl_stb_st_req_is_fence_o     (amo_ctrl_stb_st_req_is_fence ),
    .amo_ctrl_stb_st_req_no_fence_wb_resp_o(amo_ctrl_stb_st_req_no_fence_wb_resp),
    .amo_ctrl_stb_st_req_sc_rt_check_succ_o(amo_ctrl_stb_st_req_sc_rt_check_succ),
    .amo_ctrl_stb_st_req_rob_tag_o      (amo_ctrl_stb_st_req_rob_tag ),
    .amo_ctrl_stb_st_req_prd_o          (amo_ctrl_stb_st_req_prd ),
    .amo_ctrl_stb_st_req_opcode_o       (amo_ctrl_stb_st_req_opcode ),
    .amo_ctrl_stb_st_req_paddr_o        (amo_ctrl_stb_st_req_paddr ),
    .amo_ctrl_stb_st_req_data_o         (amo_ctrl_stb_st_req_data ),
`ifdef RUBY
    .amo_ctrl_stb_st_req_lsu_tag_o      (amo_ctrl_stb_st_req_lsu_tag ),
`endif
    .amo_ctrl_stb_st_req_rdy_i          (amo_ctrl_stb_st_req_rdy ),
  
  // input resp to finish the amo fsm
    .l1d_rob_wb_vld_i                   (l1d_rob_wb_vld_o     [LSU_DATA_PIPE_COUNT-1:0] ),
    .l1d_rob_wb_rob_tag_i               (l1d_rob_wb_rob_tag_o [LSU_DATA_PIPE_COUNT-1:0] ),

  // output in amo state
    .in_amo_state_o                     (in_amo_state ),

    .clk (clk),
    .rst (rst)
  );


// store buffer

  rvh_l1d_stb 
  #(
    .N_STB              (L1D_STB_ENTRY_NUM    ),
    .N_STB_ST_IN_PORT   (LSU_DATA_PIPE_COUNT  ),
    .N_STB_LD_IN_PORT   (LSU_ADDR_PIPE_COUNT  )
  )
  STB_U
  (
    // LS_PIPE -> STB : ST Request
    .ls_pipe_stb_st_req_vld_i             (amo_ctrl_stb_st_req_vld ),
    .ls_pipe_l1d_st_req_is_fence_i        (amo_ctrl_stb_st_req_is_fence),
    .ls_pipe_l1d_st_req_no_fence_wb_resp_i(amo_ctrl_stb_st_req_no_fence_wb_resp),
    .ls_pipe_l1d_st_req_sc_rt_check_succ_i(amo_ctrl_stb_st_req_sc_rt_check_succ),
    .ls_pipe_stb_st_req_rob_tag_i         (amo_ctrl_stb_st_req_rob_tag ),
    .ls_pipe_stb_st_req_prd_i             (amo_ctrl_stb_st_req_prd     ),
    .ls_pipe_stb_st_req_opcode_i          (amo_ctrl_stb_st_req_opcode  ),
    .ls_pipe_stb_st_req_paddr_i           (amo_ctrl_stb_st_req_paddr   ),
    .ls_pipe_stb_st_req_data_i            (amo_ctrl_stb_st_req_data    ),
`ifdef RUBY
    .ls_pipe_stb_st_req_lsu_tag_i         (amo_ctrl_stb_st_req_lsu_tag ),
`endif
    .ls_pipe_stb_st_req_rdy_o             (amo_ctrl_stb_st_req_rdy     ),

    // LS_PIPE -> STB : LD Request
    .ls_pipe_stb_ld_req_vld_i             (ls_pipe_l1d_ld_req_vld_masked & ls_pipe_l1d_bank_ld_req_rdy    ),
    .ls_pipe_stb_ld_req_rob_tag_i         (ls_pipe_l1d_ld_req_rob_tag_i ),
    .ls_pipe_stb_ld_req_prd_i             (ls_pipe_l1d_ld_req_prd_i     ),
    .ls_pipe_stb_ld_req_opcode_i          (ls_pipe_l1d_ld_req_opcode_i  ),
`ifdef RUBY
    .ls_pipe_stb_ld_req_lsu_tag_i         (ls_pipe_l1d_ld_req_lsu_tag_i ),
`endif
    .ls_pipe_stb_ld_req_idx_i             (ls_pipe_l1d_ld_req_index_i   ),
    .ls_pipe_stb_ld_req_offset_i          (ls_pipe_l1d_ld_req_offset_i  ),
    .ls_pipe_stb_ld_req_vtag_i            (ls_pipe_l1d_ld_req_vtag_i    ),
    .l1d_stb_st_req_rdy_i                 (ls_pipe_l1d_ld_req_rdy_unmasked),
    .ls_pipe_stb_ld_req_rdy_o             (ls_pipe_stb_ld_req_rdy       ),

    // core pipeline flush, kill load req in pipe
    .kill_ld_req_i                        (rob_flush_i                      ),
    
    // LS Pipe -> STB : DTLB response
    .ls_pipe_stb_dtlb_resp_vld_i          (ls_pipe_l1d_dtlb_resp_vld_i ),
    .ls_pipe_stb_dtlb_resp_ppn_i          (ls_pipe_l1d_dtlb_resp_ppn_i ),
    .ls_pipe_stb_dtlb_resp_excp_vld_i     (ls_pipe_l1d_dtlb_resp_excp_vld_i ),
    .ls_pipe_stb_dtlb_resp_hit_i          (ls_pipe_l1d_dtlb_resp_hit_i  ),
    .ls_pipe_stb_dtlb_resp_miss_i         (ls_pipe_l1d_dtlb_resp_miss_i ),
    
    // STB -> ROB : Write Back
    .stb_rob_wb_vld_o                     (stb_rob_wb_vld               ),
    .stb_rob_wb_rob_tag_o                 (stb_rob_wb_rob_tag           ),
    // STB -> Int PRF : Write Back
    .stb_int_prf_wb_vld_o                 (stb_int_prf_wb_vld           ),
    .stb_int_prf_wb_tag_o                 (stb_int_prf_wb_tag           ), // TODO: no need, only need ld bypass vld and data
    .stb_int_prf_wb_data_o                (stb_int_prf_wb_data          ),
    .stb_l1d_arb_bank_id_o                (stb_l1d_arb_bank_id          ),
`ifdef RUBY
    .stb_lsu_lsu_tag_o                    (stb_lsu_lsu_tag              ), // TODO: no need, only need ld bypass vld and data
`endif
    
    // STB -> D$ Pipeline : ST Request
    .stb_l1d_st_req_vld_o                 (stb_l1d_arb_st_req_vld           ),
    .stb_l1d_st_req_rob_tag_o             (stb_l1d_arb_st_req_rob_tag       ),
    .stb_l1d_st_req_prd_o                 (stb_l1d_arb_st_req_prd           ),
    .stb_l1d_st_req_opcode_o              (stb_l1d_arb_st_req_opcode        ),
    .stb_l1d_st_req_paddr_o               (stb_l1d_arb_st_req_paddr         ),
    .stb_l1d_st_req_data_o                (stb_l1d_arb_st_req_data          ),
    .stb_l1d_st_req_data_byte_mask_o      (stb_l1d_arb_st_req_data_byte_mask),
`ifdef RUBY
    .stb_l1d_st_req_lsu_tag_o             (stb_l1d_arb_st_req_lsu_tag),
`endif
    .stb_l1d_st_req_sc_rt_check_succ_o    (stb_l1d_arb_st_req_sc_rt_check_succ),
    .stb_l1d_st_req_amo_offset_o          (stb_l1d_arb_st_req_amo_offset    ),
    .stb_l1d_st_req_rdy_i                 (stb_l1d_arb_st_req_rdy           ),

    // PTW -> D$ : Request
    .ptw_walk_req_vld_i                   (ptw_walk_req_vld_masked               ),
    .ptw_walk_req_id_i                    (ptw_walk_req_id_i                ),
    .ptw_walk_req_addr_i                  (ptw_walk_req_addr_i              ),
    .ptw_walk_l1d_req_rdy_i               (ptw_walk_req_rdy_unmasked        ),
    .ptw_walk_req_rdy_o                   (l1d_arb_stb_ptw_walk_req_rdy     ),

    // stb in flush state
    .stb_l1d_in_fence_busy_o              (     ),

    // stb ld partial hit: replay the load
    .stb_l1d_ld_partial_hit_replay_o      (stb_l1d_ld_replay_vld               ),

    // stb ptw partial hit: replay the ptw
    .stb_l1d_ptw_partial_hit_replay_o     (stb_l1d_ptw_replay_vld              ),

    // fencei, need to firstly evict all stb entries to cache bank
    .fencei_flush_vld_i                   (fencei_flush_stb_vld                 ),
    .fencei_flush_rdy_o                   (fencei_flush_stb_rdy                 ),
    .fencei_flush_done_o                  (fencei_flush_stb_done                ),

    .clk                                  (clk ),
    .rst                                  (rst )
  );


`ifdef RUBY
  // for ruby test, need to resp st lsu_id when it actually writen into cache data ram
  logic [L1D_BANK_ID_NUM-1:0]                          l1d_lsu_st_lsu_tag_vld_per_bank;
  logic [L1D_BANK_ID_NUM-1:0][RRV64_LSU_ID_WIDTH-1:0]  l1d_lsu_st_lsu_tag_per_bank;
  logic [LSU_DATA_PIPE_COUNT-1:0][L1D_BANK_ID_NUM-1:0]                          l1d_lsu_st_lsu_tag_vld_bank_map_to_input_port;
  logic [LSU_DATA_PIPE_COUNT-1:0][L1D_BANK_ID_NUM-1:0][RRV64_LSU_ID_WIDTH-1:0]  l1d_lsu_st_lsu_tag_bank_map_to_input_port;

  logic [LSU_DATA_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] l1d_lsu_st_lsu_tag_re_per_input_port;

  always_comb begin
    l1d_lsu_st_lsu_tag_vld_bank_map_to_input_port  = '0;
    l1d_lsu_st_lsu_tag_bank_map_to_input_port      = '0;
    for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
      for(int j = 0; j < L1D_BANK_ID_NUM; j++) begin
        if(l1d_lsu_st_lsu_tag_vld_per_bank[j] && (l1d_lsu_st_lsu_tag_per_bank[j][RRV64_LSU_ID_WIDTH-1-:$clog2(LSU_DATA_PIPE_COUNT)] == i[$clog2(LSU_DATA_PIPE_COUNT)-1:0])) begin
          l1d_lsu_st_lsu_tag_vld_bank_map_to_input_port[i][j] = 1'b1;
          l1d_lsu_st_lsu_tag_bank_map_to_input_port    [i][j] = l1d_lsu_st_lsu_tag_per_bank[j];
        end
      end
    end
  end

  generate
    for(i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin: gen_l1d_lsu_st_lsu_tag_vld_per_input_port_o_fifo
      mp_fifo
      #(
        .payload_t          (logic[RRV64_LSU_ID_WIDTH-1:0]  ),
        .ENQUEUE_WIDTH      (L1D_BANK_ID_NUM        ),
        .DEQUEUE_WIDTH      (1                      ),
        .DEPTH              (N_MSHR*L1D_BANK_ID_NUM ),
        .MUST_TAKEN_ALL     (0                      )
      )
      l1d_lsu_st_lsu_tag_vld_per_input_port_o_fifo_u
      (
        // Enqueue
        .enqueue_vld_i          (l1d_lsu_st_lsu_tag_vld_bank_map_to_input_port  [i]),
        .enqueue_payload_i      (l1d_lsu_st_lsu_tag_bank_map_to_input_port      [i]),
        .enqueue_rdy_o          (                                 ),
        // Dequeue
        .dequeue_vld_o          (l1d_lsu_st_lsu_tag_vld_per_input_port_o          [i]),
        .dequeue_payload_o      (l1d_lsu_st_lsu_tag_per_input_port_o              [i]),
        .dequeue_rdy_i          (l1d_lsu_st_lsu_tag_re_per_input_port           [i]),
        
        .flush_i                (1'b0                             ),
        
        .clk                    (clk                           ),
        .rst                    (~rst                          )
      );
      
      assign l1d_lsu_st_lsu_tag_re_per_input_port[i] = l1d_lsu_st_lsu_tag_vld_per_input_port_o[i] & l1d_lsu_st_lsu_tag_rdy_per_input_port_i[i];

    end
  endgenerate

`endif

  // cache bank gen
generate
  for(i = 0; i < L1D_BANK_ID_NUM; i++) begin: gen_l1d_bank
    rvh_l1d_bank
    #(
      .CORE_ID(CORE_ID ),
      .BANK_ID (i)
    )
    L1D_CACHE_BANK_U
    (
      // LS_PIPE -> D$ : LD Request
      .ls_pipe_l1d_ld_req_vld_i               (l1d_arb_bank_ld_req_vld[i]     ),
      .ls_pipe_l1d_ld_req_rob_tag_i           (l1d_arb_bank_ld_req_rob_tag[i] ),
      .ls_pipe_l1d_ld_req_prd_i               (l1d_arb_bank_ld_req_prd[i]     ),
      .ls_pipe_l1d_ld_req_opcode_i            (l1d_arb_bank_ld_req_opcode[i]  ),
  `ifdef RUBY
      .ls_pipe_l1d_ld_req_lsu_tag_i           (l1d_arb_bank_ld_req_lsu_tag[i] ),
  `endif
  
      .ls_pipe_l1d_ld_req_idx_i               (l1d_arb_bank_ld_req_idx[i]     ),
      .ls_pipe_l1d_ld_req_offset_i            (l1d_arb_bank_ld_req_offset[i]  ),
      .ls_pipe_l1d_ld_req_vtag_i              (l1d_arb_bank_ld_req_vtag[i]),
      
      .stb_l1d_ld_rdy_i                       (l1d_arb_bank_stb_ld_req_rdy[i] ),
      .ls_pipe_l1d_ld_req_rdy_o               (l1d_arb_bank_ld_req_rdy[i]     ),
      
      // LS_PIPE -> D$ : Kill LD Response
      .ls_pipe_l1d_ld_kill_i                  (1'b0                       ),
      .ls_pipe_l1d_ld_rar_fail_i              (1'b0                       ),
      
      // LS_PIPE -> D$ : ST Request
      .ls_pipe_l1d_st_req_vld_i               (l1d_arb_bank_st_req_vld[i]     ),
      .ls_pipe_l1d_st_req_io_region_i         (l1d_arb_bank_st_req_io_region[i]),
      .ls_pipe_l1d_st_req_rob_tag_i           (l1d_arb_bank_st_req_rob_tag[i] ),
      .ls_pipe_l1d_st_req_prd_i               (l1d_arb_bank_st_req_prd[i]     ),
      .ls_pipe_l1d_st_req_opcode_i            (l1d_arb_bank_st_req_opcode[i]  ),
  `ifdef RUBY
      .ls_pipe_l1d_st_req_lsu_tag_i           (l1d_arb_bank_st_req_lsu_tag[i] ),
  `endif
      .ls_pipe_l1d_st_req_paddr_i             (l1d_arb_bank_st_req_paddr[i]   ),
      .ls_pipe_l1d_st_req_data_i              (l1d_arb_bank_st_req_data[i]    ), // data from stb
      .ls_pipe_l1d_st_req_data_byte_mask_i    (l1d_arb_bank_st_req_data_byte_mask[i]  ), // data byte mask from stb
      .ls_pipe_l1d_st_req_sc_rt_check_succ_i  (l1d_arb_bank_st_req_sc_rt_check_succ[i]), // sc
      .ls_pipe_l1d_st_req_sc_amo_offset_i     (l1d_arb_bank_st_req_sc_amo_offset[i]),

      .ls_pipe_l1d_st_req_rdy_o               (l1d_arb_bank_st_req_rdy[i]     ),

`ifdef RUBY
      // for ruby test, need to resp st lsu_id when it actually writen into cache data ram
      .l1d_lsu_st_lsu_tag_vld_o               (l1d_lsu_st_lsu_tag_vld_per_bank [i]),
      .l1d_lsu_st_lsu_tag_o                   (l1d_lsu_st_lsu_tag_per_bank     [i]),
`endif
      
      // LS_PIPE -> D$ : Kill ST Response
      .ls_pipe_l1d_ld_raw_fail_i              (1'b0                       ),
      
      // DTLB -> D$
      .dtlb_l1d_resp_vld_i                    (l1d_arb_bank_dtlb_resp_vld     [i]),
      .dtlb_l1d_resp_excp_vld_i               (l1d_arb_bank_dtlb_resp_excp_vld[i]), // s1 kill
      .dtlb_l1d_resp_hit_i                    (l1d_arb_bank_dtlb_resp_hit     [i]),      // s1 kill
      .dtlb_l1d_resp_ppn_i                    (l1d_arb_bank_dtlb_resp_ppn     [i]), // VIPT, get at s1 if tlb hit
      .dtlb_l1d_resp_rdy_o                    (l1d_arb_bank_dtlb_resp_rdy     [i]),

      // STB -> D$ : store buffer load bypass
      .stb_l1d_bank_ld_bypass_valid_i         (stb_l1d_bank_ld_bypass_valid   [i]),
      .stb_l1d_bank_ld_bypass_data_i          (stb_l1d_bank_ld_bypass_data    [i]),
`ifdef RUBY
      // ruby replay need lsu_id, so the stb partial replay need to send by l1d bank
      .stb_l1d_bank_ld_bypass_partial_hit_replay_i  (stb_l1d_bank_ld_replay_vld [i]),
`endif

      // s2 kill
      .lsu_l1d_s2_kill_valid_i                (l1d_arb_bank_ld_kill_resp      [i]),
      // input  logic [BANK_TAG_WIDTH-1:0]     lsu_l1d_s2_kill_valid_i,
  
      // D$ -> LSQ, mshr full replay
      .l1d_ls_pipe_replay_vld_o               (bank_l1d_replay_vld[i]     ),
      .l1d_ls_pipe_mshr_full_o                (bank_l1d_mshr_full[i]      ),
  `ifdef RUBY
      .l1d_ls_pipe_replay_lsu_tag_o           (bank_l1d_replay_lsu_tag[i]        ),
  `endif
  
      // D$ -> ROB : Write Back
      .l1d_rob_wb_vld_o                       (l1d_rob_wb_vld    [i]      ), // TODO:
      .l1d_rob_wb_rob_tag_o                   (l1d_rob_wb_rob_tag[i]      ), // TODO:
      
      // D$ -> Int PRF : Write Back
      .l1d_int_prf_wb_vld_o                   (l1d_bank_l1d_wb_vld[i]           ),
      .l1d_int_prf_wb_tag_o                   (l1d_bank_l1d_wb_tag[i]           ),
      .l1d_int_prf_wb_data_o                  (l1d_bank_l1d_wb_data[i]          ),
      .l1d_int_prf_wb_vld_from_mlfb_o         (l1d_bank_l1d_wb_vld_from_mlfb[i] ),
      .l1d_int_prf_wb_rdy_from_mlfb_i         (l1d_bank_l1d_wb_rdy_from_mlfb[i] ),
      
  `ifdef RUBY
      .l1d_lsu_lsu_tag_o                      (l1d_bank_l1d_lsu_tag[i]          ),
  `endif
      
      // PTW -> D$ : Request
      .ptw_walk_req_vld_i                     (l1d_arb_bank_ptw_walk_req_vld  [i]),
      .ptw_walk_req_id_i                      (l1d_arb_bank_ptw_walk_req_id   [i]),
      .ptw_walk_req_addr_i                    (l1d_arb_bank_ptw_walk_req_paddr[i]),
      .stb_l1d_ptw_walk_req_rdy_i             (l1d_arb_stb_ptw_walk_req_rdy      ),
      .ptw_walk_req_rdy_o                     (l1d_arb_bank_ptw_walk_req_rdy  [i]),

      // PTW -> D$ : Response
      .ptw_walk_resp_vld_o                    (band_l1d_arb_ptw_walk_resp_vld [i]),
      .ptw_walk_resp_id_o                     (band_l1d_arb_ptw_walk_resp_id  [i]),
      .ptw_walk_resp_pte_o                    (band_l1d_arb_ptw_walk_resp_pte [i]),
      .ptw_walk_resp_rdy_i                    (ptw_walk_resp_rdy_i              ),

        // l1d snp ctrl -> l1d bank
      .snp_l1d_bank_snp_req_i                             (snp_l1d_bank_snp_req       [i]),
    // s0 req
      .snp_l1d_bank_snp_s0_req_vld_i                      (snp_l1d_bank_snp_s0_req_vld[i]),
      .snp_l1d_bank_snp_s0_req_hsk_i                      (snp_l1d_bank_snp_s0_req_hsk[i]),
      .snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_i   (snp_l1d_bank_snp_s0_turn_down_refill_ready_vld[i]), // all_2
      .snp_l1d_bank_snp_s0_req_rdy_o                      (snp_l1d_bank_snp_s0_req_rdy[i]), // not used, reserve for stall snoop transaction
      .snp_l1d_bank_snp_s0_o                              (snp_l1d_bank_snp_s0        [i]),

    // s1 req: read tag ram, read lst
      .snp_l1d_bank_snp_s1_req_vld_i                      (snp_l1d_bank_snp_s1_req_vld[i]),
      .snp_l1d_bank_snp_s1_req_hsk_i                      (snp_l1d_bank_snp_s1_req_hsk[i]),
      .snp_l1d_bank_snp_s1_req_rdy_o                      (snp_l1d_bank_snp_s1_req_rdy[i]),
      .snp_l1d_bank_snp_s1_o                              (snp_l1d_bank_snp_s1        [i]),

    // s2 req
      .snp_l1d_bank_snp_s2_req_vld_i                      (snp_l1d_bank_snp_s2_req_vld            [i]), // vld for: all_1
      .snp_l1d_bank_snp_s2_req_hsk_i                      (snp_l1d_bank_snp_s2_req_hsk            [i]), // hsk for: s2_2, s2_3
      .snp_l1d_bank_snp_s2_req_new_line_state_i           (snp_l1d_bank_snp_s2_req_new_line_state [i]), // dat for: s2_3
      .snp_l1d_bank_snp_s2_req_way_id_i                   (snp_l1d_bank_snp_s2_req_way_id         [i]),
      .snp_l1d_bank_snp_s2_req_data_ram_rd_vld_i          (snp_l1d_bank_snp_s2_req_data_ram_rd_vld[i]), // vld for: s2_2
      .snp_l1d_bank_snp_s2_req_rdy_o                      (snp_l1d_bank_snp_s2_req_rdy            [i]),
      .snp_l1d_bank_snp_s2_o                              (snp_l1d_bank_snp_s2                    [i]),

    // s3 req
      .snp_l1d_bank_snp_s3_req_vld_i                      (snp_l1d_bank_snp_s3_req_vld            [i]), // vld for: all_1
      .snp_l1d_bank_snp_s3_tag_compare_match_id_i         (snp_l1d_bank_snp_s3_tag_compare_match_id[i]),
      .snp_l1d_bank_snp_s3_req_line_data_o                (snp_l1d_bank_snp_s3_req_line_data      [i]),
  
    // L1D -> L2 : Request
    // cache tx port, private cache -> scu
      // req
      .pc_scu_req_vld_o               (pc_cc_arb_req_vld   [i] ),
      .pc_scu_req_o                   (pc_cc_arb_req       [i] ),
      .pc_scu_req_rdy_i               (pc_cc_arb_req_rdy   [i] ),
    
      // resp
      .pc_scu_resp_vld_o              (l1d_bank_cc_arb_resp_vld  [i] ),
      .pc_scu_resp_o                  (l1d_bank_cc_arb_resp      [i] ),
      .pc_scu_resp_rdy_i              (l1d_bank_cc_arb_resp_rdy  [i] ),
    
      // evict/wb
      .pc_scu_evict_vld_o             (pc_cc_arb_evict_vld [i] ),
      .pc_scu_evict_o                 (pc_cc_arb_evict     [i] ),
      .pc_scu_evict_rdy_i             (pc_cc_arb_evict_rdy [i] ),
    
      // data
      .pc_scu_data_vld_o              (l1d_bank_cc_arb_data_vld  [i] ),
      .pc_scu_data_o                  (l1d_bank_cc_arb_data      [i] ),
      .pc_scu_data_rdy_i              (l1d_bank_cc_arb_data_rdy  [i] ),
    
    // cache rx port, scu -> private cache
      // resp
      .scu_pc_resp_vld_i              (cc_arb_pc_resp_vld  [i] ),
      .scu_pc_resp_i                  (cc_arb_pc_resp      [i] ),
      .scu_pc_resp_rdy_o              (cc_arb_pc_resp_rdy  [i] ),
    
      // data
      .scu_pc_data_vld_i              (cc_arb_pc_data_vld  [i] ),
      .scu_pc_data_i                  (cc_arb_pc_data      [i] ),
      .scu_pc_data_rdy_o              (cc_arb_pc_data_rdy  [i] ),
  
      // L1D-> LSU : evict or snooped // move to lid, not in bank
      .l1d_lsu_invld_vld_o                    (), // TODO:
      .l1d_lsu_invld_tag_o                    (), // TODO: // tag+bankid
  
  
      // kill all the load in pipeline, and mark all the load miss in mshr "no resp"
      .rob_flush_i                            (rob_flush_i              ),

      // make all dirty line into clean, write back dirty line
      .fencei_flush_vld_i                     (fencei_flush_bank_vld  ),
      .fencei_flush_grant_o                   (fencei_flush_grant_per_bank_out[i]),
  
      .clk                                    (clk                 ),
      .rst                                    (rst                )
    );
  end
endgenerate

// cache bank snp ctrl gen
logic [L1D_BANK_ID_NUM-1:0] snp_req_head_buf_valid_clr;
assign snp_req_head_buf_valid_clr_o = snp_req_head_buf_valid_clr;
generate
  for(i = 0; i < L1D_BANK_ID_NUM; i++) begin: gen_l1d_bank_snp_ctrl

    rvh_l1d_snp_ctrl 
    #(
      .CORE_ID(CORE_ID ),
      .SNOOP_REQ_BUFFER_DEPTH(L1D_BANK_SNOOP_REQ_BUFFER_DEPTH )
    )
    rvh_l1d_snp_ctrl_dut (
      // cache rx port, scu -> private cache
        // snp
      .scu_pc_snp_vld_i   (cc_arb_pc_snp_vld   [i] ),
      .scu_pc_snp_i       (cc_arb_pc_snp       [i] ),
      .scu_pc_snp_rdy_o   (cc_arb_pc_snp_rdy   [i] ),

      // cache tx port, private cache -> scu
        // resp
      .pc_scu_resp_vld_o  (l1d_snp_cc_arb_resp_vld  [i] ),
      .pc_scu_resp_o      (l1d_snp_cc_arb_resp      [i] ),
      .pc_scu_resp_rdy_i  (l1d_snp_cc_arb_resp_rdy  [i] ),
        // data
      .pc_scu_data_vld_o  (l1d_snp_cc_arb_data_vld  [i] ),
      .pc_scu_data_o      (l1d_snp_cc_arb_data      [i] ),
      .pc_scu_data_rdy_i  (l1d_snp_cc_arb_data_rdy  [i] ),

      // snp ctrl <-> l1d bank intf
      .snp_l1d_bank_snp_req_o        (snp_l1d_bank_snp_req [i] ),
        // s0 req
      .snp_l1d_bank_snp_s0_req_vld_o (snp_l1d_bank_snp_s0_req_vld   [i] ),
      .snp_l1d_bank_snp_s0_req_hsk_o (snp_l1d_bank_snp_s0_req_hsk   [i] ),
      .snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_o (snp_l1d_bank_snp_s0_turn_down_refill_ready_vld  [i] ),
      .snp_l1d_bank_snp_s0_req_rdy_i (snp_l1d_bank_snp_s0_req_rdy   [i] ),
      .snp_l1d_bank_snp_s0_i (snp_l1d_bank_snp_s0   [i] ),
        // s1 req
      .snp_l1d_bank_snp_s1_req_vld_o (snp_l1d_bank_snp_s1_req_vld   [i] ),
      .snp_l1d_bank_snp_s1_req_hsk_o (snp_l1d_bank_snp_s1_req_hsk   [i] ),
      .snp_l1d_bank_snp_s1_req_rdy_i (snp_l1d_bank_snp_s1_req_rdy   [i] ),
      .snp_l1d_bank_snp_s1_i (snp_l1d_bank_snp_s1   [i] ),
        // s2 req
      .snp_l1d_bank_snp_s2_req_vld_o (snp_l1d_bank_snp_s2_req_vld   [i] ),
      .snp_l1d_bank_snp_s2_req_hsk_o (snp_l1d_bank_snp_s2_req_hsk   [i] ),
      .snp_l1d_bank_snp_s2_req_new_line_state_o (snp_l1d_bank_snp_s2_req_new_line_state   [i] ),
      .snp_l1d_bank_snp_s2_req_way_id_o (snp_l1d_bank_snp_s2_req_way_id   [i] ),
      .snp_l1d_bank_snp_s2_req_data_ram_rd_vld_o (snp_l1d_bank_snp_s2_req_data_ram_rd_vld   [i] ),
      .snp_l1d_bank_snp_s2_req_rdy_i (snp_l1d_bank_snp_s2_req_rdy   [i] ),
      .snp_l1d_bank_snp_s2_i (snp_l1d_bank_snp_s2   [i] ),
        // s3 req
      .snp_l1d_bank_snp_s3_req_vld_o (snp_l1d_bank_snp_s3_req_vld   [i] ),
      .snp_l1d_bank_snp_s3_tag_compare_match_id_o (snp_l1d_bank_snp_s3_tag_compare_match_id   [i] ),
      .snp_l1d_bank_snp_s3_req_line_data_i (snp_l1d_bank_snp_s3_req_line_data   [i] ),
      .snp_req_head_buf_valid_clr_o (snp_req_head_buf_valid_clr [i]),
      .clk  (clk ),
      .rst  (rst)
    );

  end
endgenerate




rvh_l1d_bank_cc_arb 
#(
  .INPUT_PORT_NUM(L1D_BANK_ID_NUM )
)
rvh_l1d_bank_cc_arb_dut (
  // L1D banks -> cc arb
    // private cache -> scu
      // req
  .pc_scu_req_vld_i       (pc_cc_arb_req_vld   ),
  .pc_scu_req_i           (pc_cc_arb_req       ),
  .pc_scu_req_rdy_o       (pc_cc_arb_req_rdy   ),
      // resp
  .pc_scu_resp_vld_i      (pc_cc_arb_resp_vld  ),
  .pc_scu_resp_i          (pc_cc_arb_resp      ),
  .pc_scu_resp_rdy_o      (pc_cc_arb_resp_rdy  ),
      // evict/wb
  .pc_scu_evict_vld_i     (pc_cc_arb_evict_vld ),
  .pc_scu_evict_i         (pc_cc_arb_evict     ),
  .pc_scu_evict_rdy_o     (pc_cc_arb_evict_rdy ),
      // data
  .pc_scu_data_vld_i      (pc_cc_arb_data_vld  ),
  .pc_scu_data_i          (pc_cc_arb_data      ),
  .pc_scu_data_rdy_o      (pc_cc_arb_data_rdy  ),

    // scu -> private cache
      // resp
  .scu_pc_resp_vld_o      (cc_arb_pc_resp_vld  ),
  .scu_pc_resp_o          (cc_arb_pc_resp      ),
  .scu_pc_resp_rdy_i      (cc_arb_pc_resp_rdy  ),
      // snp
  .scu_pc_snp_vld_o       (cc_arb_pc_snp_vld   ),
  .scu_pc_snp_o           (cc_arb_pc_snp       ),
  .scu_pc_snp_rdy_i       (cc_arb_pc_snp_rdy   ),
      // data
  .scu_pc_data_vld_o      (cc_arb_pc_data_vld  ),
  .scu_pc_data_o          (cc_arb_pc_data      ),
  .scu_pc_data_rdy_i      (cc_arb_pc_data_rdy  ),

    // cc arb -> scu
      // req
  .arb_pc_scu_req_vld_o   (pc_scu_req_vld_o ),
  .arb_pc_scu_req_o       (pc_scu_req_o ),
  .arb_pc_scu_req_rdy_i   (pc_scu_req_rdy_i ),
      // resp
  .arb_pc_scu_resp_vld_o  (pc_scu_resp_vld_o ),
  .arb_pc_scu_resp_o      (pc_scu_resp_o ),
  .arb_pc_scu_resp_rdy_i  (pc_scu_resp_rdy_i ),
      // evict/wb
  .arb_pc_scu_evict_vld_o (pc_scu_evict_vld_o ),
  .arb_pc_scu_evict_o     (pc_scu_evict_o ),
  .arb_pc_scu_evict_rdy_i (pc_scu_evict_rdy_i ),
      // data
  .arb_pc_scu_data_vld_o  (pc_scu_data_vld_o ),
  .arb_pc_scu_data_o      (pc_scu_data_o ),
  .arb_pc_scu_data_rdy_i  (pc_scu_data_rdy_i ),

    // cache rx port, scu -> private cache
      // resp
  .arb_scu_pc_resp_vld_i  (scu_pc_resp_vld_i ),
  .arb_scu_pc_resp_i      (scu_pc_resp_i ),
  .arb_scu_pc_resp_rdy_o  (scu_pc_resp_rdy_o ),
      // snp
  .arb_scu_pc_snp_vld_i   (scu_pc_snp_vld_i ),
  .arb_scu_pc_snp_i       (scu_pc_snp_i ),
  .arb_scu_pc_snp_rdy_o   (scu_pc_snp_rdy_o ),
      // data
  .arb_scu_pc_data_vld_i  (scu_pc_data_vld_i ),
  .arb_scu_pc_data_i      (scu_pc_data_i ),
  .arb_scu_pc_data_rdy_o  (scu_pc_data_rdy_o ),


  .clk (clk ),
  .rst (rst )
);



// replay buffer for ptw req
// replay when the ptw req partial hit in the stb, and the stb needs to evict that stb entry to cache
rvh_l1d_ptw_replay_buffer 
#(
  .REPLAY_LATENCY (4)
) L1D_PTW_REPLAY_BUFFER_U (
  .ptw_walk_req_vld_i   (ptw_walk_req_vld_masked   ),
  .ptw_walk_req_id_i    (ptw_walk_req_id_i    ),
  .ptw_walk_req_addr_i  (ptw_walk_req_addr_i  ),

  .ptw_walk_resp_vld_i  (ptw_walk_resp_vld_o  ),
  .ptw_walk_resp_rdy_i  (ptw_walk_resp_rdy_i  ),

  .stb_l1d_ptw_replay_vld_i (stb_l1d_ptw_replay_vld),

  .ptw_walk_replay_req_vld_o   (ptw_replay_bank_ptw_walk_req_vld    ),
  .ptw_walk_replay_req_id_o    (ptw_replay_bank_ptw_walk_req_id     ),
  .ptw_walk_replay_req_paddr_o (ptw_replay_bank_ptw_walk_req_paddr  ),
  .ptw_walk_replay_req_rdy_i   (ptw_replay_bank_ptw_walk_req_rdy    ),

  .clk  ( clk ),
  .rst  ( rst )
);


`ifndef SYNTHESIS
int dc_debug_print;
initial begin
  dc_debug_print = 0;
  $value$plusargs("dc_debug_print=%d",dc_debug_print);
end

logic [63:0] cycle;
always_ff @(posedge clk or negedge rst) begin
  if(~rst) begin
    cycle <= '0;
  end else begin
    cycle <= cycle + 1;
  end
end

always_ff @(posedge clk) begin
  if(dc_debug_print) begin
    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      if(ls_pipe_l1d_ld_req_vld_masked[i] & ls_pipe_l1d_ld_req_rdy_o[i]) begin
        $display("\n\n====================");
        $display("22@ cycle = %d, load req[core %2d][port %d, l1d bank %d] handshake", cycle, CORE_ID, i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0], ls_pipe_l1d_ld_req_index_i[i][L1D_BANK_ID_INDEX_WIDTH-1:0]);
        // $display("lsu_id    = 0x%x", lsu_l1d_ld_req[i].lsu_id);
        $display("rob_tag   = 0x%x", ls_pipe_l1d_ld_req_rob_tag_i[i]);
        $display("opcode    = 0x%x", ls_pipe_l1d_ld_req_opcode_i[i]);
        $display("vaddr     = 0x%x", {ls_pipe_l1d_ld_req_vtag_i[i], ls_pipe_l1d_ld_req_index_i[i], ls_pipe_l1d_ld_req_offset_i[i]});
        $display("prd_tag   = 0x%x", ls_pipe_l1d_ld_req_prd_i[i]);
        $display("====================");
      end
    end

    for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
      if(ls_pipe_l1d_st_req_vld_masked[i] & ls_pipe_l1d_st_req_rdy_o[i]) begin
        $display("\n\n====================");
        $display("22@ cycle = %d, store req[core %2d][port %d, l1d bank %d] handshake", cycle, CORE_ID, i[$clog2(LSU_DATA_PIPE_COUNT)-1:0], ls_pipe_l1d_st_req_paddr_i[i][L1D_OFFSET_WIDTH+L1D_BANK_ID_INDEX_WIDTH-1:L1D_OFFSET_WIDTH]);
        // $display("lsu_id    = 0x%x", lsu_l1d_st_req[i].lsu_id);
        $display("rob_tag   = 0x%x", ls_pipe_l1d_st_req_rob_tag_i[i]);
        $display("opcode    = 0x%x", ls_pipe_l1d_st_req_opcode_i[i]);
        $display("paddr     = 0x%x", ls_pipe_l1d_st_req_paddr_i[i]);
        $display("prd_tag   = 0x%x", ls_pipe_l1d_st_req_prd_i[i]);
        $display("is_fence  = 0x%x", ls_pipe_l1d_st_req_is_fence_i[i]);
        $write("st_dat    = 0x");
        for(int j = XLEN/64-1; j >=0; j--) begin
          $write("%h", ls_pipe_l1d_st_req_data_i[i][j*64+:64]);
        end
        $display("\n====================");
      end
    end

    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      if(l1d_rob_wb_vld_o[i]) begin
        $display("\n\n====================");
        $display("22@ cycle = %d, load resp[core %2d][port %d] handshake", cycle, CORE_ID, i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0]);
        // $display("lsu_id    = 0x%x", lsu_l1d_ld_resp[i].lsu_id);
        $display("rob_tag   = 0x%x", l1d_rob_wb_rob_tag_o[i]);
        // $display("req_type  = 0x%x", lsu_l1d_ld_resp[i].req_type);
        $display("prd_tag   = 0x%x", l1d_int_prf_wb_tag_o[i]);
        $write("ld_data   = 0x");
        for(int j = XLEN/64-1; j >=0; j--) begin
          $write("%h", l1d_int_prf_wb_data_o[i][j*64+:64]);
        end
        $display("\n====================");
      end
    end

    if(pc_scu_req_vld_o & pc_scu_req_rdy_i) begin
      $display("\n\n====================");
      $display("@ cycle = %d, [core %2d] l1d -> scu req channel handshake", cycle, CORE_ID);
      $display("addr       = 0x%x", pc_scu_req_o.addr);
      $display("rtype      = %s", pc_scu_req_o.rtype.name());
      $display("id.cid     = 0x%x // private cache id", pc_scu_req_o.id.cid);
      $display("id.bid     = 0x%x // cache bank id, the highest used for distinguish i$/d$ ", pc_scu_req_o.id.bid);
      $display("id.pc_tid  = 0x%x // cache mshr id in req and req's resp", pc_scu_req_o.id.pc_tid);
      $display("====================");
    end
    if(pc_scu_resp_vld_o & pc_scu_resp_rdy_i) begin
      $display("\n\n====================");
      $display("@ cycle = %d, [core %2d] l1d -> scu resp channel handshake", cycle, CORE_ID);
      $display("rtype      = %s", pc_scu_resp_o.rtype.name());
      $display("id.cid     = 0x%x // private cache id", pc_scu_resp_o.id.cid);
      $display("id.bid     = 0x%x // cache bank id, the highest used for distinguish i$/d$ ", pc_scu_resp_o.id.bid);
      $display("id.pc_tid  = 0x%x // cache mshr id in req and req's resp", pc_scu_resp_o.id.pc_tid);
      $display("id.scu_tid = 0x%x // scu mshr id in snp, msb to diff scu mshr / repl mshr", pc_scu_resp_o.id.scu_tid);
      $display("====================");
    end
    if(pc_scu_evict_vld_o & pc_scu_evict_rdy_i) begin
      $display("\n\n====================");
      $display("@ cycle = %d, [core %2d] l1d -> scu evict channel handshake", cycle, CORE_ID);
      $display("addr       = 0x%x", pc_scu_evict_o.addr);
      $display("rtype      = %s", pc_scu_evict_o.rtype.name());
      $display("id.cid     = 0x%x // private cache id", pc_scu_evict_o.id.cid);
      $display("id.bid     = 0x%x // cache bank id, the highest used for distinguish i$/d$ ", pc_scu_evict_o.id.bid);
      $display("id.pc_tid  = 0x%x // cache mshr id in req and req's resp", pc_scu_evict_o.id.pc_tid);
      $display("====================");
    end
    if(pc_scu_data_vld_o & pc_scu_data_rdy_i) begin
      $display("\n\n====================");
      $display("@ cycle = %d, [core %2d] l1d -> scu data channel handshake", cycle, CORE_ID);
      $display("rtype      = %s", pc_scu_data_o.rtype.name());
      $display("id.cid     = 0x%x // private cache id", pc_scu_data_o.id.cid);
      $display("id.bid     = 0x%x // cache bank id, the highest used for distinguish i$/d$ ", pc_scu_data_o.id.bid);
      $display("id.pc_tid  = 0x%x // cache mshr id in req and req's resp", pc_scu_data_o.id.pc_tid);
      $display("id.scu_tid = 0x%x // scu mshr id in snp, msb to diff scu mshr / repl mshr", pc_scu_data_o.id.scu_tid);
      $display("data_valid = 0x%x", pc_scu_data_o.data_valid);
      $display("data_dirty = 0x%x", pc_scu_data_o.data_dirty);
      $write(  "data(valid,dirty) = 0x");
      for(int i = DATA_BURST_NUM-1; i >=0; i--) begin
        $write("%h(%d,%d) ", pc_scu_data_o.data[i],pc_scu_data_o.data_valid[i],pc_scu_data_o.data_dirty[i]);
      end
      $display("\n====================");
    end


    if(scu_pc_resp_vld_i & scu_pc_resp_rdy_o) begin
      $display("\n\n====================");
      $display("@ cycle = %d, scu -> [core %2d] l1d resp channel handshake", cycle, CORE_ID);
      $display("rtype      = %s", scu_pc_resp_i.rtype.name());
      $display("id.cid     = 0x%x // private cache id", scu_pc_resp_i.id.cid);
      $display("id.bid     = 0x%x // cache bank id, the highest used for distinguish i$/d$ ", scu_pc_resp_i.id.bid);
      $display("id.pc_tid  = 0x%x // cache mshr id in req and req's resp", scu_pc_resp_i.id.pc_tid);
      $display("id.scu_tid = 0x%x // scu mshr id in snp, msb to diff scu mshr / repl mshr", scu_pc_resp_i.id.scu_tid);
      $display("====================");
    end
    if(scu_pc_snp_vld_i & scu_pc_snp_rdy_o) begin
      $display("\n\n====================");
      $display("@ cycle = %d, scu -> [core %2d] l1d snp channel handshake", cycle, CORE_ID);
      $display("addr       = 0x%x", scu_pc_snp_i.addr);
      $display("rtype      = %s", scu_pc_snp_i.rtype.name());
      $display("send_target= 0x%x", scu_pc_snp_i.id.cid);
      $display("id.scu_tid = 0x%x // scu mshr id in snp, msb to diff scu mshr / repl mshr", scu_pc_snp_i.id.scu_tid);
      $display("====================");
    end
    if(scu_pc_data_vld_i & scu_pc_data_rdy_o) begin
      $display("\n\n====================");
      $display("@ cycle = %d, scu -> [core %2d] l1d data channel handshake", cycle, CORE_ID);
      $display("rtype      = %s", scu_pc_data_i.rtype.name());
      $display("id.cid     = 0x%x // private cache id", scu_pc_data_i.id.cid);
      $display("id.bid     = 0x%x // cache bank id, the highest used for distinguish i$/d$ ", scu_pc_data_i.id.bid);
      $display("id.pc_tid  = 0x%x // cache mshr id in req and req's resp", scu_pc_data_i.id.pc_tid);
      $display("id.scu_tid = 0x%x // scu mshr id in snp, msb to diff scu mshr / repl mshr", scu_pc_data_i.id.scu_tid);
      $display("data_valid = 0x%x", scu_pc_data_i.data_valid);
      $display("data_dirty = 0x%x", scu_pc_data_i.data_dirty);
      $write(  "data(valid,dirty) = 0x");
      for(int i = DATA_BURST_NUM-1; i >=0; i--) begin
        $write("%h(%d,%d) ", scu_pc_data_i.data[i],scu_pc_data_i.data_valid[i],scu_pc_data_i.data_dirty[i]);
      end
      $display("\n====================");
    end

  end
end

`endif

endmodule : rvh_l1d
