module m1_ebi_if_handshake
    import ebi_pkg::*;
    import rvh_l1d_cc_pkg::*;
    import rvh_noc_pkg::*;
    import rvh_uncore_param_pkg::*;
(
    input  logic                                    m1_clk_i,
    input  logic                                    rst_i,

    output logic [M1_M2_CHANNEL_NUM-1:0]            m1_m2_channel_entry_valid_o, 
    input  logic [M1_M2_CHANNEL_NUM-1:0]            m1_m2_channel_push_ready_i,
    output ebi_type_union m1_m2_channel_hs_entry_o, // there they are registers

    output logic [M2_M1_CHANNEL_NUM-1:0]            entry_if_recv_success_o, 
    input  logic [M2_M1_CHANNEL_NUM-1:0]            m2_m1_vc_valid_i,
    input  ebi_type_union m2_m1_vc_entry_list_i,
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
    input  cache_scu_cc_req_t                                      tx_flit_channel_0_i, // req
    input  cache_scu_cc_resp_t                                     tx_flit_channel_1_i, // resp
    input  cache_scu_cc_req_t                                      tx_flit_channel_2_i, // evict
    input  cache_scu_cc_data_t                                     tx_flit_channel_3_i, // data
    input  cache_scu_cc_snp_t                                      tx_flit_channel_4_i, // snp


    output  cache_scu_cc_req_t                                     rx_flit_channel_0_o, // req
    output  cache_scu_cc_resp_t                                    rx_flit_channel_1_o, // resp
    output  cache_scu_cc_req_t                                     rx_flit_channel_2_o, // evict
    output  cache_scu_cc_data_t                                    rx_flit_channel_3_o, // data
    output  cache_scu_cc_snp_t                                     rx_flit_channel_4_o // snp
);

// logic [M2_M1_CHANNEL_NUM-1:0] m2_m1_entry_valid; 
ebi_type_union m2_m1_vc_entry_list; // registers here

generate
for (genvar i = 0; i < M2_M1_CHANNEL_NUM; i++) begin
    assign entry_if_recv_success_o[i] = 1'b1;
end
endgenerate


always_ff @(posedge m1_clk_i) begin
    if(rst_i) begin
        m1_m2_channel_hs_entry_o.c0 <= '0;
        m1_m2_channel_hs_entry_o.c1 <= '0;
        m1_m2_channel_hs_entry_o.c2 <= '0;
        m1_m2_channel_hs_entry_o.c4 <= '0;
        m1_m2_channel_hs_entry_o.c5 <= '0;
        m1_m2_channel_hs_entry_o.c6 <= '0;
        m1_m2_channel_hs_entry_o.c7 <= '0;
        m1_m2_channel_hs_entry_o.c8 <= '0;
        m1_m2_channel_hs_entry_o.c9 <= '0;
    end else begin
        if(tx_flit_v_i[0]) begin
            m1_m2_channel_hs_entry_o.c0 <= {tx_flit_pend_i[0], tx_flit_vc_id_i[0], 
                    tx_flit_look_ahead_routing_i[0], tx_flit_channel_0_i}; 
        end
        if(tx_flit_v_i[1]) begin
            m1_m2_channel_hs_entry_o.c1 <= {tx_flit_pend_i[1], tx_flit_vc_id_i[1], 
                    tx_flit_look_ahead_routing_i[1], tx_flit_channel_1_i}; 
        end
        if(tx_flit_v_i[2]) begin
            m1_m2_channel_hs_entry_o.c2 <= {tx_flit_pend_i[2], tx_flit_vc_id_i[2], 
                    tx_flit_look_ahead_routing_i[2], tx_flit_channel_2_i}; 
        end
        if(tx_flit_v_i[4]) begin
            m1_m2_channel_hs_entry_o.c4 <= {tx_flit_pend_i[4], tx_flit_vc_id_i[4], 
                    tx_flit_look_ahead_routing_i[4], tx_flit_channel_4_i}; 
        end
        if(rx_lcrd_v_i[0]) begin
            m1_m2_channel_hs_entry_o.c5 <= rx_lcrd_id_i[0];
        end
        if(rx_lcrd_v_i[1]) begin
            m1_m2_channel_hs_entry_o.c6 <= rx_lcrd_id_i[1];
        end
        if(rx_lcrd_v_i[2]) begin
            m1_m2_channel_hs_entry_o.c7 <= rx_lcrd_id_i[2];
        end
        if(rx_lcrd_v_i[3]) begin
            m1_m2_channel_hs_entry_o.c8 <= rx_lcrd_id_i[3];
        end
        if(rx_lcrd_v_i[4]) begin
            m1_m2_channel_hs_entry_o.c9 <= rx_lcrd_id_i[4];
        end
    end
end

generate
for (genvar i = 0; i < M1_M2_CHANNEL_NUM; i++) begin
    if((i != ID_DATA) && ( i < CHANNEL_NUM)) begin
        always_ff @(posedge m1_clk_i) begin
            if(rst_i) begin
                m1_m2_channel_entry_valid_o[i] <= 1'b0;
                // m1_m2_channel_hs_entry_o[i] <= {MAX_M1_M2_MESSAGE_LENGTH{1'b0}};
            end else begin
                if(tx_flit_v_i[i]) begin
                    // m1_m2_channel_hs_entry_o[i] <= {tx_flit_pend_i[i], tx_flit_vc_id_i[i], 
                    // tx_flit_look_ahead_routing_i[i], tx_flit_channels_i[i][M1_M2_CHANNEL_LENGTH_LIST[i]-(1 + VC_ID_NUM_MAX_W + LAR_W)-1:0]}; 
                    m1_m2_channel_entry_valid_o[i] <= 1'b1;
                end else begin 
                    if(m1_m2_channel_entry_valid_o[i] & m1_m2_channel_push_ready_i[i]) begin
                        m1_m2_channel_entry_valid_o[i] <= 1'b0;
                    end
                end
            end
        end
    end else if (i != ID_DATA) begin
        always_ff @(posedge m1_clk_i) begin
            if(rst_i) begin
                m1_m2_channel_entry_valid_o[i] <= 1'b0;
                // m1_m2_channel_hs_entry_o[i] <= {MAX_M1_M2_MESSAGE_LENGTH{1'b0}};
            end else begin
                if(rx_lcrd_v_i[i-ID_CR_REQ]) begin
                    // m1_m2_channel_hs_entry_o[i] <= rx_lcrd_id_i[i-ID_CR_REQ]; 
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

cache_scu_cc_data_t data_precom;
assign data_precom = tx_flit_channel_3_i;
logic [DATA_LINE_W-1:0] com_result;
logic [DATA_BURST_NUM_W:0] valid_counter;

data_com u_data_com (
    .data_valid(data_precom.data_valid),
    .data_uncom(data_precom.data),
    .data_com(com_result),
    .valid_counter(valid_counter)
);

always_ff @(posedge m1_clk_i) begin
    if(rst_i) begin
        m1_m2_channel_entry_valid_o[ID_DATA] <= 1'b0;
        // m1_m2_channel_hs_entry_o[ID_DATA] <= 'b0;
        m1_m2_channel_hs_entry_o.c3 <= 'b0;
    end else begin
        if(tx_flit_v_i[ID_DATA]) begin
            // m1_m2_channel_hs_entry_o[ID_DATA] <= { com_result, tx_flit_pend_i[ID_DATA], tx_flit_vc_id_i[ID_DATA],
            m1_m2_channel_hs_entry_o.c3 <= { com_result, tx_flit_pend_i[ID_DATA], tx_flit_vc_id_i[ID_DATA],
                tx_flit_look_ahead_routing_i[ID_DATA], tx_flit_channel_3_i[DATA_VALID_LOCATION+DATA_BURST_NUM-1:0], valid_counter};
            m1_m2_channel_entry_valid_o[ID_DATA] <= 1'b1;
        end else begin
            if(m1_m2_channel_entry_valid_o[ID_DATA] & m1_m2_channel_push_ready_i[ID_DATA]) begin
                m1_m2_channel_entry_valid_o[ID_DATA] <= 1'b0;
            end
        end
    end
end

/////  ---------------------- RX ------------------------------

always_ff @(posedge m1_clk_i) begin
    if(rst_i) begin
        m2_m1_vc_entry_list.c0 <= '0;
        m2_m1_vc_entry_list.c1 <= '0;
        m2_m1_vc_entry_list.c2 <= '0;
        m2_m1_vc_entry_list.c4 <= '0;
        m2_m1_vc_entry_list.c5 <= '0;
        m2_m1_vc_entry_list.c6 <= '0;
        m2_m1_vc_entry_list.c7 <= '0;
        m2_m1_vc_entry_list.c8 <= '0;
        m2_m1_vc_entry_list.c9 <= '0;
    end else begin
        if((!rx_flit_v_o[0]) & m2_m1_vc_valid_i[0]) begin
            m2_m1_vc_entry_list.c0 <= m2_m1_vc_entry_list_i.c0;
        end
        if((!rx_flit_v_o[1]) & m2_m1_vc_valid_i[1]) begin
            m2_m1_vc_entry_list.c1 <= m2_m1_vc_entry_list_i.c1;
        end
        if((!rx_flit_v_o[2]) & m2_m1_vc_valid_i[2]) begin
            m2_m1_vc_entry_list.c2 <= m2_m1_vc_entry_list_i.c2;
        end
        if((!rx_flit_v_o[4]) & m2_m1_vc_valid_i[4]) begin
            m2_m1_vc_entry_list.c4 <= m2_m1_vc_entry_list_i.c4;
        end
        if((!tx_lcrd_v_o[0]) & m2_m1_vc_valid_i[5]) begin
            m2_m1_vc_entry_list.c5 <= m2_m1_vc_entry_list_i.c5;
        end
        if((!tx_lcrd_v_o[1]) & m2_m1_vc_valid_i[6]) begin
            m2_m1_vc_entry_list.c6 <= m2_m1_vc_entry_list_i.c6;
        end
        if((!tx_lcrd_v_o[2]) & m2_m1_vc_valid_i[7]) begin
            m2_m1_vc_entry_list.c7 <= m2_m1_vc_entry_list_i.c7;
        end
        if((!tx_lcrd_v_o[3]) & m2_m1_vc_valid_i[8]) begin
            m2_m1_vc_entry_list.c8 <= m2_m1_vc_entry_list_i.c8;
        end
        if((!tx_lcrd_v_o[4]) & m2_m1_vc_valid_i[9]) begin
            m2_m1_vc_entry_list.c9 <= m2_m1_vc_entry_list_i.c9;
        end
    end
end

generate
    for(genvar i = 0; i < M1_M2_CHANNEL_NUM; i++) begin
        if((i != ID_DATA) && (i < CHANNEL_NUM)) begin
            always_ff @(posedge m1_clk_i) begin
                if(rst_i) begin
                    rx_flit_v_o[i] <= {1'b0};
                    // m2_m1_vc_entry_list[i] <= {MAX_M2_M1_MESSAGE_LENGTH{1'b0}};
                end else begin
                    if(rx_flit_v_o[i]) begin
                        rx_flit_v_o[i] <= 1'b0;
                    end else if((!rx_flit_v_o[i]) & m2_m1_vc_valid_i[i]) begin
                        rx_flit_v_o[i] <= 1'b1;
                        // m2_m1_vc_entry_list[i] <= m2_m1_vc_entry_list_i[i];
                    end
                end
            end
        end else if (i != ID_DATA) begin
            always_ff @(posedge m1_clk_i) begin
                if(rst_i) begin
                    tx_lcrd_v_o[i-ID_CR_REQ] <= {1'b0};
                    // m2_m1_vc_entry_list[i] <= {MAX_M2_M1_MESSAGE_LENGTH{1'b0}};
                end else begin
                    if(tx_lcrd_v_o[i-ID_CR_REQ]) begin
                        tx_lcrd_v_o[i-ID_CR_REQ] <= 1'b0;
                    end else if((!tx_lcrd_v_o[i-ID_CR_REQ]) & m2_m1_vc_valid_i[i]) begin
                        tx_lcrd_v_o[i-ID_CR_REQ] <= 1'b1;
                        // m2_m1_vc_entry_list[i] <= m2_m1_vc_entry_list_i[i];
                    end
                end
            end
        end
    end
endgenerate

logic [DATA_LINE_W-1:0] data_uncom_buffer;
data_uncom u_data_uncom(
    .data_valid(m2_m1_vc_entry_list_i.c3[DATA_BURST_NUM_W+1+DATA_VALID_LOCATION +: DATA_BURST_NUM]),
    .data_com(m2_m1_vc_entry_list_i.c3[(DATA_BURST_NUM_W+1+DATA_VALID_LOCATION+DATA_BURST_NUM+(1+LAR_W+VC_ID_NUM_MAX_W)) +: DATA_LINE_W]),
    .data_uncom(data_uncom_buffer)
);

always_ff @(posedge m1_clk_i) begin
    if(rst_i) begin
        rx_flit_v_o[ID_DATA] <= {1'b0};
        m2_m1_vc_entry_list.c3 <= {MAX_M2_M1_MESSAGE_LENGTH{1'b0}};
        // m2_m1_vc_entry_list[ID_DATA] <= {MAX_M2_M1_MESSAGE_LENGTH{1'b0}};
    end else begin
        if(rx_flit_v_o[ID_DATA]) begin
            rx_flit_v_o[ID_DATA] <= 1'b0;
        end else if((!rx_flit_v_o[ID_DATA]) & m2_m1_vc_valid_i[ID_DATA]) begin
            rx_flit_v_o[ID_DATA] <= 1'b1;
            // m2_m1_vc_entry_list[ID_DATA] <= {m2_m1_vc_entry_list_i[ID_DATA][(DATA_BURST_NUM+DATA_VALID_LOCATION+DATA_BURST_NUM_W+1)+:(1+LAR_W+VC_ID_NUM_MAX_W)],
            m2_m1_vc_entry_list.c3 <= {m2_m1_vc_entry_list_i.c3[(DATA_BURST_NUM+DATA_VALID_LOCATION+DATA_BURST_NUM_W+1)+:(1+LAR_W+VC_ID_NUM_MAX_W)],
                data_uncom_buffer, m2_m1_vc_entry_list_i.c3[(1+DATA_BURST_NUM_W+DATA_VALID_LOCATION+DATA_BURST_NUM-1):0]};
        end
    end
end

// generate
//     for (genvar i = 0; i < CHANNEL_NUM; i++) begin
//         assign rx_flit_pend_o[i] = m2_m1_vc_entry_list[i][M1_M2_CHANNEL_LENGTH_LIST[i]-1];
//         assign rx_flit_vc_id_o[i] = m2_m1_vc_entry_list[i][(M1_M2_CHANNEL_LENGTH_LIST[i]-2) -: VC_ID_NUM_MAX_W];
//         assign rx_flit_look_ahead_routing_o[i] = m2_m1_vc_entry_list[i][(M1_M2_CHANNEL_LENGTH_LIST[i]-VC_ID_NUM_MAX_W-2) -: LAR_W];
//     end
//     for (genvar i = ID_CR_REQ; i < ID_CR_SNP+1; i++) begin
//         assign tx_lcrd_id_o[i-ID_CR_REQ] = m2_m1_vc_entry_list[i];
//     end
// endgenerate

// the last bits matches corresponding output flit
// assign rx_flit_channel_0_o = m2_m1_vc_entry_list[ID_REQ];
// assign rx_flit_channel_1_o = m2_m1_vc_entry_list[ID_RESP];
// assign rx_flit_channel_2_o = m2_m1_vc_entry_list[ID_EVICT];
// assign rx_flit_channel_3_o = m2_m1_vc_entry_list[ID_DATA][DATA_MESSAGE_LENGTH-1:(DATA_BURST_NUM_W+1)];
// assign rx_flit_channel_4_o = m2_m1_vc_entry_list[ID_SNP];

assign rx_flit_pend_o[0] = m2_m1_vc_entry_list.c0[M1_M2_CHANNEL_LENGTH_LIST[0]-1];
assign rx_flit_pend_o[1] = m2_m1_vc_entry_list.c1[M1_M2_CHANNEL_LENGTH_LIST[1]-1];
assign rx_flit_pend_o[2] = m2_m1_vc_entry_list.c2[M1_M2_CHANNEL_LENGTH_LIST[2]-1];
assign rx_flit_pend_o[3] = m2_m1_vc_entry_list.c3[M1_M2_CHANNEL_LENGTH_LIST[3]-1];
assign rx_flit_pend_o[4] = m2_m1_vc_entry_list.c4[M1_M2_CHANNEL_LENGTH_LIST[4]-1];

assign rx_flit_vc_id_o[0] = m2_m1_vc_entry_list.c0[(M1_M2_CHANNEL_LENGTH_LIST[0]-2) -: VC_ID_NUM_MAX_W];
assign rx_flit_vc_id_o[1] = m2_m1_vc_entry_list.c1[(M1_M2_CHANNEL_LENGTH_LIST[1]-2) -: VC_ID_NUM_MAX_W];
assign rx_flit_vc_id_o[2] = m2_m1_vc_entry_list.c2[(M1_M2_CHANNEL_LENGTH_LIST[2]-2) -: VC_ID_NUM_MAX_W];
assign rx_flit_vc_id_o[3] = m2_m1_vc_entry_list.c3[(M1_M2_CHANNEL_LENGTH_LIST[3]-2) -: VC_ID_NUM_MAX_W];
assign rx_flit_vc_id_o[4] = m2_m1_vc_entry_list.c4[(M1_M2_CHANNEL_LENGTH_LIST[4]-2) -: VC_ID_NUM_MAX_W];

assign rx_flit_look_ahead_routing_o[0] = m2_m1_vc_entry_list.c0[(M1_M2_CHANNEL_LENGTH_LIST[0]-VC_ID_NUM_MAX_W-2) -: LAR_W];
assign rx_flit_look_ahead_routing_o[1] = m2_m1_vc_entry_list.c1[(M1_M2_CHANNEL_LENGTH_LIST[1]-VC_ID_NUM_MAX_W-2) -: LAR_W];
assign rx_flit_look_ahead_routing_o[2] = m2_m1_vc_entry_list.c2[(M1_M2_CHANNEL_LENGTH_LIST[2]-VC_ID_NUM_MAX_W-2) -: LAR_W];
assign rx_flit_look_ahead_routing_o[3] = m2_m1_vc_entry_list.c3[(M1_M2_CHANNEL_LENGTH_LIST[3]-VC_ID_NUM_MAX_W-2) -: LAR_W];
assign rx_flit_look_ahead_routing_o[4] = m2_m1_vc_entry_list.c4[(M1_M2_CHANNEL_LENGTH_LIST[4]-VC_ID_NUM_MAX_W-2) -: LAR_W];

assign tx_lcrd_id_o[0] = m2_m1_vc_entry_list.c5;
assign tx_lcrd_id_o[1] = m2_m1_vc_entry_list.c6;
assign tx_lcrd_id_o[2] = m2_m1_vc_entry_list.c7;
assign tx_lcrd_id_o[3] = m2_m1_vc_entry_list.c8;
assign tx_lcrd_id_o[4] = m2_m1_vc_entry_list.c9;

assign rx_flit_channel_0_o = m2_m1_vc_entry_list.c0;
assign rx_flit_channel_1_o = m2_m1_vc_entry_list.c1;
assign rx_flit_channel_2_o = m2_m1_vc_entry_list.c2;
assign rx_flit_channel_3_o = m2_m1_vc_entry_list.c3[DATA_MESSAGE_LENGTH-1:(DATA_BURST_NUM_W+1)];
assign rx_flit_channel_4_o = m2_m1_vc_entry_list.c4;

endmodule: m1_ebi_if_handshake