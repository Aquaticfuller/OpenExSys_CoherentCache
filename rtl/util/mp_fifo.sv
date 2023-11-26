`ifndef __MP_FIFO_SV__
`define __MP_FIFO_SV__

module mp_fifo
#(
    parameter type payload_t = logic[3:0],
    parameter int unsigned ENQUEUE_WIDTH = 4,
    parameter int unsigned DEQUEUE_WIDTH = 4,
    parameter int unsigned DEPTH = 16,
    parameter int unsigned MUST_TAKEN_ALL = 1
)
(
    // Enqueue
    input logic[ENQUEUE_WIDTH-1:0] enqueue_vld_i,
    input payload_t[ENQUEUE_WIDTH-1:0] enqueue_payload_i,
    output logic[ENQUEUE_WIDTH-1:0] enqueue_rdy_o,    
    // Dequeue
    output logic[DEQUEUE_WIDTH-1:0] dequeue_vld_o,
    output payload_t[DEQUEUE_WIDTH-1:0] dequeue_payload_o,
    input logic[DEQUEUE_WIDTH-1:0] dequeue_rdy_i,
    
    input logic flush_i,
    
    input clk,
    input rst
);

    localparam int unsigned ENTRY_PTR_WIDTH = $clog2(DEPTH);
    localparam int unsigned ENTRY_CNT_WIDTH = $clog2(DEPTH+1);

    logic[ENQUEUE_WIDTH-1:0][ENTRY_PTR_WIDTH-1:0] enq_ptr;
    logic[DEQUEUE_WIDTH-1:0][ENTRY_PTR_WIDTH-1:0] deq_ptr;
    logic[ENTRY_CNT_WIDTH-1:0] avail_cnt;

    payload_t[DEPTH-1:0] payload_dff;


    logic[ENQUEUE_WIDTH-1:0] enq_fire;
    logic[DEQUEUE_WIDTH-1:0] deq_fire;

    assign enq_fire = enqueue_vld_i & enqueue_rdy_o;
    assign deq_fire = dequeue_vld_o & dequeue_rdy_i;
    
    generate
        for(genvar i = 0 ; i < DEQUEUE_WIDTH; i++) begin
            assign dequeue_payload_o[i] = payload_dff[deq_ptr[i]];
            assign dequeue_vld_o[i] = (DEPTH-avail_cnt) > i;
        end
    endgenerate
    
    generate
        if(MUST_TAKEN_ALL) begin
            assign enqueue_rdy_o = {ENQUEUE_WIDTH{avail_cnt >= ENQUEUE_WIDTH}};
        end else begin
            for(genvar i = 0; i < ENQUEUE_WIDTH; i++) begin
                assign enqueue_rdy_o[i] = avail_cnt > i;
            end
        end
    endgenerate
        

    always_ff@(posedge clk) begin : payload_dff_update
        for(int i = 0; i < ENQUEUE_WIDTH; i++) begin
            if(enq_fire[i]) begin
                payload_dff[enq_ptr[i]] <= enqueue_payload_i[i];
            end
        end
    end

    usage_manager #(
        .ENTRY_COUNT(DEPTH),
        .ENQ_WIDTH(ENQUEUE_WIDTH),
        .DEQ_WIDTH(DEQUEUE_WIDTH),
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
    
endmodule : mp_fifo

`endif