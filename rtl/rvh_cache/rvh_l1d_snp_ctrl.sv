module rvh_l1d_snp_ctrl
  // import riscv_pkg::*;
  // import rvh_pkg::*;
  // import uop_encoding_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_noc_pkg::*;
  import rvh_uncore_param_pkg::*;
#(
  parameter int unsigned CORE_ID = 0,
  parameter int unsigned SNOOP_REQ_BUFFER_DEPTH = 2,
  parameter int unsigned SNOOP_REQ_BUFFER_DEPTH_W = SNOOP_REQ_BUFFER_DEPTH > 1 ? $clog2(SNOOP_REQ_BUFFER_DEPTH) : 1
`ifdef COMMON_DATA_VALID_LATENCY_EN
  ,parameter COMMON_DATA_VALID_LATENCY = 32
`endif
)
(
  // // ace5 snoop channels
  //   // snoop addr
  // input  logic              snp_req_if_acvalid_i,
  // output logic              snp_req_if_acready_o,
  // input  cache_mem_if_ac_t  snp_req_if_ac_i,
  //   // snoop resp
  // output logic              snp_resp_if_crvalid_o,
  // input  logic              snp_resp_if_crready_i,
  // output cache_mem_if_cr_t  snp_resp_if_cr_o,
  //   // snoop data
  // output logic              snp_resp_if_cdvalid_o,
  // input  logic              snp_resp_if_cdready_i,
  // output cache_mem_if_cd_t  snp_resp_if_cd_o,

  // cache rx port, scu -> private cache
    // snp
  input  logic                        scu_pc_snp_vld_i,
  input  cache_scu_cc_snp_t           scu_pc_snp_i,
  output logic                        scu_pc_snp_rdy_o,

  // cache tx port, private cache -> scu
    // resp
  output logic                        pc_scu_resp_vld_o,
  output cache_scu_cc_resp_t          pc_scu_resp_o,
  input  logic                        pc_scu_resp_rdy_i,
    // data
  output logic                        pc_scu_data_vld_o,
  output cache_scu_cc_data_t          pc_scu_data_o,
  input  logic                        pc_scu_data_rdy_i,



  // snp ctrl <-> l1d bank intf
  output snp_req_head_buf_t snp_l1d_bank_snp_req_o,
    // s0 req
  output logic                  snp_l1d_bank_snp_s0_req_vld_o, // vld for: all_1
  output logic                  snp_l1d_bank_snp_s0_req_hsk_o,
  output logic                  snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_o, // all_2
  input  logic                  snp_l1d_bank_snp_s0_req_rdy_i,
  input  snp_l1d_bank_snp_s0_t  snp_l1d_bank_snp_s0_i,
    // s1 req
  output logic                  snp_l1d_bank_snp_s1_req_vld_o, // vld for: all_1
  output logic                  snp_l1d_bank_snp_s1_req_hsk_o, // hsk for: s1_1
  input  logic                  snp_l1d_bank_snp_s1_req_rdy_i,
  input  snp_l1d_bank_snp_s1_t  snp_l1d_bank_snp_s1_i,
    // s2 req
  output logic                  snp_l1d_bank_snp_s2_req_vld_o, // vld for: all_1
  output logic                  snp_l1d_bank_snp_s2_req_hsk_o, // hsk for: s2_3
  output rrv64_mesi_type_e      snp_l1d_bank_snp_s2_req_new_line_state_o,
  output logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  snp_l1d_bank_snp_s2_req_way_id_o,
  output logic                  snp_l1d_bank_snp_s2_req_data_ram_rd_vld_o, // vld for: s2_2
  input  logic                  snp_l1d_bank_snp_s2_req_rdy_i,
  input  snp_l1d_bank_snp_s2_t  snp_l1d_bank_snp_s2_i,

    // s3 req
  output logic                  snp_l1d_bank_snp_s3_req_vld_o, // vld for: all_1
  output logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] snp_l1d_bank_snp_s3_tag_compare_match_id_o,
  input  logic [L1D_BANK_LINE_DATA_SIZE-1:0] snp_l1d_bank_snp_s3_req_line_data_i,

  output logic snp_req_head_buf_valid_clr_o,
  input  logic clk,
  input  logic rst
);
genvar i;

// ace5 snoop channels
  // snoop addr
logic snp_req_if_ac_hsk;
  // snoop resp
logic snp_resp_if_cr_hsk;
logic snp_resp_if_cr_bypass; // data resp no need resp
  // snoop data
logic snp_resp_if_cd_hsk;
logic snp_resp_if_cd_bypass; // dataless resp no need data

// snp req buf order fifo
logic                                 snp_req_buf_order_fifo_dq_vld;
logic                                 snp_req_buf_order_fifo_dq_rdy;
logic [SNOOP_REQ_BUFFER_DEPTH_W-1:0]  snp_req_buf_order_fifo_dq_pl;

// snoop head buffer
logic              snp_req_buf_snp_head_buf_hsk;
logic              snp_req_head_buf_valid, snp_req_head_buf_valid_nxt;
logic              snp_req_head_buf_valid_set, snp_req_head_buf_valid_clr;
logic              snp_req_head_buf_valid_ena;

snp_req_head_buf_t snp_req_head_buf;

snp_req_buf_t      snp_req_head_buf_snp_req, snp_req_head_buf_snp_req_nxt;
logic              snp_req_head_buf_snp_req_ena;

logic              snp_req_head_buf_s1_conflict_check_done;
logic              snp_req_head_buf_s1_conflict_check_done_nxt;
logic              snp_req_head_buf_s1_conflict_check_done_set, snp_req_head_buf_s1_conflict_check_done_clr;
logic              snp_req_head_buf_s1_ena;

logic              snp_req_head_buf_s2_read_tag_lst_done;
logic              snp_req_head_buf_s2_read_tag_lst_done_nxt;
logic              snp_req_head_buf_s2_read_tag_lst_done_set, snp_req_head_buf_s2_read_tag_lst_done_clr;
rrv64_l1d_lst_t    snp_req_head_buf_s2_lst_dat;
rrv64_l1d_lst_t    snp_req_head_buf_s2_lst_dat_nxt;
logic              snp_req_head_buf_s2_ena;

logic              snp_req_head_buf_s3_rd_data_wr_lst_done, snp_req_head_buf_s3_rd_data_wr_lst_done_nxt;
logic              snp_req_head_buf_s3_rd_data_wr_lst_done_set, snp_req_head_buf_s3_rd_data_wr_lst_done_clr;

logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  snp_req_head_buf_s3_tag_compare_match_id, snp_req_head_buf_s3_tag_compare_match_id_nxt;

logic              snp_req_head_buf_s3_data_resp, snp_req_head_buf_s3_data_resp_nxt;
logic              snp_req_head_buf_s3_data_resp_set, snp_req_head_buf_s3_data_resp_clr;

logic              snp_req_head_buf_s3_resp_inv, snp_req_head_buf_s3_resp_inv_nxt;
logic              snp_req_head_buf_s3_resp_inv_set, snp_req_head_buf_s3_resp_inv_clr;

logic              snp_req_head_buf_s3_resp_sc, snp_req_head_buf_s3_resp_sc_nxt;
logic              snp_req_head_buf_s3_resp_sc_set, snp_req_head_buf_s3_resp_sc_clr;

logic              snp_req_head_buf_s3_resp_pd, snp_req_head_buf_s3_resp_pd_nxt;
logic              snp_req_head_buf_s3_resp_pd_set, snp_req_head_buf_s3_resp_pd_clr;

logic              snp_req_head_buf_s3_was_unique, snp_req_head_buf_s3_was_unique_nxt;
logic              snp_req_head_buf_s3_was_unique_set, snp_req_head_buf_s3_was_unique_clr;

logic              snp_req_head_buf_s3_ena;

logic              snp_req_head_buf_s4_snp_resp_done, snp_req_head_buf_s4_snp_resp_done_nxt;
logic              snp_req_head_buf_s4_snp_resp_done_set, snp_req_head_buf_s4_snp_resp_done_clr;
logic              snp_req_head_buf_s4_snp_resp_done_ena;

logic              snp_req_head_buf_cr_hsk_done, snp_req_head_buf_cr_hsk_done_nxt;
logic              snp_req_head_buf_cr_hsk_done_set, snp_req_head_buf_cr_hsk_done_clr;
logic              snp_req_head_buf_cr_ena;

logic              snp_req_head_buf_cd_hsk_done, snp_req_head_buf_cd_hsk_done_nxt;
logic              snp_req_head_buf_cd_hsk_done_set, snp_req_head_buf_cd_hsk_done_clr;
logic              snp_req_head_buf_cd_ena;

logic [L1D_BANK_LINE_DATA_SIZE-1:0] snp_req_head_buf_cd_data_hold, snp_req_head_buf_cd_data_hold_nxt;
logic              snp_req_head_buf_cd_data_hold_ena;
logic              snp_req_head_buf_cd_data_hold_valid_d, snp_req_head_buf_cd_data_hold_valid_q;
logic              snp_req_head_buf_cd_data_hold_valid_clr, snp_req_head_buf_cd_data_hold_valid_set;
logic              snp_req_head_buf_cd_data_hold_valid_ena;

// snp ctrl <-> l1d bank intf

// snoop req buffer
snp_req_buf_t [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf;
snp_req_buf_t                               snp_req_buf_new_entry;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_ena;

// snoop req buffer valid
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid_nxt;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid_set;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid_clr;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid_ena;

logic                                       snp_req_buf_has_free_entry;
logic         [SNOOP_REQ_BUFFER_DEPTH_W-1:0]snp_req_buf_free_entry_id;
logic         [SNOOP_REQ_BUFFER_DEPTH_W:0]  snp_req_buf_free_entry_num;

// 1. ac (snoop addr) channel: receive snoop req from scu
assign snp_req_if_ac_hsk  = scu_pc_snp_vld_i & scu_pc_snp_rdy_o;
assign scu_pc_snp_rdy_o   = snp_req_buf_has_free_entry;

// 2. snoop req buffer maintainence
// 2.1 ace ac channel decoder
rvh_l1d_snp_dec
rvh_l1d_snp_dec_u (
  .scu_pc_snp_i         (scu_pc_snp_i      ),
  .snp_req_buf_entry_o  (snp_req_buf_new_entry)
);

// 2.2 if the snoop req buffer has free entry, alloc new snoop req(for deadlock free, now the buffer depth is 1)
rvh_l1d_mshr_alloc
#(
  .INPUT_NUM    (SNOOP_REQ_BUFFER_DEPTH)
)
rvh_l1d_snp_req_buffer_alloc_u
(
  .mshr_bank_valid_i    (snp_req_buf_valid          ),
  .mshr_id_o            (snp_req_buf_free_entry_id  ),
  .has_free_mshr_o      (snp_req_buf_has_free_entry ),
  .free_mshr_num_o      (snp_req_buf_free_entry_num )
);

// 2.3 snp_req_buf alloc and dealloc
always_comb begin : comb_snp_req_buf_valid_set
  snp_req_buf_valid_set = '0;
  if(snp_req_if_ac_hsk) begin
    snp_req_buf_valid_set[snp_req_buf_free_entry_id] = 1'b1;
  end
end

always_comb begin : comb_snp_req_buf_valid_clr
  snp_req_buf_valid_clr = '0;
  if(snp_req_buf_snp_head_buf_hsk) begin
    snp_req_buf_valid_clr[snp_req_buf_order_fifo_dq_pl] = 1'b1;
  end
end

assign snp_req_buf_valid_nxt = (snp_req_buf_valid | snp_req_buf_valid_set) & ~snp_req_buf_valid_clr;
assign snp_req_buf_valid_ena = snp_req_buf_valid_set | snp_req_buf_valid_clr;
assign snp_req_buf_ena       = snp_req_buf_valid_set;


generate
  for(i = 0; i < SNOOP_REQ_BUFFER_DEPTH; i++) begin: gen_snp_req_buf_valid
    std_dffre
    #(.WIDTH(1))
    U_L1D_SNP_REQ_BUF_VALID_REG
    (
      .clk  (clk),
      .rstn (rst),
      .en   (snp_req_buf_valid_ena [i]),
      .d    (snp_req_buf_valid_nxt [i]),
      .q    (snp_req_buf_valid     [i])
    );
  end
  for(i = 0; i < SNOOP_REQ_BUFFER_DEPTH; i++) begin: gen_snp_req_buf
    std_dffe
    #(.WIDTH($bits(snp_req_buf_t))) 
    U_L1D_SNP_REQ_BUF_REG
    (
      .clk(clk),
      .en (snp_req_buf_ena [i]  ),
      .d  (snp_req_buf_new_entry),
      .q  (snp_req_buf     [i]  )
    );
  end
endgenerate

// 2.4 send the snoop req to l1d bank in order
mp_fifo
#(
    .payload_t          (logic[SNOOP_REQ_BUFFER_DEPTH_W-1:0]    ),
    .ENQUEUE_WIDTH      (1                                      ),
    .DEQUEUE_WIDTH      (1                                      ),
    .DEPTH              (SNOOP_REQ_BUFFER_DEPTH                 ),
    .MUST_TAKEN_ALL     (1                                      )
)
l1d_snp_req_buf_order_fifo_u
(
    // Enqueue
    .enqueue_vld_i          (snp_req_if_ac_hsk          ),
    .enqueue_payload_i      (snp_req_buf_free_entry_id  ),
    .enqueue_rdy_o          (                    ),
    // Dequeue
    .dequeue_vld_o          (snp_req_buf_order_fifo_dq_vld   ),
    .dequeue_payload_o      (snp_req_buf_order_fifo_dq_pl    ),
    .dequeue_rdy_i          (snp_req_buf_order_fifo_dq_rdy   ),

    .flush_i                (1'b0                ),

    .clk                    (clk                 ),
    .rst                    (~rst                 )
);

// 3 head buf
// 3.1 when head buf is invalid, load a new snoop req from snp_req_buf
assign snp_req_buf_order_fifo_dq_rdy = ~snp_req_head_buf_valid;
assign snp_req_buf_snp_head_buf_hsk = snp_req_buf_order_fifo_dq_vld & snp_req_buf_order_fifo_dq_rdy;

// 3.1.1 head buf valid
assign snp_req_head_buf_valid_nxt = (snp_req_head_buf_valid | snp_req_head_buf_valid_set) & ~snp_req_head_buf_valid_clr;
assign snp_req_head_buf_valid_ena = snp_req_head_buf_valid_set | snp_req_head_buf_valid_clr;
assign snp_req_head_buf_valid_set = snp_req_buf_snp_head_buf_hsk;
assign snp_req_head_buf_valid_clr = (snp_req_head_buf_s4_snp_resp_done_set & snp_req_head_buf_cr_hsk_done_set & snp_req_head_buf_cd_hsk_done_set) | // hsk immediately at s4
                                    (snp_req_head_buf_valid & snp_req_head_buf.s4_snp_resp_done & snp_req_head_buf.cr_hsk_done & snp_req_head_buf.cd_hsk_done);

assign snp_req_head_buf_valid_clr_o = snp_req_head_buf_valid_clr;

std_dffre#(.WIDTH(1))U_STA_REG_HEAD_BUF_VALID(.clk(clk),.rstn(rst),.en(snp_req_head_buf_valid_ena),.d(snp_req_head_buf_valid_nxt),.q(snp_req_head_buf_valid));


// 3.1.2 head buf, the head buf is linked to many regs with different enable signal
assign snp_req_head_buf.snp_req                 = snp_req_head_buf_snp_req;
assign snp_req_head_buf.s1_conflict_check_done  = snp_req_head_buf_s1_conflict_check_done;
// assign snp_req_head_buf.s1_dataless_resp_i      = snp_req_head_buf_s1_dataless_resp_i;
assign snp_req_head_buf.s2_read_tag_lst_done    = snp_req_head_buf_s2_read_tag_lst_done;
assign snp_req_head_buf.s2_lst_dat              = snp_req_head_buf_s2_lst_dat;
assign snp_req_head_buf.s3_rd_data_wr_lst_done  = snp_req_head_buf_s3_rd_data_wr_lst_done;
assign snp_req_head_buf.s3_tag_compare_match_id = snp_req_head_buf_s3_tag_compare_match_id;
assign snp_req_head_buf.s3_data_resp            = snp_req_head_buf_s3_data_resp;
assign snp_req_head_buf.s3_resp_inv             = snp_req_head_buf_s3_resp_inv;
assign snp_req_head_buf.s3_resp_sc              = snp_req_head_buf_s3_resp_sc;
assign snp_req_head_buf.s3_resp_pd              = snp_req_head_buf_s3_resp_pd;
assign snp_req_head_buf.s3_was_unique           = snp_req_head_buf_s3_was_unique;
assign snp_req_head_buf.s4_snp_resp_done        = snp_req_head_buf_s4_snp_resp_done;
assign snp_req_head_buf.cr_hsk_done             = snp_req_head_buf_cr_hsk_done;
assign snp_req_head_buf.cd_hsk_done             = snp_req_head_buf_cd_hsk_done;
assign snp_req_head_buf.cd_data_hold            = snp_req_head_buf_cd_data_hold;

// 3.1.3 head buf signals
// 3.1.3.1 snp_req
assign snp_req_head_buf_snp_req_nxt = snp_req_buf[snp_req_buf_order_fifo_dq_pl];
assign snp_req_head_buf_snp_req_ena = snp_req_head_buf_valid_set;

std_dffe#(.WIDTH($bits(snp_req_buf_t)))U_DAT_REG_HEAD_BUF_SNP_REQ(.clk(clk),.en(snp_req_head_buf_snp_req_ena),.d(snp_req_head_buf_snp_req_nxt),.q(snp_req_head_buf_snp_req));

// 4 snp ctrl -> l1d bank intf snoop transaction
logic snp_l1d_bank_snp_s0_req_rdy_internal;
logic snp_l1d_bank_snp_s1_req_rdy_internal;
logic snp_l1d_bank_snp_s2_req_rdy_internal;

assign snp_l1d_bank_snp_req_o         = snp_req_head_buf;

// 4.1 s0
// 4.1.1 snp req out to l1d bank
assign snp_l1d_bank_snp_s0_req_vld_o  = snp_req_head_buf_valid & ~snp_req_head_buf.s1_conflict_check_done;

// 4.1.2 check data from l1d bank
logic [L1D_BANK_PADDR_TAG_WIDTH-1:0] snp_addr_tag;
logic [L1D_BANK_SET_INDEX_WIDTH-1:0] snp_addr_idx;
logic [N_MSHR-1:0] snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry;
// logic [N_MSHR-1:0] snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry_sent;
logic [N_EWRQ-1:0] snp_l1d_bank_req_line_addr_hit_in_ewrq_per_entry;
logic snp_l1d_bank_req_line_addr_hit_in_pipe;
logic snp_l1d_bank_req_line_addr_hit_in_mshr;
// logic snp_l1d_bank_req_line_addr_hit_in_mshr_sent;
logic snp_l1d_bank_req_line_addr_hit_in_ewrq;

assign snp_addr_tag = snp_req_head_buf.snp_req.snp_line_addr[L1D_STB_LINE_ADDR_SIZE-1 -: L1D_BANK_PADDR_TAG_WIDTH];
assign snp_addr_idx = snp_req_head_buf.snp_req.snp_line_addr[L1D_BANK_ID_INDEX_WIDTH  +: L1D_BANK_SET_INDEX_WIDTH];

generate
  for(i = 0; i < N_MSHR; i++) begin: gen_snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry
      assign snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry[i] = snp_l1d_bank_snp_s0_i.mshr_bank_valid[i] & 
                                                                  (snp_addr_tag == snp_l1d_bank_snp_s0_i.mshr_bank[i].new_tag) & // tag match
                                                                  (snp_addr_idx == snp_l1d_bank_snp_s0_i.mshr_bank[i].bank_index); // bank idx match
      // assign snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry_sent[i]     = snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry[i] & snp_l1d_bank_snp_s0_mshr_bank_sent_i[i];
  end
  for(i = 0; i < N_EWRQ; i++) begin: gen_snp_l1d_bank_req_line_addr_hit_in_ewrq_per_entry
      assign snp_l1d_bank_req_line_addr_hit_in_ewrq_per_entry[i] = snp_l1d_bank_snp_s0_i.ewrq_vld[i] &
                                                                  (snp_addr_tag == snp_l1d_bank_snp_s0_i.ewrq_addr[i][L1D_BANK_LINE_ADDR_SIZE-1-:L1D_BANK_PADDR_TAG_WIDTH]) & // tag match
                                                                  (snp_addr_idx == snp_l1d_bank_snp_s0_i.ewrq_addr[i][L1D_BANK_SET_INDEX_WIDTH-1:0]); // bank idx match
  end
endgenerate

assign snp_l1d_bank_req_line_addr_hit_in_pipe = (snp_l1d_bank_snp_s0_i.s1_valid &
                                                  (snp_addr_tag == snp_l1d_bank_snp_s0_i.s1_tag_used_to_compare) & // tag match
                                                  (snp_addr_idx == snp_l1d_bank_snp_s0_i.cur.s1.ls_pipe_l1d_req_idx) // bank idx match
                                                ) |
                                                (snp_l1d_bank_snp_s0_i.s2_valid &
                                                  (snp_addr_tag == snp_l1d_bank_snp_s0_i.cur.s2.ls_pipe_l1d_req_tag) & // tag match
                                                  (snp_addr_idx == snp_l1d_bank_snp_s0_i.cur.s2.ls_pipe_l1d_req_idx) // bank idx match
                                                );
assign snp_l1d_bank_req_line_addr_hit_in_mshr       = (|snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry); // TODO: for now no CleanUnique will send by cache, but if it is added, the mshr need to be modified at if snp hit
// assign snp_l1d_bank_req_line_addr_hit_in_mshr_sent  = (|snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry_sent);
assign snp_l1d_bank_req_line_addr_hit_in_ewrq       = (|snp_l1d_bank_req_line_addr_hit_in_ewrq_per_entry);

// 4.1.3 s0 handshake
assign snp_l1d_bank_snp_s0_req_rdy_internal = ~snp_l1d_bank_snp_s0_i.s1_st_req_tag_hit     & // s0_1: if s1 is a store hit need to write data ram, wait for 1 cycle
                                              ~snp_l1d_bank_snp_s0_i.s2_st_req_tag_hit     & // s0_1: if s2 is a store hit need to write data ram, wait for 1 cycle
                                              // ~snp_l1d_bank_req_line_addr_hit_in_mshr_sent & // s0_2: in mshr sent out
                                              // ~snp_l1d_bank_req_line_addr_hit_in_mshr      & // TODO: for now no CleanUnique will send by cache, but if it is added, the mshr need to be modified at if snp hit
                                              ~snp_l1d_bank_req_line_addr_hit_in_ewrq      & // s0_2: in ewrq
                                              ~snp_l1d_bank_req_line_addr_hit_in_pipe;       // s0_2: in pipeline
assign snp_l1d_bank_snp_s0_req_hsk_o  = snp_l1d_bank_snp_s0_req_vld_o &
                                        snp_l1d_bank_snp_s0_req_rdy_internal &
                                        snp_l1d_bank_snp_s0_req_rdy_i;

assign snp_req_head_buf_s1_conflict_check_done_set  = snp_l1d_bank_snp_s0_req_hsk_o;
assign snp_req_head_buf_s1_conflict_check_done_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s1_conflict_check_done_nxt  = snp_req_head_buf_s1_conflict_check_done_set & (~snp_req_head_buf_s1_conflict_check_done_clr);
assign snp_req_head_buf_s1_ena                      = snp_req_head_buf_s1_conflict_check_done_set | snp_req_head_buf_s1_conflict_check_done_clr;

std_dffre #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S1_CONFLICT_CHECK_DONE (.clk(clk),.rstn (rst), .en(snp_req_head_buf_s1_ena) ,.d(snp_req_head_buf_s1_conflict_check_done_nxt) ,.q(snp_req_head_buf_s1_conflict_check_done));

// 4.1.4 all_2: for s0, stall mlfb refill transaction [mlfb_cache_peek_valid, mlfb_cache_check_valid, mlfb_cache_evict_valid, mlfb_cache_evict_bypass, mlfb_cache_refill_valid] if no sent-out line addr hit in mshr(cond s0.3)
assign snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_o = snp_l1d_bank_snp_s0_req_vld_o; //&
                                                          // ~snp_l1d_bank_req_line_addr_hit_in_mshr; // TODO: for now no CleanUnique will send by cache, but if it is added, the mshr need to be modified at if snp hit
                                                          // ~snp_l1d_bank_req_line_addr_hit_in_mshr_sent; // wait until the sent mshr get resp and removed

// 4.2 s1: read tag ram, read lst if needed, then goto s2
// 4.2.1 snp req out to l1d bank
assign snp_l1d_bank_snp_s1_req_vld_o  = snp_req_head_buf_valid & snp_req_head_buf.s1_conflict_check_done & ~snp_req_head_buf.s2_read_tag_lst_done;
// 4.2.2 s1 handshake
assign snp_l1d_bank_snp_s1_req_rdy_internal = 1'b1;
assign snp_l1d_bank_snp_s1_req_hsk_o = snp_l1d_bank_snp_s1_req_vld_o &
                                       snp_l1d_bank_snp_s1_req_rdy_internal &
                                       snp_l1d_bank_snp_s1_req_rdy_i;

assign snp_req_head_buf_s2_read_tag_lst_done_set = snp_l1d_bank_snp_s1_req_hsk_o;
assign snp_req_head_buf_s2_read_tag_lst_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s2_read_tag_lst_done_nxt = snp_req_head_buf_s2_read_tag_lst_done_set | (~snp_req_head_buf_s2_read_tag_lst_done_clr);
assign snp_req_head_buf_s2_lst_dat_nxt           = snp_l1d_bank_snp_s1_i.lst_dat;
assign snp_req_head_buf_s2_ena                   = snp_req_head_buf_s2_read_tag_lst_done_set | snp_req_head_buf_s2_read_tag_lst_done_clr;

std_dffre #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S2_READ_TAG_LST_DONE (.clk(clk),.rstn (rst),.en(snp_req_head_buf_s2_ena) ,.d(snp_req_head_buf_s2_read_tag_lst_done_nxt) ,.q(snp_req_head_buf_s2_read_tag_lst_done));
std_dffe #(.WIDTH($bits(rrv64_l1d_lst_t))) U_DAT_REG_HEAD_BUF_S2_LST_DAT (.clk(clk),.en(snp_req_head_buf_s2_ena) ,.d(snp_req_head_buf_s2_lst_dat_nxt) ,.q(snp_req_head_buf_s2_lst_dat));


// 4.3 s2: compare tag, check lst; read data ram if needed(cond s2.3, s2.4, s2.5)
// 4.3.1 compare tag, check lst
logic [L1D_BANK_WAY_NUM-1:0]          s2_tag_compare_result_per_way;
logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  s2_tag_compare_match_id;

logic s2_tag_miss;
logic s2_tag_hit_state_inv;
logic s2_tag_hit_state_sc;
logic s2_tag_hit_state_uc;
logic s2_tag_hit_state_ud;

assign s2_tag_compare_result_per_way = snp_l1d_bank_snp_s2_i.tag_compare_result_per_way;
always_comb begin
  s2_tag_compare_match_id = '0;
  for(int i = 0; i < L1D_BANK_WAY_NUM; i++) begin
    if(s2_tag_compare_result_per_way[i] == 1'b1) begin
      s2_tag_compare_match_id = i[L1D_BANK_WAY_INDEX_WIDTH-1:0];
    end
  end
end

assign s2_tag_miss  = ~(|s2_tag_compare_result_per_way);
assign s2_tag_hit_state_inv = ~s2_tag_miss & (snp_req_head_buf.s2_lst_dat.mesi_sta[s2_tag_compare_match_id] == INVALID);
assign s2_tag_hit_state_sc  = ~s2_tag_miss & (snp_req_head_buf.s2_lst_dat.mesi_sta[s2_tag_compare_match_id] == SHARED);
assign s2_tag_hit_state_uc  = ~s2_tag_miss & (snp_req_head_buf.s2_lst_dat.mesi_sta[s2_tag_compare_match_id] == EXCLUSIVE);
assign s2_tag_hit_state_ud  = ~s2_tag_miss & (snp_req_head_buf.s2_lst_dat.mesi_sta[s2_tag_compare_match_id] == MODIFIED);

  // need to read data ram
assign snp_l1d_bank_snp_s2_req_data_ram_rd_vld_o = snp_req_head_buf.snp_req.snp_return_clean_data & (s2_tag_hit_state_sc | s2_tag_hit_state_uc) |
                                                   snp_req_head_buf.snp_req.snp_return_dirty_data & (s2_tag_hit_state_ud);

// 4.3.2 snp req out to l1d bank
assign snp_l1d_bank_snp_s2_req_vld_o  = snp_req_head_buf_valid &
                                        snp_req_head_buf.s1_conflict_check_done &
                                        snp_req_head_buf.s2_read_tag_lst_done &
                                        ~snp_req_head_buf.s3_rd_data_wr_lst_done;

assign snp_l1d_bank_snp_s2_req_new_line_state_o = ((~s2_tag_hit_state_inv) & snp_req_head_buf.snp_req.snp_leave_sharedclean) ? SHARED : INVALID;
assign snp_l1d_bank_snp_s2_req_way_id_o         = s2_tag_compare_match_id;

// 4.3.3 s2 handshake
logic snp_l1d_bank_snp_s2_req_hsk;

assign snp_l1d_bank_snp_s2_req_rdy_internal = 1'b1;
assign snp_l1d_bank_snp_s2_req_hsk   = snp_l1d_bank_snp_s2_req_vld_o &
                                       snp_l1d_bank_snp_s2_req_rdy_internal &
                                       snp_l1d_bank_snp_s2_req_rdy_i;
assign snp_l1d_bank_snp_s2_req_hsk_o = snp_l1d_bank_snp_s2_req_hsk & ~s2_tag_miss; // if the s2_tag_miss set, means the cache doesn't have this line, it is because it is evicted before the snp arrived, so it no need to update lst

assign snp_req_head_buf_s3_rd_data_wr_lst_done_set = snp_l1d_bank_snp_s2_req_hsk;
assign snp_req_head_buf_s3_rd_data_wr_lst_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_rd_data_wr_lst_done_nxt = snp_req_head_buf_s3_rd_data_wr_lst_done_set & (~snp_req_head_buf_s3_rd_data_wr_lst_done_clr);
assign snp_req_head_buf_s3_ena                     = snp_req_head_buf_s3_rd_data_wr_lst_done_set | snp_req_head_buf_s3_rd_data_wr_lst_done_clr;

  // pass s2 hit way id to s3
assign snp_req_head_buf_s3_tag_compare_match_id_nxt = s2_tag_compare_match_id;

  // need s3 data resp
assign snp_req_head_buf_s3_data_resp_set  = snp_l1d_bank_snp_s2_req_data_ram_rd_vld_o;
assign snp_req_head_buf_s3_data_resp_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_data_resp_nxt  = snp_req_head_buf_s3_data_resp_set & (~snp_req_head_buf_s3_data_resp_clr);

  // need s3 data resp SnpAck_FoundI
assign snp_req_head_buf_s3_resp_inv_set  = s2_tag_miss |
                                           s2_tag_hit_state_inv;
assign snp_req_head_buf_s3_resp_inv_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_resp_inv_nxt  = snp_req_head_buf_s3_resp_inv_set & (~snp_req_head_buf_s3_resp_inv_clr);

  // need s3 data resp SnpAck_FoundSorE
assign snp_req_head_buf_s3_resp_sc_set  = (s2_tag_hit_state_sc | s2_tag_hit_state_uc);
assign snp_req_head_buf_s3_resp_sc_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_resp_sc_nxt  = snp_req_head_buf_s3_resp_sc_set & (~snp_req_head_buf_s3_resp_sc_clr);

  // need s3 data resp pass dirty
assign snp_req_head_buf_s3_resp_pd_set  = (s2_tag_hit_state_ud) & snp_req_head_buf.snp_req.snp_return_dirty_data;
assign snp_req_head_buf_s3_resp_pd_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_resp_pd_nxt  = snp_req_head_buf_s3_resp_pd_set & (~snp_req_head_buf_s3_resp_pd_clr);

  // the cache line was unqiue
assign snp_req_head_buf_s3_was_unique_set  = s2_tag_hit_state_ud | s2_tag_hit_state_uc;
assign snp_req_head_buf_s3_was_unique_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_was_unique_nxt  = snp_req_head_buf_s3_was_unique_set & (~snp_req_head_buf_s3_was_unique_clr);


std_dffre #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_RD_DATA_WR_LST_DONE (.clk(clk),.rstn (rst),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_rd_data_wr_lst_done_nxt) ,.q(snp_req_head_buf_s3_rd_data_wr_lst_done));
std_dffe #(.WIDTH(L1D_BANK_WAY_INDEX_WIDTH)) U_DAT_REG_HEAD_BUF_S3_TAG_COMPARE_MATCH_ID(.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_tag_compare_match_id_nxt) ,.q(snp_req_head_buf_s3_tag_compare_match_id));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_DATA_RESP (.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_data_resp_nxt) ,.q(snp_req_head_buf_s3_data_resp));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_RESP_INV  (.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_resp_inv_nxt) ,.q(snp_req_head_buf_s3_resp_inv));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_RESP_SC   (.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_resp_sc_nxt) ,.q(snp_req_head_buf_s3_resp_sc));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_RESP_PD   (.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_resp_pd_nxt) ,.q(snp_req_head_buf_s3_resp_pd));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_WAS_UNIQUE(.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_was_unique_nxt) ,.q(snp_req_head_buf_s3_was_unique));


// 4.4 s3: snoop resp

// 4.4.1 get data ram output for data resp
assign snp_l1d_bank_snp_s3_req_vld_o  = snp_req_head_buf_valid &
                                        snp_req_head_buf.s1_conflict_check_done &
                                        snp_req_head_buf.s2_read_tag_lst_done &
                                        snp_req_head_buf.s3_rd_data_wr_lst_done &
                                        ~snp_req_head_buf.s4_snp_resp_done;
assign snp_l1d_bank_snp_s3_tag_compare_match_id_o = snp_req_head_buf.s3_tag_compare_match_id;

// 4.4.2 do the snoop resp
assign pc_scu_resp_vld_o      = (snp_l1d_bank_snp_s3_req_vld_o & ~snp_req_head_buf.s3_data_resp) | // for now, snp resp with data no need to send resp, only need to send data
                                (snp_req_head_buf_valid & snp_req_head_buf.s4_snp_resp_done & ~snp_req_head_buf.cr_hsk_done); // if cr hsk failed, continue to send cr vld
assign snp_resp_if_cr_hsk     = pc_scu_resp_vld_o & pc_scu_resp_rdy_i;
assign snp_resp_if_cr_bypass  = snp_l1d_bank_snp_s3_req_vld_o & snp_req_head_buf.s3_data_resp;

// assign snp_resp_if_cr_o.crresp.DataTransfer = snp_req_head_buf.s3_data_resp;
// assign snp_resp_if_cr_o.crresp.Error        = 1'b0;
// assign snp_resp_if_cr_o.crresp.PassDirty    = snp_req_head_buf.s3_resp_pd;
// assign snp_resp_if_cr_o.crresp.IsShared     = snp_req_head_buf.s3_resp_sc;
// assign snp_resp_if_cr_o.crresp.WasUnique    = snp_req_head_buf.s3_was_unique;

assign pc_scu_resp_o.id.cid     = CORE_ID;
assign pc_scu_resp_o.id.bid     = '0;
assign pc_scu_resp_o.id.pc_tid  = '0;
assign pc_scu_resp_o.id.scu_tid = snp_req_head_buf.snp_req.id.scu_tid;
assign pc_scu_resp_o.id.sid     = snp_req_head_buf.snp_req.id.sid;
assign pc_scu_resp_o.rtype      = snp_req_head_buf.s3_resp_inv ? SnpAck_FoundI : SnpAck_FoundSorE;

assign pc_scu_resp_o.src_id     = '0;
assign pc_scu_resp_o.tgt_id     = '0;
`ifdef ENABLE_TXN_ID
assign pc_scu_resp_o.txn_id     = TxnID_Width'(pc_scu_resp_o.id);
`endif
`ifdef USE_QOS_VALUE
  assign pc_scu_resp_o.qos_value  = '0;
`endif

// 4.4.3 do the snoop data resp
`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
logic need_critical_word_first;
logic critical_sent_q_or_no_critical;
logic critical_sent_q_and_common_part_can_send;
logic pc_scu_data_vld_tmp;

logic critical_sent_d, critical_sent_q;
logic critical_sent_set, critical_sent_clr;
logic critical_sent_ena;
logic [DATA_BURST_NUM-1:0] critical_word_mask;
logic [DATA_BURST_NUM-1:0] common_word_mask;

assign critical_sent_q_or_no_critical = critical_sent_q | ~need_critical_word_first;

assign need_critical_word_first = snp_req_head_buf.snp_req.data_resp_with_critical_word_first;

assign critical_sent_set = snp_resp_if_cd_hsk & ~critical_sent_q_or_no_critical;
assign critical_sent_clr = snp_req_head_buf_cd_hsk_done_nxt;
assign critical_sent_ena = critical_sent_set | critical_sent_clr;
assign critical_sent_d   = (critical_sent_q | critical_sent_set) & ~critical_sent_clr;

std_dffre
  #(.WIDTH(1)) 
U_SNP_CTRL_critical_sent_REG
(
  .clk  (clk    ),
  .rstn (rst    ),
  .en   (critical_sent_ena ),
  .d    (critical_sent_d   ),
  .q    (critical_sent_q   )
);

assign critical_word_mask = need_critical_word_first ? DATA_BURST_NUM'(1 << snp_req_head_buf.snp_req.snp_line_addr_offset[(L1D_OFFSET_WIDTH-1)-:DATA_BURST_NUM_W]): '0;
assign common_word_mask   = need_critical_word_first ? ~critical_word_mask & '1 : '1;


assign pc_scu_data_vld_tmp    = (snp_l1d_bank_snp_s3_req_vld_o & snp_req_head_buf.s3_data_resp) | // first time send cd vld
                                (snp_req_head_buf_valid & snp_req_head_buf.s4_snp_resp_done & ~snp_req_head_buf.cd_hsk_done); // if cd hsk failed, continue to send cd vld
assign pc_scu_data_vld_o      = pc_scu_data_vld_tmp & (~critical_sent_q | critical_sent_q & critical_sent_q_and_common_part_can_send);
assign snp_resp_if_cd_hsk     = pc_scu_data_vld_o & pc_scu_data_rdy_i;
assign snp_resp_if_cd_bypass  = snp_l1d_bank_snp_s3_req_vld_o & ~snp_req_head_buf.s3_data_resp;

assign pc_scu_data_o.id.cid     = CORE_ID;
assign pc_scu_data_o.id.bid     = '0;
assign pc_scu_data_o.id.pc_tid  = '0;
assign pc_scu_data_o.id.scu_tid = snp_req_head_buf.snp_req.id.scu_tid;
assign pc_scu_data_o.id.scu_sid = snp_req_head_buf.snp_req.id.scu_sid;
assign pc_scu_data_o.rtype      = SnpAck_FoundM;

logic [DATA_BURST_NUM-1:0][DATA_LENGTH_PER_PKG-1:0]   pc_scu_data_tmp;
generate
  for(genvar data_seg_id = 0; data_seg_id < DATA_BURST_NUM; data_seg_id++) begin: gen_pc_scu_data_o
    assign pc_scu_data_tmp    [data_seg_id] = snp_req_head_buf_cd_data_hold_valid_q ? snp_req_head_buf_cd_data_hold[data_seg_id*DATA_LENGTH_PER_PKG+:DATA_LENGTH_PER_PKG] :
                                                                                      snp_l1d_bank_snp_s3_req_line_data_i[data_seg_id*DATA_LENGTH_PER_PKG+:DATA_LENGTH_PER_PKG];
  `ifdef SET_INVALID_DATA_PART_ZERO_EN
    assign pc_scu_data_o.data [data_seg_id] = critical_sent_q_or_no_critical ? pc_scu_data_tmp[data_seg_id] & {DATA_LENGTH_PER_PKG{common_word_mask[data_seg_id]}} :
                                                                               pc_scu_data_tmp[data_seg_id] & {DATA_LENGTH_PER_PKG{critical_word_mask[data_seg_id]}};
  `else
    assign pc_scu_data_o.data [data_seg_id] = pc_scu_data_tmp [data_seg_id];
  `endif
  end
endgenerate

  `ifdef PRIVATE_CACHE_TO_SCU_DATA_SNP_RESP_DIRTY_PART_ONLY
assign pc_scu_data_o.data_valid = (critical_sent_q_or_no_critical ? common_word_mask : critical_word_mask) & snp_req_head_buf.s2_lst_dat.data_dirty[snp_req_head_buf.s3_tag_compare_match_id];
assign pc_scu_data_o.data_dirty = pc_scu_data_o.data_valid;
  `else
assign pc_scu_data_o.data_valid = critical_sent_q_or_no_critical ? common_word_mask : critical_word_mask;
assign pc_scu_data_o.data_dirty = '1;
  `endif

assign pc_scu_data_o.is_critical      = ~critical_sent_q_or_no_critical;
assign pc_scu_data_o.has_another_part = critical_sent_q_or_no_critical ? (|critical_word_mask) : (|common_word_mask);

assign pc_scu_data_o.src_id     = '0;
assign pc_scu_data_o.tgt_id     = '0;
  `ifdef ENABLE_TXN_ID
assign pc_scu_data_o.txn_id     = TxnID_Width'(pc_scu_data_o.id);
  `endif
  `ifdef USE_QOS_VALUE
assign pc_scu_data_o.qos_value  = critical_sent_q_or_no_critical ? '0 : '1;
  `endif


  `ifdef COMMON_DATA_VALID_LATENCY_EN
logic [COMMON_DATA_VALID_LATENCY-1:0] common_data_valid_delay;
logic                                 common_data_valid_delay_ena;

generate
  for(genvar di = 1; di < COMMON_DATA_VALID_LATENCY; di++) begin: gen_common_data_valid_delay
    std_dffre
      #(.WIDTH(1)) 
    U_SNP_CTRL_common_data_valid_delay_REG
    (
      .clk  (clk    ),
      .rstn (rst    ),
      .en   (common_data_valid_delay_ena ),
      .d    (common_data_valid_delay[di-1] ),
      .q    (common_data_valid_delay[di]   )
    );
  end
endgenerate

assign common_data_valid_delay_ena  = critical_sent_set | (pc_scu_data_vld_tmp & critical_sent_q);
assign common_data_valid_delay  [0] = critical_sent_set | (critical_sent_q & pc_scu_data_vld_o & ~pc_scu_data_rdy_i); // other than critical_sent_set, if the critical_sent_q_and_common_part_can_send set but hsk failed because of ready_i low, reassign the critical_sent_q_and_common_part_can_send;
assign critical_sent_q_and_common_part_can_send = common_data_valid_delay[COMMON_DATA_VALID_LATENCY-1];
  `else
assign critical_sent_q_and_common_part_can_send = '1;
  `endif

`else
assign pc_scu_data_vld_o      = (snp_l1d_bank_snp_s3_req_vld_o & snp_req_head_buf.s3_data_resp) | // first time send cd vld
                                (snp_req_head_buf_valid & snp_req_head_buf.s4_snp_resp_done & ~snp_req_head_buf.cd_hsk_done); // if cd hsk failed, continue to send cd vld
assign snp_resp_if_cd_hsk     = pc_scu_data_vld_o & pc_scu_data_rdy_i;
assign snp_resp_if_cd_bypass  = snp_l1d_bank_snp_s3_req_vld_o & ~snp_req_head_buf.s3_data_resp;

// assign snp_resp_if_cd_o.cddata = snp_l1d_bank_snp_s3_req_line_data_i;
// assign snp_resp_if_cd_o.cdlast = 1'b1;

assign pc_scu_data_o.id.cid     = CORE_ID;
assign pc_scu_data_o.id.bid     = '0;
assign pc_scu_data_o.id.pc_tid  = '0;
assign pc_scu_data_o.id.scu_tid = snp_req_head_buf.snp_req.id.scu_tid;
assign pc_scu_data_o.id.sid     = snp_req_head_buf.snp_req.id.sid;
assign pc_scu_data_o.rtype      = SnpAck_FoundM;
generate
  for(genvar data_seg_id = 0; data_seg_id < DATA_BURST_NUM; data_seg_id++) begin
    assign pc_scu_data_o.data [data_seg_id] = snp_req_head_buf_cd_data_hold_valid_q ? snp_req_head_buf_cd_data_hold[data_seg_id*DATA_LENGTH_PER_PKG+:DATA_LENGTH_PER_PKG] :
                                                                                      snp_l1d_bank_snp_s3_req_line_data_i[data_seg_id*DATA_LENGTH_PER_PKG+:DATA_LENGTH_PER_PKG];
  end
endgenerate

  `ifdef PRIVATE_CACHE_TO_SCU_DATA_SNP_RESP_DIRTY_PART_ONLY
assign pc_scu_data_o.data_valid = snp_req_head_buf.s2_lst_dat.data_dirty[snp_req_head_buf.s3_tag_compare_match_id];
assign pc_scu_data_o.data_dirty = pc_scu_data_o.data_valid;
  `else
assign pc_scu_data_o.data_valid = '1;
assign pc_scu_data_o.data_dirty = '1;
  `endif

assign pc_scu_data_o.src_id     = '0;
assign pc_scu_data_o.tgt_id     = '0;
  `ifdef ENABLE_TXN_ID
assign pc_scu_data_o.txn_id     = TxnID_Width'(pc_scu_data_o.id);
  `endif
  `ifdef USE_QOS_VALUE
assign pc_scu_data_o.qos_value  = '0;
  `endif
`endif

// 4.4.4 s3 handshake
assign snp_req_head_buf_s4_snp_resp_done_set = snp_l1d_bank_snp_s3_req_vld_o;
assign snp_req_head_buf_s4_snp_resp_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s4_snp_resp_done_nxt = snp_l1d_bank_snp_s3_req_vld_o & (~snp_req_head_buf_s4_snp_resp_done_clr);
assign snp_req_head_buf_s4_snp_resp_done_ena = snp_req_head_buf_s4_snp_resp_done_set | snp_req_head_buf_s4_snp_resp_done_clr;

std_dffre #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S4_SNP_RESP_DONE (.clk(clk),.rstn (rst),.en(snp_req_head_buf_s4_snp_resp_done_ena) ,.d(snp_req_head_buf_s4_snp_resp_done_nxt) ,.q(snp_req_head_buf_s4_snp_resp_done));

// 4.4.5 check cr and cd hsk
assign snp_req_head_buf_cr_hsk_done_set = snp_resp_if_cr_hsk | snp_resp_if_cr_bypass;
assign snp_req_head_buf_cr_hsk_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_cr_hsk_done_nxt = snp_req_head_buf_cr_hsk_done_set & (~snp_req_head_buf_cr_hsk_done_clr);
assign snp_req_head_buf_cr_ena          = snp_req_head_buf_cr_hsk_done_set | snp_req_head_buf_cr_hsk_done_clr;

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
assign snp_req_head_buf_cd_hsk_done_set = (snp_resp_if_cd_hsk & critical_sent_q_or_no_critical) | snp_resp_if_cd_bypass;
`else
assign snp_req_head_buf_cd_hsk_done_set = snp_resp_if_cd_hsk | snp_resp_if_cd_bypass;
`endif
assign snp_req_head_buf_cd_hsk_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_cd_hsk_done_nxt = snp_req_head_buf_cd_hsk_done_set & (~snp_req_head_buf_cd_hsk_done_clr);
assign snp_req_head_buf_cd_ena          = snp_req_head_buf_cd_hsk_done_set | snp_req_head_buf_cd_hsk_done_clr;

std_dffre #(.WIDTH(1)) U_STA_REG_HEAD_BUF_CR_HSK_DONE (.clk(clk),.rstn (rst),.en(snp_req_head_buf_cr_ena) ,.d(snp_req_head_buf_cr_hsk_done_nxt) ,.q(snp_req_head_buf_cr_hsk_done));
std_dffre #(.WIDTH(1)) U_STA_REG_HEAD_BUF_CD_HSK_DONE (.clk(clk),.rstn (rst),.en(snp_req_head_buf_cd_ena) ,.d(snp_req_head_buf_cd_hsk_done_nxt) ,.q(snp_req_head_buf_cd_hsk_done));

// 4.4.6 if cd channel not hsk immediately, buffer the data
assign snp_req_head_buf_cd_data_hold_nxt = snp_l1d_bank_snp_s3_req_line_data_i;
assign snp_req_head_buf_cd_data_hold_ena = snp_l1d_bank_snp_s3_req_vld_o &
                                           (~snp_req_head_buf_cd_hsk_done_nxt // |
                                            // snp_req_head_buf_cd_hsk_done_nxt & ~snp_resp_if_cd_o.cdlast
                                            );
std_dffe #(.WIDTH(L1D_BANK_LINE_DATA_SIZE)) U_DAT_REG_HEAD_BUF_CD_DATA_HOLD (.clk(clk),.en(snp_req_head_buf_cd_data_hold_ena) ,.d(snp_req_head_buf_cd_data_hold_nxt) ,.q(snp_req_head_buf_cd_data_hold));
std_dffre #(.WIDTH(1)) U_DAT_REG_HEAD_BUF_CD_DATA_HOLD_VALID (.clk(clk),.rstn (rst),.en(snp_req_head_buf_cd_data_hold_valid_ena),.d(snp_req_head_buf_cd_data_hold_valid_d) ,.q(snp_req_head_buf_cd_data_hold_valid_q));

assign snp_req_head_buf_cd_data_hold_valid_set = snp_req_head_buf_cd_data_hold_ena;
assign snp_req_head_buf_cd_data_hold_valid_clr = snp_req_head_buf_cd_data_hold_valid_q & snp_req_head_buf_cd_hsk_done_nxt;
assign snp_req_head_buf_cd_data_hold_valid_ena = snp_req_head_buf_cd_data_hold_valid_set | snp_req_head_buf_cd_data_hold_valid_clr;
assign snp_req_head_buf_cd_data_hold_valid_d   = (snp_req_head_buf_cd_data_hold_valid_q | snp_req_head_buf_cd_data_hold_valid_set) & ~snp_req_head_buf_cd_data_hold_valid_clr;

endmodule
