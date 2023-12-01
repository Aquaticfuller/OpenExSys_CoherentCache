// Copyright 2021 RISC-V International Open Source Laboratory (RIOS Lab). All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.


module rvh_l1d_ewrq
  import rvh_pkg::*;
  // import uop_encoding_pkg::*;
  import rvh_l1d_cc_pkg::*;
  import rvh_l1d_pkg::*;
  import rvh_noc_pkg::*;
  import rvh_uncore_param_pkg::*;
#(
  parameter int BANK_ID=0,
  parameter int CORE_ID=0
)
(
  //------------------------------------------------------
  // new ewrq req
  input  logic                      l1d_ewrq_new_ewrq_valid_i,
  input  logic                      l1d_ewrq_new_writeback_valid_i,
  input  logic [L1D_BANK_LINE_ADDR_SIZE-1:0] l1d_ewrq_new_ewrq_addr_i,
  input  logic [L1D_BANK_LINE_DATA_SIZE-1:0] l1d_ewrq_new_ewrq_dat_i,
// `ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
  input  rrv64_l1d_lst_req_t        l1d_ewrq_new_ewrq_lst_i,
// `endif
  output logic                      l1d_ewrq_new_ewrq_ready_o,

  // output data and valid
  output logic[N_EWRQ-1:0][L1D_BANK_LINE_ADDR_SIZE-1:0] ewrq_addr_o,
  output logic[N_EWRQ-1:0]                     ewrq_vld_o,

  // cache rx port, scu -> private cache
    // resp
  input  logic                        scu_pc_resp_vld_i,
  input  cache_scu_cc_resp_t          scu_pc_resp_i,
  output logic                        scu_pc_resp_rdy_o,
  
  // cache tx port, private cache -> scu
    // evict/wb
  output logic                        pc_scu_evict_vld_o,
  output cache_scu_cc_req_t           pc_scu_evict_o,
  input  logic                        pc_scu_evict_rdy_i,

    // data
  output logic                        pc_scu_data_vld_o,
  output cache_scu_cc_data_t          pc_scu_data_o,
  input  logic                        pc_scu_data_rdy_i,


  // else
  input  logic              rst, clk
);

  typedef struct packed {
    logic [L1D_BANK_LINE_ADDR_SIZE-1:0] line_addr;
    logic [L1D_BANK_LINE_DATA_SIZE-1:0] data;
    logic                               data_valid;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
    rrv64_l1d_lst_req_t                 lst_dat;
`endif
  } ewrq_entry_t;


  //==========================================================
  // command fifo
  // {{{
  logic aw_fifo_re, aw_fifo_we;
  logic w_fifo_re;

  logic aw_fifo_sent_d, aw_fifo_sent_q;
  logic aw_fifo_sent_clr, aw_fifo_sent_set;
  logic aw_fifo_sent_ena;
  logic aw_fifo_wb_ack_received_d, aw_fifo_wb_ack_received_q;
  logic aw_fifo_wb_ack_received_clr, aw_fifo_wb_ack_received_set;
  logic aw_fifo_wb_ack_received_ena;
  
  logic [SCU_TID_W-1:0] scu_tid_d, scu_tid_q;
  logic [SCU_SLICE_NUM_W-1:0] scu_sid_d, scu_sid_q;
  logic scu_tid_ena;

  ewrq_entry_t aw_fifo_din, aw_fifo_dout;
  ewrq_entry_t [N_EWRQ-1:0] ewrq_entry;
  logic [N_EWRQ-1:0] ewrq_entry_valid;

  generate
    for(genvar ewrq_id = 0; ewrq_id < N_EWRQ; ewrq_id++) begin
      assign ewrq_addr_o[ewrq_id] = ewrq_entry[ewrq_id].line_addr;
      assign ewrq_vld_o [ewrq_id] = ewrq_entry_valid[ewrq_id];
    end
  endgenerate

  logic aw_fifo_not_empty;
  logic aw_fifo_enqueue_rdy;

  assign l1d_ewrq_new_ewrq_ready_o = aw_fifo_enqueue_rdy;

  // write address command fifo{{{
  sp_fifo_dat_vld_output
  #(
    .payload_t      (ewrq_entry_t),
    // .ENQUEUE_WIDTH  (1),
    // .DEQUEUE_WIDTH  (1),
    .DEPTH          (N_EWRQ),
    .MUST_TAKEN_ALL (1)
  )
  AW_FIFO_U
  (
    // Enqueue
    .enqueue_vld_i          (aw_fifo_we         ),
    .enqueue_payload_i      (aw_fifo_din        ),
    .enqueue_rdy_o          (aw_fifo_enqueue_rdy),
    // Dequeue
    .dequeue_vld_o          (aw_fifo_not_empty  ),
    .dequeue_payload_o      (aw_fifo_dout       ),
    .dequeue_rdy_i          (aw_fifo_re         ),
    
    // output data and valid
    .payload_dff            (ewrq_entry         ),
    .payload_vld_dff        (ewrq_entry_valid   ),

    .flush_i                (1'b0               ),
    
    .clk                    (clk),
    .rst                    (~rst)
  );


  //==========================================================
  // FIFO interface
  // {{{

  //==========================================================
  // aw fifo interface
  //==========================================================
  // Initiate a write back when a miss request occurs and the allocated $line is dirty, 
  // the allocated way_id is flop version of v.s3.way_id 
  assign aw_fifo_we  = l1d_ewrq_new_ewrq_valid_i & aw_fifo_enqueue_rdy & (l1d_ewrq_new_ewrq_lst_i != INVALID); // for a corner case, when a snp invalidate a line, but a refill was interrupted by the snp, the refill may try to writeback a invalid line
  // Allocated mshr entry ID for the req initiated the mem write 
  assign aw_fifo_din.line_addr  = l1d_ewrq_new_ewrq_addr_i;
  assign aw_fifo_din.data       = l1d_ewrq_new_ewrq_dat_i;
  assign aw_fifo_din.data_valid = l1d_ewrq_new_writeback_valid_i;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
  assign aw_fifo_din.lst_dat    = l1d_ewrq_new_ewrq_lst_i;
`endif
  // Proceed to next mem write when aw channel handshake completed
  assign aw_fifo_sent_set = pc_scu_evict_vld_o & pc_scu_evict_rdy_i;
  assign aw_fifo_sent_clr = aw_fifo_re;
  assign aw_fifo_sent_ena = aw_fifo_sent_set | aw_fifo_sent_clr;
  assign aw_fifo_sent_d   = (aw_fifo_sent_q | aw_fifo_sent_set) & ~aw_fifo_sent_clr;

  assign aw_fifo_wb_ack_received_set = aw_fifo_sent_q & scu_pc_resp_vld_i & (scu_pc_resp_i.rtype == WriteBack_Ack);
  assign aw_fifo_wb_ack_received_clr = aw_fifo_re;
  assign aw_fifo_wb_ack_received_ena = aw_fifo_wb_ack_received_set | aw_fifo_wb_ack_received_clr;
  assign aw_fifo_wb_ack_received_d   = (aw_fifo_wb_ack_received_q | aw_fifo_wb_ack_received_set) & ~aw_fifo_wb_ack_received_clr ;

  assign scu_tid_d   = scu_pc_resp_i.id.scu_tid;
  assign scu_sid_d   = scu_pc_resp_i.id.sid;
  assign scu_tid_ena = aw_fifo_wb_ack_received_set;

  assign aw_fifo_re  = w_fifo_re | (aw_fifo_sent_q & ~aw_fifo_dout.data_valid & aw_fifo_wb_ack_received_set);

  assign scu_pc_resp_rdy_o = '1;
  //==========================================================
  // w fifo interface
  //==========================================================
  assign w_fifo_re  = pc_scu_data_vld_o & pc_scu_data_rdy_i; 


  // }}}
  //==========================================================
  // Mem-NOC interface
  // {{{

  //==========================================================
  // AW channel
  //==========================================================
  assign pc_scu_evict_vld_o       = aw_fifo_not_empty & ~aw_fifo_sent_q;

  assign pc_scu_evict_o.id.cid    = CORE_ID;
  assign pc_scu_evict_o.id.bid    = {1'b0, BANK_ID[CACHE_MASTERID_W-1:0]}; // msb 1 represents d$;
  assign pc_scu_evict_o.id.pc_tid = '0;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
  assign pc_scu_evict_o.rtype     = aw_fifo_dout.data_valid ? WriteBackPartial : Evict;
`else
  assign pc_scu_evict_o.rtype     = aw_fifo_dout.data_valid ? WriteBackFull : Evict;
`endif
  assign pc_scu_evict_o.addr      = {aw_fifo_dout.line_addr, BANK_ID[L1D_BANK_ID_INDEX_WIDTH-1:0], {L1D_BANK_OFFSET_WIDTH{1'b0}}};

  assign pc_scu_evict_o.src_id     = '0;
  assign pc_scu_evict_o.tgt_id     = '0;
`ifdef ENABLE_TXN_ID
  assign pc_scu_evict_o.txn_id     = TxnID_Width'(pc_scu_evict_o.id);
`endif

`ifdef SCU_TO_PRIVATE_CACHE_DATA_WRITE_RESP_CLEAN_PART_ONLY
  assign pc_scu_evict_o.data_part_to_be_fully_write = '0; // not used in evict req
`endif

`ifdef USE_QOS_VALUE
  assign pc_scu_evict_o.qos_value  = '0;
`endif

  //==========================================================
  // W channel
  //==========================================================
  assign pc_scu_data_vld_o = aw_fifo_not_empty & aw_fifo_wb_ack_received_q & aw_fifo_dout.data_valid;

  assign pc_scu_data_o.id.cid     = CORE_ID;
  assign pc_scu_data_o.id.bid     = {1'b0, BANK_ID[CACHE_MASTERID_W-1:0]}; // msb 1 represents d$;
  assign pc_scu_data_o.id.pc_tid  = '0;
  assign pc_scu_data_o.id.scu_tid = scu_tid_q;
  assign pc_scu_data_o.id.sid     = scu_sid_q;
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
  assign pc_scu_data_o.rtype      = WriteBackPartialData;
`else
  assign pc_scu_data_o.rtype      = WriteBackFullData;
`endif
  generate
    for(genvar data_seg_id = 0; data_seg_id < DATA_BURST_NUM; data_seg_id++) begin
`ifdef SET_INVALID_DATA_PART_ZERO_EN
    assign pc_scu_data_o.data [data_seg_id] = aw_fifo_dout.data[data_seg_id*DATA_LENGTH_PER_PKG+:DATA_LENGTH_PER_PKG] & {DATA_LENGTH_PER_PKG{pc_scu_data_o.data_valid[data_seg_id]}};
`else
    assign pc_scu_data_o.data [data_seg_id] = aw_fifo_dout.data[data_seg_id*DATA_LENGTH_PER_PKG+:DATA_LENGTH_PER_PKG];
`endif
    end
  endgenerate
`ifdef PRIVATE_CACHE_TO_SCU_DATA_WRITEBACK_DIRTY_PART_ONLY
  assign pc_scu_data_o.data_valid = aw_fifo_dout.lst_dat.data_dirty;
  assign pc_scu_data_o.data_dirty = aw_fifo_dout.lst_dat.data_dirty;
`else
  assign pc_scu_data_o.data_valid = '1;
  assign pc_scu_data_o.data_dirty = '1;
`endif

`ifdef PRIVATE_CACHE_TO_SCU_DATA_RESP_CRITICAL_WORD_FIRST
  assign pc_scu_data_o.is_critical      = '0;
  assign pc_scu_data_o.has_another_part = '0;
`endif

  assign pc_scu_data_o.src_id     = '0;
  assign pc_scu_data_o.tgt_id     = '0;
`ifdef ENABLE_TXN_ID
  assign pc_scu_data_o.txn_id     = TxnID_Width'(pc_scu_data_o.id);
`endif
`ifdef USE_QOS_VALUE
  assign pc_scu_data_o.qos_value  = '0;
`endif

  //==========================================================

  always_ff @ (posedge clk or negedge rst) begin
    if (~rst) begin
      aw_fifo_sent_q            <= '0;
      aw_fifo_wb_ack_received_q <= '0;
      scu_tid_q                 <= '0;
      scu_sid_q                 <= '0;
    end else begin      
      if(aw_fifo_sent_ena) begin
        aw_fifo_sent_q <= aw_fifo_sent_d;
      end
      if(aw_fifo_wb_ack_received_ena) begin
        aw_fifo_wb_ack_received_q <= aw_fifo_wb_ack_received_d;
      end
      if(scu_tid_ena) begin
        scu_tid_q <= scu_tid_d;
        scu_sid_q <= scu_sid_d;
      end
    end
  end



`ifndef SYNTHESIS

  assert property(
    @(posedge clk) disable iff(~rst) (scu_pc_resp_vld_i && scu_pc_resp_rdy_o) |-> !$isunknown(scu_pc_resp_i)
  )
  else begin
    $fatal("");
  end

`endif

endmodule
