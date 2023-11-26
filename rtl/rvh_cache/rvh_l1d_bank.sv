module rvh_l1d_bank
  import riscv_pkg::*;
  import rvh_pkg::*;
  import uop_encoding_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_uncore_param_pkg::*;
#(
  parameter CORE_ID = 0,
  parameter BANK_ID = 0
)
(
    // LS_PIPE -> D$ : LD Request
    input  logic                          ls_pipe_l1d_ld_req_vld_i,
    input  logic [     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_rob_tag_i,
    input  logic [    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_prd_i,
    input  logic [      LDU_OP_WIDTH-1:0] ls_pipe_l1d_ld_req_opcode_i,
`ifdef RUBY
    input  logic [RRV64_LSU_ID_WIDTH-1:0] ls_pipe_l1d_ld_req_lsu_tag_i,
`endif

    input  logic [L1D_BANK_SET_INDEX_WIDTH-1:0] ls_pipe_l1d_ld_req_idx_i,
    input  logic [L1D_BANK_OFFSET_WIDTH-1:0   ] ls_pipe_l1d_ld_req_offset_i,
    input  logic [L1D_BANK_TAG_WIDTH-1:0      ] ls_pipe_l1d_ld_req_vtag_i,
    
    input  logic                          stb_l1d_ld_rdy_i,
    output logic                          ls_pipe_l1d_ld_req_rdy_o,
    // LS_PIPE -> D$ : Kill LD Response
    input  logic                          ls_pipe_l1d_ld_kill_i,
    input  logic                          ls_pipe_l1d_ld_rar_fail_i,
    // LS_PIPE -> D$ : ST Request
    input  logic                          ls_pipe_l1d_st_req_vld_i,
    input  logic                          ls_pipe_l1d_st_req_io_region_i,
    input  logic [     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_rob_tag_i,
    input  logic [    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_prd_i,
    input  logic [      STU_OP_WIDTH-1:0] ls_pipe_l1d_st_req_opcode_i,
`ifdef RUBY
    input  logic [RRV64_LSU_ID_WIDTH-1:0] ls_pipe_l1d_st_req_lsu_tag_i,
`endif
    input  logic [       PADDR_WIDTH-1:0] ls_pipe_l1d_st_req_paddr_i,
    input  logic [  L1D_STB_DATA_WIDTH  -1:0] ls_pipe_l1d_st_req_data_i, // data from stb
    input  logic [  L1D_STB_DATA_WIDTH/8-1:0] ls_pipe_l1d_st_req_data_byte_mask_i, // data byte mask from stb
    input  logic                              ls_pipe_l1d_st_req_sc_rt_check_succ_i, // sc
    input  logic [      L1D_OFFSET_WIDTH-1:0] ls_pipe_l1d_st_req_sc_amo_offset_i,
    output logic                          ls_pipe_l1d_st_req_rdy_o,

`ifdef RUBY
    // for ruby test, need to resp st lsu_id when it actually writen into cache data ram
    output logic                           l1d_lsu_st_lsu_tag_vld_o,
    output logic [RRV64_LSU_ID_WIDTH-1:0]  l1d_lsu_st_lsu_tag_o,
`endif

    // LS_PIPE -> D$ : Kill ST Response
    input  logic                          ls_pipe_l1d_ld_raw_fail_i,
    // DTLB -> D$
    input  logic                          dtlb_l1d_resp_vld_i,
    input  logic                          dtlb_l1d_resp_excp_vld_i, // s1 kill
    input  logic                          dtlb_l1d_resp_hit_i,      // s1 kill
    input  logic [       PPN_WIDTH-1:0]   dtlb_l1d_resp_ppn_i, // VIPT, get at s1 if tlb hit
    output logic                          dtlb_l1d_resp_rdy_o,

    // STB -> D$ : store buffer load bypass
    input  logic                          stb_l1d_bank_ld_bypass_valid_i,
    input  logic [            XLEN-1:0]   stb_l1d_bank_ld_bypass_data_i,
`ifdef RUBY
// ruby replay need lsu_id, so the stb partial replay need to send by l1d bank
    input  logic                          stb_l1d_bank_ld_bypass_partial_hit_replay_i,
`endif

    // s2 kill
    // 1. kill load miss new mshr and load hit resp at s2
    // 2. stb part hit, replay the load and kill the load in l1d bank
    input  logic                          lsu_l1d_s2_kill_valid_i,

    // D$ -> LSQ, mshr full / stb partial hit replay
    output logic                          l1d_ls_pipe_replay_vld_o,
    output logic                          l1d_ls_pipe_mshr_full_o,
`ifdef RUBY
    output logic [RRV64_LSU_ID_WIDTH-1:0] l1d_ls_pipe_replay_lsu_tag_o,
`endif

    // D$ -> ROB : Write Back
    output logic                          l1d_rob_wb_vld_o,
    output logic [     ROB_TAG_WIDTH-1:0] l1d_rob_wb_rob_tag_o,
    // D$ -> Int PRF : Write Back
    output logic                          l1d_int_prf_wb_vld_o,
    output logic [    PREG_TAG_WIDTH-1:0] l1d_int_prf_wb_tag_o,
    output logic [              XLEN-1:0] l1d_int_prf_wb_data_o,

    output logic                          l1d_int_prf_wb_vld_from_mlfb_o,
    input  logic                          l1d_int_prf_wb_rdy_from_mlfb_i,
`ifdef RUBY
    output logic [RRV64_LSU_ID_WIDTH-1:0] l1d_lsu_lsu_tag_o,
    // output rrv64_l1d_req_type_dec_t       l1d_lsu_req_type_dec_o,
`endif

    // PTW -> D$ : Request
    input  logic                          ptw_walk_req_vld_i,
    input  logic [      PTW_ID_WIDTH-1:0] ptw_walk_req_id_i,
    input  logic [       PADDR_WIDTH-1:0] ptw_walk_req_addr_i,
    input  logic                          stb_l1d_ptw_walk_req_rdy_i,
    output logic                          ptw_walk_req_rdy_o,
    // PTW -> D$ : Response
    output logic                          ptw_walk_resp_vld_o,
    output logic [      PTW_ID_WIDTH-1:0] ptw_walk_resp_id_o,
    output logic [         PTE_WIDTH-1:0] ptw_walk_resp_pte_o,
    input  logic                          ptw_walk_resp_rdy_i,

    // l1d snp ctrl -> l1d bank
    input snp_req_head_buf_t              snp_l1d_bank_snp_req_i,
      // s0 req
    input  logic                          snp_l1d_bank_snp_s0_req_vld_i,
    input  logic                          snp_l1d_bank_snp_s0_req_hsk_i,
    input  logic                          snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_i, // all_2
    output logic                          snp_l1d_bank_snp_s0_req_rdy_o, // not used, reserve for stall snoop transaction
    output snp_l1d_bank_snp_s0_t          snp_l1d_bank_snp_s0_o,

      // s1 req: read tag ram, read lst
    input  logic                          snp_l1d_bank_snp_s1_req_vld_i,
    input  logic                          snp_l1d_bank_snp_s1_req_hsk_i,
    output logic                          snp_l1d_bank_snp_s1_req_rdy_o,
    output snp_l1d_bank_snp_s1_t          snp_l1d_bank_snp_s1_o,

      // s2 req
    input  logic                          snp_l1d_bank_snp_s2_req_vld_i, // vld for: all_1
    input  logic                          snp_l1d_bank_snp_s2_req_hsk_i, // hsk for: s2_2, s2_3
    input  rrv64_mesi_type_e              snp_l1d_bank_snp_s2_req_new_line_state_i, // dat for: s2_3
    input  logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  snp_l1d_bank_snp_s2_req_way_id_i,
    input  logic                          snp_l1d_bank_snp_s2_req_data_ram_rd_vld_i, // vld for: s2_2
    output logic                          snp_l1d_bank_snp_s2_req_rdy_o,
    output snp_l1d_bank_snp_s2_t          snp_l1d_bank_snp_s2_o,

      // s3 req
    input  logic                          snp_l1d_bank_snp_s3_req_vld_i, // vld for: all_1
    input  logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] snp_l1d_bank_snp_s3_tag_compare_match_id_i,
    output logic [L1D_BANK_LINE_DATA_SIZE-1:0]  snp_l1d_bank_snp_s3_req_line_data_o,


    // L1D -> L2 : Request
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
  
      // data
    input  logic                        scu_pc_data_vld_i,
    input  cache_scu_cc_data_t          scu_pc_data_i,
    output logic                        scu_pc_data_rdy_o,

    // L1D-> LSU : evict or snooped // move to l1d, not in bank
    output logic                            l1d_lsu_invld_vld_o,
    output logic[PADDR_WIDTH-1:0]           l1d_lsu_invld_tag_o, // tag+bankid

    // kill all the load in pipeline, and mark all the load miss in mshr "no resp"
    input logic rob_flush_i,

    // make all dirty line into clean, write back dirty line
    input  logic fencei_flush_vld_i,
    output logic fencei_flush_grant_o,

    input logic clk,
    input logic rst
);

// pipe reg
l1d_pipe_reg_t cur, nxt;

// pipe valid
logic s1_valid, s2_valid;
logic s1_nxt_ena,s2_nxt_ena;
logic s1_valid_nxt,s2_valid_nxt;
logic s1_stall, s2_stall;

//decode
rrv64_l1d_req_type_dec_t req_type_dec;

// tag ram access
logic cache_rd_valid_tram;
logic cache_wr_valid_tram;
logic[L1D_BANK_WAY_NUM-1:0] cache_rd_tram_way_en;
logic[L1D_BANK_WAY_NUM-1:0] cache_wr_tram_way_en;
logic[L1D_BANK_SET_INDEX_WIDTH-1:0 ] cache_idx_tram;
// logic[L1D_BANK_OFFSET_WIDTH-1:0] cache_offset_tram;

logic[L1D_BANK_WAY_NUM-1:0] tram_cs ;
logic[L1D_BANK_WAY_NUM-1:0] tram_wen ;
// logic[L1D_BANK_WAY_NUM-1:0] tram_wmask;
logic[L1D_BANK_WAY_NUM-1:0][L1D_BANK_SET_INDEX_WIDTH-1:0] tram_addr;
logic[L1D_BANK_TAG_RAM_WORD_WIDTH-1:0] cache_wr_dat_tram;
logic[L1D_BANK_WAY_NUM-1:0][L1D_BANK_TAG_RAM_WORD_WIDTH-1:0] tram_wdat; // +1 for valid bit
logic[L1D_BANK_WAY_NUM-1:0][L1D_BANK_TAG_RAM_WORD_WIDTH-1:0] tram_rdat;


// data ram access
logic cache_rd_valid_dram;
logic cache_wr_valid_dram;
logic[L1D_BANK_SET_INDEX_WIDTH-1:0 ] cache_idx_dram;
logic[L1D_BANK_OFFSET_WIDTH-1:0] cache_offset_dram;
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] cache_way_idx_dram;
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] cache_way_idx_dram_s1;
logic[L1D_BANK_OFFSET_WIDTH-1:0   ] cache_offset_dram_s1;
logic[L1D_BANK_WAY_NUM -1:0] cache_way_en_dram_raw;
logic[L1D_BANK_WAY_NUM -1:0] cache_way_en_dram;
logic[L1D_BANK_WAY_NUM -1:0] cache_way_en_dram_seg;
logic[L1D_BANK_WAY_NUM -1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8-1:0] cache_way_byte_en_dram_seg;
logic[XLEN -1:0] cache_wr_dat_dram;


logic [L1D_BANK_WAY_NUM-1:0] dram_cs ;
logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8-1:0] dram_wen_biten; // byte enable
logic              [L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8-1:0] dram_wen_biten_tmp; // byte enable
logic [XLEN/8-1:0] st_dat_biten; // byte enable
logic [L1D_BANK_WAY_NUM-1:0] dram_wen;
logic [L1D_BANK_WAY_NUM-1:0] dram_wen_way;
//logic [L1D_BANK_WAY_NUM-1:0] dram_wen_all;
logic [L1D_BANK_SET_INDEX_WIDTH-1:0] dram_addr;
logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_SET_INDEX_WIDTH + L1D_BANK_WAY_INDEX_WIDTH-1:0] dram_addr_ram;
logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_SET_INDEX_WIDTH + L1D_BANK_WAY_INDEX_WIDTH-1:0]dram_addr_by_way;
logic [L1D_BANK_SET_INDEX_WIDTH + L1D_BANK_WAY_INDEX_WIDTH-1:0] dram_addr_by_offset;

logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_wdat;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_wdat_tmp;
logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM-1:0] dram_wdat_way;

logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM-1:0] dram_rdat;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way0;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way1;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way2;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way3;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way_seg_realigned;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way_selected;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way_seg_realigned_offset0;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way_seg_realigned_offset1;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way_seg_realigned_offset2;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] dram_rdat_all_way_seg_realigned_offset3;
logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM-1:0] dram_wdat_ram;

logic [L1D_BANK_SET_INDEX_WIDTH-1:0] ls_pipe_l1d_st_req_idx;
logic [L1D_BANK_OFFSET_WIDTH-1:0   ] ls_pipe_l1d_st_req_offset;
logic [L1D_BANK_PADDR_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_tag;

//MLFB
logic plru_rd_en_mlfb_peek;
logic[L1D_BANK_SET_INDEX_WIDTH-1:0] plru_rd_idx_mlfb_peek;
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] plru_rd_dat_mlfb_peek;
logic[L1D_BANK_SET_INDEX_WIDTH-1:0] lst_rd_idx_mlfb_peek;
logic[L1D_BANK_SET_INDEX_WIDTH-1:0] lst_rd_idx_peek;
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] lst_rd_avail_way_mlfb_peek;
rrv64_l1d_lst_t lst_rd_dat_mlfb_peek;

logic[L1D_BANK_SET_INDEX_WIDTH-1:0] lst_rd_idx_s0_req;
rrv64_l1d_lst_t lst_rd_dat_s0_req;

logic mlfb_evict_valid;
logic mlfb_writeback_valid;
logic mlfb_evict_ready;
logic mlfb_evict_hsk;
rrv64_l1d_evict_req_t mlfb_evict_req;

// logic evict_valid_cache;
// logic evict_ready_cache;
// logic evict_hsk_cache;
// rrv64_l1d_evict_req_t evict_req;

logic refill_valid;
logic refill_ready;               // include bank pipe hazard and output arbiter hazard
logic refill_bank_internal_ready; // include bank pipe hazard
logic refill_hsk;                 // include bank pipe hazard and output arbiter hazard
logic refill_bank_internal_hsk;   // include bank pipe hazard
logic refill_hsk_with_ram_write; // include bank pipe hazard and output arbiter hazard, for refill that needs to write data ram
rrv64_l1d_refill_req_t refill_req;

logic [L1D_BANK_SET_INDEX_WIDTH -1:0] lst_check_set_idx;
logic [L1D_BANK_WAY_INDEX_WIDTH -1:0] lst_check_way_idx;
logic lst_check_valid;
logic lst_check_ready;

logic mlfb_mshr_dealloc_valid;
logic mlfb_mshr_dealloc_ready;
logic[N_MSHR_W-1:0] mlfb_mshr_dealloc_idx ;
logic[N_MSHR_W-1:0] mlfb_mshr_head_rd_idx ;
mshr_t                          mlfb_mshr_head_rd_mshr_entry;
logic                           mlfb_mshr_head_rd_mshr_entry_no_resp;
logic[N_MSHR_W-1:0] mlfb_mshr_head_pending_rd_idx;
mshr_t                          mlfb_mshr_head_pending_rd_mshr_entry;

// s1 tag compare
logic[L1D_BANK_PADDR_TAG_WIDTH-1:0] tag_used_to_compare;
logic[L1D_BANK_WAY_NUM-1:0] s1_tag_compare_result_per_way;
logic[L1D_BANK_WAY_NUM-1:0] s1_tag_compare_valid_per_way;
logic[L1D_BANK_WAY_NUM-1:0] s1_tag_compare_hit_per_way;
logic[L1D_BANK_WAY_NUM-1:0] s1_tag_compare_data_hit_permission_miss_per_way;
logic s1_tag_compare_hit;

// MSHR signals
logic                         mshr_we;
mshr_t [N_MSHR-1:0]           mshr_bank;
logic  [N_MSHR-1:0]           mshr_bank_valid;
logic  [N_MSHR-1:0]           mshr_bank_no_resp;
logic  [N_MSHR-1:0]           mshr_bank_sent;
mshr_t                        new_mshr;
logic                         new_mshr_valid;
logic [N_MSHR_W-1:0]    new_mshr_id;
logic                         has_free_mshr;
logic [N_MSHR_W:0]            free_mshr_num;

// ewrq
logic                      l1d_ewrq_new_ewrq_valid;
logic                      l1d_ewrq_new_writeback_valid;
logic [L1D_BANK_LINE_ADDR_SIZE-1:0] l1d_ewrq_new_ewrq_addr; // line address, no offset
logic [L1D_BANK_LINE_DATA_SIZE-1:0] l1d_ewrq_new_ewrq_dat;
rrv64_l1d_lst_req_t                 l1d_ewrq_new_ewrq_lst;
logic                      l1d_ewrq_new_ewrq_ready;

logic[N_EWRQ-1:0][L1D_BANK_LINE_ADDR_SIZE-1:0] ewrq_addr;
logic[N_EWRQ-1:0]                     ewrq_vld;

// lst
logic lst_mesi_wr_en_s0_req_vld;
logic[L1D_BANK_SET_INDEX_WIDTH-1:0] lst_mesi_wr_set_idx_s0_req;
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] lst_mesi_wr_way_idx_s0_req;
rrv64_l1d_lst_req_t lst_wr_dat_s0_req;

logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] s2_tag_compare_hit_way_idx;

// s3 ld resp to lsu
logic l1d_lsu_resp_valid;
logic l1d_lsu_resp_is_refill;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] l1d_lsu_resp_dat;
rrv64_l1d_req_type_dec_t            l1d_lsu_ld_req_type_dec;
logic [L1D_BANK_OFFSET_WIDTH-1:0]   l1d_lsu_resp_offset;
logic [ROB_TAG_WIDTH-1:0]  l1d_lsu_resp_rob_tag;
logic [PREG_TAG_WIDTH-1:0] l1d_lsu_resp_prd;

// hand shake
logic ls_pipe_l1d_ld_req_hsk;
logic ls_pipe_l1d_st_req_hsk;
logic ls_pipe_l1d_lr_req_hsk;
logic ls_pipe_l1d_sc_req_hsk;
logic ls_pipe_l1d_amo_req_hsk;
logic ptw_l1d_walk_req_hsk;
logic dtlb_l1d_resp_hsk;
logic s1_st_req_tag_hit;
logic s2_st_req_tag_hit;
logic s2_amo_req_tag_hit;
logic s1_ld_req_tag_hit;
logic s1_ptw_req_tag_hit;
logic s1_lr_req_tag_hit;
logic s1_sc_req_tag_hit;
logic s1_amo_req_tag_hit;
logic s1_st_req_tag_miss;
logic s2_st_req_tag_miss;
logic s1_ld_req_tag_miss;
logic s1_ptw_req_tag_miss;
logic s1_lr_req_tag_miss;
logic s1_sc_req_tag_miss;
logic s1_amo_req_tag_miss;
logic s1_req_tag_miss;
logic s2_req_tag_miss;
logic s1_data_ram_st_hit_wr_ready;

logic s1_st_req_tag_vld;
logic s1_ld_req_tag_vld;

logic            s2_sc_req_hit;
// fencei flush fsm
// make all dirty line into clean, write back dirty line
logic fencei_flush_hsk;
logic fencei_flush_rdy_internal;
l1d_bank_fencei_flush_state_t l1d_bank_fencei_flush_state_d, l1d_bank_fencei_flush_state_q;
logic l1d_bank_fencei_flush_state_d_ena;
logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] l1d_bank_fencei_flush_way_idx_ptr_d, l1d_bank_fencei_flush_way_idx_ptr_q;
logic l1d_bank_fencei_flush_way_idx_ptr_d_ena;
logic [L1D_BANK_SET_INDEX_WIDTH-1:0] l1d_bank_fencei_flush_set_idx_ptr_d, l1d_bank_fencei_flush_set_idx_ptr_q;
logic l1d_bank_fencei_flush_set_idx_ptr_d_ena;
logic in_fencei_flush;
logic in_fencei_flush_pending;
logic in_fencei_flush_s1;
logic in_fencei_flush_s2;
logic in_fencei_flush_s3;
logic in_fencei_flush_wait_ewrq_clean;
logic in_fencei_finish_flush;
logic next_way_idx_ptr_en;
logic next_set_idx_ptr_en;

// atomic alu
logic           amo_alu_data_vld;
l1d_amo_type_e  amo_type;
alu_minor_op_t  amo_alu_op;
logic           amo_alu_op_w;
logic           amo_alu_op_u;
logic[XLEN-1:0] amo_operand0;
logic[XLEN-1:0] amo_operand1_src_data;
logic[XLEN-1:0] amo_operand1;
logic[XLEN-1:0] amo_alu_result;
logic[XLEN-1:0] amo_result;
logic[L1D_BANK_OFFSET_WIDTH-1:0]   amo_req_offset;
logic[L1D_BANK_LINE_DATA_SIZE-1:0] amo_refill_data;
// logic[L1D_BANK_LINE_DATA_SIZE-1:0] s2_amo_refill_byte_enable;

// snoop ctrl
// during snoop transaction, stop l1d bank from receiving new st, ptw, ld req from core
logic in_snoop_trans_stall_core_s0_req;
logic in_snoop_trans_stall_refill;
// logic snp_l1d_bank_snp_s0_req_hsk;
// logic snp_l1d_bank_snp_s1_req_hsk;
// logic snp_l1d_bank_snp_s2_req_hsk;
logic [L1D_BANK_PADDR_TAG_WIDTH-1:0] snp_addr_tag;
logic [L1D_BANK_SET_INDEX_WIDTH-1:0] snp_addr_idx;


assign snp_addr_tag = snp_l1d_bank_snp_req_i.snp_req.snp_line_addr[L1D_STB_LINE_ADDR_SIZE-1 -: L1D_BANK_PADDR_TAG_WIDTH];
assign snp_addr_idx = snp_l1d_bank_snp_req_i.snp_req.snp_line_addr[L1D_BANK_ID_INDEX_WIDTH  +: L1D_BANK_SET_INDEX_WIDTH];

assign in_snoop_trans_stall_core_s0_req = (snp_l1d_bank_snp_s0_req_vld_i & snp_l1d_bank_snp_s0_req_rdy_o) |
                                          (snp_l1d_bank_snp_s1_req_vld_i & snp_l1d_bank_snp_s1_req_rdy_o) |
                                          (snp_l1d_bank_snp_s2_req_vld_i & snp_l1d_bank_snp_s2_req_rdy_o) |
                                          snp_l1d_bank_snp_s3_req_vld_i;

assign in_snoop_trans_stall_refill      = snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_i |
                                          snp_l1d_bank_snp_s1_req_vld_i |
                                          snp_l1d_bank_snp_s2_req_vld_i;

  // snp s0
assign snp_l1d_bank_snp_s0_req_rdy_o  = 1'b1; // not used, reserve for stall snoop transaction

assign snp_l1d_bank_snp_s0_o.s1_st_req_tag_hit = s1_st_req_tag_hit; // s0_1
assign snp_l1d_bank_snp_s0_o.s2_st_req_tag_hit = s2_st_req_tag_hit; // s0_1
assign snp_l1d_bank_snp_s0_o.s1_valid          = s1_valid;          // s0_2 pipeline s1 vld
assign snp_l1d_bank_snp_s0_o.s2_valid          = s2_valid;          // s0_2 pipeline s2 vld
assign snp_l1d_bank_snp_s0_o.cur               = cur;               // s0_2 pipeline
assign snp_l1d_bank_snp_s0_o.s1_tag_used_to_compare = tag_used_to_compare; // s0_2 pipeline for vipt s1 ptag
assign snp_l1d_bank_snp_s0_o.mshr_bank_valid   = mshr_bank_valid;   // s0_2 mshr vld
assign snp_l1d_bank_snp_s0_o.mshr_bank_sent    = mshr_bank_sent;    // s0_2 mshr sent
assign snp_l1d_bank_snp_s0_o.mshr_bank         = mshr_bank;         // s0_2 mshr
assign snp_l1d_bank_snp_s0_o.ewrq_vld          = ewrq_vld;          // s0_2 ewrq
assign snp_l1d_bank_snp_s0_o.ewrq_addr         = ewrq_addr;         // s0_2 addr

  // snp s1
assign snp_l1d_bank_snp_s1_req_rdy_o  = 1'b1; // not used, reserve for stall snoop transaction

assign snp_l1d_bank_snp_s1_o.lst_dat  =  lst_rd_dat_s0_req;

  // snp s2
assign snp_l1d_bank_snp_s2_req_rdy_o  = 1'b1; // not used, reserve for stall snoop transaction

assign snp_l1d_bank_snp_s2_o.tag_compare_result_per_way = s1_tag_compare_result_per_way;

  // snp s3
assign snp_l1d_bank_snp_s3_req_line_data_o = dram_rdat_all_way_selected;

// to tag ram
genvar waynum;
generate
  for(waynum = 0; waynum < L1D_BANK_WAY_NUM; waynum++) begin: gen_tag_ram_ctrl_signal
    assign tram_cs  [waynum] = cache_rd_tram_way_en[waynum] | cache_wr_tram_way_en[waynum];
    assign tram_wen [waynum] = cache_wr_tram_way_en[waynum];
    assign tram_addr[waynum] = cache_idx_tram;
    assign tram_wdat[waynum] = cache_wr_dat_tram;
  end
endgenerate

`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rst) (((|cache_rd_tram_way_en) & (|cache_wr_tram_way_en))== '0))
    else $fatal("l1d bank: tag ram read and write at the same time");
`endif

// --- tag --- //
// tag ram generate
generate
  for(waynum = 0; waynum < L1D_BANK_WAY_NUM; waynum++) begin: gen_tag_ram
    generic_spram
    #(
      .w(L1D_BANK_TAG_RAM_WORD_WIDTH),
      .p(L1D_BANK_TAG_RAM_WORD_WIDTH),
      .d(L1D_BANK_SET_NUM),
      .log2d($clog2(L1D_BANK_SET_NUM)),
      .id(1),

      .RAM_LATENCY(1),
      .RESET      (1),
      .RESET_HIGH (0)
    )
    U_TAG_RAM
    (
      .clk (clk),//clock
      .ce (tram_cs[waynum]),//chip enable,low active
      .we (tram_wen[waynum]),//write enable,low active
      .addr (tram_addr[waynum]),//address
      .din (tram_wdat[waynum]),//data in
      .dout (tram_rdat[waynum]),//data out
      .biten ('1)
//      .biten (tram_wen_biten[waynum])
    );
  end
endgenerate

`ifndef SYNTHESIS
logic data_ram_wrtie_given_idx_and_way;
logic data_ram_read_given_idx;
always_comb begin
  data_ram_wrtie_given_idx_and_way = '0;
  data_ram_read_given_idx = '0;
  for(int i = 0; i < L1D_BANK_WAY_NUM; i++) begin
    if(tram_cs[i]) begin
      if(tram_addr[i] == 'h6) begin
        data_ram_read_given_idx = 1'b1;
        if(tram_wen[i] && (i == 3)) begin
          data_ram_wrtie_given_idx_and_way = 1'b1;
        end
      end
    end
  end
end
`endif

// --- data --- //
  // to data ram

//{set_idx,line_seg=0} : way0_seg0 way1_seg0 way2_seg0 way3_seg0
//{set_idx,line_seg=l} : way3_seg1 way0_seg1 way1_seg1 way2_seg1
//{set_idx,line_seg=2} : way2_seg2 way3_seg2 way0_seg2 way1_seg2
//{set_idx,line seg=3} : way1_seg3 way2_seg3 way3_seg3 way0_seg3

// wr byte enable gen
logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8-1:0] ls_pipe_l1d_st_req_data_byte_mask_per_seg;
generate
if(L1D_OFFSET_BIT_DIFF_STB_SEG > 0) begin
  logic [L1D_OFFSET_BIT_DIFF_STB_SEG-1:0] offset_bit_diff_stb_seg;
  logic [L1D_BANK_LINE_DATA_SIZE/8-1:0] ls_pipe_l1d_st_req_data_byte_mask_whole_line;

  assign offset_bit_diff_stb_seg = cur.s2.ls_pipe_l1d_req_offset[L1D_BANK_OFFSET_WIDTH-1-:L1D_OFFSET_BIT_DIFF_STB_SEG];
  always_comb begin:ls_pipe_l1d_st_req_data_byte_mask_whole_line_gen
      ls_pipe_l1d_st_req_data_byte_mask_whole_line = '0;
      ls_pipe_l1d_st_req_data_byte_mask_whole_line[offset_bit_diff_stb_seg*(L1D_STB_DATA_WIDTH/8)+:(L1D_STB_DATA_WIDTH/8)] = refill_hsk_with_ram_write ? refill_req.dat_byte_mask : 
                                                                                                                                                         cur.s2.ls_pipe_l1d_st_req_dat_byte_mask;
      for(int i = 0; i < L1D_BANK_WAY_NUM; i++) begin
          ls_pipe_l1d_st_req_data_byte_mask_per_seg[i] = ls_pipe_l1d_st_req_data_byte_mask_whole_line[(i*(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8))+:(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8)];
      end
  end
end else begin
  logic [L1D_BANK_LINE_DATA_SIZE/8-1:0] ls_pipe_l1d_st_req_data_byte_mask_whole_line;

  always_comb begin:ls_pipe_l1d_st_req_data_byte_mask_whole_line_gen
      ls_pipe_l1d_st_req_data_byte_mask_whole_line = refill_hsk_with_ram_write ? refill_req.dat_byte_mask : 
                                                                                 cur.s2.ls_pipe_l1d_st_req_dat_byte_mask;
      for(int i = 0; i < L1D_BANK_WAY_NUM; i++) begin
          ls_pipe_l1d_st_req_data_byte_mask_per_seg[i] = ls_pipe_l1d_st_req_data_byte_mask_whole_line[(i*(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8))+:(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8)];
      end
  end
end
endgenerate

// data ram access
assign dram_cs = (cache_way_en_dram & {L1D_BANK_WAY_NUM{cache_wr_valid_dram }}) | {L1D_BANK_WAY_NUM{cache_rd_valid_dram }};
`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rst) ((cache_wr_valid_dram & cache_rd_valid_dram)== '0))
    else $fatal("l1d bank: data ram read and write at the same time");
`endif
assign dram_wen = dram_wen_way; // lsu st wr a single way
assign dram_addr = cache_idx_dram;
assign dram_addr_by_offset = {dram_addr,cache_offset_dram[5:4]};

//assign dram_wdat_tmp[XLEN-1:0] = cur.s1.ls_pipe_l1d_st_req_dat;
//assign dram_wdat = dram_wdat_tmp << (cur.s1.ls_pipe_l1d_req_offset * 8);
assign dram_wdat    = amo_alu_data_vld          ? amo_refill_data :
                      refill_hsk_with_ram_write ? refill_req.dat     :
                                                  cur.s2.line_data;
assign st_dat_biten = cur.s2.ls_pipe_l1d_st_req_dat_byte_mask;
//assign st_dat_biten   = cur.s1.req_type_dec.op_b  ? {{(XLEN/8-1){1'b0}}, 1'b1}  :
//                        cur.s1.req_type_dec.op_hw ? {{(XLEN/8-2){1'b0}}, 2'b11} :
//                        cur.s1.req_type_dec.op_w  ? {{(XLEN/8-4){1'b0}}, 4'b1111} :
//                        cur.s1.req_type_dec.op_dw ? {{(XLEN/8-8){1'b0}}, 8'b11111111} : '0;
assign dram_wen_biten_tmp = refill_hsk_with_ram_write ? '1 : (st_dat_biten << cur.s1.ls_pipe_l1d_req_offset[$clog2(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8)-1:0]);
// assign dram line seg idx=cache_line_seg dram;
generate
  genvar jj;
  for(jj=0; jj<L1D_BANK_WAY_NUM; jj++) begin:DATA_RAM_SIGNAL_GEN
    assign cache_way_en_dram[jj] = cache_way_en_dram_seg[jj];
    assign dram_wen_way[jj] = cache_wr_valid_dram & cache_way_en_dram[jj];
    assign dram_wen_biten[jj] = cache_way_byte_en_dram_seg[jj];
//    assign dram_wen_all[jj] = cache_wr_valid_dram ;
    if(jj==0) begin
      assign cache_way_byte_en_dram_seg[jj] = {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b00)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[0]) |
                                              {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b11)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[1]) |
                                              {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b10)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[2]) |         
                                              {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b01)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[3]) ;

      assign dram_wdat_way[jj] = (cache_way_idx_dram == 2'b00) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0 +: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                 (cache_way_idx_dram == 2'b01) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3 +: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                 (cache_way_idx_dram == 2'b10) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2 +: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                                                 dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1 +: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)];
      assign dram_addr_by_way [jj]= {(L1D_BANK_SET_INDEX_WIDTH+2){(cache_way_idx_dram == 2'b00)}} & {dram_addr,2'b00} |
                                    {(L1D_BANK_SET_INDEX_WIDTH+2){(cache_way_idx_dram == 2'b01)}} & {dram_addr,2'b11} |
                                    {(L1D_BANK_SET_INDEX_WIDTH+2){(cache_way_idx_dram == 2'b10)}} & {dram_addr,2'b10} |
                                    {(L1D_BANK_SET_INDEX_WIDTH+2){(cache_way_idx_dram == 2'b11)}} & {dram_addr,2'b01} ; 
    end
    if(jj==1) begin
      assign cache_way_byte_en_dram_seg[jj]  = {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b00)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[1]) |
                                          {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b11)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[2]) |
                                          {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b10)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[3]) | 
                                          {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b01)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[0]) ;
      assign dram_wdat_way[jj]  = (cache_way_idx_dram == 2'b00) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                  (cache_way_idx_dram == 2'b01) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                  (cache_way_idx_dram == 2'b10) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                                                  dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)];
      assign dram_addr_by_way [jj]= {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b00)}} & {dram_addr,2'b01} |
                                    {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b01)}} & {dram_addr,2'b00} |
                                    {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b10)}} & {dram_addr,2'b11} |
                                    {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b11)}} & {dram_addr,2'b10};
    end
    if(jj==2) begin
      assign cache_way_byte_en_dram_seg[jj]  = {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b00)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[2]) |
                                          {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b11)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[3]) |
                                          {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b10)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[0]) |
                                          {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b01)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[1]);
      assign dram_wdat_way[jj] = (cache_way_idx_dram == 2'b00) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                 (cache_way_idx_dram == 2'b01) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                 (cache_way_idx_dram == 2'b10) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                                                 dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)];
      assign dram_addr_by_way [jj]= {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b00)}} & {dram_addr,2'b10} |
                                    {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b01)}} & {dram_addr,2'b01} |
                                    {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b10)}} & {dram_addr,2'b00} |
                                    {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b11)}} & {dram_addr,2'b11} ;
    end
    if(jj==3) begin
      assign cache_way_byte_en_dram_seg[jj] = {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b00)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[3]) |
                                         {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b11)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[0]) |
                                         {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b10)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[1]) |
                                         {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM/8){(cache_way_idx_dram == 2'b01)}} & (ls_pipe_l1d_st_req_data_byte_mask_per_seg[2]);
      assign dram_wdat_way[jj] = (cache_way_idx_dram == 2'b00) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                 (cache_way_idx_dram == 2'b01) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                 (cache_way_idx_dram == 2'b10) ? dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)]:
                                                                 dram_wdat[(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)];
      assign dram_addr_by_way [jj] = {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b00)}} & {dram_addr,2'b11} |
                                     {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b01)}} & {dram_addr,2'b10} |
                                     {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b10)}} & {dram_addr,2'b01} |
                                     {(L1D_BANK_SET_INDEX_WIDTH + 2){(cache_way_idx_dram == 2'b11)}} & {dram_addr,2'b00} ;
    end

    assign dram_addr_ram[jj]  = (cache_rd_valid_dram & ~mlfb_evict_hsk & ~in_fencei_flush_s2 & ~snp_l1d_bank_snp_s2_req_hsk_i) ? dram_addr_by_offset : dram_addr_by_way[jj];
    assign dram_wdat_ram[jj]  = dram_wdat_way[jj];
    assign cache_way_en_dram_seg[jj] = |cache_way_byte_en_dram_seg[jj];
//    assign dram_wen_biten[jj] = {(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM){dram_wen[jj]}};


    if(jj==0) begin
      assign dram_rdat_all_way0 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat[jj];
      assign dram_rdat_all_way1 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat[jj];
      assign dram_rdat_all_way2 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat[jj];
      assign dram_rdat_all_way3 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat[jj];
      assign dram_rdat_all_way_seg_realigned_offset0 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset1 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset2 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset3 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
    end
    if(jj==1) begin
      assign dram_rdat_all_way0 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat[jj];
      assign dram_rdat_all_way1 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat[jj];
      assign dram_rdat_all_way2 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat[jj];
      assign dram_rdat_all_way3 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat[jj];
      assign dram_rdat_all_way_seg_realigned_offset0 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset1 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset2 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset3 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
    end
    if(jj==2) begin
      assign dram_rdat_all_way0 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way1 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way2 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way3 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset0 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset1 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset2 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset3 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
    end
    if(jj==3) begin
      assign dram_rdat_all_way0 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way1 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way2 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way3 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset0 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 3+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset1 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 2+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset2 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 1+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
      assign dram_rdat_all_way_seg_realigned_offset3 [(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM) * 0+: (L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM)] =dram_rdat [jj];
    end
  end
endgenerate

// data ram generate
generate
  for(waynum = 0; waynum < L1D_BANK_WAY_NUM; waynum++) begin: DATA_RAM_GEN
    generic_spram
    #(
      .w(L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM),//128
      .p(8),
      .d(L1D_BANK_SET_NUM*L1D_BANK_WAY_NUM), // 256
      .log2d($clog2(L1D_BANK_SET_NUM*L1D_BANK_WAY_NUM)), // 8
      .id(0),

      .RAM_LATENCY(1),
      .RESET      (1),
      .RESET_HIGH (0)
    )
    U_DATA_RAM
    (
      .clk (clk),//clock
      .ce (dram_cs[waynum]),//chip enable,low active
      .we (dram_wen[waynum]),//write enable,low active
      .addr (dram_addr_ram[waynum]),//address
      .din (dram_wdat_ram[waynum]),//data in
      .dout (dram_rdat[waynum]),//data out
      .biten (dram_wen_biten[waynum]) // byte enable
    );
  end
endgenerate


// ------- pipe logic --------- // 

//--- stage 0 ---//
// 1. load : data ram read:
//                given idx and offset, read all way with certain offset
//           tag ram read:
//                given idx, read all way
//           lst reg read:
//                given idx, read all way state
// 2. store: tag ram read:
//                given idx, read all way
//           lst reg read:
//                given idx, read all way state
// 3. evict: tag ram read:
//                given idx and way id, read single way
//           data ram read:
//                given idx and way id, read single way


// req decode
rvh_l1d_dec l1dc_dec_u
(
  // ld has higher priority
    // .is_ld_req_vld_i        (ls_pipe_l1d_ld_req_vld_i   ), 
    // .is_st_req_vld_i        (~ls_pipe_l1d_ld_req_vld_i & ls_pipe_l1d_st_req_vld_i),  
  // st has higher priority
    .is_ld_req_vld_i        (~ls_pipe_l1d_st_req_vld_i & ~ptw_walk_req_vld_i & ls_pipe_l1d_ld_req_vld_i   ),
    .is_st_req_vld_i        (ls_pipe_l1d_st_req_vld_i),
    .is_ptw_req_vld_i       (~ls_pipe_l1d_st_req_vld_i & ptw_walk_req_vld_i),
    .ls_pipe_l1d_ld_req_opcode_i (ls_pipe_l1d_ld_req_opcode_i),
    .ls_pipe_l1d_st_req_opcode_i (ls_pipe_l1d_st_req_opcode_i),
    .req_type_dec_o         (req_type_dec)
);

logic [L1D_BANK_SET_INDEX_WIDTH-1:0] ls_pipe_l1d_req_idx;
logic [N_MSHR-1:0] ls_pipe_l1d_req_idx_haz_in_mshr_per_entry;
logic [N_EWRQ-1:0] ls_pipe_l1d_req_idx_haz_in_ewrq_per_entry;
logic ls_pipe_l1d_req_idx_haz_in_mshr;
logic ls_pipe_l1d_req_idx_haz_in_ewrq;
logic ls_pipe_l1d_req_idx_haz_in_pipe;
logic ls_pipe_l1d_req_idx_haz_in_pipe_s2;

assign ls_pipe_l1d_req_idx_cmp_in_pipe_s2 = (ls_pipe_l1d_req_idx == cur.s2.ls_pipe_l1d_req_idx);

assign ls_pipe_l1d_req_idx =  ls_pipe_l1d_st_req_vld_i   ? ls_pipe_l1d_st_req_paddr_i[L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH] :
                              ptw_walk_req_vld_i         ? ptw_walk_req_addr_i[L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH] :
                                                           ls_pipe_l1d_ld_req_idx_i;     // ls_pipe_l1d_ld_req_vld_i   ? ls_pipe_l1d_ld_req_idx_i :
assign ls_pipe_l1d_req_idx_haz_in_pipe = (ls_pipe_l1d_ld_req_vld_i | ls_pipe_l1d_st_req_vld_i | ptw_walk_req_vld_i) &
                                         ((((s1_ld_req_tag_miss | s1_ptw_req_tag_miss) | (s1_valid & cur.s1.req_type_dec.is_st & ~cur.s1.is_evict)) &
                                         (ls_pipe_l1d_req_idx == cur.s1.ls_pipe_l1d_req_idx)) |
                                         (s2_req_tag_miss &
                                         ls_pipe_l1d_req_idx_cmp_in_pipe_s2));  
                                          
genvar i;
generate
  for(i = 0; i < N_MSHR; i++) begin: gen_ls_pipe_l1d_req_idx_haz_in_mshr_per_entry
      assign ls_pipe_l1d_req_idx_haz_in_mshr_per_entry[i] = mshr_bank_valid[i] & 
                                                            (ls_pipe_l1d_req_idx == mshr_bank[i].bank_index);
  end
  for(i = 0; i < N_EWRQ; i++) begin: gen_ls_pipe_l1d_req_idx_haz_in_ewrq_per_entry
      assign ls_pipe_l1d_req_idx_haz_in_ewrq_per_entry[i] = ewrq_vld[i] &
                                                            (ls_pipe_l1d_req_idx == ewrq_addr[i][L1D_BANK_SET_INDEX_WIDTH-1:0]);
  end
endgenerate

assign ls_pipe_l1d_req_idx_haz_in_mshr = (|ls_pipe_l1d_req_idx_haz_in_mshr_per_entry) & (ls_pipe_l1d_ld_req_vld_i | ls_pipe_l1d_st_req_vld_i);
assign ls_pipe_l1d_req_idx_haz_in_ewrq = (|ls_pipe_l1d_req_idx_haz_in_ewrq_per_entry) & (ls_pipe_l1d_ld_req_vld_i | ls_pipe_l1d_st_req_vld_i);

// lsu ld
 // s0 ld need to rd tag, data ram
assign ls_pipe_l1d_ld_req_rdy_o = ~s1_stall &
                                  ~ls_pipe_l1d_st_req_vld_i &         // lsu st has higher priority
                                  ~ptw_walk_req_vld_i &               // ptw walk has higher priority
                                  ~s2_st_req_tag_hit &                // if cur.s2 is a store hit, it need to write data ram at its s2
                                  ~s2_amo_req_tag_hit &               // if cur.s2 is a amo hit, it need to write data ram at its s2
                                  ~s2_sc_req_hit &                    // if cur.s2 is a sc hit, it need to write data ram at its s2
                                  ~mlfb_evict_hsk &                   // evict has higher priority
                                  ~refill_valid &                     // refill has highest priority
                                  ~ls_pipe_l1d_req_idx_haz_in_pipe &  // same idx miss at s1 and s2
                                  ~ls_pipe_l1d_req_idx_haz_in_mshr &  // same idx in mshr
                                  ~ls_pipe_l1d_req_idx_haz_in_ewrq &  // same idx in ewrq
                                  ~rob_flush_i &                      // rob flush, kill load req in pipeline
                                  ~in_fencei_flush &                  // in fencei state, block l1d
                                  ~in_snoop_trans_stall_core_s0_req;  // during snoop transaction, stop l1d bank from receiving new st, ptw, ld req from core
assign ls_pipe_l1d_ld_req_hsk   = ls_pipe_l1d_ld_req_vld_i & ls_pipe_l1d_ld_req_rdy_o
                                                           & stb_l1d_ld_rdy_i;    // stb ld also need to be ready

// stb st
  // s0 st need to rd tag ram
assign ls_pipe_l1d_st_req_rdy_o = ~s1_stall &
                                  // ~ls_pipe_l1d_ld_req_vld_i &           // lsu ld has higher priority
                                  // ~ptw_walk_req_vld_i &                 // ptw walk has higher priority
                                  ~mlfb_evict_hsk &                     // evict has higher priority
                                  ~refill_valid &                       // refill has highest priority
                                  ~ls_pipe_l1d_req_idx_haz_in_pipe &    // same idx miss at s1 and s2
                                  ~ls_pipe_l1d_req_idx_haz_in_mshr &    // same idx in mshr
                                  ~ls_pipe_l1d_req_idx_haz_in_ewrq &    // same idx in ewrq
                                  ~(  ~has_free_mshr | 
                                      ((free_mshr_num == 1) & (s1_req_tag_miss | s2_req_tag_miss)) | 
                                      ((free_mshr_num == 2) & (s1_req_tag_miss & s2_req_tag_miss)) // if no mshr or there is going to be no mshr, stall st
                                  ) &
                                  ~in_fencei_flush &                    // in fencei state, block l1d
                                  ~in_snoop_trans_stall_core_s0_req;    // during snoop transaction, stop l1d bank from receiving new st, ptw, ld req from core

assign ls_pipe_l1d_st_req_hsk   = ls_pipe_l1d_st_req_vld_i & ls_pipe_l1d_st_req_rdy_o;

// lr
assign ls_pipe_l1d_lr_req_hsk  = ls_pipe_l1d_st_req_hsk & req_type_dec.is_lr;
// sc
assign ls_pipe_l1d_sc_req_hsk  = ls_pipe_l1d_st_req_hsk & req_type_dec.is_sc;
// atomic
assign ls_pipe_l1d_amo_req_hsk = ls_pipe_l1d_st_req_hsk & req_type_dec.is_amo;

// ptw walk
  // s0 ld need to rd tag, data ram
assign ptw_walk_req_rdy_o = ~s1_stall &
                            ~ls_pipe_l1d_st_req_vld_i &           // lsu st has higher priority
                            ~s2_st_req_tag_hit &                  // if cur.s2 is a store hit, it need to write data ram at its s2
                            ~s2_amo_req_tag_hit &               // if cur.s2 is a amo hit, it need to write data ram at its s2
                            ~s2_sc_req_hit &                    // if cur.s2 is a sc hit, it need to write data ram at its s2
                            ~mlfb_evict_hsk &                     // evict has higher priority
                            ~refill_valid &                       // refill has highest priority
                            ~ls_pipe_l1d_req_idx_haz_in_pipe &    // same idx miss at s1 and s2
                            ~ls_pipe_l1d_req_idx_haz_in_mshr &    // same idx in mshr
                            ~ls_pipe_l1d_req_idx_haz_in_ewrq &    // same idx in ewrq
                            ~(  ~has_free_mshr | 
                                      ((free_mshr_num == 1) & (s1_req_tag_miss | s2_req_tag_miss)) | 
                                      ((free_mshr_num == 2) & (s1_req_tag_miss & s2_req_tag_miss)) // if no mshr or there is going to be no mshr, stall ptw ld
                            ) &
                            ~in_fencei_flush &                    // in fencei state, block l1d
                            ~in_snoop_trans_stall_core_s0_req;    // during snoop transaction, stop l1d bank from receiving new st, ptw, ld req from core

assign ptw_l1d_walk_req_hsk = ptw_walk_req_vld_i & ptw_walk_req_rdy_o
                                                 & stb_l1d_ptw_walk_req_rdy_i;  // stb ptw also need to be ready

// mlfb evict
assign mlfb_evict_ready = ~s1_stall &
                          ~(s1_valid & cur.s1.is_evict |
                            // s2_valid & cur.s2.is_evict |
                            s2_st_req_tag_hit          | // if s2 is a store hit, let it write data ram first
                            s2_amo_req_tag_hit         | // if cur.s2 is a amo hit, it need to write data ram at its s2
                            s2_sc_req_hit              | // if cur.s2 is a sc hit, it need to write data ram at its s2
                            refill_hsk                 | // refill has highest priority
                            ~l1d_ewrq_new_ewrq_ready) ;  // ewrq is full
assign mlfb_evict_hsk = (mlfb_evict_valid | mlfb_writeback_valid) & mlfb_evict_ready;

// mlfb refill
assign refill_bank_internal_ready = ~(s2_valid & (cur.s2.req_type_dec.is_ld|cur.s2.req_type_dec.is_ptw_ld) & cur.s2.tag_compare_hit) & // if s2 is a load/ptw hit and is about to resp, wait for 1 cycle
                                    ~(stb_l1d_bank_ld_bypass_valid_i) & (      // if a stb load bypass comes and is about to resp, wait for 1 cycle
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
                                    refill_req.ld_no_refill |                  // if refill no refill, no data ram write
`endif
                                    (~s2_st_req_tag_hit &                      // if s2 is a store hit need to write data ram, wait for 1 cycle
                                    ~s2_amo_req_tag_hit &                      // if cur.s2 is a amo hit, it need to write data ram at its s2
                                    ~s2_sc_req_hit));                          // if cur.s2 is a sc hit, it need to write data ram at its s2
assign refill_ready               = refill_bank_internal_ready &
                                    ~(refill_valid & refill_req.is_ld & ~refill_req.ld_no_resp & ~l1d_int_prf_wb_rdy_from_mlfb_i) & // if the resp is from mlfb but the resp arbiter is not ready, hold the refill. for load hit, there is no such stall condition
                                    ~(refill_valid & refill_req.req_type_dec.is_ptw_ld & ~ptw_walk_resp_rdy_i); // if the resp is from mlfb but the ptw resp arbiter is not ready, hold the refill.
                                    // ~in_snoop_trans_stall_core_s0_req;  // snp has higher priority over refill
assign refill_bank_internal_hsk   = refill_valid & refill_bank_internal_ready;
assign refill_hsk                 = refill_valid & refill_ready;
`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
assign refill_hsk_with_ram_write = refill_hsk & ~refill_req.ld_no_refill;
`else
assign refill_hsk_with_ram_write = refill_hsk;
`endif

// fencei flush
  // can start fencei flush when the cache bank has no on fly req
assign fencei_flush_rdy_internal  = ~s1_valid & ~s2_valid & ~(|mshr_bank_valid);
assign fencei_flush_hsk           = (fencei_flush_vld_i | in_fencei_flush_pending) & fencei_flush_rdy_internal;

// lst reg access
  // lsu ld,st rd
assign lst_rd_idx_s0_req = cache_idx_tram; // for s0 load/store lst access, idx is he same as tag ram access

// tag ram access
  // rd
assign cache_rd_valid_tram = mlfb_evict_hsk         | // mlfb evict rd tag
                             ls_pipe_l1d_ld_req_hsk | // lsu ld s0 rd tag
                             ls_pipe_l1d_st_req_hsk | // lsu st s0 rd tag
                             ptw_l1d_walk_req_hsk   | // mmu ptw s0 rd tag
                             in_fencei_flush_s2       // fencei flush s2: read dirty data line tag
                            ;

assign ls_pipe_l1d_st_req_idx    = ls_pipe_l1d_st_req_paddr_i[L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH];
assign ls_pipe_l1d_st_req_offset = (req_type_dec.is_lr | req_type_dec.is_amo) ? ls_pipe_l1d_st_req_sc_amo_offset_i : ls_pipe_l1d_st_req_paddr_i[L1D_BANK_OFFSET_WIDTH-1:0];
assign ls_pipe_l1d_st_req_tag    = ls_pipe_l1d_st_req_paddr_i[PADDR_WIDTH-1:L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH];

assign cache_idx_tram      = refill_hsk_with_ram_write      ? refill_req.set_idx          :
                             mlfb_evict_hsk                 ? mlfb_evict_req.set_idx      :
                             ls_pipe_l1d_ld_req_hsk         ? ls_pipe_l1d_ld_req_idx_i    : 
                             ptw_l1d_walk_req_hsk           ? ptw_walk_req_addr_i[L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH] :
                             in_fencei_flush_s2             ? l1d_bank_fencei_flush_set_idx_ptr_q : // fencei flush s2: read dirty data line tag
                             snp_l1d_bank_snp_s1_req_hsk_i  ? snp_addr_idx                :
                                                              ls_pipe_l1d_st_req_idx; // default: st, lr, sc, amo
// assign cache_offset_tram   = mlfb_evict_hsk         ? '0                          :
//                              ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_offset_i : 
//                              ptw_l1d_walk_req_hsk   ? ptw_walk_req_addr_i[L1D_BANK_OFFSET_WIDTH-1:0] :
//                              in_fencei_flush_s2     ? '0                            : // fencei flush s2: read dirty data line tag
//                                                       ls_pipe_l1d_st_req_offset;


generate
    for(waynum = 0; waynum < L1D_BANK_WAY_NUM; waynum++) begin
        assign cache_rd_tram_way_en[waynum] = mlfb_evict_hsk                ? (waynum == mlfb_evict_req.way_idx)    :
                                              ls_pipe_l1d_ld_req_hsk        ? '1                                    :
                                              ls_pipe_l1d_st_req_hsk        ? '1                                    :
                                              ptw_l1d_walk_req_hsk          ? '1                                    :
                                              in_fencei_flush_s2            ? (waynum == l1d_bank_fencei_flush_way_idx_ptr_q) :
                                              snp_l1d_bank_snp_s1_req_hsk_i ? '1                                    :
                                                                            '0;
    end
endgenerate

  //wr
assign cache_wr_valid_tram = refill_hsk_with_ram_write;
generate
  for(waynum = 0; waynum < L1D_BANK_WAY_NUM; waynum++) begin
    assign cache_wr_tram_way_en[waynum] = refill_hsk_with_ram_write ? (waynum == refill_req.way_idx)    :
                                                                      '0;
  end
endgenerate
assign cache_wr_dat_tram = refill_req.tag;

// data ram access
  // rd
assign cache_rd_valid_dram = (mlfb_evict_hsk & mlfb_writeback_valid) | // mlfb writeback rd data
                             ls_pipe_l1d_ld_req_hsk  | // lsu ld s0 rd data
                             ptw_l1d_walk_req_hsk    | // mmu ptw s0 rd data
                             in_fencei_flush_s2      | // fencei flush s2: read dirty data line
                             ls_pipe_l1d_lr_req_hsk  | // load reserve s0 rd data
                             ls_pipe_l1d_amo_req_hsk | // atomic s0 rd data
                             snp_l1d_bank_snp_s2_req_hsk_i & snp_l1d_bank_snp_s2_req_data_ram_rd_vld_i; // snoop ctrl s2 read data ram
  // wr
assign cache_wr_valid_dram = refill_hsk_with_ram_write |         // mlfb refill wr data;
                             s2_st_req_tag_hit  | // stb st s2 wr data;
                             s2_amo_req_tag_hit | // amo st s2 wr data
                             s2_sc_req_hit ;      // sc write s2


  // addr
assign cache_idx_dram      = refill_hsk_with_ram_write ? refill_req.set_idx            :   // mlfb refill wr data
                             mlfb_evict_hsk         ? mlfb_evict_req.set_idx        :   // mlfb evict s0 rd data
                             ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_idx_i      :   // lsu ld s0 rd data
                             ptw_l1d_walk_req_hsk   ? ptw_walk_req_addr_i[L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH] : // mmu ptw s0 rd data
                             in_fencei_flush_s2     ? l1d_bank_fencei_flush_set_idx_ptr_q : // fencei flush s2: read dirty data line
                             (ls_pipe_l1d_lr_req_hsk | ls_pipe_l1d_amo_req_hsk) ? ls_pipe_l1d_st_req_idx : // lr, amo use st req port, rd data at s0
                             snp_l1d_bank_snp_s2_req_hsk_i ? snp_addr_idx           :       // snoop ctrl s2 read data ram
                                                      cur.s2.ls_pipe_l1d_req_idx;      // lsu st s2 wr data

assign cache_offset_dram   = refill_hsk_with_ram_write ? '0                            :   // mlfb refill wr data
                             mlfb_evict_hsk         ? '0                            :   // mlfb evict s0 rd data
                             ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_offset_i   :   // lsu ld s0 rd data
                             ptw_l1d_walk_req_hsk   ? ptw_walk_req_addr_i[L1D_BANK_OFFSET_WIDTH-1:0] : // mmu ptw s0 rd data
                             in_fencei_flush_s2     ? '0                            : // fencei flush s2: read dirty data line
                             (ls_pipe_l1d_lr_req_hsk | ls_pipe_l1d_amo_req_hsk) ? ls_pipe_l1d_st_req_offset : // lr, amo use st req port, rd data at s0
                             snp_l1d_bank_snp_s2_req_hsk_i ? '0                     : // snoop ctrl s2 read data ram
                                                      cur.s2.ls_pipe_l1d_req_offset;    // lsu st s2 wr data

assign cache_way_idx_dram  = refill_hsk_with_ram_write      ? refill_req.way_idx        :
                             mlfb_evict_hsk                 ? mlfb_evict_req.way_idx    :
                             in_fencei_flush_s2             ? l1d_bank_fencei_flush_way_idx_ptr_q : // fencei flush s2: read dirty data line
                             snp_l1d_bank_snp_s2_req_hsk_i  ? snp_l1d_bank_snp_s2_req_way_id_i : // snoop ctrl s2 read data ram
                                                              s2_tag_compare_hit_way_idx;

//--- stage 1 ---//
// 1. lsu load:
//   1.1 tlb hit: 
//     1.1.1 compare tag ram output with tlb physical tag
//       1.1.1.1 if hit: resp to lsu at s1
//       1.1.1.2 if miss: miss req goes into mshr
//   1.2 tlb miss:
//     1.2.1 kill the lsu ld req

// tag compare
logic ld_tlb_hit;

    // lsu ld gets tag for tlb at s1
logic[L1D_BANK_PADDR_TAG_WIDTH-1:0] paddr_tag_from_tlb;
// logic[L1D_BANK_PADDR_TAG_WIDTH-1:0] dtlb_l1d_resp_ppn;

assign dtlb_l1d_resp_rdy_o  = '1; // TODO: not used
assign dtlb_l1d_resp_hsk    = dtlb_l1d_resp_vld_i & dtlb_l1d_resp_rdy_o;

// assign dtlb_l1d_resp_ppn = dtlb_l1d_resp_ppn_i[L1D_BANK_PADDR_TAG_WIDTH-1:0];
generate
  if(L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH >= 12) begin
    assign paddr_tag_from_tlb = dtlb_l1d_resp_ppn_i[PPN_WIDTH-1:((L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH)-12)];
  end else begin
    assign paddr_tag_from_tlb = {dtlb_l1d_resp_ppn_i, cur.s1.ls_pipe_l1d_req_vtag[(12-(L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH))-1:0]};
  end
endgenerate

assign ld_tlb_hit = dtlb_l1d_resp_hsk & dtlb_l1d_resp_hit_i & ~dtlb_l1d_resp_excp_vld_i;

    // compare tag from [1.snoop req:from snp ctrl; 2.load:from tlb; 3.store:from stb]
    // mux between snp req, ld tlb tag and st tag/ptw tag
assign tag_used_to_compare  = (in_snoop_trans_stall_core_s0_req & ~s1_st_req_tag_vld & ~s2_st_req_tag_hit & ~s1_ld_req_tag_vld)  ? snp_addr_tag : // s0_1: if s1 or s2 is a store hit need to write data ram, wait for 1 cycle
                              cur.s1.req_type_dec.is_ld         ? paddr_tag_from_tlb :
                                                                  cur.s1.ls_pipe_l1d_st_req_tag; // st tag and ptw tag share the slot

generate
  for(waynum = 0; waynum < L1D_BANK_WAY_NUM; waynum++) begin: gen_s1_tag_compare_hit_per_way
    assign s1_tag_compare_result_per_way[waynum] = (tram_rdat[waynum] == tag_used_to_compare);
    // assign s1_tag_compare_valid_per_way [waynum] = s1_tag_compare_result_per_way[waynum] &&
    //                                                (cur.s1.lst_dat.mesi_sta[waynum] != INVALID);
    assign s1_tag_compare_hit_per_way[waynum] = s1_tag_compare_result_per_way[waynum] && // tag match
                                                (((cur.s1.req_type_dec.is_ld || cur.s1.req_type_dec.is_ptw_ld) && (cur.s1.lst_dat.mesi_sta[waynum] == SHARED)) ||
                                                 (cur.s1.lst_dat.mesi_sta[waynum] == EXCLUSIVE) ||
                                                 (cur.s1.lst_dat.mesi_sta[waynum] == MODIFIED)
                                                );
    assign s1_tag_compare_data_hit_permission_miss_per_way[waynum]  = s1_tag_compare_result_per_way[waynum] && // tag match
                                                                      ((cur.s1.req_type_dec.is_st /*|| cur.s1.req_type_dec.is_amo || cur.s1.req_type_dec.is_lr*/) && 
                                                                      (cur.s1.lst_dat.mesi_sta[waynum] == SHARED))
                                                                      ;
  end
endgenerate

assign s1_st_req_tag_vld = s1_valid & cur.s1.req_type_dec.is_st & ~cur.s1.is_evict;
assign s1_ld_req_tag_vld = s1_valid & cur.s1.req_type_dec.is_ld & ~cur.s1.is_evict;

assign s1_tag_compare_hit = (cur.s1.req_type_dec.is_ld ? ld_tlb_hit : 1'b1) &&
                            (|s1_tag_compare_hit_per_way);

assign s1_ld_req_tag_hit   = s1_ld_req_tag_vld & s1_tag_compare_hit; 
assign s1_ptw_req_tag_hit  = s1_valid & cur.s1.req_type_dec.is_ptw_ld & ~cur.s1.is_evict & s1_tag_compare_hit; 
assign s1_st_req_tag_hit   = s1_st_req_tag_vld & s1_tag_compare_hit; 
assign s1_lr_req_tag_hit   = s1_valid & cur.s1.req_type_dec.is_lr & ~cur.s1.is_evict & s1_tag_compare_hit; // TODO: this is only for single core
assign s1_sc_req_tag_hit   = s1_valid & cur.s1.req_type_dec.is_sc & ~cur.s1.is_evict & s1_tag_compare_hit; // TODO: this is only for single core
assign s1_amo_req_tag_hit  = s1_valid & cur.s1.req_type_dec.is_amo & ~cur.s1.is_evict & s1_tag_compare_hit; // TODO: this is only for single core

assign s1_ld_req_tag_miss  = s1_ld_req_tag_vld & ~s1_tag_compare_hit; 
assign s1_ptw_req_tag_miss = s1_valid & cur.s1.req_type_dec.is_ptw_ld & ~cur.s1.is_evict & ~s1_tag_compare_hit; 
assign s1_st_req_tag_miss  = s1_st_req_tag_vld & ~s1_tag_compare_hit; 
assign s1_lr_req_tag_miss  = s1_valid & cur.s1.req_type_dec.is_lr & ~cur.s1.is_evict & ~s1_tag_compare_hit; // TODO: this is only for single core
assign s1_sc_req_tag_miss  = s1_valid & cur.s1.req_type_dec.is_sc & ~cur.s1.is_evict & ~s1_tag_compare_hit; // TODO: this is only for single core
assign s1_amo_req_tag_miss = s1_valid & cur.s1.req_type_dec.is_amo & ~cur.s1.is_evict & ~s1_tag_compare_hit; // TODO: this is only for single core
assign s1_req_tag_miss = s1_valid & (~cur.s1.req_type_dec.is_sc) & ~cur.s1.is_evict & ~s1_tag_compare_hit;
assign s2_req_tag_miss = s2_valid & (~cur.s2.req_type_dec.is_sc) & ~cur.s2.is_evict & ~cur.s2.tag_compare_hit;

assign s1_data_ram_st_hit_wr_ready = '1;

assign s2_amo_req_tag_hit = s2_valid & cur.s2.req_type_dec.is_amo & ~cur.s2.is_evict & cur.s2.tag_compare_hit; 
assign s2_st_req_tag_hit  = s2_valid & cur.s2.req_type_dec.is_st & ~cur.s2.is_evict & cur.s2.tag_compare_hit; 
assign s2_st_req_tag_miss = s2_valid & cur.s2.req_type_dec.is_st & ~cur.s2.is_evict & ~cur.s2.tag_compare_hit; 

//cache result sel
assign cache_way_idx_dram_s1 = in_fencei_flush_s3 ? l1d_bank_fencei_flush_way_idx_ptr_q : 
                               snp_l1d_bank_snp_s3_req_vld_i ? snp_l1d_bank_snp_s3_tag_compare_match_id_i :
                               cur.s1.evict_way_idx;
assign cache_offset_dram_s1 = cur.s1.ls_pipe_l1d_req_offset;
assign dram_rdat_all_way_selected = {(L1D_BANK_LINE_DATA_SIZE){(cache_way_idx_dram_s1 == 2'b00)}}& dram_rdat_all_way0 | 
                                    {(L1D_BANK_LINE_DATA_SIZE){(cache_way_idx_dram_s1 == 2'b01)}}& dram_rdat_all_way1 |
                                    {(L1D_BANK_LINE_DATA_SIZE){(cache_way_idx_dram_s1 == 2'b10)}}& dram_rdat_all_way2 | 
                                    {(L1D_BANK_LINE_DATA_SIZE){(cache_way_idx_dram_s1 == 2'b11)}}& dram_rdat_all_way3 ;
assign dram_rdat_all_way_seg_realigned  = {(L1D_BANK_LINE_DATA_SIZE){(cache_offset_dram_s1[5:4] == 2'b00)}}& dram_rdat_all_way_seg_realigned_offset0 |
                                          {(L1D_BANK_LINE_DATA_SIZE){(cache_offset_dram_s1[5:4] == 2'b01)}}& dram_rdat_all_way_seg_realigned_offset1 |
                                          {(L1D_BANK_LINE_DATA_SIZE){(cache_offset_dram_s1[5:4] == 2'b10)}}& dram_rdat_all_way_seg_realigned_offset2 |
                                          {(L1D_BANK_LINE_DATA_SIZE){(cache_offset_dram_s1[5:4] == 2'b11)}}& dram_rdat_all_way_seg_realigned_offset3 ;
assign dram_rdat_all = dram_rdat_all_way_seg_realigned;


// sc result
logic            s2_is_sc_valid;
logic [L1D_BANK_LINE_DATA_SIZE-1:0] s2_sc_resp_dat;
assign s2_is_sc_valid = s2_valid & cur.s2.req_type_dec.is_sc;
assign s2_sc_req_hit = s2_is_sc_valid &
                   cur.s2.sc_rt_check_succ & // reservation table valid
                   cur.s2.tag_compare_hit; // tag hit & state is unique
assign s2_sc_resp_dat = s2_sc_req_hit ? '0 : {{(L1D_BANK_LINE_DATA_SIZE-1){1'b0}}, 1'b1};

// --- lsu resp --- //
// s2 ld resp to lsu
assign l1d_lsu_resp_valid = ((stb_l1d_bank_ld_bypass_valid_i               |     // resp when stb load bypass
                             (s2_valid & cur.s2.tag_compare_hit & (cur.s2.req_type_dec.is_ld | cur.s2.req_type_dec.is_ptw_ld)) | // resp when no stb load bypass, and ld/ptw hit
                             (s2_valid & cur.s2.tag_compare_hit & (cur.s2.req_type_dec.is_amo | cur.s2.req_type_dec.is_lr)) | // resp when amo/lr hit
                             (refill_bank_internal_hsk & refill_req.is_ld & ~refill_req.ld_no_resp) // resp ld when no ld hit, and a refill valid
                             )&
                            ~lsu_l1d_s2_kill_valid_i                       &     // don't resp when the load is killed at s2 by lsu pma/pmp/memory consistency check fail
                            ~(rob_flush_i & cur.s2.req_type_dec.is_ld))        |     // don't resp when the load is killed at s2 by rob flush
                            (refill_bank_internal_hsk & refill_req.req_type_dec.is_ptw_ld) |   // resp ptw when no ld hit, and a refill valid, always resp regardless any flush
                            (refill_bank_internal_hsk & (refill_req.req_type_dec.is_amo | refill_req.req_type_dec.is_lr)) |  // resp amo/lr when a refill valid, always resp regardless any flush
                            (s2_valid & cur.s2.req_type_dec.is_sc); // resp sc regardless there is a hit or miss
assign l1d_lsu_resp_is_refill = refill_bank_internal_hsk;
assign l1d_lsu_resp_dat = (refill_bank_internal_hsk) ? refill_req.dat : // TODO: sc resp data
                          s2_is_sc_valid             ? s2_sc_resp_dat :
                                                       cur.s2.line_data;
assign l1d_lsu_ld_req_type_dec = (refill_bank_internal_hsk) ? refill_req.req_type_dec
                                                            : cur.s2.req_type_dec;
assign l1d_lsu_resp_offset = (refill_bank_internal_hsk) ? refill_req.offset :
                                                          cur.s2.ls_pipe_l1d_req_offset;
assign l1d_lsu_resp_rob_tag = (refill_bank_internal_hsk) ? refill_req.rob_tag : cur.s2.ls_pipe_l1d_req_rob_tag;
assign l1d_lsu_resp_prd     = (refill_bank_internal_hsk) ? refill_req.prd : cur.s2.ls_pipe_l1d_req_prd;
`ifdef RUBY
logic [RRV64_LSU_ID_WIDTH -1:0] l1d_lsu_resp_lsu_tag;
assign l1d_lsu_resp_lsu_tag = (refill_bank_internal_hsk) ? refill_req.lsu_tag : cur.s2.ls_pipe_l1d_req_lsu_tag;
`endif
// assign l1d_lsu_req_type_dec_o = (refill_bank_internal_hsk & refill_req.is_ld) ? refill_req.req_type_dec : cur.s2.req_type_dec;

logic[XLEN-1:0] unsign_ext_dat;
rvh_l1d_lsu_hit_resp rvh1_l1d_lsu_hit_resp_u
(
  .resp_valid_i                 (l1d_lsu_resp_valid            ),
  .refill_valid_i               (l1d_lsu_resp_is_refill         ),
  .tag_compare_hit_per_way_i    (cur.s2.tag_compare_hit_per_way ),
  .ld_tlb_hit_i                 (cur.s2.ld_tlb_hit          ),
  .lsu_ld_dat_i                 (l1d_lsu_resp_dat               ),
  .lsu_ld_req_type_dec_i        (l1d_lsu_ld_req_type_dec        ),
  .ls_pipe_l1d_ld_req_rob_tag_i (l1d_lsu_resp_rob_tag           ),
  .ls_pipe_l1d_ld_req_prd_i     (l1d_lsu_resp_prd               ),
`ifdef RUBY
  .ls_pipe_l1d_ld_req_lsu_tag_i (l1d_lsu_resp_lsu_tag           ),
  .l1d_lsu_lsu_tag_o            (l1d_lsu_lsu_tag_o              ),
`endif
//  .ls_pipe_l1d_ld_req_opcode_i  (cur.s1.ls_pipe_l1d_ld_req_opcode),
//  .ls_pipe_l1d_ld_req_idx_i     (cur.s1.ls_pipe_l1d_req_idx),
  .ls_pipe_l1d_ld_req_offset_i  (l1d_lsu_resp_offset        ),

  // D$ -> ROB : Write Back
  .l1d_rob_wb_vld_o             (l1d_rob_wb_vld_o           ),
  .l1d_rob_wb_rob_tag_o         (l1d_rob_wb_rob_tag_o       ),

  // STB -> D$ : store buffer load bypass
  .stb_l1d_bank_ld_bypass_valid_i (stb_l1d_bank_ld_bypass_valid_i),
  .stb_l1d_bank_ld_bypass_data_i  (stb_l1d_bank_ld_bypass_data_i ),

  // D$ -> Int PRF : Write Back
  .l1d_int_prf_wb_vld_o         (l1d_int_prf_wb_vld_o       ),
  .l1d_int_prf_wb_tag_o         (l1d_int_prf_wb_tag_o       ),
  .l1d_int_prf_wb_data_o        (l1d_int_prf_wb_data_o      ),
  .l1d_int_prf_wb_vld_from_mlfb_o(l1d_int_prf_wb_vld_from_mlfb_o),

  // D$ -> PTW : Response
  .l1d_ptw_walk_vld_o           (ptw_walk_resp_vld_o        ),
  .l1d_ptw_walk_id_o            (ptw_walk_resp_id_o         ),
  .l1d_ptw_walk_pte_o           (ptw_walk_resp_pte_o        ),

  .unsign_ext_dat_o             (unsign_ext_dat             )
);

// atomic alu
assign amo_alu_data_vld = (s2_valid & cur.s2.req_type_dec.is_amo)        | // s2 amo req hit
                          (refill_hsk & refill_req.req_type_dec.is_amo);   // refill amo req
assign amo_alu_op_w  = refill_hsk ? refill_req.req_type_dec.op_w : cur.s2.req_type_dec.op_w;
assign amo_alu_op_u  = refill_hsk ? refill_req.req_type_dec.amo_u : cur.s2.req_type_dec.amo_u;
assign amo_type      = refill_hsk ? refill_req.req_type_dec.amo_type : cur.s2.req_type_dec.amo_type;
assign amo_req_offset = refill_hsk ? refill_req.offset : cur.s2.ls_pipe_l1d_req_offset;
always_comb begin
  amo_alu_op = '0;
  amo_result = amo_alu_result;
  unique case (amo_type)
    AMOSWAP: begin
      amo_alu_op = ALU_ADD;
      amo_result = amo_operand1;
    end
    AMOADD: begin
      amo_alu_op = ALU_ADD;
    end
    AMOAND: begin
      amo_alu_op = ALU_AND;
    end
    AMOOR: begin
      amo_alu_op = ALU_OR;
    end
    AMOXOR: begin
      amo_alu_op = ALU_XOR;
    end
    AMOMAX: begin
      amo_alu_op = amo_alu_op_u ? ALU_SLTU : ALU_SLT;
      amo_result = amo_alu_result[0] ? amo_operand1 : amo_operand0;
    end
    AMOMIN: begin
      amo_alu_op = amo_alu_op_u ? ALU_SLTU : ALU_SLT;
      amo_result = amo_alu_result[0] ? amo_operand0 : amo_operand1;
    end
    default: begin
    end
  endcase
end
assign amo_operand0 = (cur.s2.req_type_dec.amo_type == AMOSWAP) ? '0 : 
                          amo_alu_op_w ? {{32{~amo_alu_op_u & unsign_ext_dat[31]}}, unsign_ext_dat[31:0]} :
                                            unsign_ext_dat;
assign amo_operand1_src_data = refill_hsk ? refill_req.amo_st_data : cur.s2.amo_st_data;
assign amo_operand1 = amo_alu_op_w  ? {{32{~amo_alu_op_u & amo_operand1_src_data[31]}}, amo_operand1_src_data[31:0]} :
                                      amo_operand1_src_data;

rvh_l1d_alu
rvh_l1d_alu_u (
  .issue_opcode_i   (amo_alu_op ),
  .issue_op_w_i     (amo_alu_op_w),
  .issue_operand0_i (amo_operand0 ),
  .issue_operand1_i (amo_operand1 ),

  .wb_data_o        (amo_alu_result)
);

always_comb begin
  amo_refill_data = s2_valid ? '0 : refill_req.dat; // s2_valid means it is a hit, else it is refill
  // s2_amo_refill_byte_enable = s2_valid ? '0 : '1; // s2_valid means it is a hit, else it is refill
  if(amo_alu_op_w) begin
    amo_refill_data[amo_req_offset*8+:32]      = amo_result[32-1:0];
    // s2_amo_refill_byte_enable[amo_req_offset+:4]  = 8'hf;
  end else begin
    amo_refill_data[amo_req_offset*8+:64]      = amo_result[64-1:0];
    // s2_amo_refill_byte_enable[amo_req_offset+:8]  = 8'hff;
  end

end


// ---  mshr ---  //
// miss req goes into mshr
//----------------Write to mshr-------------------------
// treat flush address as a write miss, if hit
// new mshr generate at s2, not s1 any more
  assign mshr_we = s2_req_tag_miss &
                  ~stb_l1d_bank_ld_bypass_valid_i &
                  ~(rob_flush_i & cur.s2.req_type_dec.is_ld) & // don't alloc mshr when the load is killed at s2 by rob flush
                  ~(cur.s2.req_type_dec.is_sc); //for sc cache miss, it just fails, no need to get line
  assign new_mshr_valid             = mshr_we & 
                                      has_free_mshr &           // although cache bank miss, it can be hit in stb and it is a hit
                                      ~lsu_l1d_s2_kill_valid_i; // don't alloc mshr when the load is killed at s2 by lsu pma/pmp/memory consistency check fail

//  assign new_mshr.tid               = '0; //cur.s2.cpu_req.tid;
  assign new_mshr.rob_tag           = cur.s2.ls_pipe_l1d_req_rob_tag;
  assign new_mshr.prd               = cur.s2.ls_pipe_l1d_req_prd;
`ifdef RUBY
  assign new_mshr.lsu_tag           = cur.s2.ls_pipe_l1d_req_lsu_tag;
`endif
  assign new_mshr.rw                = ~cur.s2.req_type_dec.is_ld & ~cur.s2.req_type_dec.is_ptw_ld;
  assign new_mshr.flush             = '0;//(cur.s2.cpu_req.req_type == REQ_FLUSH_ADDR) | (cur.s2.cpu_req.req_type == REQ_FLUSH_IDX);
  assign new_mshr.no_write_alloc    = '0;//cur.s2.no_write_alloc;
//  assign new_mshr.way_id            = '0; //TODO: remove //replace_way_id;
  // load address to memory (new address for both read and write misses)
  assign new_mshr.new_tag           = cur.s2.ls_pipe_l1d_req_tag;
  // write back address (i.e. old address from tag ram)
  // assign new_mshr.old_tag           = '0; // nxt.s3.is_dirty_forward ? mshr_mc_resp_ff.new_tag : cc_tag_pway[replace_way_id];
  assign new_mshr.bank_index        = cur.s2.ls_pipe_l1d_req_idx;
  assign new_mshr.offset            = cur.s2.ls_pipe_l1d_req_offset;
  assign new_mshr.way_id            = '0;
  assign new_mshr.data              = cur.s2.line_data; //cur.s2.cpu_req.data;
  assign new_mshr.data_byte_mask    = cur.s2.ls_pipe_l1d_st_req_dat_byte_mask;
  assign new_mshr.req_type_dec      = cur.s2.req_type_dec;
  // snoop
  assign new_mshr.old_lst_state     = cur.s2.lst_dat.mesi_sta[s2_tag_compare_hit_way_idx];
  // amo
  assign new_mshr.amo_st_data       = cur.s2.amo_st_data;
  // only tag match, no state match result, for S -> M
  assign new_mshr.tag_compare_data_hit_permission_miss_per_way   = cur.s2.tag_compare_data_hit_permission_miss_per_way;



//  assign new_mshr.byte_mask      = '0; //cur.s2.cpu_req.byte_mask;
  // 1. if a clean line then it's not dirty. 
  // 2. forwarding dirty bit
//  assign mshr_dirty_in = '0; // new_mshr_valid_ff & cc_dirty_ram_dout[new_mshr_replace_way_id_ff] & new_mshr_replace_way_valid_ff |
//                           // new_mshr_valid_ff & new_mshr_dirty_forward_ff;



  rvh_l1d_mshr_alloc
  #(
    .INPUT_NUM    (N_MSHR)
  )
  rvh_l1d_mshr_alloc_u
  (
    .mshr_bank_valid_i    (mshr_bank_valid),
    .mshr_id_o            (new_mshr_id    ),
    .has_free_mshr_o      (has_free_mshr  ),
    .free_mshr_num_o      (free_mshr_num  )
  );

  // if mshr is full, kill the req and replay it
      // D$ -> LSQ, mshr full replay
  assign l1d_ls_pipe_replay_vld_o = (mshr_we & ~has_free_mshr)  // although cache bank miss, it can be hit in stb and it is a hit;
`ifdef RUBY
                                    | stb_l1d_bank_ld_bypass_partial_hit_replay_i; // stb partial hit replay
`else
                                    ;
`endif
  assign l1d_ls_pipe_mshr_full_o  = ~has_free_mshr;
`ifdef RUBY
  assign l1d_ls_pipe_replay_lsu_tag_o   = new_mshr.lsu_tag;
`endif

  rvh_l1d_mshr #(
    .CORE_ID(CORE_ID ),
    .BANK_ID(BANK_ID )
    ) MSHR(
    // mshr req
    .new_mshr_valid_i     (new_mshr_valid ),
    .new_mshr_i           (new_mshr       ),
    .new_mshr_id_i        (new_mshr_id    ),
    .dirty('0), // one cycle late from mshr_in (pipeline delay)
    .mshr_bank_o          (mshr_bank      ),
    .mshr_bank_valid_o    (mshr_bank_valid),
    .mshr_bank_no_resp_o  (mshr_bank_no_resp),
    .mshr_bank_sent_o     (mshr_bank_sent ),

    // mlfb intf
    .mlfb_mshr_dealloc_valid_i (mlfb_mshr_dealloc_valid),
    .mlfb_mshr_dealloc_idx_i   (mlfb_mshr_dealloc_idx ),
    .mlfb_mshr_dealloc_ready_o (mlfb_mshr_dealloc_ready ),

    // MEM NOC
    //  // AR
    // .l2_req_if_arvalid          (l2_req_if_arvalid      ),
    // .l2_req_if_arready          (l2_req_if_arready      ),
    // .l2_req_if_ar               (l2_req_if_ar           ),

    // cache tx port, private cache -> scu
      // req
    .pc_scu_req_vld_o       (pc_scu_req_vld_o),
    .pc_scu_req_o           (pc_scu_req_o    ),
    .pc_scu_req_rdy_i       (pc_scu_req_rdy_i),

    .rob_flush_i                (rob_flush_i                ),
    .clk                        (clk                    ),
    .rst                        (rst                    )
    );




//----- mlfb ----------//
// after receiving a whole cache line, do one step each cycle:
// 1. head_buf_valid_nxt = true
// 2. read lru reg & read valid & dirty reg => get victim or available
// 3. set reserve bit in lst
// 4. if need evict, send evict(flush) req to s0
// 5. after evict(flush) req go though pipeline(read tag and data at s0, get into ewrq at s1), line refill(write tag and data ram, update valid, dirty and lru)
// 6. if step 5 done, deallocate mlfb and mshr entry
logic[PADDR_WIDTH-1:0]  s1_paddr, s2_paddr;
assign s1_paddr = {paddr_tag_from_tlb, cur.s1.ls_pipe_l1d_req_idx, BANK_ID[L1D_BANK_ID_INDEX_WIDTH-1:0], cur.s1.ls_pipe_l1d_req_offset};
assign s2_paddr = {cur.s2.ls_pipe_l1d_req_tag, cur.s2.ls_pipe_l1d_req_idx, BANK_ID[L1D_BANK_ID_INDEX_WIDTH-1:0], cur.s2.ls_pipe_l1d_req_offset};

assign mlfb_mshr_head_rd_mshr_entry         = mshr_bank[mlfb_mshr_head_rd_idx];
assign mlfb_mshr_head_rd_mshr_entry_no_resp = mshr_bank_no_resp[mlfb_mshr_head_rd_idx];

logic                        scu_pc_final_resp_vld;
cache_scu_cc_resp_t          scu_pc_final_resp;
logic                        scu_pc_final_resp_rdy;

assign scu_pc_final_resp_vld  = scu_pc_resp_vld_i & (scu_pc_resp_i.rtype == Comp_UD);
assign scu_pc_final_resp      = scu_pc_resp_i;

// scu to private cache mlfb Comp_UD resp fifo
logic mlfb_resp_fifo_dq_vld;
logic mlfb_resp_fifo_dq_rdy;
logic mlfb_resp_fifo_dq_hsk;
cache_scu_cc_resp_t mlfb_resp_fifo_dq_pl;
logic mlfb_resp_fifo_dq_rdy_from_mlfb;

mp_fifo
#(
    .payload_t          (cache_scu_cc_resp_t    ),
    .ENQUEUE_WIDTH      (1                                      ),
    .DEQUEUE_WIDTH      (1                                      ),
    .DEPTH              (N_MSHR                   ),
    .MUST_TAKEN_ALL     (1                                      )
)
mlfb_resp_fifo_u
(
    // Enqueue
    .enqueue_vld_i          (scu_pc_final_resp_vld       ),
    .enqueue_payload_i      (scu_pc_final_resp           ),
    .enqueue_rdy_o          (scu_pc_final_resp_rdy       ),
    // Dequeue
    .dequeue_vld_o          (mlfb_resp_fifo_dq_vld   ),
    .dequeue_payload_o      (mlfb_resp_fifo_dq_pl    ),
    .dequeue_rdy_i          (mlfb_resp_fifo_dq_rdy   ),

    .flush_i                (1'b0                ),

    .clk                    (clk                 ),
    .rst                    (~rst                )
);

assign mlfb_resp_fifo_dq_rdy = ~scu_pc_data_vld_i & mlfb_resp_fifo_dq_rdy_from_mlfb;
assign mlfb_resp_fifo_dq_hsk = mlfb_resp_fifo_dq_vld & mlfb_resp_fifo_dq_rdy;


rvh_l1d_mlfb #(
.ENTRY_NUM(N_MLFB),
.BANK_ID(BANK_ID ),
.CORE_ID(CORE_ID )
) U_RRV64_L1D_MLFB (
 .clk (clk)
,.rstn (rst)
,.rob_flush_i               (rob_flush_i          )

// ,.l1d_l2_rd_resp_valid  (l2_resp_if_rvalid)
// ,.l1d_l2_rd_resp_ready  (l2_resp_if_rready)
// ,.l1d_l2_rd_resp        (l2_resp_if_r)

// cache rx port, scu -> private cache
  // resp
,.scu_pc_resp_vld_i         (mlfb_resp_fifo_dq_hsk)
,.scu_pc_resp_i             (mlfb_resp_fifo_dq_pl)
,.scu_pc_resp_rdy_o         (mlfb_resp_fifo_dq_rdy_from_mlfb)

  // data
,.scu_pc_data_vld_i         (scu_pc_data_vld_i)
,.scu_pc_data_i             (scu_pc_data_i)
,.scu_pc_data_rdy_o         (scu_pc_data_rdy_o)

// cache tx port, private cache -> scu
  // resp
,.pc_scu_resp_vld_o         (pc_scu_resp_vld_o)
,.pc_scu_resp_o             (pc_scu_resp_o)
,.pc_scu_resp_rdy_i         (pc_scu_resp_rdy_i)


,.mlfb_mshr_dealloc_valid (mlfb_mshr_dealloc_valid)
,.mlfb_mshr_dealloc_ready (mlfb_mshr_dealloc_ready )
,.mlfb_mshr_dealloc_idx (mlfb_mshr_dealloc_idx )

,.mlfb_mshr_head_rd_idx (mlfb_mshr_head_rd_idx  )
,.mlfb_mshr_head_rd_mshr_entry (mlfb_mshr_head_rd_mshr_entry)
,.mlfb_mshr_head_rd_mshr_entry_no_resp (mlfb_mshr_head_rd_mshr_entry_no_resp)
//,.mlfb_mshr_head_pending_rd_idx (mlfb_mshr_head_pending_rd_idx)
//,.mlfb_mshr_head_pending_rd_mshr_entry (mlfb_mshr_head_pending_rd_mshr_entry)

,.mlfb_lru_peek_valid (plru_rd_en_mlfb_peek)
,.mlfb_lru_peek_set_idx (plru_rd_idx_mlfb_peek )
,.mlfb_lru_peek_dat (plru_rd_dat_mlfb_peek)

,.mlfb_lst_peek_set_idx(lst_rd_idx_mlfb_peek)
,.mlfb_lst_peek_dat(lst_rd_dat_mlfb_peek )
,.mlfb_lst_peek_avail_way_idx (lst_rd_avail_way_mlfb_peek )

,.mlfb_lst_check_set_idx (lst_check_set_idx)
,.mlfb_lst_check_way_idx (lst_check_way_idx)
,.mlfb_lst_check_valid  (lst_check_valid )
,.mlfb_lst_check_ready  (lst_check_ready )

,.mlfb_cache_evict_req_valid  (mlfb_evict_valid)
,.mlfb_cache_writeback_req_valid (mlfb_writeback_valid)
,.mlfb_cache_evict_req_ready (mlfb_evict_ready )
,.mlfb_cache_evict_req (mlfb_evict_req )

,.mlfb_cache_refill_req_valid (refill_valid )
,.mlfb_cache_refill_req_ready (refill_ready )
,.mlfb_cache_refill_req (refill_req )

//,.mlfb_stb_rd_resp_valid (mlfb_stb_rd_resp_valid )
//,.mlfb_stb_rd_resp (mlfb_stb_rd_resp )
//,.mlfb_stb_rd_resp_line_dat (mlfb_stb_rd_resp_line_dat)

//,.l1d_scu_rnsd_coh_ack_valid (l1d_scu_rnsd_coh_ack_valid )
//,.l1d_scu_rnsd_coh_ack(l1d_scu_rnsd_coh_ack)
//,.mlfb_head_buf_valid (mlfb_head_buf_valid)
,.s1_valid (s1_valid)
,.s1_paddr (s1_paddr)
,.s2_valid (s2_valid)
,.s2_paddr (s2_paddr)

// all_2: snoop req stall mlfb refill transaction if no sent-out line addr hit in mshr(cond s0.3)
,.snoop_stall_refill_i(in_snoop_trans_stall_refill)
);



// --- ewrq --- //
assign l1d_ewrq_new_ewrq_valid      = s1_valid & cur.s1.is_evict | // mlfb evict
                                      in_fencei_flush_s3;          // fencei evict s3
assign l1d_ewrq_new_writeback_valid = s1_valid & cur.s1.is_evict & cur.s1.is_writeback |
                                      in_fencei_flush_s3;
assign l1d_ewrq_new_ewrq_addr  = in_fencei_flush_s3 ? {tram_rdat[l1d_bank_fencei_flush_way_idx_ptr_q], l1d_bank_fencei_flush_set_idx_ptr_q} :
                                                      {tram_rdat[cur.s1.evict_way_idx], cur.s1.ls_pipe_l1d_req_idx} ;
assign l1d_ewrq_new_ewrq_dat   = dram_rdat_all_way_selected;

`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
assign l1d_ewrq_new_ewrq_lst.mesi_sta   = cur.s1.lst_dat.mesi_sta   [cur.s1.evict_way_idx];
assign l1d_ewrq_new_ewrq_lst.data_dirty = cur.s1.lst_dat.data_dirty [cur.s1.evict_way_idx];
`else
assign l1d_ewrq_new_ewrq_lst.mesi_sta   = cur.s1.lst_dat.mesi_sta   [cur.s1.evict_way_idx];
`endif


logic                        scu_pc_wb_resp_vld;
cache_scu_cc_resp_t          scu_pc_wb_resp;
logic                        scu_pc_wb_resp_rdy;

assign scu_pc_wb_resp_vld   = scu_pc_resp_vld_i & (scu_pc_resp_i.rtype == WriteBack_Ack);
assign scu_pc_wb_resp       = scu_pc_resp_i;

rvh_l1d_ewrq #(
  .CORE_ID(CORE_ID ),
  .BANK_ID(BANK_ID )
  ) EWRQ(
  // new ewrq req
  .l1d_ewrq_new_ewrq_valid_i  (l1d_ewrq_new_ewrq_valid),
  .l1d_ewrq_new_writeback_valid_i (l1d_ewrq_new_writeback_valid),
  .l1d_ewrq_new_ewrq_addr_i   (l1d_ewrq_new_ewrq_addr ),
  .l1d_ewrq_new_ewrq_dat_i    (l1d_ewrq_new_ewrq_dat  ),
// `ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
  .l1d_ewrq_new_ewrq_lst_i    (l1d_ewrq_new_ewrq_lst  ),
// `endif
  .l1d_ewrq_new_ewrq_ready_o  (l1d_ewrq_new_ewrq_ready),

  // output data and valid
  .ewrq_addr_o                (ewrq_addr              ),
  .ewrq_vld_o                 (ewrq_vld               ),

  // cache rx port, scu -> private cache
    // resp
  .scu_pc_resp_vld_i                  (scu_pc_wb_resp_vld),
  .scu_pc_resp_i                      (scu_pc_wb_resp),
  .scu_pc_resp_rdy_o                  (scu_pc_wb_resp_rdy),
  
  // cache tx port, private cache -> scu
    // evict/wb
  .pc_scu_evict_vld_o                 (pc_scu_evict_vld_o),
  .pc_scu_evict_o                     (pc_scu_evict_o),
  .pc_scu_evict_rdy_i                 (pc_scu_evict_rdy_i),

    // data
  .pc_scu_data_vld_o                  (pc_scu_data_vld_o),
  .pc_scu_data_o                      (pc_scu_data_o),
  .pc_scu_data_rdy_i                  (pc_scu_data_rdy_i),


  .clk                          (clk                    ),
  .rst                          (rst                    )

);

assign scu_pc_resp_rdy_o = l1d_ewrq_new_ewrq_valid ? scu_pc_wb_resp_rdy :
                                                     scu_pc_final_resp_rdy;

// --- lst --- //
//LST req, ordered by priority
// write req
//  port 1. mlfb refill: given idx & way_id, write state & check_bit
//       1. lsu store s2: given idx & way_id, write state(dirty bit)
//       1. fencei evict s2 write: given idx & way_id, write state(dirty to clean)
//       1. snoop ctrl s2 write: given idx & way_id, write new state
//       2. mlfb evict check: given idx & way_id, write check_bit
// read req: (as reg, all read can performed parallelly)
//       3. mlfb evict peek: given idx, read all way state
//       3. fencei evict s1 peek: given idx, read all way state
//       4. lsu load s0: given idx, read all way state
//       4. lsu store, lr, amo s0: given idx, read all way state
//       4. snoop ctrl s1: given idx, read alla way state

always_comb begin
  s2_tag_compare_hit_way_idx = '0;
  for(int i = 0; i < L1D_BANK_WAY_NUM; i++) begin
      if(cur.s2.tag_compare_hit_per_way[i] == 1'b1) begin
          s2_tag_compare_hit_way_idx = i;
      end
  end
end

assign lst_mesi_wr_en_s0_req_vld  =  refill_hsk_with_ram_write |  // mlfb refill
                                     mlfb_evict_hsk     |  // mlfb evict, to handle corner case: when a evict valid and put into ewrq, but the refill is stalled by a snpto the same addr as the evict req, make the snp get wrong line state.
                                     s2_st_req_tag_hit  |  // lsu store s2
                                     s2_amo_req_tag_hit |  // amo write s2
                                     s2_sc_req_hit      |  // sc write s2
                                     in_fencei_flush_s2 |  // fencei evict s2
                                     snp_l1d_bank_snp_s2_req_hsk_i; // snoop ctrl s2
assign lst_mesi_wr_set_idx_s0_req =  refill_hsk_with_ram_write      ? refill_req.set_idx        :
                                     mlfb_evict_hsk                 ? mlfb_evict_req.set_idx    : // mlfb evict, to handle corner case
                                     in_fencei_flush_s2             ? l1d_bank_fencei_flush_set_idx_ptr_q :
                                     snp_l1d_bank_snp_s2_req_hsk_i  ? snp_addr_idx  :
                                                                      cur.s2.ls_pipe_l1d_req_idx;
assign lst_mesi_wr_way_idx_s0_req =  refill_hsk_with_ram_write      ? refill_req.way_idx     :
                                     mlfb_evict_hsk                 ? mlfb_evict_req.way_idx : // mlfb evict, to handle corner case
                                     in_fencei_flush_s2             ? l1d_bank_fencei_flush_way_idx_ptr_q :
                                     snp_l1d_bank_snp_s2_req_hsk_i  ? snp_l1d_bank_snp_s2_req_way_id_i :
                                                                      s2_tag_compare_hit_way_idx;
assign lst_wr_dat_s0_req.mesi_sta =  refill_hsk_with_ram_write      ? refill_req.mesi_sta :
                                     mlfb_evict_hsk                 ? INVALID             : // mlfb evict, to handle corner case
                                     in_fencei_flush_s2             ? EXCLUSIVE           :
                                     snp_l1d_bank_snp_s2_req_hsk_i  ? snp_l1d_bank_snp_s2_req_new_line_state_i :
                                                                      MODIFIED  ; // TODO: for cmo flush, INVALID
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
logic [DATA_LINE_W/8-1:0]  data_dirty_per_byte;
assign data_dirty_per_byte  = refill_hsk_with_ram_write      ? refill_req.dat_dirty_byte_mask :
                              in_fencei_flush_s2             ? '0 :
                              snp_l1d_bank_snp_s2_req_hsk_i  ? '0 :
                                                               cur.s2.lst_dat.data_dirty[s2_tag_compare_hit_way_idx] | cur.s2.ls_pipe_l1d_st_req_dat_byte_mask; // TODO: for cmo flush, INVALID
generate
  for(genvar data_seg_id = 0; data_seg_id < DATA_BURST_NUM; data_seg_id++) begin
    assign lst_wr_dat_s0_req.data_dirty[data_seg_id] = (|data_dirty_per_byte[(DATA_LENGTH_PER_PKG/8*data_seg_id)+:(DATA_LENGTH_PER_PKG/8)]) |
                                                       ((refill_hsk_with_ram_write | in_fencei_flush_s2 | snp_l1d_bank_snp_s2_req_hsk_i) ? 1'b0 : cur.s2.lst_dat.data_dirty[s2_tag_compare_hit_way_idx][data_seg_id]); // for store hit, the dirty bit should be accumulated
  end
endgenerate
`endif

assign lst_rd_idx_peek = in_fencei_flush_s1 ? l1d_bank_fencei_flush_set_idx_ptr_q
                                            : lst_rd_idx_mlfb_peek;

rvh_l1d_lst
#(
 .entry_num(L1D_BANK_SET_NUM)
 ,.way_num(L1D_BANK_WAY_NUM)
)
U_L1D_LST(
     .clk (clk)
    ,.rstn (rst )
    ,.lst_mesi_wr_en_s0_req (lst_mesi_wr_en_s0_req_vld ) // 1
    ,.lst_mesi_wr_set_idx_s0_req (lst_mesi_wr_set_idx_s0_req)
    ,.lst_mesi_wr_way_idx_s0_req (lst_mesi_wr_way_idx_s0_req)
    ,.lst_wr_dat_s0_req          (lst_wr_dat_s0_req)
    
    ,.lst_mesi_wr_en_snp ('0  )
    ,.lst_mesi_wr_set_idx_snp ('0)
    ,.lst_mesi_wr_way_idx_snp ('0)
    ,.lst_mesi_wr_dat_snp ('0)
    
    ,.lst_rd_idx_s0_req (lst_rd_idx_s0_req)  // 4
    ,.lst_rd_dat_s0_req (lst_rd_dat_s0_req)  
    
    ,.lst_rd_idx_mlfb_peek (lst_rd_idx_peek) // 3
    ,.lst_rd_dat_mlfb_peek (lst_rd_dat_mlfb_peek)
    // ,.lst_avail_way_rd_idx_mlfb_peek (lst_rd_idx_mlfb_peek)
    ,.lst_avail_way_rd_dat_mlfb_peek (lst_rd_avail_way_mlfb_peek)
    
    ,.lst_check_set_idx (lst_check_set_idx) // 2
    ,.lst_check_way_idx (lst_check_way_idx)
    ,.lst_check_valid (lst_check_valid )
    ,.lst_check_ready (lst_check_ready )
);

`ifndef SYNTHESIS
logic lst_wrtie_given_idx_and_way;
// logic lst_read_given_idx;
always_comb begin
  lst_wrtie_given_idx_and_way = '0;
  
  if(lst_mesi_wr_en_s0_req_vld) begin
    if(lst_mesi_wr_set_idx_s0_req == 'h6) begin
      if(lst_mesi_wr_way_idx_s0_req == 'h3) begin
        lst_wrtie_given_idx_and_way = 1'b1;
      end
    end
  end
end
`endif

// --- plru ---//
//PLRU req, ordered by priority
// write req
//  port 1. load/store hit: given idx & way_id, update plru
// read req: (as reg, all read can performed parallelly)
//       2. mlfb evict peek: given idx, get victim way_id

logic plru_upd_en_s1_cache_hit;
logic[L1D_BANK_SET_INDEX_WIDTH-1:0] plru_set_idx_s1_cache_hit; 
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] plru_way_idx_s1_cache_hit;

assign plru_upd_en_s1_cache_hit  = s1_valid & ~s1_stall & (s1_ld_req_tag_hit | s1_st_req_tag_hit);
assign plru_set_idx_s1_cache_hit = cur.s1.ls_pipe_l1d_req_idx;
assign plru_way_idx_s1_cache_hit = s2_tag_compare_hit_way_idx;

rvh_l1d_plru
#(
.entry_num(L1D_BANK_SET_NUM)
,.way_num(L1D_BANK_WAY_NUM)
)
U_RRV64_L1D_PLRU(
.clk (clk)
,.rstn (rst)
,.upd_en_hit (plru_upd_en_s1_cache_hit)
,.upd_set_idx_hit (plru_set_idx_s1_cache_hit)
,.upd_way_idx_hit (plru_way_idx_s1_cache_hit)

,.rd_en_refill (plru_rd_en_mlfb_peek)
,.rd_idx_refill (plru_rd_idx_mlfb_peek)
,.rd_dat_refill (plru_rd_dat_mlfb_peek) 
);


// fencei flush fsm
// make all dirty line into clean, write back dirty line
  // next fencei flush state
always_comb begin: case_l1d_bank_fencei_flush_state_d
  l1d_bank_fencei_flush_state_d = FLUSH_IDLE;
  l1d_bank_fencei_flush_state_d_ena = 1'b0;

  next_way_idx_ptr_en = 1'b0;
  next_set_idx_ptr_en = 1'b0;

  case(l1d_bank_fencei_flush_state_q)
    FLUSH_IDLE: begin
      if(fencei_flush_hsk) begin // fencei req comes and hsk success
        l1d_bank_fencei_flush_state_d     = FLUSH_READ_LST;
        l1d_bank_fencei_flush_state_d_ena = 1'b1;
      end else if(fencei_flush_vld_i) begin // fencei req comes and hsk fail
        l1d_bank_fencei_flush_state_d     = FLUSH_PENDING;
        l1d_bank_fencei_flush_state_d_ena = 1'b1;
      end
    end
    FLUSH_PENDING: begin
      if(fencei_flush_hsk) begin // fencei req comes and hsk success
        l1d_bank_fencei_flush_state_d     = FLUSH_READ_LST;
        l1d_bank_fencei_flush_state_d_ena = 1'b1;
      end else begin // fencei req comes and hsk fail
        l1d_bank_fencei_flush_state_d     = FLUSH_PENDING;
        l1d_bank_fencei_flush_state_d_ena = 1'b0;
      end
    end
    // read lst and judge whether need to read data ram
    FLUSH_READ_LST: begin
      if(lst_rd_dat_mlfb_peek.mesi_sta[l1d_bank_fencei_flush_way_idx_ptr_q] == MODIFIED) begin // dirty, need to write back
        l1d_bank_fencei_flush_state_d     = FLUSH_READ_DATA_RAM_WRITE_LST;
        l1d_bank_fencei_flush_state_d_ena = 1'b1;
      end else begin // clear/invalid, read next line lst
        if((l1d_bank_fencei_flush_set_idx_ptr_q == L1D_BANK_SET_NUM-1) && 
           (l1d_bank_fencei_flush_way_idx_ptr_q == L1D_BANK_WAY_NUM-1)) begin // fencei flush finished
          l1d_bank_fencei_flush_state_d     = FLUSH_WAIT_EVICT_QUEUE_CLEAN;
          l1d_bank_fencei_flush_state_d_ena = 1'b1;
        end else begin
          l1d_bank_fencei_flush_state_d     = FLUSH_READ_LST;
          l1d_bank_fencei_flush_state_d_ena = 1'b0;
          // ptr point to next line
          next_way_idx_ptr_en = 1'b1;
          next_set_idx_ptr_en = l1d_bank_fencei_flush_way_idx_ptr_q == '1;
        end
      end
    end
    // read data & tag ram if needed, write lst if needed
    FLUSH_READ_DATA_RAM_WRITE_LST: begin
      l1d_bank_fencei_flush_state_d     = FLUSH_ENQUEUE_EVICT_QUEUE;
      l1d_bank_fencei_flush_state_d_ena = 1'b1;
    end
    // put the dirty data into evict queue if needed
    FLUSH_ENQUEUE_EVICT_QUEUE: begin
      if(l1d_ewrq_new_ewrq_ready == 1'b1) begin // ewrq enqueue finish
        if((l1d_bank_fencei_flush_set_idx_ptr_q == L1D_BANK_SET_NUM-1) && 
           (l1d_bank_fencei_flush_way_idx_ptr_q == L1D_BANK_WAY_NUM-1)) begin // fencei flush finished
          l1d_bank_fencei_flush_state_d     = FLUSH_WAIT_EVICT_QUEUE_CLEAN;
          l1d_bank_fencei_flush_state_d_ena = 1'b1;
        end else begin
          l1d_bank_fencei_flush_state_d     = FLUSH_READ_LST;
          l1d_bank_fencei_flush_state_d_ena = 1'b1;
          // ptr point to next line
          next_way_idx_ptr_en = 1'b1;
          next_set_idx_ptr_en = l1d_bank_fencei_flush_set_idx_ptr_q == '1;
        end
      end else begin // if the ewrq is full, replay the ram read and try ewrq enqueue again
        l1d_bank_fencei_flush_state_d     = FLUSH_READ_DATA_RAM_WRITE_LST;
        l1d_bank_fencei_flush_state_d_ena = 1'b1;
      end
    end
    FLUSH_WAIT_EVICT_QUEUE_CLEAN: begin
      if((|ewrq_vld) == '0) begin // evict queue is empty
        l1d_bank_fencei_flush_state_d     = FLUSH_FINISH;
        l1d_bank_fencei_flush_state_d_ena = 1'b1;
      end else begin // else, wait for evict queue empty
        l1d_bank_fencei_flush_state_d     = FLUSH_WAIT_EVICT_QUEUE_CLEAN;
        l1d_bank_fencei_flush_state_d_ena = 1'b0;
      end
    end
    FLUSH_FINISH: begin
      l1d_bank_fencei_flush_state_d     = FLUSH_IDLE;
      l1d_bank_fencei_flush_state_d_ena = 1'b1;
      // ptr point to initial line
      next_way_idx_ptr_en = 1'b1;
      next_set_idx_ptr_en = 1'b1;
    end
    default: begin
      l1d_bank_fencei_flush_state_d     = FLUSH_IDLE;
      l1d_bank_fencei_flush_state_d_ena = 1'b1;
      next_way_idx_ptr_en = 1'b0;
      next_set_idx_ptr_en = 1'b0;
    end
  endcase
end

  // output of fsm
    // states
assign in_fencei_flush_pending  = (l1d_bank_fencei_flush_state_q == FLUSH_PENDING);
assign in_fencei_flush_s1       = (l1d_bank_fencei_flush_state_q == FLUSH_READ_LST);
assign in_fencei_flush_s2       = (l1d_bank_fencei_flush_state_q == FLUSH_READ_DATA_RAM_WRITE_LST);
assign in_fencei_flush_s3       = (l1d_bank_fencei_flush_state_q == FLUSH_ENQUEUE_EVICT_QUEUE);
assign in_fencei_flush_wait_ewrq_clean  = (l1d_bank_fencei_flush_state_q == FLUSH_WAIT_EVICT_QUEUE_CLEAN);
assign in_fencei_flush          = in_fencei_flush_pending | in_fencei_flush_s1 | in_fencei_flush_s2 | in_fencei_flush_s3 | in_fencei_flush_wait_ewrq_clean| in_fencei_finish_flush;
assign in_fencei_finish_flush   = (l1d_bank_fencei_flush_state_q == FLUSH_FINISH);

  // next set, wat idx ptr
assign l1d_bank_fencei_flush_way_idx_ptr_d      = in_fencei_finish_flush ? '0 : l1d_bank_fencei_flush_way_idx_ptr_q + 1;
assign l1d_bank_fencei_flush_set_idx_ptr_d      = in_fencei_finish_flush ? '0 : l1d_bank_fencei_flush_set_idx_ptr_q + 1;
assign l1d_bank_fencei_flush_way_idx_ptr_d_ena  = in_fencei_finish_flush | next_way_idx_ptr_en;
assign l1d_bank_fencei_flush_set_idx_ptr_d_ena  = in_fencei_finish_flush | next_set_idx_ptr_en;

  // fencei flush finish signal
assign fencei_flush_grant_o = in_fencei_finish_flush;

  // fsm registers
std_dffrve
#(.WIDTH($bits(l1d_bank_fencei_flush_state_t)))
U_L1D_BANK_FENCEI_STATE_REG
(
  .clk(clk),
  .rstn(rst),
  .rst_val(FLUSH_IDLE),
  .en(l1d_bank_fencei_flush_state_d_ena),
  .d(l1d_bank_fencei_flush_state_d),
  .q(l1d_bank_fencei_flush_state_q)
);
std_dffre
#(.WIDTH(L1D_BANK_WAY_INDEX_WIDTH)) 
U_L1D_BANK_FENCEI_WAY_IDX_REG
(
  .clk(clk),
  .rstn(rst),
  .en(l1d_bank_fencei_flush_way_idx_ptr_d_ena),
  .d(l1d_bank_fencei_flush_way_idx_ptr_d),
  .q(l1d_bank_fencei_flush_way_idx_ptr_q)
);
std_dffre
#(.WIDTH(L1D_BANK_SET_INDEX_WIDTH)) 
U_L1D_BANK_FENCEI_SET_IDX_REG
(
  .clk(clk),
  .rstn(rst),
  .en(l1d_bank_fencei_flush_set_idx_ptr_d_ena),
  .d(l1d_bank_fencei_flush_set_idx_ptr_d),
  .q(l1d_bank_fencei_flush_set_idx_ptr_q)
);

// stage reg
// s0-s1
assign s1_stall =   s1_valid & (
                    cur.s1.req_type_dec.is_ld & s1_tag_compare_hit & s2_stall            |  // load hit, but s2 ready is low
                    // cur.s1.req_type_dec.is_ld & ~s1_tag_compare_hit & ~has_free_mshr     |  // load miss, mshr full
                    // cur.s1.req_type_dec.is_st & s1_tag_compare_hit & refill_hsk          |  // store hit, but refill comes at the same cycle 
                    // cur.s1.req_type_dec.is_st & ~s1_tag_compare_hit & ~has_free_mshr     |  // store miss, mshr full
                    cur.s1.is_evict & ~l1d_ewrq_new_ewrq_ready                              // evict, but ewrq full
                    ); // TODO: this is useless, remove it
assign s1_valid_nxt = ls_pipe_l1d_ld_req_hsk | ls_pipe_l1d_st_req_hsk | mlfb_evict_hsk | ptw_l1d_walk_req_hsk;
assign s1_nxt_ena = s1_valid_nxt & ~s1_stall;
assign nxt.s1.ls_pipe_l1d_req_rob_tag  = ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_rob_tag_i :
                                         ptw_l1d_walk_req_hsk   ? ptw_walk_req_id_i            :
                                                                  ls_pipe_l1d_st_req_rob_tag_i;
assign nxt.s1.ls_pipe_l1d_req_prd      = ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_prd_i
                                                                : ls_pipe_l1d_st_req_prd_i;
// assign nxt.s1.ls_pipe_l1d_req_opcode   = ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_opcode_i
//                                                                 : ls_pipe_l1d_st_req_opcode_i;
`ifdef RUBY
assign nxt.s1.ls_pipe_l1d_req_lsu_tag  = ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_lsu_tag_i
                                                                : ls_pipe_l1d_st_req_lsu_tag_i;
`endif
assign nxt.s1.ls_pipe_l1d_req_idx      = mlfb_evict_hsk         ? mlfb_evict_req.set_idx      :
                                         ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_idx_i    :
                                         ptw_l1d_walk_req_hsk   ? ptw_walk_req_addr_i[L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH] :
                                                                  ls_pipe_l1d_st_req_idx;
assign nxt.s1.ls_pipe_l1d_req_offset   = ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_offset_i :
                                         ptw_l1d_walk_req_hsk   ? ptw_walk_req_addr_i[L1D_BANK_OFFSET_WIDTH-1:0] :
                                                                  ls_pipe_l1d_st_req_offset;
assign nxt.s1.ls_pipe_l1d_req_vtag     = ls_pipe_l1d_ld_req_vtag_i;
 //TODO: separate enable signal
assign nxt.s1.ls_pipe_l1d_st_req_tag   = ptw_l1d_walk_req_hsk ? ptw_walk_req_addr_i[PADDR_WIDTH-1:L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH]
                                                              : ls_pipe_l1d_st_req_tag;
assign nxt.s1.ls_pipe_l1d_st_req_dat   = ls_pipe_l1d_st_req_data_i;
assign nxt.s1.ls_pipe_l1d_st_req_dat_byte_mask = ls_pipe_l1d_st_req_data_byte_mask_i;

`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
assign nxt.s1.lst_dat.mesi_sta         = lst_rd_dat_s0_req.mesi_sta;
generate
  for(genvar way_id = 0; way_id < L1D_BANK_WAY_NUM; way_id++) begin: gen_nxt_s1_lst_dat_data_dirty
    assign nxt.s1.lst_dat.data_dirty[way_id] = ((~s2_req_tag_miss & ls_pipe_l1d_req_idx_cmp_in_pipe_s2) & ((L1D_BANK_WAY_NUM'(1 << way_id)) == cur.s2.tag_compare_hit_per_way)) ? 
                                                (lst_wr_dat_s0_req.data_dirty | lst_rd_dat_s0_req.data_dirty[way_id]) : 
                                               lst_rd_dat_s0_req.data_dirty[way_id];
  end
endgenerate
`else
assign nxt.s1.lst_dat                  = lst_rd_dat_s0_req;
`endif

assign nxt.s1.req_type_dec             = req_type_dec;
assign nxt.s1.is_evict                 = mlfb_evict_hsk;
assign nxt.s1.is_writeback             = mlfb_evict_hsk & mlfb_writeback_valid;
assign nxt.s1.evict_way_idx            = mlfb_evict_req.way_idx;

assign nxt.s1.sc_rt_check_succ         = ls_pipe_l1d_st_req_sc_rt_check_succ_i;

std_dffr #(.WIDTH(1)) U_STG_VALID_REG_S1 (.clk(clk),.rstn(rst),.d(s1_valid_nxt),.q(s1_valid));
std_dffe #(.WIDTH($bits(l1d_pipe_s1_t))) U_STG_DAT_REG_S1 (.clk(clk),.en(s1_nxt_ena),.d(nxt.s1),.q(cur.s1));

  // s1-s2
// assign s2_stall = refill_valid & refill_req.is_ld; // when refill_valid and it needs to resp to lsu, the resp channel is occupied
assign s2_stall = 1'b0;
assign s2_valid_nxt = (((s1_ld_req_tag_hit |      // ld hit need go into s2, and resp to lsu at s2
                        s1_ld_req_tag_miss) &     // ld miss need go into s2, and go to new mshr at s2
                        ld_tlb_hit &              // ld should tlb hit, or kill the ld req
                        ~rob_flush_i)          |  // rob flush, kill load req in pipeline

                        (s1_ptw_req_tag_hit |     // ptw ld hit need go into s2, and resp to mmu at s2
                         s1_ptw_req_tag_miss)  |  // ptw ld miss need go into s2, and go to new mshr at s2

                        (s1_st_req_tag_hit  |     // st hit need go into s2, and write data ram
                         s1_st_req_tag_miss)   |  // st miss need go into s2, and go to new mshr at s2

                        (s1_lr_req_tag_hit |       // lr hit need go into s2, to set reservation table and resp to lsu
                         s1_lr_req_tag_miss)   |   // lr miss need go into s2, to go to new mshr

                        (s1_sc_req_tag_hit |       // sc hit need go into s2, sc succ, clear resv table, resp 0 to lsu, write data ram
                         s1_sc_req_tag_miss)   |   // sc miss need go into s2, sc fail, clear resv table, resp 1 to lsu

                         (s1_amo_req_tag_hit |     // amo hit need go into s2, to do alu
                          s1_amo_req_tag_miss)     // amo miss need go into s2, to go to new mshr
                        )
                      & ~cur.s1.is_evict;  // evict no need to go to s2, it goes to ewrq directly
assign s2_nxt_ena = s2_valid_nxt & ~s2_stall;

assign nxt.s2.tag_compare_hit               = s1_tag_compare_hit;
assign nxt.s2.tag_compare_hit_per_way       = s1_tag_compare_hit_per_way;
assign nxt.s2.tag_compare_data_hit_permission_miss_per_way = s1_tag_compare_data_hit_permission_miss_per_way; // only tag match, no state match result, for S -> M
// assign nxt.s2.tag_compare_hit_way_idx       = s1_tag_compare_hit_way_idx;
assign nxt.s2.ld_tlb_hit                    = ld_tlb_hit;
assign nxt.s2.line_data                     = (cur.s1.req_type_dec.is_ld | cur.s1.req_type_dec.is_ptw_ld | cur.s1.req_type_dec.is_amo | cur.s1.req_type_dec.is_lr) ? dram_rdat_all
                                                                        : cur.s1.ls_pipe_l1d_st_req_dat;
assign nxt.s2.amo_st_data                   = cur.s1.ls_pipe_l1d_st_req_dat[cur.s1.ls_pipe_l1d_req_offset*8 +: XLEN];
assign nxt.s2.ls_pipe_l1d_req_rob_tag       = cur.s1.ls_pipe_l1d_req_rob_tag;
assign nxt.s2.ls_pipe_l1d_req_prd           = cur.s1.ls_pipe_l1d_req_prd;
`ifdef RUBY
assign nxt.s2.ls_pipe_l1d_req_lsu_tag       = cur.s1.ls_pipe_l1d_req_lsu_tag;
`endif
assign nxt.s2.req_type_dec                  = cur.s1.req_type_dec;
assign nxt.s2.is_evict                      = cur.s1.is_evict;
assign nxt.s2.is_writeback                  = cur.s1.is_writeback;
assign nxt.s2.ls_pipe_l1d_req_tag           = cur.s1.req_type_dec.is_ld ? paddr_tag_from_tlb
                                                                        : cur.s1.ls_pipe_l1d_st_req_tag;
assign nxt.s2.ls_pipe_l1d_req_idx           = cur.s1.ls_pipe_l1d_req_idx;
assign nxt.s2.ls_pipe_l1d_req_offset        = cur.s1.ls_pipe_l1d_req_offset;

 //TODO: separate enable signal
// assign nxt.s2.ls_pipe_l1d_st_req_dat        = cur.s1.ls_pipe_l1d_st_req_dat;
assign nxt.s2.ls_pipe_l1d_st_req_dat_byte_mask = cur.s1.ls_pipe_l1d_st_req_dat_byte_mask;

// snoop
assign nxt.s2.lst_dat                       = cur.s1.lst_dat;

// sc
assign nxt.s2.sc_rt_check_succ              = cur.s1.sc_rt_check_succ;

std_dffr #(.WIDTH(1)) U_STG_VALID_REG_S2 (.clk(clk),.rstn(rst),.d(s2_valid_nxt),.q(s2_valid));
std_dffe #(.WIDTH($bits(l1d_pipe_s2_t))) U_STG_DAT_REG_S2 (.clk(clk),.en(s2_nxt_ena),.d(nxt.s2),.q(cur.s2));



`ifndef SYNTHESIS

// miss rate counter
logic [64-1:0] ls_num_counter_d, ls_num_counter_q;
logic ls_num_counter_ena;
logic [64-1:0] miss_num_counter_d, miss_num_counter_q;
logic miss_num_counter_ena;

assign ls_num_counter_d     = ls_num_counter_q + 1;
assign miss_num_counter_d   = miss_num_counter_q + 1;

assign ls_num_counter_ena   = ls_pipe_l1d_ld_req_hsk | ls_pipe_l1d_st_req_hsk;
assign miss_num_counter_ena = new_mshr_valid;

std_dffre
#(.WIDTH(64))
U_DAT_LS_NUM_COUNTER
(
  .clk(clk),
  .rstn(rst),
  .en(ls_num_counter_ena),
  .d(ls_num_counter_d),
  .q(ls_num_counter_q)
);

std_dffre
#(.WIDTH(64))
U_DAT_MISS_NUM_COUNTER
(
  .clk(clk),
  .rstn(rst),
  .en(miss_num_counter_ena),
  .d(miss_num_counter_d),
  .q(miss_num_counter_q)
);

real ls_num_counter;
real miss_num_counter;

final begin
  ls_num_counter    = ls_num_counter_q;
  miss_num_counter  = miss_num_counter_q;
  $display("l1d CORE_ID = %2d, BANK_ID = %2d, miss rate = (%d/%d) = %f", 
  CORE_ID, BANK_ID, miss_num_counter, ls_num_counter, miss_num_counter/ls_num_counter);
end

`endif

`ifdef RUBY
logic st_hit_vld;
logic st_refill_vld;

assign st_hit_vld     = s2_st_req_tag_hit;
assign st_refill_vld  = refill_hsk & ~refill_req.is_ld;

assign l1d_lsu_st_lsu_tag_vld_o = st_hit_vld | st_refill_vld;
assign l1d_lsu_st_lsu_tag_o     = st_hit_vld ? cur.s2.ls_pipe_l1d_req_lsu_tag : refill_req.lsu_tag;

`endif

endmodule : rvh_l1d_bank
