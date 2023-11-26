`ifndef __ONE_COUNTER_SV__
`define __ONE_COUNTER_SV__

module one_counter
#(
    parameter int unsigned DATA_WIDTH = 8,
    localparam int unsigned CNT_WIDTH = $clog2(DATA_WIDTH) + 1
)
(
    input logic[DATA_WIDTH-1:0] data_i,
    output logic[CNT_WIDTH-1:0] cnt_o
);
    localparam int unsigned PADDED_DATA_WIDTH = 1 << $clog2(DATA_WIDTH);

    logic [PADDED_DATA_WIDTH-1:0] padded_data;

    always_comb begin
        padded_data = {PADDED_DATA_WIDTH{1'b0}};
        padded_data[DATA_WIDTH-1:0] = data_i;
    end

    if(DATA_WIDTH == 1) begin
        assign cnt_o = data_i;
    end else begin
    
        logic [CNT_WIDTH-2:0] res_left,res_right;
    
        assign cnt_o = res_left + res_right;
    
        one_counter #(
            .DATA_WIDTH(PADDED_DATA_WIDTH/2)
        ) one_counter_left_u (
            .data_i(padded_data[PADDED_DATA_WIDTH-1:PADDED_DATA_WIDTH/2]),
            .cnt_o(res_left)
        );
        one_counter #(
            .DATA_WIDTH(PADDED_DATA_WIDTH/2)
        ) one_counter_right_u (
            .data_i(padded_data[PADDED_DATA_WIDTH/2-1:0]),
            .cnt_o(res_right)
        );
    end
    
    

    

endmodule : one_counter

`endif