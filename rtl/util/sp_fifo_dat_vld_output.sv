module sp_fifo_dat_vld_output
#(
    parameter type payload_t = logic[3:0],
    // parameter int unsigned 1 = 4,
    // parameter int unsigned 1 = 4,
    parameter int unsigned DEPTH = 16,
    parameter int unsigned MUST_TAKEN_ALL = 1
)
(
    // Enqueue
    input logic[1-1:0] enqueue_vld_i,
    input payload_t[1-1:0] enqueue_payload_i,
    output logic[1-1:0] enqueue_rdy_o,    
    // Dequeue
    output logic[1-1:0] dequeue_vld_o,
    output payload_t[1-1:0] dequeue_payload_o,
    input logic[1-1:0] dequeue_rdy_i,
    
    // output data and valid
    output payload_t[DEPTH-1:0] payload_dff,
    output logic [DEPTH-1:0] payload_vld_dff,

    input logic flush_i,
    
    input clk,
    input rst
);

    localparam int unsigned ENTRY_PTR_WIDTH = $clog2(DEPTH);
    localparam int unsigned ENTRY_CNT_WIDTH = $clog2(DEPTH+1);

    logic[1-1:0][ENTRY_PTR_WIDTH-1:0] enq_ptr;
    logic[1-1:0][ENTRY_PTR_WIDTH-1:0] deq_ptr;
    logic[ENTRY_CNT_WIDTH-1:0] avail_cnt;

    // payload_t[DEPTH-1:0] payload_dff;
    // logic [DEPTH-1:0] payload_vld_dff;


    logic[1-1:0] enq_fire;
    logic[1-1:0] deq_fire;

    assign enq_fire = enqueue_vld_i & enqueue_rdy_o;
    assign deq_fire = dequeue_vld_o & dequeue_rdy_i;
    
    generate
        for(genvar i = 0 ; i < 1; i++) begin
            assign dequeue_payload_o[i] = payload_dff[deq_ptr[i]];
            assign dequeue_vld_o[i] = (DEPTH-avail_cnt) > i;
        end
    endgenerate
    
    generate
        if(MUST_TAKEN_ALL) begin
            assign enqueue_rdy_o = {1{avail_cnt >= 1}};
        end else begin
            for(genvar i = 0; i < 1; i++) begin
                assign enqueue_rdy_o[i] = avail_cnt > i;
            end
        end
    endgenerate
        

    always_ff@(posedge clk) begin : payload_dff_update
        for(int i = 0; i < 1; i++) begin
            if(enq_fire[i]) begin
                payload_dff[enq_ptr[i]] <= enqueue_payload_i[i];
            end
        end
    end

    always_ff@(posedge clk) begin : payload_vld_dff_update
        if(rst) begin
            payload_vld_dff <= '0;
        end else begin
            for(int i = 0; i < 1; i++) begin
                if(enq_fire[i]) begin
                    payload_vld_dff[enq_ptr[i]] <= 1'b1;
                end
                if(deq_fire[i]) begin
                    payload_vld_dff[deq_ptr[i]] <= 1'b0;
                end
            end
        end
    end

    usage_manager #(
        .ENTRY_COUNT(DEPTH),
        .ENQ_WIDTH(1),
        .DEQ_WIDTH(1),
        .FLAG_EN(0),
        .INIT_IS_FULL(0),
        .COMB_DEQ_EN(0),
        .COMB_ENQ_EN(1)
    ) u_usage_manager (
        .enq_fire_i(enq_fire),
        .deq_fire_i(deq_fire),
        .head_o(deq_ptr),
        .tail_o(enq_ptr),
        .avail_cnt_o(avail_cnt),
        .flush_i(flush_i),
        .clk(clk),
        .rst(rst)
    );
    
endmodule : sp_fifo_dat_vld_output
