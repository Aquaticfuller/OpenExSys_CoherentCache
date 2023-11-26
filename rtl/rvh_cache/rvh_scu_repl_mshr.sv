module rvh_scu_repl_mshr
  import rvh_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_noc_pkg::*;
  import rvh_uncore_param_pkg::*;
#(
  parameter int MSHR_NUM      = 8,
  parameter int MSHR_NUM_W    = $clog2(MSHR_NUM) > 0 ? $clog2(MSHR_NUM) : 1
)
(
  // new mshr
  input  logic                              new_mshr_valid_i,
  input  logic [LLC_DATA_RAM_BANK_NUM-1:0]  new_mshr_enqueue_req_to_read_data_ram_fifo_i,
  input  logic                              new_mshr_enqueue_snp_to_cache_fifo_i,
  input  scu_repl_mshr_t                    new_mshr_i,
  input  [MSHR_NUM_W-1:0]                   new_mshr_id_i,

  // mshr_q and mshr_valid_q output
  output scu_repl_mshr_t [MSHR_NUM-1:0]            mshr_q_o,
  output logic      [MSHR_NUM-1:0]                 mshr_valid_q_o,

  // scu -> cache, snp intf
  output logic                              scu_pc_snp_vld_o,
  output cache_scu_cc_snp_t                 scu_pc_snp_o,
  input  logic                              scu_pc_snp_rdy_i,

  // scu -> cache, resp intf
  output logic                              scu_pc_resp_vld_o,
  output cache_scu_cc_resp_t                scu_pc_resp_o,
  input  logic                              scu_pc_resp_rdy_i,

  // cache -> scu, resp intf
  input  logic                              pc_scu_resp_vld_i,
  input  cache_scu_cc_resp_t                pc_scu_resp_i,
  output logic                              pc_scu_resp_rdy_o,

  // cache -> scu, evict/wb
  input  logic                              pc_scu_evict_vld_i,
  input  cache_scu_cc_req_t                 pc_scu_evict_i,
  input  logic [MSHR_NUM_W-1:0]             pc_scu_evict_mshr_id_i,
  output logic                              pc_scu_evict_rdy_o,

  // cache -> scu, data intf
  input  logic                              pc_scu_data_vld_i,
  input  cache_scu_cc_data_t                pc_scu_data_i,
  output logic                              pc_scu_data_rdy_o,

  // data ram intf
    // read req out
  output logic [LLC_DATA_RAM_BANK_NUM-1:0]                             mshr_read_data_ram_valid_o,
  output logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]            mshr_read_data_ram_way_valid_o,
  output logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] mshr_read_data_ram_idx_o,
  input  logic [LLC_DATA_RAM_BANK_NUM-1:0]                             mshr_read_data_ram_ready_i,
    // read data in
  output logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]            mshr_read_data_ram_way_valid_q_o,
  output logic [LLC_DATA_RAM_BANK_NUM-1:0]                             mshr_read_data_ram_valid_q_o,
  input  logic [LLC_DATA_RAM_BANK_NUM-1:0][DATA_LINE_W-1:0]            mshr_read_data_ram_dram_rdat_i,

  // tag ram intf
    // write req out
  output logic [LLC_TAG_RAM_BANK_NUM-1:0]                              mshr_write_tag_ram_valid_o,
  output logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]             mshr_write_tag_ram_way_valid_o,
  output logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] mshr_write_tag_ram_idx_o,
  output scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0]          mshr_write_tag_ram_dram_wdat_o,
  input  logic [LLC_TAG_RAM_BANK_NUM-1:0]                              mshr_write_tag_ram_ready_i,

  // mem intf
    // AW 
  output logic              mem_if_awvalid_o,
  input  logic              mem_if_awready_i,
  output cache_mem_if_aw_t  mem_if_aw_o,
    // W 
  output logic              mem_if_wvalid_o,
  input  logic              mem_if_wready_i,
  output cache_mem_if_w_t   mem_if_w_o,
    // B
  input  logic              mem_if_bvalid_i,
  output logic              mem_if_bready_o,
  input  cache_mem_if_b_t   mem_if_b_i,

  // else
  input  logic                clk_i,
  input  logic                rstn_i
);

// mshr reg
scu_repl_mshr_t     [MSHR_NUM-1:0]   mshr_q, mshr_d;
scu_repl_mshr_ena_t [MSHR_NUM-1:0]   mshr_ena;
// mshr valid
logic      [MSHR_NUM-1:0]   mshr_valid_d, mshr_valid_q;
logic      [MSHR_NUM-1:0]   mshr_valid_d_set, mshr_valid_d_clr;
logic      [MSHR_NUM-1:0]   mshr_valid_ena;

// fifo signals
  // req_to_write_mem_fifo
logic                   req_to_write_mem_fifo_we;
logic [MSHR_NUM_W-1:0]  req_to_write_mem_fifo_din;
  // req_to_read_data_ram_fifo
logic [LLC_DATA_RAM_BANK_NUM-1:0]                  req_to_read_data_ram_fifo_we;
logic [LLC_DATA_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0]  req_to_read_data_ram_fifo_din;
  // snp_to_cache_fifo
logic                   snp_to_cache_fifo_we;
logic [MSHR_NUM_W-1:0]  snp_to_cache_fifo_din;
  // resp_to_requestor_fifo
logic                   resp_to_requestor_fifo_we;
logic [MSHR_NUM_W-1:0]  resp_to_requestor_fifo_din;
  // req_to_write_tag_ram_fifo
logic [LLC_TAG_RAM_BANK_NUM-1:0]                   req_to_write_tag_ram_fifo_we;
logic [LLC_TAG_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0]   req_to_write_tag_ram_fifo_din;

assign mshr_q_o = mshr_q;
assign mshr_valid_q_o = mshr_valid_q;

// ---------------
// mshr_q dealloc judge
// ---------------
logic [MSHR_NUM-1:0] mshr_transition_action_finished; // when this is set, means the final data writeback can start
logic [MSHR_NUM-1:0] mshr_writeback_action_finished; // when this is set, means the tag, dir, state update can start
logic [MSHR_NUM-1:0] mshr_final_action_finished; // when this is set, means the transaction is finished, the mshr can be deallocated
generate
  for(genvar mshr_id = 0; mshr_id < MSHR_NUM; mshr_id++) begin
    assign mshr_transition_action_finished[mshr_id] =
                                    // it is a valid mshr
                                    mshr_valid_q[mshr_id] &
                                    // all wait done
                                    ~mshr_q[mshr_id].wait_for_wb_data_en &
                                    ~mshr_q[mshr_id].wait_for_llc_read_data_en &
                                    // all snp sent
                                      // ~mshr_q[mshr_id].need_invalid_snp &
                                    (mshr_q[mshr_id].snp_need_to_send_list == mshr_q[mshr_id].snp_sent_list) &
                                    // all snp / evict / wb resp or data received
                                    (mshr_q[mshr_id].snp_sent_list == (mshr_q[mshr_id].snp_resp_receiving_list | mshr_q[mshr_id].snp_data_receiving_list)) & // all snp received
                                    (
                                      (mshr_q[mshr_id].snp_resp_receiving_invalid_list == (mshr_q[mshr_id].evict_resp_receiving_list & mshr_q[mshr_id].snp_resp_receiving_invalid_list)) | // all evict received (may get unexpected evict, they need to be handled but not required), or
                                      mshr_q[mshr_id].writeback_data_received                                              // the writeback received
                                    );

    assign mshr_writeback_action_finished[mshr_id] = 
                                    // it is a valid mshr
                                    mshr_valid_q[mshr_id] &
                                    // mshr_transition_action_finished
                                    mshr_transition_action_finished[mshr_id] &
                                    // dirty writeback to mem has done or no need
                                    mshr_q[mshr_id].dirty_writeback_mem_done;

    assign mshr_final_action_finished[mshr_id] = 
                                    // it is a valid mshr
                                    mshr_valid_q[mshr_id] &
                                    // mshr_writeback_action_finished
                                    mshr_writeback_action_finished[mshr_id] &
                                    // all tag / dir update done
                                    ~mshr_q[mshr_id].need_to_update_tag &
                                    ~mshr_q[mshr_id].need_to_update_dir;

  end
endgenerate


// ---------------
// fifo enqueue
// ---------------
logic                   mshr_at_writeback_stage_valid;
logic [MSHR_NUM_W-1:0]  mshr_at_writeback_stage_id;
logic                   mshr_at_writeback_stage_enqueue_valid;

logic                   mshr_at_final_write_stage_valid;
logic [MSHR_NUM_W-1:0]  mshr_at_final_write_stage_id;
logic                   mshr_at_write_tag_ram_stage_enqueue_valid;
logic                   mshr_at_write_state_dir_reg_stage_enqueue_valid;

always_comb begin
  req_to_write_mem_fifo_we        = '0;
  req_to_write_mem_fifo_din       = '0;
  req_to_read_data_ram_fifo_we    = '0;
  req_to_read_data_ram_fifo_din   = '0;
  snp_to_cache_fifo_we            = '0;
  snp_to_cache_fifo_din           = '0;
  resp_to_requestor_fifo_we       = '0;
  resp_to_requestor_fifo_din      = '0;
  req_to_write_tag_ram_fifo_we    = '0;
  req_to_write_tag_ram_fifo_din   = '0;

  // new_mshr
  if(new_mshr_valid_i) begin
    for(int i = 0; i < LLC_DATA_RAM_BANK_NUM; i++) begin
      req_to_read_data_ram_fifo_we [i] = new_mshr_enqueue_req_to_read_data_ram_fifo_i[i];
      req_to_read_data_ram_fifo_din[i] = new_mshr_id_i;
    end

    snp_to_cache_fifo_we          = new_mshr_enqueue_snp_to_cache_fifo_i;
    snp_to_cache_fifo_din         = new_mshr_id_i;
  end

  // writeback from private cache, hit in mshr, then send ack to privact cache to gt wb data
  if(pc_scu_evict_vld_i) begin
    unique case(pc_scu_evict_i.rtype)
      WriteBackFull,
      WriteBackPartial: begin
        resp_to_requestor_fifo_we  = 1'b1;
        resp_to_requestor_fifo_din = pc_scu_evict_mshr_id_i;
      end
      default: begin
      end
    endcase
  end

  // final writeback dirty data to mem
  if(mshr_at_writeback_stage_enqueue_valid) begin
    req_to_write_mem_fifo_we  = |(mshr_q[mshr_at_writeback_stage_id].data_valid & mshr_q[mshr_at_writeback_stage_id].data_dirty);
    req_to_write_mem_fifo_din = mshr_at_writeback_stage_id;
  end

  // final tag_dir_state ram write
  if(mshr_at_write_tag_ram_stage_enqueue_valid | mshr_at_write_state_dir_reg_stage_enqueue_valid) begin
`ifdef LLC_TAG_RAM_MULTI_BANK
    req_to_write_tag_ram_fifo_we  [mshr_q[mshr_at_final_write_stage_id].addr[LLC_OFFSET_WIDTH+:$clog2(LLC_TAG_RAM_BANK_NUM)]] = 1'b1;
    req_to_write_tag_ram_fifo_din [mshr_q[mshr_at_final_write_stage_id].addr[LLC_OFFSET_WIDTH+:$clog2(LLC_TAG_RAM_BANK_NUM)]] = mshr_at_final_write_stage_id;
`else
    req_to_write_tag_ram_fifo_we [0] = 1'b1;
    req_to_write_tag_ram_fifo_din[0] = mshr_at_final_write_stage_id;
`endif
  end
end

assign mshr_at_writeback_stage_enqueue_valid = mshr_at_writeback_stage_valid &
                                          ~mshr_q[mshr_at_writeback_stage_id].dirty_writeback_mem_enqueued;

assign mshr_at_write_tag_ram_stage_enqueue_valid = mshr_at_final_write_stage_valid &
                                                   mshr_q[mshr_at_final_write_stage_id].need_to_update_tag &
                                                   ~mshr_q[mshr_at_final_write_stage_id].final_update_enqueued;

assign mshr_at_write_state_dir_reg_stage_enqueue_valid = mshr_at_final_write_stage_valid &
                                                         mshr_q[mshr_at_final_write_stage_id].need_to_update_dir &
                                                         ~mshr_q[mshr_at_final_write_stage_id].final_update_enqueued;

priority_encoder
#(
  .SEL_WIDTH(MSHR_NUM)
)
mshr_at_writeback_stage_enqueue_mshr_id_sel
(
  .sel_i      (mshr_transition_action_finished & ~mshr_writeback_action_finished ),
  .id_vld_o   (mshr_at_writeback_stage_valid         ),
  .id_o       (mshr_at_writeback_stage_id            )
);

priority_encoder
#(
  .SEL_WIDTH(MSHR_NUM)
)
mshr_at_final_write_stage_enqueue_mshr_id_sel
(
  .sel_i      (mshr_writeback_action_finished & ~mshr_final_action_finished ),
  .id_vld_o   (mshr_at_final_write_stage_valid         ),
  .id_o       (mshr_at_final_write_stage_id            )
);



// ---------------
// snp_to_cache_fifo
// ---------------
logic                   snp_to_cache_fifo_dout_vld;
logic [MSHR_NUM_W-1:0]  snp_to_cache_fifo_dout;
logic                   snp_to_cache_fifo_re;
logic                   scu_pc_snp_vld_hsk;
logic                           snp_need_to_send_list_sel_vld;
logic [PRIVATE_CACHE_NUM_W-1:0] snp_need_to_send_list_sel_idx;

assign snp_to_cache_fifo_re = snp_to_cache_fifo_dout_vld & ~snp_need_to_send_list_sel_vld;

mp_fifo
#(
  .payload_t          (logic[MSHR_NUM_W-1:0]  ),
  .ENQUEUE_WIDTH      (1                      ),
  .DEQUEUE_WIDTH      (1                      ),
  .DEPTH              (MSHR_NUM               ),
  .MUST_TAKEN_ALL     (1                      )
)
snp_to_cache_fifo_u
(
  // Enqueue
  .enqueue_vld_i          (snp_to_cache_fifo_we         ),
  .enqueue_payload_i      (snp_to_cache_fifo_din        ),
  .enqueue_rdy_o          (                                 ),
  // Dequeue
  .dequeue_vld_o          (snp_to_cache_fifo_dout_vld   ),
  .dequeue_payload_o      (snp_to_cache_fifo_dout       ),
  .dequeue_rdy_i          (snp_to_cache_fifo_re         ),
  
  .flush_i                (1'b0                             ),
  
  .clk                    (clk_i                            ),
  .rst                    (~rstn_i                          )
);

priority_encoder
#(
  .SEL_WIDTH(PRIVATE_CACHE_NUM)
)
scu_mshr_evict_mshr_id_sel
(
  .sel_i      (mshr_q[snp_to_cache_fifo_dout].snp_need_to_send_list & ~mshr_q[snp_to_cache_fifo_dout].snp_sent_list ),
  .id_vld_o   (snp_need_to_send_list_sel_vld  ),
  .id_o       (snp_need_to_send_list_sel_idx  )
);

assign scu_pc_snp_vld_o        = snp_to_cache_fifo_dout_vld & snp_need_to_send_list_sel_vld;
// assign scu_pc_snp_o.send_list  = mshr_q[snp_to_cache_fifo_dout].snp_need_to_send_list;
assign scu_pc_snp_o.id.scu_tid = {1'b1, (SCU_TID_W-1)'(snp_to_cache_fifo_dout)};
assign scu_pc_snp_o.id.cid     = snp_need_to_send_list_sel_idx;
assign scu_pc_snp_o.rtype      = mshr_q[snp_to_cache_fifo_dout].need_invalid_snp ? SnpUnique
                                                                                 : SnpShared;
assign scu_pc_snp_o.addr       = mshr_q[snp_to_cache_fifo_dout].addr;

assign scu_pc_snp_o.src_id     = '0;
assign scu_pc_snp_o.tgt_id     = '0;
`ifdef ENABLE_TXN_ID
assign scu_pc_snp_o.txn_id     = TxnID_Width'(scu_pc_snp_o.id);
`endif

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
assign scu_pc_snp_o.data_resp_with_critical_word_first = '0; // for repl mshr, no need critical word first snp data resp
`endif

`ifdef USE_QOS_VALUE
assign scu_pc_snp_o.qos_value  = '0;
`endif

assign scu_pc_snp_vld_hsk      = scu_pc_snp_vld_o & scu_pc_snp_rdy_i;


// ---------------
// req_to_write_mem_fifo
// ---------------
// aw
logic                   req_to_write_mem_fifo_aw_dout_vld;
logic [MSHR_NUM_W-1:0]  req_to_write_mem_fifo_aw_dout;
logic                   req_to_write_mem_fifo_aw_re;
logic                   req_to_write_mem_fifo_aw_re_ff;

assign req_to_write_mem_fifo_aw_re = mem_if_awvalid_o & mem_if_awready_i;

mp_fifo
#(
  .payload_t          (logic[MSHR_NUM_W-1:0]  ),
  .ENQUEUE_WIDTH      (1                      ),
  .DEQUEUE_WIDTH      (1                      ),
  .DEPTH              (MSHR_NUM               ),
  .MUST_TAKEN_ALL     (1                      )
)
req_to_write_mem_fifo_aw_u
(
  // Enqueue
  .enqueue_vld_i          (req_to_write_mem_fifo_we          ),
  .enqueue_payload_i      (req_to_write_mem_fifo_din         ),
  .enqueue_rdy_o          (                                 ),
  // Dequeue
  .dequeue_vld_o          (req_to_write_mem_fifo_aw_dout_vld    ),
  .dequeue_payload_o      (req_to_write_mem_fifo_aw_dout        ),
  .dequeue_rdy_i          (req_to_write_mem_fifo_aw_re          ),
  
  .flush_i                (1'b0                             ),
  
  .clk                    (clk_i                            ),
  .rst                    (~rstn_i                          )
);

assign mem_if_awvalid_o     = req_to_write_mem_fifo_aw_dout_vld & ~req_to_write_mem_fifo_aw_re_ff;
assign mem_if_aw_o.awid.tid = req_to_write_mem_fifo_aw_dout;
assign mem_if_aw_o.awid.bid = '0;
assign mem_if_aw_o.awaddr   = {mshr_q[req_to_write_mem_fifo_aw_dout].addr[PADDR_WIDTH-1:LLC_OFFSET_WIDTH], {LLC_OFFSET_WIDTH{1'b0}}};
assign mem_if_aw_o.awlen    = BURST_SIZE-1;// read a full burst from memory(2'b11)
assign mem_if_aw_o.awsize   = AXI_SIZE;
assign mem_if_aw_o.awburst  = 2'b01; // INCR mode


// w
logic                   req_to_write_mem_fifo_w_dout_vld;
logic [MSHR_NUM_W-1:0]  req_to_write_mem_fifo_w_dout;
logic                   req_to_write_mem_fifo_w_re;
logic                   req_to_write_mem_fifo_w_re_ff;

assign req_to_write_mem_fifo_w_re  = (~mem_req_ff.wvalid | mem_if_w_o.wlast) & mem_if_wvalid_o & mem_if_wready_i; 

mp_fifo
#(
  .payload_t          (logic[MSHR_NUM_W-1:0]  ),
  .ENQUEUE_WIDTH      (1                      ),
  .DEQUEUE_WIDTH      (1                      ),
  .DEPTH              (MSHR_NUM               ),
  .MUST_TAKEN_ALL     (1                      )
)
req_to_write_mem_fifo_w_u
(
  // Enqueue
  .enqueue_vld_i          (req_to_write_mem_fifo_we          ),
  .enqueue_payload_i      (req_to_write_mem_fifo_din         ),
  .enqueue_rdy_o          (                                 ),
  // Dequeue
  .dequeue_vld_o          (req_to_write_mem_fifo_w_dout_vld    ),
  .dequeue_payload_o      (req_to_write_mem_fifo_w_dout        ),
  .dequeue_rdy_i          (req_to_write_mem_fifo_w_re          ),
  
  .flush_i                (1'b0                             ),
  
  .clk                    (clk_i                            ),
  .rst                    (~rstn_i                          )
);

  // W 
mem_fsm_reg_t     mem_req_ff, mem_req_nxt;
logic             wlast_ff;

// wvalid
assign  mem_if_wvalid_o = mem_req_ff.wvalid & mem_req_nxt.wvalid & ~req_to_write_mem_fifo_w_re_ff;
// mshr_bank[w_fifo_dout]'s old tag[16:15], which is cc_tag_pway[replace_way_id][19:18] + allocated mshr entry ID
assign  mem_if_w_o.wid.tid     = '1;
assign  mem_if_w_o.wid.bid     = '0;
// send 512-bit data over 8 cycles
assign  mem_if_w_o.wdata = mshr_q[req_to_write_mem_fifo_w_dout].data[mem_req_ff.wdata_offset];
assign  mem_if_w_o.wlast = &mem_req_ff.wdata_offset;



// Pipe valid for write back data pipe. Valid asserted for following cases.
// first or after last burst 
// no new transactions, w_fifo_empty happends after w_fifo_re which is the last mem_if_wready_i
// mshr_w => mshr_bank[w_fifo_dout]
// way_id    => replace_way_id at s2
always_comb begin
  mem_req_nxt.wvalid = ~req_to_write_mem_fifo_w_dout_vld                           ? 1'b0 : 
                                  (~mem_req_ff.wvalid | wlast_ff) & req_to_write_mem_fifo_w_dout_vld  ? 1'b1 :
                                                                                                mem_req_ff.wvalid;
end
// Counter to indicate how many chunk of write back data is accepted. Updates it for
// 1. W channel handshake completed, reset the offset
// 2. Handshake completed and write data pipe is valid and not prceed to next mem write, increment offset  
always_comb begin
  mem_req_nxt.wdata_offset = ((~mem_req_ff.wvalid | mem_if_w_o.wlast) & mem_if_wready_i) ? '0      :
                              (mem_if_wready_i & mem_req_ff.wvalid & ~req_to_write_mem_fifo_w_re_ff)       ?  mem_req_ff.wdata_offset + 1  :
                                                                                              mem_req_ff.wdata_offset;
end

// write data state machine
always_ff @ (posedge clk_i) begin
  wlast_ff <= mem_if_wvalid_o & mem_if_w_o.wlast & mem_if_wready_i;
end

always_ff @ (posedge clk_i) begin
  if (~rstn_i) begin
    mem_req_ff.wvalid <= '0;
    // mem_req_ff.waddr <= '0;
    mem_req_ff.wdata_offset <= '0;
    // mem_req_ff.rdata_pipe_valid <='0;

  end else begin
    mem_req_ff   <= mem_req_nxt;

  end

  req_to_write_mem_fifo_aw_re_ff <= req_to_write_mem_fifo_aw_re;
    req_to_write_mem_fifo_w_re_ff  <= req_to_write_mem_fifo_w_re;
end

// ---------------
// req_to_read_data_ram_fifo
// ---------------
logic [LLC_DATA_RAM_BANK_NUM-1:0]                 req_to_read_data_ram_fifo_dout_vld;
logic [LLC_DATA_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0] req_to_read_data_ram_fifo_dout;
logic [LLC_DATA_RAM_BANK_NUM-1:0]                 req_to_read_data_ram_fifo_re;

logic [LLC_DATA_RAM_BANK_NUM-1:0]                 read_data_ram_s0_valid_d, read_data_ram_s0_valid_q;
logic [LLC_DATA_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0] read_data_ram_s0_mshr_id_d, read_data_ram_s0_mshr_id_q;
logic [LLC_DATA_RAM_BANK_NUM-1:0]                 read_data_ram_s0_mshr_id_ena;

generate
  for(genvar data_ram_bank_id = 0; data_ram_bank_id <  LLC_DATA_RAM_BANK_NUM; data_ram_bank_id++) begin: gen_req_to_read_data_ram_fifo
    mp_fifo
    #(
      .payload_t          (logic[MSHR_NUM_W-1:0]  ),
      .ENQUEUE_WIDTH      (1                      ),
      .DEQUEUE_WIDTH      (1                      ),
      .DEPTH              (MSHR_NUM               ),
      .MUST_TAKEN_ALL     (1                      )
    )
    req_to_read_data_ram_fifo_u
    (
      // Enqueue
      .enqueue_vld_i          (req_to_read_data_ram_fifo_we       [data_ram_bank_id]        ),
      .enqueue_payload_i      (req_to_read_data_ram_fifo_din      [data_ram_bank_id]        ),
      .enqueue_rdy_o          (                                 ),
      // Dequeue
      .dequeue_vld_o          (req_to_read_data_ram_fifo_dout_vld [data_ram_bank_id]   ),
      .dequeue_payload_o      (req_to_read_data_ram_fifo_dout     [data_ram_bank_id]   ),
      .dequeue_rdy_i          (req_to_read_data_ram_fifo_re       [data_ram_bank_id]   ),

      .flush_i                (1'b0                             ),

      .clk                    (clk_i                            ),
      .rst                    (~rstn_i                          )
    );

    // s0: read out a mshr id and use its info to do data ram read
    assign req_to_read_data_ram_fifo_re [data_ram_bank_id] = req_to_read_data_ram_fifo_dout_vld [data_ram_bank_id] & mshr_read_data_ram_ready_i[data_ram_bank_id]; // TODO: data ram bank read and write conflict
    assign read_data_ram_s0_valid_d     [data_ram_bank_id] = req_to_read_data_ram_fifo_re       [data_ram_bank_id];
    assign read_data_ram_s0_mshr_id_d   [data_ram_bank_id] = req_to_read_data_ram_fifo_dout     [data_ram_bank_id];
    assign read_data_ram_s0_mshr_id_ena [data_ram_bank_id] = req_to_read_data_ram_fifo_re       [data_ram_bank_id];

      // read req out
    assign mshr_read_data_ram_valid_o     [data_ram_bank_id] = req_to_read_data_ram_fifo_dout_vld [data_ram_bank_id];
    assign mshr_read_data_ram_way_valid_o [data_ram_bank_id] = mshr_q[req_to_read_data_ram_fifo_dout[data_ram_bank_id]].victim_way_chosen_result;
    assign mshr_read_data_ram_idx_o       [data_ram_bank_id] = mshr_q[req_to_read_data_ram_fifo_dout[data_ram_bank_id]].addr[(LLC_OFFSET_WIDTH+$clog2(LLC_DATA_RAM_BANK_NUM))+:LLC_PER_DATA_RAM_BANK_INDEX_WIDTH];


    // s1: write the readout data ram bank data to the certain mshr
      // read data in
    assign mshr_read_data_ram_way_valid_q_o [data_ram_bank_id] = mshr_q[read_data_ram_s0_mshr_id_q[data_ram_bank_id]].victim_way_chosen_result;
    assign mshr_read_data_ram_valid_q_o     [data_ram_bank_id] = read_data_ram_s0_valid_q;

    // read data ram bank pipeline reg
    std_dffr
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_read_data_ram_s0_valid_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .d    (read_data_ram_s0_valid_d[data_ram_bank_id]   ),
      .q    (read_data_ram_s0_valid_q[data_ram_bank_id]   )
    );

    std_dffre
    #(.WIDTH(MSHR_NUM_W)) 
    U_SCU_REPL_MSHR_read_data_ram_s0_mshr_id_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (read_data_ram_s0_mshr_id_ena[data_ram_bank_id]  ),
      .d    (read_data_ram_s0_mshr_id_d[data_ram_bank_id]   ),
      .q    (read_data_ram_s0_mshr_id_q[data_ram_bank_id]   )
    );
  end
endgenerate

// ---------------
// req_to_write_tag_ram_fifo
// ---------------
logic [LLC_TAG_RAM_BANK_NUM-1:0]                 req_to_write_tag_ram_fifo_dout_vld;
logic [LLC_TAG_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0] req_to_write_tag_ram_fifo_dout;
logic [LLC_TAG_RAM_BANK_NUM-1:0]                 req_to_write_tag_ram_fifo_re;
scu_repl_mshr_t [LLC_TAG_RAM_BANK_NUM-1:0]       chosen_mshr_entry;
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0]  new_tag;

generate
  for(genvar tag_ram_bank_id = 0; tag_ram_bank_id <  LLC_TAG_RAM_BANK_NUM; tag_ram_bank_id++) begin: gen_req_to_write_tag_ram_fifo
    mp_fifo
    #(
      .payload_t          (logic[MSHR_NUM_W-1:0]  ),
      .ENQUEUE_WIDTH      (1                      ),
      .DEQUEUE_WIDTH      (1                      ),
      .DEPTH              (MSHR_NUM               ),
      .MUST_TAKEN_ALL     (1                      )
    )
    req_to_write_tag_ram_fifo_u
    (
      // Enqueue
      .enqueue_vld_i          (req_to_write_tag_ram_fifo_we       [tag_ram_bank_id]        ),
      .enqueue_payload_i      (req_to_write_tag_ram_fifo_din      [tag_ram_bank_id]        ),
      .enqueue_rdy_o          (                                 ),
      // Dequeue
      .dequeue_vld_o          (req_to_write_tag_ram_fifo_dout_vld [tag_ram_bank_id]   ),
      .dequeue_payload_o      (req_to_write_tag_ram_fifo_dout     [tag_ram_bank_id]   ),
      .dequeue_rdy_i          (req_to_write_tag_ram_fifo_re       [tag_ram_bank_id]   ),

      .flush_i                (1'b0                             ),

      .clk                    (clk_i                            ),
      .rst                    (~rstn_i                          )
    );

    assign chosen_mshr_entry[tag_ram_bank_id] = mshr_q[req_to_write_tag_ram_fifo_dout[tag_ram_bank_id]];

    assign req_to_write_tag_ram_fifo_re[tag_ram_bank_id] = req_to_write_tag_ram_fifo_dout_vld[tag_ram_bank_id] & mshr_write_tag_ram_ready_i[tag_ram_bank_id];

    assign mshr_write_tag_ram_valid_o  [tag_ram_bank_id] = req_to_write_tag_ram_fifo_re      [tag_ram_bank_id];

    assign mshr_write_tag_ram_way_valid_o [tag_ram_bank_id] = chosen_mshr_entry[tag_ram_bank_id].victim_way_chosen_result;
    assign mshr_write_tag_ram_idx_o       [tag_ram_bank_id] = chosen_mshr_entry[tag_ram_bank_id].addr[(LLC_OFFSET_WIDTH+$clog2(LLC_TAG_RAM_BANK_NUM))+:LLC_PER_TAG_RAM_BANK_INDEX_WIDTH];
    assign mshr_write_tag_ram_dram_wdat_o [tag_ram_bank_id] = new_tag[tag_ram_bank_id];


    assign new_tag [tag_ram_bank_id].tag          = chosen_mshr_entry[tag_ram_bank_id].addr[(PADDR_WIDTH-1)-:LLC_TAG_WIDTH];
    assign new_tag [tag_ram_bank_id].state.valid  = 1'b0;
    assign new_tag [tag_ram_bank_id].state.dirty  = 1'b0;
    assign new_tag [tag_ram_bank_id].dir          = '0;
  end
endgenerate



// ---------------
// resp_to_requestor_fifo
// ---------------
logic                   resp_to_requestor_fifo_dout_vld;
logic [MSHR_NUM_W-1:0]  resp_to_requestor_fifo_dout;
logic                   resp_to_requestor_fifo_re;

assign resp_to_requestor_fifo_re = resp_to_requestor_fifo_dout_vld & scu_pc_resp_rdy_i; // TODO: the resp from repl mshr has higher priority

mp_fifo
#(
  .payload_t          (logic[MSHR_NUM_W-1:0]  ),
  .ENQUEUE_WIDTH      (1                      ),
  .DEQUEUE_WIDTH      (1                      ),
  .DEPTH              (MSHR_NUM               ),
  .MUST_TAKEN_ALL     (1                      )
)
resp_to_requestor_fifo_u
(
  // Enqueue
  .enqueue_vld_i          (resp_to_requestor_fifo_we         ),
  .enqueue_payload_i      (resp_to_requestor_fifo_din        ),
  .enqueue_rdy_o          (                                 ),
  // Dequeue
  .dequeue_vld_o          (resp_to_requestor_fifo_dout_vld   ),
  .dequeue_payload_o      (resp_to_requestor_fifo_dout       ),
  .dequeue_rdy_i          (resp_to_requestor_fifo_re         ),
  
  .flush_i                (1'b0                             ),
  
  .clk                    (clk_i                            ),
  .rst                    (~rstn_i                          )
);

assign scu_pc_resp_vld_o  = resp_to_requestor_fifo_dout_vld;
assign scu_pc_resp_o.id.cid     = mshr_q[resp_to_requestor_fifo_dout].wb_pc_id.cid;
assign scu_pc_resp_o.id.bid     = mshr_q[resp_to_requestor_fifo_dout].wb_pc_id.bid;
assign scu_pc_resp_o.id.pc_tid  = mshr_q[resp_to_requestor_fifo_dout].wb_pc_id.pc_tid;
assign scu_pc_resp_o.id.scu_tid = {1'b1, (SCU_TID_W-1)'(resp_to_requestor_fifo_dout)};
assign scu_pc_resp_o.rtype      = WriteBack_Ack;

assign scu_pc_resp_o.src_id     = '0;
assign scu_pc_resp_o.tgt_id     = '0;
`ifdef ENABLE_TXN_ID
assign scu_pc_resp_o.txn_id     = TxnID_Width'(scu_pc_resp_o.id);
`endif
`ifdef USE_QOS_VALUE
assign scu_pc_resp_o.qos_value  = '0;
`endif

// ---------------
// mshr_valid_d
// ---------------
always_comb begin
  mshr_valid_d_set = '0;
  if(new_mshr_valid_i) begin
    mshr_valid_d_set[new_mshr_id_i] = 1'b1;
  end
end

assign mshr_valid_d_clr = mshr_final_action_finished;
assign mshr_valid_ena   = mshr_valid_d_set | mshr_valid_d_clr;

assign mshr_valid_d = (mshr_valid_q & ~mshr_valid_d_clr) | mshr_valid_d_set;
   


// ---------------
// mshr_d
// ---------------
always_comb begin
  mshr_ena = '0;
  mshr_d   = '0;
  
  // new_mshr
  if(new_mshr_valid_i) begin
    mshr_ena[new_mshr_id_i]       = '1;
    mshr_ena[new_mshr_id_i].data  = '0;

    mshr_d[new_mshr_id_i] = new_mshr_i;
  end

  // data read from data ram bank
  for(int data_ram_bank_id = 0; data_ram_bank_id <  LLC_DATA_RAM_BANK_NUM; data_ram_bank_id++) begin
    if(read_data_ram_s0_valid_q[data_ram_bank_id]) begin
      for(int burst_id = 0; burst_id < DATA_BURST_NUM; burst_id++) begin
        mshr_ena[read_data_ram_s0_mshr_id_q[data_ram_bank_id]].data       [burst_id] = ~mshr_q[read_data_ram_s0_mshr_id_q[data_ram_bank_id]].data_valid[burst_id];
      end
      mshr_ena[read_data_ram_s0_mshr_id_q[data_ram_bank_id]].data_valid                 = 1'b1;
      mshr_ena[read_data_ram_s0_mshr_id_q[data_ram_bank_id]].wait_for_llc_read_data_en  = 1'b1;

      for(int burst_id = 0; burst_id < DATA_BURST_NUM; burst_id++) begin
        mshr_d[read_data_ram_s0_mshr_id_q[data_ram_bank_id]].data       [burst_id] = mshr_read_data_ram_dram_rdat_i[data_ram_bank_id][burst_id*DATA_LENGTH_PER_PKG+:DATA_LENGTH_PER_PKG];
        mshr_d[read_data_ram_s0_mshr_id_q[data_ram_bank_id]].data_valid [burst_id] = 1'b1;
      end
      mshr_d[read_data_ram_s0_mshr_id_q[data_ram_bank_id]].wait_for_llc_read_data_en = 1'b0;

    end
  end

  // data resp from snp / writeback
  if(pc_scu_data_vld_i) begin
    for(int burst_id = 0; burst_id < DATA_BURST_NUM; burst_id++) begin
      mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data [burst_id] |= pc_scu_data_i.data_valid[burst_id];
    end
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_valid = 1'b1;
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_dirty = 1'b1;
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].writeback_data_received = 1'b1;
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].wait_for_wb_data_en = 1'b1;
    
    for(int burst_id = 0; burst_id < DATA_BURST_NUM; burst_id++) begin
      if(pc_scu_data_i.data_valid[burst_id]) begin
        mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data [burst_id] = pc_scu_data_i.data[burst_id];
      end
    end
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_valid |= (mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_valid | pc_scu_data_i.data_valid);
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_dirty |= (mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_dirty | (pc_scu_data_i.data_dirty & pc_scu_data_i.data_valid));
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].writeback_data_received = 1'b1;
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].wait_for_wb_data_en = 1'b0;

    unique case(pc_scu_data_i.rtype)
      SnpAck_FoundM: begin
        mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_data_receiving_list  = 1'b1;

        mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_data_receiving_list  = PRIVATE_CACHE_NUM'(1<<pc_scu_data_i.id.cid);
      end
      default:begin
      end
    endcase
  end


  // evict from private cache, hit in mshr
  if(pc_scu_evict_vld_i) begin
    unique case(pc_scu_evict_i.rtype)
      Evict: begin
        mshr_ena[pc_scu_evict_mshr_id_i].evict_resp_receiving_list  = 1'b1;
        
        mshr_d[pc_scu_evict_mshr_id_i].evict_resp_receiving_list = mshr_q[pc_scu_evict_mshr_id_i].evict_resp_receiving_list | PRIVATE_CACHE_NUM'(1<<pc_scu_evict_i.id.cid);
      end
      WriteBackFull: begin
        mshr_ena[pc_scu_evict_mshr_id_i].evict_resp_receiving_list  = 1'b1;
        mshr_ena[pc_scu_evict_mshr_id_i].wait_for_wb_data_en        = 1'b1;
        mshr_ena[pc_scu_evict_mshr_id_i].wb_pc_id                   = 1'b1;
        mshr_ena[pc_scu_evict_mshr_id_i].wb_rtype                   = 1'b1;
        
        mshr_d[pc_scu_evict_mshr_id_i].evict_resp_receiving_list = mshr_q[pc_scu_evict_mshr_id_i].evict_resp_receiving_list | PRIVATE_CACHE_NUM'(1<<pc_scu_evict_i.id.cid);
        mshr_d[pc_scu_evict_mshr_id_i].wait_for_wb_data_en       = 1'b1;
        mshr_d[pc_scu_evict_mshr_id_i].wb_pc_id                  = pc_scu_evict_i.id;
        mshr_d[pc_scu_evict_mshr_id_i].wb_rtype                  = pc_scu_evict_i.rtype;
      end
      WriteBackPartial: begin
        mshr_ena[pc_scu_evict_mshr_id_i].evict_resp_receiving_list  = 1'b1;
        mshr_ena[pc_scu_evict_mshr_id_i].wait_for_wb_data_en        = 1'b1;
        mshr_ena[pc_scu_evict_mshr_id_i].wb_pc_id                   = 1'b1;
        mshr_ena[pc_scu_evict_mshr_id_i].wb_rtype                   = 1'b1;
        
        mshr_d[pc_scu_evict_mshr_id_i].evict_resp_receiving_list = mshr_q[pc_scu_evict_mshr_id_i].evict_resp_receiving_list | PRIVATE_CACHE_NUM'(1<<pc_scu_evict_i.id.cid);
        mshr_d[pc_scu_evict_mshr_id_i].wait_for_wb_data_en       = 1'b1;
        mshr_d[pc_scu_evict_mshr_id_i].wb_pc_id                  = pc_scu_evict_i.id;
        mshr_d[pc_scu_evict_mshr_id_i].wb_rtype                  = pc_scu_evict_i.rtype;
      end
      default: begin
      end
    endcase
  end

  // scu send snp to cache
  if(scu_pc_snp_vld_hsk) begin
      mshr_ena[snp_to_cache_fifo_dout].snp_sent_list    = 1'b1;
      // mshr_ena[snp_to_cache_fifo_dout].need_invalid_snp = mshr_q[snp_to_cache_fifo_dout].need_invalid_snp;
      // mshr_ena[snp_to_cache_fifo_dout].need_shared_snp  = mshr_q[snp_to_cache_fifo_dout].need_shared_snp;

      mshr_d[snp_to_cache_fifo_dout].snp_sent_list    = mshr_q[snp_to_cache_fifo_dout].snp_sent_list | PRIVATE_CACHE_NUM'(1<<snp_need_to_send_list_sel_idx);
      // mshr_d[snp_to_cache_fifo_dout].need_invalid_snp = 1'b0;
      // mshr_d[snp_to_cache_fifo_dout].need_shared_snp  = 1'b0;
  end


  // scu receive snp resp / final resp ack
  if(pc_scu_resp_vld_i) begin
    unique case(pc_scu_resp_i.rtype)
      SnpAck_FoundI: begin
        // received invalid snp resp. means it is evicted or writebacked
        mshr_ena[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_resp_receiving_list = 1'b1;
        mshr_ena[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_resp_receiving_invalid_list = 1'b1;

        mshr_d[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_resp_receiving_list = mshr_q[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_resp_receiving_list | PRIVATE_CACHE_NUM'(1<<pc_scu_resp_i.id.cid);
        mshr_d[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_resp_receiving_invalid_list = mshr_q[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_resp_receiving_invalid_list | PRIVATE_CACHE_NUM'(1<<pc_scu_resp_i.id.cid);
      end
      SnpAck_FoundSorE: begin
        mshr_ena[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_resp_receiving_list = 1'b1;

        mshr_d[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_resp_receiving_list = mshr_q[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_resp_receiving_list | PRIVATE_CACHE_NUM'(1<<pc_scu_resp_i.id.cid);
      end
      default: begin
      end
    endcase
  end

  // scu final writeback mem enqueued
  if(mshr_at_writeback_stage_enqueue_valid) begin
    mshr_ena[mshr_at_writeback_stage_id].dirty_writeback_mem_enqueued = 1'b1;
    
    mshr_d[mshr_at_writeback_stage_id].dirty_writeback_mem_enqueued = 1'b1;
    
    if(~req_to_write_mem_fifo_we) begin // actually no dirty data
      mshr_ena[mshr_at_writeback_stage_id].dirty_writeback_mem_done = 1'b1;
    
      mshr_d[mshr_at_writeback_stage_id].dirty_writeback_mem_done = 1'b1;  
    end
  end

  // scu final writeback mem all data sent
  if(req_to_write_mem_fifo_w_re) begin
    mshr_ena[req_to_write_mem_fifo_w_dout].dirty_writeback_mem_done = 1'b1;
    
    mshr_d[req_to_write_mem_fifo_w_dout].dirty_writeback_mem_done = 1'b1;
  end

  // scu final data, tag, dir ram write
  if( mshr_at_write_tag_ram_stage_enqueue_valid  |
      mshr_at_write_state_dir_reg_stage_enqueue_valid) begin

    mshr_ena[mshr_at_final_write_stage_id].final_update_enqueued = 1'b1;

    mshr_d[mshr_at_final_write_stage_id].final_update_enqueued = 1'b1;
  end
end


// ---------------
// ready out signals
// ---------------
assign pc_scu_resp_rdy_o  = 1'b1;
assign pc_scu_evict_rdy_o = 1'b1;
assign pc_scu_data_rdy_o  = 1'b1;
assign mem_if_bready_o    = 1'b1;

// ---------------
// mshr ff logic
// ---------------
generate
  for(genvar mshr_id = 0; mshr_id < MSHR_NUM; mshr_id++) begin
    std_dffre
    #(.WIDTH(PADDR_WIDTH)) 
    U_SCU_REPL_MSHR_addr_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].addr ),
      .d    (mshr_d[mshr_id].addr   ),
      .q    (mshr_q[mshr_id].addr   )
    );

    std_dffre
    #(.WIDTH($bits(cache_cc_req_tid_t))) 
    U_SCU_REPL_MSHR_wb_pc_id_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wb_pc_id ),
      .d    (mshr_d[mshr_id].wb_pc_id   ),
      .q    (mshr_q[mshr_id].wb_pc_id   )
    );

    std_dffre
    #(.WIDTH($bits(cache_scu_cc_req_type_e))) 
    U_SCU_REPL_MSHR_wb_rtype_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wb_rtype ),
      .d    (mshr_d[mshr_id].wb_rtype   ),
      .q    (mshr_q[mshr_id].wb_rtype   )
    );

    std_dffre
    #(.WIDTH($bits(scu_dir_entry_t))) 
    U_SCU_REPL_MSHR_dir_entry_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].dir_entry ),
      .d    (mshr_d[mshr_id].dir_entry   ),
      .q    (mshr_q[mshr_id].dir_entry   )
    );

    std_dffre
    #(.WIDTH($bits(scu_llc_line_state_t))) 
    U_SCU_REPL_MSHR_state_entry_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].state_entry ),
      .d    (mshr_d[mshr_id].state_entry   ),
      .q    (mshr_q[mshr_id].state_entry   )
    );

    std_dffre
    #(.WIDTH(LLC_WAY_NUM)) 
    U_SCU_MSHR_victim_way_chosen_result_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].victim_way_chosen_result ),
      .d    (mshr_d[mshr_id].victim_way_chosen_result   ),
      .q    (mshr_q[mshr_id].victim_way_chosen_result   )
    );


    for(genvar data_seg_id = 0; data_seg_id < DATA_BURST_NUM; data_seg_id++) begin
      std_dffre
      #(.WIDTH(DATA_LENGTH_PER_PKG)) 
      U_SCU_REPL_MSHR_data_REG
      (
        .clk  (clk_i    ),
        .rstn (rstn_i   ),
        .en   (mshr_ena[mshr_id].data[data_seg_id] ),
        .d    (mshr_d[mshr_id].data[data_seg_id]   ),
        .q    (mshr_q[mshr_id].data[data_seg_id]   )
      );
    end

    std_dffre
    #(.WIDTH(DATA_BURST_NUM)) 
    U_SCU_REPL_MSHR_data_valid_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].data_valid ),
      .d    (mshr_d[mshr_id].data_valid   ),
      .q    (mshr_q[mshr_id].data_valid   )
    );

    std_dffre
    #(.WIDTH(DATA_BURST_NUM)) 
    U_SCU_REPL_MSHR_data_dirty_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].data_dirty ),
      .d    (mshr_d[mshr_id].data_dirty   ),
      .q    (mshr_q[mshr_id].data_dirty   )
    );

    // std_dffre
    // #(.WIDTH(DATA_BURST_NUM_W)) 
    // U_SCU_REPL_MSHR_mem_req_data_seg_wr_ptr_REG
    // (
    //   .clk  (clk_i    ),
    //   .rstn (rstn_i   ),
    //   .en   (mshr_ena[mshr_id].mem_req_data_seg_wr_ptr ),
    //   .d    (mshr_d[mshr_id].mem_req_data_seg_wr_ptr   ),
    //   .q    (mshr_q[mshr_id].mem_req_data_seg_wr_ptr   )
    // );


    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_REPL_MSHR_snp_need_to_send_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].snp_need_to_send_list ),
      .d    (mshr_d[mshr_id].snp_need_to_send_list   ),
      .q    (mshr_q[mshr_id].snp_need_to_send_list   )
    );

    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_REPL_MSHR_snp_sent_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].snp_sent_list ),
      .d    (mshr_d[mshr_id].snp_sent_list   ),
      .q    (mshr_q[mshr_id].snp_sent_list   )
    );

    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_REPL_MSHR_snp_resp_receiving_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].snp_resp_receiving_list ),
      .d    (mshr_d[mshr_id].snp_resp_receiving_list   ),
      .q    (mshr_q[mshr_id].snp_resp_receiving_list   )
    );

    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_REPL_MSHR_snp_data_receiving_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].snp_data_receiving_list ),
      .d    (mshr_d[mshr_id].snp_data_receiving_list   ),
      .q    (mshr_q[mshr_id].snp_data_receiving_list   )
    );

    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_MSHR_snp_resp_receiving_invalid_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].snp_resp_receiving_invalid_list ),
      .d    (mshr_d[mshr_id].snp_resp_receiving_invalid_list   ),
      .q    (mshr_q[mshr_id].snp_resp_receiving_invalid_list   )
    );

    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_REPL_MSHR_evict_resp_receiving_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].evict_resp_receiving_list ),
      .d    (mshr_d[mshr_id].evict_resp_receiving_list   ),
      .q    (mshr_q[mshr_id].evict_resp_receiving_list   )
    );

    std_dffre
    #(.WIDTH(1))
    U_SCU_REPL_MSHR_writeback_data_received_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].writeback_data_received ),
      .d    (mshr_d[mshr_id].writeback_data_received   ),
      .q    (mshr_q[mshr_id].writeback_data_received   )
    );

    std_dffre
    #(.WIDTH(1))
    U_SCU_REPL_MSHR_wait_for_wb_data_en_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wait_for_wb_data_en ),
      .d    (mshr_d[mshr_id].wait_for_wb_data_en   ),
      .q    (mshr_q[mshr_id].wait_for_wb_data_en   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_wait_for_llc_read_data_en_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wait_for_llc_read_data_en ),
      .d    (mshr_d[mshr_id].wait_for_llc_read_data_en   ),
      .q    (mshr_q[mshr_id].wait_for_llc_read_data_en   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_need_invalid_snp_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].need_invalid_snp ),
      .d    (mshr_d[mshr_id].need_invalid_snp   ),
      .q    (mshr_q[mshr_id].need_invalid_snp   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_final_update_enqueued_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].final_update_enqueued ),
      .d    (mshr_d[mshr_id].final_update_enqueued   ),
      .q    (mshr_q[mshr_id].final_update_enqueued   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_need_to_update_tag_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].need_to_update_tag ),
      .d    (mshr_d[mshr_id].need_to_update_tag   ),
      .q    (mshr_q[mshr_id].need_to_update_tag   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_need_to_update_dir_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].need_to_update_dir ),
      .d    (mshr_d[mshr_id].need_to_update_dir   ),
      .q    (mshr_q[mshr_id].need_to_update_dir   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_monitor_evict_before_update_dir_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].monitor_evict_before_update_dir ),
      .d    (mshr_d[mshr_id].monitor_evict_before_update_dir   ),
      .q    (mshr_q[mshr_id].monitor_evict_before_update_dir   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_monitor_evict_before_receiving_all_snp_resp_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].monitor_evict_before_receiving_all_snp_resp ),
      .d    (mshr_d[mshr_id].monitor_evict_before_receiving_all_snp_resp   ),
      .q    (mshr_q[mshr_id].monitor_evict_before_receiving_all_snp_resp   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_monitor_writeback_before_receiving_all_snp_resp_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].monitor_writeback_before_receiving_all_snp_resp ),
      .d    (mshr_d[mshr_id].monitor_writeback_before_receiving_all_snp_resp   ),
      .q    (mshr_q[mshr_id].monitor_writeback_before_receiving_all_snp_resp   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_dirty_writeback_mem_enqueued_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].dirty_writeback_mem_enqueued ),
      .d    (mshr_d[mshr_id].dirty_writeback_mem_enqueued   ),
      .q    (mshr_q[mshr_id].dirty_writeback_mem_enqueued   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_dirty_writeback_mem_done_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].dirty_writeback_mem_done ),
      .d    (mshr_d[mshr_id].dirty_writeback_mem_done   ),
      .q    (mshr_q[mshr_id].dirty_writeback_mem_done   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_REPL_MSHR_mshr_valid_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_valid_ena[mshr_id] ),
      .d    (mshr_valid_d  [mshr_id] ),
      .q    (mshr_valid_q  [mshr_id] )
    );

  end
endgenerate

`ifndef SYNTHESIS
  assert property(@(posedge clk_i)disable iff(~rstn_i) (new_mshr_valid_i)|-> (~mshr_valid_q[new_mshr_id_i]))
    else $fatal("mshr: set new_mshr entry to a valid entry");
`endif
endmodule
