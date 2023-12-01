/*
# function
the store buffer should have following functions:
1. buffer store     : multiple stores may come into stb, th stb buffer them and send them to l1d bank at some timeout;
2. store merge      : when different st req hit the same cache line, stb shoul merge them into one cache line, set its write mask, and send them to l1d bank as one write req;
3. load bypass      : the st reqs in stb are commited, so it has latest data, when a load req comes, it has to search the stb for its data;
4. eviction         : when the eviction condition is met, e.g. stb full, load partical hit, the stb need to evict one or all stb entries to l1d bank;
5. coherence snoop  : snoop will search the stb, if there is a hit, it should wait for the stb entry evicted to the l1d bank and then start its coherence operation.

# load req (vipt)
| stage | l1d stb                                                                                                    | l1d bank                                                             |
| ----- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| s0    | as vipt, no physical tag at s0, do nothing                                                                 | read tag ram, data ram, lst                                          |
| s1    | get tlb resp, read/comapre line addr, the one which is evict hak at that cycle is taken as miss            | get tlb resp, compare tag, compare state, select data                |
| s2    | if full hit: resp data; if partial hit: ldq replay, force the stb entry go into l1d bank; if miss: no resp | if hit: resp data; if miss: alloc new mshr, if mshr full: ldq replay |
|       |                                                                                                            |                                                                      |

# stb store req (pipt) vs load req (vipt)
| stage | l1d stb store                                                                                                                                              | l1d stb load                                                                                               |
| ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| s0    | read/comapre line addr, if miss(the one which is evict hak at that cycle is taken as miss) & no free stb entry(include the one in s1): lower ready signal  | as vipt, no physical tag at s0, do nothing                                                                 |
| s1    | if hit: select the hit entry idx, merge and update stb entry; if miss: alloc new stb entry                                                                 | get tlb resp, read/comapre line addr                                                                       |
| s2    |                                                                                                                                                            | if full hit: resp data; if partial hit: ldq replay, force the stb entry go into l1d bank; if miss: no resp |

# stb evict (when stb full / stb entry timeout)
## when evict (with priority)
1. stb flush (evict all)
1. coherence snoop hit
2. load partial hit
3. stb full
4. stb entry timeout (optional)
## evict steps
* s0:
1. choose one stb entry to evict (by maintaining a fifo input is new stb entry idx, output is the entry to evict)
2. send out the req valid to l1d bank input arbiter
3. if handshake, invalid the stb entry
## flush steps
1. when stb_evict_state_q is FLUSH, start to evict all the stb entries, lower all the ld st ready signal behand it until the stb is empty
*/

module rvh_l1d_stb
  import riscv_pkg::*;
  import rvh_pkg::*;
  import uop_encoding_pkg::*;
  import rvh_l1d_pkg::*;
#(
    parameter int unsigned N_STB = 8,
    parameter int unsigned N_STB_ST_IN_PORT  = 2,
    parameter int unsigned N_STB_LD_IN_PORT  = 2,
    // parameter int unsigned N_STB_OUT_PORT = 1,
    localparam int unsigned STB_ID_WIDHT = N_STB > 1 ? $clog2(N_STB) : 1
)
(
     // LS_PIPE -> STB : ST Request
    input  logic [N_STB_ST_IN_PORT-1:0]                         ls_pipe_stb_st_req_vld_i,
    input  logic [N_STB_ST_IN_PORT-1:0]                         ls_pipe_l1d_st_req_is_fence_i,
    input  logic                                                ls_pipe_l1d_st_req_no_fence_wb_resp_i,
    input  logic                                                ls_pipe_l1d_st_req_sc_rt_check_succ_i,
    input  logic [N_STB_ST_IN_PORT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_stb_st_req_rob_tag_i,
    input  logic [N_STB_ST_IN_PORT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_stb_st_req_prd_i,
    input  logic [N_STB_ST_IN_PORT-1:0][      STU_OP_WIDTH-1:0] ls_pipe_stb_st_req_opcode_i,
    input  logic [N_STB_ST_IN_PORT-1:0][       PADDR_WIDTH-1:0] ls_pipe_stb_st_req_paddr_i,
    input  logic [N_STB_ST_IN_PORT-1:0][              XLEN-1:0] ls_pipe_stb_st_req_data_i,
`ifdef RUBY
    input  logic [N_STB_ST_IN_PORT-1:0][RRV64_LSU_ID_WIDTH-1:0] ls_pipe_stb_st_req_lsu_tag_i,
`endif
    output logic [N_STB_ST_IN_PORT-1:0]                         ls_pipe_stb_st_req_rdy_o,

    // LS_PIPE -> STB : LD Request
    input  logic [N_STB_LD_IN_PORT-1:0]                         ls_pipe_stb_ld_req_vld_i,
    // input  logic [N_STB_LD_IN_PORT-1:0]                         ls_pipe_stb_ld_req_io_i,
    input  logic [N_STB_LD_IN_PORT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_stb_ld_req_rob_tag_i,
    input  logic [N_STB_LD_IN_PORT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_stb_ld_req_prd_i,
    input  logic [N_STB_LD_IN_PORT-1:0][      LDU_OP_WIDTH-1:0] ls_pipe_stb_ld_req_opcode_i,
`ifdef RUBY
    input  logic [N_STB_LD_IN_PORT-1:0][RRV64_LSU_ID_WIDTH-1:0] ls_pipe_stb_ld_req_lsu_tag_i,
`endif

    input  logic [N_STB_LD_IN_PORT-1:0][   L1D_INDEX_WIDTH-1:0] ls_pipe_stb_ld_req_idx_i,
    input  logic [N_STB_LD_IN_PORT-1:0][  L1D_OFFSET_WIDTH-1:0] ls_pipe_stb_ld_req_offset_i,
    input  logic [N_STB_LD_IN_PORT-1:0][     L1D_TAG_WIDTH-1:0] ls_pipe_stb_ld_req_vtag_i, // vtag
    input  logic [N_STB_LD_IN_PORT-1:0]                         l1d_stb_st_req_rdy_i, // stb need l1d bank rdy to hsk
    output logic [N_STB_LD_IN_PORT-1:0]                         ls_pipe_stb_ld_req_rdy_o,

    // core pipeline flush, kill load req in pipe
    input  logic                                                kill_ld_req_i,

    // LS Pipe -> STB : DTLB response
    input  logic [N_STB_LD_IN_PORT-1:0]                         ls_pipe_stb_dtlb_resp_vld_i,
    input  logic [N_STB_LD_IN_PORT-1:0][         PPN_WIDTH-1:0] ls_pipe_stb_dtlb_resp_ppn_i,
    input  logic [N_STB_LD_IN_PORT-1:0]                         ls_pipe_stb_dtlb_resp_excp_vld_i,
    input  logic [N_STB_LD_IN_PORT-1:0]                         ls_pipe_stb_dtlb_resp_hit_i,
    input  logic [N_STB_LD_IN_PORT-1:0]                         ls_pipe_stb_dtlb_resp_miss_i,

    // STB -> ROB : Write Back
    output logic [N_STB_LD_IN_PORT+N_STB_ST_IN_PORT-1:0]                    stb_rob_wb_vld_o,
    output logic [N_STB_LD_IN_PORT+N_STB_ST_IN_PORT-1:0][ROB_TAG_WIDTH-1:0] stb_rob_wb_rob_tag_o,
    // STB -> Int PRF : Write Back
    output logic [N_STB_LD_IN_PORT-1:0]                         stb_int_prf_wb_vld_o,
    output logic [N_STB_LD_IN_PORT-1:0][INT_PREG_TAG_WIDTH-1:0] stb_int_prf_wb_tag_o,
    output logic [N_STB_LD_IN_PORT-1:0][              XLEN-1:0] stb_int_prf_wb_data_o,

    output logic [N_STB_LD_IN_PORT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] stb_l1d_arb_bank_id_o,
`ifdef RUBY
    output logic [N_STB_LD_IN_PORT-1:0][RRV64_LSU_ID_WIDTH-1:0] stb_lsu_lsu_tag_o,
`endif

    // STB -> D$ Pipeline : ST Request
    output  logic /*[N_STB_OUT_PORT-1:0]*/                          stb_l1d_st_req_vld_o,
    output  logic /*[N_STB_OUT_PORT-1:0]*/[     ROB_TAG_WIDTH-1:0]  stb_l1d_st_req_rob_tag_o,
    output  logic /*[N_STB_OUT_PORT-1:0]*/[    PREG_TAG_WIDTH-1:0]  stb_l1d_st_req_prd_o,
    output  logic /*[N_STB_OUT_PORT-1:0]*/[      STU_OP_WIDTH-1:0]  stb_l1d_st_req_opcode_o,
    output  logic /*[N_STB_OUT_PORT-1:0]*/[       PADDR_WIDTH-1:0]  stb_l1d_st_req_paddr_o,
    output  logic /*[N_STB_OUT_PORT-1:0]*/[L1D_STB_DATA_WIDTH-1:0]  stb_l1d_st_req_data_o,
    output  logic                       [L1D_STB_DATA_WIDTH/8-1:0]  stb_l1d_st_req_data_byte_mask_o,
`ifdef RUBY
    output  logic                         [RRV64_LSU_ID_WIDTH-1:0]  stb_l1d_st_req_lsu_tag_o,
`endif
    output  logic                                                   stb_l1d_st_req_sc_rt_check_succ_o, // sc
    output  logic                          [ L1D_OFFSET_WIDTH-1:0]  stb_l1d_st_req_amo_offset_o, // sc

    input   logic /*[N_STB_OUT_PORT-1:0]*/                          stb_l1d_st_req_rdy_i,

    // PTW -> D$ : Request
    input  logic                          ptw_walk_req_vld_i,
    input  logic [      PTW_ID_WIDTH-1:0] ptw_walk_req_id_i,
    input  logic [       PADDR_WIDTH-1:0] ptw_walk_req_addr_i,
    input  logic                          ptw_walk_l1d_req_rdy_i,
    output logic                          ptw_walk_req_rdy_o,

    // stb in fence flush state
    output logic                                                   stb_l1d_in_fence_busy_o,

    // stb ld partial hit: replay the load
    output logic [N_STB_LD_IN_PORT-1:0]   stb_l1d_ld_partial_hit_replay_o,

    // stb ptw partial hit: replay the ptw
    output logic                          stb_l1d_ptw_partial_hit_replay_o,

    // fencei, need to firstly evict all stb entries to cache bank
    input  logic                          fencei_flush_vld_i,
    output logic                          fencei_flush_rdy_o,
    output logic                          fencei_flush_done_o,
 
    input clk,
    input rst
 );
 genvar i, j, k;
 
  // stb entry
  logic             [N_STB-1:0]               stb_entry_valid;
  logic             [N_STB-1:0]               stb_entry_valid_nxt;
  logic             [N_STB-1:0]               stb_entry_valid_ena;

  logic             [N_STB-1:0]               stb_entry_evict_at_once;
  logic             [N_STB-1:0]               stb_entry_evict_at_once_nxt;
  logic             [N_STB-1:0]               stb_entry_evict_at_once_ena;

  stb_entry_t       [N_STB-1:0]               stb_entry;
  stb_entry_t       [N_STB-1:0]               stb_entry_nxt;
  logic       [N_STB-1:0][N_STB_ST_IN_PORT-1:0]   stb_entry_nxt_new_ena_per_input;
  logic       [N_STB-1:0][N_STB_ST_IN_PORT-1:0]   stb_entry_nxt_upd_ena_per_input;
  logic       [N_STB_ST_IN_PORT-1:0][N_STB-1:0]   stb_entry_nxt_new_ena_per_input_trans;
  logic       [N_STB_ST_IN_PORT-1:0][N_STB-1:0]   stb_entry_nxt_upd_ena_per_input_trans;
  // logic       [N_STB_ST_IN_PORT-1:0][N_STB-1:0]   stb_entry_nxt_ena_per_input_trans;
  logic       [N_STB-1:0]                         stb_entry_nxt_new_ena_per_stb_entry;
  logic       [N_STB-1:0]                         stb_entry_nxt_upd_ena_per_stb_entry;
  logic       [N_STB-1:0]                         stb_entry_nxt_set_ena;

  logic       [N_STB-1:0]                         stb_entry_nxt_clr_ena_selected_evict;
  logic       [N_STB-1:0]                         stb_entry_nxt_clr_ena_in_age_evict;
  logic       [N_STB-1:0]                         stb_entry_nxt_clr_ena;
  
  logic [STB_ID_WIDHT:0]            free_stb_entry_num;
  
  // pipe reg
    // st pipe
  l1d_stb_st_pipe_reg_t [N_STB_ST_IN_PORT-1:0] st_cur, st_nxt;
  logic                 [N_STB_ST_IN_PORT-1:0] st_s1_valid;
  logic                 [N_STB_ST_IN_PORT-1:0] st_s1_nxt_ena;
  logic                 [N_STB_ST_IN_PORT-1:0] st_s1_valid_nxt;
    // ld pipe
  l1d_stb_ld_pipe_reg_t [N_STB_LD_IN_PORT-1:0] ld_cur, ld_nxt;
  logic                 [N_STB_LD_IN_PORT-1:0] ld_s1_valid, ld_s2_valid;
  logic                 [N_STB_LD_IN_PORT-1:0] ld_s1_nxt_ena, ld_s2_nxt_ena;
  logic                 [N_STB_LD_IN_PORT-1:0] ld_s1_valid_nxt, ld_s2_valid_nxt;

  // selected input/output entry
  stb_entry_t [N_STB_ST_IN_PORT-1:0]                     new_stb_entry;
  logic       [N_STB_ST_IN_PORT-1:0][STB_ID_WIDHT-1:0]   new_stb_entry_idx;
  logic       [N_STB_ST_IN_PORT-1:0]                     new_stb_entry_idx_vld;
  
  stb_entry_t [N_STB_ST_IN_PORT-1:0]                     upd_stb_entry_old;
  stb_entry_t [N_STB_ST_IN_PORT-1:0]                     upd_stb_entry_new;
  logic       [N_STB_ST_IN_PORT-1:0][STB_ID_WIDHT-1:0]   upd_stb_entry_idx;
  logic       [N_STB_ST_IN_PORT-1:0]                     upd_stb_entry_idx_vld;

  logic                                                  out_selected_stb_entry_valid;
  logic                                                  out_selected_stb_entry_hited_at_ld_s1;
  logic                                                  out_selected_stb_entry_hited_at_st_s1;
  stb_entry_t                                            out_selected_stb_entry;
  logic                                                  out_in_age_stb_entry_valid;
  logic                                                  out_in_age_stb_entry_hited_at_ld_s1;
  logic                                                  out_in_age_stb_entry_hited_at_st_s1;
  stb_entry_t                                            out_in_age_stb_entry;
  logic                                                  stb_l1d_st_req_hsk;

  // load bypass
  stb_entry_t [N_STB_LD_IN_PORT-1:0]  bps_stb_entry;
  logic       [N_STB_LD_IN_PORT-1:0]  stb_ld_bypass_full_hit;
  logic       [N_STB_LD_IN_PORT-1:0]  stb_ld_bypass_partial_hit;
  logic       [N_STB_LD_IN_PORT-1:0]  stb_ld_bypass_miss;

  // evict fsm
  l1d_stb_evict_state_t stb_evict_state_d, stb_evict_state_q;
  logic is_in_flush_stb_evict_state;
  logic is_in_selected_evict_stb_evict_state;
  logic is_in_in_age_evict_stb_evict_state;
  logic stb_evict_state_d_ena;
  logic have_stb_entry_to_flush;
  logic have_stb_entry_to_evict_at_once;
  logic have_stb_entry_to_evict_in_age;

  logic [ROB_TAG_WIDTH-1:0] flush_req_rob_tag;
  logic [ROB_TAG_WIDTH-1:0] flush_req_rob_tag_nxt;
  logic                     flush_req_rob_tag_ena;


  logic [N_STB-1:0] common_evict_mask;
  logic [N_STB-1:0] at_once_evict_mask; // the stb entry need to be evicted at once from load partial hit

  // hsk
    // st req
  logic [N_STB_ST_IN_PORT-1:0] st_req_has_free_stb_entry;
  logic [N_STB_ST_IN_PORT-1:0] st_req_rdy;
  logic [N_STB_ST_IN_PORT-1:0] st_req_hak;
    // ld req
  logic [N_STB_LD_IN_PORT-1:0] ld_req_rdy;
  logic [N_STB_LD_IN_PORT-1:0] ld_req_hak;
    // ptw req
  logic  ptw_req_rdy;
  logic  ptw_req_hak;

  // fencei
  logic fencei_flush_hsk;

  assign fencei_flush_rdy_o = ~st_s1_valid & ~ld_s1_valid & ~ld_s2_valid;
  assign fencei_flush_hsk   = fencei_flush_vld_i & fencei_flush_rdy_o;

  // fencei flush done
  assign fencei_flush_done_o      = ~(|stb_entry_valid);

  // stb in fence flush state
  assign stb_l1d_in_fence_busy_o  = is_in_flush_stb_evict_state;

  // stb ld partial hit: replay the load
  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_stb_l1d_ld_partial_hit_replay
      assign stb_l1d_ld_partial_hit_replay_o[i] = ld_s2_valid[i] & ~ld_cur[i].s2.is_ptw_ld & stb_ld_bypass_partial_hit[i];
    end
  endgenerate
  assign stb_l1d_ptw_partial_hit_replay_o = ld_s2_valid[0] & ld_cur[0].s2.is_ptw_ld & stb_ld_bypass_partial_hit[0];

  // --------------------------------------------------------
  // store req: buffer store + store merge 
  // --------------------------------------------------------
  // s0.0 check if the N_STB_ST_IN_PORT st reqs are the same cache line
    // ===== TODO: here only work for 2 input ports ======
  logic st_req_hit_the_same_cache_line;
`ifndef RUBY
  assign st_req_hit_the_same_cache_line = &ls_pipe_stb_st_req_vld_i & (ls_pipe_stb_st_req_paddr_i[0][PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE] == ls_pipe_stb_st_req_paddr_i[1][PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE]);
`else
  assign st_req_hit_the_same_cache_line = '0; // for ruby coherence test, no store merge
`endif
    // ===================================================

  // s0.1 read/comapre line addr + the st reqs at s1
  // logic [N_STB_ST_IN_PORT-1:0] s1_stb_hit_stb_entry_evict_at_the_same_cycle;
  
  logic [N_STB_ST_IN_PORT-1:0][N_STB-1:0]             st_req_hit_stb_per_entry;
  logic [N_STB_ST_IN_PORT-1:0][N_STB_ST_IN_PORT-1:0]  st_req_hit_st_pipe_s1_per_entry;
  logic [N_STB_ST_IN_PORT-1:0][N_STB-1:0][N_STB_ST_IN_PORT-1:0]   st_req_hit_st_pipe_s1_per_entry_trans_mid;
  logic [N_STB_ST_IN_PORT-1:0][N_STB-1:0]                         st_req_hit_st_pipe_s1_per_entry_trans;
  logic [N_STB_ST_IN_PORT-1:0]              st_req_hit_stb;
  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_st_req_hit_stb_per_entry
      for(j = 0; j < N_STB; j++) begin
`ifndef RUBY
        assign st_req_hit_stb_per_entry[i][j]   = (stb_entry_valid[j] & (ls_pipe_stb_st_req_paddr_i[i][PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE] == stb_entry[j].line_paddr) |   // the stb entry is valid
                                                  st_req_hit_st_pipe_s1_per_entry_trans[i][j]) &                                                                              // the stb is going to be valid at next cycle
                                                  ~(is_in_selected_evict_stb_evict_state & stb_l1d_st_req_hsk & at_once_evict_mask[j]) &                                      // the one which is evict hak at that cycle is taken as miss, this is selected evict
                                                  ~(is_in_in_age_evict_stb_evict_state & stb_l1d_st_req_hsk & common_evict_mask[j]) &                                         // the one which is evict hak at that cycle is taken as miss, this is in age evict
                                                  ~(is_in_flush_stb_evict_state & stb_l1d_st_req_hsk & common_evict_mask[j]);                                                 // the one which is evict hak at that cycle is taken as miss, this is in fence flush
`else
        assign st_req_hit_stb_per_entry[i][j]   = '0; // for ruby coherence test, no store merge
`endif
      end
      assign st_req_hit_stb[i] = |(st_req_hit_stb_per_entry[i]);
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_st_req_hit_st_pipe_s1_per_entry_trans
      for(j = 0; j < N_STB; j++) begin
        for(k = 0; k < N_STB_ST_IN_PORT; k++) begin
          assign st_req_hit_st_pipe_s1_per_entry_trans_mid[i][j][k] = (stb_entry_nxt_new_ena_per_input[j][k] | stb_entry_nxt_upd_ena_per_input[j][k]) & st_req_hit_st_pipe_s1_per_entry[i][k];
        end
        assign st_req_hit_st_pipe_s1_per_entry_trans[i][j] = |(st_req_hit_st_pipe_s1_per_entry_trans_mid[i][j]);
      end
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_st_req_hit_st_pipe_s1_per_entry
      for(j = 0; j < N_STB_ST_IN_PORT; j++) begin
        if(j == 0) begin: gen_st_req_hit_st_pipe_s1_per_entry_from_first_st_pipe // if the st reqs hit_the_same_cache_line, use pipe 0
          assign st_req_hit_st_pipe_s1_per_entry[i][j]  = st_s1_valid[j]
                                                        & (ls_pipe_stb_st_req_paddr_i[i][PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE] == st_cur[j].s1.paddr[PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE])
                                                        & (~st_cur[j].s1.stb_hit /*| s1_stb_hit_stb_entry_evict_at_the_same_cycle[j]*/);
        end else begin: gen_st_req_hit_st_pipe_s1_per_entry_from_other_st_pipe
          assign st_req_hit_st_pipe_s1_per_entry[i][j]  = st_s1_valid[j]
                                                        & (ls_pipe_stb_st_req_paddr_i[i][PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE] == st_cur[j].s1.paddr[PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE])
                                                        & (~st_cur[j].s1.stb_hit /*| s1_stb_hit_stb_entry_evict_at_the_same_cycle[j]*/)
                                                        & ~st_cur[j].s1.hit_the_same_cache_line;
        end
      end
    end
  endgenerate

  
  // s0.2 calulate free stb entry number, comb logic
  one_counter
  #(
    .DATA_WIDTH (N_STB)
  )
  free_stb_entry_num_counter_u
  (
    .data_i       (~stb_entry_valid   ),
    .cnt_o        (free_stb_entry_num )
  );

  // s0.3 st req handshake
    // ===== TODO: here only work for 2 input ports ======
  logic free_stb_entry_num_more_or_equal_one;
  logic free_stb_entry_num_more_or_equal_two;
  logic free_stb_entry_num_more_or_equal_three;
  logic s1_st_req_valid_num_equal_one;
  logic s1_st_req_valid_num_equal_two;
  logic [$clog2(3):0] higher_priority_than_s0_1_st_req_in_pipeline_num;

  logic s1_first_id_needed_vld;
  logic s1_second_id_needed_vld;

  assign s1_first_id_needed_vld   = st_s1_valid[0] & (~st_cur[0].s1.stb_hit /*| s1_stb_hit_stb_entry_evict_at_the_same_cycle[0]*/);
  assign s1_second_id_needed_vld  = st_s1_valid[1] & (~st_cur[1].s1.stb_hit /*| s1_stb_hit_stb_entry_evict_at_the_same_cycle[1]*/) & ~st_cur[1].s1.hit_the_same_cache_line;
  
  assign free_stb_entry_num_more_or_equal_one   = free_stb_entry_num >= 1;
  assign free_stb_entry_num_more_or_equal_two   = free_stb_entry_num >= 2;
  assign free_stb_entry_num_more_or_equal_three = free_stb_entry_num >= 3;
  assign free_stb_entry_num_more_or_equal_four  = free_stb_entry_num >= 4;
  
  // =============================
  // aggressive allocatation, may have bug
  // assign s1_st_req_valid_num_equal_one = (s1_first_id_needed_vld | (st_s1_valid[1] & ~st_cur[1].s1.stb_hit)) & ~s1_st_req_valid_num_equal_two;
  // assign s1_st_req_valid_num_equal_two = (s1_first_id_needed_vld & (st_s1_valid[1] & ~st_cur[1].s1.stb_hit));

  // one_counter
  // #(
  //   .DATA_WIDTH (3)
  //   )
  // higher_priority_than_s0_1_st_req_in_pipeline_num_counter_u
  // (
  //   .data_i       ({s1_first_id_needed_vld, s1_second_id_needed_vld, (ls_pipe_stb_st_req_vld_i[0] & ~st_req_hit_stb[0])}    ),
  //   .cnt_o        (higher_priority_than_s0_1_st_req_in_pipeline_num )
  // );
  // ===========================

  // conservative allocatation, take all valid st req in pipe as need to alloc new stb entry
  assign s1_st_req_valid_num_equal_one = st_s1_valid[0] ^ st_s1_valid[1];
  assign s1_st_req_valid_num_equal_two = st_s1_valid[0] & st_s1_valid[1];
  
  one_counter
  #(
    .DATA_WIDTH (3)
    )
  higher_priority_than_s0_1_st_req_in_pipeline_num_counter_u
  (
    .data_i       ({st_s1_valid[0], st_s1_valid[1], ls_pipe_stb_st_req_vld_i[0]}    ),
    .cnt_o        (higher_priority_than_s0_1_st_req_in_pipeline_num )
  );

  assign st_req_has_free_stb_entry[0] = (free_stb_entry_num_more_or_equal_one & ~s1_st_req_valid_num_equal_one & ~s1_st_req_valid_num_equal_two) |
                                        (free_stb_entry_num_more_or_equal_two & ~s1_st_req_valid_num_equal_two) |
                                        free_stb_entry_num_more_or_equal_three;
  assign st_req_has_free_stb_entry[1] = (free_stb_entry_num_more_or_equal_one   & (higher_priority_than_s0_1_st_req_in_pipeline_num == 0)) |  // stb 1 free, none of s0[0], s1[0], s1[1] can be valid
                                        (free_stb_entry_num_more_or_equal_two   & (higher_priority_than_s0_1_st_req_in_pipeline_num <= 1)) |  // stb 2 free, one of s0[0], s1[0], s1[1] can be valid
                                        (free_stb_entry_num_more_or_equal_three & (higher_priority_than_s0_1_st_req_in_pipeline_num <= 2)) |  // stb 3 free, two of s0[0], s1[0], s1[1] can be valid
                                        (free_stb_entry_num_more_or_equal_four);                                                              // stb 4 free, all of s0[0], s1[0], s1[1] can be valid

    // ===================================================

  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s0_st_req_rdy
      if(i == 0) begin: gen_st_req_rdy_for_first_port
        assign st_req_rdy[i]  = (st_req_hit_stb[i] |              // st req hit stb entry
                                st_req_has_free_stb_entry[i]) &   // st req miss stb entry, need to have enough free stb entry
                                ~is_in_flush_stb_evict_state;     // if stb is in fence flush state, don't take any other req
      end
      else begin: gen_st_req_rdy_for_other_port
        assign st_req_rdy[i]  = (st_req_hit_stb[i] |              // st req hit stb entry
                                st_req_has_free_stb_entry[i]) &   // st req miss stb entry, need to have enough free stb entry
                                ~is_in_flush_stb_evict_state  &   // if stb is in fence flush state, don't take any other req
                                ~(|(ls_pipe_stb_st_req_vld_i[i-1:0] & ls_pipe_l1d_st_req_is_fence_i[i-1:0])) & // if higher priority port is a fence, don't take req from lower priority
                                ~ls_pipe_l1d_st_req_is_fence_i[i] & // only take fence from port 0
                                ((&(ls_pipe_stb_st_req_vld_i[i-1:0] & st_req_rdy[i-1:0])) | ~(|ls_pipe_stb_st_req_vld_i[i-1:0])); // in order store, if higher priority port not ready, lower priority port is not ready too
      end
      assign ls_pipe_stb_st_req_rdy_o[i] = st_req_rdy[i];
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s0_st_req_hsk
      assign st_req_hak[i]  = ls_pipe_stb_st_req_vld_i[i] & st_req_rdy[i];
    end
  endgenerate

  // s1.0 common logic between st req hit and miss
  // s1.0.0 trans XLEN st req into cache line size
  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH-1:0]      s1_st_req_data_transed; // stb data length data 
  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH/8-1:0]    s1_st_req_data_byte_mask_transed; // stb data length write byte mask 
  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH/8-1:0]    s1_st_req_data_byte_mask_transed_mid; // stb data length write byte mask 
  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH-1:0]      s1_st_req_data_bit_mask_transed; // stb data length write bit mask 
  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s1_st_xlen_stb_length_trans
      rrv2rvh_ruby_stmask_trans stb_stmask_trans_st_req_u
      (
        .st_dat_i                             (st_cur[i].s1.data                            ),
        .st_offset_i                          (st_cur[i].s1.paddr[L1D_OFFSET_WIDTH-1:0]     ),
        .st_opcode_i                          (st_cur[i].s1.opcode                          ),
        .ls_pipe_l1d_st_req_data_o            (s1_st_req_data_transed          [i]          ), // data from stb
        .ls_pipe_l1d_st_req_data_byte_mask_o  (s1_st_req_data_byte_mask_transed[i]          )  // data byte mask from stb
      );
      assign s1_st_req_data_byte_mask_transed_mid[i] = s1_st_req_data_byte_mask_transed[i] & {(L1D_STB_DATA_WIDTH/8){st_s1_valid[i]}};
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s1_st_req_data_bit_mask_transed
      for(j = 0; j < L1D_STB_DATA_WIDTH; j++) begin
        assign s1_st_req_data_bit_mask_transed[i][j] = s1_st_req_data_byte_mask_transed_mid[i][j/8];
      end
    end
  endgenerate

  // s1.0.1 if the st req hit the same cache line, their data and write mask need to be merged, and the port with larger port id should overwrite smaller one if there is interleave among the st req
    // ===== TODO: here only work for 2 input ports ======
  logic [L1D_STB_DATA_WIDTH-1:0]      s1_st_req_data_merged;                  // stb data length data 
  logic [L1D_STB_DATA_WIDTH-1:0]      s1_st_req_data_bit_mask_merged;         // stb data length write bit mask 
  logic [L1D_STB_DATA_WIDTH/8-1:0]    s1_st_req_data_byte_mask_merged;        // stb data length write byte mask 
  logic [L1D_STB_DATA_WIDTH-1:0]      s1_st_req_data_bit_mask_interleaved;    // stb data length write mask 
  assign s1_st_req_data_bit_mask_interleaved  = s1_st_req_data_bit_mask_transed[0] & s1_st_req_data_bit_mask_transed[1];
  assign s1_st_req_data_bit_mask_merged       = s1_st_req_data_bit_mask_transed[0] | s1_st_req_data_bit_mask_transed[1];
  assign s1_st_req_data_byte_mask_merged      = s1_st_req_data_byte_mask_transed_mid[0] | s1_st_req_data_byte_mask_transed_mid[1];
  assign s1_st_req_data_merged                = ((s1_st_req_data_transed[0] & s1_st_req_data_bit_mask_transed[0]) | (s1_st_req_data_transed[1] & s1_st_req_data_bit_mask_transed[1])) & ~s1_st_req_data_bit_mask_interleaved | // uninterleaved part
                                                s1_st_req_data_transed[1] & s1_st_req_data_bit_mask_interleaved;  // interleaved part, the port with larger port id should overwrite smaller one if there is interleave among the st req
    // ===================================================



  // s1.1 if st req miss: alloc new stb entry
  // s1.1.0 new stb entry gen
  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s1_new_stb_entry
      // // ctrl
      // // assign new_stb_entry[i].valid             = st_s1_valid[i] & ~st_cur[i].s1.stb_hit & new_stb_entry_idx_vld[i]; // for miss st req, alloc new stb entry
      // assign new_stb_entry[i].valid             = 1'b1; // for miss st req, alloc new stb entry

      // data
      assign new_stb_entry[i].rob_tag           = st_cur[i].s1.rob_tag;
      assign new_stb_entry[i].prd               = st_cur[i].s1.prd;
      assign new_stb_entry[i].opcode            = st_cur[i].s1.opcode;
      assign new_stb_entry[i].line_paddr        = st_cur[i].s1.paddr[PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE];
      assign new_stb_entry[i].line_data         = st_cur[i].s1.hit_the_same_cache_line ? s1_st_req_data_merged            : s1_st_req_data_transed[i]; 
      assign new_stb_entry[i].write_byte_mask   = st_cur[i].s1.hit_the_same_cache_line ? s1_st_req_data_byte_mask_merged  : s1_st_req_data_byte_mask_transed_mid[i];
`ifdef RUBY
      assign new_stb_entry[i].lsu_tag           = st_cur[i].s1.lsu_tag;
`endif
      assign new_stb_entry[i].sc_rt_check_succ  = st_cur[i].s1.sc_rt_check_succ; // sc
      assign new_stb_entry[i].amo_offset        = st_cur[i].s1.paddr[L1D_OFFSET_WIDTH-1:0];
    end
  endgenerate

`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rst) (s1_first_id_needed_vld)|-> new_stb_entry_idx_vld[0])
    else $fatal("st pipe 0: stb fail to alloc new stb entry at s1");
  assert property(@(posedge clk)disable iff(~rst) (s1_second_id_needed_vld)|-> new_stb_entry_idx_vld[1])
    else $fatal("st pipe 1: stb fail to alloc new stb entry at s1");
`endif

  // s1.1.1 select new stb entry idx
    // ===== TODO: here only work for 2 input ports ======
  select_two_from_n_valid
  #(
      .SEL_WIDTH    (N_STB)
  )
  select_new_stb_entry_idx_u
  (
      .sel_i              (~stb_entry_valid         ),
      .first_id_needed_vld_i  (s1_first_id_needed_vld),
      .second_id_needed_vld_i (s1_second_id_needed_vld),
      .first_id_vld_o     (new_stb_entry_idx_vld[0] ),
      .second_id_vld_o    (new_stb_entry_idx_vld[1] ),
      .first_id_o         (new_stb_entry_idx[0]     ),
      .second_id_o        (new_stb_entry_idx[1]     )
  );

  // s1.2 if st req hit: select the hit entry idx, merge and gen new stb entry to update stb
  // s1.2.0 upd stb select
  always_comb begin: comb_s1_upd_stb_entry_select
    upd_stb_entry_idx = '0;
    for(int i = 0; i < N_STB_ST_IN_PORT; i++) begin
      for(int j = 0; j < N_STB; j++) begin
        if(st_cur[i].s1.stb_hit_entry_mask[j] == 1'b1) begin
          upd_stb_entry_idx[i] = j[STB_ID_WIDHT-1:0];
        end
      end
    end
  end
  
  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s1_upd_stb_entry_old
      assign upd_stb_entry_idx_vld[i] = st_cur[i].s1.stb_hit /*& ~s1_stb_hit_stb_entry_evict_at_the_same_cycle[i]*/;
      assign upd_stb_entry_old    [i] = stb_entry[upd_stb_entry_idx[i]];
    end
  endgenerate

  // s1.2.1 merge and update stb entry
  // logic [L1D_STB_DATA_WIDTH-1:0]      s1_st_req_data_merged;                  // stb data length data 
  // logic [L1D_STB_DATA_WIDTH/8-1:0]    s1_st_req_data_byte_mask_merged;        // stb data length write mask 
  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH/8-1:0]    s1_st_req_upd_old_byte_mask_interleaved;  // stb data length write byte mask 
  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH-1:0]      s1_st_req_upd_old_bit_mask_interleaved;   // stb data length write bit mask 
  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH-1:0]      s1_st_req_data_selected;                  // stb data length data 
  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH/8-1:0]    s1_st_req_data_byte_mask_selected;        // stb data length write byte mask 
  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH-1:0]      s1_st_req_data_bit_mask_selected;         // stb data length write bit mask 

  logic [N_STB_ST_IN_PORT-1:0][L1D_STB_DATA_WIDTH-1:0]      s1_upd_stb_entry_old_write_bit_mask;

  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s1_st_req_data_bit_mask
      for(j = 0; j < L1D_STB_DATA_WIDTH; j++) begin
        assign s1_st_req_upd_old_bit_mask_interleaved [i][j]  = s1_st_req_upd_old_byte_mask_interleaved [i][j/8];
        assign s1_st_req_data_bit_mask_selected       [i][j]  = s1_st_req_data_byte_mask_selected       [i][j/8];
        assign s1_upd_stb_entry_old_write_bit_mask    [i][j]  = upd_stb_entry_old[i].write_byte_mask       [j/8];
      end
    end
  endgenerate


  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s1_st_req_data_selected
      assign s1_st_req_data_selected[i]           = st_cur[i].s1.hit_the_same_cache_line  ? s1_st_req_data_merged
                                                                                          : s1_st_req_data_transed[i];
      assign s1_st_req_data_byte_mask_selected[i] = st_cur[i].s1.hit_the_same_cache_line  ? s1_st_req_data_byte_mask_merged
                                                                                          : s1_st_req_data_byte_mask_transed_mid[i];
      assign s1_st_req_upd_old_byte_mask_interleaved[i] = (s1_st_req_data_byte_mask_selected[i] & upd_stb_entry_old[i].write_byte_mask);
    end

    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s1_upd_stb_entry_new
      assign upd_stb_entry_new[i].rob_tag               = upd_stb_entry_old[i].rob_tag;
      assign upd_stb_entry_new[i].prd                   = upd_stb_entry_old[i].prd;
      assign upd_stb_entry_new[i].opcode                = upd_stb_entry_old[i].opcode;
      assign upd_stb_entry_new[i].line_paddr            = upd_stb_entry_old[i].line_paddr;
`ifdef RUBY
      assign upd_stb_entry_new[i].lsu_tag               = upd_stb_entry_old[i].lsu_tag;
`endif

      assign upd_stb_entry_new[i].write_byte_mask       = (s1_st_req_data_byte_mask_selected[i] | upd_stb_entry_old[i].write_byte_mask);
      assign upd_stb_entry_new[i].line_data             = ((s1_st_req_data_selected[i] & s1_st_req_data_bit_mask_selected[i]) | (upd_stb_entry_old[i].line_data & s1_upd_stb_entry_old_write_bit_mask[i])) & ~s1_st_req_upd_old_bit_mask_interleaved[i] |
                                                          s1_st_req_data_selected[i] & s1_st_req_upd_old_bit_mask_interleaved[i];

      assign upd_stb_entry_new[i].sc_rt_check_succ      = upd_stb_entry_old[i].sc_rt_check_succ; // amo,lr,sc will not have merge req
      assign upd_stb_entry_new[i].amo_offset            = upd_stb_entry_old[i].amo_offset;       // amo,lr,sc will not have merge req
    end
  endgenerate

  // s1.3 update stb
  // s1.3.0 generate stb_entry_nxt_set_ena
`ifndef SYNTHESIS
  logic [N_STB-1:0] stb_entry_nxt_ena_per_stb_entry_interleave;
`endif

  // // if the ld hit with a about to evict stb entry at the same cycle, the stb entry evict is stalled so no need to take it as a miss
  // generate
  //   for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s1_stb_hit_stb_entry_evict_at_the_same_cycle
  //     assign s1_stb_hit_stb_entry_evict_at_the_same_cycle[i] = |(st_cur[i].s1.stb_hit_entry_mask & stb_entry_nxt_clr_ena); //while the st req at s1 is hit a stb entry, the stb entry is evicting at the same cycle and will be invalid at next cycle
  //   end
  // endgenerate

  generate
    for(i = 0; i < N_STB; i++) begin: gen_stb_entry_nxt_ena
      for(j = 0; j < N_STB_ST_IN_PORT; j++) begin: gen_stb_entry_nxt_ena_per_input
        if(j == 0) begin: gen_stb_entry_nxt_new_ena_for_first_pipe // if the st reqs hit_the_same_cache_line, use pipe 0
          assign stb_entry_nxt_new_ena_per_input[i][j] = (i[STB_ID_WIDHT-1:0] == new_stb_entry_idx[j]) & new_stb_entry_idx_vld[j] & st_s1_valid[j] & (~st_cur[j].s1.stb_hit /*| s1_stb_hit_stb_entry_evict_at_the_same_cycle[j]*/);
          assign stb_entry_nxt_upd_ena_per_input[i][j] = (i[STB_ID_WIDHT-1:0] == upd_stb_entry_idx[j]) & upd_stb_entry_idx_vld[j] & st_s1_valid[j] &  st_cur[j].s1.stb_hit;
        end else begin: gen_stb_entry_nxt_new_ena_for_other_pipe
          assign stb_entry_nxt_new_ena_per_input[i][j] = (i[STB_ID_WIDHT-1:0] == new_stb_entry_idx[j]) & new_stb_entry_idx_vld[j] & st_s1_valid[j] & (~st_cur[j].s1.stb_hit /*| s1_stb_hit_stb_entry_evict_at_the_same_cycle[j]*/) & ~st_cur[j].s1.hit_the_same_cache_line;
          assign stb_entry_nxt_upd_ena_per_input[i][j] = (i[STB_ID_WIDHT-1:0] == upd_stb_entry_idx[j]) & upd_stb_entry_idx_vld[j] & st_s1_valid[j] &  st_cur[j].s1.stb_hit & ~st_cur[j].s1.hit_the_same_cache_line;
        end
      end
      assign stb_entry_nxt_new_ena_per_stb_entry[i] = |(stb_entry_nxt_new_ena_per_input[i]);
      assign stb_entry_nxt_upd_ena_per_stb_entry[i] = |(stb_entry_nxt_upd_ena_per_input[i]);
      assign stb_entry_nxt_set_ena[i] = stb_entry_nxt_new_ena_per_stb_entry[i] | stb_entry_nxt_upd_ena_per_stb_entry[i];

`ifndef SYNTHESIS
      assign stb_entry_nxt_ena_per_stb_entry_interleave[i] = stb_entry_nxt_new_ena_per_stb_entry[i] & stb_entry_nxt_upd_ena_per_stb_entry[i];
      assert property(@(posedge clk)disable iff(~rst) ( stb_entry_nxt_ena_per_stb_entry_interleave[i] == '0 ))
              else $fatal("stb try to alloc and update the same stb entry at the same time");
`endif
    end
  endgenerate

  // s1.3.1 generate stb_entry_nxt_clr_ena
  assign stb_entry_nxt_clr_ena = stb_entry_nxt_clr_ena_selected_evict | stb_entry_nxt_clr_ena_in_age_evict;
  always_comb begin: comb_stb_entry_nxt_clr_ena
    stb_entry_nxt_clr_ena_selected_evict = '0;
    stb_entry_nxt_clr_ena_in_age_evict   = '0;
    if(stb_l1d_st_req_hsk) begin
      if(is_in_selected_evict_stb_evict_state) begin
        stb_entry_nxt_clr_ena_selected_evict = at_once_evict_mask;
      end 
      else if(is_in_in_age_evict_stb_evict_state | is_in_flush_stb_evict_state) begin
        stb_entry_nxt_clr_ena_in_age_evict = common_evict_mask;
      end
    end
  end

  

  // s1.3.2 for each next stb entry, which input port should it connect to
  logic [N_STB-1:0][$clog2(N_STB_ST_IN_PORT)-1:0] stb_input_port_idx_per_new_stb_entry;
  logic [N_STB-1:0][$clog2(N_STB_ST_IN_PORT)-1:0] stb_input_port_idx_per_upd_stb_entry;

  always_comb begin: comb_stb_input_port_idx_per_new_stb_entry
    stb_input_port_idx_per_new_stb_entry = '0;
    for(int i = 0; i < N_STB; i++) begin
      for(int j = 0; j < N_STB_ST_IN_PORT; j++) begin
        if(stb_entry_nxt_new_ena_per_input[i][j]) begin
          stb_input_port_idx_per_new_stb_entry[i] = j[$clog2(N_STB_ST_IN_PORT)-1:0];
        end
      end
    end
  end

  always_comb begin: comb_stb_input_port_idx_per_upd_stb_entry
    stb_input_port_idx_per_upd_stb_entry = '0;
    for(int i = 0; i < N_STB; i++) begin
      for(int j = 0; j < N_STB_ST_IN_PORT; j++) begin
        if(stb_entry_nxt_upd_ena_per_input[i][j]) begin
          stb_input_port_idx_per_upd_stb_entry[i] = j[$clog2(N_STB_ST_IN_PORT)-1:0];
        end
      end
    end
  end

  // s1.3.3 generate stb_entry_nxt
  generate
    for(i = 0; i < N_STB; i++) begin: gen_stb_entry_nxt
      assign stb_entry_nxt[i] = stb_entry_nxt_new_ena_per_stb_entry[i] ? new_stb_entry     [stb_input_port_idx_per_new_stb_entry[i]] 
                                                                       : upd_stb_entry_new [stb_input_port_idx_per_upd_stb_entry[i]];
    end
  endgenerate

  // s1.3.4 update stb
  generate
    for(i = 0; i < N_STB; i++) begin: gen_update_stb
      std_dffre #(.WIDTH($bits(stb_entry_t))) U_L1D_STB_ENTRY (.clk(clk), .rstn(rst), .en(stb_entry_nxt_set_ena[i]), .d(stb_entry_nxt[i]), .q(stb_entry[i]));
    end
  endgenerate

  // s1.3.5 update stb valid
  generate
    for(i = 0; i < N_STB; i++) begin: gen_stb_entry_valid_nxt
      assign stb_entry_valid_nxt[i] = (stb_entry_nxt_set_ena[i] | stb_entry_valid[i]) & ~stb_entry_nxt_clr_ena[i];
      // assign stb_entry_valid_nxt[i] = stb_entry_nxt_set_ena[i] ? 1'b1 : stb_entry_valid[i] & ~stb_entry_nxt_clr_ena[i];
    end
  endgenerate

  // set valid when new st req alloc new stb entry, clear when stb write req hsk to l1d bank
  logic [N_STB-1:0] stb_entry_valid_set_ena;
  logic [N_STB-1:0] stb_entry_valid_clr_ena;
  assign stb_entry_valid_set_ena = stb_entry_nxt_set_ena;
  assign stb_entry_valid_clr_ena = stb_entry_nxt_clr_ena;
  assign stb_entry_valid_ena = stb_entry_nxt_set_ena | stb_entry_nxt_clr_ena;

  generate
    for(i = 0; i < N_STB; i++) begin: gen_update_stb_entry_valid
      std_dffre #(.WIDTH(1)) U_STB_ENTRY_VALID (.clk(clk), .rstn(rst), .en(stb_entry_valid_ena[i]), .d(stb_entry_valid_nxt[i]), .q(stb_entry_valid[i]));
    end
  endgenerate
  // --------------------------------------------------------




  // --------------------------------------------------------
  // load req: load bypass
  // --------------------------------------------------------
  // s0 as vipt, no physical tag at s0, do nothing, just take the load req
  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s0_ld_req_rdy
      assign ld_req_rdy[i]  = ~is_in_flush_stb_evict_state  &   // if stb is in flush state, don't take any other req
                              ~have_stb_entry_to_flush &        // if st port have a fence, don't take load req
                              ~ptw_walk_req_vld_i;              // ptw req has higher priority
      assign ls_pipe_stb_ld_req_rdy_o[i] = ld_req_rdy[i];
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s0_ld_req_hsk
      assign ld_req_hak[i]  = ls_pipe_stb_ld_req_vld_i[i] & ld_req_rdy[i] & l1d_stb_st_req_rdy_i[i];
    end
  endgenerate

  // take ptw req as a ld req
  assign ptw_req_rdy    = ~is_in_flush_stb_evict_state  &   // if stb is in flush state, don't take any other req
                          ~have_stb_entry_to_flush;         // if st port have a fence, don't take load req
  assign ptw_walk_req_rdy_o = ptw_req_rdy;

  assign ptw_req_hak    = ptw_walk_req_vld_i & ptw_req_rdy & ptw_walk_l1d_req_rdy_i;

  // s1 comare with stb entry: get tlb resp, read/comapre line addr, the one which is evict hak at that cycle is taken as miss
  // s1.0 get tlb resp, generate physical addr
  logic[N_STB_LD_IN_PORT-1:0][L1D_BANK_PADDR_TAG_WIDTH-1:0] s1_ld_req_paddr_tag_from_tlb;
  logic[N_STB_LD_IN_PORT-1:0][L1D_STB_LINE_ADDR_SIZE-1:0]   s1_ld_req_line_paddr;

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s1_ld_req_paddr_tag_from_tlb
      if(L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH >= 12) begin: gen_ptag_from_part_of_ppn
        assign s1_ld_req_paddr_tag_from_tlb[i] = ls_pipe_stb_dtlb_resp_ppn_i[i][PPN_WIDTH-1:((L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH)-12)];
      end else begin: gen_ptag_from_ppn_plus_part_of_vtag
        assign s1_ld_req_paddr_tag_from_tlb[i] = {ls_pipe_stb_dtlb_resp_ppn_i[i], ld_cur[i].s1.vtag[(12-(L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH))-1:0]};
      end
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s1_ld_req_line_paddr
      assign s1_ld_req_line_paddr[i] = ld_cur[i].s1.is_ptw_ld ? {ld_cur[i].s1.vtag, ld_cur[i].s1.index}
                                                              : {s1_ld_req_paddr_tag_from_tlb[i], ld_cur[i].s1.index};
    end
  endgenerate

  // s1.1 comapre ld req line addr against stb entry + the st reqs at s1
  logic [N_STB_LD_IN_PORT-1:0][N_STB-1:0]             ld_req_hit_stb_per_entry;
  logic [N_STB_LD_IN_PORT-1:0][N_STB_ST_IN_PORT-1:0]  ld_req_hit_st_pipe_s1_per_entry;
  logic [N_STB_LD_IN_PORT-1:0][N_STB-1:0][N_STB_ST_IN_PORT-1:0]   ld_req_hit_st_pipe_s1_per_entry_trans_mid;
  logic [N_STB_LD_IN_PORT-1:0][N_STB-1:0]                         ld_req_hit_st_pipe_s1_per_entry_trans;
  logic [N_STB_LD_IN_PORT-1:0]                        ld_req_hit_stb;
  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_ld_req_hit_stb_per_entry
      for(j = 0; j < N_STB; j++) begin
        assign ld_req_hit_stb_per_entry[i][j]   = (stb_entry_valid[j] & (s1_ld_req_line_paddr[i] == stb_entry[j].line_paddr) |  // the stb entry is valid
                                                  ld_req_hit_st_pipe_s1_per_entry_trans[i][j]);                                 // the stb is going to be valid at next cycle
                                                  // if the ld hit with a about to evict stb entry at the same cycle, the stb entry evict is stalled so no need to take it as a miss
                                                  // ~(is_in_selected_evict_stb_evict_state & stb_l1d_st_req_hsk & at_once_evict_mask[j]) & // the one which is evict hak at that cycle is taken as miss, this is selected evict
                                                  // ~(is_in_in_age_evict_stb_evict_state & stb_l1d_st_req_hsk & common_evict_mask[j]) &    // the one which is evict hak at that cycle is taken as miss, this is in age evict
                                                  // ~(is_in_flush_stb_evict_state & stb_l1d_st_req_hsk & common_evict_mask[j]);            // the one which is evict hak at that cycle is taken as miss, this is in flush
      end
      assign ld_req_hit_stb[i] = |(ld_req_hit_stb_per_entry[i]);
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_ld_req_hit_st_pipe_s1_per_entry_trans
      for(j = 0; j < N_STB; j++) begin
        for(k = 0; k < N_STB_ST_IN_PORT; k++) begin
          assign ld_req_hit_st_pipe_s1_per_entry_trans_mid[i][j][k] = (stb_entry_nxt_new_ena_per_input[j][k] | stb_entry_nxt_upd_ena_per_input[j][k]) & ld_req_hit_st_pipe_s1_per_entry[i][k];
        end
        assign ld_req_hit_st_pipe_s1_per_entry_trans[i][j] = |(ld_req_hit_st_pipe_s1_per_entry_trans_mid[i][j]);
      end
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_ld_req_hit_st_pipe_s1_per_entry
      for(j = 0; j < N_STB_ST_IN_PORT; j++) begin
        if(j == 0) begin: gen_ld_req_hit_st_pipe_s1_per_entry_from_first_st_pipe // if the st reqs hit_the_same_cache_line, use pipe 0
          assign ld_req_hit_st_pipe_s1_per_entry[i][j]  = st_s1_valid[j]
                                                        & (s1_ld_req_line_paddr[i] == st_cur[j].s1.paddr[PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE])
                                                        & ~st_cur[j].s1.stb_hit;
        end else begin: gen_ld_req_hit_st_pipe_s1_per_entry_from_other_st_pipe
          assign ld_req_hit_st_pipe_s1_per_entry[i][j]  = st_s1_valid[j]
                                                        & (s1_ld_req_line_paddr[i] == st_cur[j].s1.paddr[PADDR_WIDTH-1-:L1D_STB_LINE_ADDR_SIZE])
                                                        & ~st_cur[j].s1.stb_hit
                                                        & ~st_cur[j].s1.hit_the_same_cache_line;
        end
      end
    end
  endgenerate

  // s2 resp: if full hit: resp data; if partial hit: ldq replay, force the stb entry go into l1d bank; if miss: no resp
  // s2.0 generate ld req byte mask by opcode and offset
  logic [N_STB_LD_IN_PORT-1:0][L1D_STB_DATA_WIDTH/8-1:0]    s2_ld_req_data_byte_mask_transed; // stb data length read byte mask 
  logic [N_STB_LD_IN_PORT-1:0][L1D_STB_DATA_WIDTH-1:0]    s2_ld_req_data_bit_mask_transed; // stb data length read bit mask 
  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s2_ld_xlen_stb_length_trans
      rrv2rvh_ruby_ldmask_trans stb_ldmask_trans_ld_req_u
      (
        .ld_offset_i                          (ld_cur[i].s2.offset       ),
        .ld_opcode_i                          (ld_cur[i].s2.opcode       ),
        .ls_pipe_l1d_ld_req_data_byte_mask_o  (s2_ld_req_data_byte_mask_transed[i] )// data byte mask from stb
      );
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s2_ld_req_data_bit_mask_transed
      for(j = 0; j < L1D_STB_DATA_WIDTH; j++) begin
        assign s2_ld_req_data_bit_mask_transed[i][j] = s2_ld_req_data_byte_mask_transed[i][j/8];
      end
    end
  endgenerate

  // s2.1 compare the ld req byte mask against the hit stb entries found at s1
  // s2.1.0 select the hit stb entry
  always_comb begin
    for(int i = 0; i < N_STB_LD_IN_PORT; i++) begin
      bps_stb_entry[i] = '0;
      for(int j = 0; j < N_STB; j++) begin
        if(ld_cur[i].s2.stb_hit_per_entry[j]) begin
          bps_stb_entry[i] = stb_entry[j];
        end
      end
    end
  end

  // s2.1.1 compare the ld req byte mask against the hit stb entries found at s1
  logic [N_STB_LD_IN_PORT-1:0][L1D_STB_DATA_WIDTH/8-1:0]  s2_ld_req_data_byte_mask_interleaved;
  logic [N_STB_LD_IN_PORT-1:0]                            s2_ld_req_data_byte_mask_interleaved_equal;
  logic [N_STB_LD_IN_PORT-1:0]                            s2_ld_req_data_byte_mask_interleaved_valid;

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s2_ld_req_data_byte_mask_interleaved
      assign s2_ld_req_data_byte_mask_interleaved[i] = s2_ld_req_data_byte_mask_transed[i] & bps_stb_entry[i].write_byte_mask;
    end
      
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_stb_ld_bypass_hit
      assign s2_ld_req_data_byte_mask_interleaved_equal[i] = (s2_ld_req_data_byte_mask_interleaved[i] == s2_ld_req_data_byte_mask_transed[i]);
      assign s2_ld_req_data_byte_mask_interleaved_valid[i] = |(s2_ld_req_data_byte_mask_interleaved[i]);
      assign stb_ld_bypass_full_hit   [i] = s2_ld_req_data_byte_mask_interleaved_equal[i];
      assign stb_ld_bypass_partial_hit[i] = ~s2_ld_req_data_byte_mask_interleaved_equal[i] & s2_ld_req_data_byte_mask_interleaved_valid[i];
      assign stb_ld_bypass_miss       [i] = ~s2_ld_req_data_byte_mask_interleaved_valid[i];
    end
  endgenerate

  // s2.2 ld resp: if full hit: resp data; if partial hit: ldq replay, force the stb entry go into l1d bank; if miss: no resp
  // s2.2.0 if full hit: resp data
  logic [N_STB_LD_IN_PORT-1:0][L1D_STB_DATA_WIDTH-1:0] full_hit_line_data_mid;
  logic [N_STB_LD_IN_PORT-1:0][L1D_STB_DATA_WIDTH-1:0] full_hit_xlen_data;
  logic [N_STB_LD_IN_PORT-1:0][L1D_BIT_OFFSET_WIDTH-1:0] ld_cur_s2_bit_offset;

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_full_hit_line_data
      assign ld_cur_s2_bit_offset[i]    = ld_cur[i].s2.offset << 3;
      assign full_hit_line_data_mid[i]  = (s2_ld_req_data_bit_mask_transed[i] & bps_stb_entry[i].line_data) >> ld_cur_s2_bit_offset[i];
      assign full_hit_xlen_data[i]      = full_hit_line_data_mid[i][XLEN-1:0];
    end
  endgenerate

    // for ld req full hit
  generate
    // ctrl
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_wb_vld_for_load_bypass_o
      assign stb_rob_wb_vld_o[i]      = ld_s2_valid[i] & stb_ld_bypass_full_hit[i] & (~kill_ld_req_i | ld_cur[i].s2.is_ptw_ld);
      assign stb_int_prf_wb_vld_o[i]  = stb_rob_wb_vld_o[i];
    end
    // data
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_wb_dat_o
      assign stb_rob_wb_rob_tag_o [i]   = ld_cur[i].s2.rob_tag;
      assign stb_int_prf_wb_tag_o [i]   = ld_cur[i].s2.prd;
      assign stb_int_prf_wb_data_o[i]   = full_hit_xlen_data[i];
      assign stb_l1d_arb_bank_id_o[i]   = bps_stb_entry[i].line_paddr[L1D_BANK_ID_INDEX_WIDTH-1:0];
`ifdef RUBY
      assign stb_lsu_lsu_tag_o    [i]   = ld_cur[i].s2.lsu_tag;
`endif
    end
  endgenerate



  // s2.2.1 if partial hit: ldq replay, set the stb entry evict_at_once bit
  logic[N_STB_LD_IN_PORT-1:0][N_STB-1:0]  stb_entry_evict_at_once_nxt_mid;
  logic[N_STB-1:0][N_STB_LD_IN_PORT-1:0]  stb_entry_evict_at_once_nxt_mid_trans;
  always_comb begin: comb_stb_entry_evict_at_once_nxt_mid
    for(int i = 0; i < N_STB_LD_IN_PORT; i++) begin
      stb_entry_evict_at_once_nxt_mid[i] = stb_entry_evict_at_once;
      if(stb_l1d_ld_partial_hit_replay_o[i]) begin
        stb_entry_evict_at_once_nxt_mid[i] = ld_cur[i].s2.stb_hit_per_entry | stb_entry_evict_at_once;
      end
    end
  end

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_stb_entry_evict_at_once_nxt_mid_trans
      for(j = 0; j < N_STB; j++) begin
        assign stb_entry_evict_at_once_nxt_mid_trans[j][i] = stb_entry_evict_at_once_nxt_mid[i][j];
      end
    end
  endgenerate

  generate
    for(i = 0; i < N_STB; i++) begin: gen_stb_entry_evict_at_once_nxt
      assign stb_entry_evict_at_once_nxt[i] = (|(stb_entry_evict_at_once_nxt_mid_trans[i])) & ~stb_entry_nxt_new_ena_per_stb_entry[i];
    end
  endgenerate

  // set valid when ld find partial hit on a stb entry, clear when new st req alloc new stb entry
  logic [N_STB-1:0] stb_entry_evict_at_once_set_ena;
  logic [N_STB-1:0] stb_entry_evict_at_once_clr_ena;
  assign stb_entry_evict_at_once_set_ena  = {N_STB{{|stb_l1d_ld_partial_hit_replay_o}}};
  assign stb_entry_evict_at_once_clr_ena  = stb_entry_valid_set_ena;
  assign stb_entry_evict_at_once_ena      = stb_entry_evict_at_once_set_ena | stb_entry_evict_at_once_clr_ena;

  generate
    for(i = 0; i < N_STB; i++) begin: gen_stb_entry_evict_at_once
      std_dffre #(.WIDTH(1)) U_STB_ENTRY_EVICT_AT_ONCE (.clk(clk), .rstn(rst), .en(stb_entry_evict_at_once_ena[i]), .d(stb_entry_evict_at_once_nxt[i]), .q(stb_entry_evict_at_once[i]));
    end
  endgenerate

  // s2.2.2 if miss: no resp


  // --------------------------------------------------------
  // eviction
  // ## eviction priority
  // 1. stb flush (evict all)
  // 1. coherence snoop hit: can't be ignored, if there is higher priority evict req at the same cycle, let the snoop reg wait
  // 2. load partial hit: can be ignored if there is higher priority evict req at the same cycle, so set the stb entry's evict_at_once bit, let it evict as soon as no higher priority evict req
  // 3. stb full: in age evict
  // 4. stb entry timeout (optional)
  // --------------------------------------------------------
  
  // stb entry age matrix
  logic[N_STB_ST_IN_PORT-1:0] s1_st_req_in_valid;
  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin
      if(i == 0) begin: gen_s1_st_req_in_valid_for_first_pipe
        assign s1_st_req_in_valid[i] = st_s1_valid[i] & (~st_cur[i].s1.stb_hit /*| s1_stb_hit_stb_entry_evict_at_the_same_cycle[i]*/);
      end else begin: gen_s1_st_req_in_valid_for_other_pipe
        assign s1_st_req_in_valid[i] = st_s1_valid[i] & (~st_cur[i].s1.stb_hit /*| s1_stb_hit_stb_entry_evict_at_the_same_cycle[i]*/) & ~st_cur[i].s1.hit_the_same_cache_line;
      end
    end
  endgenerate
  
  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_stb_entry_nxt_ena_per_input_trans
      for( j = 0; j < N_STB; j++) begin
        assign stb_entry_nxt_new_ena_per_input_trans[i][j] = stb_entry_nxt_new_ena_per_input[j][i];
        assign stb_entry_nxt_upd_ena_per_input_trans[i][j] = stb_entry_nxt_upd_ena_per_input[j][i];
      end
      // assign stb_entry_nxt_ena_per_input_trans[i] = stb_entry_nxt_new_ena_per_input_trans[i] | stb_entry_nxt_upd_ena_per_input_trans[i];
    end
  endgenerate

  AgeMatrixSelector
  #(
    .EntryCount (N_STB            ),
    .EnqWidth   (N_STB_ST_IN_PORT ),
    .SelWidth   (1                )
  )
  stb_entry_age_matrix_for_at_once_evict_u
  (
    .enq_fire_i     (s1_st_req_in_valid                           ),
    .enq_mask_i     (stb_entry_nxt_new_ena_per_input_trans        ),
    .deq_fire_i     (|stb_entry_valid_clr_ena                     ),
    .deq_mask_i     (stb_entry_nxt_clr_ena                        ),
    .sel_mask_i     (stb_entry_evict_at_once & stb_entry_valid    ), // select the stb entry need to be evicted at once
    .result_mask_o  (at_once_evict_mask                           ),
    .entry_vld_i    (stb_entry_valid                              ),
    .clk            (clk                                          ),
    .rstn           (rst                                          )
  );

  AgeMatrixSelector
  #(
    .EntryCount (N_STB            ),
    .EnqWidth   (N_STB_ST_IN_PORT ),
    .SelWidth   (1                )
  )
  stb_entry_age_matrix_for_common_evict_u
  (
    .enq_fire_i     (s1_st_req_in_valid                           ),
    .enq_mask_i     (stb_entry_nxt_new_ena_per_input_trans        ),
    .deq_fire_i     (|stb_entry_valid_clr_ena                     ),
    .deq_mask_i     (stb_entry_nxt_clr_ena                        ),
    .sel_mask_i     (stb_entry_valid                              ), // select the common evict stb entry
    .result_mask_o  (common_evict_mask                            ),
    .entry_vld_i    (stb_entry_valid                              ),
    .clk            (clk                                          ),
    .rstn           (rst                                          )
  );

  // next stb_evict_state
  assign stb_l1d_st_req_hsk = stb_l1d_st_req_vld_o & stb_l1d_st_req_rdy_i;

  assign have_stb_entry_to_flush         = (|(ls_pipe_stb_st_req_vld_i & ls_pipe_l1d_st_req_is_fence_i)) | fencei_flush_hsk;
  assign have_stb_entry_to_evict_at_once = |(at_once_evict_mask | stb_entry_evict_at_once_set_ena);
`ifdef RUBY
  assign have_stb_entry_to_evict_in_age  = (|common_evict_mask) & ~free_stb_entry_num_more_or_equal_four; // evict all the valid entry asap for coherence test
`else
  assign have_stb_entry_to_evict_in_age  = (|common_evict_mask) & ~free_stb_entry_num_more_or_equal_two;
`endif

  always_comb begin: case_stb_evict_state_d
    stb_evict_state_d     = IDLE;
    stb_evict_state_d_ena = 1'b0;
    unique case (stb_evict_state_q)
      IDLE: begin
        if(have_stb_entry_to_flush) begin
          stb_evict_state_d     = FLUSH;
          stb_evict_state_d_ena = 1'b1;
        end
        else if(have_stb_entry_to_evict_at_once) begin
          stb_evict_state_d     = SELECTED_EVICT;
          stb_evict_state_d_ena = 1'b1;
        end
        else if(have_stb_entry_to_evict_in_age) begin
          stb_evict_state_d     = IN_AGE_EVICT;
          stb_evict_state_d_ena = 1'b1;
        end
      end
      SELECTED_EVICT: begin
        if(have_stb_entry_to_flush) begin // fence flush has highest priority
          stb_evict_state_d     = FLUSH;
          stb_evict_state_d_ena = 1'b1;
        end
        else if(stb_l1d_st_req_hsk | ~have_stb_entry_to_evict_at_once) begin // this evict hsk or no more selected evict
          if(have_stb_entry_to_evict_at_once) begin // have stb_entry_to_evict_at_once, continue to do SELECTED_EVICT
            stb_evict_state_d     = SELECTED_EVICT;
            stb_evict_state_d_ena = 1'b0;
          end
          else if(have_stb_entry_to_evict_in_age) begin // no stb_entry_to_evict_at_once,  check if need to in age evict
            stb_evict_state_d     = IN_AGE_EVICT;
            stb_evict_state_d_ena = 1'b1;
          end 
          else begin
            stb_evict_state_d     = IDLE;
            stb_evict_state_d_ena = 1'b1;
          end
        end 
        else begin // this evict not hsk, continue to do SELECTED_EVICT
          stb_evict_state_d     = SELECTED_EVICT;
          stb_evict_state_d_ena = 1'b0;
        end
      end
      IN_AGE_EVICT: begin
        if(have_stb_entry_to_flush) begin // iflush has highest priority
          stb_evict_state_d     = FLUSH;
          stb_evict_state_d_ena = 1'b1;
        end
        else if(stb_l1d_st_req_hsk | ~have_stb_entry_to_evict_in_age) begin // this evict hsk or no more in age evict
          if(have_stb_entry_to_evict_at_once) begin // have stb_entry_to_evict_at_once, do SELECTED_EVICT
            stb_evict_state_d     = SELECTED_EVICT;
            stb_evict_state_d_ena = 1'b1;
          end
          else if(have_stb_entry_to_evict_in_age) begin // no stb_entry_to_evict_at_once,  check if need to in age evict
            stb_evict_state_d     = IN_AGE_EVICT;
            stb_evict_state_d_ena = 1'b0;
          end 
          else begin
            stb_evict_state_d     = IDLE;
            stb_evict_state_d_ena = 1'b1;
          end
        end 
        else begin // this evict not hsk, continue to do IN_AGE_EVICT
          stb_evict_state_d     = IN_AGE_EVICT;
          stb_evict_state_d_ena = 1'b0;
        end
      end
      FLUSH: begin
        if(|stb_entry_valid == 1'b1) begin // the flush not finished
          stb_evict_state_d     = FLUSH;
          stb_evict_state_d_ena = 1'b0;
        end else begin // the flush finished
          stb_evict_state_d     = IDLE;
          stb_evict_state_d_ena = 1'b1;
        end
      end
      default: begin
        stb_evict_state_d     = IDLE;
        stb_evict_state_d_ena = 1'b1;
      end
    endcase
  end

  // output of fsm, stb evict output to l1d bank
  always_comb begin: comb_select_out_selected_stb_entry
    out_selected_stb_entry_valid  = 1'b0;
    out_selected_stb_entry        = '0;
    for(int i = 0; i < N_STB; i++) begin
      if(at_once_evict_mask[i]) begin
        out_selected_stb_entry_valid  = stb_entry_valid[i];
        out_selected_stb_entry        = stb_entry[i];
      end
    end
  end

  always_comb begin: comb_select_out_in_age_stb_entry
    out_in_age_stb_entry_valid  = 1'b0;
    out_in_age_stb_entry        = '0;
    for(int i = 0; i < N_STB; i++) begin
      if(common_evict_mask[i]) begin
        out_in_age_stb_entry_valid  = stb_entry_valid[i];
        out_in_age_stb_entry        = stb_entry[i];
      end
    end
  end

  // when ld req at stb ld pipe s1, the stb evict should not do if it is the same stb entry the ld req at s1 hit
  // when st req at stb ld pipe s0, the stb evict should not do if it is the same stb entry the ld req at s1 hit
  logic [N_STB_LD_IN_PORT-1:0]  out_selected_stb_entry_hited_at_ld_s1_per_input;
  logic [N_STB_LD_IN_PORT-1:0]  out_in_age_stb_entry_hited_at_ld_s1_per_input;

  logic [N_STB_ST_IN_PORT-1:0]  out_selected_stb_entry_hited_at_st_s1_per_input;
  logic [N_STB_ST_IN_PORT-1:0]  out_in_age_stb_entry_hited_at_st_s1_per_input;

  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_out_stb_entry_hited_at_ld_s1_per_input
      assign out_selected_stb_entry_hited_at_ld_s1_per_input[i]  = ld_s1_valid[i] & (|(ld_nxt[i].s2.stb_hit_per_entry & at_once_evict_mask));
      assign out_in_age_stb_entry_hited_at_ld_s1_per_input  [i]  = ld_s1_valid[i] & (|(ld_nxt[i].s2.stb_hit_per_entry & common_evict_mask));
    end
  endgenerate

  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_out_stb_entry_hited_at_st_s0_per_input
      assign out_selected_stb_entry_hited_at_st_s1_per_input[i]  = st_s1_valid[i] & (|(st_cur[i].s1.stb_hit_entry_mask & at_once_evict_mask));
      assign out_in_age_stb_entry_hited_at_st_s1_per_input  [i]  = st_s1_valid[i] & (|(st_cur[i].s1.stb_hit_entry_mask & common_evict_mask));
    end
  endgenerate
  
  assign out_selected_stb_entry_hited_at_ld_s1 = |out_selected_stb_entry_hited_at_ld_s1_per_input;
  assign out_in_age_stb_entry_hited_at_ld_s1   = |out_in_age_stb_entry_hited_at_ld_s1_per_input;

  assign out_selected_stb_entry_hited_at_st_s1 = |out_selected_stb_entry_hited_at_st_s1_per_input;
  assign out_in_age_stb_entry_hited_at_st_s1   = |out_in_age_stb_entry_hited_at_st_s1_per_input;


  always_comb begin: comb_stb_evict_state_fsm_output
    stb_l1d_st_req_vld_o       =   '0;
    stb_l1d_st_req_rob_tag_o   =   '0;
    stb_l1d_st_req_prd_o       =   '0;
    stb_l1d_st_req_opcode_o    =   '0;
    stb_l1d_st_req_paddr_o     =   '0;
    stb_l1d_st_req_data_o      =   '0;
    stb_l1d_st_req_data_byte_mask_o = '0;
    stb_l1d_st_req_sc_rt_check_succ_o = '0;
    stb_l1d_st_req_amo_offset_o = '0;

    is_in_flush_stb_evict_state           = '0;
    is_in_selected_evict_stb_evict_state  = '0;
    is_in_in_age_evict_stb_evict_state    = '0;

    for(int i = N_STB_LD_IN_PORT; i < N_STB_LD_IN_PORT+N_STB_ST_IN_PORT; i++) begin
      // stb_rob_wb_vld_o[i] = 1'b0;
      // stb_rob_wb_rob_tag_o[i] = '0;
    end

    unique case (stb_evict_state_q)
      IDLE: begin
      end
      SELECTED_EVICT: begin
        if(|at_once_evict_mask) begin
          stb_l1d_st_req_vld_o      = out_selected_stb_entry_valid & ~out_selected_stb_entry_hited_at_ld_s1 & ~out_selected_stb_entry_hited_at_st_s1;
          stb_l1d_st_req_rob_tag_o  = out_selected_stb_entry.rob_tag;
          stb_l1d_st_req_prd_o      = out_selected_stb_entry.prd;
          stb_l1d_st_req_opcode_o   = out_selected_stb_entry.opcode;
          stb_l1d_st_req_paddr_o    = {out_selected_stb_entry.line_paddr, {L1D_OFFSET_WIDTH{1'b0}}};
          stb_l1d_st_req_data_o     = out_selected_stb_entry.line_data;
          stb_l1d_st_req_data_byte_mask_o = out_selected_stb_entry.write_byte_mask;
          stb_l1d_st_req_sc_rt_check_succ_o = out_selected_stb_entry.sc_rt_check_succ;
          stb_l1d_st_req_amo_offset_o     = out_selected_stb_entry.amo_offset;
`ifdef RUBY
          stb_l1d_st_req_lsu_tag_o         = out_selected_stb_entry.lsu_tag;
`endif
          is_in_selected_evict_stb_evict_state = 1'b1;
        end
      end
      IN_AGE_EVICT: begin
        if(|common_evict_mask) begin
          stb_l1d_st_req_vld_o      = out_in_age_stb_entry_valid & ~out_in_age_stb_entry_hited_at_ld_s1 & ~out_in_age_stb_entry_hited_at_st_s1;
          stb_l1d_st_req_rob_tag_o  = out_in_age_stb_entry.rob_tag;
          stb_l1d_st_req_prd_o      = out_in_age_stb_entry.prd;
          stb_l1d_st_req_opcode_o   = out_in_age_stb_entry.opcode;
          stb_l1d_st_req_paddr_o    = {out_in_age_stb_entry.line_paddr, {L1D_OFFSET_WIDTH{1'b0}}};
          stb_l1d_st_req_data_o     = out_in_age_stb_entry.line_data;
          stb_l1d_st_req_data_byte_mask_o = out_in_age_stb_entry.write_byte_mask;
          stb_l1d_st_req_sc_rt_check_succ_o = out_in_age_stb_entry.sc_rt_check_succ;
          stb_l1d_st_req_amo_offset_o     = out_in_age_stb_entry.amo_offset;
`ifdef RUBY
          stb_l1d_st_req_lsu_tag_o         = out_in_age_stb_entry.lsu_tag;
`endif
          is_in_in_age_evict_stb_evict_state = 1'b1;
        end
      end
      FLUSH: begin
        is_in_flush_stb_evict_state = 1'b1;
        if(|common_evict_mask) begin
          stb_l1d_st_req_vld_o      = out_in_age_stb_entry_valid & ~out_in_age_stb_entry_hited_at_ld_s1 & ~out_in_age_stb_entry_hited_at_st_s1;
          stb_l1d_st_req_rob_tag_o  = out_in_age_stb_entry.rob_tag;
          stb_l1d_st_req_prd_o      = out_in_age_stb_entry.prd;
          stb_l1d_st_req_opcode_o   = out_in_age_stb_entry.opcode;
          stb_l1d_st_req_paddr_o    = {out_in_age_stb_entry.line_paddr, {L1D_OFFSET_WIDTH{1'b0}}};
          stb_l1d_st_req_data_o     = out_in_age_stb_entry.line_data;
          stb_l1d_st_req_data_byte_mask_o = out_in_age_stb_entry.write_byte_mask;
          stb_l1d_st_req_sc_rt_check_succ_o = out_in_age_stb_entry.sc_rt_check_succ;
          stb_l1d_st_req_amo_offset_o     = out_in_age_stb_entry.amo_offset;
`ifdef RUBY
          stb_l1d_st_req_lsu_tag_o         = out_in_age_stb_entry.lsu_tag;
`endif
        end else begin // flush done, resp rob
          // stb_rob_wb_vld_o    [N_STB_LD_IN_PORT-1+1] = 1'b1;
          // stb_rob_wb_rob_tag_o[N_STB_LD_IN_PORT-1+1] = flush_req_rob_tag;
        end
      end
      default: begin
      end
    endcase
  end

  // flush hsk, resp rob
  assign stb_rob_wb_vld_o    [N_STB_LD_IN_PORT+N_STB_ST_IN_PORT-1:N_STB_LD_IN_PORT-1+1+1] = '0;
  assign stb_rob_wb_vld_o    [N_STB_LD_IN_PORT-1+1] = (|(ls_pipe_stb_st_req_vld_i & ls_pipe_l1d_st_req_is_fence_i & ls_pipe_stb_st_req_rdy_o)) & ~ls_pipe_l1d_st_req_no_fence_wb_resp_i;
  assign stb_rob_wb_rob_tag_o[N_STB_LD_IN_PORT+N_STB_ST_IN_PORT-1:N_STB_LD_IN_PORT-1+1+1] = '0;
  assign stb_rob_wb_rob_tag_o[N_STB_LD_IN_PORT-1+1] = flush_req_rob_tag_nxt;

  // dff stb_evict_state
  always_comb begin
    flush_req_rob_tag_ena = 1'b0;
    
    flush_req_rob_tag_nxt = '0;
    
    for(int i = N_STB_ST_IN_PORT-1; i >= 0; i--) begin
      if(ls_pipe_stb_st_req_vld_i[i] & ls_pipe_l1d_st_req_is_fence_i[i]) begin
        flush_req_rob_tag_nxt = ls_pipe_stb_st_req_rob_tag_i[i];
        flush_req_rob_tag_ena = 1'b1;
      end
    end
  end

  std_dffre
  #(.WIDTH(ROB_TAG_WIDTH))
  U_FLUSH_REQ_ROB_TAG_REG
  (
    .clk(clk),
    .rstn(rst),
    .en(flush_req_rob_tag_ena),
    .d(flush_req_rob_tag_nxt),
    .q(flush_req_rob_tag)
  );
  std_dffrve
  #(.WIDTH($bits(l1d_stb_evict_state_t)))
  U_ST_EVICT_STATE_REG
  (
    .clk(clk),
    .rstn(rst),
    .rst_val(IDLE),
    .en(stb_evict_state_d_ena),
    .d(stb_evict_state_d),
    .q(stb_evict_state_q)
  );

  // --------------------------------------------------------
  // pipeline register
  // --------------------------------------------------------
  // st req
  // s0 -> s1
  generate
    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s0_st_nxt_s1
      // ctrl
      assign st_s1_valid_nxt[i] = st_req_hak[i] & ~ls_pipe_l1d_st_req_is_fence_i[i]; // if it is a fence, no need go into st pipe
      assign st_s1_nxt_ena  [i] = st_s1_valid_nxt[i]; // TODO: more fine-grained enable signal
      
      // data
      assign st_nxt[i].s1.rob_tag         = ls_pipe_stb_st_req_rob_tag_i          [i];
      assign st_nxt[i].s1.prd             = ls_pipe_stb_st_req_prd_i              [i];
      assign st_nxt[i].s1.opcode          = ls_pipe_stb_st_req_opcode_i           [i];
      assign st_nxt[i].s1.paddr           = ls_pipe_stb_st_req_paddr_i            [i];
      assign st_nxt[i].s1.data            = ls_pipe_stb_st_req_data_i             [i];
`ifdef RUBY
      assign st_nxt[i].s1.lsu_tag         = ls_pipe_stb_st_req_lsu_tag_i          [i];
`endif

      assign st_nxt[i].s1.stb_hit            = st_req_hit_stb                     [i];
      assign st_nxt[i].s1.stb_hit_entry_mask = st_req_hit_stb_per_entry           [i];

    // ===== TODO: here only work for 2 input ports ======
      assign st_nxt[i].s1.hit_the_same_cache_line = st_req_hit_the_same_cache_line;
    // ===================================================

      assign st_nxt[i].s1.sc_rt_check_succ   = ls_pipe_l1d_st_req_sc_rt_check_succ_i; // sc, only comes from port 0
    end

    for(i = 0; i < N_STB_ST_IN_PORT; i++) begin: gen_s0_st_cur_s1
      std_dffr #(.WIDTH(1)) U_ST_STG_VALID_REG_S1 (.clk(clk),.rstn(rst),.d(st_s1_valid_nxt[i]),.q(st_s1_valid[i]));
      std_dffe #(.WIDTH($bits(l1d_stb_st_pipe_s1_t))) U_ST_STG_DAT_REG_S1 (.clk(clk),.en(st_s1_nxt_ena[i]),.d(st_nxt[i].s1),.q(st_cur[i].s1));
    end
  endgenerate

  // ld req
  // s0 -> s1
  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s0_ld_nxt_s1
      // ctrl
      if(i == 0) begin: gen_first_ld_req_with_ptw
        assign ld_s1_valid_nxt[i] = (ld_req_hak[i] | ptw_req_hak)& 
                                    ~have_stb_entry_to_flush &      // if there is a fence at the same cycle, no need go into ld pipe
                                    (~kill_ld_req_i | ptw_req_hak); // if there is a core pipeline flush, kill all load req in pipe
      end else begin: gen_other_ld_req_without_ptw
        assign ld_s1_valid_nxt[i] = ld_req_hak[i] & 
                                    ~have_stb_entry_to_flush & // if there is a fence at the same cycle, no need go into ld pipe
                                    ~kill_ld_req_i;            // if there is a core pipeline flush, kill all load req in pipe
      end

      assign ld_s1_nxt_ena  [i] = ld_s1_valid_nxt[i];

      // data
      assign ld_nxt[i].s1.rob_tag   = ld_req_hak [i] ? ls_pipe_stb_ld_req_rob_tag_i [i] : ptw_walk_req_id_i ;
      assign ld_nxt[i].s1.prd       = ls_pipe_stb_ld_req_prd_i     [i] ;
      assign ld_nxt[i].s1.opcode    = ld_req_hak [i] ? ls_pipe_stb_ld_req_opcode_i  [i] : LDU_LD;
      assign ld_nxt[i].s1.is_ptw_ld = ptw_req_hak;
      assign ld_nxt[i].s1.vtag      = ld_req_hak [i] ? ls_pipe_stb_ld_req_vtag_i    [i] : ptw_walk_req_addr_i[PADDR_WIDTH-1-:L1D_TAG_WIDTH] ;
      assign ld_nxt[i].s1.index     = ld_req_hak [i] ? ls_pipe_stb_ld_req_idx_i     [i] : ptw_walk_req_addr_i[L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH-1:L1D_OFFSET_WIDTH];
      assign ld_nxt[i].s1.offset    = ld_req_hak [i] ? ls_pipe_stb_ld_req_offset_i  [i] : ptw_walk_req_addr_i[L1D_OFFSET_WIDTH-1:0] ;
`ifdef RUBY
      assign ld_nxt[i].s1.lsu_tag   = ls_pipe_stb_ld_req_lsu_tag_i    [i];
`endif
    end

    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s0_ld_cur_s1
      std_dffr #(.WIDTH(1)) U_LD_STG_VALID_REG_S1 (.clk(clk),.rstn(rst),.d(ld_s1_valid_nxt[i]),.q(ld_s1_valid[i]));
      std_dffe #(.WIDTH($bits(l1d_stb_ld_pipe_s1_t))) U_LD_STG_DAT_REG_S1 (.clk(clk),.en(ld_s1_nxt_ena[i]),.d(ld_nxt[i].s1),.q(ld_cur[i].s1));
    end
  endgenerate

  // s1 -> s2
  generate
    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s1_ld_nxt_s2
      // ctr
      assign ld_s2_valid_nxt[i] = ld_s1_valid[i] & (
                                  // ld req
                                  ((ls_pipe_stb_dtlb_resp_vld_i[i] & ls_pipe_stb_dtlb_resp_hit_i[i]) & // load req tlb hit
                                  ~kill_ld_req_i)       |                                             // if there is a core pipeline flush, kill all load req in pipe
                                  // ptw req
                                  ld_cur[i].s1.is_ptw_ld);

      assign ld_s2_nxt_ena  [i] = ld_s2_valid_nxt[i];

      // data
      assign ld_nxt[i].s2.rob_tag           = ld_cur[i].s1.rob_tag       ;
      assign ld_nxt[i].s2.prd               = ld_cur[i].s1.prd           ;
      assign ld_nxt[i].s2.opcode            = ld_cur[i].s1.opcode        ;
      assign ld_nxt[i].s2.is_ptw_ld         = ld_cur[i].s1.is_ptw_ld     ;
      assign ld_nxt[i].s2.offset            = ld_cur[i].s1.offset        ;
      assign ld_nxt[i].s2.stb_hit           = ld_req_hit_stb          [i];
      assign ld_nxt[i].s2.stb_hit_per_entry = ld_req_hit_stb_per_entry[i];
`ifdef RUBY
      assign ld_nxt[i].s2.lsu_tag           = ld_cur[i].s1.lsu_tag       ;
`endif
    end

    for(i = 0; i < N_STB_LD_IN_PORT; i++) begin: gen_s0_ld_cur_s2
      std_dffr #(.WIDTH(1)) U_LD_STG_VALID_REG_S2 (.clk(clk),.rstn(rst),.d(ld_s2_valid_nxt[i]),.q(ld_s2_valid[i]));
      std_dffe #(.WIDTH($bits(l1d_stb_ld_pipe_s2_t))) U_LD_STG_DAT_REG_S2 (.clk(clk),.en(ld_s2_nxt_ena[i]),.d(ld_nxt[i].s2),.q(ld_cur[i].s2));
    end
  endgenerate

  // --------------------------------------------------------
  


endmodule