`ifndef __ONE_HOT_PRIORITY_ENCODER_SV__
`define __ONE_HOT_PRIORITY_ENCODER_SV__


module one_hot_priority_encoder
#(
    parameter int unsigned SEL_WIDTH = 8
)
(
    input logic[SEL_WIDTH-1:0] sel_i,
    output logic[SEL_WIDTH-1:0] sel_o
);
    
    localparam int unsigned SEL_ID_WIDHT = $clog2(SEL_WIDTH);
    
    
    logic [SEL_WIDTH-1:0] sel_mask;
    
    assign sel_mask = ((~sel_i + 1'b1) & sel_i);
    
    assign sel_o = sel_mask;
    
    


endmodule : one_hot_priority_encoder

`endif