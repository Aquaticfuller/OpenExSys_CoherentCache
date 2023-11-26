module m1_ebi
    import ebi_pkg::*;
    import rvh_l1d_cc_pkg::*;
    import rvh_uncore_param_pkg::*;
    import rvh_noc_pkg::*;
(
    input logic                 m1_clk,
    input logic                 bus_clk,
    input logic                 rst,
  // control signals
    input logic           [CHANNEL_NUM-1:0]                      tx_flit_pend_i,
    input logic           [CHANNEL_NUM-1:0]                      tx_flit_v_i,
    input logic           [CHANNEL_NUM-1:0][VC_ID_NUM_MAX_W-1:0] tx_flit_vc_id_i,
    input io_port_t       [CHANNEL_NUM-1:0]                      tx_flit_look_ahead_routing_i,

    output  logic           [CHANNEL_NUM-1:0]                      rx_flit_pend_o,
    output  logic           [CHANNEL_NUM-1:0]                      rx_flit_v_o,
    output  logic           [CHANNEL_NUM-1:0][VC_ID_NUM_MAX_W-1:0] rx_flit_vc_id_o,
    output  io_port_t       [CHANNEL_NUM-1:0]                      rx_flit_look_ahead_routing_o,

    output  logic           [CHANNEL_NUM-1:0]                      tx_lcrd_v_o,
    output  logic           [CHANNEL_NUM-1:0][VC_ID_NUM_MAX_W-1:0] tx_lcrd_id_o,

    input logic           [CHANNEL_NUM-1:0]                      rx_lcrd_v_i,
    input logic           [CHANNEL_NUM-1:0][VC_ID_NUM_MAX_W-1:0] rx_lcrd_id_i,

  // payload
    input cache_scu_cc_req_t                                     tx_flit_channel_0_i, // req
    input cache_scu_cc_resp_t                                    tx_flit_channel_1_i, // resp
    input cache_scu_cc_req_t                                     tx_flit_channel_2_i, // evict
    input cache_scu_cc_data_t                                    tx_flit_channel_3_i, // data
    input cache_scu_cc_snp_t                                     tx_flit_channel_4_i, // snp

    output  cache_scu_cc_req_t                                     rx_flit_channel_0_o, // req
    output  cache_scu_cc_resp_t                                    rx_flit_channel_1_o, // resp
    output  cache_scu_cc_req_t                                     rx_flit_channel_2_o, // evict
    output  cache_scu_cc_data_t                                    rx_flit_channel_3_o, // data
    output  cache_scu_cc_snp_t                                     rx_flit_channel_4_o, // snp

        //external interface
    output logic   [OFF_DIE_WD-1:0]             m1_m2_bus_o,
    input  logic                                m2_m1_credit_i,
    input  logic   [OFF_DIE_WD-1:0]             m2_m1_bus_i,
    output logic                                m1_m2_credit_o
);

// for tx
ebi_type_union m1_m2_channel_hs_entry;
logic [M1_M2_CHANNEL_NUM-1:0] m1_m2_channel_entry_valid, m1_m2_channel_push_ready;
// for rx
logic [M1_M2_CHANNEL_NUM-1:0] m2_m1_vc_valid, entry_if_recv_success;
ebi_type_union m2_m1_vc_entry_list;

// handshake module which control interface signal turning to unified signal
m1_ebi_if_handshake u_m1_ebi_if_handshake(
    .m1_clk_i(m1_clk),
    .rst_i(rst),
    .m1_m2_channel_entry_valid_o(m1_m2_channel_entry_valid), 
    .m1_m2_channel_push_ready_i(m1_m2_channel_push_ready),
    .m1_m2_channel_hs_entry_o(m1_m2_channel_hs_entry),
    
    .entry_if_recv_success_o(entry_if_recv_success), 
    .m2_m1_vc_valid_i(m2_m1_vc_valid),
    .m2_m1_vc_entry_list_i(m2_m1_vc_entry_list),

    .tx_flit_pend_i(tx_flit_pend_i),
    .tx_flit_v_i(tx_flit_v_i),
    .tx_flit_vc_id_i(tx_flit_vc_id_i),
    .tx_flit_look_ahead_routing_i(tx_flit_look_ahead_routing_i),
    .rx_flit_pend_o(rx_flit_pend_o),
    .rx_flit_v_o(rx_flit_v_o),
    .rx_flit_vc_id_o(rx_flit_vc_id_o),
    .rx_flit_look_ahead_routing_o(rx_flit_look_ahead_routing_o),
    .tx_lcrd_v_o(tx_lcrd_v_o),
    .tx_lcrd_id_o(tx_lcrd_id_o),
    .rx_lcrd_v_i(rx_lcrd_v_i),
    .rx_lcrd_id_i(rx_lcrd_id_i),
    
    .tx_flit_channel_0_i(tx_flit_channel_0_i), 
    .tx_flit_channel_1_i(tx_flit_channel_1_i),
    .tx_flit_channel_2_i(tx_flit_channel_2_i), 
    .tx_flit_channel_3_i(tx_flit_channel_3_i),
    .tx_flit_channel_4_i(tx_flit_channel_4_i), 

    .rx_flit_channel_0_o(rx_flit_channel_0_o), // req
    .rx_flit_channel_1_o(rx_flit_channel_1_o), // resp
    .rx_flit_channel_2_o(rx_flit_channel_2_o), // evict
    .rx_flit_channel_3_o(rx_flit_channel_3_o), // data
    .rx_flit_channel_4_o(rx_flit_channel_4_o) // snp
);

ebi_tx #(
    .TX_CHANNEL_NUM(M1_M2_CHANNEL_NUM),
    .CHANNEL_NUM_WIDTH(M1_M2_CHANNEL_NUM_WIDTH),
    .MAX_MESSAGE_LENGTH(MAX_M1_M2_MESSAGE_LENGTH),
    .MAX_MESSAGE_WIDTH(MAX_M1_M2_MESSAGE_WIDTH),
    .CHANNEL_LENGTH_LIST(M1_M2_CHANNEL_LENGTH_LIST)
) u_m1_tx(
    .if_clk(m1_clk),
    .bus_clk(bus_clk),
    .rst(rst),
    .channel_hs_entry(m1_m2_channel_hs_entry),  // wire here
    .channel_entry_valid(m1_m2_channel_entry_valid),  
    .channel_push_ready(m1_m2_channel_push_ready),
    .bus_out(m1_m2_bus_o),
    .credit_in(m2_m1_credit_i)
);

ebi_rx #(
    .RX_CHANNEL_NUM(M1_M2_CHANNEL_NUM),
    .CHANNEL_NUM_WIDTH(M1_M2_CHANNEL_NUM_WIDTH),
    .MAX_MESSAGE_LENGTH(MAX_M1_M2_MESSAGE_LENGTH),
    .MAX_MESSAGE_WIDTH(MAX_M1_M2_MESSAGE_WIDTH),
    .CHANNEL_LENGTH_LIST(M1_M2_CHANNEL_LENGTH_LIST)
) u_m1_rx (
    .if_clk(m1_clk),
    .bus_clk(bus_clk),
    .rst(rst),
    .vc_entry_list(m2_m1_vc_entry_list),  // wire here
    .vc_valid(m2_m1_vc_valid),  
    .entry_if_recv_success(entry_if_recv_success),
    .bus_in(m2_m1_bus_i),
    .credit_out(m1_m2_credit_o)
);

endmodule: m1_ebi