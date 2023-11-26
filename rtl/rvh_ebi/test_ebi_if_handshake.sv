module test_ebi_if_handshake
    import test_ebi_pkg::*;
    import rvh_noc_pkg::*;
    import rvh_uncore_param_pkg::*;
(
    input  logic                                    m1_clk_i,
    input  logic                                    rst_i,

    output logic [M1_M2_CHANNEL_NUM-1:0]            m1_m2_channel_entry_valid_o, 
    input  logic [M1_M2_CHANNEL_NUM-1:0]            m1_m2_channel_push_ready_i,
    output logic [M1_M2_CHANNEL_NUM-1:0][MAX_M1_M2_MESSAGE_LENGTH-1:0] m1_m2_channel_hs_entry_o, // there they are registers

    output logic [M2_M1_CHANNEL_NUM-1:0]            entry_if_recv_success_o, 
    input  logic [M2_M1_CHANNEL_NUM-1:0]            m2_m1_vc_valid_i,
    input  logic [M2_M1_CHANNEL_NUM-1:0][MAX_M2_M1_MESSAGE_LENGTH-1:0] m2_m1_vc_entry_list_i,
  // control signals
    input logic                                 tx_flit_pend_i,
    input logic                                 tx_flit_v_i,
    input logic           [VC_ID_NUM_MAX_W-1:0] tx_flit_vc_id_i,
    input io_port_t                             tx_flit_look_ahead_routing_i,

    output  logic                                 rx_flit_pend_o,
    output  logic                                 rx_flit_v_o,
    output  logic           [VC_ID_NUM_MAX_W-1:0] rx_flit_vc_id_o,
    output  io_port_t                             rx_flit_look_ahead_routing_o,

    output  logic                                 tx_lcrd_v_o,
    output  logic           [VC_ID_NUM_MAX_W-1:0] tx_lcrd_id_o,

    input logic                                 rx_lcrd_v_i,
    input logic           [VC_ID_NUM_MAX_W-1:0] rx_lcrd_id_i,

  // payload
    input cache_scu_cc_test_t  tx_flit_channels_i,

    output  cache_scu_cc_test_t                                     rx_flit_channel_0_o
);

// logic [M2_M1_CHANNEL_NUM-1:0] m2_m1_entry_valid; 
logic [M2_M1_CHANNEL_NUM-1:0][MAX_M2_M1_MESSAGE_LENGTH-1:0] m2_m1_vc_entry_list; // registers here

generate
for (genvar i = 0; i < M2_M1_CHANNEL_NUM; i++) begin
    assign entry_if_recv_success_o[i] = 1'b1;
end
endgenerate

generate
for (genvar i = 0; i < M1_M2_CHANNEL_NUM; i++) begin
    if(i == ID_TEST) begin
        always_ff @(posedge m1_clk_i) begin
            if(rst_i) begin
                m1_m2_channel_entry_valid_o[i] <= 1'b0;
                m1_m2_channel_hs_entry_o[i] <= {MAX_M1_M2_MESSAGE_LENGTH{1'b0}};
            end else begin
                if(tx_flit_v_i) begin
                    m1_m2_channel_hs_entry_o[i] <= {tx_flit_pend_i, tx_flit_vc_id_i, 
                    tx_flit_look_ahead_routing_i, tx_flit_channels_i[M1_M2_CHANNEL_LENGTH_LIST[i]-(1 + VC_ID_NUM_MAX_W + LAR_W)-1:0]}; 
                    m1_m2_channel_entry_valid_o[i] <= 1'b1;
                end else begin 
                    if(m1_m2_channel_entry_valid_o[i] & m1_m2_channel_push_ready_i[i]) begin
                        m1_m2_channel_entry_valid_o[i] <= 1'b0;
                    end
                end
            end
        end
    end else begin
        always_ff @(posedge m1_clk_i) begin
            if(rst_i) begin
                m1_m2_channel_entry_valid_o[i] <= 1'b0;
                m1_m2_channel_hs_entry_o[i] <= {MAX_M1_M2_MESSAGE_LENGTH{1'b0}};
            end else begin
                if(rx_lcrd_v_i) begin
                    m1_m2_channel_hs_entry_o[i] <= rx_lcrd_id_i; 
                    m1_m2_channel_entry_valid_o[i] <= 1'b1;
                end else begin 
                    if(m1_m2_channel_entry_valid_o[i] & m1_m2_channel_push_ready_i[i]) begin
                        m1_m2_channel_entry_valid_o[i] <= 1'b0;
                    end
                end
            end
        end
    end
end
endgenerate

/////  ---------------------- RX ------------------------------
generate
    for(genvar i = 0; i < M1_M2_CHANNEL_NUM; i++) begin
        if (i == ID_TEST) begin
            always_ff @(posedge m1_clk_i) begin
                if(rst_i) begin
                    rx_flit_v_o[i] <= {1'b0};
                    m2_m1_vc_entry_list[i] <= {MAX_M2_M1_MESSAGE_LENGTH{1'b0}};
                end else begin
                    if(rx_flit_v_o[i]) begin
                        rx_flit_v_o[i] <= 1'b0;
                    end else if((!rx_flit_v_o[i]) & m2_m1_vc_valid_i[i]) begin
                        rx_flit_v_o[i] <= 1'b1;
                        m2_m1_vc_entry_list[i] <= m2_m1_vc_entry_list_i[i];
                    end
                end
            end
        end else begin
            always_ff @(posedge m1_clk_i) begin
                if(rst_i) begin
                    tx_lcrd_v_o <= {1'b0};
                    m2_m1_vc_entry_list[i] <= {MAX_M2_M1_MESSAGE_LENGTH{1'b0}};
                end else begin
                    if(tx_lcrd_v_o) begin
                        tx_lcrd_v_o <= 1'b0;
                    end else if((!tx_lcrd_v_o) & m2_m1_vc_valid_i[i]) begin
                        tx_lcrd_v_o <= 1'b1;
                        m2_m1_vc_entry_list[i] <= m2_m1_vc_entry_list_i[i];
                    end
                end
            end
        end
    end
endgenerate

generate
for (genvar i = 0; i < M1_M2_CHANNEL_NUM; i++) begin
    if(i == ID_TEST) begin
        assign rx_flit_pend_o = m2_m1_vc_entry_list[i][M1_M2_CHANNEL_LENGTH_LIST[i]-1];
        assign rx_flit_vc_id_o = m2_m1_vc_entry_list[i][(M1_M2_CHANNEL_LENGTH_LIST[i]-2) -: VC_ID_NUM_MAX_W];
        assign rx_flit_look_ahead_routing_o = m2_m1_vc_entry_list[i][(M1_M2_CHANNEL_LENGTH_LIST[i]-VC_ID_NUM_MAX_W-2) -: LAR_W];
    end else begin
        assign tx_lcrd_id_o = m2_m1_vc_entry_list[i];
    end
end
endgenerate

// the last bits matches corresponding output flit
assign rx_flit_channel_0_o = m2_m1_vc_entry_list[ID_TEST];


endmodule: test_ebi_if_handshake