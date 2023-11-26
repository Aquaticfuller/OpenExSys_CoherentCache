module test_ebi_tx
    import test_ebi_pkg::*;
    import rvh_noc_pkg::*;
    import rvh_uncore_param_pkg::*;
#(
    parameter CHANNEL_NUM,
    parameter CHANNEL_NUM_WIDTH,
    parameter MAX_MESSAGE_LENGTH,
    parameter MAX_MESSAGE_WIDTH,
    parameter int unsigned CHANNEL_LENGTH_LIST[CHANNEL_NUM]
)
(
    input if_clk,
    input bus_clk,
    input rst,
    input  logic [CHANNEL_NUM-1:0][MAX_MESSAGE_LENGTH-1:0]          channel_hs_entry,  // wire here
    input  logic [CHANNEL_NUM-1:0]                                  channel_entry_valid,  
    output logic [CHANNEL_NUM-1:0]                                  channel_push_ready,
    output logic  [OFF_DIE_WD-1:0]                                  bus_out,
    input  logic                                                    credit_in
);

logic send_success, send_fail; // indicates that message has been received without transmitting error
logic [CHANNEL_NUM-1:0] vc_arb_valid_q, vc_arb_valid, send_ar_grt;
logic [CHANNEL_NUM_WIDTH-1:0] send_ar_grt_idx;
logic [CREDIT_WIDTH:0] send_credit_count;
logic en_recv_credit, en_message_bit_count;
credit_t credit_slot, asynced_credit; // this signal need to be synced to cache domain
recv_credit_state_t next_credit_state, credit_state;
logic recv_credit_synced;
logic send_next_one;
logic async_send_credit_fifo_empty;
logic [CHANNEL_NUM-1:0][OFF_DIE_WD + MAX_MESSAGE_LENGTH-1:0] vc_entry_list;   // plus OFF_DIE_WD because OFF_DIE_WD might not align with actual message length 
logic [CHANNEL_NUM-1:0] entry_send_success;
logic [MAX_MESSAGE_LENGTH-1:0] arbbed_message;
logic [CHANNEL_NUM_WIDTH + MAX_MESSAGE_LENGTH-1:0] asynced_message;
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

assign entry_send_success = {CHANNEL_NUM{(!async_send_credit_fifo_empty) & (asynced_credit == SUCCESS)}} & send_ar_grt; // the second term indicates that ar message is being transmitted    
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

generate 
    for (genvar i = 0; i < CHANNEL_NUM ;i++) begin
        StreamFIFO #(
            .Depth(EBI_BUFFER_DEPTH),
            .WordWidth(CHANNEL_LENGTH_LIST[i])
        ) u_send_vc (
            .enq_vld_i(channel_entry_valid[i]),
            .enq_payload_i(channel_hs_entry[i][CHANNEL_LENGTH_LIST[i] -1 : 0]),
            .enq_rdy_o(channel_push_ready[i]),
            .deq_vld_o(vc_arb_valid[i]),
            .deq_payload_o(vc_entry_list[i]),
            .deq_rdy_i(entry_send_success[i]),
            .flush_i(1'b0),
            .clk(if_clk),
            .rstn(~rst)
        );
    end
endgenerate 

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
    .N_INPUT(CHANNEL_NUM)
) vc_send_arb(
  .req_i        (vc_arb_valid_q   ),
  .update_i     (|vc_arb_valid_q), //when message is successfully transmitted, next message can be arbitted
  .grt_o        (send_ar_grt    ),
  .grt_idx_o    (send_ar_grt_idx),
  .rstn         (rst            ),
  .clk          (if_clk      )
);

assign arbbed_message = vc_entry_list[send_ar_grt_idx];

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
    .rdata(asynced_message),
    .rempty(async_message_send_fifo_empty),
    .arempty()
);

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
assign message_length = CHANNEL_LENGTH_LIST[channel_id] + CHANNEL_NUM_WIDTH;  // TODO: add other options
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
            MESSAGE_SEND: begin   //if left message bit <8, append the last bit (it doesn't matter)
                if(all_message_transmitted | (send_parity_count == PARITY_LENGTH - 1'b1)) begin  // if count not autoinc, this signal will hold
                    en_message_bit_count = 1'b0; 
                end else begin
                    en_message_bit_count = 1'b1;
                end
                if (send_parity_count == PARITY_LENGTH - 1'b1)begin
                    en_send_parity_count = 1'b0;
                    next_transmit_state = INSERT_PARITY;
                end else begin
                    en_send_parity_count = 1'b1;
                    next_transmit_state = MESSAGE_SEND;
                end
            end
            INSERT_PARITY: begin
                if(all_message_transmitted) begin
                    next_transmit_state = END_BIT;
                end else begin
                    next_transmit_state = MESSAGE_SEND;
                    en_send_parity_count = 1'b1;
                    en_message_bit_count = 1'b1;
                end
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
                        transmitting_bit[i] <= parity_bit[i] ^ asynced_message[message_count * OFF_DIE_WD + i];
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


endmodule: test_ebi_tx