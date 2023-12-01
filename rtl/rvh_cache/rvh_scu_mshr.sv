module rvh_scu_mshr
  import rvh_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_noc_pkg::*;
  import rvh_uncore_param_pkg::*;
#(
  parameter int MSHR_NUM      = 8,
  parameter int MSHR_NUM_W    = $clog2(MSHR_NUM) > 0 ? $clog2(MSHR_NUM) : 1
`ifdef COMMON_DATA_VALID_LATENCY_EN
  ,parameter COMMON_DATA_VALID_LATENCY = 32
`endif
)
(
  // new mshr
  input  logic                              new_mshr_valid_i,
  input  logic                              new_mshr_enqueue_req_to_read_mem_fifo_i,
  input  logic [LLC_DATA_RAM_BANK_NUM-1:0]  new_mshr_enqueue_req_to_read_data_ram_fifo_i,
  input  logic                              new_mshr_enqueue_snp_to_cache_fifo_i,
  input  logic                              new_mshr_enqueue_resp_to_requestor_fifo_i,
  input  scu_mshr_t                         new_mshr_i,
  input  [MSHR_NUM_W-1:0]                   new_mshr_id_i,

  // mshr_q and mshr_valid_q output
  output scu_mshr_t [MSHR_NUM-1:0]          mshr_q_o,
  output logic      [MSHR_NUM-1:0]          mshr_valid_q_o,

  // scu -> cache, snp intf
  output logic                              scu_pc_snp_vld_o,
  output cache_scu_cc_snp_t                 scu_pc_snp_o,
  input  logic                              scu_pc_snp_rdy_i,

  // scu -> cache, resp intf
  output logic                              scu_pc_resp_vld_o,
  output cache_scu_cc_resp_t                scu_pc_resp_o,
  input  logic                              scu_pc_resp_rdy_i,

  // scu -> cache, data resp intf
  output logic                              scu_pc_data_vld_o,
  output cache_scu_cc_data_t                scu_pc_data_o,
  input  logic                              scu_pc_data_rdy_i,

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

    // write req out
  output logic [LLC_DATA_RAM_BANK_NUM-1:0]                             mshr_write_data_ram_valid_o,
  output logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]            mshr_write_data_ram_way_valid_o,
  output logic [LLC_DATA_RAM_BANK_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] mshr_write_data_ram_idx_o,
  output logic [LLC_DATA_RAM_BANK_NUM-1:0][DATA_LINE_W-1:0]            mshr_write_data_ram_dram_wdat_o,
  input  logic [LLC_DATA_RAM_BANK_NUM-1:0]                             mshr_write_data_ram_ready_i,

  // tag ram intf
    // write req out
  output logic [LLC_TAG_RAM_BANK_NUM-1:0]                              mshr_write_tag_ram_valid_o,
  output logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_WAY_NUM-1:0]             mshr_write_tag_ram_way_valid_o,
  output logic [LLC_TAG_RAM_BANK_NUM-1:0][LLC_PER_DATA_RAM_BANK_INDEX_WIDTH-1:0] mshr_write_tag_ram_idx_o,
  output scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0]          mshr_write_tag_ram_dram_wdat_o,
  input  logic [LLC_TAG_RAM_BANK_NUM-1:0]                              mshr_write_tag_ram_ready_i,

  // mem intf
    // AR
  output logic                              mem_if_arvalid_o,
  output cache_mem_if_ar_t                  mem_if_ar_o,
  input  logic                              mem_if_arready_i,
    // R
  input  logic                              mem_if_rvalid_i,
  input  cache_mem_if_r_t                   mem_if_r_i,
  output logic                              mem_if_rready_o,

  // else
  input  logic                clk_i,
  input  logic                rstn_i
);

`ifndef SYNTHESIS
logic new_mshr_is_CleanUnique;
assign new_mshr_is_CleanUnique = new_mshr_valid_i & (new_mshr_i.req.rtype == CleanUnique);
`endif

// mshr reg
scu_mshr_t     [MSHR_NUM-1:0]   mshr_q, mshr_d;
scu_mshr_ena_t [MSHR_NUM-1:0]   mshr_ena;
// mshr valid
logic      [MSHR_NUM-1:0]   mshr_valid_d, mshr_valid_q;
logic      [MSHR_NUM-1:0]   mshr_valid_d_set, mshr_valid_d_clr;
logic      [MSHR_NUM-1:0]   mshr_valid_ena;

// fifo signals
  // req_to_read_mem_fifo
logic                   req_to_read_mem_fifo_we;
logic [MSHR_NUM_W-1:0]  req_to_read_mem_fifo_din;
  // req_to_read_data_ram_fifo
logic [LLC_DATA_RAM_BANK_NUM-1:0]                  req_to_read_data_ram_fifo_we;
logic [LLC_DATA_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0]  req_to_read_data_ram_fifo_din;
  // snp_to_cache_fifo
logic                   snp_to_cache_fifo_we;
logic [MSHR_NUM_W-1:0]  snp_to_cache_fifo_din;
  // resp_to_requestor_fifo, 2 enqueue ports, 0 for new_mshr, 1 for exist mshr
logic [2-1:0]                  resp_to_requestor_fifo_we;
logic [2-1:0][MSHR_NUM_W-1:0]  resp_to_requestor_fifo_din;
  // data_to_requestor_fifo, 2 enqueue ports, 0 for critical word first data resp(is it is enabled), 1 for full line or comoon part data resp
logic [2-1:0]                  data_to_requestor_fifo_we;
logic [2-1:0][MSHR_NUM_W-1:0]  data_to_requestor_fifo_din;
  // req_to_write_data_ram_fifo
logic [LLC_DATA_RAM_BANK_NUM-1:0]                  req_to_write_data_ram_fifo_we;
logic [LLC_DATA_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0]  req_to_write_data_ram_fifo_din;
  // req_to_write_tag_ram_fifo
logic [LLC_TAG_RAM_BANK_NUM-1:0]                   req_to_write_tag_ram_fifo_we;
logic [LLC_TAG_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0]   req_to_write_tag_ram_fifo_din;

assign mshr_q_o = mshr_q;
assign mshr_valid_q_o = mshr_valid_q;

// ---------------
// mshr_q dealloc judge
// ---------------
logic [MSHR_NUM-1:0] mshr_transition_action_finished; // when this is set, means the final resp can be sent
logic [MSHR_NUM-1:0] mshr_resp_action_finished; // when this is set, means the tag, data, dir, state update can start
logic [MSHR_NUM-1:0] mshr_final_action_finished; // when this is set, means the transaction is finished, the mshr can be deallocated
generate
  for(genvar mshr_id = 0; mshr_id < MSHR_NUM; mshr_id++) begin
    assign mshr_transition_action_finished[mshr_id] =
                                    // it is a valid mshr
                                    mshr_valid_q[mshr_id] &
                                    // all wait done
                                    ~mshr_q[mshr_id].wait_for_wb_data_en &
                                    ~mshr_q[mshr_id].wait_for_mem_read_data_en &
                                    ~mshr_q[mshr_id].wait_for_llc_read_data_en &
                                    // all snp sent
                                      // ~mshr_q[mshr_id].need_invalid_snp &
                                      // ~mshr_q[mshr_id].need_shared_snp &
                                    (mshr_q[mshr_id].snp_need_to_send_list == mshr_q[mshr_id].snp_sent_list) &
                                    // all snp / evict / wb resp or data received
                                    (mshr_q[mshr_id].snp_sent_list == (mshr_q[mshr_id].snp_resp_receiving_list | mshr_q[mshr_id].snp_data_receiving_list)) & // all snp received
                                    (
                                      (mshr_q[mshr_id].snp_resp_receiving_invalid_list == (mshr_q[mshr_id].evict_resp_receiving_list & mshr_q[mshr_id].snp_resp_receiving_invalid_list)) | // all evict received (may get unexpected evict, they need to be handled but not required), or
                                      mshr_q[mshr_id].writeback_data_received                                              // the writeback received
                                    );

    assign mshr_resp_action_finished[mshr_id] = 
                                    // it is a valid mshr
                                    mshr_valid_q[mshr_id] &
                                    // mshr_transition_action_finished
                                    mshr_transition_action_finished[mshr_id] &
                                    // the resp ack has received or no need
                                    ~mshr_q[mshr_id].wait_for_resp_ack;

    assign mshr_final_action_finished[mshr_id] = 
                                    // it is a valid mshr
                                    mshr_valid_q[mshr_id] &
                                    // mshr_resp_action_finished
                                    mshr_resp_action_finished[mshr_id] &
                                    // all data / tag / dir update done
                                    ~mshr_q[mshr_id].need_to_update_data &
                                    ~mshr_q[mshr_id].need_to_update_tag &
                                    ~mshr_q[mshr_id].need_to_update_dir;
                                    // // all dirty data writen to data ram
                                    // ~(|(mshr_q[mshr_id].data_valid & mshr_q[mshr_id].data_dirty));

  end
endgenerate


// ---------------
// fifo enqueue
// ---------------
logic                   mshr_at_resp_stage_valid;
logic [MSHR_NUM-1:0]    mshr_at_resp_stage_valid_oh;
logic [MSHR_NUM_W-1:0]  mshr_at_resp_stage_id;
logic                   mshr_at_resp_stage_enqueue_valid;

logic                   mshr_at_final_write_stage_valid;
// logic [MSHR_NUM-1:0]    mshr_at_final_write_stage_valid_oh;
logic [MSHR_NUM_W-1:0]  mshr_at_final_write_stage_id;
logic                   mshr_at_write_data_ram_stage_enqueue_valid;
logic                   mshr_at_write_tag_ram_stage_enqueue_valid;
logic                   mshr_at_write_state_dir_reg_stage_enqueue_valid;

always_comb begin
  req_to_read_mem_fifo_we         = '0;
  req_to_read_mem_fifo_din        = '0;
  req_to_read_data_ram_fifo_we    = '0;
  req_to_read_data_ram_fifo_din   = '0;
  snp_to_cache_fifo_we            = '0;
  snp_to_cache_fifo_din           = '0;
  resp_to_requestor_fifo_we       = '0;
  resp_to_requestor_fifo_din      = '0;
  data_to_requestor_fifo_we       = '0;
  data_to_requestor_fifo_din      = '0;
  req_to_write_data_ram_fifo_we   = '0;
  req_to_write_data_ram_fifo_din  = '0;
  req_to_write_tag_ram_fifo_we    = '0;
  req_to_write_tag_ram_fifo_din   = '0;

  // new_mshr
  if(new_mshr_valid_i) begin
    req_to_read_mem_fifo_we       = new_mshr_enqueue_req_to_read_mem_fifo_i;
    req_to_read_mem_fifo_din      = new_mshr_id_i;

    for(int i = 0; i < LLC_DATA_RAM_BANK_NUM; i++) begin
      req_to_read_data_ram_fifo_we [i] = new_mshr_enqueue_req_to_read_data_ram_fifo_i[i];
      req_to_read_data_ram_fifo_din[i] = new_mshr_id_i;
    end

    snp_to_cache_fifo_we          = new_mshr_enqueue_snp_to_cache_fifo_i;
    snp_to_cache_fifo_din         = new_mshr_id_i;

    resp_to_requestor_fifo_we [0] = new_mshr_enqueue_resp_to_requestor_fifo_i;
    resp_to_requestor_fifo_din[0] = new_mshr_id_i;
  end

  // writeback from private cache, hit in mshr, then send ack to privact cache to gt wb data
  if(pc_scu_evict_vld_i) begin
    unique case(pc_scu_evict_i.rtype)
      WriteBackFull,
      WriteBackPartial: begin
        resp_to_requestor_fifo_we [1] = 1'b1;
        resp_to_requestor_fifo_din[1] = pc_scu_evict_mshr_id_i;
      end
      default: begin
      end
    endcase
  end

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
  if(pc_scu_data_vld_i) begin
    data_to_requestor_fifo_we [0] = pc_scu_data_i.is_critical & pc_scu_data_i.has_another_part & ~mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].common_received_wait_for_critical; // mshr_d.critical_received_wait_for_common set
    data_to_requestor_fifo_din[0] = pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0];
  end
`endif

  // final resp and data from scu to requestor cache
  if(mshr_at_resp_stage_enqueue_valid) begin
    unique case(mshr_q[mshr_at_resp_stage_id].req.rtype)
      ReadShared,
      ReadOnce,
      ReadUnique: begin
        data_to_requestor_fifo_we [1] = 1'b1;
        data_to_requestor_fifo_din[1] = mshr_at_resp_stage_id;
      end
      CleanUnique: begin
        resp_to_requestor_fifo_we [1] = 1'b1;
        resp_to_requestor_fifo_din[1] = mshr_at_resp_stage_id;
      end
      default: begin
      end
    endcase
  end

  // final data ram write
  if(mshr_at_write_data_ram_stage_enqueue_valid) begin
`ifdef LLC_DATA_RAM_MULTI_BANK
    req_to_write_data_ram_fifo_we [mshr_q[mshr_at_final_write_stage_id].req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = 1'b1;
    req_to_write_data_ram_fifo_din[mshr_q[mshr_at_final_write_stage_id].req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_DATA_RAM_BANK_NUM)]] = mshr_at_final_write_stage_id;
`else
    req_to_write_data_ram_fifo_we [0] = 1'b1;
    req_to_write_data_ram_fifo_din[0] = mshr_at_final_write_stage_id;
`endif
  end
  // final tag_dir_state ram write
  if(mshr_at_write_tag_ram_stage_enqueue_valid | mshr_at_write_state_dir_reg_stage_enqueue_valid) begin
`ifdef LLC_TAG_RAM_MULTI_BANK
    req_to_write_tag_ram_fifo_we  [mshr_q[mshr_at_final_write_stage_id].req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_TAG_RAM_BANK_NUM)]] = 1'b1;
    req_to_write_tag_ram_fifo_din [mshr_q[mshr_at_final_write_stage_id].req.addr[LLC_OFFSET_WIDTH+:$clog2(LLC_TAG_RAM_BANK_NUM)]] = mshr_at_final_write_stage_id;
`else
    req_to_write_tag_ram_fifo_we [0] = 1'b1;
    req_to_write_tag_ram_fifo_din[0] = mshr_at_final_write_stage_id;
`endif
  end
end

assign mshr_at_resp_stage_enqueue_valid = mshr_at_resp_stage_valid &
                                          ~mshr_q[mshr_at_resp_stage_id].final_resp_enqueued &
                                          ~pc_scu_evict_vld_i;

assign mshr_at_write_data_ram_stage_enqueue_valid = mshr_at_final_write_stage_valid &
                                                    (|(mshr_q[mshr_at_final_write_stage_id].data_valid)) & // notice: the all valid bit should be assert, though the dirty writeback may be partial, the rest part should be read from data ram before write data ram
                                                    mshr_q[mshr_at_final_write_stage_id].need_to_update_data &
                                                    ~mshr_q[mshr_at_final_write_stage_id].final_update_enqueued;

assign mshr_at_write_tag_ram_stage_enqueue_valid = mshr_at_final_write_stage_valid &
                                                   mshr_q[mshr_at_final_write_stage_id].need_to_update_tag &
                                                   ~mshr_q[mshr_at_final_write_stage_id].final_update_enqueued;

assign mshr_at_write_state_dir_reg_stage_enqueue_valid = mshr_at_final_write_stage_valid &
                                                         mshr_q[mshr_at_final_write_stage_id].need_to_update_dir &
                                                         ~mshr_q[mshr_at_final_write_stage_id].final_update_enqueued;

// priority_encoder
// #(
//   .SEL_WIDTH(MSHR_NUM)
// )
// mshr_at_resp_stage_enqueue_mshr_id_sel
// (
//   .sel_i      (mshr_transition_action_finished & ~mshr_resp_action_finished ),
//   .id_vld_o   (mshr_at_resp_stage_valid         ),
//   .id_o       (mshr_at_resp_stage_id            )
// );

logic [MSHR_NUM-1:0] mshr_at_resp_stage_enqueue;
generate
  for(genvar mshr_id = 0; mshr_id < MSHR_NUM; mshr_id++) begin: gen_mshr_at_resp_stage_enqueue
    assign mshr_at_resp_stage_enqueue[mshr_id] = mshr_transition_action_finished[mshr_id] & 
                                                ~mshr_resp_action_finished[mshr_id] 
`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
                                                & (mshr_q[mshr_id].critical_part_resp_enqueued ? mshr_q[mshr_id].critical_part_resp_done : '1)
`endif
                                                ;
  end
endgenerate

one_hot_rr_arb #(
  .N_INPUT      (MSHR_NUM) 
) mshr_at_resp_stage_enqueue_mshr_id_sel (
  .req_i        (mshr_at_resp_stage_enqueue   ),
  .update_i     (|mshr_at_resp_stage_enqueue  ),
  .grt_o        (mshr_at_resp_stage_valid_oh                     ),
  .grt_idx_o    (mshr_at_resp_stage_id                 ),
  .rstn         (rstn_i                        ),
  .clk          (clk_i                        )
);

assign mshr_at_resp_stage_valid = |mshr_at_resp_stage_valid_oh;

priority_encoder
#(
  .SEL_WIDTH(MSHR_NUM)
)
mshr_at_final_write_stage_enqueue_mshr_id_sel
(
  .sel_i      (mshr_resp_action_finished & ~mshr_final_action_finished ),
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
  .enqueue_rdy_o          (                             ),
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
assign scu_pc_snp_o.id.sid     = '0; // assign it outside scu
assign scu_pc_snp_o.id.scu_tid = {1'b0, (SCU_TID_W-1)'(snp_to_cache_fifo_dout)};
assign scu_pc_snp_o.id.cid     = snp_need_to_send_list_sel_idx;
assign scu_pc_snp_o.rtype      = mshr_q[snp_to_cache_fifo_dout].need_invalid_snp ? SnpUnique
                                                                                 : SnpShared;
assign scu_pc_snp_o.addr       = mshr_q[snp_to_cache_fifo_dout].req.addr;

assign scu_pc_snp_o.src_id     = '0;
assign scu_pc_snp_o.tgt_id     = '0;
`ifdef ENABLE_TXN_ID
assign scu_pc_snp_o.txn_id     = TxnID_Width'(scu_pc_snp_o.id);
`endif

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
assign scu_pc_snp_o.data_resp_with_critical_word_first = ~mshr_q[snp_to_cache_fifo_dout].need_invalid_snp; // for load req, need critical word first snp data resp
`endif

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
  `ifdef USE_QOS_VALUE
assign scu_pc_snp_o.qos_value  = scu_pc_snp_o.data_resp_with_critical_word_first ? '1 : '0;
  `endif
`else
  `ifdef USE_QOS_VALUE
assign scu_pc_snp_o.qos_value  = '0;
  `endif
`endif

assign scu_pc_snp_vld_hsk      = scu_pc_snp_vld_o & scu_pc_snp_rdy_i;


// ---------------
// req_to_read_mem_fifo
// ---------------
logic                   req_to_read_mem_fifo_dout_vld;
logic [MSHR_NUM_W-1:0]  req_to_read_mem_fifo_dout;
logic                   req_to_read_mem_fifo_re;

assign req_to_read_mem_fifo_re = req_to_read_mem_fifo_dout_vld & mem_if_arready_i; // TODO: the snp req from repl mshr has higher priority

mp_fifo
#(
  .payload_t          (logic[MSHR_NUM_W-1:0]  ),
  .ENQUEUE_WIDTH      (1                      ),
  .DEQUEUE_WIDTH      (1                      ),
  .DEPTH              (MSHR_NUM               ),
  .MUST_TAKEN_ALL     (1                      )
)
req_to_read_mem_fifo_u
(
  // Enqueue
  .enqueue_vld_i          (req_to_read_mem_fifo_we          ),
  .enqueue_payload_i      (req_to_read_mem_fifo_din         ),
  .enqueue_rdy_o          (                                 ),
  // Dequeue
  .dequeue_vld_o          (req_to_read_mem_fifo_dout_vld    ),
  .dequeue_payload_o      (req_to_read_mem_fifo_dout        ),
  .dequeue_rdy_i          (req_to_read_mem_fifo_re          ),
  
  .flush_i                (1'b0                             ),
  
  .clk                    (clk_i                            ),
  .rst                    (~rstn_i                          )
);

assign mem_if_arvalid_o     = req_to_read_mem_fifo_dout_vld;
assign mem_if_ar_o.arid.tid = req_to_read_mem_fifo_dout;
assign mem_if_ar_o.arid.bid = '0;
assign mem_if_ar_o.araddr   = {mshr_q[req_to_read_mem_fifo_dout].req.addr[PADDR_WIDTH-1:LLC_OFFSET_WIDTH], {LLC_OFFSET_WIDTH{1'b0}}};
assign mem_if_ar_o.arlen    = BURST_SIZE-1;// read a full burst from memory(2'b11)
assign mem_if_ar_o.arsize   = AXI_SIZE;
assign mem_if_ar_o.arburst  = 2'b01; // INCR mode


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
    assign mshr_read_data_ram_way_valid_o [data_ram_bank_id] = mshr_q[req_to_read_data_ram_fifo_dout[data_ram_bank_id]].valid_tags_compare_result;
    assign mshr_read_data_ram_idx_o       [data_ram_bank_id] = mshr_q[req_to_read_data_ram_fifo_dout[data_ram_bank_id]].req.addr[(LLC_OFFSET_WIDTH+$clog2(LLC_DATA_RAM_BANK_NUM))+:LLC_PER_DATA_RAM_BANK_INDEX_WIDTH];


    // s1: write the readout data ram bank data to the certain mshr
      // read data in
    assign mshr_read_data_ram_way_valid_q_o [data_ram_bank_id] = mshr_q[read_data_ram_s0_mshr_id_q[data_ram_bank_id]].valid_tags_compare_result;
    assign mshr_read_data_ram_valid_q_o     [data_ram_bank_id] = read_data_ram_s0_valid_q;

    // read data ram bank pipeline reg
    std_dffr
    #(.WIDTH(1)) 
    U_SCU_MSHR_read_data_ram_s0_valid_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .d    (read_data_ram_s0_valid_d[data_ram_bank_id]   ),
      .q    (read_data_ram_s0_valid_q[data_ram_bank_id]   )
    );

    std_dffre
    #(.WIDTH(MSHR_NUM_W)) 
    U_SCU_MSHR_read_data_ram_s0_mshr_id_REG
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
// req_to_write_data_ram_fifo
// ---------------
logic [LLC_DATA_RAM_BANK_NUM-1:0]                 req_to_write_data_ram_fifo_dout_vld;
logic [LLC_DATA_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0] req_to_write_data_ram_fifo_dout;
logic [LLC_DATA_RAM_BANK_NUM-1:0]                 req_to_write_data_ram_fifo_re;

generate
  for(genvar data_ram_bank_id = 0; data_ram_bank_id <  LLC_DATA_RAM_BANK_NUM; data_ram_bank_id++) begin: gen_req_to_write_data_ram_fifo
    mp_fifo
    #(
      .payload_t          (logic[MSHR_NUM_W-1:0]  ),
      .ENQUEUE_WIDTH      (1                      ),
      .DEQUEUE_WIDTH      (1                      ),
      .DEPTH              (MSHR_NUM               ),
      .MUST_TAKEN_ALL     (1                      )
    )
    req_to_write_data_ram_fifo_u
    (
      // Enqueue
      .enqueue_vld_i          (req_to_write_data_ram_fifo_we       [data_ram_bank_id]        ),
      .enqueue_payload_i      (req_to_write_data_ram_fifo_din      [data_ram_bank_id]        ),
      .enqueue_rdy_o          (                                 ),
      // Dequeue
      .dequeue_vld_o          (req_to_write_data_ram_fifo_dout_vld [data_ram_bank_id]   ),
      .dequeue_payload_o      (req_to_write_data_ram_fifo_dout     [data_ram_bank_id]   ),
      .dequeue_rdy_i          (req_to_write_data_ram_fifo_re       [data_ram_bank_id]   ),

      .flush_i                (1'b0                             ),

      .clk                    (clk_i                            ),
      .rst                    (~rstn_i                          )
    );

    assign req_to_write_data_ram_fifo_re[data_ram_bank_id] = req_to_write_data_ram_fifo_dout_vld[data_ram_bank_id] & mshr_write_data_ram_ready_i[data_ram_bank_id];

    assign mshr_write_data_ram_valid_o  [data_ram_bank_id] = req_to_write_data_ram_fifo_re      [data_ram_bank_id];

    assign mshr_write_data_ram_way_valid_o [data_ram_bank_id] = mshr_q[req_to_write_data_ram_fifo_dout[data_ram_bank_id]].valid_tags_compare_result;
    assign mshr_write_data_ram_idx_o       [data_ram_bank_id] = mshr_q[req_to_write_data_ram_fifo_dout[data_ram_bank_id]].req.addr[(LLC_OFFSET_WIDTH+$clog2(LLC_DATA_RAM_BANK_NUM))+:LLC_PER_DATA_RAM_BANK_INDEX_WIDTH];
    for(genvar burst_id = 0; burst_id < DATA_BURST_NUM; burst_id++) begin: gen_mshr_write_data_ram_dram_wdat_o
      assign mshr_write_data_ram_dram_wdat_o [data_ram_bank_id][burst_id*DATA_LENGTH_PER_PKG+:DATA_LENGTH_PER_PKG] = mshr_q[req_to_write_data_ram_fifo_dout[data_ram_bank_id]].data[burst_id];
    end
  end
endgenerate



// ---------------
// req_to_write_tag_ram_fifo
// ---------------
logic [LLC_TAG_RAM_BANK_NUM-1:0]                 req_to_write_tag_ram_fifo_dout_vld;
logic [LLC_TAG_RAM_BANK_NUM-1:0][MSHR_NUM_W-1:0] req_to_write_tag_ram_fifo_dout;
logic [LLC_TAG_RAM_BANK_NUM-1:0]                 req_to_write_tag_ram_fifo_re;
scu_mshr_t [LLC_TAG_RAM_BANK_NUM-1:0]            chosen_mshr_entry;
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0]  new_tag;

`ifndef SYNTHESIS
scu_llc_fused_tag_entry_t [LLC_TAG_RAM_BANK_NUM-1:0] addr_0_tag;
`endif

generate
  for(genvar tag_ram_bank_id = 0; tag_ram_bank_id <  LLC_TAG_RAM_BANK_NUM; tag_ram_bank_id++) begin: gen_req_to_write_tag_ram_fifo
`ifndef SYNTHESIS
    std_dffre
    #(.WIDTH($bits(scu_llc_fused_tag_entry_t))) 
    U_SCU_MSHR_0_tag_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   ((req_to_write_tag_ram_fifo_dout_vld[tag_ram_bank_id] & (mshr_q[req_to_write_tag_ram_fifo_dout[tag_ram_bank_id]].req.addr == 'h0))),
      .d    (new_tag[tag_ram_bank_id]  ),
      .q    (addr_0_tag[tag_ram_bank_id]   )
    );
`endif

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

    assign mshr_write_tag_ram_way_valid_o [tag_ram_bank_id] = chosen_mshr_entry[tag_ram_bank_id].valid_tags_compare_result;
    assign mshr_write_tag_ram_idx_o       [tag_ram_bank_id] = chosen_mshr_entry[tag_ram_bank_id].req.addr[(LLC_OFFSET_WIDTH+$clog2(LLC_TAG_RAM_BANK_NUM))+:LLC_PER_TAG_RAM_BANK_INDEX_WIDTH];
    assign mshr_write_tag_ram_dram_wdat_o [tag_ram_bank_id] = new_tag[tag_ram_bank_id];


    assign new_tag [tag_ram_bank_id].tag          = chosen_mshr_entry[tag_ram_bank_id].req.addr[(PADDR_WIDTH-1)-:LLC_TAG_WIDTH];
    assign new_tag [tag_ram_bank_id].state.valid  = 1'b1;
    assign new_tag [tag_ram_bank_id].state.dirty  = chosen_mshr_entry[tag_ram_bank_id].state_entry.dirty | 
                                                    (chosen_mshr_entry[tag_ram_bank_id].need_to_update_data & (|chosen_mshr_entry[tag_ram_bank_id].data_dirty));

    always_comb begin
      new_tag [tag_ram_bank_id].dir   = chosen_mshr_entry[tag_ram_bank_id].dir_entry;

      if(chosen_mshr_entry[tag_ram_bank_id].need_to_update_dir) begin
        // remove inv_snp or evcit/wb caches from sharer_list
        new_tag[tag_ram_bank_id].dir.sharer_list = chosen_mshr_entry[tag_ram_bank_id].dir_entry.sharer_list &
                                                   ~((chosen_mshr_entry[tag_ram_bank_id].snp_resp_receiving_list | chosen_mshr_entry[tag_ram_bank_id].snp_data_receiving_list) & {PRIVATE_CACHE_NUM{chosen_mshr_entry[tag_ram_bank_id].need_invalid_snp}}) &
                                                   ~chosen_mshr_entry[tag_ram_bank_id].evict_resp_receiving_list;

        // add new sharer into sharer_list, and set/unset owener bit
        unique case(chosen_mshr_entry[tag_ram_bank_id].req.rtype)
          ReadShared: begin
            new_tag[tag_ram_bank_id].dir.has_owner = ~(|(chosen_mshr_entry[tag_ram_bank_id].dir_entry.sharer_list));
            new_tag[tag_ram_bank_id].dir.sharer_list |= ((PRIVATE_CACHE_NUM'(1<<chosen_mshr_entry[tag_ram_bank_id].req.id.cid)) & ~chosen_mshr_entry[tag_ram_bank_id].evict_resp_receiving_list);
          end
          ReadUnique: begin
            new_tag[tag_ram_bank_id].dir.has_owner = 1'b1;
            new_tag[tag_ram_bank_id].dir.sharer_list |= ((PRIVATE_CACHE_NUM'(1<<chosen_mshr_entry[tag_ram_bank_id].req.id.cid)) & ~chosen_mshr_entry[tag_ram_bank_id].evict_resp_receiving_list);
          end
          CleanUnique: begin
            new_tag[tag_ram_bank_id].dir.has_owner = ~chosen_mshr_entry[tag_ram_bank_id].the_permission_dropped;
            new_tag[tag_ram_bank_id].dir.sharer_list |= (((PRIVATE_CACHE_NUM'(1<<chosen_mshr_entry[tag_ram_bank_id].req.id.cid)) & {PRIVATE_CACHE_NUM{~chosen_mshr_entry[tag_ram_bank_id].the_permission_dropped}})
                                                        & ~chosen_mshr_entry[tag_ram_bank_id].evict_resp_receiving_list);
          end
          Evict,
          WriteBackFull,
          WriteBackPartial: begin
            new_tag[tag_ram_bank_id].dir.has_owner = 1'b0;
          end
          default:begin
          end
        endcase

      end
    end
  end
endgenerate



// ---------------
// resp_to_requestor_fifo
// ---------------
logic                   resp_to_requestor_fifo_dout_vld;
logic [MSHR_NUM_W-1:0]  resp_to_requestor_fifo_dout;
logic                   resp_to_requestor_fifo_re;

cache_scu_cc_resp_type_e resp_type_for_final_resp;

assign resp_to_requestor_fifo_re = resp_to_requestor_fifo_dout_vld & scu_pc_resp_rdy_i; // TODO: the resp from repl mshr has higher priority

mp_fifo
#(
  .payload_t          (logic[MSHR_NUM_W-1:0]  ),
  .ENQUEUE_WIDTH      (2                      ),
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
assign scu_pc_resp_o.id.cid     = mshr_q[resp_to_requestor_fifo_dout].wait_for_wb_data_en ? mshr_q[resp_to_requestor_fifo_dout].wb_pc_id.cid :
                                                                                            mshr_q[resp_to_requestor_fifo_dout].req.id.cid;
assign scu_pc_resp_o.id.bid     = mshr_q[resp_to_requestor_fifo_dout].wait_for_wb_data_en ? mshr_q[resp_to_requestor_fifo_dout].wb_pc_id.bid :
                                                                                            mshr_q[resp_to_requestor_fifo_dout].req.id.bid;
assign scu_pc_resp_o.id.pc_tid  = mshr_q[resp_to_requestor_fifo_dout].wait_for_wb_data_en ? mshr_q[resp_to_requestor_fifo_dout].wb_pc_id.pc_tid :
                                                                                            mshr_q[resp_to_requestor_fifo_dout].req.id.pc_tid;
assign scu_pc_resp_o.id.sid     = '0; // assign it outside scu
assign scu_pc_resp_o.id.scu_tid = {1'b0, (SCU_TID_W-1)'(resp_to_requestor_fifo_dout)};
assign scu_pc_resp_o.rtype      = mshr_q[resp_to_requestor_fifo_dout].wait_for_wb_data_en ? WriteBack_Ack : resp_type_for_final_resp;
assign scu_pc_resp_o.src_id     = '0;
assign scu_pc_resp_o.tgt_id     = '0;
`ifdef ENABLE_TXN_ID
assign scu_pc_resp_o.txn_id     = TxnID_Width'(scu_pc_resp_o.id);
`endif
`ifdef USE_QOS_VALUE
assign scu_pc_resp_o.qos_value  = '0;
`endif

always_comb begin
  resp_type_for_final_resp = Comp_UD;
  unique case(mshr_q[resp_to_requestor_fifo_dout].req.rtype)
    // ReadShared: begin
    //   if(|(mshr_q[resp_to_requestor_fifo_dout].dir_entry.sharer_list)) begin
    //     resp_type_for_final_resp = RespSepData_SC;
    //   end else begin
    //     resp_type_for_final_resp = RespSepData_UC;
    //   end
    // end
    // ReadOnce: begin
    //   resp_type_for_final_resp = RespSepData_I;
    // end
    // ReadUnique: begin
    //   resp_type_for_final_resp = RespSepData_UD;
    // end
    CleanUnique: begin
      resp_type_for_final_resp = Comp_UD;
    end
    default:begin
    end
  endcase
end


// ---------------
// data_to_requestor_fifo
// ---------------
logic                   data_to_requestor_fifo_dout_vld;
logic [MSHR_NUM_W-1:0]  data_to_requestor_fifo_dout;
logic                   data_to_requestor_fifo_re;

cache_scu_cc_data_type_e data_type_for_final_resp;

logic scu_pc_data_hsk;
assign scu_pc_data_hsk = scu_pc_data_vld_o & scu_pc_data_rdy_i;

mp_fifo
#(
  .payload_t          (logic[MSHR_NUM_W-1:0]  ),
  .ENQUEUE_WIDTH      (2                      ),
  .DEQUEUE_WIDTH      (1                      ),
  .DEPTH              (MSHR_NUM               ),
  .MUST_TAKEN_ALL     (1                      )
)
data_to_requestor_fifo_u
(
  // Enqueue
  .enqueue_vld_i          (data_to_requestor_fifo_we         ),
  .enqueue_payload_i      (data_to_requestor_fifo_din        ),
  .enqueue_rdy_o          (                                  ),
  // Dequeue
  .dequeue_vld_o          (data_to_requestor_fifo_dout_vld   ),
  .dequeue_payload_o      (data_to_requestor_fifo_dout       ),
  .dequeue_rdy_i          (data_to_requestor_fifo_re         ),
  
  .flush_i                (1'b0                             ),
  
  .clk                    (clk_i                            ),
  .rst                    (~rstn_i                          )
);

`ifdef SCU_TO_PRIVATE_CACHE_DATA_RESP_CRITICAL_WORD_FIRST
logic need_critical_word_first; // for now, only ReadShared/ReadOnce (load) use critical word first
logic critical_sent_q_or_no_critical;
logic critical_sent_q_and_common_part_can_send;

logic critical_sent_d, critical_sent_q;
logic critical_sent_set, critical_sent_clr;
logic critical_sent_ena;
logic [DATA_BURST_NUM-1:0] critical_word_mask;
logic [DATA_BURST_NUM-1:0] common_word_mask;

logic only_critical; // as the mshr only received the critical part from snp data resp, only send critical part to reqor
  `ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
assign only_critical = mshr_q[data_to_requestor_fifo_dout].critical_part_resp_enqueued & ~mshr_q[data_to_requestor_fifo_dout].critical_part_resp_done;
  `else
assign only_critical = '0;
  `endif


assign critical_sent_q_or_no_critical = critical_sent_q | ~need_critical_word_first;
assign data_to_requestor_fifo_re = scu_pc_data_hsk & (critical_sent_q_or_no_critical | only_critical);

assign need_critical_word_first = (mshr_q[data_to_requestor_fifo_dout].req.rtype == ReadShared) | 
                                  (mshr_q[data_to_requestor_fifo_dout].req.rtype == ReadOnce);

assign critical_sent_set = scu_pc_data_hsk & ~critical_sent_q_or_no_critical & ~only_critical; // for only_critical, as it is not closelt followed by the common part, no need to record the critical_sent state
assign critical_sent_clr = data_to_requestor_fifo_re;
assign critical_sent_ena = critical_sent_set | critical_sent_clr;
assign critical_sent_d   = (critical_sent_q | critical_sent_set) & ~critical_sent_clr;

std_dffre
  #(.WIDTH(1)) 
U_SCU_MSHR_critical_sent_REG
(
  .clk  (clk_i    ),
  .rstn (rstn_i   ),
  .en   (critical_sent_ena ),
  .d    (critical_sent_d   ),
  .q    (critical_sent_q   )
);

  `ifdef SCU_TO_PRIVATE_CACHE_DATA_WRITE_RESP_CLEAN_PART_ONLY
assign critical_word_mask = need_critical_word_first ?  (DATA_BURST_NUM'(1 << mshr_q[data_to_requestor_fifo_dout].req.addr[(LLC_OFFSET_WIDTH-1)-:DATA_BURST_NUM_W]) & 
                                                          mshr_q[data_to_requestor_fifo_dout].data_valid) & 
                                                          ~(mshr_q[data_to_requestor_fifo_dout].req.data_part_to_be_fully_write & {DATA_BURST_NUM{(mshr_q[data_to_requestor_fifo_dout].req.rtype == ReadUnique)}}) :
                                                        '0;
assign common_word_mask   = need_critical_word_first ?  (~critical_word_mask & mshr_q[data_to_requestor_fifo_dout].data_valid) & 
                                                          ~(mshr_q[data_to_requestor_fifo_dout].req.data_part_to_be_fully_write & {DATA_BURST_NUM{(mshr_q[data_to_requestor_fifo_dout].req.rtype == ReadUnique)}}) : 
                                                        mshr_q[data_to_requestor_fifo_dout].data_valid &
                                                          ~(mshr_q[data_to_requestor_fifo_dout].req.data_part_to_be_fully_write & {DATA_BURST_NUM{(mshr_q[data_to_requestor_fifo_dout].req.rtype == ReadUnique)}});
  `else
assign critical_word_mask = need_critical_word_first ? DATA_BURST_NUM'(1 << mshr_q[data_to_requestor_fifo_dout].req.addr[(LLC_OFFSET_WIDTH-1)-:DATA_BURST_NUM_W]) & mshr_q[data_to_requestor_fifo_dout].data_valid : '0;
assign common_word_mask   = need_critical_word_first ? ~critical_word_mask & mshr_q[data_to_requestor_fifo_dout].data_valid : mshr_q[data_to_requestor_fifo_dout].data_valid;
  `endif


assign scu_pc_data_vld_o  = data_to_requestor_fifo_dout_vld & (~critical_sent_q | critical_sent_q & critical_sent_q_and_common_part_can_send);
assign scu_pc_data_o.id.cid     = mshr_q[data_to_requestor_fifo_dout].req.id.cid;
assign scu_pc_data_o.id.bid     = mshr_q[data_to_requestor_fifo_dout].req.id.bid;
assign scu_pc_data_o.id.pc_tid  = mshr_q[data_to_requestor_fifo_dout].req.id.pc_tid;
assign scu_pc_data_o.id.sid     = '0; // assign it outside scu
assign scu_pc_data_o.id.scu_tid = {1'b0, (SCU_TID_W-1)'(data_to_requestor_fifo_dout)};
assign scu_pc_data_o.rtype      = data_type_for_final_resp;

  `ifdef SET_INVALID_DATA_PART_ZERO_EN
generate
  for(genvar burst_id = 0; burst_id < DATA_BURST_NUM; burst_id++) begin
    assign scu_pc_data_o.data[burst_id] = critical_sent_q_or_no_critical ? mshr_q[data_to_requestor_fifo_dout].data[burst_id] & {DATA_LENGTH_PER_PKG{common_word_mask[burst_id]}} :
                                                                           mshr_q[data_to_requestor_fifo_dout].data[burst_id] & {DATA_LENGTH_PER_PKG{critical_word_mask[burst_id]}};
  end
endgenerate
  `else
assign scu_pc_data_o.data       = mshr_q[data_to_requestor_fifo_dout].data;
  `endif

assign scu_pc_data_o.data_valid = critical_sent_q_or_no_critical ? common_word_mask : critical_word_mask;
assign scu_pc_data_o.data_dirty = mshr_q[data_to_requestor_fifo_dout].data_dirty;

assign scu_pc_data_o.is_critical      = ~critical_sent_q_or_no_critical;
assign scu_pc_data_o.has_another_part = critical_sent_q_or_no_critical ? (|critical_word_mask) : ((|common_word_mask) | only_critical);

assign scu_pc_data_o.src_id     = '0;
assign scu_pc_data_o.tgt_id     = '0;
  `ifdef ENABLE_TXN_ID
assign scu_pc_data_o.txn_id     = TxnID_Width'(scu_pc_data_o.id);
  `endif
  `ifdef USE_QOS_VALUE
assign scu_pc_data_o.qos_value  = critical_sent_q_or_no_critical ? '0 : '1;
  `endif



  `ifndef SYNTHESIS
assert property(@(posedge clk_i)disable iff(~rstn_i) ((critical_sent_clr & critical_sent_set) == '0))
  else $fatal("scu_mshr: set and clr critical_sent at the same cycle for a mshr");
assert property(@(posedge clk_i)disable iff(~rstn_i) (only_critical) |-> (need_critical_word_first))
  else $fatal("scu_mshr: only_critical should only for the transaction that need_critical_word_first");
  `endif

  `ifdef COMMON_DATA_VALID_LATENCY_EN
logic [COMMON_DATA_VALID_LATENCY-1:0] common_data_valid_delay;
logic                                 common_data_valid_delay_ena;

generate
  for(genvar di = 1; di < COMMON_DATA_VALID_LATENCY; di++) begin: gen_common_data_valid_delay
    std_dffre
      #(.WIDTH(1)) 
    U_SCU_MSHR_common_data_valid_delay_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (common_data_valid_delay_ena ),
      .d    (common_data_valid_delay[di-1] ),
      .q    (common_data_valid_delay[di]   )
    );
  end
endgenerate

assign common_data_valid_delay_ena  = critical_sent_set | (data_to_requestor_fifo_dout_vld & critical_sent_q);
assign common_data_valid_delay  [0] = critical_sent_set | (critical_sent_q & scu_pc_data_vld_o & ~scu_pc_data_rdy_i); // other than critical_sent_set, if the critical_sent_q_and_common_part_can_send set but hsk failed because of ready_i low, reassign the critical_sent_q_and_common_part_can_send;
assign critical_sent_q_and_common_part_can_send = common_data_valid_delay[COMMON_DATA_VALID_LATENCY-1];
  `else
assign critical_sent_q_and_common_part_can_send = '1;
  `endif


`else
assign data_to_requestor_fifo_re = scu_pc_data_hsk;

assign scu_pc_data_vld_o  = data_to_requestor_fifo_dout_vld;
assign scu_pc_data_o.id.cid     = mshr_q[data_to_requestor_fifo_dout].req.id.cid;
assign scu_pc_data_o.id.bid     = mshr_q[data_to_requestor_fifo_dout].req.id.bid;
assign scu_pc_data_o.id.pc_tid  = mshr_q[data_to_requestor_fifo_dout].req.id.pc_tid;
assign scu_pc_data_o.id.sid     = '0; // assign it outside scu
assign scu_pc_data_o.id.scu_tid = {1'b0, (SCU_TID_W-1)'(data_to_requestor_fifo_dout)};
assign scu_pc_data_o.rtype      = data_type_for_final_resp;
assign scu_pc_data_o.data       = mshr_q[data_to_requestor_fifo_dout].data;


  `ifdef SCU_TO_PRIVATE_CACHE_DATA_WRITE_RESP_CLEAN_PART_ONLY
assign scu_pc_data_o.data_valid = mshr_q[data_to_requestor_fifo_dout].data_valid &
                                  ~(mshr_q[data_to_requestor_fifo_dout].req.data_part_to_be_fully_write & {DATA_BURST_NUM{(mshr_q[data_to_requestor_fifo_dout].req.rtype == ReadUnique)}});
  `else
assign scu_pc_data_o.data_valid = mshr_q[data_to_requestor_fifo_dout].data_valid;
  `endif

assign scu_pc_data_o.data_dirty = mshr_q[data_to_requestor_fifo_dout].data_dirty;

assign scu_pc_data_o.src_id     = '0;
assign scu_pc_data_o.tgt_id     = '0;
  `ifdef ENABLE_TXN_ID
assign scu_pc_data_o.txn_id     = TxnID_Width'(scu_pc_data_o.id);
  `endif
  `ifdef USE_QOS_VALUE
assign scu_pc_data_o.qos_value  = '0;
  `endif
`endif

always_comb begin
  data_type_for_final_resp = CompData_I;
  unique case(mshr_q[data_to_requestor_fifo_dout].req.rtype)
    ReadShared: begin
      if(|(mshr_q[data_to_requestor_fifo_dout].dir_entry.sharer_list)) begin
        data_type_for_final_resp = CompData_SC;
      end else begin
        data_type_for_final_resp = CompData_UC;
      end
    end
    ReadOnce: begin
      data_type_for_final_resp = CompData_I;
    end
    ReadUnique: begin
      data_type_for_final_resp = CompData_UD;
    end
    default:begin
    end
  endcase
end


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

  // data resp from mem
  if(mem_if_rvalid_i) begin
    mshr_ena[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].data[mshr_q[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].mem_resp_data_seg_wr_ptr]  = 1'b1;
    mshr_ena[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].data_valid                 = 1'b1;
    mshr_ena[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].mem_resp_data_seg_wr_ptr   = 1'b1;
    mshr_ena[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].wait_for_mem_read_data_en  = mem_if_r_i.rlast;

    mshr_d[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].data[mshr_q[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].mem_resp_data_seg_wr_ptr] = mem_if_r_i.dat;
    mshr_d[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].data_valid = mshr_q[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].data_valid | DATA_BURST_NUM'(1<<mshr_q[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].mem_resp_data_seg_wr_ptr);
    mshr_d[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].mem_resp_data_seg_wr_ptr   = mshr_q[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].mem_resp_data_seg_wr_ptr + 1;
    mshr_d[mem_if_r_i.rid.tid[MSHR_NUM_W-1:0]].wait_for_mem_read_data_en  = 1'b0;
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
`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].writeback_data_received = ~pc_scu_data_i.has_another_part |
                                                                                  (~pc_scu_data_i.is_critical & pc_scu_data_i.has_another_part & mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].critical_received_wait_for_common) |
                                                                                  (pc_scu_data_i.is_critical & pc_scu_data_i.has_another_part & mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].common_received_wait_for_critical);
`else
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].writeback_data_received = 1'b1;
`endif
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].wait_for_wb_data_en = 1'b1;
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].need_to_update_data = 1'b1;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].critical_received_wait_for_common = 1'b1; // only when critical part received and need to wait for common part, the mlfb should resp the critical word first transaction, other condition only need common refill transaction
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].common_received_wait_for_critical = 1'b1; // rare: common part comes ahead of critical part, wait for critical part and do common refill transaction
    mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].critical_part_resp_enqueued = pc_scu_data_i.is_critical & pc_scu_data_i.has_another_part & ~mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].common_received_wait_for_critical; // mshr_d.critical_received_wait_for_common set;
`endif

    for(int burst_id = 0; burst_id < DATA_BURST_NUM; burst_id++) begin
      if(pc_scu_data_i.data_valid[burst_id]) begin
        mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data [burst_id] = pc_scu_data_i.data[burst_id];
      end
    end
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_valid |= (mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_valid | pc_scu_data_i.data_valid);
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_dirty |= (mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].data_dirty | (pc_scu_data_i.data_dirty & pc_scu_data_i.data_valid));
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].writeback_data_received = 1'b1;
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].wait_for_wb_data_en = 1'b0;
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].need_to_update_data = 1'b1;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
    // only when critical part received and need to wait for common part, the mlfb should resp the critical word first transaction, other condition only need common refill transaction
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].critical_received_wait_for_common = (mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].critical_received_wait_for_common | // ori
                                                                                           (pc_scu_data_i.is_critical & pc_scu_data_i.has_another_part & ~mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].common_received_wait_for_critical)) & // set
                                                                                          ~(~pc_scu_data_i.is_critical & pc_scu_data_i.has_another_part); // clr
    // rare: common part comes ahead of critical part, wait for critical part and do common refill transaction
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].common_received_wait_for_critical = (mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].common_received_wait_for_critical | // ori
                                                                                           (~pc_scu_data_i.is_critical & pc_scu_data_i.has_another_part & ~mshr_q[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].critical_received_wait_for_common)) & // set
                                                                                          ~(pc_scu_data_i.is_critical & pc_scu_data_i.has_another_part); // clr
    mshr_d[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].critical_part_resp_enqueued = 1'b1;
`endif

    unique case(pc_scu_data_i.rtype)
      SnpAck_FoundM: begin
`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
        mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_data_receiving_list = mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].writeback_data_received;
`else
        mshr_ena[pc_scu_data_i.id.scu_tid[SCU_TID_W-1-1:0]].snp_data_receiving_list  = 1'b1;
`endif

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

      mshr_d[snp_to_cache_fifo_dout].snp_sent_list  = mshr_q[snp_to_cache_fifo_dout].snp_sent_list | PRIVATE_CACHE_NUM'(1<<snp_need_to_send_list_sel_idx);
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

      FinishTrans_Ack: begin
        mshr_ena[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].wait_for_resp_ack = 1'b1;

        mshr_d[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].wait_for_resp_ack = 1'b0;
      end

      // reqor: req a Cleanunique, but it was inv snped before it get Unique permission, so it kept to be invalid
      FinishTrans_Ack_I: begin
        mshr_ena[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].wait_for_resp_ack = 1'b1;
        mshr_ena[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].the_permission_dropped = 1'b1;

        mshr_d[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].wait_for_resp_ack = 1'b0;
        mshr_d[pc_scu_resp_i.id.scu_tid[SCU_TID_W-1-1:0]].the_permission_dropped = 1'b1;
      end

      default: begin
      end
    endcase
  end

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
  // scu critical data resp to reqor from critical snp data sent
  if(scu_pc_data_hsk & only_critical) begin
    mshr_ena[data_to_requestor_fifo_dout].critical_part_resp_done = 1'b1;
    
    mshr_d[data_to_requestor_fifo_dout].critical_part_resp_done = 1'b1;
  end
`endif

  // scu final resp enqueued
  if(mshr_at_resp_stage_enqueue_valid) begin
    mshr_ena[mshr_at_resp_stage_id].final_resp_enqueued = 1'b1;

    mshr_d[mshr_at_resp_stage_id].final_resp_enqueued = 1'b1;
  end

  // scu final data, tag, dir ram write enqueued
  if( mshr_at_write_data_ram_stage_enqueue_valid |
      mshr_at_write_tag_ram_stage_enqueue_valid  |
      mshr_at_write_state_dir_reg_stage_enqueue_valid) begin

    mshr_ena[mshr_at_final_write_stage_id].final_update_enqueued = 1'b1;

    mshr_d[mshr_at_final_write_stage_id].final_update_enqueued = 1'b1;
  end

  // scu final data write done
  for(int data_ram_bank_id = 0; data_ram_bank_id <  LLC_DATA_RAM_BANK_NUM; data_ram_bank_id++) begin
    if(req_to_write_data_ram_fifo_re[data_ram_bank_id]) begin
      mshr_ena[req_to_write_data_ram_fifo_dout[data_ram_bank_id]].need_to_update_data = 1'b1;

      mshr_d  [req_to_write_data_ram_fifo_dout[data_ram_bank_id]].need_to_update_data = 1'b0;
    end
  end

  // scu final tag and dir write done
  for(int tag_ram_bank_id = 0; tag_ram_bank_id <  LLC_TAG_RAM_BANK_NUM; tag_ram_bank_id++) begin
    if(req_to_write_tag_ram_fifo_re[tag_ram_bank_id]) begin
      mshr_ena[req_to_write_tag_ram_fifo_dout[tag_ram_bank_id]].need_to_update_tag = 1'b1;
      mshr_ena[req_to_write_tag_ram_fifo_dout[tag_ram_bank_id]].need_to_update_dir = 1'b1;

      mshr_d  [req_to_write_tag_ram_fifo_dout[tag_ram_bank_id]].need_to_update_tag = 1'b0;
      mshr_d  [req_to_write_tag_ram_fifo_dout[tag_ram_bank_id]].need_to_update_dir = 1'b0;
    end
  end
end


// ---------------
// ready out signals
// ---------------
assign pc_scu_resp_rdy_o  = 1'b1;
assign pc_scu_evict_rdy_o = 1'b1;
assign pc_scu_data_rdy_o  = 1'b1;
assign mem_if_rready_o    = 1'b1;


// ---------------
// mshr ff logic
// ---------------
generate
  for(genvar mshr_id = 0; mshr_id < MSHR_NUM; mshr_id++) begin
    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_llc_hit_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].llc_hit ),
      .d    (mshr_d[mshr_id].llc_hit   ),
      .q    (mshr_q[mshr_id].llc_hit   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_dir_hit_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].dir_hit ),
      .d    (mshr_d[mshr_id].dir_hit   ),
      .q    (mshr_q[mshr_id].dir_hit   )
    );

    std_dffre
    #(.WIDTH($bits(cache_scu_cc_req_t))) 
    U_SCU_MSHR_req_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].req ),
      .d    (mshr_d[mshr_id].req   ),
      .q    (mshr_q[mshr_id].req   )
    );

    std_dffre
    #(.WIDTH($bits(cache_cc_req_tid_t))) 
    U_SCU_MSHR_wb_pc_id_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wb_pc_id ),
      .d    (mshr_d[mshr_id].wb_pc_id   ),
      .q    (mshr_q[mshr_id].wb_pc_id   )
    );

    std_dffre
    #(.WIDTH($bits(cache_scu_cc_req_type_e))) 
    U_SCU_MSHR_wb_rtype_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wb_rtype ),
      .d    (mshr_d[mshr_id].wb_rtype   ),
      .q    (mshr_q[mshr_id].wb_rtype   )
    );

    std_dffre
    #(.WIDTH($bits(scu_dir_entry_t))) 
    U_SCU_MSHR_dir_entry_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].dir_entry ),
      .d    (mshr_d[mshr_id].dir_entry   ),
      .q    (mshr_q[mshr_id].dir_entry   )
    );

    std_dffre
    #(.WIDTH($bits(scu_llc_line_state_t))) 
    U_SCU_MSHR_state_entry_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].state_entry ),
      .d    (mshr_d[mshr_id].state_entry   ),
      .q    (mshr_q[mshr_id].state_entry   )
    );

    std_dffre
    #(.WIDTH(LLC_WAY_NUM)) 
    U_SCU_MSHR_valid_tags_compare_result_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].valid_tags_compare_result ),
      .d    (mshr_d[mshr_id].valid_tags_compare_result   ),
      .q    (mshr_q[mshr_id].valid_tags_compare_result   )
    );


    for(genvar data_seg_id = 0; data_seg_id < DATA_BURST_NUM; data_seg_id++) begin
      std_dffre
      #(.WIDTH(DATA_LENGTH_PER_PKG)) 
      U_SCU_MSHR_data_REG
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
    U_SCU_MSHR_data_valid_REG
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

    std_dffre
    #(.WIDTH(DATA_BURST_NUM_W)) 
    U_SCU_MSHR_mem_resp_data_seg_wr_ptr_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].mem_resp_data_seg_wr_ptr ),
      .d    (mshr_d[mshr_id].mem_resp_data_seg_wr_ptr   ),
      .q    (mshr_q[mshr_id].mem_resp_data_seg_wr_ptr   )
    );


    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_MSHR_snp_need_to_send_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].snp_need_to_send_list ),
      .d    (mshr_d[mshr_id].snp_need_to_send_list   ),
      .q    (mshr_q[mshr_id].snp_need_to_send_list   )
    );

    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_MSHR_snp_sent_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].snp_sent_list ),
      .d    (mshr_d[mshr_id].snp_sent_list   ),
      .q    (mshr_q[mshr_id].snp_sent_list   )
    );

    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_MSHR_snp_resp_receiving_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].snp_resp_receiving_list ),
      .d    (mshr_d[mshr_id].snp_resp_receiving_list   ),
      .q    (mshr_q[mshr_id].snp_resp_receiving_list   )
    );

    std_dffre
    #(.WIDTH(PRIVATE_CACHE_NUM)) 
    U_SCU_MSHR_snp_data_receiving_list_REG
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
    U_SCU_MSHR_evict_resp_receiving_list_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].evict_resp_receiving_list ),
      .d    (mshr_d[mshr_id].evict_resp_receiving_list   ),
      .q    (mshr_q[mshr_id].evict_resp_receiving_list   )
    );

    std_dffre
    #(.WIDTH(1))
    U_SCU_MSHR_writeback_data_received_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].writeback_data_received ),
      .d    (mshr_d[mshr_id].writeback_data_received   ),
      .q    (mshr_q[mshr_id].writeback_data_received   )
    );

    std_dffre
    #(.WIDTH(1))
    U_SCU_MSHR_wait_for_wb_data_en_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wait_for_wb_data_en ),
      .d    (mshr_d[mshr_id].wait_for_wb_data_en   ),
      .q    (mshr_q[mshr_id].wait_for_wb_data_en   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_wait_for_mem_read_data_en_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wait_for_mem_read_data_en ),
      .d    (mshr_d[mshr_id].wait_for_mem_read_data_en   ),
      .q    (mshr_q[mshr_id].wait_for_mem_read_data_en   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_wait_for_llc_read_data_en_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wait_for_llc_read_data_en ),
      .d    (mshr_d[mshr_id].wait_for_llc_read_data_en   ),
      .q    (mshr_q[mshr_id].wait_for_llc_read_data_en   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_need_invalid_snp_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].need_invalid_snp ),
      .d    (mshr_d[mshr_id].need_invalid_snp   ),
      .q    (mshr_q[mshr_id].need_invalid_snp   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_need_shared_snp_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].need_shared_snp ),
      .d    (mshr_d[mshr_id].need_shared_snp   ),
      .q    (mshr_q[mshr_id].need_shared_snp   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_final_update_enqueued_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].final_update_enqueued ),
      .d    (mshr_d[mshr_id].final_update_enqueued   ),
      .q    (mshr_q[mshr_id].final_update_enqueued   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_need_to_update_data_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].need_to_update_data ),
      .d    (mshr_d[mshr_id].need_to_update_data   ),
      .q    (mshr_q[mshr_id].need_to_update_data   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_need_to_update_tag_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].need_to_update_tag ),
      .d    (mshr_d[mshr_id].need_to_update_tag   ),
      .q    (mshr_q[mshr_id].need_to_update_tag   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_need_to_update_dir_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].need_to_update_dir ),
      .d    (mshr_d[mshr_id].need_to_update_dir   ),
      .q    (mshr_q[mshr_id].need_to_update_dir   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_monitor_evict_before_update_dir_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].monitor_evict_before_update_dir ),
      .d    (mshr_d[mshr_id].monitor_evict_before_update_dir   ),
      .q    (mshr_q[mshr_id].monitor_evict_before_update_dir   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_monitor_evict_before_receiving_all_snp_resp_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].monitor_evict_before_receiving_all_snp_resp ),
      .d    (mshr_d[mshr_id].monitor_evict_before_receiving_all_snp_resp   ),
      .q    (mshr_q[mshr_id].monitor_evict_before_receiving_all_snp_resp   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_monitor_writeback_before_receiving_all_snp_resp_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].monitor_writeback_before_receiving_all_snp_resp ),
      .d    (mshr_d[mshr_id].monitor_writeback_before_receiving_all_snp_resp   ),
      .q    (mshr_q[mshr_id].monitor_writeback_before_receiving_all_snp_resp   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_final_resp_sent_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].final_resp_enqueued ),
      .d    (mshr_d[mshr_id].final_resp_enqueued   ),
      .q    (mshr_q[mshr_id].final_resp_enqueued   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_wait_for_resp_ack_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].wait_for_resp_ack ),
      .d    (mshr_d[mshr_id].wait_for_resp_ack   ),
      .q    (mshr_q[mshr_id].wait_for_resp_ack   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_the_permission_dropped_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].the_permission_dropped ),
      .d    (mshr_d[mshr_id].the_permission_dropped   ),
      .q    (mshr_q[mshr_id].the_permission_dropped   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_mshr_valid_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_valid_ena[mshr_id] ),
      .d    (mshr_valid_d  [mshr_id] ),
      .q    (mshr_valid_q  [mshr_id] )
    );

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_critical_received_wait_for_common_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].critical_received_wait_for_common ),
      .d    (mshr_d[mshr_id].critical_received_wait_for_common   ),
      .q    (mshr_q[mshr_id].critical_received_wait_for_common   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_common_received_wait_for_critical_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].common_received_wait_for_critical ),
      .d    (mshr_d[mshr_id].common_received_wait_for_critical   ),
      .q    (mshr_q[mshr_id].common_received_wait_for_critical   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_critical_part_resp_enqueued_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].critical_part_resp_enqueued ),
      .d    (mshr_d[mshr_id].critical_part_resp_enqueued   ),
      .q    (mshr_q[mshr_id].critical_part_resp_enqueued   )
    );

    std_dffre
    #(.WIDTH(1)) 
    U_SCU_MSHR_critical_part_resp_done_REG
    (
      .clk  (clk_i    ),
      .rstn (rstn_i   ),
      .en   (mshr_ena[mshr_id].critical_part_resp_done ),
      .d    (mshr_d[mshr_id].critical_part_resp_done   ),
      .q    (mshr_q[mshr_id].critical_part_resp_done   )
    );
`endif

  end
endgenerate

`ifndef SYNTHESIS
  assert property(@(posedge clk_i)disable iff(~rstn_i) (new_mshr_valid_i)|-> (~mshr_valid_q[new_mshr_id_i]))
    else $fatal("mshr: set new_mshr entry to a valid entry");
`endif
endmodule
