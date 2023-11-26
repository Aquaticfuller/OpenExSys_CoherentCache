module rvh_scu
  import rvh_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_uncore_param_pkg::*;
  import rvh_noc_pkg::*;
#(
  parameter int MSHR_NUM      = 8,
  parameter int MSHR_NUM_W    = $clog2(MSHR_NUM) > 0 ? $clog2(MSHR_NUM) : 1,
  parameter int REPL_MSHR_NUM      = 8,
  parameter int REPL_MSHR_NUM_W    = $clog2(REPL_MSHR_NUM) > 0 ? $clog2(REPL_MSHR_NUM) : 1,
  parameter int EVICT_ESCAPE_MSHR_NUM = 1, // to prevent evict that need to alloc new mshr block that hit other valid mshr and don't need to alloc new mshr ones, make some mshr entry only alloc to evict req
  parameter int EVICT_FIFO_ROTATE_COUNTER_W = 6
)
(
  // scu rx port, private cache -> scu
    // req
  input  logic                        pc_scu_req_vld_i,
  input  cache_scu_cc_req_t           pc_scu_req_i,
  output logic                        pc_scu_req_rdy_o,

    // resp
  input  logic                        pc_scu_resp_vld_i,
  input  cache_scu_cc_resp_t          pc_scu_resp_i,
  output logic                        pc_scu_resp_rdy_o,

    // evict/wb
  input  logic                        pc_scu_evict_vld_i,
  input  cache_scu_cc_req_t           pc_scu_evict_i,
  output logic                        pc_scu_evict_rdy_o,

    // data
  input  logic                        pc_scu_data_vld_i,
  input  cache_scu_cc_data_t          pc_scu_data_i,
  output logic                        pc_scu_data_rdy_o,

  // scu tx port, scu -> private cache
    // resp
  output logic                        scu_pc_resp_vld_o,
  output cache_scu_cc_resp_t          scu_pc_resp_o,
  input  logic                        scu_pc_resp_rdy_i,

    // snp
  output logic                        scu_pc_snp_vld_o,
  output cache_scu_cc_snp_t           scu_pc_snp_o,
  input  logic                        scu_pc_snp_rdy_i,

    // data
  output logic                        scu_pc_data_vld_o,
  output cache_scu_cc_data_t          scu_pc_data_o,
  input  logic                        scu_pc_data_rdy_i,


  // mem intf
    // AR
  output logic                        mem_if_arvalid_o,
  output cache_mem_if_ar_t            mem_if_ar_o,
  input  logic                        mem_if_arready_i,
    // R
  input  logic                        mem_if_rvalid_i,
  input  cache_mem_if_r_t             mem_if_r_i,
  output logic                        mem_if_rready_o,
    // AW
  output logic                        mem_if_awvalid_o,
  input  logic                        mem_if_awready_i,
  output cache_mem_if_aw_t            mem_if_aw_o,
    // W
  output logic                        mem_if_wvalid_o,
  input  logic                        mem_if_wready_i,
  output cache_mem_if_w_t             mem_if_w_o,
    // B
  input  logic                        mem_if_bvalid_i,
  output logic                        mem_if_bready_o,
  input  cache_mem_if_b_t             mem_if_b_i,


  output logic                        pc_scu_evict_hsk_o,
  output logic                        pc_scu_req_hsk_o,

  output logic                        scu_evict_buf_order_fifo_dq_hsk_o,
  output logic                        scu_req_buf_order_fifo_dq_hsk_o,

  // clk, rst
  input  logic                        clk_i,
  input  logic                        rstn_i
);

// registers and related sgnals
  // pipe reg
scu_pipe_reg_t cur, nxt;
logic nxt_s0_ena, nxt_s1_ena;
  // pipe valid
logic s0_valid_d, s1_valid_d;
logic s0_valid_q, s1_valid_q;
  // pipe stall
logic s0_stall;
logic s1_stall;
logic new_mshr_stall;


  // mshr reg
scu_mshr_t [MSHR_NUM-1:0]   mshr_q;
  // mshr valid
logic      [MSHR_NUM-1:0]   mshr_valid_q;
  // mshr free num excludes escape mshr
logic      [MSHR_NUM_W:0]   free_mshr_no_escape_num;
logic      [MSHR_NUM_W-1:0] selected_free_mshr_no_escape_id;
logic                       selected_free_mshr_no_escape_id_valid;
  // mshr free num includes escape mshr
logic      [MSHR_NUM_W:0]   free_mshr_with_escape_num;
logic      [MSHR_NUM_W-1:0] selected_free_mshr_with_escape_id;
logic                       selected_free_mshr_with_escape_id_valid;

  // repl mshr reg
scu_repl_mshr_t [REPL_MSHR_NUM-1:0]   repl_mshr_q;
  // repl mshr valid
logic      [REPL_MSHR_NUM-1:0]   repl_mshr_valid_q;
  // repl mshr free num
logic      [REPL_MSHR_NUM_W:0]      free_repl_mshr_num;
logic      [REPL_MSHR_NUM_W-1:0]  selected_free_repl_mshr_id;
logic                             selected_free_repl_mshr_id_valid;

//   // state reg
// scu_llc_line_state_t  [LLC_SET_NUM-1:0][LLC_WAY_NUM-1:0] llc_line_state_q, llc_line_state_d;
// logic                 [LLC_SET_NUM-1:0][LLC_WAY_NUM-1:0] llc_line_state_ena;
//   // dir reg
// scu_dir_entry_t       [LLC_SET_NUM-1:0][LLC_WAY_NUM-1:0] scu_dir_entry_q, scu_dir_entry_d;
// logic                 [LLC_SET_NUM-1:0][LLC_WAY_NUM-1:0] scu_dir_entry_ena;

  // mshr fifo signals
    // req_to_read_mem_fifo
logic                             new_mshr_enqueue_req_to_read_mem_fifo;
    // req_to_read_data_ram_fifo
logic [LLC_DATA_RAM_BANK_NUM-1:0] new_mshr_enqueue_req_to_read_data_ram_fifo;
    // snp_to_cache_fifo
logic                             new_mshr_enqueue_snp_to_cache_fifo;
    // resp_to_requestor_fifo
logic                             new_mshr_enqueue_resp_to_requestor_fifo;

  // mshr fifo signals
    // req_to_read_data_ram_fifo
logic [LLC_DATA_RAM_BANK_NUM-1:0] new_repl_mshr_enqueue_req_to_read_data_ram_fifo;
    // snp_to_cache_fifo
logic                             new_repl_mshr_enqueue_snp_to_cache_fifo;


  // mshr with data ram intf
    // read req out
logic [LLC_DATA_RAM_BANK_NUM-1:0]                                        mshr_read_data_ram_valid;
logic [LLC_DATA_RAM_BANK_NUM-1:0]                                        mshr_read_data_ram_ready;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                       mshr_read_data_ram_way_valid;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] mshr_read_data_ram_idx;
    // read data in
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                       mshr_read_data_ram_way_valid_q;
logic [LLC_DATA_RAM_BANK_NUM-1:0]                                        mshr_read_data_ram_valid_q;
logic [LLC_DATA_RAM_BANK_NUM-1:0][DATA_LINE_W-1:0]                       mshr_read_data_ram_dram_rdat;

    // write req out
logic [LLC_DATA_RAM_BANK_NUM-1:0]                                        mshr_write_data_ram_valid;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                       mshr_write_data_ram_way_valid;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] mshr_write_data_ram_idx;
logic [LLC_DATA_RAM_BANK_NUM-1:0][DATA_LINE_W-1:0]                       mshr_write_data_ram_dram_wdat;
logic [LLC_DATA_RAM_BANK_NUM-1:0]                                        mshr_write_data_ram_ready;

  // mshr with tag ram intf
    // write req out
logic [LLC_TAG_RAM_BANK_NUM-1:0]                                         mshr_write_tag_ram_valid;
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                        mshr_write_tag_ram_way_valid;
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0]  mshr_write_tag_ram_idx;
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0]                     mshr_write_tag_ram_dram_wdat;
logic [LLC_TAG_RAM_BANK_NUM-1:0]                                         mshr_write_tag_ram_ready;


  // repl mshr with data ram intf
    // read req out
logic [LLC_DATA_RAM_BANK_NUM-1:0]                                        repl_mshr_read_data_ram_valid;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                       repl_mshr_read_data_ram_way_valid;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] repl_mshr_read_data_ram_idx;
logic [LLC_DATA_RAM_BANK_NUM-1:0]                                        repl_mshr_read_data_ram_ready;
    // read data in
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                       repl_mshr_read_data_ram_way_valid_q;
logic [LLC_DATA_RAM_BANK_NUM-1:0]                                        repl_mshr_read_data_ram_valid_q;
logic [LLC_DATA_RAM_BANK_NUM-1:0][DATA_LINE_W-1:0]                       repl_mshr_read_data_ram_dram_rdat;

  // repl mshr with tag ram intf
    // write req out
logic [LLC_TAG_RAM_BANK_NUM-1:0]                                         repl_mshr_write_tag_ram_valid;
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                        repl_mshr_write_tag_ram_way_valid;
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0]  repl_mshr_write_tag_ram_idx;
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0]                     repl_mshr_write_tag_ram_dram_wdat;
logic [LLC_TAG_RAM_BANK_NUM-1:0]                                         repl_mshr_write_tag_ram_ready;



// cache to scu evict fifo

logic scu_evict_buf_order_fifo_eq_vld;
logic scu_evict_buf_order_fifo_eq_rdy;
cache_scu_cc_req_t scu_evict_buf_order_fifo_eq_pl;

logic scu_evict_buf_order_fifo_dq_vld;
logic scu_evict_buf_order_fifo_dq_rdy;
cache_scu_cc_req_t scu_evict_buf_order_fifo_dq_pl;

logic [EVICT_FIFO_ROTATE_COUNTER_W-1:0] rotate_counter_q, rotate_counter_d;
logic rotate_counter_ena;

logic scu_evict_buf_order_fifo_rotate_vld;
cache_scu_cc_req_t scu_evict_buf_order_fifo_rotate_pl;

assign rotate_counter_ena = scu_evict_buf_order_fifo_dq_vld;
assign rotate_counter_d   = scu_evict_buf_order_fifo_dq_hsk_o ? '0 : rotate_counter_q + 1;

assign scu_evict_buf_order_fifo_rotate_vld = (rotate_counter_q == '1) & scu_evict_buf_order_fifo_dq_vld & ~pc_scu_evict_vld_i;
assign scu_evict_buf_order_fifo_rotate_pl  = scu_evict_buf_order_fifo_dq_pl;

assign scu_evict_buf_order_fifo_eq_vld = pc_scu_evict_vld_i | scu_evict_buf_order_fifo_rotate_vld;
assign scu_evict_buf_order_fifo_eq_pl  = pc_scu_evict_vld_i ? pc_scu_evict_i : scu_evict_buf_order_fifo_rotate_pl;

assign pc_scu_evict_rdy_o = scu_evict_buf_order_fifo_eq_rdy;


mp_fifo
#(
    .payload_t          (cache_scu_cc_req_t    ),
    .ENQUEUE_WIDTH      (1                                      ),
    .DEQUEUE_WIDTH      (1                                      ),
    .DEPTH              (SCU_EVICT_BUFFER_DEPTH+1               ), // one more entry for rotate
    .MUST_TAKEN_ALL     (1                                      )
)
scu_evict_fifo_u
(
    // Enqueue
    .enqueue_vld_i          (scu_evict_buf_order_fifo_eq_vld      ),
    .enqueue_payload_i      (scu_evict_buf_order_fifo_eq_pl       ),
    .enqueue_rdy_o          (scu_evict_buf_order_fifo_eq_rdy      ),
    // Dequeue
    .dequeue_vld_o          (scu_evict_buf_order_fifo_dq_vld   ),
    .dequeue_payload_o      (scu_evict_buf_order_fifo_dq_pl    ),
    .dequeue_rdy_i          (scu_evict_buf_order_fifo_dq_rdy   ),

    .flush_i                (1'b0                ),

    .clk                    (clk_i                 ),
    .rst                    (~rstn_i                 )
);

assign scu_evict_buf_order_fifo_dq_hsk_o = scu_evict_buf_order_fifo_dq_vld & (scu_evict_buf_order_fifo_dq_rdy & ~scu_evict_buf_order_fifo_rotate_vld);

// resp EVICT at the cycle when the EVICT req is hsk into SCU
logic                        evict_req_need_to_resp;
logic                        scu_pc_evict_resp_vld;
cache_scu_cc_resp_t          scu_pc_evict_resp;
logic                        scu_pc_evict_resp_rdy;

assign evict_req_need_to_resp = scu_evict_buf_order_fifo_dq_vld & (scu_evict_buf_order_fifo_dq_pl.rtype == Evict);
assign scu_pc_evict_resp_vld  = scu_evict_buf_order_fifo_dq_hsk_o & evict_req_need_to_resp;

assign scu_pc_evict_resp.id.cid     = scu_evict_buf_order_fifo_dq_pl.id.cid;
assign scu_pc_evict_resp.id.bid     = scu_evict_buf_order_fifo_dq_pl.id.bid;
assign scu_pc_evict_resp.id.pc_tid  = scu_evict_buf_order_fifo_dq_pl.id.pc_tid;
assign scu_pc_evict_resp.id.scu_tid = '0; // not used
assign scu_pc_evict_resp.rtype      = WriteBack_Ack;
assign scu_pc_evict_resp.src_id     = '0;
assign scu_pc_evict_resp.tgt_id     = '0;
`ifdef ENABLE_TXN_ID
assign scu_pc_evict_resp.txn_id     = TxnID_Width'(scu_pc_evict_resp.id);
`endif
`ifdef USE_QOS_VALUE
assign scu_pc_evict_resp.qos_value  = '0;
`endif


std_dffre 
  #(.WIDTH(EVICT_FIFO_ROTATE_COUNTER_W)) 
U_DAT_ROTATE_COUNTER_REG
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en(rotate_counter_ena),
  .d(rotate_counter_d),
  .q(rotate_counter_q)
);


// cache to scu req fifo
logic scu_req_buf_order_fifo_dq_vld;
logic scu_req_buf_order_fifo_dq_rdy;
cache_scu_cc_req_t scu_req_buf_order_fifo_dq_pl;

mp_fifo
#(
    .payload_t          (cache_scu_cc_req_t    ),
    .ENQUEUE_WIDTH      (1                                      ),
    .DEQUEUE_WIDTH      (1                                      ),
    .DEPTH              (SCU_REQ_BUFFER_DEPTH                   ),
    .MUST_TAKEN_ALL     (1                                      )
)
scu_req_fifo_u
(
    // Enqueue
    .enqueue_vld_i          (pc_scu_req_vld_i       ),
    .enqueue_payload_i      (pc_scu_req_i           ),
    .enqueue_rdy_o          (pc_scu_req_rdy_o       ),
    // Dequeue
    .dequeue_vld_o          (scu_req_buf_order_fifo_dq_vld   ),
    .dequeue_payload_o      (scu_req_buf_order_fifo_dq_pl    ),
    .dequeue_rdy_i          (scu_req_buf_order_fifo_dq_rdy   ),

    .flush_i                (1'b0                ),

    .clk                    (clk_i                 ),
    .rst                    (~rstn_i                 )
);

assign scu_req_buf_order_fifo_dq_hsk_o = scu_req_buf_order_fifo_dq_vld & scu_req_buf_order_fifo_dq_rdy;



// ---------------
// SCU s0: check if the req can be taken at the cycle
// ---------------
logic pc_scu_req_taken_into_pipe;
logic s0_pc_scu_evict_wb; // if s0 also has a evict, stall the req pipeline at s2, count it will take a mshr at s0
// s0: 1 check mshr
    // s0: 1.1 conflict same line addr
logic                 req_found_same_addr_mshr;
logic [MSHR_NUM-1:0]  req_found_same_addr_mshr_per_mshr_entry;
// logic [MSHR_NUM-1:0]  ask_for_unique_mshr;
// logic [MSHR_NUM-1:0]  ask_for_unique_mshr_per_mshr_entry;

assign req_found_same_addr_mshr = |(req_found_same_addr_mshr_per_mshr_entry);

generate
  for(genvar mshr_id = 0; mshr_id < MSHR_NUM; mshr_id++) begin: gen_req_found_same_addr_mshr_per_mshr_entry
    assign req_found_same_addr_mshr_per_mshr_entry[mshr_id] = mshr_valid_q[mshr_id] &
                                                        (scu_req_buf_order_fifo_dq_pl.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH] == mshr_q[mshr_id].req.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH]);
  end
endgenerate

// assign ask_for_unique_mshr = |(ask_for_unique_mshr_per_mshr_entry);

// generate
//   for(genvar mshr_id = 0; mshr_id < MSHR_NUM; mshr_id++) begin: gen_ask_for_unique_mshr_per_mshr_entry
//     assign ask_for_unique_mshr_per_mshr_entry[mshr_id] = mshr_valid_q[mshr_id] &
//                                                    ((mshr_q[mshr_id].req.rtype == ReadUnique) | (mshr_q[mshr_id].req.rtype == CleanUnique));
//   end
// endgenerate

    // s0: 1.2 no free mshr entry(the vld mshr entry+in pipeline req == total mshr entry)
logic has_free_mshr_entry;

always_comb begin
  has_free_mshr_entry = '0;
  if(s0_pc_scu_evict_wb) begin
    if(s0_valid_q & s1_valid_q) begin
      has_free_mshr_entry = free_mshr_no_escape_num > 3;
    end else if(s0_valid_q ^ s1_valid_q) begin
      has_free_mshr_entry = free_mshr_no_escape_num > 2;
    end else begin
      has_free_mshr_entry = free_mshr_no_escape_num > 1;
    end
  end else begin
    if(s0_valid_q & s1_valid_q) begin
      has_free_mshr_entry = free_mshr_no_escape_num > 2;
    end else if(s0_valid_q ^ s1_valid_q) begin
      has_free_mshr_entry = free_mshr_no_escape_num > 1;
    end else begin
      has_free_mshr_entry = selected_free_mshr_no_escape_id_valid;
    end
  end
end


  // s0: 2 check pipeline
    // s0: 2.1 conflict same line addr
logic           req_found_same_addr_pipe;
logic [2-1:0]   req_found_same_addr_pipe_per_pipe;
// logic           ask_for_unique_pipe;
// logic [2-1:0]   ask_for_unique_pipe_per_pipe;

assign req_found_same_addr_pipe = |(req_found_same_addr_pipe_per_pipe);

assign req_found_same_addr_pipe_per_pipe[0] = s0_valid_q &
                                              (scu_req_buf_order_fifo_dq_pl.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH] == cur.s0.req.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH]);
assign req_found_same_addr_pipe_per_pipe[1] = s1_valid_q &
                                              (scu_req_buf_order_fifo_dq_pl.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH] == cur.s1.req.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH]);


// assign ask_for_unique_pipe = |(ask_for_unique_pipe_per_pipe);

// assign ask_for_unique_pipe_per_pipe[0] = s0_valid_q &
//                                          ((cur.s0.req.rtype == ReadUnique) | (cur.s0.req.rtype == CleanUnique));
// assign ask_for_unique_pipe_per_pipe[1] = s1_valid_q &
//                                          ((cur.s1.req.rtype == ReadUnique) | (cur.s1.req.rtype == CleanUnique));


  // s0: 3 check repl mshr
    // s0: 3.1 conflict same line addr
logic                 req_found_same_addr_repl_mshr;
logic [REPL_MSHR_NUM-1:0]  req_found_same_addr_repl_mshr_per_repl_mshr_entry;

assign req_found_same_addr_repl_mshr = |(req_found_same_addr_repl_mshr_per_repl_mshr_entry);

generate
  for(genvar mshr_id = 0; mshr_id < REPL_MSHR_NUM; mshr_id++) begin: gen_req_found_same_addr_repl_mshr_per_repl_mshr_entry
    assign req_found_same_addr_repl_mshr_per_repl_mshr_entry[mshr_id] = repl_mshr_valid_q[mshr_id] &
                                                                    (scu_req_buf_order_fifo_dq_pl.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH] == repl_mshr_q[mshr_id].addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH]);
  end
endgenerate

  // s0: req hsk with interconnect
logic pc_scu_req_hsk;
assign pc_scu_req_hsk = scu_req_buf_order_fifo_dq_vld & scu_req_buf_order_fifo_dq_rdy;
assign pc_scu_req_taken_into_pipe   = scu_req_buf_order_fifo_dq_vld & 
                                      has_free_mshr_entry &
                                      ~req_found_same_addr_mshr & ~req_found_same_addr_pipe & ~req_found_same_addr_repl_mshr;
assign scu_req_buf_order_fifo_dq_rdy =  scu_req_buf_order_fifo_dq_vld &
                                        ~s0_stall &
                                        ~s0_pc_scu_evict_wb &
                                        (
                                          (pc_scu_req_taken_into_pipe) //|
                                          // (~req_found_same_addr_pipe & ask_for_unique_mshr) |
                                          // (~req_found_same_addr_mshr & ask_for_unique_pipe)
                                        ); // removed: 1.1.2.2 in mshr is ReadUnique or CleanUnique: will snp the reqor and inv it, take the req and remove it, no resp to reqor because the reqor itself will restart the req after get inv snp

assign pc_scu_req_hsk_o = pc_scu_req_hsk;


// ---------------
// SCU s0: evict/wb
// ---------------
logic pc_scu_evict_is_evict;
logic pc_scu_evict_is_wb_full;
logic pc_scu_evict_is_wb_partial;

assign pc_scu_evict_is_evict      = scu_evict_buf_order_fifo_dq_vld & (scu_evict_buf_order_fifo_dq_pl.rtype == Evict);
assign pc_scu_evict_is_wb_full    = scu_evict_buf_order_fifo_dq_vld & (scu_evict_buf_order_fifo_dq_pl.rtype == WriteBackFull);
assign pc_scu_evict_is_wb_partial = scu_evict_buf_order_fifo_dq_vld & (scu_evict_buf_order_fifo_dq_pl.rtype == WriteBackPartial);
assign s0_pc_scu_evict_wb = pc_scu_evict_is_evict | pc_scu_evict_is_wb_full | pc_scu_evict_is_wb_partial;
  // s0: 1 check pipeline
    // s0: 1.1 conflict same line addr: stall the evict/wb.
logic           evict_found_same_addr_pipe;
logic [2-1:0]   evict_found_same_addr_pipe_per_pipe;

assign evict_found_same_addr_pipe = |(evict_found_same_addr_pipe_per_pipe);

assign evict_found_same_addr_pipe_per_pipe[0] = s0_valid_q &
                                              (scu_evict_buf_order_fifo_dq_pl.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH] == cur.s0.req.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH]);
assign evict_found_same_addr_pipe_per_pipe[1] = s1_valid_q &
                                              (scu_evict_buf_order_fifo_dq_pl.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH] == cur.s1.req.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH]);


  // s0: 2 check mshr/ repl mshr
    // s0: 2.1 hit valid mshr: no need to alloc new mshr, just send to evict/wb to the mshr entry.
logic                 evict_found_same_addr_updated_mshr;
logic                 evict_found_same_not_updated_addr_mshr;
logic [MSHR_NUM-1:0]  evict_found_same_addr_mshr_per_mshr_entry;
logic [MSHR_NUM-1:0]  evict_found_same_addr_not_updated_dir_mshr_per_mshr_entry;

logic                              scu_mshr_evict_vld;
cache_scu_cc_req_t                 scu_mshr_evict;
logic [MSHR_NUM_W-1:0]             scu_mshr_evict_mshr_id;
logic                              scu_mshr_evict_rdy;

generate
  for(genvar mshr_id = 0; mshr_id < MSHR_NUM; mshr_id++) begin: gen_evict_found_same_addr_mshr_per_mshr_entry
    assign evict_found_same_addr_mshr_per_mshr_entry[mshr_id] = mshr_valid_q[mshr_id] &
                                                        (scu_evict_buf_order_fifo_dq_pl.addr[PADDR_WIDTH-1:LLC_OFFSET_WIDTH] == mshr_q[mshr_id].req.addr[PADDR_WIDTH-1:LLC_OFFSET_WIDTH]);

    assign evict_found_same_addr_not_updated_dir_mshr_per_mshr_entry[mshr_id] = evict_found_same_addr_mshr_per_mshr_entry[mshr_id] &
                                                                                mshr_q[mshr_id].need_to_update_dir & ~mshr_q[mshr_id].final_update_enqueued;
  end
endgenerate

assign evict_found_same_addr_updated_mshr = (evict_found_same_addr_mshr_per_mshr_entry != evict_found_same_addr_not_updated_dir_mshr_per_mshr_entry);

priority_encoder
#(
  .SEL_WIDTH(MSHR_NUM)
)
scu_mshr_evict_mshr_id_sel
(
  .sel_i      (evict_found_same_addr_not_updated_dir_mshr_per_mshr_entry  ),
  .id_vld_o   (evict_found_same_not_updated_addr_mshr                 ),
  .id_o       (scu_mshr_evict_mshr_id                     )
);

assign scu_mshr_evict_vld     = scu_evict_buf_order_fifo_dq_hsk_o & evict_found_same_not_updated_addr_mshr;
assign scu_mshr_evict         = scu_evict_buf_order_fifo_dq_pl;

    // s0: 2.2 hit valid repl mshr: no need to alloc new mshr, just send to evict/wb to the repl mshr entry
logic                       evict_found_same_addr_updated_repl_mshr;
logic                       evict_found_same_not_updated_addr_repl_mshr;
logic [REPL_MSHR_NUM-1:0]   evict_found_same_addr_repl_mshr_per_repl_mshr_entry;
logic [REPL_MSHR_NUM-1:0]   evict_found_same_addr_not_updated_dir_repl_mshr_per_repl_mshr_entry;
 
logic                              scu_repl_mshr_evict_vld;
cache_scu_cc_req_t                 scu_repl_mshr_evict;
logic [REPL_MSHR_NUM_W-1:0]        scu_repl_mshr_evict_repl_mshr_id;
logic                              scu_repl_mshr_evict_rdy;

generate
  for(genvar mshr_id = 0; mshr_id < REPL_MSHR_NUM; mshr_id++) begin: gen_evict_found_same_addr_repl_mshr_per_repl_mshr_entry
    assign evict_found_same_addr_repl_mshr_per_repl_mshr_entry[mshr_id] = repl_mshr_valid_q[mshr_id] &
                                                        (scu_evict_buf_order_fifo_dq_pl.addr[PADDR_WIDTH-1:LLC_OFFSET_WIDTH] == repl_mshr_q[mshr_id].addr[PADDR_WIDTH-1:LLC_OFFSET_WIDTH]);

    assign evict_found_same_addr_not_updated_dir_repl_mshr_per_repl_mshr_entry[mshr_id] = evict_found_same_addr_repl_mshr_per_repl_mshr_entry[mshr_id] &
                                                                                          ((repl_mshr_q[mshr_id].need_to_update_dir & ~repl_mshr_q[mshr_id].final_update_enqueued) | ~repl_mshr_q[mshr_id].need_to_update_dir);
  end
endgenerate

assign evict_found_same_addr_updated_repl_mshr = (evict_found_same_addr_repl_mshr_per_repl_mshr_entry != evict_found_same_addr_not_updated_dir_repl_mshr_per_repl_mshr_entry);

priority_encoder
#(
  .SEL_WIDTH(REPL_MSHR_NUM)
)
scu_repl_mshr_evict_repl_mshr_id_sel
(
  .sel_i      (evict_found_same_addr_not_updated_dir_repl_mshr_per_repl_mshr_entry  ),
  .id_vld_o   (evict_found_same_not_updated_addr_repl_mshr                 ),
  .id_o       (scu_repl_mshr_evict_repl_mshr_id                     )
);

assign scu_repl_mshr_evict_vld     = scu_evict_buf_order_fifo_dq_hsk_o & evict_found_same_not_updated_addr_repl_mshr;
assign scu_repl_mshr_evict         = scu_evict_buf_order_fifo_dq_pl;



    // s0: 2.3 no hit mshr/ repl mshr
      // s0: 2.3.1 no free mshr entry(the vld mshr entry+in pipeline req == total mshr entry)
logic has_free_mshr_entry_for_evict;

always_comb begin
  has_free_mshr_entry_for_evict = '0;
  if(s0_valid_q & s1_valid_q) begin
    has_free_mshr_entry_for_evict = free_mshr_with_escape_num > 2;
  end else if(s0_valid_q ^ s1_valid_q) begin
    has_free_mshr_entry_for_evict = free_mshr_with_escape_num > 1;
  end else begin
    has_free_mshr_entry_for_evict = selected_free_mshr_with_escape_id_valid;
  end
end

  // s0: evict hsk with interconnect
logic pc_scu_evict_hsk;
logic pc_scu_evict_need_new_mshr;
logic pc_scu_evict_alloc_new_mshr_hsk;
assign pc_scu_evict_hsk = scu_evict_buf_order_fifo_dq_hsk_o;
assign pc_scu_evict_need_new_mshr   = scu_evict_buf_order_fifo_dq_vld &
                                      ~evict_found_same_addr_pipe &
                                      ~evict_found_same_not_updated_addr_mshr;
assign pc_scu_evict_alloc_new_mshr_hsk  = pc_scu_evict_need_new_mshr & (scu_evict_buf_order_fifo_dq_rdy & ~scu_evict_buf_order_fifo_rotate_vld);
assign scu_evict_buf_order_fifo_dq_rdy  = (scu_evict_buf_order_fifo_dq_vld &
                                          ~s0_stall &
                                          ~evict_found_same_addr_pipe &
                                          (~pc_scu_evict_need_new_mshr | has_free_mshr_entry_for_evict) &
                                          ~evict_found_same_addr_updated_mshr &
                                          ~evict_found_same_addr_updated_repl_mshr &
                                          (evict_req_need_to_resp ? scu_pc_resp_rdy_i : '1)) |
                                          scu_evict_buf_order_fifo_rotate_vld; // not real dequeue, only fifo rotate
assign pc_scu_evict_hsk_o = pc_scu_evict_hsk;

// ---------------
// SCU s0: nxt.s0
// ---------------
logic [LLC_PER_TAG_RAM_BANK_INDEX_WIDTH-1:0]  s1_read_tag_ram_bank_idx;
logic [LLC_TAG_RAM_BANK_NUM_WIDTH-1:0]        s1_read_tag_ram_bank_id;

assign s0_stall   = s0_valid_q & (
                      s1_stall |  // stall when s1 stall and cur.s0 has valid req
                      mshr_write_tag_ram_valid[s1_read_tag_ram_bank_id] |     // stall by mshr write tag ram bank conflict
                      repl_mshr_write_tag_ram_valid[s1_read_tag_ram_bank_id]  // stall by repl mshr write tag ram bank conflict
                    );

assign s0_valid_d = s0_stall           ? s0_valid_q :
                    s0_pc_scu_evict_wb ? pc_scu_evict_hsk & ~scu_mshr_evict_vld & ~scu_repl_mshr_evict_vld :
                                         pc_scu_req_hsk;
assign nxt_s0_ena = ~s0_stall & s0_valid_d; // update cur.s0 data only when s0 not stalled and have valid data to write
assign nxt.s0.req = s0_pc_scu_evict_wb ? scu_evict_buf_order_fifo_dq_pl : scu_req_buf_order_fifo_dq_pl;
assign nxt.s0.no_need_alloc_new_mshr = s0_pc_scu_evict_wb & ~pc_scu_evict_need_new_mshr;
assign nxt.s0.is_evict_wb            = s0_pc_scu_evict_wb;

// ---------------
// SCU s1: read state/tag/dir
// ---------------
  // s1: 1 read tag ram
logic s1_read_tag_ram_en;

assign s1_read_tag_ram_en = s0_valid_q;
assign s1_read_tag_ram_bank_idx = cur.s0.req.addr[(LLC_OFFSET_WIDTH+$clog2(LLC_TAG_RAM_BANK_NUM))+:LLC_PER_TAG_RAM_BANK_INDEX_WIDTH];
`ifdef LLC_TAG_RAM_MULTI_BANK
assign s1_read_tag_ram_bank_id  = cur.s0.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_TAG_RAM_BANK_NUM)];
`else
assign s1_read_tag_ram_bank_id  = '0;
`endif
/* both of state and dir are fused with tag
  // s1: 2 read state reg
scu_llc_line_state_t [LLC_WAY_NUM-1:0] llc_line_state_for_chosen_set;
logic [LLC_INDEX_WIDTH-1:0]  s1_req_llc_idx;

assign s1_req_llc_idx = cur.s0.req.addr[LLC_OFFSET_WIDTH+:LLC_INDEX_WIDTH];

generate
  for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin: gen_llc_line_state_for_chosen_set
    assign llc_line_state_for_chosen_set[way_id] = llc_line_state_q[s1_req_llc_idx][way_id];
  end
endgenerate

  // s1: 3 read dir reg
scu_dir_entry_t [LLC_WAY_NUM-1:0] scu_dir_entry_for_chosen_set;

generate
  for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin: gen_scu_dir_entry_for_chosen_set
    assign scu_dir_entry_for_chosen_set[way_id] = scu_dir_entry_q[s1_req_llc_idx][way_id];
  end
endgenerate
*/
  // s1: nxt.s1
assign s1_stall   = s1_valid_q &
                    new_mshr_stall;
assign s1_valid_d = s1_stall  ? s1_valid_q :
                    s0_stall  ? '0 : s0_valid_q;
assign nxt_s1_ena = ~s1_stall & s1_valid_d; // update cur.s1 data only when s1 not stalled and have valid data to write
assign nxt.s1.req = cur.s0.req;
assign nxt.s1.no_need_alloc_new_mshr = cur.s0.no_need_alloc_new_mshr;
assign nxt.s1.is_evict_wb            = cur.s0.is_evict_wb;
// assign nxt.s1.llc_line_state_for_chosen_set = llc_line_state_for_chosen_set;
// assign nxt.s1.scu_dir_entry_for_chosen_set  = scu_dir_entry_for_chosen_set;


// ---------------
// SCU s2: get tag ram data, config new mshr
// ---------------
logic [LLC_TAG_RAM_BANK_NUM_WIDTH-1:0]      s2_get_tag_ram_bank_id;
logic [LLC_WAY_NUM-1:0][LLC_TAG_WIDTH-1:0]  tags_for_given_set;
scu_llc_line_state_t [LLC_WAY_NUM-1:0]      llc_line_state_for_chosen_set;
scu_dir_entry_t [LLC_WAY_NUM-1:0]           scu_dir_entry_for_chosen_set;
scu_mshr_t      new_mshr;
logic           new_mshr_valid;
logic           need_new_repl_mshr;

`ifdef LLC_TAG_RAM_MULTI_BANK
assign s2_get_tag_ram_bank_id = cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_TAG_RAM_BANK_NUM)];
`else
assign s2_get_tag_ram_bank_id = '0;
`endif

  // s2: 1 compare tag
logic [LLC_WAY_NUM-1:0]                         tags_compare_result;
logic [LLC_WAY_NUM-1:0]                         valid_bits_result;
logic [LLC_WAY_NUM-1:0]                         dirty_bits_result;
logic [LLC_WAY_NUM-1:0]                         valid_tags_compare_result;
logic [LLC_WAY_NUM-1:0]                         owner_bits_result;
logic [LLC_WAY_NUM-1:0][PRIVATE_CACHE_NUM-1:0]  sharer_vectors_result;
logic [LLC_WAY_NUM-1:0]                         has_sharer_result;

scu_llc_line_state_t                            llc_line_state_for_chosen_set_chosen_way;
scu_dir_entry_t                                 scu_dir_entry_for_chosen_set_chosen_way;
logic [PRIVATE_CACHE_NUM-1:0]                   sharer_vectors_result_chosen_way;
logic [PRIVATE_CACHE_NUM-1:0]                   sharer_vectors_result_chosen_way_no_reqor;

logic dir_hit; // private cache(s) has valid and latest data
logic llc_hit; // llc has valid and latest data

generate
  for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin: gen_tags_compare_result
    assign tags_compare_result  [way_id] = (cur.s1.req.addr[(PADDR_WIDTH-1)-:LLC_TAG_WIDTH] == tags_for_given_set[way_id]);
    assign valid_bits_result    [way_id] = llc_line_state_for_chosen_set[way_id].valid;
    assign dirty_bits_result    [way_id] = llc_line_state_for_chosen_set[way_id].dirty;
    assign owner_bits_result    [way_id] = scu_dir_entry_for_chosen_set[way_id].has_owner;
    assign sharer_vectors_result[way_id] = scu_dir_entry_for_chosen_set[way_id].sharer_list;
    assign has_sharer_result    [way_id] = |(scu_dir_entry_for_chosen_set[way_id].sharer_list);
  end
endgenerate

assign valid_tags_compare_result = tags_compare_result & valid_bits_result;
assign llc_hit = |(valid_tags_compare_result & (~owner_bits_result | (owner_bits_result & ~has_sharer_result)));
assign dir_hit = |(valid_tags_compare_result & has_sharer_result);

always_comb begin: comb_sharer_vectors_result_chosen_way_no_reqor
  sharer_vectors_result_chosen_way_no_reqor = sharer_vectors_result_chosen_way;
  sharer_vectors_result_chosen_way_no_reqor[cur.s1.req.id.cid] = 1'b0;
end

assign new_mshr_valid = ~s1_stall & s1_valid_q & ~cur.s1.no_need_alloc_new_mshr;

always_comb begin: comb_new_mshr_alloc
  // new_mshr
  new_mshr = '0;
  new_mshr.llc_hit      = llc_hit;
  new_mshr.dir_hit      = dir_hit;
  new_mshr.req          = cur.s1.req;
  new_mshr.wb_pc_id     = '0;
  new_mshr.wb_rtype     = '0;
  new_mshr.dir_entry    = scu_dir_entry_for_chosen_set_chosen_way;
  new_mshr.state_entry  = llc_line_state_for_chosen_set_chosen_way;
  new_mshr.valid_tags_compare_result = valid_tags_compare_result;
  new_mshr.data         = '0;
  new_mshr.data_valid   = '0;
  new_mshr.data_dirty   = '0;
  new_mshr.mem_resp_data_seg_wr_ptr   = '0;

  new_mshr.snp_need_to_send_list      = '0;
  new_mshr.snp_sent_list              = '0;
  new_mshr.snp_resp_receiving_list    = '0;
  new_mshr.snp_data_receiving_list    = '0;
  new_mshr.snp_resp_receiving_invalid_list = '0;
  new_mshr.evict_resp_receiving_list  = '0;
  new_mshr.writeback_data_received    = '0;

  new_mshr.wait_for_wb_data_en                              = '0;
  new_mshr.wait_for_mem_read_data_en                        = '0;
  new_mshr.wait_for_llc_read_data_en                        = '0;
  new_mshr.need_invalid_snp                                 = '0;
  new_mshr.need_shared_snp                                  = '0;
  new_mshr.final_update_enqueued                            = '0;
  new_mshr.need_to_update_data                              = '0;
  new_mshr.need_to_update_tag                               = '0;
  new_mshr.need_to_update_dir                               = '0;
  new_mshr.monitor_evict_before_update_dir                  = '0;
  new_mshr.monitor_evict_before_receiving_all_snp_resp      = '0;
  new_mshr.monitor_writeback_before_receiving_all_snp_resp  = '0;
  new_mshr.final_resp_enqueued                              = '0;
  new_mshr.wait_for_resp_ack                                = '0;
  new_mshr.the_permission_dropped                           = '0;

  // req_to_read_mem_fifo
  new_mshr_enqueue_req_to_read_mem_fifo       = '0;
  // req_to_read_data_ram_fifo
  new_mshr_enqueue_req_to_read_data_ram_fifo  = '0;
  // snp_to_cache_fifo
  new_mshr_enqueue_snp_to_cache_fifo          = '0;
  // resp_to_requestor_fifo 
  new_mshr_enqueue_resp_to_requestor_fifo     = '0;


  unique case({dir_hit, llc_hit})
    // s2: 1.1 no tag match or it is invalid: it is dir miss+llc miss
    2'b00: begin
      // set new_mshr
      new_mshr.wait_for_mem_read_data_en  = 1'b1;
      new_mshr.need_to_update_data        = 1'b1;
      new_mshr.need_to_update_tag         = 1'b1;
      new_mshr.need_to_update_dir         = 1'b1;
      new_mshr.wait_for_resp_ack          = 1'b1;

      new_mshr.valid_tags_compare_result = new_repl_mshr.victim_way_chosen_result;
      new_mshr.dir_entry                 = '0;
      new_mshr.state_entry               = '0;

      // enqueue req_to_read_mem_fifo
      new_mshr_enqueue_req_to_read_mem_fifo  = 1'b1;
      
      unique case(cur.s1.req.rtype)
        CleanUnique: begin
          // if the sharer vector donesn't have reqor, treat the req as a ReadUnique
          new_mshr.req.rtype = ReadUnique; // treat the req as a ReadUnique
        end
        default: begin
        end
      endcase
    end
    // s2: 1.2 valid tag match, sharer vector empty: it is owned by llc, it is dir miss+llc hit
    2'b01: begin
      // set new_mshr
      new_mshr.wait_for_llc_read_data_en  = 1'b1;
      new_mshr.need_to_update_dir         = 1'b1;
      new_mshr.wait_for_resp_ack          = 1'b1;
      // enqueue req_to_read_data_ram_fifo
`ifdef LLC_DATA_RAM_MULTI_BANK
      new_mshr_enqueue_req_to_read_data_ram_fifo [cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
`else
      new_mshr_enqueue_req_to_read_data_ram_fifo [0] = 1'b1;
`endif

      unique case(cur.s1.req.rtype)
        CleanUnique: begin
          // if the sharer vector donesn't have reqor, treat the req as a ReadUnique
          new_mshr.req.rtype = ReadUnique; // treat the req as a ReadUnique
        end
        default: begin
        end
      endcase
    end
    // s2: 1.3 valid tag match, sharer vector has sharer, owner bit unset: it is dir hit+llc hit
    2'b11: begin
      unique case(cur.s1.req.rtype)
        ReadShared,
        ReadOnce: begin
          // set new_mshr
          new_mshr.wait_for_llc_read_data_en        = 1'b1;
          new_mshr.need_to_update_dir               = 1'b1;
          new_mshr.wait_for_resp_ack                = 1'b1;
          new_mshr.monitor_evict_before_update_dir  = 1'b1;
          // enqueue req_to_read_data_ram_fifo
`ifdef LLC_DATA_RAM_MULTI_BANK
          new_mshr_enqueue_req_to_read_data_ram_fifo [cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
`else
          new_mshr_enqueue_req_to_read_data_ram_fifo [0] = 1'b1;
`endif
        end

        ReadUnique: begin
          // set new_mshr
          new_mshr.wait_for_llc_read_data_en        = 1'b1;
          new_mshr.need_invalid_snp                 = 1'b1;
          new_mshr.need_to_update_dir               = 1'b1;
          new_mshr.wait_for_resp_ack                = 1'b1;
          new_mshr.monitor_evict_before_update_dir  = 1'b1;
          new_mshr.monitor_evict_before_receiving_all_snp_resp = 1'b1;
          new_mshr.snp_need_to_send_list            = sharer_vectors_result_chosen_way_no_reqor;
          // enqueue req_to_read_data_ram_fifo
`ifdef LLC_DATA_RAM_MULTI_BANK
          new_mshr_enqueue_req_to_read_data_ram_fifo [cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
`else
          new_mshr_enqueue_req_to_read_data_ram_fifo [0] = 1'b1;
`endif
          // enqueue snp_to_cache_fifo
          new_mshr_enqueue_snp_to_cache_fifo  = 1'b1;
        end

        CleanUnique: begin
          if(sharer_vectors_result_chosen_way[cur.s1.req.id.cid]) begin
            if(|(sharer_vectors_result_chosen_way_no_reqor)) begin // has more than 1 sharers
              // set new_mshr
              new_mshr.need_invalid_snp                 = 1'b1;
              new_mshr.need_to_update_dir               = 1'b1;
              new_mshr.wait_for_resp_ack                = 1'b1;
              new_mshr.monitor_evict_before_update_dir  = 1'b1;
              new_mshr.monitor_evict_before_receiving_all_snp_resp = 1'b1;
              new_mshr.snp_need_to_send_list            = sharer_vectors_result_chosen_way_no_reqor;
              // enqueue snp_to_cache_fifo
              new_mshr_enqueue_snp_to_cache_fifo  = 1'b1;
            end else begin //  has only 1 sharer, it should be the requestor
              // set new_mshr
              new_mshr.need_to_update_dir               = 1'b1;
              new_mshr.wait_for_resp_ack                = 1'b1;
              // enqueue resp_to_requestor_fifo
              new_mshr_enqueue_resp_to_requestor_fifo   = 1'b1;

              new_mshr.final_resp_enqueued              = 1'b1; // take new_mshr_enqueue_resp_to_requestor_fifo as final resp

            end         
          end else begin // if the sharer vector donesn't have reqor, treat the req as a ReadUnique
            // set new_mshr
            new_mshr.wait_for_llc_read_data_en        = 1'b1;
            new_mshr.need_invalid_snp                 = 1'b1;
            new_mshr.need_to_update_dir               = 1'b1;
            new_mshr.wait_for_resp_ack                = 1'b1;
            new_mshr.monitor_evict_before_update_dir  = 1'b1;
            new_mshr.monitor_evict_before_receiving_all_snp_resp = 1'b1;
            new_mshr.snp_need_to_send_list            = sharer_vectors_result_chosen_way_no_reqor;

            new_mshr.req.rtype                        = ReadUnique; // treat the req as a ReadUnique

            // enqueue req_to_read_data_ram_fifo
`ifdef LLC_DATA_RAM_MULTI_BANK
            new_mshr_enqueue_req_to_read_data_ram_fifo [cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
`else
            new_mshr_enqueue_req_to_read_data_ram_fifo [0] = 1'b1;
`endif
            // enqueue snp_to_cache_fifo
            new_mshr_enqueue_snp_to_cache_fifo  = 1'b1;
          end
        end

        Evict: begin
          // set new_mshr
          new_mshr.need_to_update_dir               = 1'b1;
          new_mshr.evict_resp_receiving_list        = PRIVATE_CACHE_NUM'(1<<cur.s1.req.id.cid);
        end
        default: begin
        end
      endcase
    end
    // s2: 1.4 valid tag match, sharer vector has sharer, owner bit set: it is dir hit+llc miss, 
    // consider the owner as dirty, need to do snp(for ReadShared and ReadOnce shared snp, else inv snp) and get any return dirty data
    2'b10: begin
      unique case(cur.s1.req.rtype)
        ReadShared,
        ReadOnce: begin
          // set new_mshr
          new_mshr.wait_for_llc_read_data_en        = 1'b1;
          new_mshr.need_shared_snp                  = 1'b1;
          new_mshr.need_to_update_dir               = 1'b1;
          new_mshr.wait_for_resp_ack                = 1'b1;
          new_mshr.monitor_evict_before_update_dir  = 1'b1;
          new_mshr.monitor_evict_before_receiving_all_snp_resp      = 1'b1;
          new_mshr.monitor_writeback_before_receiving_all_snp_resp  = 1'b1;
          new_mshr.snp_need_to_send_list            = sharer_vectors_result_chosen_way_no_reqor;
          // enqueue req_to_read_data_ram_fifo
`ifdef LLC_DATA_RAM_MULTI_BANK
          new_mshr_enqueue_req_to_read_data_ram_fifo [cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
`else
          new_mshr_enqueue_req_to_read_data_ram_fifo [0] = 1'b1;
`endif
          // enqueue snp_to_cache_fifo
          new_mshr_enqueue_snp_to_cache_fifo  = 1'b1;
        end
        ReadUnique,
        CleanUnique: begin // for CleanUnique, it means the reqor has been invalidated before the req get into scu, so treat it as a ReadUnique
          // set new_mshr
          new_mshr.wait_for_llc_read_data_en        = 1'b1;
          new_mshr.need_invalid_snp                 = 1'b1;
          new_mshr.need_to_update_dir               = 1'b1;
          new_mshr.wait_for_resp_ack                = 1'b1;
          new_mshr.monitor_evict_before_receiving_all_snp_resp      = 1'b1;
          new_mshr.monitor_writeback_before_receiving_all_snp_resp  = 1'b1;
          new_mshr.snp_need_to_send_list            = sharer_vectors_result_chosen_way_no_reqor;

          new_mshr.req.rtype                        = ReadUnique; // for CleanUnique, treat the req as a ReadUnique

          // enqueue req_to_read_data_ram_fifo
`ifdef LLC_DATA_RAM_MULTI_BANK
          new_mshr_enqueue_req_to_read_data_ram_fifo [cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
`else
          new_mshr_enqueue_req_to_read_data_ram_fifo [0] = 1'b1;
`endif
          // enqueue snp_to_cache_fifo
          new_mshr_enqueue_snp_to_cache_fifo  = 1'b1;
        end

        WriteBackFull: begin
          // set new_mshr
          new_mshr.need_to_update_data              = 1'b1;
          new_mshr.need_to_update_dir               = 1'b1;
          new_mshr.wait_for_wb_data_en              = 1'b1;
          new_mshr.evict_resp_receiving_list        = PRIVATE_CACHE_NUM'(1<<cur.s1.req.id.cid);
          new_mshr.wb_pc_id                         = cur.s1.req.id;
          new_mshr.wb_rtype                         = cur.s1.req.rtype;
          // enqueue resp_to_requestor_fifo
          new_mshr_enqueue_resp_to_requestor_fifo   = 1'b1;
        end

        WriteBackPartial: begin
          // set new_mshr
          new_mshr.wait_for_llc_read_data_en        = 1'b1;
          new_mshr.need_to_update_data              = 1'b1;
          new_mshr.need_to_update_dir               = 1'b1;
          new_mshr.wait_for_wb_data_en              = 1'b1;
          new_mshr.evict_resp_receiving_list        = PRIVATE_CACHE_NUM'(1<<cur.s1.req.id.cid);
          new_mshr.wb_pc_id                         = cur.s1.req.id;
          new_mshr.wb_rtype                         = cur.s1.req.rtype;
          // enqueue req_to_read_data_ram_fifo
`ifdef LLC_DATA_RAM_MULTI_BANK
          new_mshr_enqueue_req_to_read_data_ram_fifo [cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
`else
          new_mshr_enqueue_req_to_read_data_ram_fifo [0] = 1'b1;
`endif
          // enqueue resp_to_requestor_fifo
          new_mshr_enqueue_resp_to_requestor_fifo   = 1'b1;
        end

        Evict: begin // may get Evict in this situation because a UniqueClean line may be evicted from private cache while scu record it as owner
          // set new_mshr
          new_mshr.need_to_update_dir               = 1'b1;
          new_mshr.evict_resp_receiving_list        = PRIVATE_CACHE_NUM'(1<<cur.s1.req.id.cid);
        end

        default: begin
        end
      endcase
    end
    default: begin
    end
  endcase
end

`ifndef SYNTHESIS
// the writeback or evict have to be exist sharer
assert property(@(posedge clk_i)disable iff(~rstn_i) (new_mshr_valid & ((new_mshr.req.rtype == WriteBackFull) | (new_mshr.req.rtype == WriteBackPartial) | (new_mshr.req.rtype == Evict))) 
                                                      |-> (((PRIVATE_CACHE_NUM'(1<<cur.s1.req.id.cid)) & new_mshr.dir_entry.sharer_list) != '0))
  else $fatal("scu: receive a evict or writeback while the resquestor is not in dir sharer");
`endif

onehot_mux
#(
  .SOURCE_COUNT(LLC_WAY_NUM ),
  .DATA_WIDTH  ($bits(scu_llc_line_state_t) )
)
onehot_mux_llc_line_state_for_chosen_set_chosen_way_u (
  .sel_i    (valid_tags_compare_result                ),
  .data_i   (llc_line_state_for_chosen_set            ),
  .data_o   (llc_line_state_for_chosen_set_chosen_way )
);

onehot_mux
#(
  .SOURCE_COUNT(LLC_WAY_NUM ),
  .DATA_WIDTH  ($bits(scu_dir_entry_t) )
)
onehot_mux_scu_dir_entry_for_chosen_set_chosen_way_u (
  .sel_i    (valid_tags_compare_result                ),
  .data_i   (scu_dir_entry_for_chosen_set             ),
  .data_o   (scu_dir_entry_for_chosen_set_chosen_way  )
);

onehot_mux
#(
  .SOURCE_COUNT(LLC_WAY_NUM ),
  .DATA_WIDTH  (PRIVATE_CACHE_NUM )
)
onehot_mux_sharer_vectors_result_chosen_way_u (
  .sel_i    (valid_tags_compare_result          ),
  .data_i   (sharer_vectors_result              ),
  .data_o   (sharer_vectors_result_chosen_way   )
);



// ---------------
// SCU s2: get tag ram data, select a victim line, and config new repl mshr
// ---------------
// select a victim line
logic [LLC_WAY_NUM-1:0]   invalid_line_in_chosen_set;
logic                 invalid_line_in_chosen_set_exist;
logic [LLC_WAY_NUM_W-1:0] invalid_line_in_chosen_set_way_id;

logic [LLC_WAY_NUM-1:0]   notshared_clean_line_in_chosen_set;
logic                 notshared_clean_line_in_chosen_set_exist;
logic [LLC_WAY_NUM_W-1:0] notshared_clean_line_in_chosen_set_way_id;

logic [LLC_WAY_NUM-1:0]   notshared_dirty_line_in_chosen_set;
logic                 notshared_dirty_line_in_chosen_set_exist;
logic [LLC_WAY_NUM_W-1:0] notshared_dirty_line_in_chosen_set_way_id;

logic [LLC_WAY_NUM-1:0]   shared_line_in_chosen_set;
logic                 shared_line_in_chosen_set_exist;
logic [LLC_WAY_NUM_W-1:0] shared_line_in_chosen_set_way_id;

// logic [LLC_WAY_NUM-1:0]   shared_clean_line_in_chosen_set;
// logic                 shared_clean_line_in_chosen_set_exist;
// logic [LLC_WAY_NUM_W-1:0] shared_clean_line_in_chosen_set_way_id;

// logic [LLC_WAY_NUM-1:0]   shared_dirty_line_in_chosen_set;
// logic                 shared_dirty_line_in_chosen_set_exist;
// logic [LLC_WAY_NUM_W-1:0] shared_dirty_line_in_chosen_set_way_id;

logic [LLC_WAY_NUM_W-1:0]         repl_chosen_way_id;
scu_llc_line_state_t          repl_llc_line_state_for_chosen_set_chosen_way;
scu_dir_entry_t               repl_scu_dir_entry_for_chosen_set_chosen_way;
logic [PRIVATE_CACHE_NUM-1:0] repl_sharer_vectors_result_chosen_way;

assign invalid_line_in_chosen_set           = ~valid_bits_result; // empty line
assign notshared_clean_line_in_chosen_set   = ~has_sharer_result & ~dirty_bits_result & valid_bits_result; // not shared by private cache and clean, can be overwriten directly
assign notshared_dirty_line_in_chosen_set   = ~has_sharer_result & dirty_bits_result & valid_bits_result;  // not shared by private cache but dirty, only need to read data ram and writeback to mem
assign shared_line_in_chosen_set            = has_sharer_result & valid_bits_result;  // shared by private cache, need to read data ram(the snp resp can be partial), need to inv snp to sharers, writeback only if the sharer return dirty data and(or) data ram is dirty
// assign shared_clean_line_in_chosen_set      = has_sharer_result & ~dirty_bits_result & valid_bits_result;  // shared by private cache but clean, no need to read data ram and writeback, only need to inv snp to sharers, writeback only if the sharer return dirty data
// assign shared_dirty_line_in_chosen_set      = has_sharer_result & dirty_bits_result & valid_bits_result;   // shared by private cache and dirty, need to read data ram, and inv snp to sharers, writeback data to mem

assign repl_llc_line_state_for_chosen_set_chosen_way  = llc_line_state_for_chosen_set[repl_chosen_way_id];
assign repl_scu_dir_entry_for_chosen_set_chosen_way   = scu_dir_entry_for_chosen_set [repl_chosen_way_id];
assign repl_sharer_vectors_result_chosen_way          = sharer_vectors_result        [repl_chosen_way_id];

assign need_new_repl_mshr = ~dir_hit & ~llc_hit & s1_valid_q &
                            // empty line / not shared by private cache and clean, can be overwriten directly
                            ~(invalid_line_in_chosen_set_exist | notshared_clean_line_in_chosen_set_exist);


always_comb begin
  repl_chosen_way_id = '0;
  // empty line
  if(invalid_line_in_chosen_set_exist) begin
    repl_chosen_way_id = invalid_line_in_chosen_set_way_id;

  // not shared by private cache and clean, can be overwriten directly
  end else if (notshared_clean_line_in_chosen_set_exist) begin
    repl_chosen_way_id = notshared_clean_line_in_chosen_set_way_id;

  // not shared by private cache but dirty, only need to read data ram and writeback to mem
  end else if(notshared_dirty_line_in_chosen_set_exist) begin
    repl_chosen_way_id = notshared_dirty_line_in_chosen_set_way_id;

  // shared by private cache, need to read data ram(the snp resp can be partial), need to inv snp to sharers, writeback only if the sharer return dirty data and(or) data ram is dirty
  end else if(shared_line_in_chosen_set_exist) begin
    repl_chosen_way_id = shared_line_in_chosen_set_way_id;

  end
end

priority_encoder
#(
  .SEL_WIDTH(LLC_WAY_NUM)
)
invalid_line_in_chosen_set_way_id_sel
(
  .sel_i      (invalid_line_in_chosen_set         ),
  .id_vld_o   (invalid_line_in_chosen_set_exist   ),
  .id_o       (invalid_line_in_chosen_set_way_id  )
);

priority_encoder
#(
  .SEL_WIDTH(LLC_WAY_NUM)
)
notshared_clean_line_in_chosen_set_way_id_sel
(
  .sel_i      (notshared_clean_line_in_chosen_set         ),
  .id_vld_o   (notshared_clean_line_in_chosen_set_exist   ),
  .id_o       (notshared_clean_line_in_chosen_set_way_id  )
);

priority_encoder
#(
  .SEL_WIDTH(LLC_WAY_NUM)
)
notshared_dirty_line_in_chosen_set_way_id_sel
(
  .sel_i      (notshared_dirty_line_in_chosen_set         ),
  .id_vld_o   (notshared_dirty_line_in_chosen_set_exist   ),
  .id_o       (notshared_dirty_line_in_chosen_set_way_id  )
);

priority_encoder
#(
  .SEL_WIDTH(LLC_WAY_NUM)
)
shared_line_in_chosen_set_way_id_sel
(
  .sel_i      (shared_line_in_chosen_set         ),
  .id_vld_o   (shared_line_in_chosen_set_exist   ),
  .id_o       (shared_line_in_chosen_set_way_id  )
);


// config new repl mshr
scu_repl_mshr_t new_repl_mshr;
logic           new_repl_mshr_valid;

assign new_repl_mshr_valid = ~s1_stall & need_new_repl_mshr;

always_comb begin: comb_new_repl_mshr_alloc
  // new_repl_mshr
  new_repl_mshr = '0;
  new_repl_mshr.addr         = {tags_for_given_set[repl_chosen_way_id], cur.s1.req.addr[LLC_OFFSET_WIDTH+LLC_INDEX_WIDTH-1:0]};
  new_repl_mshr.wb_pc_id     = '0;
  new_repl_mshr.wb_rtype     = '0;
  new_repl_mshr.dir_entry    = repl_scu_dir_entry_for_chosen_set_chosen_way;
  new_repl_mshr.state_entry  = repl_llc_line_state_for_chosen_set_chosen_way;
  new_repl_mshr.victim_way_chosen_result = LLC_WAY_NUM'(1<<repl_chosen_way_id);
  new_repl_mshr.data         = '0;
  new_repl_mshr.data_valid   = '0;
  new_repl_mshr.data_dirty   = '0;
  // new_repl_mshr.mem_req_data_seg_wr_ptr    = '0;

  new_repl_mshr.snp_need_to_send_list      = '0;
  new_repl_mshr.snp_sent_list              = '0;
  new_repl_mshr.snp_resp_receiving_list    = '0;
  new_repl_mshr.snp_data_receiving_list    = '0;
  new_repl_mshr.snp_resp_receiving_invalid_list = '0;
  new_repl_mshr.evict_resp_receiving_list  = '0;
  new_repl_mshr.writeback_data_received    = '0;

  new_repl_mshr.wait_for_wb_data_en                              = '0;
  new_repl_mshr.wait_for_llc_read_data_en                        = '0;
  new_repl_mshr.need_invalid_snp                                 = '0;
  new_repl_mshr.final_update_enqueued                            = '0;
  new_repl_mshr.need_to_update_tag                               = '0;
  new_repl_mshr.need_to_update_dir                               = '0;
  new_repl_mshr.monitor_evict_before_update_dir                  = '0;
  new_repl_mshr.monitor_evict_before_receiving_all_snp_resp      = '0;
  new_repl_mshr.monitor_writeback_before_receiving_all_snp_resp  = '0;
  new_repl_mshr.dirty_writeback_mem_enqueued                     = '0;
  new_repl_mshr.dirty_writeback_mem_done                         = '0;

  // req_to_read_data_ram_fifo
  new_repl_mshr_enqueue_req_to_read_data_ram_fifo  = '0;
  // snp_to_cache_fifo
  new_repl_mshr_enqueue_snp_to_cache_fifo          = '0;

  // not shared by private cache but dirty, only need to read data ram and writeback to mem
  if(notshared_dirty_line_in_chosen_set_exist) begin
    // set new_repl_mshr
    new_repl_mshr.wait_for_llc_read_data_en = 1'b1;
    // new_repl_mshr.need_to_update_dir        = 1'b1;
    new_repl_mshr.data_dirty                = '1;

    // enqueue req_to_read_data_ram_fifo
`ifdef LLC_DATA_RAM_MULTI_BANK
    new_repl_mshr_enqueue_req_to_read_data_ram_fifo [cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
`else
    new_repl_mshr_enqueue_req_to_read_data_ram_fifo [0] = 1'b1;
`endif

 // shared by private cache, need to read data ram(the snp resp can be partial), need to inv snp to sharers, writeback only if the sharer return dirty data and(or) data ram is dirty
  end else if(shared_line_in_chosen_set_exist) begin
    // set new_repl_mshr
    new_repl_mshr.snp_need_to_send_list     = repl_sharer_vectors_result_chosen_way;
    new_repl_mshr.wait_for_llc_read_data_en = 1'b1;
    new_repl_mshr.need_invalid_snp          = 1'b1;
    // new_repl_mshr.need_to_update_dir        = 1'b1;
    new_repl_mshr.monitor_evict_before_receiving_all_snp_resp     = 1'b1;
    new_repl_mshr.monitor_writeback_before_receiving_all_snp_resp = 1'b1;
    new_repl_mshr.data_dirty                = {DATA_BURST_NUM{dirty_bits_result[repl_chosen_way_id]}};

    // enqueue req_to_read_data_ram_fifo
`ifdef LLC_DATA_RAM_MULTI_BANK
    new_repl_mshr_enqueue_req_to_read_data_ram_fifo [cur.s1.req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
`else
    new_repl_mshr_enqueue_req_to_read_data_ram_fifo [0] = 1'b1;
`endif
    // enqueue snp_to_cache_fifo
    new_repl_mshr_enqueue_snp_to_cache_fifo  = 1'b1;
  end
end


  // new_mshr_stall
assign new_mshr_stall = (need_new_repl_mshr & ~selected_free_repl_mshr_id_valid) | 
                        (s1_valid_q & ~need_new_repl_mshr & 
                          (cur.s1.is_evict_wb ? ~selected_free_mshr_with_escape_id_valid : ~selected_free_mshr_no_escape_id_valid)
                        );


// arbiter for mshr and repl mshr output, priority mshr > repl mshr
// repl mshr
  // scu rx port, private cache -> scu
    // resp
logic                        pc_scu_repl_mshr_resp_vld;
cache_scu_cc_resp_t          pc_scu_repl_mshr_resp;
logic                        pc_scu_repl_mshr_resp_rdy;

    // data
logic                        pc_scu_repl_mshr_data_vld;
cache_scu_cc_data_t          pc_scu_repl_mshr_data;
logic                        pc_scu_repl_mshr_data_rdy;

  // scu tx port, scu -> private cache
    // resp
logic                        scu_pc_repl_mshr_resp_vld;
cache_scu_cc_resp_t          scu_pc_repl_mshr_resp;
logic                        scu_pc_repl_mshr_resp_rdy;

    // snp
logic                        scu_pc_repl_mshr_snp_vld;
cache_scu_cc_snp_t           scu_pc_repl_mshr_snp;
logic                        scu_pc_repl_mshr_snp_rdy;

// arbiter for mshr and repl mshr output, priority mshr > repl mshr
// mshr
  // scu rx port, private cache -> scu
    // resp
logic                        pc_scu_mshr_resp_vld;
cache_scu_cc_resp_t          pc_scu_mshr_resp;
logic                        pc_scu_mshr_resp_rdy;

    // data
logic                        pc_scu_mshr_data_vld;
cache_scu_cc_data_t          pc_scu_mshr_data;
logic                        pc_scu_mshr_data_rdy;

  // scu tx port, scu -> private cache
    // resp
logic                        scu_pc_mshr_resp_vld;
cache_scu_cc_resp_t          scu_pc_mshr_resp;
logic                        scu_pc_mshr_resp_rdy;

    // snp
logic                        scu_pc_mshr_snp_vld;
cache_scu_cc_snp_t           scu_pc_mshr_snp;
logic                        scu_pc_mshr_snp_rdy;

// scu rx port, private cache -> scu
assign pc_scu_mshr_resp_vld       = pc_scu_resp_vld_i & ~pc_scu_resp_i.id.scu_tid[SCU_TID_W-1];
assign pc_scu_mshr_resp           = pc_scu_resp_i;

assign pc_scu_mshr_data_vld       = pc_scu_data_vld_i & ~pc_scu_data_i.id.scu_tid[SCU_TID_W-1];
assign pc_scu_mshr_data           = pc_scu_data_i;

assign pc_scu_repl_mshr_resp_vld  = pc_scu_resp_vld_i & pc_scu_resp_i.id.scu_tid[SCU_TID_W-1];
assign pc_scu_repl_mshr_resp           = pc_scu_resp_i;

assign pc_scu_repl_mshr_data_vld  = pc_scu_data_vld_i & pc_scu_data_i.id.scu_tid[SCU_TID_W-1];
assign pc_scu_repl_mshr_data      = pc_scu_data_i;

assign pc_scu_resp_rdy_o = pc_scu_mshr_resp_vld ? pc_scu_mshr_resp_rdy : pc_scu_repl_mshr_resp_rdy;
assign pc_scu_data_rdy_o = pc_scu_mshr_data_vld ? pc_scu_mshr_data_rdy : pc_scu_repl_mshr_data_rdy;

// scu tx port, scu -> private cache
assign scu_pc_resp_vld_o          = scu_pc_repl_mshr_resp_vld | scu_pc_mshr_resp_vld | scu_pc_evict_resp_vld;
assign scu_pc_resp_o              = scu_pc_evict_resp_vld ? scu_pc_evict_resp :
                                    scu_pc_mshr_resp_vld  ? scu_pc_mshr_resp  : scu_pc_repl_mshr_resp;

assign scu_pc_mshr_resp_rdy       = scu_pc_resp_rdy_i & ~scu_pc_evict_resp_vld;
assign scu_pc_repl_mshr_resp_rdy  = scu_pc_resp_rdy_i & ~scu_pc_mshr_resp_vld & ~scu_pc_evict_resp_vld;

assign scu_pc_snp_vld_o           = scu_pc_repl_mshr_snp_vld | scu_pc_mshr_snp_vld;
assign scu_pc_snp_o               = scu_pc_mshr_snp_vld ? scu_pc_mshr_snp : scu_pc_repl_mshr_snp;

assign scu_pc_mshr_snp_rdy        = scu_pc_snp_rdy_i;
assign scu_pc_repl_mshr_snp_rdy   = scu_pc_snp_rdy_i & ~scu_pc_mshr_snp_vld;

// ---------------
// repl mshr reg
// ---------------


// alloc new repl mshr
rvh_l1d_mshr_alloc
#(
  .INPUT_NUM    (REPL_MSHR_NUM)
)
rvh_scu_repl_mshr_alloc_u
(
  .mshr_bank_valid_i    (repl_mshr_valid_q                 ),
  .mshr_id_o            (selected_free_repl_mshr_id        ),
  .has_free_mshr_o      (selected_free_repl_mshr_id_valid  ),
  .free_mshr_num_o      (free_repl_mshr_num                )
);

rvh_scu_repl_mshr
#(
  .MSHR_NUM(REPL_MSHR_NUM)
)
REPL_MSHR
(
  // mshr req
  .new_mshr_valid_i       (new_repl_mshr_valid   ),
  .new_mshr_enqueue_req_to_read_data_ram_fifo_i   (new_repl_mshr_enqueue_req_to_read_data_ram_fifo),
  .new_mshr_enqueue_snp_to_cache_fifo_i           (new_repl_mshr_enqueue_snp_to_cache_fifo),
  .new_mshr_i             (new_repl_mshr         ),
  .new_mshr_id_i          (selected_free_repl_mshr_id    ),

  // mshr_q and mshr_valid_q output
  .mshr_q_o               (repl_mshr_q       ),
  .mshr_valid_q_o         (repl_mshr_valid_q ),

  // scu -> cache, snp intf
  .scu_pc_snp_vld_o       (scu_pc_repl_mshr_snp_vld ),
  .scu_pc_snp_o           (scu_pc_repl_mshr_snp     ),
  .scu_pc_snp_rdy_i       (scu_pc_repl_mshr_snp_rdy ),

  // scu -> cache, resp intf
  .scu_pc_resp_vld_o      (scu_pc_repl_mshr_resp_vld),
  .scu_pc_resp_o          (scu_pc_repl_mshr_resp    ),
  .scu_pc_resp_rdy_i      (scu_pc_repl_mshr_resp_rdy),

  // cache -> scu, resp inft
  .pc_scu_resp_vld_i      (pc_scu_repl_mshr_resp_vld),
  .pc_scu_resp_i          (pc_scu_repl_mshr_resp    ),
  .pc_scu_resp_rdy_o      (pc_scu_repl_mshr_resp_rdy),

  // cache -> scu, evict/wb
  .pc_scu_evict_vld_i     (scu_repl_mshr_evict_vld     ),
  .pc_scu_evict_i         (scu_repl_mshr_evict         ),
  .pc_scu_evict_mshr_id_i (scu_repl_mshr_evict_repl_mshr_id ),
  .pc_scu_evict_rdy_o     (scu_repl_mshr_evict_rdy     ),

  // cache -> scu, data inft
  .pc_scu_data_vld_i      (pc_scu_repl_mshr_data_vld),
  .pc_scu_data_i          (pc_scu_repl_mshr_data    ),
  .pc_scu_data_rdy_o      (pc_scu_repl_mshr_data_rdy),

  // data ram intf
    // read req out
  .mshr_read_data_ram_valid_o       (repl_mshr_read_data_ram_valid       ),
  .mshr_read_data_ram_way_valid_o   (repl_mshr_read_data_ram_way_valid   ),
  .mshr_read_data_ram_idx_o         (repl_mshr_read_data_ram_idx         ),
  .mshr_read_data_ram_ready_i       (repl_mshr_read_data_ram_ready       ),
    // read data in
  .mshr_read_data_ram_way_valid_q_o (repl_mshr_read_data_ram_way_valid_q ),
  .mshr_read_data_ram_valid_q_o     (repl_mshr_read_data_ram_valid_q     ),
  .mshr_read_data_ram_dram_rdat_i   (repl_mshr_read_data_ram_dram_rdat   ),

  // tag ram intf
    // write req out
  .mshr_write_tag_ram_valid_o       (repl_mshr_write_tag_ram_valid       ),
  .mshr_write_tag_ram_way_valid_o   (repl_mshr_write_tag_ram_way_valid   ),
  .mshr_write_tag_ram_idx_o         (repl_mshr_write_tag_ram_idx         ),
  .mshr_write_tag_ram_dram_wdat_o   (repl_mshr_write_tag_ram_dram_wdat   ),
  .mshr_write_tag_ram_ready_i       (repl_mshr_write_tag_ram_ready       ),

  // MEM NOC
    // AW 
  .mem_if_awvalid_o                (mem_if_awvalid_o    ),
  .mem_if_awready_i                (mem_if_awready_i    ),
  .mem_if_aw_o                     (mem_if_aw_o         ),
    // W 
  .mem_if_wvalid_o                 (mem_if_wvalid_o     ),
  .mem_if_wready_i                 (mem_if_wready_i     ),
  .mem_if_w_o                      (mem_if_w_o          ),
    // B
  .mem_if_bvalid_i                 (mem_if_bvalid_i     ),
  .mem_if_bready_o                 (mem_if_bready_o     ),
  .mem_if_b_i                      (mem_if_b_i          ),

  .clk_i                      (clk_i                    ),
  .rstn_i                     (rstn_i                    )
);


// ---------------
// mshr reg
// ---------------
rvh_l1d_mshr_alloc
#(
  .INPUT_NUM    (MSHR_NUM)
)
rvh_scu_mshr_with_escape_alloc_u
(
  .mshr_bank_valid_i    (mshr_valid_q                 ),
  .mshr_id_o            (selected_free_mshr_with_escape_id        ),
  .has_free_mshr_o      (selected_free_mshr_with_escape_id_valid  ),
  .free_mshr_num_o      (free_mshr_with_escape_num                )
);

rvh_l1d_mshr_alloc
#(
  .INPUT_NUM    (MSHR_NUM)
)
rvh_scu_mshr_no_escape_alloc_u
(
  .mshr_bank_valid_i    ({{EVICT_ESCAPE_MSHR_NUM{1'b1}}, mshr_valid_q[MSHR_NUM-EVICT_ESCAPE_MSHR_NUM-1:0]}),
  .mshr_id_o            (selected_free_mshr_no_escape_id        ),
  .has_free_mshr_o      (selected_free_mshr_no_escape_id_valid  ),
  .free_mshr_num_o      (free_mshr_no_escape_num                )
);

`ifndef SYNTHESIS
always_comb begin
  assert(EVICT_ESCAPE_MSHR_NUM < MSHR_NUM);
end
`endif

rvh_scu_mshr
#(
  .MSHR_NUM(MSHR_NUM)
) 
MSHR
(
  // mshr req
  .new_mshr_valid_i       (new_mshr_valid   ),
  .new_mshr_enqueue_req_to_read_mem_fifo_i        (new_mshr_enqueue_req_to_read_mem_fifo),
  .new_mshr_enqueue_req_to_read_data_ram_fifo_i   (new_mshr_enqueue_req_to_read_data_ram_fifo),
  .new_mshr_enqueue_snp_to_cache_fifo_i           (new_mshr_enqueue_snp_to_cache_fifo),
  .new_mshr_enqueue_resp_to_requestor_fifo_i      (new_mshr_enqueue_resp_to_requestor_fifo),
  .new_mshr_i             (new_mshr         ),
  .new_mshr_id_i          (selected_free_mshr_with_escape_id    ),

  // mshr_q and mshr_valid_q output
  .mshr_q_o               (mshr_q            ),
  .mshr_valid_q_o         (mshr_valid_q      ),

  // scu -> cache, snp intf
  .scu_pc_snp_vld_o       (scu_pc_mshr_snp_vld ),
  .scu_pc_snp_o           (scu_pc_mshr_snp     ),
  .scu_pc_snp_rdy_i       (scu_pc_mshr_snp_rdy ),

  // scu -> cache, resp intf
  .scu_pc_resp_vld_o      (scu_pc_mshr_resp_vld),
  .scu_pc_resp_o          (scu_pc_mshr_resp    ),
  .scu_pc_resp_rdy_i      (scu_pc_mshr_resp_rdy),

  // scu -> cache, data resp intf
  .scu_pc_data_vld_o      (scu_pc_data_vld_o),
  .scu_pc_data_o          (scu_pc_data_o    ),
  .scu_pc_data_rdy_i      (scu_pc_data_rdy_i),

  // cache -> scu, resp inft
  .pc_scu_resp_vld_i      (pc_scu_mshr_resp_vld),
  .pc_scu_resp_i          (pc_scu_mshr_resp    ),
  .pc_scu_resp_rdy_o      (pc_scu_mshr_resp_rdy),

  // cache -> scu, evict/wb
  .pc_scu_evict_vld_i     (scu_mshr_evict_vld     ),
  .pc_scu_evict_i         (scu_mshr_evict         ),
  .pc_scu_evict_mshr_id_i (scu_mshr_evict_mshr_id ),
  .pc_scu_evict_rdy_o     (scu_mshr_evict_rdy     ),

  // cache -> scu, data inft
  .pc_scu_data_vld_i      (pc_scu_mshr_data_vld),
  .pc_scu_data_i          (pc_scu_mshr_data    ),
  .pc_scu_data_rdy_o      (pc_scu_mshr_data_rdy),

  // data ram intf
    // read req out
  .mshr_read_data_ram_valid_o       (mshr_read_data_ram_valid       ),
  .mshr_read_data_ram_way_valid_o   (mshr_read_data_ram_way_valid   ),
  .mshr_read_data_ram_idx_o         (mshr_read_data_ram_idx         ),
  .mshr_read_data_ram_ready_i       (mshr_read_data_ram_ready       ),
    // read data in
  .mshr_read_data_ram_way_valid_q_o (mshr_read_data_ram_way_valid_q ),
  .mshr_read_data_ram_valid_q_o     (mshr_read_data_ram_valid_q     ),
  .mshr_read_data_ram_dram_rdat_i   (mshr_read_data_ram_dram_rdat   ),

    // write req out
  .mshr_write_data_ram_valid_o      (mshr_write_data_ram_valid      ),
  .mshr_write_data_ram_way_valid_o  (mshr_write_data_ram_way_valid  ),
  .mshr_write_data_ram_idx_o        (mshr_write_data_ram_idx        ),
  .mshr_write_data_ram_dram_wdat_o  (mshr_write_data_ram_dram_wdat  ),
  .mshr_write_data_ram_ready_i      (mshr_write_data_ram_ready      ),

  // tag ram intf
    // write req out
  .mshr_write_tag_ram_valid_o      (mshr_write_tag_ram_valid       ),
  .mshr_write_tag_ram_way_valid_o  (mshr_write_tag_ram_way_valid   ),
  .mshr_write_tag_ram_idx_o        (mshr_write_tag_ram_idx         ),
  .mshr_write_tag_ram_dram_wdat_o  (mshr_write_tag_ram_dram_wdat   ),
  .mshr_write_tag_ram_ready_i      (mshr_write_tag_ram_ready       ),

  // MEM NOC
    // AR
  .mem_if_arvalid_o                (mem_if_arvalid_o      ),
  .mem_if_ar_o                     (mem_if_ar_o           ),
  .mem_if_arready_i                (mem_if_arready_i      ),
    // R
  .mem_if_rvalid_i                 (mem_if_rvalid_i       ),
  .mem_if_r_i                      (mem_if_r_i            ),
  .mem_if_rready_o                 (mem_if_rready_o       ),


  .clk_i                      (clk_i                    ),
  .rstn_i                     (rstn_i                    )
);

// ---------------
// tag ram
// ---------------
// tag ram read
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                                       tag_ram_read_en;
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0][LLC_PER_TAG_RAM_BANK_INDEX_WIDTH-1:0] tag_ram_read_idx;

assign repl_mshr_write_tag_ram_ready = '1;
assign mshr_write_tag_ram_ready      = ~repl_mshr_write_tag_ram_valid;

generate
  for(genvar tag_ram_bank_id = 0; tag_ram_bank_id < LLC_TAG_RAM_BANK_NUM; tag_ram_bank_id++) begin
    for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin
      always_comb begin
        tag_ram_read_en [tag_ram_bank_id][way_id] = '0;
        tag_ram_read_idx[tag_ram_bank_id][way_id] = '0;
        if(s1_read_tag_ram_bank_id == tag_ram_bank_id) begin
          tag_ram_read_en [tag_ram_bank_id][way_id] = s1_read_tag_ram_en;
          tag_ram_read_idx[tag_ram_bank_id][way_id] = s1_read_tag_ram_bank_idx;
        end
      end
    end
  end
endgenerate

// tag ram write
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                                       tag_ram_write_en;
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0][LLC_PER_TAG_RAM_BANK_INDEX_WIDTH-1:0] tag_ram_write_idx;
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                   tag_ram_write_data;

generate
  for(genvar tag_ram_bank_id = 0; tag_ram_bank_id < LLC_TAG_RAM_BANK_NUM; tag_ram_bank_id++) begin: gen_tag_ram_write
    for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin
      assign tag_ram_write_en  [tag_ram_bank_id][way_id] = (mshr_write_tag_ram_valid[tag_ram_bank_id] & mshr_write_tag_ram_way_valid[tag_ram_bank_id][way_id]) |
                                                           (repl_mshr_write_tag_ram_valid[tag_ram_bank_id] & repl_mshr_write_tag_ram_way_valid[tag_ram_bank_id][way_id]);
      assign tag_ram_write_idx [tag_ram_bank_id][way_id] = repl_mshr_write_tag_ram_valid[tag_ram_bank_id] ? repl_mshr_write_tag_ram_idx[tag_ram_bank_id] : 
                                                                                                            mshr_write_tag_ram_idx[tag_ram_bank_id];
      assign tag_ram_write_data[tag_ram_bank_id][way_id] = repl_mshr_write_tag_ram_valid[tag_ram_bank_id] ? repl_mshr_write_tag_ram_dram_wdat[tag_ram_bank_id] :
                                                                                                            mshr_write_tag_ram_dram_wdat[tag_ram_bank_id];
    end
  end
endgenerate

// tag ram signals
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                                       tram_cs;
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                                       tram_wen;
logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0][LLC_PER_TAG_RAM_BANK_INDEX_WIDTH-1:0] tram_addr;
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                   tram_wdat;
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                   tram_rdat;

assign tram_cs    = tag_ram_read_en | tag_ram_write_en;
assign tram_wen   = tag_ram_write_en;
assign tram_wdat  = tag_ram_write_data;
generate
  for(genvar tag_ram_bank_id = 0; tag_ram_bank_id < LLC_DATA_RAM_BANK_NUM; tag_ram_bank_id++) begin: gen_tram_addr
    assign tram_addr[tag_ram_bank_id]  = (|(tram_wen[tag_ram_bank_id])) ? tag_ram_write_idx[tag_ram_bank_id] : 
                                                                          tag_ram_read_idx [tag_ram_bank_id];
  end
endgenerate


// tag ram generate
`ifndef SYNTHESIS
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0]  addr_to_check_tag;
logic [LLC_TAG_RAM_BANK_NUM-1:0][PADDR_WIDTH-1:0]     addr_to_wtag;
logic [LLC_TAG_RAM_BANK_NUM-1:0]                      check_tag_wen;

generate
  for(genvar tag_ram_bank_id = 0; tag_ram_bank_id <  LLC_TAG_RAM_BANK_NUM; tag_ram_bank_id++) begin: gen_req_to_write_tag_ram_fifo
`ifdef LLC_TAG_RAM_MULTI_BANK
    assign addr_to_wtag[tag_ram_bank_id]  = {tram_wdat[tag_ram_bank_id][0].tag, tram_addr[tag_ram_bank_id][0], tag_ram_bank_id[0+:LLC_TAG_RAM_BANK_NUM_WIDTH], 6'b0};
`else
    assign addr_to_wtag[tag_ram_bank_id]  = {tram_wdat[tag_ram_bank_id][0].tag, tram_addr[tag_ram_bank_id][0], 6'b0};
`endif
    assign check_tag_wen[tag_ram_bank_id] = (|tag_ram_write_en[tag_ram_bank_id]) & (addr_to_wtag[tag_ram_bank_id] == 'h1c0d040);
    std_dffre
    #(.WIDTH($bits(scu_llc_fused_tag_entry_t))) 
    U_SCU_MSHR_to_check_tag_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (check_tag_wen[tag_ram_bank_id]),
      .d    (tram_wdat[tag_ram_bank_id][0]  ),
      .q    (addr_to_check_tag[tag_ram_bank_id]   )
    );
  end
endgenerate
`endif

generate
  for(genvar bank_id = 0; bank_id <  LLC_TAG_RAM_BANK_NUM; bank_id++) begin: gen_tag_ram_bank
    for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin: gen_tag_ram_way
      generic_spram
      #(
        .w($bits(scu_llc_fused_tag_entry_t)),            // data width
        .p($bits(scu_llc_fused_tag_entry_t)),            // word partition size (data bits per write enable)
        .d(LLC_PER_TAG_RAM_BANK_SET_NUM),              // data depth
        .log2d(LLC_PER_TAG_RAM_BANK_INDEX_WIDTH),  // address width
        .id(bank_id*LLC_WAY_NUM+way_id), // unique value per instance

        .RAM_LATENCY(1),
        .RESET      (1),
        .RESET_HIGH (0)
      )
      U_TAG_RAM
      (
        .clk   (clk_i),//clock
        .ce    (tram_cs  [bank_id][way_id]),  // chip enable,low active
        .we    (tram_wen [bank_id][way_id]),  // write enable,low active
        .addr  (tram_addr[bank_id][way_id]),  // address
        .din   (tram_wdat[bank_id][way_id]),  // data in
        .dout  (tram_rdat[bank_id][way_id]),  // data out
        .biten ('1)
      );
    end
  end
endgenerate

// if s1 stall, buffer the read tag ram data for future read
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0] tram_rdat_s1_stall_d, tram_rdat_s1_stall_q;
logic tram_rdat_s1_stall_vld_d, tram_rdat_s1_stall_vld_q;
logic tram_rdat_s1_stall_ena;

assign tram_rdat_s1_stall_d     = tram_rdat;
assign tram_rdat_s1_stall_vld_d = s1_valid_q & s1_stall;
assign tram_rdat_s1_stall_ena   = ~tram_rdat_s1_stall_vld_q & tram_rdat_s1_stall_vld_d;

std_dffr 
#(.WIDTH(1))
U_TRAM_RDAT_S1_STALL_VLD_REG
(
  .clk(clk_i),
  .rstn(rstn_i),
  .d(tram_rdat_s1_stall_vld_d),
  .q(tram_rdat_s1_stall_vld_q)
);

generate
  for(genvar tag_ram_bank_id = 0; tag_ram_bank_id < LLC_DATA_RAM_BANK_NUM; tag_ram_bank_id++) begin
    for(genvar llc_way_id = 0; llc_way_id < LLC_WAY_NUM; llc_way_id++) begin
      std_dffe 
      #(
        .WIDTH($bits(scu_llc_fused_tag_entry_t))
      )
      U_TRAM_RDAT_S1_STALL_REG
      (
        .clk(clk_i),
        .en(tram_rdat_s1_stall_ena),
        .d(tram_rdat_s1_stall_d[tag_ram_bank_id][llc_way_id]),
        .q(tram_rdat_s1_stall_q[tag_ram_bank_id][llc_way_id])
      );
    end
  end
endgenerate

// s2 read tag
generate
  for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin: gen_tags_for_given_set
    assign tags_for_given_set           [way_id] = tram_rdat_s1_stall_vld_q ? tram_rdat_s1_stall_q[s2_get_tag_ram_bank_id][way_id].tag :
                                                                              tram_rdat[s2_get_tag_ram_bank_id][way_id].tag;
    assign llc_line_state_for_chosen_set[way_id] = tram_rdat_s1_stall_vld_q ? tram_rdat_s1_stall_q[s2_get_tag_ram_bank_id][way_id].state :
                                                                              tram_rdat[s2_get_tag_ram_bank_id][way_id].state;
    assign scu_dir_entry_for_chosen_set [way_id] = tram_rdat_s1_stall_vld_q ? tram_rdat_s1_stall_q[s2_get_tag_ram_bank_id][way_id].dir :
                                                                              tram_rdat[s2_get_tag_ram_bank_id][way_id].dir;
  end
endgenerate



// ---------------
// data ram
// ---------------
// data ram read
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                                        data_ram_read_en;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] data_ram_read_idx;

assign repl_mshr_read_data_ram_ready = '1;
assign mshr_write_data_ram_ready     =  ~repl_mshr_read_data_ram_valid;
assign mshr_read_data_ram_ready      =  ~repl_mshr_read_data_ram_valid &
                                        ~mshr_write_data_ram_valid;

generate
  for(genvar data_ram_bank_id = 0; data_ram_bank_id < LLC_DATA_RAM_BANK_NUM; data_ram_bank_id++) begin: gen_data_ram_read
    for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin
      assign data_ram_read_en [data_ram_bank_id][way_id] = (mshr_read_data_ram_valid[data_ram_bank_id] & mshr_read_data_ram_way_valid[data_ram_bank_id][way_id]) |
                                                           (repl_mshr_read_data_ram_valid[data_ram_bank_id] & repl_mshr_read_data_ram_way_valid[data_ram_bank_id][way_id]);
      assign data_ram_read_idx[data_ram_bank_id][way_id] = repl_mshr_read_data_ram_valid[data_ram_bank_id] ? repl_mshr_read_data_ram_idx :
                                                                                                             mshr_read_data_ram_idx[data_ram_bank_id];
    end
  end
endgenerate

// data ram write
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                                        data_ram_write_en;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] data_ram_write_idx;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0][DATA_LINE_W-1:0]                       data_ram_write_data;

generate
  for(genvar data_ram_bank_id = 0; data_ram_bank_id < LLC_DATA_RAM_BANK_NUM; data_ram_bank_id++) begin: gen_data_ram_write
    for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin
      assign data_ram_write_en  [data_ram_bank_id][way_id] = mshr_write_data_ram_valid[data_ram_bank_id] & mshr_write_data_ram_way_valid[data_ram_bank_id][way_id] &
                                                             ~repl_mshr_read_data_ram_valid[data_ram_bank_id];
      assign data_ram_write_idx [data_ram_bank_id][way_id] = mshr_write_data_ram_idx[data_ram_bank_id];
      assign data_ram_write_data[data_ram_bank_id][way_id] = mshr_write_data_ram_dram_wdat[data_ram_bank_id];
    end
  end
endgenerate


// data ram signals
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                                        dram_cs;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]                                        dram_wen;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] dram_addr;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0][DATA_LINE_W-1:0]                       dram_wdat;
logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0][DATA_LINE_W-1:0]                       dram_rdat;

assign dram_cs    = data_ram_read_en | data_ram_write_en;
assign dram_wen   = data_ram_write_en;
assign dram_wdat  = data_ram_write_data;
generate
  for(genvar data_ram_bank_id = 0; data_ram_bank_id < LLC_DATA_RAM_BANK_NUM; data_ram_bank_id++) begin: gen_dram_addr
    assign dram_addr[data_ram_bank_id]  = (|(dram_wen[data_ram_bank_id])) ? data_ram_write_idx[data_ram_bank_id] : 
                                                                            data_ram_read_idx [data_ram_bank_id];
  end
endgenerate


// data ram generate
generate
  for(genvar bank_id = 0; bank_id <  LLC_DATA_RAM_BANK_NUM; bank_id++) begin: gen_data_ram_bank
    for(genvar way_id = 0; way_id < LLC_WAY_NUM; way_id++) begin: gen_data_ram_way
      generic_spram
      #(
        .w(DATA_LINE_W),            // data width
        .p(DATA_LINE_W),            // word partition size (data bits per write enable)
        .d(LLC_PER_DATA_RAM_BANK_SET_NUM),              // data depth
        .log2d(LLC_PER_DATA_RAM_BANK_INDEX_WIDTH),  // address width
        .id(bank_id*LLC_WAY_NUM+way_id), // unique value per instance

        .RAM_LATENCY(1),
        .RESET      (1),
        .RESET_HIGH (0)
      )
      U_DATA_RAM
      (
        .clk   (clk_i),//clock
        .ce    (dram_cs  [bank_id][way_id]),  // chip enable,low active
        .we    (dram_wen [bank_id][way_id]),  // write enable,low active
        .addr  (dram_addr[bank_id][way_id]),  // address
        .din   (dram_wdat[bank_id][way_id]),  // data in
        .dout  (dram_rdat[bank_id][way_id]),  // data out
        .biten ('1)
      );
    end
  end
endgenerate

logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0] chosen_mshr_read_data_ram_way_valid_q;
logic [LLC_DATA_RAM_BANK_NUM-1:0][DATA_LINE_W-1:0] chosen_mshr_read_data_ram_dram_rdat;
generate
  for(genvar bank_id = 0; bank_id < LLC_DATA_RAM_BANK_NUM; bank_id++) begin: gen_chosen_mshr_read_data_ram_way_valid_q
    assign chosen_mshr_read_data_ram_way_valid_q[bank_id] =  repl_mshr_read_data_ram_valid_q[bank_id] ? repl_mshr_read_data_ram_way_valid_q[bank_id] :
                                                                                                        mshr_read_data_ram_way_valid_q[bank_id];
  end
endgenerate

generate
  for(genvar bank_id = 0; bank_id < LLC_DATA_RAM_BANK_NUM; bank_id++) begin: gen_mshr_read_data_ram_dram_rdat
    onehot_mux
    #(
      .SOURCE_COUNT(LLC_WAY_NUM ),
      .DATA_WIDTH  (DATA_LINE_W )
    )
    onehot_mux_mshr_read_data_ram_dram_rdat_u (
      .sel_i    (chosen_mshr_read_data_ram_way_valid_q[bank_id] ),
      .data_i   (dram_rdat[bank_id]                             ),
      .data_o   (chosen_mshr_read_data_ram_dram_rdat[bank_id]   )
    );
  end
endgenerate

assign mshr_read_data_ram_dram_rdat       = chosen_mshr_read_data_ram_dram_rdat;
assign repl_mshr_read_data_ram_dram_rdat  = chosen_mshr_read_data_ram_dram_rdat;


  // pipe reg
std_dffr #(.WIDTH(1)) U_STG_VALID_REG_S0 (.clk(clk_i),.rstn(rstn_i),.d(s0_valid_d),.q(s0_valid_q));
std_dffr #(.WIDTH(1)) U_STG_VALID_REG_S1 (.clk(clk_i),.rstn(rstn_i),.d(s1_valid_d),.q(s1_valid_q));
std_dffe #(.WIDTH($bits(scu_pipe_s0_t))) U_STG_DAT_REG_S0 (.clk(clk_i),.en(nxt_s0_ena),.d(nxt.s0),.q(cur.s0));
std_dffe #(.WIDTH($bits(scu_pipe_s1_t))) U_STG_DAT_REG_S1 (.clk(clk_i),.en(nxt_s1_ena),.d(nxt.s1),.q(cur.s1));



`ifndef SYNTHESIS

// miss rate counter
logic [64-1:0] ls_num_counter_d, ls_num_counter_q;
logic ls_num_counter_ena;
logic [64-1:0] miss_num_counter_d, miss_num_counter_q;
logic miss_num_counter_ena;

assign ls_num_counter_d     = ls_num_counter_q + 1;
assign miss_num_counter_d   = miss_num_counter_q + 1;

assign ls_num_counter_ena   = new_mshr_valid & 
                              ((new_mshr.req.rtype == ReadShared) |
                               (new_mshr.req.rtype == ReadOnce) |
                               (new_mshr.req.rtype == ReadUnique) |
                               (new_mshr.req.rtype == CleanUnique)
                              );
assign miss_num_counter_ena = ls_num_counter_ena &   
                              ~new_mshr.llc_hit &
                              ~new_mshr.dir_hit;

std_dffre
#(.WIDTH(64))
U_DAT_LS_NUM_COUNTER
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en(ls_num_counter_ena),
  .d(ls_num_counter_d),
  .q(ls_num_counter_q)
);

std_dffre
#(.WIDTH(64))
U_DAT_MISS_NUM_COUNTER
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en(miss_num_counter_ena),
  .d(miss_num_counter_d),
  .q(miss_num_counter_q)
);

real ls_num_counter;
real miss_num_counter;

final begin
  ls_num_counter    = ls_num_counter_q;
  miss_num_counter  = miss_num_counter_q;
  $display("LLC miss rate = (%d/%d) = %f", 
  miss_num_counter, ls_num_counter, miss_num_counter/ls_num_counter);
end


// scu per channel bandwidth
logic [64-1:0] cycle_num_counter_d, cycle_num_counter_q;
logic cycle_num_counter_ena;
// 5 channel: 0 req, 1 resp, 2 evict, 3 data, 4 snp; 2 direction: 0 in, 1 out
logic [5-1:0][2-1:0][64-1:0] channel_num_counter_d, channel_num_counter_q;
logic [5-1:0][2-1:0]         channel_num_counter_ena;

logic        [2-1:0][64-1:0] data_channel_byte_counter_d, data_channel_byte_counter_q;
logic        [2-1:0]         data_channel_byte_counter_ena;

logic        [64-1:0] data_channel_wb_num_counter_d, data_channel_wb_num_counter_q;
logic                 data_channel_wb_num_counter_ena;
logic        [64-1:0] data_channel_wb_byte_counter_d, data_channel_wb_byte_counter_q;
logic                 data_channel_wb_byte_counter_ena;

logic        [64-1:0] data_channel_snp_num_counter_d, data_channel_snp_num_counter_q;
logic                 data_channel_snp_num_counter_ena;
logic        [64-1:0] data_channel_snp_byte_counter_d, data_channel_snp_byte_counter_q;
logic                 data_channel_snp_byte_counter_ena;

logic        [64-1:0] data_channel_readunique_num_counter_d, data_channel_readunique_num_counter_q;
logic                 data_channel_readunique_num_counter_ena;
logic        [64-1:0] data_channel_readunique_byte_counter_d, data_channel_readunique_byte_counter_q;
logic                 data_channel_readunique_byte_counter_ena;


logic [DATA_BURST_NUM_W:0] pc_scu_data_i_data_valid_num;
logic [DATA_BURST_NUM_W:0] scu_pc_data_o_data_valid_num;

one_counter
#(
  .DATA_WIDTH(DATA_BURST_NUM)
)
data_channel_byte_counter_in_u
(
  .data_i(pc_scu_data_i.data_valid),
  .cnt_o (pc_scu_data_i_data_valid_num)
);

one_counter
#(
  .DATA_WIDTH(DATA_BURST_NUM)
)
data_channel_byte_counter_out_u
(
  .data_i(scu_pc_data_o.data_valid),
  .cnt_o (scu_pc_data_o_data_valid_num)
);

// ena
assign cycle_num_counter_ena   = '1;

assign channel_num_counter_ena[0][0] = pc_scu_req_vld_i & pc_scu_req_rdy_o;
assign channel_num_counter_ena[0][1] = '0;
assign channel_num_counter_ena[1][0] = pc_scu_resp_vld_i & pc_scu_resp_rdy_o;
assign channel_num_counter_ena[1][1] = scu_pc_resp_vld_o & scu_pc_resp_rdy_i;
assign channel_num_counter_ena[2][0] = pc_scu_evict_vld_i & pc_scu_evict_rdy_o;
assign channel_num_counter_ena[2][1] = '0;
assign channel_num_counter_ena[3][0] = pc_scu_data_vld_i & pc_scu_data_rdy_o;
assign channel_num_counter_ena[3][1] = scu_pc_data_vld_o & scu_pc_data_rdy_i;
assign channel_num_counter_ena[4][0] = '0;
assign channel_num_counter_ena[4][1] = scu_pc_snp_vld_o & scu_pc_snp_rdy_i;

assign data_channel_byte_counter_ena[0] = channel_num_counter_ena[3][0];
assign data_channel_byte_counter_ena[1] = channel_num_counter_ena[3][1];


assign data_channel_wb_num_counter_ena          = channel_num_counter_ena[3][0] & ((pc_scu_data_i.rtype == WriteBackFullData) | (pc_scu_data_i.rtype == WriteBackPartialData));
assign data_channel_snp_num_counter_ena         = channel_num_counter_ena[3][0] & ((pc_scu_data_i.rtype == SnpAck_FoundM));
assign data_channel_readunique_num_counter_ena  = channel_num_counter_ena[3][1] & ((scu_pc_data_o.rtype == CompData_UD));

assign data_channel_wb_byte_counter_ena         = data_channel_wb_num_counter_ena;
assign data_channel_snp_byte_counter_ena        = data_channel_snp_num_counter_ena;
assign data_channel_readunique_byte_counter_ena = data_channel_readunique_num_counter_ena;

// d
assign cycle_num_counter_d     = cycle_num_counter_q + 1;

generate
  for(genvar i = 0; i < 5; i++) begin
    for(genvar j = 0; j < 2; j++) begin
      assign channel_num_counter_d[i][j] = channel_num_counter_q[i][j] + 1;
    end
  end
endgenerate

assign data_channel_byte_counter_d[0] = data_channel_byte_counter_q[0] + pc_scu_data_i_data_valid_num * DATA_LENGTH_PER_PKG / 8;
assign data_channel_byte_counter_d[1] = data_channel_byte_counter_q[1] + scu_pc_data_o_data_valid_num * DATA_LENGTH_PER_PKG / 8;

assign data_channel_wb_num_counter_d            = data_channel_wb_num_counter_q + 1;
assign data_channel_snp_num_counter_d           = data_channel_snp_num_counter_q + 1;
assign data_channel_readunique_num_counter_d    = data_channel_readunique_num_counter_q + 1;

assign data_channel_wb_byte_counter_d           = data_channel_wb_byte_counter_q  + pc_scu_data_i_data_valid_num * DATA_LENGTH_PER_PKG / 8;
assign data_channel_snp_byte_counter_d          = data_channel_snp_byte_counter_q + pc_scu_data_i_data_valid_num * DATA_LENGTH_PER_PKG / 8;
assign data_channel_readunique_byte_counter_d   = data_channel_readunique_byte_counter_q + scu_pc_data_o_data_valid_num * DATA_LENGTH_PER_PKG / 8; 

// dff
generate
  for(genvar i = 0; i < 5; i++) begin: gen_channel_num_counter_q
    for(genvar j = 0; j < 2; j++) begin
      std_dffre
      #(.WIDTH(64))
      U_DAT_CHANNEL_NUM_COUNTER
      (
        .clk(clk_i),
        .rstn(rstn_i),
        .en (channel_num_counter_ena[i][j]),
        .d  (channel_num_counter_d  [i][j]),
        .q  (channel_num_counter_q  [i][j])
      );
    end
  end
endgenerate

generate
  for(genvar j = 0; j < 2; j++) begin: gen_data_channel_byte_counter_q
    std_dffre
    #(.WIDTH(64))
    U_DAT_DATA_CHANNEL_BYTE_COUNTER
    (
      .clk(clk_i),
      .rstn(rstn_i),
      .en (data_channel_byte_counter_ena[j]),
      .d  (data_channel_byte_counter_d  [j]),
      .q  (data_channel_byte_counter_q  [j])
    );
  end
endgenerate



std_dffre
#(.WIDTH(64))
U_DAT_DATA_CHANNEL_WB_NUM_COUNTER
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en (data_channel_wb_num_counter_ena   ),
  .d  (data_channel_wb_num_counter_d     ),
  .q  (data_channel_wb_num_counter_q     )
);

std_dffre
#(.WIDTH(64))
U_DAT_DATA_CHANNEL_SNP_NUM_COUNTER
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en (data_channel_snp_num_counter_ena   ),
  .d  (data_channel_snp_num_counter_d     ),
  .q  (data_channel_snp_num_counter_q     )
);

std_dffre
#(.WIDTH(64))
U_DAT_DATA_CHANNEL_READUNIQUE_NUM_COUNTER
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en (data_channel_readunique_num_counter_ena   ),
  .d  (data_channel_readunique_num_counter_d     ),
  .q  (data_channel_readunique_num_counter_q     )
);

std_dffre
#(.WIDTH(64))
U_DAT_DATA_CHANNEL_WB_BYTE_COUNTER
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en (data_channel_wb_byte_counter_ena   ),
  .d  (data_channel_wb_byte_counter_d     ),
  .q  (data_channel_wb_byte_counter_q     )
);

std_dffre
#(.WIDTH(64))
U_DAT_DATA_CHANNEL_SNP_BYTE_COUNTER
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en (data_channel_snp_byte_counter_ena   ),
  .d  (data_channel_snp_byte_counter_d     ),
  .q  (data_channel_snp_byte_counter_q     )
);

std_dffre
#(.WIDTH(64))
U_DAT_DATA_CHANNEL_READUNIQUE_BYTE_COUNTER
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en (data_channel_readunique_byte_counter_ena   ),
  .d  (data_channel_readunique_byte_counter_d     ),
  .q  (data_channel_readunique_byte_counter_q     )
);




std_dffre
#(.WIDTH(64))
U_DAT_CYCLE_NUM_COUNTER
(
  .clk(clk_i),
  .rstn(rstn_i),
  .en(cycle_num_counter_ena),
  .d(cycle_num_counter_d),
  .q(cycle_num_counter_q)
);




real ls_num_counter_mid;
real miss_num_counter_mid;

real  cycle_num_counter_mid;
real  channel_num_counter_mid[5-1:0][2-1:0];
real  data_channel_byte_counter_mid[2-1:0];

real data_channel_wb_num_counter_mid;
real data_channel_wb_byte_counter_mid;
real data_channel_snp_num_counter_mid;
real data_channel_snp_byte_counter_mid;
real data_channel_readunique_num_counter_mid;
real data_channel_readunique_byte_counter_mid;

always_ff @(posedge clk_i) begin
  if(cycle_num_counter_q[19:0] == 'h1) begin
  // if(channel_num_counter_q[0][0][17:0] == 'h1) begin
    
    ls_num_counter_mid    = ls_num_counter_q;
    miss_num_counter_mid  = miss_num_counter_q;
    $display("LLC miss rate = (%d/%d) = %f", 
    miss_num_counter_mid, ls_num_counter_mid, miss_num_counter_mid/ls_num_counter_mid);

    cycle_num_counter_mid    = cycle_num_counter_q;
    $display("SCU cycle_num_counter = %d", cycle_num_counter_mid);
    $display("SCU 5 channel: 0 req, 1 resp, 2 evict, 3 data, 4 snp; 2 direction: 0 in, 1 out");
    for(int j = 0; j < 2; j++) begin
      channel_num_counter_mid[0][j] = channel_num_counter_q[0][j];
      $display("[req  ][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
                j, channel_num_counter_mid[0][j], channel_num_counter_mid[0][j]*$bits(cache_scu_cc_req_t)/8);
    end
    for(int j = 0; j < 2; j++) begin
      channel_num_counter_mid[1][j] = channel_num_counter_q[1][j];
      $display("[resp ][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
                j, channel_num_counter_mid[1][j], channel_num_counter_mid[1][j]*$bits(cache_scu_cc_resp_t)/8);
    end
    for(int j = 0; j < 2; j++) begin
      channel_num_counter_mid[2][j] = channel_num_counter_q[2][j];
      $display("[evict][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
                j, channel_num_counter_mid[2][j], channel_num_counter_mid[2][j]*$bits(cache_scu_cc_req_t)/8);
    end
    for(int j = 0; j < 2; j++) begin
      channel_num_counter_mid   [3][j] = channel_num_counter_q[3][j];
      data_channel_byte_counter_mid[j] = data_channel_byte_counter_q[j];
      $display("[data ][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
                j, channel_num_counter_mid[3][j], data_channel_byte_counter_mid[j]);
    end
    for(int j = 0; j < 2; j++) begin
      channel_num_counter_mid[4][j] = channel_num_counter_q[4][j];
      $display("[snp  ][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
                j, channel_num_counter_mid[4][j], channel_num_counter_mid[4][j]*$bits(cache_scu_cc_snp_t)/8);
    end

    data_channel_wb_num_counter_mid           = data_channel_wb_num_counter_q;
    data_channel_wb_byte_counter_mid          = data_channel_wb_byte_counter_q;
    data_channel_snp_num_counter_mid          = data_channel_snp_num_counter_q;
    data_channel_snp_byte_counter_mid         = data_channel_snp_byte_counter_q;
    data_channel_readunique_num_counter_mid   = data_channel_readunique_num_counter_q;
    data_channel_readunique_byte_counter_mid = data_channel_readunique_byte_counter_q;

    $display("======\n");
    $display("[data in  (wb)        ]SCU channel_num_counter = %8d, channel_byte_counter = %8d, reduce=%f%%", 
          data_channel_wb_num_counter_mid, data_channel_wb_byte_counter_mid, 
          (((data_channel_wb_num_counter_mid*DATA_BURST_NUM*DATA_LENGTH_PER_PKG/8)-(data_channel_wb_byte_counter_mid))/(data_channel_wb_num_counter_mid*DATA_BURST_NUM*DATA_LENGTH_PER_PKG/8))*100
          );
    $display("[data in  (snp)       ]SCU channel_num_counter = %8d, channel_byte_counter = %8d, reduce=%f%%", 
      data_channel_snp_num_counter_mid, data_channel_snp_byte_counter_mid, 
      (((data_channel_snp_num_counter_mid*DATA_BURST_NUM*DATA_LENGTH_PER_PKG/8)-(data_channel_snp_byte_counter_mid))/(data_channel_snp_num_counter_mid*DATA_BURST_NUM*DATA_LENGTH_PER_PKG/8))*100
      );
    $display("[data out (readunique)]SCU channel_num_counter = %8d, channel_byte_counter = %8d, reduce=%f%%", 
      data_channel_readunique_num_counter_mid, data_channel_readunique_byte_counter_mid, 
      (((data_channel_readunique_num_counter_mid*DATA_BURST_NUM*DATA_LENGTH_PER_PKG/8)-(data_channel_readunique_byte_counter_mid))/(data_channel_readunique_num_counter_mid*DATA_BURST_NUM*DATA_LENGTH_PER_PKG/8))*100
      );
    $display("======\n");
  end
end

real  cycle_num_counter;
real  channel_num_counter[5-1:0][2-1:0];
real  data_channel_byte_counter[2-1:0];

final begin
  cycle_num_counter    = cycle_num_counter_q;
  $display("SCU cycle_num_counter = %d", cycle_num_counter);
  $display("SCU 5 channel: 0 req, 1 resp, 2 evict, 3 data, 4 snp; 2 direction: 0 in, 1 out");
  for(int j = 0; j < 2; j++) begin
    channel_num_counter[0][j] = channel_num_counter_q[0][j];
    $display("[req  ][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
              j, channel_num_counter[0][j], channel_num_counter[0][j]*$bits(cache_scu_cc_req_t)/8);
  end
  for(int j = 0; j < 2; j++) begin
    channel_num_counter[1][j] = channel_num_counter_q[1][j];
    $display("[resp ][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
              j, channel_num_counter[1][j], channel_num_counter[1][j]*$bits(cache_scu_cc_resp_t)/8);
  end
  for(int j = 0; j < 2; j++) begin
    channel_num_counter[2][j] = channel_num_counter_q[2][j];
    $display("[evict][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
              j, channel_num_counter[2][j], channel_num_counter[2][j]*$bits(cache_scu_cc_req_t)/8);
  end
  for(int j = 0; j < 2; j++) begin
    channel_num_counter   [3][j] = channel_num_counter_q[3][j];
    data_channel_byte_counter[j] = data_channel_byte_counter_q[j];
    $display("[data ][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
              j, channel_num_counter[3][j], data_channel_byte_counter[j]);
  end
  for(int j = 0; j < 2; j++) begin
    channel_num_counter[4][j] = channel_num_counter_q[4][j];
    $display("[snp  ][%1d]SCU channel_num_counter = %8d, channel_byte_counter = %8d", 
              j, channel_num_counter[4][j], channel_num_counter[4][j]*$bits(cache_scu_cc_snp_t)/8);
  end

  // for(int j = 0; j < 2; j++) begin
  //   data_channel_byte_counter[j] = data_channel_byte_counter_q[j];
  //   $display("SCU data_channel_byte_counter[%1d] = %8d, BW for 1GHz = %f GBps (2 direction: 0 in, 1 out)", 
  //         j, data_channel_byte_counter[j], data_channel_byte_counter[j]/cycle_num_counter);
  // end
end

`endif

endmodule
