module ebi_tx
    import ebi_pkg::*;
    import rvh_l1d_cc_pkg::*;
    import rvh_noc_pkg::*;
    import rvh_uncore_param_pkg::*;
#(
    parameter TX_CHANNEL_NUM,
    parameter CHANNEL_NUM_WIDTH,
    parameter MAX_MESSAGE_LENGTH,
    parameter MAX_MESSAGE_WIDTH,
    parameter int unsigned CHANNEL_LENGTH_LIST[TX_CHANNEL_NUM]
)
(
    input if_clk,
    input bus_clk,
    input rst,
    input  ebi_type_union                                           channel_hs_entry,  // wire here
    input  logic [TX_CHANNEL_NUM-1:0]                               channel_entry_valid,  
    output logic [TX_CHANNEL_NUM-1:0]                               channel_push_ready,
    output logic  [OFF_DIE_WD-1:0]                                  bus_out,
    input  logic                                                    credit_in
);

logic send_success, send_fail; // indicates that message has been received without transmitting error
logic [TX_CHANNEL_NUM-1:0] vc_arb_valid_q, vc_arb_valid, send_ar_grt;
logic [CHANNEL_NUM_WIDTH-1:0] send_ar_grt_idx;
logic [CREDIT_WIDTH:0] send_credit_count;
logic en_recv_credit, en_message_bit_count;
credit_t credit_slot, asynced_credit; // this signal need to be synced to cache domain
recv_credit_state_t next_credit_state, credit_state;
logic recv_credit_synced;
logic send_next_one;
logic async_send_credit_fifo_empty;
ebi_type_union vc_entry_list;
logic [TX_CHANNEL_NUM-1:0] entry_send_success;
logic [MAX_MESSAGE_LENGTH-1:0] arbbed_message;
logic [2*OFF_DIE_WD + CHANNEL_NUM_WIDTH + MAX_MESSAGE_LENGTH-1:0] asynced_message;
logic async_message_send_fifo_empty;
logic [CHANNEL_NUM_WIDTH-1:0] channel_id;

send_state_t transmit_state, next_transmit_state;
logic [PARITY_WIDTH:0]  send_parity_count;
logic en_send_parity_count;
logic [MAX_MESSAGE_WIDTH:0] message_count;
logic [OFF_DIE_WD-1:0] parity_bit;
logic [OFF_DIE_WD-1:0] transmitting_bit;
logic all_message_transmitted;
logic [MAX_MESSAGE_WIDTH:0] message_length;
logic [CREDIT_LENGTH-1:0] credit_wire;
logic fifo_read_next_one;

`ifndef COMMON_QOS_EXTRA_RT_VC

assign entry_send_success = {TX_CHANNEL_NUM{(!async_send_credit_fifo_empty) & (asynced_credit == SUCCESS)}} & send_ar_grt; // the second term indicates that ar message is being transmitted    
                                                // send_next_one is 1 cycle later than this & iterm

always_ff @(posedge if_clk) begin
    if(rst) begin
        send_next_one <= 1'b1;
        fifo_read_next_one <= 1'b0;
    end else begin
        if((|vc_arb_valid) && send_next_one) begin
            send_next_one <= 1'b0;
            fifo_read_next_one <= 1'b1;
        end else if(fifo_read_next_one) begin
            fifo_read_next_one <= 1'b0;
        end else if((asynced_credit == SUCCESS) && (!async_send_credit_fifo_empty)) begin
            send_next_one <= 1'b1;
        end
    end
end


StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[0])
) u_send_vc_0 (
    .enq_vld_i(channel_entry_valid[0]),
    .enq_payload_i(channel_hs_entry.c0),
    .enq_rdy_o(channel_push_ready[0]),
    .deq_vld_o(vc_arb_valid[0]),
    .deq_payload_o(vc_entry_list.c0),
    .deq_rdy_i(entry_send_success[0]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[1])
) u_send_vc_1 (
    .enq_vld_i(channel_entry_valid[1]),
    .enq_payload_i(channel_hs_entry.c1),
    .enq_rdy_o(channel_push_ready[1]),
    .deq_vld_o(vc_arb_valid[1]),
    .deq_payload_o(vc_entry_list.c1),
    .deq_rdy_i(entry_send_success[1]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[2])
) u_send_vc_2 (
    .enq_vld_i(channel_entry_valid[2]),
    .enq_payload_i(channel_hs_entry.c2),
    .enq_rdy_o(channel_push_ready[2]),
    .deq_vld_o(vc_arb_valid[2]),
    .deq_payload_o(vc_entry_list.c2),
    .deq_rdy_i(entry_send_success[2]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[3])
) u_send_vc_3 (
    .enq_vld_i(channel_entry_valid[3]),
    .enq_payload_i(channel_hs_entry.c3),
    .enq_rdy_o(channel_push_ready[3]),
    .deq_vld_o(vc_arb_valid[3]),
    .deq_payload_o(vc_entry_list.c3),
    .deq_rdy_i(entry_send_success[3]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[4])
) u_send_vc_4 (
    .enq_vld_i(channel_entry_valid[4]),
    .enq_payload_i(channel_hs_entry.c4),
    .enq_rdy_o(channel_push_ready[4]),
    .deq_vld_o(vc_arb_valid[4]),
    .deq_payload_o(vc_entry_list.c4),
    .deq_rdy_i(entry_send_success[4]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[5])
) u_send_vc_5 (
    .enq_vld_i(channel_entry_valid[5]),
    .enq_payload_i(channel_hs_entry.c5),
    .enq_rdy_o(channel_push_ready[5]),
    .deq_vld_o(vc_arb_valid[5]),
    .deq_payload_o(vc_entry_list.c5),
    .deq_rdy_i(entry_send_success[5]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[6])
) u_send_vc_6 (
    .enq_vld_i(channel_entry_valid[6]),
    .enq_payload_i(channel_hs_entry.c6),
    .enq_rdy_o(channel_push_ready[6]),
    .deq_vld_o(vc_arb_valid[6]),
    .deq_payload_o(vc_entry_list.c6),
    .deq_rdy_i(entry_send_success[6]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[7])
) u_send_vc_7 (
    .enq_vld_i(channel_entry_valid[7]),
    .enq_payload_i(channel_hs_entry.c7),
    .enq_rdy_o(channel_push_ready[7]),
    .deq_vld_o(vc_arb_valid[7]),
    .deq_payload_o(vc_entry_list.c7),
    .deq_rdy_i(entry_send_success[7]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[8])
) u_send_vc_8 (
    .enq_vld_i(channel_entry_valid[8]),
    .enq_payload_i(channel_hs_entry.c8),
    .enq_rdy_o(channel_push_ready[8]),
    .deq_vld_o(vc_arb_valid[8]),
    .deq_payload_o(vc_entry_list.c8),
    .deq_rdy_i(entry_send_success[8]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[9])
) u_send_vc_9 (
    .enq_vld_i(channel_entry_valid[9]),
    .enq_payload_i(channel_hs_entry.c9),
    .enq_rdy_o(channel_push_ready[9]),
    .deq_vld_o(vc_arb_valid[9]),
    .deq_payload_o(vc_entry_list.c9),
    .deq_rdy_i(entry_send_success[9]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

always_ff @(posedge if_clk) begin
    if(rst) begin
        vc_arb_valid_q <= 'b0;
    end else begin
        if(send_next_one) begin
            vc_arb_valid_q <= vc_arb_valid;
        end
    end
end

one_hot_rr_arb #(
    .N_INPUT(TX_CHANNEL_NUM)
) vc_send_arb(
  .req_i        (vc_arb_valid_q   ),
  .update_i     (|vc_arb_valid_q), //when message is successfully transmitted, next message can be arbitted
  .grt_o        (send_ar_grt    ),
  .grt_idx_o    (send_ar_grt_idx),
  .rstn         (rst            ),
  .clk          (if_clk      )
);

assign arbbed_message = send_ar_grt_idx == 4'h0 ? vc_entry_list.c0  :
                        send_ar_grt_idx == 4'h1 ? vc_entry_list.c1  :
                        send_ar_grt_idx == 4'h2 ? vc_entry_list.c2  :
                        send_ar_grt_idx == 4'h3 ? vc_entry_list.c3  :
                        send_ar_grt_idx == 4'h4 ? vc_entry_list.c4  :
                        send_ar_grt_idx == 4'h5 ? vc_entry_list.c5  :
                        send_ar_grt_idx == 4'h6 ? vc_entry_list.c6  :
                        send_ar_grt_idx == 4'h7 ? vc_entry_list.c7  :
                        send_ar_grt_idx == 4'h8 ? vc_entry_list.c8  : vc_entry_list.c9;

`else 

ebi_type_union vc_entry_list_qos;
logic [4:0] vc_arb_valid_qos_q, vc_arb_valid_qos, send_ar_grt_qos_s1;
logic [4:0] channel_push_ready_common, channel_push_ready_qos, entry_send_success_qos;
logic [TX_CHANNEL_NUM-1:0] send_ar_grt_s1, send_ar_grt_s2, send_ar_grt_qos_s2;
logic [2:0] send_ar_grt_idx_qos_s1; 
logic [3:0] send_ar_grt_idx_qos_s2, send_ar_grt_idx_s1, send_ar_grt_idx_s2;

StreamFIFO #(
    .Depth((VC_ID_NUM_MAX-QOS_VC_NUM_PER_INPUT) * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[0])
) u_send_vc_0 (
    .enq_vld_i(channel_entry_valid[0] & (channel_hs_entry.c0[QoS_Value_Width-1:0] != '1)),
    .enq_payload_i(channel_hs_entry.c0),
    .enq_rdy_o(channel_push_ready_common[0]),
    .deq_vld_o(vc_arb_valid[0]),
    .deq_payload_o(vc_entry_list.c0),
    .deq_rdy_i(entry_send_success[0]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(QOS_VC_NUM_PER_INPUT * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[0])
) u_send_vc_0_qos (
    .enq_vld_i(channel_entry_valid[0] & (channel_hs_entry.c0[QoS_Value_Width-1:0] == '1)),
    .enq_payload_i(channel_hs_entry.c0),
    .enq_rdy_o(channel_push_ready_qos[0]),
    .deq_vld_o(vc_arb_valid_qos[0]),
    .deq_payload_o(vc_entry_list_qos.c0),
    .deq_rdy_i(entry_send_success_qos[0]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);
//
StreamFIFO #(
    .Depth((VC_ID_NUM_MAX-QOS_VC_NUM_PER_INPUT) * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[1])
) u_send_vc_1 (
    .enq_vld_i(channel_entry_valid[1] & (channel_hs_entry.c1[QoS_Value_Width-1:0] != '1)),
    .enq_payload_i(channel_hs_entry.c1),
    .enq_rdy_o(channel_push_ready_common[1]),
    .deq_vld_o(vc_arb_valid[1]),
    .deq_payload_o(vc_entry_list.c1),
    .deq_rdy_i(entry_send_success[1]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(QOS_VC_NUM_PER_INPUT * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[1])
) u_send_vc_1_qos (
    .enq_vld_i(channel_entry_valid[1] & (channel_hs_entry.c1[QoS_Value_Width-1:0] == '1)),
    .enq_payload_i(channel_hs_entry.c1),
    .enq_rdy_o(channel_push_ready_qos[1]),
    .deq_vld_o(vc_arb_valid_qos[1]),
    .deq_payload_o(vc_entry_list_qos.c1),
    .deq_rdy_i(entry_send_success_qos[1]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);
//
StreamFIFO #(
    .Depth((VC_ID_NUM_MAX-QOS_VC_NUM_PER_INPUT) * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[2])
) u_send_vc_2 (
    .enq_vld_i(channel_entry_valid[2] & (channel_hs_entry.c2[QoS_Value_Width-1:0] != '1)),
    .enq_payload_i(channel_hs_entry.c2),
    .enq_rdy_o(channel_push_ready_common[2]),
    .deq_vld_o(vc_arb_valid[2]),
    .deq_payload_o(vc_entry_list.c2),
    .deq_rdy_i(entry_send_success[2]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(QOS_VC_NUM_PER_INPUT * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[2])
) u_send_vc_2_qos (
    .enq_vld_i(channel_entry_valid[2] & (channel_hs_entry.c2[QoS_Value_Width-1:0] == '1)),
    .enq_payload_i(channel_hs_entry.c2),
    .enq_rdy_o(channel_push_ready_qos[2]),
    .deq_vld_o(vc_arb_valid_qos[2]),
    .deq_payload_o(vc_entry_list_qos.c2),
    .deq_rdy_i(entry_send_success_qos[2]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);
//
StreamFIFO #(
    .Depth((VC_ID_NUM_MAX-QOS_VC_NUM_PER_INPUT) * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[3])
) u_send_vc_3 (
    .enq_vld_i(channel_entry_valid[3] & (channel_hs_entry.c3[DATA_BURST_NUM_W+1 +: QoS_Value_Width] != '1)),
    .enq_payload_i(channel_hs_entry.c3),
    .enq_rdy_o(channel_push_ready_common[3]),
    .deq_vld_o(vc_arb_valid[3]),
    .deq_payload_o(vc_entry_list.c3),
    .deq_rdy_i(entry_send_success[3]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(QOS_VC_NUM_PER_INPUT * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[3])
) u_send_vc_3_qos (
    .enq_vld_i(channel_entry_valid[3] & (channel_hs_entry.c3[DATA_BURST_NUM_W+1 +: QoS_Value_Width] == '1)),
    .enq_payload_i(channel_hs_entry.c3),
    .enq_rdy_o(channel_push_ready_qos[3]),
    .deq_vld_o(vc_arb_valid_qos[3]),
    .deq_payload_o(vc_entry_list_qos.c3),
    .deq_rdy_i(entry_send_success_qos[3]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);
//
StreamFIFO #(
    .Depth((VC_ID_NUM_MAX-QOS_VC_NUM_PER_INPUT) * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[4])
) u_send_vc_4 (
    .enq_vld_i(channel_entry_valid[4] & (channel_hs_entry.c4[QoS_Value_Width-1:0] != '1)),
    .enq_payload_i(channel_hs_entry.c4),
    .enq_rdy_o(channel_push_ready_common[4]),
    .deq_vld_o(vc_arb_valid[4]),
    .deq_payload_o(vc_entry_list.c4),
    .deq_rdy_i(entry_send_success[4]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(QOS_VC_NUM_PER_INPUT * VC_DEPTH_MAX),
    .WordWidth(CHANNEL_LENGTH_LIST[4])
) u_send_vc_4_qos (
    .enq_vld_i(channel_entry_valid[4] & (channel_hs_entry.c4[QoS_Value_Width-1:0] == '1)),
    .enq_payload_i(channel_hs_entry.c4),
    .enq_rdy_o(channel_push_ready_qos[4]),
    .deq_vld_o(vc_arb_valid_qos[4]),
    .deq_payload_o(vc_entry_list_qos.c4),
    .deq_rdy_i(entry_send_success_qos[4]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);
//


StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[5])
) u_send_vc_5 (
    .enq_vld_i(channel_entry_valid[5]),
    .enq_payload_i(channel_hs_entry.c5),
    .enq_rdy_o(channel_push_ready[5]),
    .deq_vld_o(vc_arb_valid[5]),
    .deq_payload_o(vc_entry_list.c5),
    .deq_rdy_i(entry_send_success[5]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[6])
) u_send_vc_6 (
    .enq_vld_i(channel_entry_valid[6]),
    .enq_payload_i(channel_hs_entry.c6),
    .enq_rdy_o(channel_push_ready[6]),
    .deq_vld_o(vc_arb_valid[6]),
    .deq_payload_o(vc_entry_list.c6),
    .deq_rdy_i(entry_send_success[6]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[7])
) u_send_vc_7 (
    .enq_vld_i(channel_entry_valid[7]),
    .enq_payload_i(channel_hs_entry.c7),
    .enq_rdy_o(channel_push_ready[7]),
    .deq_vld_o(vc_arb_valid[7]),
    .deq_payload_o(vc_entry_list.c7),
    .deq_rdy_i(entry_send_success[7]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[8])
) u_send_vc_8 (
    .enq_vld_i(channel_entry_valid[8]),
    .enq_payload_i(channel_hs_entry.c8),
    .enq_rdy_o(channel_push_ready[8]),
    .deq_vld_o(vc_arb_valid[8]),
    .deq_payload_o(vc_entry_list.c8),
    .deq_rdy_i(entry_send_success[8]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

StreamFIFO #(
    .Depth(EBI_BUFFER_DEPTH),
    .WordWidth(CHANNEL_LENGTH_LIST[9])
) u_send_vc_9 (
    .enq_vld_i(channel_entry_valid[9]),
    .enq_payload_i(channel_hs_entry.c9),
    .enq_rdy_o(channel_push_ready[9]),
    .deq_vld_o(vc_arb_valid[9]),
    .deq_payload_o(vc_entry_list.c9),
    .deq_rdy_i(entry_send_success[9]),
    .flush_i(1'b0),
    .clk(if_clk),
    .rstn(~rst)
);

assign channel_push_ready[4:0] = channel_push_ready_common | channel_push_ready_qos;

// send_next_one still can work for different qos
always_ff @(posedge if_clk) begin
    if(rst) begin
        vc_arb_valid_q <= 'b0;
        vc_arb_valid_qos_q <= 'b0;
    end else begin
        if(send_next_one) begin
            vc_arb_valid_qos_q <= vc_arb_valid_qos;
            // vc_arb_valid_q <= (|vc_arb_valid_qos_q) ? vc_arb_valid_q : vc_arb_valid;  
            vc_arb_valid_q <= vc_arb_valid;  
        end
    end
end

one_hot_rr_arb #( // arbite the req without knowing resp | data condition
    .N_INPUT(TX_CHANNEL_NUM)
) vc_send_arb(
  .req_i        (vc_arb_valid_q ),
  .update_i     (|vc_arb_valid_q), 
  .grt_o        (send_ar_grt_s1   ),
  .grt_idx_o    (send_ar_grt_idx_s1),
  .rstn         (rst            ),
  .clk          (if_clk      )
);

assign send_ar_grt_s2 = vc_arb_valid_q[3] ? 10'h8 : vc_arb_valid_q[1] ? 10'h2 : send_ar_grt_s1;
assign send_ar_grt_idx_s2 = vc_arb_valid_q[3] ? 4'h3 : vc_arb_valid_q[1] ? 4'h1 : {1'b0, send_ar_grt_idx_s1};


one_hot_rr_arb #( // arbite the req without knowing resp | data condition
    .N_INPUT(5)
) vc_send_arb_qos(
  .req_i        (vc_arb_valid_qos_q ),
  .update_i     (|vc_arb_valid_qos_q),
  .grt_o        (send_ar_grt_qos_s1),
  .grt_idx_o    (send_ar_grt_idx_qos_s1),
  .rstn         (rst            ),
  .clk          (if_clk      )
);

assign send_ar_grt_qos_s2 = vc_arb_valid_qos_q[3] ? 10'h8 : vc_arb_valid_qos_q[1] ? 10'h2 : {5'b0, send_ar_grt_qos_s1};
assign send_ar_grt_idx_qos_s2 = vc_arb_valid_qos_q[3] ? 4'h3 : vc_arb_valid_qos_q[1] ? 4'h1 : {1'b0, send_ar_grt_idx_qos_s1};

assign send_ar_grt = (|vc_arb_valid_qos_q) ? send_ar_grt_qos_s2 : send_ar_grt_s2;
assign send_ar_grt_idx = (|vc_arb_valid_qos_q) ? send_ar_grt_idx_qos_s2 : send_ar_grt_idx_s2;

assign arbbed_message = (|vc_arb_valid_qos_q) ? 
                        (send_ar_grt_idx == 4'h0 ? vc_entry_list_qos.c0  :
                         send_ar_grt_idx == 4'h1 ? vc_entry_list_qos.c1  :
                         send_ar_grt_idx == 4'h2 ? vc_entry_list_qos.c2  :
                         send_ar_grt_idx == 4'h3 ? vc_entry_list_qos.c3  : vc_entry_list_qos.c4)
                        :
                        (send_ar_grt_idx == 4'h0 ? vc_entry_list.c0  :
                         send_ar_grt_idx == 4'h1 ? vc_entry_list.c1  :
                         send_ar_grt_idx == 4'h2 ? vc_entry_list.c2  :
                         send_ar_grt_idx == 4'h3 ? vc_entry_list.c3  :
                         send_ar_grt_idx == 4'h4 ? vc_entry_list.c4  :
                         send_ar_grt_idx == 4'h5 ? vc_entry_list.c5  :
                         send_ar_grt_idx == 4'h6 ? vc_entry_list.c6  :
                         send_ar_grt_idx == 4'h7 ? vc_entry_list.c7  :
                         send_ar_grt_idx == 4'h8 ? vc_entry_list.c8  : vc_entry_list.c9);

assign entry_send_success_qos = {TX_CHANNEL_NUM{(!async_send_credit_fifo_empty) & (asynced_credit == SUCCESS)}} & send_ar_grt_qos_s2;
assign entry_send_success = {TX_CHANNEL_NUM{(!async_send_credit_fifo_empty) & (asynced_credit == SUCCESS)}} & {TX_CHANNEL_NUM{(~(|send_ar_grt_qos_s2))}} & send_ar_grt_s2;

always_ff @(posedge if_clk) begin
    if(rst) begin
        send_next_one <= 1'b1;
        fifo_read_next_one <= 1'b0;
    end else begin
        if(((|vc_arb_valid) | (|vc_arb_valid_qos)) && send_next_one) begin
            send_next_one <= 1'b0;
            fifo_read_next_one <= 1'b1;
        end else if(fifo_read_next_one) begin
            fifo_read_next_one <= 1'b0;
        end else if((asynced_credit == SUCCESS) && (!async_send_credit_fifo_empty)) begin
            send_next_one <= 1'b1;
        end
    end
end

`endif


async_fifo#(
    .DSIZE(MAX_MESSAGE_LENGTH + CHANNEL_NUM_WIDTH),
    .ASIZE(2)
) async_message_send_fifo(
    .wclk(if_clk),
    .wrst_n(~rst),
    .winc((|send_ar_grt) & fifo_read_next_one),
    .wdata({arbbed_message, send_ar_grt_idx}),
    .wfull(),
    .awfull(),
    .rclk(bus_clk),
    .rrst_n(~rst),
    .rinc(send_success && (credit_state == RCREDIT_CHECK)),
    .rdata(asynced_message[MAX_MESSAGE_LENGTH + CHANNEL_NUM_WIDTH-1:0]),
    .rempty(async_message_send_fifo_empty),
    .arempty()
);

assign asynced_message[MAX_MESSAGE_LENGTH + CHANNEL_NUM_WIDTH +: 2*OFF_DIE_WD] = '0;

always_ff @(posedge bus_clk) begin
    if(rst) begin
        transmit_state <= SEND_IDLE;
        message_count <= {MAX_MESSAGE_WIDTH{1'b0}};
        parity_bit <= {OFF_DIE_WD{1'b0}};
        send_parity_count <= {PARITY_WIDTH{1'b0}};
    end else begin
        transmit_state <= next_transmit_state;
        if(transmit_state == START_BIT) begin
            message_count <= {MAX_MESSAGE_WIDTH{1'b0}};
            parity_bit <= {OFF_DIE_WD{1'b0}};
            send_parity_count <= {PARITY_WIDTH{1'b0}};
        end else begin
            if(en_message_bit_count) begin
                message_count <= message_count + 1'b1;
            end
            if(en_send_parity_count) begin
                if(transmit_state == INSERT_PARITY) begin
                    parity_bit <= {OFF_DIE_WD{1'b0}};
                    send_parity_count <= {PARITY_WIDTH{1'b0}};
                end else begin
                    send_parity_count <= send_parity_count + 1'b1;
                    for(int i = 0; i < OFF_DIE_WD; i++) begin
                        parity_bit[i] <= parity_bit[i] ^ asynced_message[message_count * OFF_DIE_WD + i];
                    end
                end
            end
        end
    end
end

assign channel_id = asynced_message[CHANNEL_NUM_WIDTH-1:0];
assign message_length = (CHANNEL_LENGTH_LIST[channel_id] - ((channel_id == ID_DATA) ?  ((DATA_BURST_NUM - asynced_message[CHANNEL_NUM_WIDTH+:(DATA_BURST_NUM_W+1)]) * DATA_LENGTH_PER_PKG) : 0)) + CHANNEL_NUM_WIDTH;  // TODO: add other options
assign all_message_transmitted = (message_count * OFF_DIE_WD >= message_length - 1'b1); // count from zero


always_comb begin: transmit_FSM
    if(rst) begin  // can use this rst(if long enough)?
    next_transmit_state = SEND_IDLE;
    en_send_parity_count = 1'b0;
    en_message_bit_count = 1'b0; 
    end else begin
        en_send_parity_count = 1'b0;
        en_message_bit_count = 1'b0; 
        unique case (transmit_state)
            SEND_IDLE: begin
                if(!async_message_send_fifo_empty) begin
                    next_transmit_state = START_BIT;
                end else begin
                    next_transmit_state = SEND_IDLE;
                end
            end
            START_BIT: begin
                next_transmit_state = MESSAGE_SEND;
                en_send_parity_count = 1'b0;
                en_message_bit_count = 1'b0;
            end
            MESSAGE_SEND: begin
                if (all_message_transmitted | (send_parity_count == PARITY_LENGTH - 1'b1)) begin
                    en_message_bit_count = 1'b0; 
                end else begin
                    en_message_bit_count = 1'b1;
                end
                if(all_message_transmitted) begin // the last group will be not verified with parity code
                    next_transmit_state = END_BIT;
                    en_send_parity_count = 1'b0;
                end 
                `ifdef PARITY_ON
                else if (send_parity_count == PARITY_LENGTH - 1'b1)begin
                    en_send_parity_count = 1'b0;
                    next_transmit_state = INSERT_PARITY;
                end 
                `endif
                else begin
                    en_send_parity_count = 1'b1;
                    next_transmit_state = MESSAGE_SEND;
                end
            end
            INSERT_PARITY: begin
                // if(all_message_transmitted) begin
                //     next_transmit_state = END_BIT;
                // end else begin
                    next_transmit_state = MESSAGE_SEND;
                    en_send_parity_count = 1'b1;
                    en_message_bit_count = 1'b1;
                // end
            end
            END_BIT: begin
                next_transmit_state = WAIT_CREDIT;
            end
            WAIT_CREDIT: begin
                if(send_success) begin
                    next_transmit_state = SEND_IDLE;
                end else if(send_fail) begin
                    next_transmit_state = START_BIT;
                end else begin
                    next_transmit_state = WAIT_CREDIT;
                end
            end
            default: begin
                next_transmit_state = SEND_IDLE;
            end
        endcase    
    end
end

generate
    for (genvar i = 0; i < OFF_DIE_WD; i++) begin
        always_ff @(negedge bus_clk) begin // transmitting singal
            if(rst) begin
                transmitting_bit[i] <= 1'b1;
            end else begin
                unique case(transmit_state) 
                    SEND_IDLE: begin
                        transmitting_bit[i] <= 1'b1;
                    end
                    START_BIT: begin
                        transmitting_bit[i] <= 1'b0;
                    end
                    MESSAGE_SEND: begin 
                        transmitting_bit[i] <= asynced_message[message_count * OFF_DIE_WD + i]; //transmitted from the lowest bit, the lowest bits are VC id
                    end
                    INSERT_PARITY: begin
                        transmitting_bit[i] <= parity_bit[i] ^ asynced_message[message_count * OFF_DIE_WD + i];  // it is actually the process of calculating the parity bit take parity with last bit(it is non-blocking)
                    end
                    END_BIT: begin
                        transmitting_bit[i] <= 1'b1;
                    end
                    WAIT_CREDIT: begin
                        transmitting_bit[i] <= 1'b1;
                    end
                endcase
            end
        end
    end
endgenerate

//sync input
always_ff @(posedge bus_clk) begin
    if(rst) begin
        recv_credit_synced <= 1'b1;
    end else begin
        recv_credit_synced <= credit_in;
    end
end

always_comb begin
    if(rst) begin
        en_recv_credit = 1'b0;
        next_credit_state = RCREDIT_IDLE;
        send_success = 1'b0;
        send_fail = 1'b0;
    end else begin
        en_recv_credit = 1'b0;
        next_credit_state = RCREDIT_IDLE;
        send_success = 1'b0;
        send_fail = 1'b0;
        unique case(credit_state)
            RCREDIT_IDLE: begin
                if(!recv_credit_synced) begin
                    next_credit_state = RRECV_CREDIT;
                end else begin
                    next_credit_state = RCREDIT_IDLE;
                end
            end
            RRECV_CREDIT: begin
                if(send_credit_count == CREDIT_WIDTH - 1'b1) begin
                    next_credit_state = RCREDIT_CHECK;
                    en_recv_credit = 1'b0;
                end else begin
                    next_credit_state = RRECV_CREDIT;
                    en_recv_credit = 1'b1;
                end
            end
            RCREDIT_CHECK: begin
                next_credit_state = RCREDIT_IDLE;
                if(credit_slot == SUCCESS) begin
                    send_success = 1'b1;
                end else begin
                    send_fail = 1'b1;
                end
            end
        endcase
    end
end

always_ff @(posedge bus_clk) begin
    if(rst) begin
        credit_slot <= {CREDIT_LENGTH{1'b0}};
        credit_state <= RCREDIT_IDLE;
        send_credit_count <= {CREDIT_WIDTH{1'b0}};
    end else begin
        credit_state <= next_credit_state;
        if(credit_state == RCREDIT_CHECK) begin
            send_credit_count <= {CREDIT_WIDTH{1'b0}};
        end else if(en_recv_credit) begin
            credit_slot[send_credit_count] <= recv_credit_synced;
            send_credit_count <= send_credit_count + 1'b1;
        end
    end
end

assign credit_wire = credit_slot;

async_fifo#(
    .DSIZE(CREDIT_WIDTH),    // Memory data word width
    .ASIZE(2)
) async_send_credit_fifo(
    .wclk(bus_clk),
    .wrst_n(~rst),
    .winc(credit_state == RCREDIT_CHECK),
    .wdata(credit_wire),
    .wfull(),
    .awfull(),
    .rclk(if_clk),
    .rrst_n(~rst),
    .rinc(!async_send_credit_fifo_empty),
    .rdata(asynced_credit),
    .rempty(async_send_credit_fifo_empty),
    .arempty()
);

assign bus_out = transmitting_bit;


endmodule: ebi_tx